# Threadline

Threadline is Crosswake's honest, PII-free correlation thread across the three
tiers of a Crosswake application: Native -> Bridge -> Phoenix. A single
`X-Crosswake-Thread-Id` propagates from native shell activation through bridge
requests into Phoenix, so operators can reconstruct the append-only sequence of
events behind one user-visible interaction.

Threadline is an append-only sequence reconstruction tool. It is **not** an
APM, not a full replay system, and not a tracing platform. It answers
"what happened, in what order, across which tiers" — nothing more.

## Posture: ephemeral vs durable

Threadline has two valid, documented postures:

- **Ephemeral** (default): thread ids propagate and telemetry spans are
  emitted, but nothing is persisted. No ledger is configured. This is a
  supported state, not a misconfiguration.
- **Durable**: the host opts in to a host-owned audit ledger. Crosswake never
  owns the table or the repo — the host configures both:

      config :crosswake,
        audit_repo: MyApp.Repo,
        audit_ledger: MyApp.Audit.Ledger

  Run `mix crosswake.gen.audit` to scaffold the host-owned ledger schema and
  migration with the 15 canonical LEDG-02 columns (`thread_id`,
  `correlation_id`, `route_id`, `actor_ref`, `actor_kind`, `event_class`,
  `event_type`, `outcome`, `provenance`, `occurred_at`, `recorded_at`,
  `idempotency_key`, `metadata`, `row_hash`, `prev_hash`).

The ledger is PII-free by construction (D-03): forbidden metadata keys (emails,
tokens, names, raw identifiers) must never appear as ledger schema fields.

## Inspecting a thread: `mix crosswake.threadline`

The `mix crosswake.threadline` task renders a chronological Native -> Bridge ->
Phoenix text tree for one thread:

    mix crosswake.threadline --thread-id <id>
    mix crosswake.threadline --actor-ref <ref>

In ephemeral posture the task prints `Posture: Ephemeral. No ledger
configured.` and exits 0 — a valid documented state. In durable posture it
queries the host ledger and groups events by tier; events carrying a nil or
unrecognized tier value are rendered under a trailing
`Other (unrecognized tier)` bucket rather than silently dropped.

## Doctor findings

`mix crosswake.doctor` emits threadline posture findings under the
`threadline_posture` check:

| Code | Severity | Meaning |
| --- | --- | --- |
| `threadline.plug_missing` | advisory | `Crosswake.Plug.Threadline` is absent from the Phoenix router pipeline, so thread ids do not propagate into Phoenix. |
| `threadline.ledger_not_configured` | advisory | No `:audit_ledger` configured — posture is ephemeral only. |
| `threadline.pii_forbidden_field_present` | error | The configured ledger schema declares PII-forbidden fields. The ledger must be PII-free by construction (D-03). |
| `threadline.ledger_schema_drift` | warning | The configured ledger schema is missing canonical LEDG-02 columns. |

Advisory findings describe an opt-in you have not taken; the PII finding is an
error because a PII-bearing ledger violates the threadline contract.

## Deferred non-claims

A Crosswake dashboard and a hash-chain verification task
(`row_hash` / `prev_hash` integrity walking) are deferred. Their absence is a
documented non-claim, not a gap.
