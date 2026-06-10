# Threadline

## What Threadline Is

Threadline is Crosswake's honest, PII-free correlation thread across the three tiers of a Crosswake application: Native -> Bridge -> Phoenix.

A single `X-Crosswake-Thread-Id` header propagates from native shell activation through bridge requests into Phoenix, giving operators a reconstructable, append-only sequence of events for one user-visible interaction. Thread ids are opaque identifiers — they carry no identity claims. Threadline sets `Logger.metadata` and emits `:telemetry` spans; it never logs directly.

## What Threadline Is NOT

These are non-goals by design, not deferred features.

- **Not an APM / observability platform.** Threadline is a thin correlation layer. It emits `:telemetry` events; it does not collect, ingest, or sample telemetry.
- **Not an OpenTelemetry replacement.** Bespoke narrow header; coexists with OTel via a host-owned handler. No OTel dependency.
- **Not a logging framework.** The library sets `Logger.metadata` and emits telemetry; it never emits log lines.
- **Not a generic plugin / event bus.** Only a typed audit writer; no open subscription API.
- **No PII in the audit ledger.** PII-free by construction: opaque `actor_ref`, fail-closed metadata guard. Host owns the generated schema.
- **No full-session replay.** Sequence reconstruction only. Full-session replay is not in scope.

## The Propagation Contract

The header name is `X-Crosswake-Thread-Id`. The plug reads an inbound header (posture: `:inbound`) or mints a new id (posture: `:minted`) and places it in `conn.assigns[:thread_id]`.

Server-side plug: `Crosswake.Plug.Threadline`. Add it to the Phoenix router pipeline:

```elixir
pipeline :browser do
  plug Crosswake.Plug.Threadline
  # ...
end
```

LiveView on_mount: `Crosswake.Live.Threadline`. For LiveView WebSocket connections, mount it in the router:

```elixir
live_session :default, on_mount: [Crosswake.Live.Threadline] do
  # routes
end
```

The LiveView mount reads `_crosswake_thread_id` from the connect params passed by the native shell.

The plug emits three `:telemetry` events:

- `[:crosswake, :threadline, :request, :start]`
- `[:crosswake, :threadline, :request, :stop]`
- `[:crosswake, :threadline, :request, :exception]`

Each event carries four allowlisted metadata keys: `thread_id`, `correlation_id`, `route_id`, `source`. The `actor_ref` field is not included in telemetry metadata — it is persisted only in the host-owned audit ledger. All metadata passes through the PII guard before emission; forbidden keys are silently dropped.

## Posture: Ephemeral vs Durable

Threadline has two valid, documented postures:

**Ephemeral** (default): thread ids propagate and telemetry spans are emitted, but nothing is persisted. No ledger is configured. This is a supported state, not a misconfiguration.

**Durable**: the host opts in to a host-owned audit ledger. Crosswake never owns the table or the repo — the host configures both:

```elixir
config :crosswake,
  audit_repo: MyApp.Repo,
  audit_ledger: MyApp.Audit.Ledger
```

Run `mix crosswake.gen.audit` to scaffold the host-owned ledger schema and migration.

## The Audit Ledger Schema (LEDG-02)

The ledger is host-owned and append-only. There are no update or delete paths. The 15 canonical LEDG-02 columns are a frozen contract.

Run `mix crosswake.gen.audit` to scaffold the host-owned Ecto schema and migration with these fields:

| field | type | meaning |
|-------|------|---------|
| `thread_id` | `:string` | Session-spanning correlation id propagated from the native shell |
| `correlation_id` | `:string` | Per-command id layered below `thread_id` |
| `route_id` | `:string` | The Phoenix route that produced this event |
| `actor_ref` | `:string` | Opaque host-defined actor reference; never a raw user id |
| `actor_kind` | `:string` | Actor classification (e.g. `"user"`, `"service"`) |
| `event_class` | `:string` | High-level event category (e.g. `"auth"`, `"commerce"`) |
| `event_type` | `:string` | Specific event within the class |
| `outcome` | `:string` | Terminal outcome of the event |
| `provenance` | `Ecto.Enum` — `:device_claimed \| :backend_accepted` | Evidence lane: device-claimed evidence vs backend-accepted authority |
| `occurred_at` | `:utc_datetime_usec` | When the event occurred in the host application |
| `recorded_at` | `:utc_datetime_usec` | When the row was written to the ledger |
| `idempotency_key` | `:string` | Unique index on `crosswake_audit_events` — deduplicates writes |
| `metadata` | `:map` | Host-defined contextual data; PII-forbidden fields are rejected |
| `row_hash` | `:string` | Advisory HMAC of this row's content |
| `prev_hash` | `:string` | Advisory HMAC of the preceding row |

`provenance` distinguishes `device_claimed` (evidence from the native shell) from `backend_accepted` (authority confirmed by the Phoenix backend). `idempotency_key` has a unique database index — use it to guard against double-writes on retry.

## PII-Free by Construction

There are two separate forbidden-key lists. They guard different surfaces and must not be conflated.

### Telemetry Denylist (20 keys)

`Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0` — keys the Plug strips from telemetry metadata before emission. These keys must never appear in correlation spans:

`access_token`, `actor_id`, `actor_ref`, `authorization_code`, `credential_id`, `device_id`, `email`, `id_token`, `ip`, `nonce`, `org_id`, `passkey_credential_id`, `pkce_verifier`, `provider_payload`, `raw_return_to`, `refresh_token`, `return_to`, `session_ref`, `subject_ref`, `user_agent`

### Ledger PII Guard (8 keys)

The generated `reject_pii_in_metadata/1` changeset blocks these keys in the `metadata` map of any audit ledger row. These are the 8 keys forbidden from ledger metadata:

`email`, `phone`, `ip_address`, `ssn`, `name`, `first_name`, `last_name`, `address`

The changeset rejects the entire row if any of these keys is present in `metadata`. This is fail-closed: a misconfigured ledger schema that includes a PII-bearing field will trigger the `threadline.pii_forbidden_field_present` doctor error.

## Operations

### Inspecting a thread: `mix crosswake.threadline`

The `mix crosswake.threadline` task renders a chronological Native -> Bridge -> Phoenix text tree for one thread:

```
mix crosswake.threadline --thread-id <id>
mix crosswake.threadline --actor-ref <ref>
```

In ephemeral posture the task prints `Posture: Ephemeral. No ledger configured.` and exits 0 — a valid documented state. In durable posture it queries the host ledger and groups events by tier; events carrying a nil or unrecognized tier value are rendered under a trailing `Other (unrecognized tier)` bucket rather than silently dropped.

### Scaffolding the ledger: `mix crosswake.gen.audit`

`mix crosswake.gen.audit` generates the host-owned Ecto schema and timestamped migration for `crosswake_audit_events`. The generated schema implements the 15 LEDG-02 columns, the `reject_pii_in_metadata/1` changeset guard, and the `compute_hashes/1` helper. The host owns the table, the repo, and the migration.

Use `record_in_multi/2` to insert audit events inside an existing `Ecto.Multi` in the same transaction as the action they describe. Reserve the ledger for terminal critical events — auth handoffs, commerce receipts, step-up resolutions, route denials — not high-frequency request logging.

## Doctor Findings

`mix crosswake.doctor` emits threadline posture findings under the `threadline_posture` check:

| Code | Severity | Meaning |
| --- | --- | --- |
| `threadline.plug_missing` | advisory | `Crosswake.Plug.Threadline` is absent from the Phoenix router pipeline, so thread ids do not propagate into Phoenix. |
| `threadline.ledger_not_configured` | advisory | No `:audit_ledger` configured — posture is ephemeral only. |
| `threadline.pii_forbidden_field_present` | error | The configured ledger schema declares PII-forbidden fields. The ledger must be PII-free by construction (D-03). |
| `threadline.ledger_schema_drift` | warning | The configured ledger schema is missing canonical LEDG-02 columns. |
| `threadline.ledger_schema_invalid` | advisory | The configured `:audit_ledger` module is not an Ecto schema (no `__schema__/1`); PII and drift checks were skipped. |

Advisory findings describe an opt-in you have not taken; the PII finding is an error because a PII-bearing ledger violates the threadline contract.

## Honest Limitations

**WebView gap.** Native-to-Phoenix correlation requires explicit header injection from the native shell. WebView WebSocket connections, fetch calls, and XHR requests do not carry the thread id — this is a deliberate scoping decision, not a bug. For LiveView mounts inside a native shell, pass the thread id via the `_crosswake_thread_id` connect param, which `Crosswake.Live.Threadline` reads on mount.

**Hash-chaining detects, does not prevent.** row_hash and prev_hash detect gaps and overwrites after the fact. Hash-chaining does not prevent tampering — it reports it. The ledger is append-only by convention enforced at the Ecto changeset layer; it is not a cryptographically sealed ledger. Advisory hash columns are a reconstruction aid for operators, not a tamper-proof guarantee.

**OTel coexistence.** Threadline emits standard `:telemetry` events with zero OTel dependency. If your host uses OpenTelemetry, attach a host-owned OTel handler to bridge the `:telemetry` spans into your OTel pipeline. Threadline does not create or manage OTel spans, trace context, or baggage.

## Deferred Non-Claims

A `crosswake_dashboard` package and a hash-chain verification task (`row_hash`/`prev_hash` integrity walking) are deferred. Their absence is a documented non-claim, not a gap. Do not rely on undocumented internal APIs for either capability.
