# Phase 133: Telemetry Public API - Research

**Researched:** 2026-06-28
**Domain:** Elixir `:telemetry` public API surface, Keathley span conventions, telemetry_test ETS mechanics, hexdocs wiring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Seed = events that already emit. v1 `events/0` enumerates the 5 already-emitting Keathley-compliant span prefixes (`[:crosswake, :companion, :dependency_check|:kill_switch|:route_gate]`, `[:crosswake, :threadline, :request]`) expanded to their `:start`/`:stop`/`:exception` triples, plus the existing in-tree `event_names/0` surfaces. Do NOT instrument-now. Adding events later is a non-breaking minor.
- **D-02:** Reconcile the existing declared-but-unemitted events (Sigra/Chimeway/Offline `event_names/0` entries that don't yet fire). Move them to a `reserved`/planned tier excluded from the "must-emit" half of the contract test — OR down-scope `events/0` to emitting events only. Every event in the "must-emit" tier of `events/0` is actually emitted.
- **D-03:** Write an explicit semver statement in the moduledoc + guide: "telemetry events are public API — additions are minor, removals/renames are major (breaking)."
- **D-04:** Self-describing maps: `%{event: [atom,...], description: String.t(), measurements: [atom()], metadata: [atom()]}`. Keys named exactly `event/description/measurements/metadata`.
- **D-05:** Aggregate at RUNTIME, never compile-time constants. `events/0` calls each subsystem's `event_names/0`/`metadata_keys/0` at call time.
- **D-06:** Return `Enum.uniq |> Enum.sort`. Optionally expose `spannable_events/0` helper — planner's discretion.
- **D-07:** Runtime registry via an OPTIONAL behaviour callback. Add `@callback telemetry_events() :: [event_doc()]` + `@optional_callbacks telemetry_events: 0` to `Crosswake.Companion`. `events/0` walks `Application.get_env(:crosswake, :companions, [])` and merges via `function_exported?(mod, :telemetry_events, 0)`.
- **D-08:** Core names NO companion module — iterates the runtime `:companions` registry value and calls the callback. Uses `function_exported?/3` (not `Code.ensure_loaded?`) inside a function body (EXTRACT-04). In-tree sigra/chimeway/threadline `*.Telemetry` modules ARE referenced statically (allowed — in-tree).
- **D-09:** Extracted adapters self-declare their engine's events.
- **D-10:** Fail-closed: a host with no companions configured gets only core+in-tree events; never a crash.
- **D-11:** No in-tree renames. The in-tree `[:crosswake, ...]` span events are already compliant.
- **D-12:** Non-compliant `[:rindle, ...]` events are a `crosswake_rindle` package concern — not this phase.
- **D-13:** Model on `Oban.Telemetry.attach_default_logger/1`: signature `attach_default_logger(level | opts)`, stable handler id `"crosswake-default-logger"`, rely on `:telemetry`'s `{:error, :already_exists}`, ship `detach_default_logger/0`. Derive the attached event list from `events/0`.
- **D-14:** Two modern improvements over Oban: (1) `encode: false` by default — emit a structured map into `Logger` metadata; (2) force `:exception` events to `:error` regardless of configured `:level`.
- **D-15:** Default logger inherits PII-safety for free from the existing `forbidden_metadata_keys/0` denylist.
- **D-16:** Federated, non-vacuous contract test: (a) declared structural set equals `@core_events` + in-tree `event_names/0` (exact, ordered); (b) declared⇒emitted via `:telemetry_test.attach_event_handlers(self(), events)` driving the real code paths; (c) emitted⇒declared via ETS catch-all recording every `[:crosswake, ...]` event seen during the suite.
- **D-17:** Merge mechanism proven via a `test/support` stub companion implementing `telemetry_events/0` registered in test config.
- **D-18:** Add a new `Telemetry` group to `mix.exs` `groups_for_extras` (after `Truth`) AND `groups_for_modules` (after `"Companion Contract"`, containing `Crosswake.Telemetry` + per-subsystem `*.Telemetry` modules). Add `guides/telemetry.md` to `extras:` and the new extras group.
- **D-19:** `guides/telemetry.md` follows brandbook §14 concept order. No "seamless/magic/plugin/powerful/universal". Event names in JetBrains Mono.
- **D-20:** Names stay "boring on purpose," declarative, no `auto_*`/`magic`. Log/CLI prefix `[crosswake]`; messages calm/specific/actionable.

### Claude's Discretion

Exact module/file layout, the `reserved`-tier mechanism vs down-scoping (D-02), whether to ship `spannable_events/0` (D-06), the precise `event_doc` typespec, and the doc-generator (mix task vs inline) — planner decides, consistent with the decisions above.

### Deferred Ideas (OUT OF SCOPE)

- Broad per-rule/per-diagnostic instrumentation — additive minors after 133.
- Rindle event normalization (`[:rindle, :media, :transcode, stage]` → compliant span triple) — belongs to `crosswake_rindle` package.
- DASH-01 operator dashboard — deferred milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TELEM-01 | A developer can call `Crosswake.Telemetry.events/0` to get the canonical list of every `:telemetry` event Crosswake emits across companion/RouteGate, doctor, sigra, chimeway, threadline, and offline subsystems. | Grounded: 4 confirmed emitting span prefixes + 2 per-subsystem `event_names/0` catalogs; Offline.Telemetry needs special handling (no `event_names/0`, discrete events). See Standard Stack §Grounded Seed Set. |
| TELEM-02 | A reader can find `guides/telemetry.md` documenting every event's measurements and metadata, Keathley naming, stop metadata a superset of start metadata. | Grounded: exact measurements/metadata keys extracted per event from live code. Docs wiring in mix.exs confirmed. |
| TELEM-03 | A host can opt into `Crosswake.Telemetry.attach_default_logger/1`; core never auto-attaches a handler. | Grounded: `:telemetry.attach/4` + handler id `"crosswake-default-logger"` + `{:error, :already_exists}` idiom confirmed from telemetry_test.erl source. |
| TELEM-04 | A bidirectional contract test fails if any event in `events/0` is never emitted, or any emitted event is undeclared. | Grounded: `:telemetry_test.attach_event_handlers/2` exact signature confirmed from ERL source. ETS catch-all pattern confirmed viable. |
</phase_requirements>

---

## Summary

Phase 133 delivers four artifacts — `Crosswake.Telemetry` facade module, `guides/telemetry.md`, `attach_default_logger/1`, and a bidirectional contract test — all grounded in existing in-tree instrumentation. The codebase research confirms the CONTEXT.md locked decisions accurately describe the codebase reality with one critical wrinkle: the D-01/D-02 seed-set is more nuanced than the CONTEXT.md framing suggests, because the four telemetry modules (`Threadline`, `Sigra`, `Chimeway`, `Offline`) are NOT symmetrically structured. Only `Threadline.Telemetry` and `Sigra.Telemetry` and `Chimeway.Telemetry` have `event_names/0`; `Offline.Telemetry` has ONLY `metadata_keys/0` and NO `event_names/0` function and NO `@event_names` attribute — it uses atom names (`:status_transition`, `:terminal_outcome`) rather than full `[:crosswake, ...]` lists. Critically, the actual `:telemetry.execute` or `:telemetry.span` calls from Offline do NOT appear anywhere in `lib/` — Offline declares metadata shape but does not yet emit events.

The 5 confirmed emission sites are: `route_gate.ex` (3 spans: `dependency_check`, `kill_switch`, `route_gate`), `doctor.ex` (1 span: `validate_dependency`), and `plug/threadline.ex` (3 discrete events via `Threadline.Telemetry.execute/3`). The threadline plug uses discrete `:telemetry.execute` (not `:telemetry.span`) — the start/stop/exception triple is emitted manually, not via the span helper. The route_gate and doctor use `:telemetry.span/3`, which auto-emits the start/stop/exception triple.

The companion behaviour already lacks `telemetry_events/0` — it needs to be added as `@optional_callbacks`. The existing `Crosswake.Companion` has exactly 6 callbacks, and the Phase 129 contract-freeze test enforces that count with `MapSet.equal?` — adding the optional callback will change `behaviour_info(:callbacks)` and WILL trip the Phase 129 freeze test unless that test is updated in the same PR.

**Primary recommendation:** Implement in three waves: (1) add the optional `telemetry_events/0` callback to `Companion` and update the Phase 129 freeze test simultaneously; (2) build `Crosswake.Telemetry` (events/0, attach/detach) and the stub companion; (3) write `guides/telemetry.md` and wire mix.exs docs groups.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `events/0` facade aggregation | Library/Core module | — | Runtime aggregation at call time; no web tier involved |
| Companion `telemetry_events/0` optional callback | Companion behaviour contract | Individual companion modules | EXTRACT-04-safe: function body, function_exported? probe |
| `attach_default_logger/1` | Library/Core module | Host application | Core provides the opt-in; host calls it from their supervision tree |
| Contract test bidirectionality | Test layer (ExUnit) | — | ETS catch-all + telemetry_test handlers; no application state needed |
| `guides/telemetry.md` hexdocs | Build-time docs artifact | mix.exs groups wiring | Rendered by ExDoc; no runtime component |
| PII scrubbing in default logger | Library/Core module | Subsystem Telemetry modules | Reuses `forbidden_metadata_keys/0` from subsystem modules; no new logic needed |

---

## Grounded Seed Set (D-01 + D-02 analysis)

### Confirmed Emission Sites (verified by grep in lib/)

**Group A — EMITTING, SPAN-BASED** (`:telemetry.span/3` — auto-emits start/stop/exception triple):

| Span Prefix | Emitter | Lines | Measurements (:start) | Measurements (:stop) | Metadata (both) |
|------------|---------|-------|----------------------|--------------------|----------------|
| `[:crosswake, :companion, :dependency_check]` | `route_gate.ex:139` | start: `%{companion_id: atom(), route_id: binary()}` | + `duration` (monotonic_time diff, auto by span) | `companion_id`, `route_id`; stop adds `exception: true` on error path |
| `[:crosswake, :companion, :kill_switch]` | `route_gate.ex:191` | `%{companion_id: atom(), route_id: binary()}` | + `duration` (auto) | `companion_id`, `route_id` |
| `[:crosswake, :companion, :route_gate]` | `route_gate.ex:219` | `%{companion_id: atom(), route_id: binary()}` | + `duration` (auto) | `companion_id`, `route_id` |
| `[:crosswake, :companion, :validate_dependency]` | `doctor.ex:573` | `%{companion_id: atom(), route_id: nil}` | + `duration` (auto) | `companion_id`, `route_id: nil`, stop adds `result: :ok \| {:error, [module()]}` |

**Note on `:telemetry.span/3` auto-measurements:** The `:start` event receives `%{system_time: System.system_time()}` plus the caller-supplied measurements map. The `:stop` event receives `%{duration: native_time}` plus the caller-supplied stop-metadata map. The `:exception` event receives `%{duration: native_time}` plus `%{kind: kind, reason: reason, stacktrace: stacktrace}`. This means stop-metadata IS a strict superset of start-metadata for these spans. [VERIFIED: packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl — span behavior confirmed]

**Group B — EMITTING, DISCRETE** (manual `:telemetry.execute` via `Threadline.Telemetry.execute/3`):

| Event Name | Emitter | Measurements | Metadata keys |
|-----------|---------|-------------|----------------|
| `[:crosswake, :threadline, :request, :start]` | `plug/threadline.ex:52` | `%{system_time: System.system_time()}` | `thread_id`, `correlation_id`, `route_id`, `source` |
| `[:crosswake, :threadline, :request, :stop]` | `plug/threadline.ex:60` | `%{duration: monotonic_time_diff}` | `thread_id`, `correlation_id`, `route_id`, `source` |
| `[:crosswake, :threadline, :request, :exception]` | `plug/threadline.ex:69` | `%{duration: monotonic_time_diff}` | `kind: :error, reason: exception` (raw — not through the PII guard) |

**Important:** the `:exception` branch in `plug/threadline.ex` calls `Telemetry.execute/3` with raw `%{kind: :error, reason: e}` metadata — this goes through the `Threadline.Telemetry.metadata/1` PII guard, which will DROP `reason` and `kind` because they are not in `@metadata_keys`. The exception event will emit with an effectively empty metadata map for the known keys. This is correct behavior per the PII guard design, but the guide must document it accurately.

### Declared-but-Unemitted Events (D-02 — must assign to "reserved" tier or exclude)

**Sigra.Telemetry** — 14 event names declared in `@event_names`, NONE emitted in `lib/crosswake/companions/sigra/` (only the `execute/3` helper exists; no call sites outside the module itself). All 14 Sigra events are VACUOUS — declared but not fired by any code in `lib/`. [VERIFIED: grep of lib/crosswake/companions/sigra/ confirmed zero :telemetry.execute/:telemetry.span calls except inside telemetry.ex itself]

**Chimeway.Telemetry** — 10 event names declared, NONE emitted. Same pattern as Sigra — `execute/3` exists but is never called from other modules. [VERIFIED: grep confirmed]

**Offline.Telemetry** — Has NO `event_names/0` function and NO `@event_names` module attribute. Event "names" are atoms (`:status_transition`, `:terminal_outcome`) not full `[:crosswake, ...]` lists. NO `:telemetry.execute` or `:telemetry.span` calls exist anywhere in `lib/crosswake/offline/`. Offline.Telemetry defines only metadata shape — it is a pure metadata contract module with no emission. [VERIFIED: grep of lib/crosswake/offline/ confirmed]

**Resolution for D-02:** The recommended approach is a two-tier `events/0`:
- Tier `:active` — the 7 emitting events (4 companion span prefixes × 3 = 12 + 3 threadline = 15 total event names including start/stop/exception expansions). These appear in the "must-emit" side of the contract test.
- Tier `:reserved` — Sigra (14) + Chimeway (10) events. These appear in `events/0` as declared-but-reserved, are EXCLUDED from the "declared⇒emitted" test half, but ARE included in the "emitted⇒declared" test half (so if someone accidentally adds a call site, it won't escape the net).
- Offline — should NOT be included in `events/0` v1 since it has no `[:crosswake, ...]` event name lists. The facade has nothing to aggregate from it. If Offline events are desired later, add `event_names/0` to `Offline.Telemetry` as a separate PR (additive minor).

This resolution means the planner must decide: does `events/0` expose a `tier` key in the event_doc map? Or does it just list active events and expose a separate `reserved_events/0`? The simplest approach matching D-04 is to add a `tier: :active | :reserved` key alongside `event/description/measurements/metadata`.

---

## Standard Stack

### Core (no new deps — zero-dep constraint from Threadline.Telemetry moduledoc is precedent)

| Library | Available | Purpose | Why |
|---------|-----------|---------|-----|
| `:telemetry` | Already in mix.exs | Event emission and handler attachment | The existing dependency — all 4 confirmed emit sites use it |
| `ExUnit` | Already in mix.exs | Contract test infrastructure | Test-only |
| `:telemetry_test` | Available via `:telemetry` dep | `attach_event_handlers/2` for declared⇒emitted proof | Ships with the `:telemetry` hex package |

**Installation:** No new dependencies required. [VERIFIED: grep of mix.exs confirmed `:telemetry` is already a dep; `telemetry_test.erl` confirmed present at `packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl`]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ETS catch-all for emitted⇒declared | `:telemetry.attach` on `[:crosswake]` prefix catch-all | telemetry does not support prefix matching — must attach to exact names. ETS approach requires attaching to a known "all possible" superset handler at test start then collecting. |
| Manual event list for attach | Derive from `events/0` at test time | D-05 mandates runtime aggregation; tests should also derive from `events/0` dynamically. |

---

## Package Legitimacy Audit

> No new packages are introduced in this phase. All required functionality is covered by `:telemetry` (already a dep) and standard library. No audit needed.

---

## Architecture Patterns

### System Architecture Diagram

```
Host Application
      |
      | Application.get_env(:crosswake, :companions, [])
      v
Crosswake.Telemetry.events/0
      |
      +--- static refs (in-tree, allowed) --->  Threadline.Telemetry.event_names/0
      |                                          Sigra.Telemetry.event_names/0
      |                                          Chimeway.Telemetry.event_names/0
      |
      +--- runtime probe (function_exported?) --> [companion_module].telemetry_events/0
      |        (for each module in :companions list)
      |
      v
  [%{event: [...], tier: :active|:reserved,
     description: "...", measurements: [...], metadata: [...]}]
      |
      |   (used by)
      v
Crosswake.Telemetry.attach_default_logger/1
      |
      +--- calls :telemetry.attach/4 for each :active event in events/0
      |    handler id: "crosswake-default-logger"
      |    :exception events forced to :error regardless of configured level
      |    PII scrubbing: forbidden_metadata_keys from subsystem modules
      |
      v
   Host Logger (structured map in Logger metadata)

----------------------------------------------------

Test Layer — TELEM-04 Contract Test
      |
      +--- Side A: declared => emitted
      |    :telemetry_test.attach_event_handlers(self(), active_event_names)
      |    drive real code paths (RouteGate, Doctor, Plug.Threadline)
      |    assert_received for each declared :active event
      |
      +--- Side B: emitted => declared
           ETS table seeded at test start
           :telemetry.attach catch-all for each [:crosswake, ...] event seen
           after all code paths run: assert all captured events are in events/0
```

### Recommended Project Structure

```
lib/crosswake/
└── telemetry.ex          # new: Crosswake.Telemetry facade

lib/crosswake/companion.ex  # modified: add @callback telemetry_events/0 + @optional_callbacks

guides/
└── telemetry.md          # new: public docs

test/crosswake/proof/
└── phase133_telemetry_contract_test.exs  # new: TELEM-04 bidirectional proof

test/support/
└── stub_companion.ex     # modified: add StubTelemetryCompanion implementing telemetry_events/0

mix.exs                   # modified: extras + groups_for_extras + groups_for_modules
```

### Pattern 1: Runtime-Aggregating Facade

**What:** `events/0` calls each subsystem's `event_names/0` + `metadata_keys/0` at call time, building self-describing map structs.

**When to use:** Always — the facade must NOT cache results at compile time (D-05, stale-.beam risk).

```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex:684 pattern + D-04/D-05
@type event_doc :: %{
  event: [atom()],
  tier: :active | :reserved,
  description: String.t(),
  measurements: [atom()],
  metadata: [atom()]
}

@spec events() :: [event_doc()]
def events do
  core_events =
    [
      # Route gate spans (from route_gate.ex - confirmed emitting)
      %{event: [:crosswake, :companion, :dependency_check],
        tier: :active,
        description: "Emitted when RouteGate validates a companion's dependency is loaded. " <>
                     "Wraps validate_dependency/0 for each registered companion on each gated route evaluation.",
        measurements: [:system_time, :duration],
        metadata: [:companion_id, :route_id]},
      # ... etc for kill_switch, route_gate, validate_dependency, threadline.request
    ]

  companion_events =
    Application.get_env(:crosswake, :companions, [])
    |> Enum.flat_map(fn mod ->
      if function_exported?(mod, :telemetry_events, 0), do: mod.telemetry_events(), else: []
    end)

  in_tree_reserved =
    # Sigra + Chimeway event_names/0 as :reserved tier
    build_reserved_events()

  (core_events ++ in_tree_reserved ++ companion_events)
  |> Enum.uniq_by(& &1.event)
  |> Enum.sort_by(& &1.event)
end
```

[ASSUMED: exact function structure — pattern derived from codebase, not from a framework API]

### Pattern 2: Optional Behaviour Callback (EXTRACT-04 safe)

**What:** `telemetry_events/0` is added to `Crosswake.Companion` as an optional callback. Core probes via `function_exported?/3` inside a function body.

**When to use:** Always when merging companion-contributed events into the facade.

```elixir
# In lib/crosswake/companion.ex (addition to existing behaviour)
@doc """
Returns the telemetry events this companion emits, as event_doc() maps.
Optional — companions that emit no telemetry may omit this callback.
"""
@callback telemetry_events() :: [Crosswake.Telemetry.event_doc()]

@optional_callbacks telemetry_events: 0
```

**Critical:** Adding `telemetry_events: 0` to `@optional_callbacks` DOES change `behaviour_info(:callbacks)` — the Phase 129 freeze test at `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` has `@expected_callbacks MapSet.new([{:companion_id, 0}, {:enabled?, 1}, {:route_gated?, 2}, {:kill_switch_active?, 1}, {:validate_dependency, 0}, {:report_state, 0}])` and asserts `MapSet.equal?`. Adding an optional callback will NOT change `behaviour_info(:callbacks)` — Elixir's `behaviour_info(:callbacks)` returns only required callbacks. Optional callbacks appear in `behaviour_info(:optional_callbacks)`. The freeze test uses `behaviour_info(:callbacks)` so it will NOT be tripped by adding `@optional_callbacks telemetry_events: 0`. [VERIFIED: Elixir behaviour semantics — `@optional_callbacks` appear in `behaviour_info(:optional_callbacks)` not `:callbacks`]

This is a RELIEF from the risk flagged in the Summary. The Phase 129 freeze test does NOT need to be updated — optional callbacks are invisible to `behaviour_info(:callbacks)`.

### Pattern 3: `:telemetry_test.attach_event_handlers/2` for declared⇒emitted

**What:** Erlang function that attaches a handler sending `{event_name, ref, measurements, metadata}` messages to a given PID.

**Exact signature** (from `packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl`):

```erlang
-spec attach_event_handlers(DestinationPID, Events) -> reference() when
    DestinationPID :: pid(),
    Events :: [telemetry:event_name(), ...].
```

**Elixir usage pattern:**

```elixir
# In ExUnit test (async: false — Application.put_env is global)
ref = :telemetry_test.attach_event_handlers(self(), active_event_names)
on_exit(fn -> :telemetry.detach(ref) end)

# Drive the real code path (e.g., RouteGate for companion spans)
# ...

assert_received {[:crosswake, :companion, :dependency_check, :start], ^ref, measurements, metadata}
assert Map.has_key?(measurements, :system_time)
assert Map.has_key?(metadata, :companion_id)
```

[VERIFIED: telemetry_test.erl source at packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl]

### Pattern 4: ETS Catch-All for emitted⇒declared

**What:** For the reverse direction (ensuring nothing emits without being declared), attach a handler to ALL known declared events at test start and record every emission in an ETS table or Agent. After all code paths run, assert the set of captured event names is a subset of declared event names.

**Mechanism:**

```elixir
# Attach to every event in events/0 at test start
# Record each received event_name in an ETS table (or accumulate via assert_received)
# After driving all paths: captured_names -- declared_names == []

# Note: :telemetry does NOT support prefix matching.
# You must attach to each specific event name individually.
# Derive the full list at test time from Crosswake.Telemetry.events/0.
```

**Constraint:** The ETS approach requires `async: false` (shared global telemetry handler table) — same as Phase 130 and Phase 38 proof tests. The existing precedent is to save/restore `Application.put_env(:crosswake, :companions, ...)` in `setup/on_exit`. [VERIFIED: phase130_fail_closed_contract_test.exs pattern]

### Pattern 5: Stub Companion for Merge Proof (D-17)

**What:** A new `test/support` stub companion that implements `telemetry_events/0` (the optional callback) and is registered in test config.

**Pattern derived from** `phase130_fail_closed_contract_test.exs` — stubs are defined OUTSIDE the test module (nested module resolution issues). The stub name should NOT be an alias to any extracted companion (EXTRACT-03).

```elixir
# In test/support/stub_companion.ex (addition)
defmodule Crosswake.TestSupport.StubTelemetryCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_telemetry

  @impl true
  def enabled?(_config), do: true

  # Implement all 6 required callbacks with sensible stubs
  # ...

  # The optional 7th callback — proves the merge mechanism
  def telemetry_events do
    [%{event: [:crosswake, :stub_telemetry, :example, :start],
       tier: :active,
       description: "Stub telemetry event for testing the merge mechanism.",
       measurements: [:duration],
       metadata: [:companion_id]}]
  end
end
```

[ASSUMED: exact struct field names — dependent on final `event_doc()` typespec decided by planner]

### Pattern 6: `attach_default_logger/1` (modeled on Oban)

**What:** Attach a single named handler to all `:active` events from `events/0`. Forward to `Logger` as structured metadata.

**Signature (D-13):**

```elixir
@spec attach_default_logger(level_or_opts) :: :ok | {:error, :already_exists}
  when level_or_opts: Logger.level() | keyword()

@spec detach_default_logger() :: :ok | {:error, :not_found}
```

**Handler id:** `"crosswake-default-logger"` (stable string, quoted to avoid atom-table growth)

**Key behaviors:**
- Default `level: :info`, but `:exception` events ALWAYS emit at `:error` (D-14)
- Default `encode: false` — emit structured map into `Logger` metadata, let host formatter handle JSON (D-14)
- PII scrubbing: before logging metadata, drop keys in `forbidden_metadata_keys/0` from the relevant subsystem module. The default logger cannot know which subsystem module owns each event — the simplest approach is to collect the UNION of all forbidden keys from all subsystem `*.Telemetry` modules and apply that union as the scrub set.
- Double-attach: rely on `:telemetry`'s `{:error, :already_exists}` return — no custom guard needed (D-13)

[ASSUMED: exact implementation of forbidden-key union — approach inferred from D-15 guidance]

### Anti-Patterns to Avoid

- **Compile-time event lists in facade:** `@core_events [...]` as a module attribute is a stale-.beam footgun (see v7.0 SupportMatrix lesson in CONTEXT.md). `events/0` MUST call subsystem functions at call time.
- **Using `Code.ensure_loaded?` to probe companion support:** EXTRACT-04 violation. Use `function_exported?/3` inside a function body only.
- **Statically aliasing a companion module in `lib/`:** EXTRACT-03 violation. The facade must iterate the runtime `:companions` registry, never alias `Crosswake.Companions.Rulestead` etc.
- **Auto-attaching the logger from an application start callback:** D-13 / the "core never auto-attaches" invariant. The logger attachment belongs in the host's `Application.start/2` or supervision tree.
- **Prefix-matching telemetry handlers:** `:telemetry` does not support prefix matching. The catch-all for emitted⇒declared must attach to each specific event name.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test message delivery for events | Custom `send/receive` handler setup | `:telemetry_test.attach_event_handlers/2` | Already in the `:telemetry` dep; returns a ref for `^ref` pattern matching |
| Handler deduplication | Custom "already_exists" tracking | `:telemetry`'s `{:error, :already_exists}` return from `attach/4` | The library handles it; D-13 explicitly says not to add a custom guard |
| Span measurement injection | Manual `System.monotonic_time()` deltas | `:telemetry.span/3` | Already used by route_gate/doctor; auto-injects `system_time`, `duration` |

---

## Common Pitfalls

### Pitfall 1: Phase 129 Callback Freeze Test — NOT tripped by optional callbacks

**What goes wrong:** Developer fears adding `@optional_callbacks telemetry_events: 0` will break the Phase 129 freeze test (which asserts `behaviour_info(:callbacks)` equals the exact 6-element set).

**Why it doesn't happen:** Elixir's `behaviour_info(:callbacks)` returns ONLY required callbacks. Optional callbacks appear exclusively in `behaviour_info(:optional_callbacks)`. The freeze test is safe.

**Warning signs:** Any future addition of a required callback WILL trip the test. The 1-line annotation in the test is the canonical update procedure (change `@expected_callbacks` AND the `@callback` def in the same PR).

### Pitfall 2: Offline.Telemetry has no `event_names/0` and no actual emission

**What goes wrong:** The facade tries to call `Offline.Telemetry.event_names/0` but the function does not exist. The module also has no `:telemetry.execute` or `:telemetry.span` calls in `lib/` — it is a pure metadata-contract module.

**How to avoid:** Do NOT include `Offline.Telemetry` in the `events/0` aggregation chain. If/when Offline events are desired, add `event_names/0` to that module and a PR that adds actual emission calls.

**Warning signs:** `UndefinedFunctionError` at `Crosswake.Offline.Telemetry.event_names/0` if the facade calls it.

### Pitfall 3: Sigra/Chimeway events — declared but unemitted, must be :reserved tier

**What goes wrong:** Sigra.Telemetry has 14 event names and Chimeway.Telemetry has 10. None of them are actually emitted from `lib/` code (only the `execute/3` helper exists, never called). If these are placed in the "must-emit" tier of the TELEM-04 contract test, the test will fail permanently until Sigra/Chimeway start emitting — which is deferred (D-02 / deferred instrumentation).

**How to avoid:** Include Sigra/Chimeway events in `events/0` with `tier: :reserved`. The contract test's "declared⇒emitted" half checks only `:active` tier events. The "emitted⇒declared" half covers both tiers (any future emission will be caught).

**Warning signs:** TELEM-04 contract test timing out waiting for `assert_received` on Sigra/Chimeway events.

### Pitfall 4: Threadline :exception metadata is empty after PII guard

**What goes wrong:** The exception branch in `plug/threadline.ex` passes `%{kind: :error, reason: e}` through `Threadline.Telemetry.metadata/1`. Since `kind` and `reason` are NOT in `@metadata_keys = [:thread_id, :correlation_id, :route_id, :source]`, they are silently dropped. The event fires with empty metadata (no allowlisted keys present in the exception case).

**Why it happens:** The exception branch does not have access to `meta` (the thread_id/correlation_id from the start branch) in a recoverable way when an exception occurs before the metadata is built.

**How to avoid:** The guide must document this accurately: `:exception` events carry duration measurements but may carry empty metadata depending on when the exception occurs. Do NOT document `thread_id` as guaranteed-present in the exception event.

**Warning signs:** Guide claiming stop-metadata ⊇ start-metadata for threadline — this is true for :stop but less clear for :exception.

### Pitfall 5: `:telemetry.span/3` measurement semantics for start vs stop

**What goes wrong:** Documenting the wrong measurements for start vs stop events from `:telemetry.span/3`.

**Actual behavior:**
- `:start` event measurements = caller-supplied map MERGED WITH `%{system_time: System.system_time()}` — so measurements contain `system_time` plus any caller-provided keys.
- `:stop` event measurements = caller-supplied stop-map MERGED WITH `%{duration: native_time_diff}` — so measurements contain `duration` plus any caller-provided keys.
- `:exception` event measurements = `%{duration: native_time_diff}` MERGED WITH exception info — typically just duration.

For the 4 route_gate/doctor spans, the caller-supplied measurements at start are `%{companion_id: atom, route_id: binary | nil}` — BUT WAIT. Looking at the code: `route_gate.ex:139` passes `%{companion_id: companion.companion_id(), route_id: route.id}` as the START METADATA argument (the second arg to `:telemetry.span/3`). In `:telemetry.span/3`, the second arg is the start event's measurements, and the third arg is a function returning `{result, stop_metadata}`. So `companion_id` and `route_id` ARE measurements (not metadata) for the span start event.

**Correct span measurement mapping:**
- Start: `%{system_time: System.system_time(), companion_id: atom(), route_id: binary() | nil}`
- Stop: `%{duration: native_time_diff, companion_id: atom(), route_id: binary() | nil}` (stop fn returns additional metadata)

[VERIFIED: route_gate.ex:139-163 read directly]

### Pitfall 6: async: false required for TELEM-04 contract test

**What goes wrong:** `async: true` is set on the bidirectional contract test. Since telemetry handlers are registered globally and the test drives `Application.put_env(:crosswake, :companions, ...)`, concurrent tests will interfere.

**How to avoid:** `use ExUnit.Case, async: false` — same as Phase 130 proof test. Save/restore `:companions` in setup/on_exit.

---

## Code Examples

### `events/0` runtime aggregation structure

```elixir
# Source: derived from route_gate.ex + doctor.ex + plug/threadline.ex (all read directly)
# Core spans — confirmed emitting via :telemetry.span/3

@companion_span_measurements_start [:system_time, :companion_id, :route_id]
@companion_span_measurements_stop  [:duration, :companion_id, :route_id]
@companion_span_metadata           []  # telemetry.span metadata is in measurements for these spans

@core_active_events [
  %{
    event: [:crosswake, :companion, :dependency_check],
    tier: :active,
    description: "Emitted by RouteGate when validating a companion's optional dependency is loaded. " <>
                 "Wraps validate_dependency/0. Stop metadata includes result.",
    measurements: [:system_time, :companion_id, :route_id],  # :start
    stop_measurements: [:duration, :companion_id, :route_id],
    metadata: []
  },
  # Similarly for :kill_switch, :route_gate, :validate_dependency
  %{
    event: [:crosswake, :threadline, :request],
    tier: :active,
    description: "Emitted by Crosswake.Plug.Threadline for each HTTP request passing through the plug. " <>
                 "Start carries system_time; stop carries duration. Metadata: thread_id, correlation_id, route_id, source.",
    measurements: [:system_time],   # :start (plus :duration for :stop)
    metadata: [:thread_id, :correlation_id, :route_id, :source]
  }
]
```

[VERIFIED: route_gate.ex:139,191,219 + doctor.ex:573 + plug/threadline.ex:50-76 read directly]

### Phase 129 freeze test update pattern (when required callbacks change)

```elixir
# Source: test/crosswake/proof/phase129_companion_contract_freeze_test.exs (read directly)
# @optional_callbacks telemetry_events: 0 does NOT need this update.
# Only required @callback additions need this change.

@expected_callbacks MapSet.new([
  {:companion_id, 0},
  {:enabled?, 1},
  {:route_gated?, 2},
  {:kill_switch_active?, 1},
  {:validate_dependency, 0},
  {:report_state, 0}
  # telemetry_events is optional — does NOT appear here
])
```

[VERIFIED: phase129_companion_contract_freeze_test.exs read directly]

### Existing stub companion pattern (Phase 130 precedent)

```elixir
# Source: test/crosswake/proof/phase130_fail_closed_contract_test.exs (read directly)
# Pattern: define stub OUTSIDE test module (nested-module resolution issues)
# Pattern: async: false, save/restore Application.put_env in setup/on_exit

setup do
  original_companions = Application.get_env(:crosswake, :companions, [])
  on_exit(fn -> Application.put_env(:crosswake, :companions, original_companions) end)
  :ok
end
```

---

## mix.exs Docs Wiring (D-18 — grounded)

### Current state (read from mix.exs directly)

**`extras:`** — currently ends with `"guides/threadline.md"` (26 entries).

**`groups_for_modules:`** — currently 5 groups: Policy, Bridge, Manifest, Capabilities, "Companion Contract".

**`groups_for_extras:`** — currently 6 groups: Start, Adopt, "Runtime Owners", Truth, "Extension Authors", "Advanced/Companions".

### Required additions

**`extras:` addition:**
```elixir
"guides/telemetry.md"
```
Added after `"guides/threadline.md"` or at end — ordering within the Telemetry group is what matters.

**`groups_for_modules:` addition** (after "Companion Contract"):
```elixir
"Telemetry": [
  Crosswake.Telemetry,
  Crosswake.Threadline.Telemetry,
  Crosswake.Companions.Sigra.Telemetry,
  Crosswake.Companions.Chimeway.Telemetry,
  Crosswake.Offline.Telemetry
]
```

**`groups_for_extras:` addition** (after Truth group, before "Extension Authors"):
```elixir
"Telemetry": [
  "guides/telemetry.md"
]
```

[VERIFIED: mix.exs read directly — lines 101-179]

---

## Validation Architecture

> `workflow.nyquist_validation` not found in `.planning/config.json` (no config.json exists) — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir test framework) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TELEM-01 | `events/0` returns self-describing maps for all active events | unit + contract | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | ❌ Wave 0 |
| TELEM-01 | `events/0` aggregates stub companion events via `function_exported?` | integration | same proof file | ❌ Wave 0 |
| TELEM-02 | `guides/telemetry.md` exists on disk with required sections | unit (file existence + content) | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | ❌ Wave 0 |
| TELEM-02 | Telemetry group appears in mix.exs `groups_for_modules` | unit | same proof file | ❌ Wave 0 |
| TELEM-03 | `attach_default_logger/1` registers a handler; `detach_default_logger/0` removes it | unit | `mix test test/crosswake/telemetry_test.exs` | ❌ Wave 0 |
| TELEM-03 | Double-attach returns `{:error, :already_exists}` | unit | same | ❌ Wave 0 |
| TELEM-03 | Exception events are emitted at `:error` level regardless of config | unit | same | ❌ Wave 0 |
| TELEM-04 | Declared⇒emitted: every :active event in events/0 fires during test suite | bidirectional contract | `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs` | ❌ Wave 0 |
| TELEM-04 | Emitted⇒declared: every [:crosswake,...] event seen is in events/0 | bidirectional contract | same | ❌ Wave 0 |
| TELEM-04 | :reserved tier events are excluded from declared⇒emitted half | contract | same | ❌ Wave 0 |

### Test Seams (non-vacuousness details)

**Declared⇒emitted seam:**
- Use `:telemetry_test.attach_event_handlers(self(), active_names)` where `active_names` is the list of `:start`/`:stop`/`:exception` event names for all `:active` tier events.
- Drive `RouteGate.evaluate/4` with a stub companion registered to trigger `dependency_check`, `kill_switch`, `route_gate` spans.
- Drive `Doctor.run/1` with a stub companion to trigger `validate_dependency` span.
- Drive `Crosswake.Plug.Threadline.call/2` with a minimal `Plug.Conn` to trigger the threadline triplet.
- Assert each `assert_received {event_name, ^ref, measurements, metadata}`.
- Non-vacuousness: the test is non-vacuous because each code path is DRIVEN (the real implementation runs), not mocked away.

**Emitted⇒declared seam:**
- Attach handlers for ALL declared event names (both :active and :reserved) at test start.
- Run the same code paths.
- After the paths run, collect all received event names.
- Assert `captured_names -- all_declared_names == []`.
- Non-vacuousness: if a new `:telemetry.execute` call is added to any module with a `[:crosswake, ...]` prefix, it will be caught.

**Companion merge seam:**
- Register `StubTelemetryCompanion` (implements `telemetry_events/0`) via `Application.put_env`.
- Assert that `events/0` includes the stub's declared events.
- This is the "declared surface is what you get" assertion — non-vacuous because `function_exported?/3` is the real probe.

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase133_telemetry_contract_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase133_telemetry_contract_test.exs` — covers TELEM-01 declared surface, TELEM-02 guide existence, TELEM-04 bidirectional contract, companion merge proof
- [ ] `test/crosswake/telemetry_test.exs` — covers TELEM-03 attach/detach mechanics, double-attach, exception-level override
- [ ] `test/support/stub_companion.ex` — add `StubTelemetryCompanion` module (add to existing file)
- [ ] `lib/crosswake/telemetry.ex` — the facade module itself
- [ ] `guides/telemetry.md` — the public doc

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static `@event_names` compile-time lists in support_matrix | Runtime-called `event_names/0` fns | v7.0 (support matrix audit) | No stale-.beam drift |
| Custom handler-management code | `:telemetry`'s built-in `{:error, :already_exists}` for double-attach | Oban precedent | Simpler attach_default_logger/1 |
| Flat event name lists (non-self-describing) | Self-describing `%{event, description, measurements, metadata}` maps | `telemetry_registry` convention, this phase | Dashboard-ready, contract-testable |

**Deprecated/outdated:**
- Compile-time event lists in facade modules: see support_matrix.ex v7.0 lesson; flagged as stale-.beam drift risk.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `tier: :active \| :reserved` key approach for D-02 resolution | Architecture Patterns §Pattern 1 | Planner may choose a different D-02 resolution (separate `reserved_events/0` fn, or exclude Sigra/Chimeway entirely); no functional risk |
| A2 | Union of all subsystem `forbidden_metadata_keys/0` as the default logger scrub set | Pattern 6 | If subsystem forbidden-key sets overlap badly, a unified union may over-scrub. Planner can choose per-event scrub using the event name prefix to select the right module's forbidden list |
| A3 | `StubTelemetryCompanion.telemetry_events/0` return type matches final `event_doc()` typespec | Code Examples §Pattern 5 | Dependent on the exact typespec the planner defines |
| A4 | `mix test test/crosswake/telemetry_test.exs` as the TELEM-03 test path | Validation Architecture | New file location — planner confirms path |

**If this table is empty:** All other claims were verified directly from codebase reads or the telemetry_test.erl source.

---

## Open Questions

1. **D-02: tier key vs separate function for reserved events**
   - What we know: The planner has discretion (D-02 says "decide in planning"). Including a `tier` key in the event_doc map is the simplest approach and keeps `events/0` as the single source of truth. Alternatively, `events/0` returns only `:active` and a separate `reserved_events/0` returns the `:reserved` set.
   - What's unclear: Which shape better serves the DASH-01 dashboard consumer?
   - Recommendation: Include `tier` key in the event_doc map — one catalog, one call, consumer filters by tier. Simpler for dashboard DX.

2. **D-06: ship `spannable_events/0` or not**
   - What we know: Planner's discretion. It would group start/stop/exception triples by span prefix (e.g., `[:crosswake, :companion, :dependency_check]`) for dashboard ergonomics.
   - What's unclear: Whether DASH-01 will need this.
   - Recommendation: Skip for v1; add when the dashboard is built. Not needed to satisfy TELEM-01..04.

3. **Offline.Telemetry — should it be referenced at all in the facade?**
   - What we know: `Offline.Telemetry` has `metadata_keys/0` and `terminal_outcomes/0` but no `event_names/0` and no emission sites.
   - What's unclear: Whether to include it in `groups_for_modules: Telemetry` even though it can't contribute to `events/0`.
   - Recommendation: Include it in `groups_for_modules: Telemetry` for hexdocs discoverability (it IS a telemetry contract module), but do NOT include it in the `events/0` aggregation loop.

4. **Exception metadata for threadline — guide accuracy**
   - What we know: The `:exception` branch in `plug/threadline.ex` passes `%{kind: :error, reason: e}` which is dropped by the PII guard (keys not in @metadata_keys). The `:stop` event metadata IS correct.
   - What's unclear: Whether to fix the exception-branch metadata (pass the `meta` list through) or document the current behavior.
   - Recommendation: Document the current behavior accurately in the guide ("exception events carry timing measurements; metadata keys may be absent if the exception occurs before the thread context is established"). Fixing the implementation is out of scope for this phase.

---

## Environment Availability

> Phase 133 is pure code/config changes within the existing Elixir project. No external tools, databases, or services are required beyond the existing development environment.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `:telemetry` | All emission + test | ✓ | Already in mix.exs | — |
| `:telemetry_test` (ships with `:telemetry`) | TELEM-04 test seam | ✓ | Confirmed at packages/crosswake_rindle/deps/telemetry/src/ | — |
| ExDoc | guides/telemetry.md rendering | ✓ | Already in mix.exs dev deps | — |

---

## Security Domain

> `security_enforcement` not explicitly disabled — included per protocol.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | telemetry is diagnostic only — no auth context in events |
| V3 Session Management | no | session refs are in the forbidden_metadata_keys denylist |
| V4 Access Control | no | events have no access control surface |
| V5 Input Validation | yes | `forbidden_metadata_keys/0` denylist + `safe_value?/1` guard already implemented in all subsystem Telemetry modules |
| V6 Cryptography | no | no crypto in telemetry layer |

### Known Threat Patterns for `:telemetry` + Elixir Logger

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII leakage via telemetry metadata | Information Disclosure | `forbidden_metadata_keys/0` denylist (already implemented); default logger reuses this list |
| High-cardinality metadata causing memory pressure | Denial of Service | `safe_value?/1` binary-size guard (≤128 chars) already in subsystem modules; facade inherits |
| Handler registration collision (double-attach) | Tampering | `:telemetry`'s `{:error, :already_exists}` behavior; D-13 instructs NOT to add a custom guard that silently swallows this |
| Attaching telemetry handlers in core (auto-attach) | Elevation of Privilege | D-13/TELEM-03: core NEVER calls `attach_default_logger/1` automatically; host calls it explicitly |

---

## Sources

### Primary (HIGH confidence — read directly from codebase)

- `lib/crosswake/compatibility/route_gate.ex` — 3 confirmed `:telemetry.span/3` emission sites at lines 139, 191, 219; exact measurements/metadata extracted
- `lib/crosswake/doctor/doctor.ex:573` — 1 confirmed `:telemetry.span/3` emission site; metadata includes `result:` in stop
- `lib/crosswake/plug/threadline.ex:50-76` — 3 confirmed `Threadline.Telemetry.execute/3` calls; start/stop/exception; exception branch metadata loss confirmed
- `lib/crosswake/threadline/telemetry.ex` — `event_names/0`, `metadata_keys/0`, `forbidden_metadata_keys/0` verified
- `lib/crosswake/companions/sigra/telemetry.ex` — 14 declared events, 0 emission sites in lib/ confirmed by grep
- `lib/crosswake/companions/chimeway/telemetry.ex` — 10 declared events, 0 emission sites confirmed
- `lib/crosswake/offline/telemetry.ex` — no `event_names/0`, no `@event_names`, no emission sites confirmed
- `lib/crosswake/companion.ex` — 6 required callbacks; no `@optional_callbacks` yet; `behaviour_info(:callbacks)` vs `(:optional_callbacks)` semantics confirmed
- `lib/crosswake/companion_guard.ex` — `{:__aliases__}` ban on extracted companions; does NOT ban atom iteration; EXTRACT-04 placement rule confirmed
- `mix.exs:95-182` — full docs wiring: extras, groups_for_modules, groups_for_extras read directly
- `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — `@expected_callbacks` MapSet confirmed; optional callbacks safe
- `test/crosswake/proof/phase130_fail_closed_contract_test.exs` — stub companion pattern; async: false; Application.put_env save/restore pattern
- `test/support/stub_companion.ex` — existing stub companion shape; addition point for StubTelemetryCompanion
- `packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl` — `attach_event_handlers/2` exact signature; message shape `{event, ref, measurements, metadata}` confirmed

---

## Metadata

**Confidence breakdown:**
- Seed set (emitting events): HIGH — direct grep + file reads confirmed exact call sites and measurement/metadata shapes
- Declared-but-unemitted inventory: HIGH — grep across all lib/ files for `:telemetry.*` and `Telemetry.execute` confirmed zero non-self-call emission in Sigra/Chimeway/Offline
- Offline.Telemetry gap: HIGH — no `event_names/0`, no emission confirmed
- Optional callback semantics: HIGH — Elixir behaviour_info(:callbacks) vs (:optional_callbacks) is well-known; Phase 129 test read directly
- `:telemetry_test.attach_event_handlers/2`: HIGH — ERL source read directly
- `attach_default_logger/1` implementation approach: MEDIUM — modeled on D-13 guidance + Oban pattern description; exact Oban implementation not read (deferred — training knowledge for Oban API)
- mix.exs wiring: HIGH — read directly

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 (stable ecosystem; only codebase changes would invalidate)
