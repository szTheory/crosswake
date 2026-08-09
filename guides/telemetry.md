# Telemetry

## What Crosswake Telemetry Is

`Crosswake.Telemetry` is the canonical public API for the `:telemetry` events Crosswake emits across its companion, doctor, threadline, sigra, chimeway, and bridge subsystems.

Call `Crosswake.Telemetry.events/0` at runtime to retrieve a self-describing catalog of every event Crosswake declares. Each entry carries the event name prefix, a tier (`:active` for events that fire today, `:reserved` for events declared but not yet emitted), a description, and the exact measurement and metadata keys the event carries. This catalog is the source of truth for host observability pipelines, dashboards, and contract tests.

Telemetry in Crosswake is diagnostic-only. The library emits standard `:telemetry` events and exposes a typed, low-cardinality, PII-free catalog. It coexists with any host-side observability pipeline without requiring changes to existing instrumentation. No new dependencies are introduced — only `:telemetry`, which is already a project dependency.

## What Crosswake Telemetry Is NOT

These are non-goals by design, not deferred features.

- **Not an APM / observability platform.** `Crosswake.Telemetry` emits events and catalogs them. It does not collect, ingest, sample, or aggregate telemetry. Host teams choose their own pipeline.
- **Not a distributed tracing framework.** Crosswake does not create or manage trace context, spans in the OTel sense, or baggage. If your host uses OpenTelemetry, attach a host-owned OTel handler to bridge the `:telemetry` events into your OTel pipeline.
- **Not a generic event bus.** The event catalog is typed, low-cardinality, and scoped to Crosswake subsystem activity. It is not an open subscription API for arbitrary host events.
- **Not a source of PII.** All metadata passes through a forbidden-key denylist before emission. PII-bearing fields are silently dropped. See [Security and PII](#security-and-pii).

## Semver Contract

Telemetry events are **public API**.

- **Additions** (new event prefixes, new measurement keys, new metadata keys) are non-breaking minor releases.
- **Removals or renames** of existing event prefixes, measurement keys, or metadata keys are breaking changes requiring a semver major bump.

Host code that attaches handlers to Crosswake events may depend on this stability guarantee.

## Events

The table below lists every `:active` event from `Crosswake.Telemetry.events/0` — events that fire today in production code. Event names follow the Keathley span convention: a prefix atom list expanded to `:start`, `:stop`, and `:exception` suffixes.

For span-based events (emitted via `:telemetry.span/3`), the `:start` event carries `system_time` in measurements and the `:stop`/`:exception` events carry `duration`. For the four companion spans, `companion_id` and `route_id` are passed as the span context map (the second argument to `:telemetry.span/3`), which `:telemetry` places in **metadata**, not measurements — this is the Keathley span convention.

**Stop metadata is a superset of start metadata** for span-based events. See the threadline `:exception` caveat below.

### Companion: dependency\_check

Emitted when `RouteGate` checks a companion's optional dependency presence.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `companion_id`, `route_id` |
| `:stop` | `duration` | `companion_id`, `route_id` |
| `:exception` | `duration` | `companion_id`, `route_id` |

Event names:
- `` `[:crosswake, :companion, :dependency_check, :start]` ``
- `` `[:crosswake, :companion, :dependency_check, :stop]` ``
- `` `[:crosswake, :companion, :dependency_check, :exception]` ``

### Companion: kill\_switch

Emitted when `RouteGate` evaluates a companion's kill switch. Short-circuits ahead of route\_gate evaluation.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `companion_id`, `route_id` |
| `:stop` | `duration` | `companion_id`, `route_id` |
| `:exception` | `duration` | `companion_id`, `route_id` |

Event names:
- `` `[:crosswake, :companion, :kill_switch, :start]` ``
- `` `[:crosswake, :companion, :kill_switch, :stop]` ``
- `` `[:crosswake, :companion, :kill_switch, :exception]` ``

### Companion: route\_gate

Emitted when `RouteGate` evaluates a companion's route policy.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `companion_id`, `route_id` |
| `:stop` | `duration` | `companion_id`, `route_id` |
| `:exception` | `duration` | `companion_id`, `route_id` |

Event names:
- `` `[:crosswake, :companion, :route_gate, :start]` ``
- `` `[:crosswake, :companion, :route_gate, :stop]` ``
- `` `[:crosswake, :companion, :route_gate, :exception]` ``

### Companion: validate\_dependency

Emitted when Doctor runs `validate_dependency/0` for each registered companion. The `:stop` event carries an additional `result` metadata key.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `companion_id`, `route_id` |
| `:stop` | `duration` | `companion_id`, `route_id`, `result` |
| `:exception` | `duration` | `companion_id`, `route_id` |

Event names:
- `` `[:crosswake, :companion, :validate_dependency, :start]` ``
- `` `[:crosswake, :companion, :validate_dependency, :stop]` ``
- `` `[:crosswake, :companion, :validate_dependency, :exception]` ``

### Threadline: request

Emitted by `Crosswake.Plug.Threadline` for each incoming HTTP request correlation span. Unlike the companion spans above, this event is emitted via discrete `:telemetry.execute` calls (not `:telemetry.span/3`), so measurements and metadata are set explicitly per suffix.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `thread_id`, `correlation_id`, `route_id`, `source` |
| `:stop` | `duration` | `thread_id`, `correlation_id`, `route_id`, `source` |
| `:exception` | `duration` | (see caveat below) |

**Threadline `:exception` metadata caveat.** The `:exception` event is emitted when a plug exception occurs before the correlation context is fully established. In this case, `kind` and `reason` are passed as metadata, but they are not in the threadline metadata allowlist (`thread_id`, `correlation_id`, `route_id`, `source`) and are dropped by the PII guard. The exception event carries timing measurements (`duration`) but the metadata map may be effectively empty. Do not assert that `thread_id` is present in a threadline `:exception` event — the stop ⊇ start metadata guarantee holds for `:stop` but not for `:exception` in the threadline case.

Event names:
- `` `[:crosswake, :threadline, :request, :start]` ``
- `` `[:crosswake, :threadline, :request, :stop]` ``
- `` `[:crosswake, :threadline, :request, :exception]` ``

### Bridge: push

Emitted when `Crosswake.Bridge.push/3` dispatches a bounded capability to the native shell. Metadata never includes the adopter-supplied `ref:` — it stays library-internal (D-20) and never crosses into telemetry, keeping metadata cardinality bounded to route/capability/command.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `route_id`, `capability`, `command` |
| `:stop` | `duration` | `route_id`, `capability`, `command` |
| `:exception` | `duration` | `route_id`, `capability`, `command` |

Event names:
- `` `[:crosswake, :bridge, :push, :start]` ``
- `` `[:crosswake, :bridge, :push, :stop]` ``
- `` `[:crosswake, :bridge, :push, :exception]` ``

### Bridge: reply

Emitted when a bridge ask resolves to a delivered reply (`:ok` or `:deny`) — whether or not the adopter passed `ref:` and receives it in `handle_info/2` (D-21). Deny replies also carry `denial_reason`, drawn from the closed 14-reason `Crosswake.Shell.Denial` vocabulary — never a free string.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `route_id`, `command`, `status`, `denial_reason` (deny only) |
| `:stop` | `duration` | `route_id`, `command`, `status`, `denial_reason` (deny only) |
| `:exception` | `duration` | `route_id`, `command`, `status`, `denial_reason` (deny only) |

Event names:
- `` `[:crosswake, :bridge, :reply, :start]` ``
- `` `[:crosswake, :bridge, :reply, :stop]` ``
- `` `[:crosswake, :bridge, :reply, :exception]` ``

### Bridge: dropped

Emitted when a reply, unreachable fact, or timer message arrives for a correlation id that is no longer in flight. `reason` is `:duplicate` (a second terminal event arrived for a correlation id already resolved) or `:foreign_epoch` (the reply was minted under a prior per-mount epoch — the LiveView reconnected since it was dispatched). Exactly-once delivery is structural (D-23): this event is what makes a duplicate or stale delivery an observable counter instead of a silent double mutation.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `route_id`, `reason` |
| `:stop` | `duration` | `route_id`, `reason` |
| `:exception` | `duration` | `route_id`, `reason` |

Event names:
- `` `[:crosswake, :bridge, :dropped, :start]` ``
- `` `[:crosswake, :bridge, :dropped, :stop]` ``
- `` `[:crosswake, :bridge, :dropped, :exception]` ``

### Bridge: hook\_ack

Emitted when the bridge hook's acknowledgement arrives before the server-armed wiring deadline.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `route_id` |
| `:stop` | `duration` | `route_id` |
| `:exception` | `duration` | `route_id` |

Event names:
- `` `[:crosswake, :bridge, :hook_ack, :start]` ``
- `` `[:crosswake, :bridge, :hook_ack, :stop]` ``
- `` `[:crosswake, :bridge, :hook_ack, :exception]` ``

### Bridge: hook\_missing

Emitted when no acknowledgement arrives before the server-armed wiring deadline elapses — the bridge hook is not wired on this page at all. **This count should always be zero in a healthy deploy.** A nonzero rate means some page is missing the hook script tag or the `phx-hook` attribute — alert on it.

| Suffix | Measurements | Metadata |
|--------|-------------|----------|
| `:start` | `system_time` | `route_id` |
| `:stop` | `duration` | `route_id` |
| `:exception` | `duration` | `route_id` |

Event names:
- `` `[:crosswake, :bridge, :hook_missing, :start]` ``
- `` `[:crosswake, :bridge, :hook_missing, :stop]` ``
- `` `[:crosswake, :bridge, :hook_missing, :exception]` ``

## Reserved Events

Sigra and Chimeway each declare event catalogs (via `event_names/0`) that are not yet emitted from production code. These appear in `Crosswake.Telemetry.events/0` with `tier: :reserved`.

Reserved events are:
- **Included** in `events/0` so adopters can see what is planned and attach handlers speculatively.
- **Excluded** from the declared⇒emitted contract test (they do not fire yet).
- **Included** in the emitted⇒declared contract test (if code accidentally starts firing them, it will be caught).

Sigra declares 14 reserved events; Chimeway declares 10. Their event names follow the `` `[:crosswake, :sigra, ...]` `` and `` `[:crosswake, :chimeway, ...]` `` prefixes respectively. Filter by `tier: :reserved` in `events/0` to enumerate them.

`Crosswake.Offline.Telemetry` is a metadata-contract module only; it has no event catalog and contributes no events to `events/0`.

## Attaching the Default Logger

Core never attaches a telemetry handler automatically. Attachment is always the host's explicit decision.

To attach the default structured logger to all `:active` Crosswake events, call `Crosswake.Telemetry.attach_default_logger/1` from your application's supervision tree or `Application.start/2`:

```elixir
# In your Application.start/2 or a startup module:
:ok = Crosswake.Telemetry.attach_default_logger()
```

The function accepts a log level atom or a keyword list:

```elixir
# Attach with a specific log level
Crosswake.Telemetry.attach_default_logger(:debug)

# Attach with keyword options
Crosswake.Telemetry.attach_default_logger(level: :info, encode: false)
```

**Options:**

| Option | Default | Description |
|--------|---------|-------------|
| `:level` | `:info` | Log level for non-exception events. `:exception` events are always logged at `:error` regardless of this setting. |
| `:encode` | `false` | When `false`, the event map is placed in `Logger` metadata under the `:crosswake_telemetry` key so host formatters can handle JSON encoding. When `true`, the map is JSON-encoded into the log message string. |

The handler is registered under the id `"crosswake-default-logger"`. Log messages are prefixed with `[crosswake]`.

To remove the handler:

```elixir
Crosswake.Telemetry.detach_default_logger()
```

## Failure Modes

**No companions configured.** `events/0` returns core and in-tree events only. It never raises. This is a valid state, not a misconfiguration.

**Double-attach.** Calling `attach_default_logger/1` when a handler with id `"crosswake-default-logger"` is already registered returns `{:error, :already_exists}`. This is the standard `:telemetry` behavior — Crosswake does not add a custom guard. Check the return value and decide whether to treat it as an error in your startup logic.

**Companion module not loaded.** `events/0` probes companions via `function_exported?/3`. If a companion module is not yet loaded when `events/0` is called, its events are excluded silently. Call `events/0` after companions are started in your supervision tree.

**Handler raises.** If an attached telemetry handler raises an exception, `:telemetry` catches it and detaches the handler. The `[crosswake]` default logger handles this per standard `:telemetry` semantics.

## Security and PII

Crosswake telemetry is PII-free by construction.

**Forbidden metadata keys.** All metadata passes through a forbidden-key denylist before emission or logging. The denylist is the union of `forbidden_metadata_keys/0` from all subsystem telemetry modules:

- `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0` — 20 keys including `access_token`, `actor_id`, `actor_ref`, `authorization_code`, `device_id`, `email`, `id_token`, `ip`, `refresh_token`, `session_ref`, and others.
- `Crosswake.Companions.Sigra.Telemetry.forbidden_metadata_keys/0` — additional keys from the Sigra subsystem.
- `Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys/0` — additional keys from the Chimeway subsystem.

Forbidden keys are silently dropped before metadata reaches any telemetry handler. They are never logged, even with the default logger attached.

**High-cardinality values.** A `safe_value?/1` guard in each subsystem telemetry module rejects metadata values longer than 128 characters. This prevents high-cardinality strings (e.g., full request bodies) from leaking into telemetry metadata.

**Host responsibility.** Companions and host code that add metadata to events must not include PII. The denylist covers known PII field names, but domain-specific PII with non-standard field names must be excluded by the host.

Do not add identity tokens, user emails, IP addresses, or other PII to telemetry metadata — even in development. Telemetry events are forwarded to external systems (APM, log aggregators, dashboards) where PII retention policies apply.

## Testing

Use `:telemetry_test.attach_event_handlers/2` in host test suites to assert that expected events fire:

```elixir
defmodule MyApp.TelemetryTest do
  use ExUnit.Case, async: false

  test "companion route gate emits telemetry" do
    event_names = [
      [:crosswake, :companion, :route_gate, :start],
      [:crosswake, :companion, :route_gate, :stop]
    ]

    ref = :telemetry_test.attach_event_handlers(self(), event_names)
    on_exit(fn -> :telemetry.detach(ref) end)

    # Drive the code path that triggers RouteGate evaluation
    # ...

    assert_received {[:crosswake, :companion, :route_gate, :start], ^ref, measurements, _metadata}
    assert Map.has_key?(measurements, :system_time)

    assert_received {[:crosswake, :companion, :route_gate, :stop], ^ref, measurements, _metadata}
    assert Map.has_key?(measurements, :duration)
  end
end
```

`attach_event_handlers/2` returns a reference used for `^ref` pattern matching, ensuring received messages originated from this handler. Always detach in `on_exit` to avoid handler leakage between tests.

Use `async: false` for any test that modifies `Application.get_env(:crosswake, :companions, ...)` — the companions config key is shared globally.

To derive the full event list from the catalog rather than hardcoding it:

```elixir
active_event_names =
  Crosswake.Telemetry.events()
  |> Enum.filter(fn e -> e.tier == :active end)
  |> Enum.flat_map(fn %{event: prefix} ->
    [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
  end)

ref = :telemetry_test.attach_event_handlers(self(), active_event_names)
```

## Related

- [Companion Contract](companion_contract.md) — the behaviour contract for companions, including the optional `telemetry_events/0` callback.
- [Threadline](threadline.md) — the HTTP correlation thread, PII-free metadata, and the ledger schema.
