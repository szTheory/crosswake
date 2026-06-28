# Phase 133: Telemetry Public API - Pattern Map

**Mapped:** 2026-06-28
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/telemetry.ex` | service/facade | request-response (runtime aggregation) | `lib/crosswake/threadline/telemetry.ex` | role-match |
| `lib/crosswake/companion.ex` | behaviour contract | — (declaration only) | existing callbacks in same file | exact |
| `test/crosswake/proof/phase133_telemetry_contract_test.exs` | test/proof | event-driven + CRUD | `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` + `phase130_fail_closed_contract_test.exs` | role-match |
| `test/support/stub_companion.ex` | test fixture | — | `test/support/stub_companion.ex` (existing stubs) | exact |
| `guides/telemetry.md` | documentation | — | `guides/threadline.md` | role-match |
| `mix.exs` | config | — | same file lines 95–181 | exact |

---

## Pattern Assignments

### `lib/crosswake/telemetry.ex` (new facade module)

**Analogs:**
- `lib/crosswake/threadline/telemetry.ex` — moduledoc framing ("NOT an APM, NOT distributed tracing, NOT a generic event bus"), `event_names/0`, `metadata_keys/0`, `forbidden_metadata_keys/0`, `execute/3` pattern
- `lib/crosswake/companions/sigra/telemetry.ex` — `@event_names` + `metadata_keys/0` + `forbidden_metadata_keys/0` shape; fullest PII denylist

**Module declaration + moduledoc framing** (mirror `lib/crosswake/threadline/telemetry.ex` lines 1–22):
```elixir
defmodule Crosswake.Telemetry do
  @moduledoc """
  Canonical public API for Crosswake telemetry events.

  `events/0` returns the runtime-aggregated catalog of every `:telemetry`
  event Crosswake emits across companion spans, doctor, threadline, sigra,
  and chimeway subsystems. Call it at runtime — not at compile time.

  Telemetry events are **public API**: additions are non-breaking minors;
  removals or renames are breaking majors requiring a semver major bump.

  **Diagnostic-only.** This module is NOT an APM replacement, NOT a
  distributed tracing framework, and NOT a generic event bus. It augments
  host observability by exposing a typed, low-cardinality, PII-free event
  catalog. It coexists with any host-side observability pipeline.

  Zero new dependencies — only `:telemetry`, already a project dependency.
  """
```

**`event_doc` typespec** (D-04 + RESEARCH.md §Pattern 1):
```elixir
@type event_doc :: %{
  event: [atom()],
  tier: :active | :reserved,
  description: String.t(),
  measurements: [atom()],
  metadata: [atom()]
}
```

**`events/0` runtime aggregation** (D-05 — NO module attribute, must call subsystem fns at call time):
```elixir
@spec events() :: [event_doc()]
def events do
  core_active = build_active_events()
  reserved = build_reserved_events()

  companion_events =
    Application.get_env(:crosswake, :companions, [])
    |> Enum.flat_map(fn mod ->
      if function_exported?(mod, :telemetry_events, 0), do: mod.telemetry_events(), else: []
    end)

  (core_active ++ reserved ++ companion_events)
  |> Enum.uniq_by(& &1.event)
  |> Enum.sort_by(& &1.event)
end
```

**CRITICAL anti-pattern to avoid:** Do NOT write `@core_events [...]` as a module attribute. That is a stale-.beam footgun (see v7.0 SupportMatrix lesson, RESEARCH.md §Anti-Patterns). All event maps must be built inside `build_active_events/0` (a private function, called at runtime).

**Core active events** (the 5 confirmed emitting span prefixes — each expanded to `:start`/`:stop`/`:exception`; see RESEARCH.md §Grounded Seed Set):

| Span prefix | Emitter | Start measurements | Stop measurements | Metadata |
|-------------|---------|-------------------|-------------------|----------|
| `[:crosswake, :companion, :dependency_check]` | `route_gate.ex:139` | `[:system_time, :companion_id, :route_id]` | `[:duration, :companion_id, :route_id]` | `[]` |
| `[:crosswake, :companion, :kill_switch]` | `route_gate.ex:191` | same | same | `[]` |
| `[:crosswake, :companion, :route_gate]` | `route_gate.ex:219` | same | same | `[]` |
| `[:crosswake, :companion, :validate_dependency]` | `doctor.ex:573` | `[:system_time, :companion_id, :route_id]` | `[:duration, :companion_id, :route_id, :result]` | `[]` |
| `[:crosswake, :threadline, :request]` | `plug/threadline.ex:52-69` | `[:system_time]` | `[:duration]` | `[:thread_id, :correlation_id, :route_id, :source]` |

**Note on `:telemetry.span/3` measurement semantics** (RESEARCH Pitfall 5): For the 4 companion spans, `companion_id` and `route_id` are passed as the START MEASUREMENTS argument (second arg to `:telemetry.span/3`), not as metadata. The event_doc `measurements` field for these spans includes `companion_id`/`route_id`.

**Reserved events** (D-02 — declared-but-unemitted Sigra + Chimeway):
```elixir
defp build_reserved_events do
  # Sigra: 14 event_names/0 entries (lib/crosswake/companions/sigra/telemetry.ex lines 10-25)
  # Chimeway: 10 event_names/0 entries (lib/crosswake/companions/chimeway/telemetry.ex lines 10-21)
  # tier: :reserved — EXCLUDED from declared=>emitted half of TELEM-04 contract test
  Enum.map(
    Crosswake.Companions.Sigra.Telemetry.event_names() ++
    Crosswake.Companions.Chimeway.Telemetry.event_names(),
    fn name ->
      %{event: name, tier: :reserved, description: "", measurements: [], metadata: []}
    end
  )
end
```

**DO NOT include `Offline.Telemetry`** in the aggregation chain. It has no `event_names/0` function and no emission sites — calling it would raise `UndefinedFunctionError` (RESEARCH Pitfall 2).

**Static refs to in-tree `*.Telemetry` modules are allowed** (D-08). Only extracted companion modules must be probed via `function_exported?/3`.

**`attach_default_logger/1`** (D-13/D-14, modeled on Oban pattern):
```elixir
@spec attach_default_logger(Logger.level() | keyword()) :: :ok | {:error, :already_exists}
def attach_default_logger(level_or_opts \\ []) do
  opts = normalize_opts(level_or_opts)
  active_events = events() |> Enum.filter(& &1.tier == :active) |> Enum.map(& &1.event)

  :telemetry.attach_many(
    "crosswake-default-logger",
    active_events,
    &handle_event/4,
    opts
  )
end

@spec detach_default_logger() :: :ok | {:error, :not_found}
def detach_default_logger do
  :telemetry.detach("crosswake-default-logger")
end
```

Key behaviors in the handler (D-14):
- `:exception` events ALWAYS log at `:error` regardless of configured `:level`
- Default `encode: false` — emit structured map into `Logger.metadata/1`, let host formatter handle JSON
- PII scrubbing: union of `forbidden_metadata_keys/0` from all subsystem modules (Threadline + Sigra + Chimeway) applied before logging

**`forbidden_metadata_keys/0` union** (D-15 — reuse existing denylist fns rather than duplicating):
```elixir
defp all_forbidden_keys do
  (Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++
   Crosswake.Companions.Sigra.Telemetry.forbidden_metadata_keys() ++
   Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys())
  |> Enum.uniq()
end
```

---

### `lib/crosswake/companion.ex` (modification — add optional callback)

**Analog:** same file, existing callbacks (lines 53–128)

**Addition pattern** (after the last `@callback report_state/0` at line 128):
```elixir
@doc """
Returns the telemetry events this companion declares, as `Crosswake.Telemetry.event_doc()` maps.

This callback is optional. Companions that emit no telemetry events may omit it.
When implemented, returned events are merged into `Crosswake.Telemetry.events/0`
at call time and contribute to the published telemetry contract.
"""
@callback telemetry_events() :: [Crosswake.Telemetry.event_doc()]

@optional_callbacks telemetry_events: 0
```

**SAFE — Phase 129 freeze test is NOT tripped.** Elixir's `behaviour_info(:callbacks)` returns only required callbacks; optional callbacks appear in `behaviour_info(:optional_callbacks)`. The existing `@expected_callbacks` MapSet at `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` line 21–28 does NOT need to change (RESEARCH.md §Pitfall 1 + Pattern 2).

**`@optional_callbacks` placement:** Must appear after all `@callback` declarations. The directive `@optional_callbacks telemetry_events: 0` is a single addition.

---

### `test/crosswake/proof/phase133_telemetry_contract_test.exs` (new proof test)

**Analogs:**
- `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — `ProofAssertions.stable_id_message/7` pattern, moduledoc structure, hermetic lane self-assertion at bottom
- `test/crosswake/proof/phase130_fail_closed_contract_test.exs` — `async: false`, `Application.put_env` save/restore in `setup/on_exit`, stub companion registration pattern

**Module header** (mirror phase130 pattern):
```elixir
defmodule Crosswake.Proof.Phase133TelemetryContractTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 133 TELEM-01..04.

  Proves bidirectional declared<=>emitted contract for Crosswake.Telemetry.events/0.
  async: false — Application.put_env(:crosswake, :companions, ...) is a shared global key.
  """

  use ExUnit.Case, async: false

  alias Crosswake.TestSupport.ProofAssertions
```

**Setup / teardown** (mirror phase130 lines 187–201):
```elixir
  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
    end)

    :ok
  end
```

**Declared⇒emitted test** (D-16 Side A — `:telemetry_test.attach_event_handlers/2`):
```elixir
  test "TELEM-04 Side A: every :active event in events/0 is emitted when code paths are driven" do
    active_names =
      Crosswake.Telemetry.events()
      |> Enum.filter(& &1.tier == :active)
      |> Enum.flat_map(fn %{event: prefix} ->
        [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
      end)

    ref = :telemetry_test.attach_event_handlers(self(), active_names)
    on_exit(fn -> :telemetry.detach(ref) end)

    # Drive each emitting code path here (RouteGate.evaluate/4, Doctor.run/1,
    # Plug.Threadline.call/2) — see RESEARCH.md §Test Seams for setup details.
    # Each code path produces assert_received {event_name, ^ref, measurements, metadata}.
  end
```

**Note on `:telemetry_test.attach_event_handlers/2` message shape** (from `packages/crosswake_rindle/deps/telemetry/src/telemetry_test.erl`):
```elixir
# Received message shape:
{event_name, ref, measurements, metadata}
# Pattern match:
assert_received {[:crosswake, :companion, :dependency_check, :start], ^ref, measurements, _meta}
assert Map.has_key?(measurements, :system_time)
```

**Emitted⇒declared test** (D-16 Side B — ETS catch-all):
```elixir
  test "TELEM-04 Side B: every [:crosswake,...] event emitted is in events/0" do
    all_declared_names =
      Crosswake.Telemetry.events()
      |> Enum.flat_map(fn %{event: prefix} ->
        [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
      end)

    ref = :telemetry_test.attach_event_handlers(self(), all_declared_names)
    on_exit(fn -> :telemetry.detach(ref) end)

    # Drive all code paths, then collect received events.
    # Assert captured_names -- all_declared_names == []
  end
```

**Companion merge test** (D-17 — stub companion registered in test config):
```elixir
  test "TELEM-01 companion merge: stub companion's declared events appear in events/0" do
    Application.put_env(:crosswake, :companions,
      [Crosswake.TestSupport.StubTelemetryCompanion])

    result = Crosswake.Telemetry.events()
    stub_events = Crosswake.TestSupport.StubTelemetryCompanion.telemetry_events()

    for event_doc <- stub_events do
      assert Enum.any?(result, fn e -> e.event == event_doc.event end),
             "stub companion event #{inspect(event_doc.event)} must appear in events/0"
    end
  end
```

**:reserved tier exclusion assertion**:
```elixir
  test "TELEM-04 :reserved tier events are excluded from declared=>emitted check" do
    reserved_events =
      Crosswake.Telemetry.events()
      |> Enum.filter(& &1.tier == :reserved)

    # Sigra has 14, Chimeway has 10 — none should be in the :active tier
    assert length(reserved_events) >= 24,
           "expected at least 24 reserved events (Sigra 14 + Chimeway 10)"

    # Confirm none of the reserved events share a prefix with active events
    active_prefixes =
      Crosswake.Telemetry.events()
      |> Enum.filter(& &1.tier == :active)
      |> MapSet.new(& &1.event)

    for %{event: event} <- reserved_events do
      refute MapSet.member?(active_prefixes, event),
             "reserved event #{inspect(event)} must not also appear in :active tier"
    end
  end
```

**Hermetic lane self-assertion** (copy verbatim from phase130 line 324–329):
```elixir
  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 133 telemetry contract proof file must not carry @moduletag: tags — it runs untagged"
  end
```

---

### `test/support/stub_companion.ex` (modification — add `StubTelemetryCompanion`)

**Analog:** same file (lines 89–151 `StubCompanion` pattern) + `phase130_fail_closed_contract_test.exs` lines 1–6 (comment header)

**Addition at end of file** (add as a new module, do NOT modify existing stubs):
```elixir
defmodule Crosswake.TestSupport.StubTelemetryCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_telemetry

  @impl true
  def enabled?(_config), do: true

  @impl true
  def route_gated?(_route, _context), do: :pass

  @impl true
  def kill_switch_active?(_context), do: false

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_telemetry,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end

  # Optional callback — proves the merge mechanism (D-17).
  # NOT @impl true (it's optional — no @impl for optional callbacks).
  def telemetry_events do
    [%{
      event: [:crosswake, :stub_telemetry, :example],
      tier: :active,
      description: "Stub telemetry event for testing the companion merge mechanism (TELEM-04 D-17).",
      measurements: [:duration],
      metadata: [:companion_id]
    }]
  end
end
```

**Key patterns from existing stubs:**
- `@moduledoc false` — all stubs in this file use it
- All 6 required `@impl true` callbacks present before the optional one
- Optional callback has NO `@impl true` annotation
- `companion_id` uses `:stub_telemetry` (not an alias to any extracted companion — avoids EXTRACT-03)

---

### `guides/telemetry.md` (new guide)

**Analogs:**
- `guides/threadline.md` lines 1–19 — "What X Is" / "What X Is NOT" structure; the exact "NOT an APM/tracing/event-bus" framing (mirror this verbatim for the telemetry facade)
- `lib/crosswake/threadline/telemetry.ex` lines 8–22 — moduledoc framing sentences (adapt for guide prose)

**Required section order** (D-19, brandbook §14 concept-page order):

```markdown
# Telemetry

## What Crosswake Telemetry Is

[definition — one paragraph]

## What Crosswake Telemetry Is NOT

[non-goals by design, not deferred features — mirror threadline.md structure]
- **Not an APM / observability platform.**
- **Not a distributed tracing framework.**
- **Not a generic event bus.**
- **Not a source of PII.**

## Semver Contract

[D-03 statement — "additions are non-breaking minors; removals/renames are breaking majors"]

## Events

[table of all :active events with measurements + metadata]
[event names in JetBrains Mono code blocks]

## Reserved Events

[Sigra / Chimeway events that are declared but not yet emitted — brief note]

## Attaching the Default Logger

[minimal attach_default_logger/1 example]

## Failure Modes

[brandbook §6 — failure-modes-first; what happens if no companions configured, double-attach, etc.]

## Security and PII

[forbidden_metadata_keys denylist, safe_value? guard]

## Testing

[how to use :telemetry_test.attach_event_handlers/2 in host test suites]

## Related

[links to companion_contract.md, threadline.md]
```

**Forbidden words** (brandbook §4): seamless, magic, plugin, powerful, universal, auto_*. Do not use.

**Log/CLI prefix** (D-20): `[crosswake]`

**Event name formatting** (D-19): Use `` `[:crosswake, :companion, :dependency_check, :start]` `` in JetBrains Mono (backtick code spans in Markdown).

---

### `mix.exs` (modification — docs wiring, D-18)

**Analog:** same file lines 95–181

**`extras:` addition** (after `"guides/threadline.md"` at line 126):
```elixir
"guides/telemetry.md"
```

**`groups_for_modules:` addition** (after `"Companion Contract"` block ending at line 139, before `]`):
```elixir
"Telemetry": [
  Crosswake.Telemetry,
  Crosswake.Threadline.Telemetry,
  Crosswake.Companions.Sigra.Telemetry,
  Crosswake.Companions.Chimeway.Telemetry,
  Crosswake.Offline.Telemetry
]
```

**Note:** `Crosswake.Offline.Telemetry` IS included in `groups_for_modules` for hexdocs discoverability (it is a telemetry contract module) but is NOT included in `events/0` aggregation (no `event_names/0`, no emission sites).

**`groups_for_extras:` addition** (after `Truth` group, before `"Extension Authors"` at line 169):
```elixir
"Telemetry": [
  "guides/telemetry.md"
]
```

---

## Shared Patterns

### Runtime companion probe (EXTRACT-04 safe)
**Source:** `lib/crosswake/companion_guard.ex` constraint + D-08 decision
**Apply to:** `lib/crosswake/telemetry.ex` `events/0` function body
```elixir
# CORRECT — function_exported?/3 inside a function body
if function_exported?(mod, :telemetry_events, 0), do: mod.telemetry_events(), else: []

# WRONG — Code.ensure_loaded? is EXTRACT-04 violation
# WRONG — Statically aliasing Crosswake.Companions.Rulestead etc.
```

### `Application.put_env` save/restore
**Source:** `test/crosswake/proof/phase130_fail_closed_contract_test.exs` lines 187–201
**Apply to:** `test/crosswake/proof/phase133_telemetry_contract_test.exs`
```elixir
setup do
  original_companions = Application.get_env(:crosswake, :companions, [])
  on_exit(fn -> Application.put_env(:crosswake, :companions, original_companions) end)
  :ok
end
```

### `ProofAssertions.stable_id_message/7`
**Source:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` lines 66–75
**Apply to:** all assertions in phase133 proof test
```elixir
ProofAssertions.stable_id_message(
  "proof.telem_01.events.shape",           # stable_id
  "human-readable description",             # description
  "Crosswake.Telemetry.events/0",          # subject
  "actual was #{inspect(actual)}",          # failure detail
  "lib/crosswake/telemetry.ex",            # file hint
  "fix description",                        # fix hint
  :merge_blocking                           # severity
)
```

### Hermetic lane self-assertion (bottom of every proof file)
**Source:** `test/crosswake/proof/phase130_fail_closed_contract_test.exs` lines 324–329
**Apply to:** `test/crosswake/proof/phase133_telemetry_contract_test.exs` (last test in file)
```elixir
test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
  source = File.read!(__ENV__.file)
  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source), "..."
end
```

### PII forbidden-key denylist
**Source:** `lib/crosswake/threadline/telemetry.ex` lines 41–62 (20 keys) + `lib/crosswake/companions/sigra/telemetry.ex` lines 48–68 (19 keys)
**Apply to:** `lib/crosswake/telemetry.ex` default logger handler — collect union of all subsystem `forbidden_metadata_keys/0` return values, apply before logging metadata.

---

## No Analog Found

All files have analogs. No gaps.

---

## Critical Gotchas

| Gotcha | File | Resolution |
|--------|------|------------|
| `Offline.Telemetry` has no `event_names/0` | `lib/crosswake/telemetry.ex` | Do NOT call `Offline.Telemetry.event_names/0` — UndefinedFunctionError |
| Sigra (14) + Chimeway (10) events are declared-but-unemitted | `lib/crosswake/telemetry.ex` | Assign `tier: :reserved`; exclude from declared⇒emitted TELEM-04 half |
| `async: false` required | `test/.../phase133_telemetry_contract_test.exs` | `Application.put_env` is global; share save/restore with `on_exit` |
| `:telemetry_test.attach_event_handlers/2` returns a `reference()` for `^ref` matching | proof test | Use `ref = :telemetry_test.attach_event_handlers(self(), names)` |
| `:telemetry.span/3` puts `companion_id`/`route_id` in MEASUREMENTS not metadata | guide + event_doc | Document measurements per event correctly; stop-metadata ≠ start-metadata for threadline `:exception` |
| Phase 129 freeze test is NOT tripped by `@optional_callbacks` | `lib/crosswake/companion.ex` | `behaviour_info(:callbacks)` omits optional callbacks; safe to add |
| Stub's optional callback must NOT have `@impl true` | `test/support/stub_companion.ex` | Optional callbacks use no `@impl` annotation |
| CompanionGuard bans `{:__aliases__}` refs to extracted companions | `lib/crosswake/telemetry.ex` | Iterate `:companions` list via `function_exported?/3`; never alias `Crosswake.Companions.Rulestead` |

---

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/proof/`, `test/support/`, `guides/`, `mix.exs`
**Files scanned:** 10 source files read directly
**Pattern extraction date:** 2026-06-28
