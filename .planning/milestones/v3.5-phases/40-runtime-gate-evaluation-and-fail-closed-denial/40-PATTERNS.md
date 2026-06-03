# Phase 40: Runtime Gate Evaluation And Fail-Closed Denial - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 3 (2 modified, 1 new)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/compatibility/route_gate.ex` | service (evaluation pipeline) | request-response, event-driven | self — extend existing module | exact (in-place extension) |
| `lib/crosswake/shell/denial.ex` | model (denial envelope) | transform | self — extend existing module | exact (in-place extension) |
| `test/crosswake/proof/phase40_gate_evaluation_test.exs` | test (hermetic proof) | request-response | `test/crosswake/proof/phase38_companion_contract_test.exs` | exact |

---

## Pattern Assignments

### `lib/crosswake/compatibility/route_gate.ex` — Decision typespec + gate evaluation pipeline

**Analog:** self (in-place extension of the existing module)

**Current `Decision.t()` typespec** (`route_gate.ex` lines 18–24) — broaden `transition`:
```elixir
# CURRENT — lines 18-24
@type t :: %__MODULE__{
        route_id: String.t(),
        status: :allow | :deny,
        denial: Denial.t() | nil,
        denials: [Denial.t()],
        transition: :activate | :halt | :stay_put
      }

# PHASE 40 CHANGE — add {:redirect, atom()} union arm
@type t :: %__MODULE__{
        route_id: String.t(),
        status: :allow | :deny,
        denial: Denial.t() | nil,
        denials: [Denial.t()],
        transition: :activate | :halt | :stay_put | {:redirect, atom()}
      }
```

**Current `evaluate/4` body** (`route_gate.ex` lines 33–52) — shows where new prepend step inserts:
```elixir
def evaluate(%Root{} = manifest, route_id, %Target{} = target, opts) do
  route = Map.get(manifest.routes, route_id)

  findings =
    manifest
    |> Compatibility.route_findings(route_id, target, opts)
    |> remap_commerce_corridor_findings(route)
    |> prepend_commerce_corridor_findings(route, manifest)   # <-- gate step inserts BEFORE this

  denials = Enum.map(findings, &Compatibility.finding_to_denial(&1, Keyword.put(opts, :route_id, route_id)))
  status = if(denials == [], do: :allow, else: :deny)

  %Decision{
    route_id: route_id,
    status: status,
    denial: List.first(denials),
    denials: denials,
    transition: transition_for(status, opts)    # <-- update to transition_for(status, route, opts)
  }
end
```

**`prepend_commerce_corridor_findings/3` pattern** (`route_gate.ex` lines 64–74) — the exact structural template for `prepend_gate_evaluation_findings/3`:
```elixir
# Two-clause pattern: RouteEntry match + nil/other fallback
defp prepend_commerce_corridor_findings(findings, %RouteEntry{} = route, %Root{} = manifest) do
  generated =
    []
    |> maybe_add_finding(commerce_corridor_undeclared(route, manifest))
    |> maybe_add_finding(commerce_corridor_runtime_incompatible(route, manifest))
    |> maybe_add_finding(commerce_corridor_policy_blocked(route, manifest))

  generated ++ findings
end

defp prepend_commerce_corridor_findings(findings, _route, _manifest), do: findings
```

**`maybe_add_finding/2`** (`route_gate.ex` lines 182–183) — nil-safe accumulator; reuse unchanged:
```elixir
defp maybe_add_finding(acc, nil), do: acc
defp maybe_add_finding(acc, finding), do: [finding | acc]
```

**Current `transition_for/2`** (`route_gate.ex` lines 54–62) — must become `transition_for/3`:
```elixir
# CURRENT — signature (status, opts)
defp transition_for(:allow, _opts), do: :activate

defp transition_for(:deny, opts) do
  if Keyword.get(opts, :activation_source) == :in_app_navigation do
    :stay_put
  else
    :halt
  end
end

# PHASE 40 REPLACEMENT — signature (status, route, opts)
# IMPORTANT: {:fallback_phoenix, id} clause must precede the general :deny clause
defp transition_for(:allow, _route, _opts), do: :activate

defp transition_for(:deny, %RouteEntry{on_unavailable: {:fallback_phoenix, route_id}}, _opts) do
  {:redirect, route_id}
end

defp transition_for(:deny, _route, opts) do
  if Keyword.get(opts, :activation_source) == :in_app_navigation do
    :stay_put
  else
    :halt
  end
end
```

**Telemetry span pattern** (`doctor.ex` lines 522–530) — wrap each companion callback call with `:telemetry.span/3`:
```elixir
result =
  :telemetry.span(
    [:crosswake, :companion, :validate_dependency],
    %{companion_id: companion_id, route_id: nil},
    fn ->
      dep_result = companion.validate_dependency()
      {dep_result, %{companion_id: companion_id, route_id: nil, result: dep_result}}
    end
  )
```
Apply this pattern for:
- `[:crosswake, :companion, :kill_switch]` wrapping `companion.kill_switch_active?(target)`
- `[:crosswake, :companion, :route_gate]` wrapping `companion.route_gated?(route, target)`
Use `%{companion_id: companion.companion_id(), route_id: route.id}` as the metadata map.

**Companion registry dispatch pattern** (`doctor.ex` lines 514–520) — read registry + per-companion config:
```elixir
companions = Application.get_env(:crosswake, :companions, [])

Enum.flat_map(companions, fn companion ->
  companion_id = companion.companion_id()
  config_map = Application.get_env(:crosswake, companion_id, %{})
  enabled = companion.enabled?(config_map)
  # ...
end)
```
For gate evaluation, filter to `enabled == true` companions before iterating.

**Direct `Denial.new/1` for `:gate_denied`** (from D-03/D-07 in CONTEXT.md) — bypass `finding_to_denial/2`:
```elixir
Denial.new(
  reason: :gate_denied,
  message: "route activation denied: gate #{route.gated_by} is inactive",
  route_id: route.id,
  details: %{
    "flag_key"     => Atom.to_string(route.gated_by),
    "reason"       => "DISABLED",
    "variant"      => "off",
    "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
  }
)
```

**Direct `Denial.new/1` for `:kill_switch_active`** (from D-08 in CONTEXT.md):
```elixir
Denial.new(
  reason: :kill_switch_active,
  message: "route activation blocked: kill switch is active",
  route_id: route.id,
  details: %{
    "companion_id" => Atom.to_string(companion.companion_id())
  }
)
```

**Important pipeline note:** Gate/kill-switch denials are produced as `Denial.t()` directly and prepended to `denials` (not `findings`). The `evaluate/4` pipeline will need to restructure slightly: run the finding-to-denial mapping first, then prepend gate denials to the resulting `denials` list. Or, equivalently, `prepend_gate_evaluation_findings/3` returns `Denial.t()` structs in a separate accumulator that is merged after `Enum.map(findings, &finding_to_denial/2)`. The critical constraint (from D-Claude's Discretion) is that `flag_key` and `evaluated_at` stay in RouteGate scope — do not thread them through `Finding.t()` or `finding_to_denial/2`.

**Nil-route guard for unknown route_id** (from `prepend_commerce_corridor_findings/3` fallback clause, line 74):
```elixir
# First clause — nil route guard (unknown route_id skips gate evaluation)
defp prepend_gate_evaluation_findings(findings, nil, _target), do: findings
# Second clause — non-gated route guard
defp prepend_gate_evaluation_findings(findings, %RouteEntry{gated_by: nil}, _target), do: findings
# Third clause — gated route (performs kill-switch then gate check)
defp prepend_gate_evaluation_findings(findings, %RouteEntry{} = route, %Target{} = target) do
  # ... companion dispatch
end
```

---

### `lib/crosswake/shell/denial.ex` — Extend `@reasons` and `reason` typespec

**Analog:** self (in-place extension)

**Current `@reasons` list** (`denial.ex` lines 8–17):
```elixir
@reasons [
  :compatibility_mismatch,
  :undeclared_capability,
  :unavailable_capability,
  :commerce_corridor,
  :origin_denied,
  :inactive_route,
  :external_entry_denied,
  :pack_incompatible
]
```
Add `:gate_denied` and `:kill_switch_active` to the end of this list.

**Current `reason` typespec** (`denial.ex` lines 22–30):
```elixir
@type reason ::
        :compatibility_mismatch
        | :undeclared_capability
        | :unavailable_capability
        | :commerce_corridor
        | :origin_denied
        | :inactive_route
        | :external_entry_denied
        | :pack_incompatible
```
Append `| :gate_denied | :kill_switch_active` union arms.

**`Denial.new/1` signature** (`denial.ex` lines 46–61) — the builder to call from RouteGate:
```elixir
def new(attrs) when is_list(attrs) do
  reason = Keyword.fetch!(attrs, :reason)
  details = Keyword.get(attrs, :details, %{})
  recovery = Keyword.get(attrs, :recovery, %{})
  {details, recovery} = ensure_commerce_corridor_payload(reason, details, recovery)

  struct!(__MODULE__, %{
    reason: reason,
    code: Keyword.get(attrs, :code, Atom.to_string(reason)),
    message: Keyword.fetch!(attrs, :message),
    hint: Keyword.get(attrs, :hint),
    route_id: Keyword.get(attrs, :route_id),
    details: details,
    recovery: recovery
  })
end
```
Note: `ensure_commerce_corridor_payload/3` has a catch-all clause (`denial.ex` line 99) that passes `:gate_denied` and `:kill_switch_active` through unchanged — no additional clause needed.

**`to_map/1`** (`denial.ex` lines 63–76) — already handles string map values via `Types.to_map/1`; pre-serialized ISO8601 string in `details["evaluated_at"]` passes through as-is:
```elixir
def to_map(%__MODULE__{} = denial) do
  %{
    "reason" => Atom.to_string(denial.reason),
    "code" => denial.code,
    "message" => denial.message,
    "route_id" => denial.route_id,
    "hint" => denial.hint,
    "details" => Types.to_map(denial.details),
    "recovery" => Types.to_map(denial.recovery)
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) or value == %{} end)
  |> Map.new()
end
```

---

### `test/crosswake/proof/phase40_gate_evaluation_test.exs` — New hermetic proof

**Analog:** `test/crosswake/proof/phase38_companion_contract_test.exs` (exact match)

**Module header and `async: false`** (`phase38_companion_contract_test.exs` lines 1–27):
```elixir
defmodule Crosswake.Proof.Phase40GateEvaluationTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 40 runtime gate evaluation.
  [purpose description]
  async: false — Application.put_env(:crosswake, :companions, ...) is a shared
  global key; running concurrently lets one test observe another's companion list.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial
end
```

**Inline router fixture pattern** (`phase39_route_policy_gating_test.exs` lines 29–65):
```elixir
defmodule GatedRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/gated", Crosswake.TestSupport.StudySessionLive,
        crosswake: [id: "gated", runtime: :live_view, gated_by: :test_flag]
    end
  end
end

defmodule FallbackRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/premium", Crosswake.TestSupport.StudySessionLive,
        crosswake: [
          id: "premium",
          runtime: :live_view,
          gated_by: :feature_premium,
          on_unavailable: {:fallback_phoenix, :home}
        ]
    end
  end
end
```

**`Application.put_env` + `on_exit` companion registration pattern** (`phase38_companion_contract_test.exs` lines 148–152):
```elixir
Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.BrokenCompanion])

on_exit(fn ->
  Application.delete_env(:crosswake, :companions)
end)
```

**Fixture companion shape** (`test/support/stub_companion.ex` lines 1–31) — the minimal template for inline test companions:
```elixir
defmodule GateDenyCompanion do
  @behaviour Crosswake.Companion
  @impl true
  def companion_id, do: :gate_deny_companion
  @impl true
  def enabled?(_config), do: true
  @impl true
  def kill_switch_active?(_context), do: false
  @impl true
  def route_gated?(%RouteEntry{gated_by: :test_flag}, _context) do
    {:deny, %Crosswake.Compatibility.Finding{
      axis: :gate_denied,
      route_id: "gated",
      message: "gate test_flag is inactive"
    }}
  end
  def route_gated?(_route, _context), do: :pass
  @impl true
  def validate_dependency, do: :ok
  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :gate_deny_companion,
      enabled: true,
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

**Kill-switch spy pattern for SC#2** (from RESEARCH.md Pattern 4) — verify `route_gated?/2` is never called:
```elixir
defmodule KillSwitchCompanion do
  @behaviour Crosswake.Companion
  @impl true
  def companion_id, do: :kill_switch_companion
  @impl true
  def enabled?(_config), do: true
  @impl true
  def kill_switch_active?(_context) do
    Process.put(:kill_switch_active_called, true)
    true
  end
  @impl true
  def route_gated?(_route, _context) do
    Process.put(:route_gated_called, true)
    :pass
  end
  # ... other callbacks
end

# In SC#2 test:
assert Process.get(:kill_switch_active_called) == true
assert Process.get(:route_gated_called) == nil
```
Use unique Process keys per test or clear them in `setup` to avoid stale state (Pitfall 6).

**Telemetry attachment for span verification** (`phase38_companion_contract_test.exs` lines 188–214):
```elixir
test_pid = self()
handler_id = "phase40-test-handler-#{System.unique_integer([:positive])}"

:telemetry.attach(
  handler_id,
  [:crosswake, :companion, :route_gate, :stop],
  fn _event, _measurements, metadata, _config ->
    send(test_pid, {:telemetry_stop, metadata})
  end,
  nil
)

on_exit(fn -> :telemetry.detach(handler_id) end)

# After calling RouteGate.evaluate/4:
assert_receive {:telemetry_stop, %{companion_id: :gate_deny_companion}}, 1000
```

**Hermeticity self-assertion** (`phase38_companion_contract_test.exs` lines 95–103):
```elixir
test "phase 40 gate evaluation proof stays hermetic — no example-host or Code.require_file dependency" do
  source = File.read!(__ENV__.file) |> String.downcase()

  refute String.contains?(source, "crosswake" <> "example.router"),
         "phase 40 gate proof must not depend on the example host router"

  refute Regex.match?(~r/code\.require_file\s*\(/, source),
         "phase 40 gate proof must not Code.require_file example-host modules"
end
```

---

## Shared Patterns

### Companion Registry Dispatch
**Source:** `lib/crosswake/doctor/doctor.ex` lines 514–520
**Apply to:** `prepend_gate_evaluation_findings/3` in `route_gate.ex`
```elixir
companions = Application.get_env(:crosswake, :companions, [])
# Per-companion config key is the companion's own atom ID (FunWithFlags-style):
config_map = Application.get_env(:crosswake, companion.companion_id(), %{})
enabled = companion.enabled?(config_map)
```

### Telemetry Span Convention
**Source:** `lib/crosswake/doctor/doctor.ex` lines 522–530
**Apply to:** Every `kill_switch_active?/1` and `route_gated?/2` call in `route_gate.ex`
```elixir
:telemetry.span(
  [:crosswake, :companion, :kill_switch],   # or :route_gate
  %{companion_id: companion_id, route_id: route.id},
  fn ->
    result = companion.kill_switch_active?(target)
    {result, %{companion_id: companion_id, route_id: route.id, result: result}}
  end
)
```
Use `:telemetry.span/3` — never manual `:start`/`:stop` calls (handles exceptions automatically).

### `Denial.new/1` Construction
**Source:** `lib/crosswake/shell/denial.ex` lines 46–61
**Apply to:** Gate and kill-switch denial production in `route_gate.ex`

Required keyword args: `reason:`, `message:`. Optional: `route_id:`, `details:`, `hint:`, `recovery:`.
`details:` map MUST use string keys (`"flag_key"`, not `:flag_key`) — `to_map/1` does not atom-to-string map values.
`"evaluated_at"` MUST be a pre-serialized ISO8601 string (`DateTime.utc_now() |> DateTime.to_iso8601()`), NOT a `DateTime` struct.

### Application.put_env Fixture Pattern
**Source:** `test/crosswake/proof/phase38_companion_contract_test.exs` lines 148–152
**Apply to:** All SC tests in `phase40_gate_evaluation_test.exs`
```elixir
Application.put_env(:crosswake, :companions, [MyFixtureCompanion])
on_exit(fn -> Application.delete_env(:crosswake, :companions) end)
```
Register within each individual test (not `setup_all`) when tests use different companion lists, to keep cleanup scoped.

---

## No Analog Found

No files in this phase lack an analog. All three files either extend themselves or have a direct structural peer in the existing proof test infrastructure.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | — |

---

## Pitfalls to Communicate to Planner

1. **`transition_for` call site** — `evaluate/4` line 50 calls `transition_for(status, opts)`. Must be updated to `transition_for(status, route, opts)` in the same task as the function definition change.

2. **`@reasons` + typespec both** — Add `:gate_denied` and `:kill_switch_active` to BOTH `@reasons` list and `@type reason` typespec in `denial.ex`. `struct!` does not validate against `@reasons`; the typespec is what enables Dialyzer.

3. **`{:fallback_phoenix, id}` clause ordering** — The `transition_for(:deny, %RouteEntry{on_unavailable: {:fallback_phoenix, id}}, _opts)` clause MUST precede the general `transition_for(:deny, _route, opts)` clause.

4. **Nil route guard in `prepend_gate_evaluation_findings/3`** — Add `defp prepend_gate_evaluation_findings(findings, nil, _target), do: findings` as the first clause, before the `gated_by: nil` guard.

5. **Gate/kill-switch denials bypass `finding_to_denial/2`** — Produce `Denial.t()` directly and prepend to `denials` (not `findings`). Do NOT add `:gate_denied` / `:kill_switch_active` axes to `finding_to_denial/2`.

6. **SC#2 spy cleanup** — Use `Process.delete(:kill_switch_active_called)` and `Process.delete(:route_gated_called)` in `setup` to clear stale state between tests sharing the same process.

## Metadata

**Analog search scope:** `lib/crosswake/compatibility/`, `lib/crosswake/shell/`, `lib/crosswake/doctor/`, `test/crosswake/proof/`, `test/support/`
**Files read:** 8
**Pattern extraction date:** 2026-05-30
