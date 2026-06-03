# Phase 42: Rulestead In-Tree Companion And Mock Example — Research

**Researched:** 2026-05-30
**Domain:** Elixir companion behaviour implementation, named Agent process, Phoenix router scoping, hermetic ExUnit proof
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `MockFlagSource` is a named Agent (or GenServer) storing `%{flag_atom => gate_state}` where `gate_state :: :gated | {:rolling_out, non_neg_integer()} | :killed`.

**D-02:** Gate state mapping from stored value:
- `:gated` → `route_gated?` returns `{:deny, finding}`; `kill_switch_active?` returns `false`
- `{:rolling_out, pct}` → same as `:gated` for Phase 42 (deny path); `gate_status: {:rolling_out, pct}` in `report_state/0`
- `:killed` → `kill_switch_active?` returns `true`; `route_gated?` is never reached (short-circuit)
- `nil` / unknown flag → `:pass` from `route_gated?`, `false` from `kill_switch_active?`

**D-03:** MockFlagSource exposes at minimum `start_link/0`, `set_flag(flag_key, gate_state)`, `get_flag(flag_key) :: gate_state | nil`. Planner may add `reset/0` for test cleanup.

**D-04:** Mock-only for Phase 42. Real `Rulestead.Snapshot` adapter deferred to Phase 43.

**D-05:** MockFlagSource lives at `lib/crosswake/companions/rulestead/mock_flag_source.ex` — distributed with the library, not example-only.

**D-06:** phoenix_host Application starts MockFlagSource (or a dev/test helper does).

**D-07:** One gated route under `/gating` scope: single path (e.g. `/gating/beta-feature`), `gated_by: :my_flag`, `on_unavailable: :deny`.

**D-08:** `on_unavailable: :deny` only. `{:fallback_phoenix}` posture deferred.

**D-09:** New scope is `/gating` — sibling to `/commerce` and `/study` scopes.

**D-10:** `validate_dependency/0` checks `Code.ensure_loaded?(Rulestead)` only. Returns `:ok` if present, `{:error, [Rulestead]}` if absent.

### Claude's Discretion

- Exact module layout within `lib/crosswake/companions/rulestead/` — single file vs. directory with `rulestead.ex` + `mock_flag_source.ex`.
- Whether MockFlagSource uses `Agent` or bare `GenServer`. Agent is simpler.
- Exact scaffold for the `/gating/beta-feature` LiveView or controller in phoenix_host.
- Proof test structure for SC#1–SC#3: follow prior proof test conventions.

### Deferred Ideas (OUT OF SCOPE)

- Real `Rulestead.Snapshot` adapter (Phase 43)
- Companion-supplied `reason`/`variant` strings — still `"DISABLED"` / `"off"`
- `{:fallback_phoenix}` route posture demonstration
- Hermetic CI lane without rulestead dep (Phase 43 — PROOF-01)
- `guides/companions.md` rulestead section (Phase 43)
- `kill_switch_status` richer typespec (deferred from Phase 41)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | Maintainer can register a first-party companion via `Crosswake.Companion` behaviour with 6 callbacks | Exercised by implementing `Crosswake.Companions.Rulestead` — all 6 callbacks implemented concretely |
| COMP-02 | Companion enabled but library missing → explicit doctor error naming missing dep | `validate_dependency/0` checks `Code.ensure_loaded?(Rulestead)`; Phase 38 doctor seam fires `:error` automatically |
| COMP-03 | Companions follow in-tree convention `lib/crosswake/companions/<name>/` and emit `[:crosswake, :companion, …]` telemetry | New directory establishes convention; telemetry emitted by RouteGate (no companion-side work needed) |
| GATE-01 | Route declared gated by named flag in route-policy DSL | phoenix_host router adds `gated_by: :my_flag` to a route in `/gating` scope |
| GATE-02 | Flag binding recorded in runtime manifest; flag value evaluated at runtime from local snapshot with no network call | MockFlagSource Agent provides no-network snapshot; existing manifest builder already records `gated_by` |
| GATE-03 | Gate denial yields structured `:gate_denied` denial with OpenFeature-shaped reason | RouteGate already does this; companion returns `{:deny, finding}` when `:gated` or `{:rolling_out, _}` |
| GATE-04 | Kill switches short-circuit ahead of all gating and fail closed | Companion returns `kill_switch_active?/1 = true` when stored state is `:killed`; RouteGate short-circuit already tested |
| GATE-05 | `mix crosswake.doctor` lists gated routes, flags unknown-referenced flags, reports gate posture | Rulestead companion registered in companions list resolves the `gated_by: :my_flag` finding; doctor seam auto-fires via Phase 38/41 wiring |
</phase_requirements>

---

## Summary

Phase 42 is purely an implementation phase — the infrastructure is already wired from Phases 38–41. The planner needs to create three Elixir modules (`Crosswake.Companions.Rulestead`, `Crosswake.Companions.Rulestead.MockFlagSource`, and a minimal Phoenix LiveView in phoenix_host), wire them into the phoenix_host Application supervisor and config, add a `/gating` scope to the router, and write one hermetic proof test file.

No new libraries are required. The `Crosswake.Companion` behaviour contract, `RouteGate` dispatch loop, and doctor seam all exist and are production-ready. The companion only needs to implement the 6 callbacks correctly. The trickiest correctness constraint is the D-02 state mapping table — the companion must not conflate `:gated` and `{:rolling_out, _}` when deciding `kill_switch_active?` vs `route_gated?`, and must emit the right `gate_status` / `kill_switch_status` pair in `report_state/0`.

The phoenix_host changes are minimal: start MockFlagSource in the Application supervisor, add one config block in `config.exs` to register the companion, and add a `/gating` scope with one route. The proof test follows the exact same `async: false` + `Application.put_env` + `on_exit` pattern established in phases 38/40/41 — it can register the real `Crosswake.Companions.Rulestead` module directly (no inline fixture needed) because it uses MockFlagSource as the state driver.

**Primary recommendation:** Two-file companion layout (`lib/crosswake/companions/rulestead.ex` + `lib/crosswake/companions/rulestead/mock_flag_source.ex`), named Agent for MockFlagSource, one minimal LiveView in phoenix_host, proof test verifies SC#1 (all three gate states via MockFlagSource), SC#2 (phoenix_host route drives denial), SC#3 (doctor error without Rulestead, clean with mock configured).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Gate state storage | Library (Agent process) | — | MockFlagSource is a named Agent started in the host Application; state lives in the process dictionary, zero network dependency |
| Gate evaluation dispatch | Library (RouteGate) | — | `prepend_gate_evaluation_findings/3` already dispatches to companions; rulestead companion only implements callbacks |
| Kill-switch short-circuit | Library (RouteGate) | — | `check_kill_switches/3` already reduces over companions; companion returns `true`/`false` from `kill_switch_active?/1` |
| Dependency validation | Library (Doctor) | Companion (validate_dependency/0) | Phase 38 `phase_38_companion_seam_findings/0` drives the doctor loop; companion only checks `Code.ensure_loaded?(Rulestead)` |
| Route gating declaration | Phoenix Router (phoenix_host) | — | `gated_by: :my_flag` keyword on the route in the `/gating` scope |
| Companion registration | Phoenix Config | — | `config :crosswake, :companions, [Crosswake.Companions.Rulestead]` in phoenix_host config |
| MockFlagSource lifecycle | Phoenix Application | — | Added to supervisor children in `CrosswakeExample.Application.start/2` |
| Doctor coverage (SC#3) | Library (Doctor) | — | Auto-fires via Phase 38 seam when rulestead registered; no new doctor code |

---

## Standard Stack

### Core (all already in mix.exs — no new deps)

| Module/Feature | Source | Purpose |
|----------------|--------|---------|
| `Crosswake.Companion` behaviour | `lib/crosswake/companion.ex` | 6-callback contract to implement |
| `Crosswake.Companion.State` | `lib/crosswake/companion/state.ex` | Return type for `report_state/0` |
| `Agent` | Elixir stdlib | Named process for MockFlagSource state |
| `Application.get_env/put_env` | Elixir stdlib | Runtime companion registration; test fixture injection |

### No New Dependencies

Phase 42 adds zero new dependencies to the main `crosswake` mix.exs and zero new dependencies to `examples/phoenix_host/mix.exs`. The `rulestead` Hex package is deliberately absent — `validate_dependency/0` returns `{:error, [Rulestead]}` in Phase 42, which is the correct fail-closed behavior for SC#3.

---

## Package Legitimacy Audit

No external packages are installed in Phase 42. This section is not applicable — zero new dependencies.

---

## Architecture Patterns

### System Architecture Diagram

```
phoenix_host config.exs
  └── config :crosswake, :companions, [Crosswake.Companions.Rulestead]

CrosswakeExample.Application.start/2
  └── starts MockFlagSource (named Agent, registered as :crosswake_rulestead_mock)

Phoenix Router /gating scope
  └── /gating/beta-feature
        crosswake: [id: "gating-beta-feature", gated_by: :rulestead, on_unavailable: :deny]

RouteGate.evaluate/4 (at activation time)
  └── prepend_gate_evaluation_findings/3
        └── companions = Application.get_env(:crosswake, :companions, [])
              └── Crosswake.Companions.Rulestead
                    ├── kill_switch_active?/1
                    │     └── MockFlagSource.get_flag(:my_flag) == :killed → true
                    │         else → false
                    └── route_gated?/2  (only called if kill_switch_active? = false)
                          └── MockFlagSource.get_flag(route.gated_by)
                                :gated | {:rolling_out, _} → {:deny, finding}
                                nil | unknown → :pass

Doctor.run/1
  ├── phase_38_companion_seam_findings/0
  │     └── Rulestead.validate_dependency/0
  │           Code.ensure_loaded?(Rulestead) = false → {:error, [Rulestead]}
  │           → :error "companion.dependency_missing"
  └── phase_41_gating_findings/1
        └── route "gating-beta-feature" gated_by: :rulestead
              → :advisory "gating.route_gated"
              companion registered → no :error "gating.flag_reference_unknown"
```

### Recommended File Structure

```
lib/crosswake/companions/
└── rulestead.ex                    # Crosswake.Companions.Rulestead (main companion)
    rulestead/
    └── mock_flag_source.ex         # Crosswake.Companions.Rulestead.MockFlagSource

examples/phoenix_host/
├── lib/crosswake_example/
│   ├── application.ex              # MODIFIED: add MockFlagSource to supervisor
│   ├── router.ex                   # MODIFIED: add /gating scope
│   └── gating/
│       └── beta_feature_live.ex    # NEW: minimal LiveView
└── config/
    └── config.exs                  # MODIFIED: register companion + enable it

test/crosswake/proof/
└── phase42_rulestead_companion_test.exs   # NEW: SC#1, SC#2, SC#3 proof
```

### Pattern 1: Companion Implementation

The companion implements all 6 callbacks. The key correctness constraint is D-02: the mapping from `MockFlagSource` state to callback return values.

```elixir
# Source: lib/crosswake/companion.ex + CONTEXT.md D-02 decision table
defmodule Crosswake.Companions.Rulestead do
  @moduledoc false
  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Companions.Rulestead.MockFlagSource

  @impl true
  def companion_id, do: :rulestead

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(route, _target) do
    case MockFlagSource.get_flag(route.gated_by) do
      :gated -> {:deny, %Finding{axis: :gate_denied, route_id: route.id,
                                  message: "#{route.gated_by} is disabled",
                                  subject: "DISABLED"}}
      {:rolling_out, _pct} -> {:deny, %Finding{axis: :gate_denied, route_id: route.id,
                                                 message: "#{route.gated_by} is rolling out",
                                                 subject: "DISABLED"}}
      _ -> :pass
    end
  end

  @impl true
  def kill_switch_active?(_target) do
    # kill_switch_active? is NOT route-specific (D-07 of Phase 40)
    # Phase 42: check a well-known flag or check if ANY flag is :killed
    # Planner decision: per CONTEXT.md D-02, :killed → kill_switch_active? true
    # The gated_by flag name must be consulted — but kill_switch_active? receives
    # only Target.t(), not a route. Resolution: the companion checks a companion-level
    # kill switch key (see Pattern 3 below).
    false  # See Pattern 3 for the actual implementation detail
  end

  @impl true
  def validate_dependency do
    if Code.ensure_loaded?(Rulestead) do
      :ok
    else
      {:error, [Rulestead]}
    end
  end

  @impl true
  def report_state do
    # Planner populates based on MockFlagSource state
    %State{
      companion_id: :rulestead,
      enabled: true,
      dependency_status: if(Code.ensure_loaded?(Rulestead), do: :present, else: {:missing, [Rulestead]}),
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

### Pattern 2: MockFlagSource Agent

```elixir
# Source: CONTEXT.md D-01, D-03
defmodule Crosswake.Companions.Rulestead.MockFlagSource do
  @moduledoc """
  Named Agent storing flag state for local dev and hermetic proof tests.
  Production code uses Rulestead.Snapshot; this module is mock-only (Phase 42).
  """
  use Agent

  @name __MODULE__

  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def set_flag(flag_key, gate_state) when is_atom(flag_key) do
    Agent.update(@name, &Map.put(&1, flag_key, gate_state))
  end

  def get_flag(flag_key) when is_atom(flag_key) do
    Agent.get(@name, &Map.get(&1, flag_key))
  end

  def reset do
    Agent.update(@name, fn _ -> %{} end)
  end
end
```

### Pattern 3: kill_switch_active? Resolution

The `kill_switch_active?/1` callback receives only `Target.t()`, not a route. The route's `gated_by` key is not available. This creates a design tension for a flag-based kill switch.

**Resolution for Phase 42 (planner decision):** The companion treats a well-known key `:rulestead_kill_switch` (or the companion_id atom `:rulestead`) stored in MockFlagSource as the companion-level kill-switch signal. Alternatively, the companion can scan all stored flags for any `:killed` state.

**Recommended approach:** Store the kill switch as a companion-level key separate from per-flag state. `kill_switch_active?/1` checks `MockFlagSource.get_flag(:rulestead_kill_switch) == :killed`. The phoenix_host demo uses `MockFlagSource.set_flag(:my_flag, :killed)` to drive the killed state — and separately the kill_switch_active? callback must map this correctly.

**Simplest correct approach for Phase 42:** Since the proof tests drive all three states by mutating MockFlagSource, and the `route.gated_by` is not available in `kill_switch_active?/1`, the planner should store kill-switch state at a per-flag-key level in MockFlagSource but expose `kill_switch_active_for?(flag_key)` internally. For the companion-level `kill_switch_active?/1`, scan all stored flags for any `:killed` entry. If ANY flag is `:killed`, return `true`.

**Caveat:** Scanning all flags is only correct for a single-flag Phase 42 demo. The planner should document this limitation. The proof test sets exactly one flag, so the scan is unambiguous.

```elixir
# Pattern 3: kill_switch_active?/1 scanning all flags
@impl true
def kill_switch_active?(_target) do
  case Process.whereis(MockFlagSource) do
    nil -> false
    _pid ->
      MockFlagSource
      |> Agent.get(&Map.values/1)
      |> Enum.any?(&(&1 == :killed))
  end
end
```

### Pattern 4: Proof Test Structure

```elixir
# Source: test/crosswake/proof/phase38_companion_contract_test.exs (setup pattern)
#         test/crosswake/proof/phase40_gate_evaluation_test.exs (companion registration)
defmodule Crosswake.Proof.Phase42RulesteadCompanionTest do
  use ExUnit.Case, async: false  # REQUIRED: shared Application.put_env key

  alias Crosswake.Companions.Rulestead
  alias Crosswake.Companions.Rulestead.MockFlagSource

  setup do
    # Start MockFlagSource for each test (or use start_supervised!)
    {:ok, _pid} = start_supervised(MockFlagSource)
    Application.put_env(:crosswake, :companions, [Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)
    :ok
  end

  # SC#1: All three gate states drive the correct RouteGate outcomes
  # SC#2: Phoenix host route with :my_flag drives denial
  # SC#3: Doctor emits :error when Rulestead absent; clean when mock configured
end
```

### Pattern 5: phoenix_host Application Supervisor

```elixir
# Modified: examples/phoenix_host/lib/crosswake_example/application.ex
def start(_type, _args) do
  children = [
    {Phoenix.PubSub, name: CrosswakeExample.PubSub},
    CrosswakeExample.Repo,
    Crosswake.Companions.Rulestead.MockFlagSource  # NEW
  ]
  opts = [strategy: :one_for_one, name: CrosswakeExample.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### Pattern 6: phoenix_host Router Scope

```elixir
# Source: existing router.ex — /commerce scope pattern, CONTEXT.md D-07/D-09
scope "/gating", CrosswakeExample.Gating do
  pipe_through [:browser]

  crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
    live "/beta-feature", BetaFeatureLive,
      crosswake: [
        id: "gating-beta-feature",
        gated_by: :rulestead,
        on_unavailable: :deny
      ]
  end
end
```

**Critical correctness note:** `gated_by: :rulestead` must match `companion_id/0` returning `:rulestead`. This is how the doctor resolves the `gating.flag_reference_unknown` check (Phase 41 doctor seam: `MapSet.member?(known_companion_ids, route.gated_by)`).

### Anti-Patterns to Avoid

- **Using `gated_by: :my_flag` with `companion_id: :rulestead`:** The doctor resolves `gated_by` against `companion_id/0`, NOT against individual flag keys. The atom in `gated_by` must be `:rulestead` (matching `companion_id/0`), not `:my_flag`. The companion internally consults `route.gated_by` to look up the flag in MockFlagSource — but `gated_by` in the route policy IS the companion_id, not a flag name. [VERIFIED: route_gate.ex line 90 reads `companion.companion_id()` and doctor.ex line 589-641 confirms `gated_by` must equal `companion_id()`]
- **Starting MockFlagSource globally outside tests:** If MockFlagSource is already running from the Application, proof tests using `start_supervised` will crash. Use `start_supervised!` or conditionally start it. The planner must decide whether proof tests start their own MockFlagSource or rely on the Application-started one.
- **Forgetting `async: false`:** Proof tests mutate global `Application.put_env(:crosswake, :companions, ...)`. Any `async: true` will let tests observe each other's companion lists. All prior proof tests enforce `async: false` — this must be continued.
- **Checking `Code.ensure_loaded?(Rulestead)` in `report_state/0` at call time:** `dependency_status` should reflect what `validate_dependency/0` would return, not a separate runtime check. Keep the two consistent.
- **`enabled?/1` returning `true` unconditionally:** The companion must check the host config map. The doctor seam calls `companion.enabled?(config_map)` where `config_map = Application.get_env(:crosswake, :rulestead, %{})`. If enabled? is always `true`, the doctor will emit a `:error` "companion.dependency_missing" even in environments where the companion should be disabled. Returning `Map.get(config, :enabled, false)` is the safe default.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Fail-closed gate denial | Custom deny logic | `RouteGate.prepend_gate_evaluation_findings/3` already dispatches to companions |
| Doctor companion loop | New doctor function | `phase_38_companion_seam_findings/0` already calls `validate_dependency/0` per companion |
| OpenFeature-shaped denial details | Custom map construction | `check_gate/3` in RouteGate already adds `flag_key`, `reason`, `variant`, `evaluated_at` |
| Kill-switch short-circuit | Custom ordering | `check_kill_switches/3` already runs before `check_gate/3` |
| Gate-state display strings | Custom formatter | `SupportMatrix.gate_state_display/1` already maps states to "gated"/"rolling_out (N%)"/"killed" |
| Named process boilerplate | GenServer | `use Agent` + `Agent.start_link` is sufficient for map storage |

**Key insight:** Phase 42 is a pure seam implementation. Every piece of infrastructure exists. The companion's job is to correctly translate MockFlagSource state into the existing callback contracts — nothing more.

---

## Common Pitfalls

### Pitfall 1: gated_by Atom Means companion_id, Not Flag Name

**What goes wrong:** Developer writes `gated_by: :my_flag` in the route and `companion_id/0` returns `:rulestead`. Doctor emits `gating.flag_reference_unknown :error` because `:my_flag` is not a registered companion ID. RouteGate also skips the companion because it filters by `companion.enabled?(config)` against the full list, not by `gated_by`.

**Why it happens:** The DSL option `gated_by:` looks like it should name a flag, but it actually names the companion responsible for evaluating the route. The companion then reads `route.gated_by` internally to look up flag state in MockFlagSource.

**How to avoid:** Set `gated_by: :rulestead` in the route policy. The companion's `route_gated?/2` implementation calls `MockFlagSource.get_flag(route.gated_by)` — which passes `:rulestead` as the flag key. In the phoenix_host setup, `MockFlagSource.set_flag(:rulestead, :gated)` is the correct call to drive the gated state.

**Warning signs:** Doctor emits `gating.flag_reference_unknown :error`. The route activates when it should be denied.

### Pitfall 2: MockFlagSource Not Running When Companion Callbacks Execute

**What goes wrong:** RouteGate calls `companion.kill_switch_active?/1` or `companion.route_gated?/2`, the companion calls `MockFlagSource.get_flag/1`, but MockFlagSource is not started → `** (exit) no process: the process is not alive or there's no process currently associated with the given name`.

**Why it happens:** In proof tests, if `start_supervised!(MockFlagSource)` is not called in `setup`, the Agent is not running. In production (phoenix_host), if the supervisor child order places MockFlagSource after a child that starts eagerly and triggers gate evaluation during init, it may not be ready.

**How to avoid:** Add MockFlagSource as the FIRST child in the supervisor, before any child that might trigger Crosswake route evaluation. In proof tests, always start it in `setup` via `start_supervised!`.

**Warning signs:** `(EXIT) no process` in test or application startup. Guard with `Process.whereis(MockFlagSource)` nil check in callbacks.

### Pitfall 3: report_state/0 gate_status / kill_switch_status Pairing for :killed State

**What goes wrong:** When the flag is `:killed`, `kill_switch_status: :active` is correct. But if `gate_status` is set to `:active` or `:inactive` alongside it, `SupportMatrix.gate_state_display/1` uses kill_switch_status first (kill switch overrides gate_status) — so the display is still "killed". However, setting `gate_status: :inactive` when the kill switch is active is most semantically correct (the gate is inactive because the kill switch has fired).

**Why it happens:** Phase 41 Phase 41 established that `kill_switch_status: :active` overrides `gate_status` in `gate_state_display/1`. The pairing is flexible but semantically the cleanest is `gate_status: :inactive` + `kill_switch_status: :active`.

**How to avoid:** Use this canonical pairing:
- `:gated` stored → `gate_status: :active`, `kill_switch_status: :inactive`
- `{:rolling_out, n}` stored → `gate_status: {:rolling_out, n}`, `kill_switch_status: :inactive`
- `:killed` stored → `gate_status: :inactive`, `kill_switch_status: :active`
- `nil` / unknown → `gate_status: :unconfigured`, `kill_switch_status: :unconfigured`

**Warning signs:** `SupportMatrix.gating_truth/0` test assertions fail on "killed" display for `:killed` flag state.

### Pitfall 4: Proof Test Concurrent MockFlagSource State

**What goes wrong:** Two proof tests run sequentially but the MockFlagSource started in `setup` carries state from the previous test because ExUnit reuses the same process if the test terminates without stopping the Agent.

**Why it happens:** `start_supervised!/1` in ExUnit creates a supervised process that is automatically stopped by the test supervisor at the end of each test. But if you start the Agent manually without registering it with ExUnit's supervisor, state leaks.

**How to avoid:** Always use `start_supervised!(MockFlagSource)` in setup. If using `reset/0` between tests, call it at the start of each test or in setup. The planner should add `MockFlagSource.reset/0` as called in the setup block after `start_supervised!`.

**Warning signs:** Gate state tests pass individually but fail in suite order; `:gated` test passes when `:killed` test runs first.

### Pitfall 5: Doctor SC#3 — clean output requires enabled? returning false

**What goes wrong:** SC#3 requires "clean doctor output" with mock configured. But if `enabled?/1` returns `true` and `validate_dependency/0` returns `{:error, [Rulestead]}` (because the actual `Rulestead` library is not in deps), doctor emits `:error "companion.dependency_missing"`.

**Why it happens:** In Phase 42, the `rulestead` Hex package is deliberately absent from deps. So `Code.ensure_loaded?(Rulestead)` always returns `false`. To get a clean doctor output, the companion must be registered as disabled (`enabled?: false`) OR `validate_dependency/0` must return `:ok` for the mock-configured case.

**Resolution from CONTEXT.md:** The SC#3 proof sets up two sub-scenarios: (a) companion enabled + library absent → `:error`, (b) companion registered with mock configured → clean output. For (b), "clean" means the companion is enabled but mock-configured such that dependency validation passes. But if `Rulestead` is not in deps, `validate_dependency/0` always returns `{:error, ...}`.

**Correct interpretation of SC#3:** The "mock source configured → clean doctor output" scenario works because the proof test registers the companion as disabled (`enabled?: false` in config) for the no-error case — a disabled companion with a missing dep emits `:advisory "companion.disabled_dependency_present"` (but only if dep IS present) or nothing (if dep is absent and companion is disabled — doctor emits nothing per Phase 38 doctor code). Check doctor.ex line 534: `{false, {:error, mods}} ->` matches to the `_` catch-all which returns `[]`. So: disabled + missing dep = no doctor finding. That is the "clean" case.

**Warning signs:** SC#3 "clean" assertion finding unexpected `:error` findings.

---

## Code Examples

### Verified: Companion Behaviour Contract (6 callbacks)

```elixir
# Source: lib/crosswake/companion.ex
@callback companion_id() :: atom()
@callback enabled?(config :: map()) :: boolean()
@callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) ::
            {:deny, Finding.t()} | :pass
@callback kill_switch_active?(context :: Target.t()) :: boolean()
@callback validate_dependency() :: :ok | {:error, [module()]}
@callback report_state() :: State.t()
```

### Verified: Doctor Companion Registration (how companion hooks in automatically)

```elixir
# Source: lib/crosswake/doctor/doctor.ex, phase_38_companion_seam_findings/0
companions = Application.get_env(:crosswake, :companions, [])
Enum.flat_map(companions, fn companion ->
  companion_id = companion.companion_id()
  config_map = Application.get_env(:crosswake, companion_id, %{})
  enabled = companion.enabled?(config_map)
  # validate_dependency/0 called; {:error, mods} + enabled → :error finding
  # {:error, mods} + disabled → [] (no finding emitted)
end)
```

### Verified: RouteGate companion dispatch (how companion is called at gate time)

```elixir
# Source: lib/crosswake/compatibility/route_gate.ex, prepend_gate_evaluation_findings/3
companions =
  Application.get_env(:crosswake, :companions, [])
  |> Enum.filter(fn companion ->
    config = Application.get_env(:crosswake, companion.companion_id(), %{})
    companion.enabled?(config)
  end)
# Only ENABLED companions are dispatched. Disabled companions are skipped entirely.
# kill_switch_active?/1 checked first; if true → :kill_switch_active denial, stop
# route_gated?/2 checked only if kill switch inactive
```

### Verified: Doctor gated_by resolution (why gated_by must equal companion_id)

```elixir
# Source: lib/crosswake/doctor/doctor.ex, phase_41_gating_findings/1 + gating_flag_reference_error/2
known_companion_ids =
  companions
  |> Enum.map(& &1.companion_id())
  |> MapSet.new()

# Route's gated_by is checked against the SET of companion_ids, not flag names:
if MapSet.member?(known_companion_ids, route.gated_by) do
  []  # Known → advisory only
else
  [:error "gating.flag_reference_unknown"]
end
```

### Verified: Companion.State gate_status type (Phase 41 extended)

```elixir
# Source: lib/crosswake/companion/state.ex
@type gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}
@type kill_switch_status :: :inactive | :active | :unconfigured
```

### Verified: gate_state_display/1 precedence (kill_switch beats gate_status)

```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex
defp gate_state_display(%Crosswake.Companion.State{kill_switch_status: :active}), do: "killed"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :active}), do: "gated"
defp gate_state_display(%Crosswake.Companion.State{gate_status: {:rolling_out, n}}),
  do: "rolling_out (#{n}%)"
defp gate_state_display(%Crosswake.Companion.State{gate_status: :inactive}), do: nil
defp gate_state_display(%Crosswake.Companion.State{gate_status: :unconfigured}), do: nil
```

---

## Runtime State Inventory

> This phase is greenfield (new modules). No rename/refactor/migration involved.

None — verified. Phase 42 adds new files and new config entries. No existing runtime state is modified.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir `Agent` | MockFlagSource | ✓ | stdlib | — |
| `ExUnit` | Proof tests | ✓ | stdlib | — |
| `:telemetry` | RouteGate telemetry spans | ✓ | already in deps | — |
| `rulestead` Hex package | `validate_dependency/0` check | ✗ (intentional) | — | `{:error, [Rulestead]}` is the correct test outcome |
| Phoenix LiveView | `/gating/beta-feature` route | ✓ | already in phoenix_host deps | — |

**Missing dependencies with no fallback:** None that block Phase 42 execution.

**`rulestead` library intentionally absent:** `Code.ensure_loaded?(Rulestead)` returns `false` throughout Phase 42. This is correct behavior — SC#3 proves the doctor emits `:error` in this case.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` — `ExUnit.start()` |
| Quick run command | `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMP-01 | Rulestead module satisfies all 6 Companion callbacks | unit | `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` | ❌ Wave 0 |
| COMP-02 | Doctor :error when rulestead enabled + library absent (SC#3a) | unit | same | ❌ Wave 0 |
| COMP-03 | `lib/crosswake/companions/rulestead/` directory exists; telemetry spans fire from RouteGate | unit/integration | same | ❌ Wave 0 |
| GATE-01 | `gated_by: :rulestead` on phoenix_host route compiles and binds in manifest | integration | `mix test --exclude requires_example_host` | ❌ Wave 0 |
| GATE-02 | MockFlagSource provides no-network runtime flag lookup | unit | same | ❌ Wave 0 |
| GATE-03 | `:gated` flag state → `:gate_denied` denial with OpenFeature fields (SC#1a) | unit | same | ❌ Wave 0 |
| GATE-04 | `:killed` flag state → `:kill_switch_active` denial; route_gated? skipped (SC#1c) | unit | same | ❌ Wave 0 |
| GATE-05 | Doctor advisory + no :error when companion registered + mock configured (SC#3b) | unit | same | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase42_rulestead_companion_test.exs` — SC#1, SC#2, SC#3 proof
- [ ] `lib/crosswake/companions/rulestead.ex` — main companion module
- [ ] `lib/crosswake/companions/rulestead/mock_flag_source.ex` — Agent process

*(Existing test infrastructure requires no changes — the new proof file is untagged and is picked up by `mix test --exclude requires_example_host` automatically.)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | Companion-based route gating is a further-restriction control; RouteGate is fail-closed by design |
| V5 Input Validation | no | Flag keys are atoms (compile-time validated as route policy DSL values) |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Gate bypass via disabled companion | Elevation of privilege | `enabled?/1` default is `false`; companion must be explicitly enabled in config |
| MockFlagSource state leaking between test runs | Tampering (test reliability) | `start_supervised!` in ExUnit setup ensures Agent is fresh per test |
| `kill_switch_active?` returning nil instead of false | Denial of service / fail-open | Callback contract enforces `boolean()` return; companion must not return nil |
| `validate_dependency/0` swallowing errors | Tampering | Returns typed `{:error, [module()]}` — no catch-all exception swallowing |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `gated_by:` in the route policy DSL must equal the companion's `companion_id/0` atom (not a flag name) | Architecture Patterns + Anti-Patterns | If wrong, doctor would emit `gating.flag_reference_unknown :error` for every gated route and RouteGate would never invoke the companion |
| A2 | MockFlagSource scanning all stored flags for `:killed` is the simplest correct approach for `kill_switch_active?/1` in Phase 42 | Pattern 3 | If wrong (e.g., planner uses a dedicated kill-switch key), tests would need to set a different flag key to trigger kill-switch state |
| A3 | The phoenix_host Application supervisor can start `Crosswake.Companions.Rulestead.MockFlagSource` as a named child directly without wrapping | Pattern 5 | If MockFlagSource's `start_link/0` signature requires opts, `{MockFlagSource, []}` is the child spec form |
| A4 | SC#3 "clean doctor output" = companion disabled (`enabled? false`) + library absent → `[]` findings (not `:advisory`) | Pitfall 5 | If the doctor emits an advisory for disabled+absent companions, "clean" assertion must be updated |

---

## Open Questions

1. **kill_switch_active?/1 flag key strategy**
   - What we know: `kill_switch_active?/1` receives only `Target.t()`, not a route or flag key; MockFlagSource stores per-flag state
   - What's unclear: Should the companion scan all flags for `:killed`, or use a dedicated companion-level kill-switch key?
   - Recommendation: Scan all flags for `:killed` (simplest for Phase 42 single-flag demo). Planner documents the scan approach as Phase 42-only; Phase 43 may refine with a dedicated key.

2. **MockFlagSource start in proof tests vs Application-started**
   - What we know: phoenix_host Application starts MockFlagSource; proof tests are hermetic and do NOT use phoenix_host
   - What's unclear: Should the proof tests use `start_supervised!` (isolated) or rely on Application to have started it?
   - Recommendation: Proof tests use `start_supervised!` — hermetic by convention; they never depend on phoenix_host Application state.

3. **`enabled?/1` config key convention**
   - What we know: `Application.get_env(:crosswake, :rulestead, %{})` is the config map passed to `enabled?/1`
   - What's unclear: Should the key be `:enabled` (simple boolean) or a rulestead-specific key?
   - Recommendation: `Map.get(config, :enabled, false)` — consistent with the FunWithFlags-style pattern cited in Phase 38 CONTEXT.md and doctor.ex commentary.

---

## Sources

### Primary (HIGH confidence)

- `lib/crosswake/companion.ex` — 6-callback behaviour contract, telemetry event names, `enabled?/1` config map convention [VERIFIED: read directly]
- `lib/crosswake/companion/state.ex` — `gate_status` and `kill_switch_status` types including `{:rolling_out, non_neg_integer()}` [VERIFIED: read directly]
- `lib/crosswake/compatibility/route_gate.ex` — dispatch loop, kill-switch first ordering, `check_gate/3` OpenFeature detail construction, `companion.enabled?(config)` filter [VERIFIED: read directly]
- `lib/crosswake/doctor/doctor.ex` — `phase_38_companion_seam_findings/0` (enabled+missing→error, disabled+missing→[]), `phase_41_gating_findings/1` (gated_by vs companion_id resolution) [VERIFIED: read directly]
- `lib/crosswake/support_matrix/support_matrix.ex` — `gate_state_display/1` kill_switch precedence, `gating_truth/0` [VERIFIED: read directly]
- `test/crosswake/proof/phase38_companion_contract_test.exs` — `async: false`, `Application.put_env`+`on_exit`, hermetic router setup [VERIFIED: read directly]
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` — inline fixture companion pattern, GateDenyCompanion, KillSwitchCompanion [VERIFIED: read directly]
- `test/crosswake/proof/phase41_gating_doctor_test.exs` — SC#2 companions with distinct gate states [VERIFIED: read directly]
- `examples/phoenix_host/lib/crosswake_example/router.ex` — existing scope structure (`/study`, `/saas`, `/native`, `/commerce`) [VERIFIED: read directly]
- `examples/phoenix_host/lib/crosswake_example/application.ex` — current supervisor children [VERIFIED: read directly]
- `.planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-CONTEXT.md` — locked decisions D-01 through D-10 [VERIFIED: read directly]

### Secondary (MEDIUM confidence)

- `mix.exs` — `elixirc_paths(:test)` includes `test/support` so support fixtures compile without `Code.require_file` [VERIFIED: read directly]
- `test/support/stub_companion.ex` — `StubCompanion` and `BrokenCompanion` patterns for reference [VERIFIED: read directly]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all implementation uses existing Elixir stdlib + crosswake internals, all read directly from source
- Architecture: HIGH — RouteGate, Doctor, and Companion seam all verified by reading the actual implementation; no assumptions about their behavior
- Pitfalls: HIGH — derived from direct code reading (doctor.ex line 534 catch-all, route_gate.ex companion_id filter, support_matrix.ex gate_state_display precedence)
- Companion state mapping: HIGH — D-02 locked decision cross-referenced with Companion.State typespec and gate_state_display/1 source

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable, no fast-moving ecosystem dependencies)
