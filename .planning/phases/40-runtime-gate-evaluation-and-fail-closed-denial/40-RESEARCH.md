# Phase 40: Runtime Gate Evaluation And Fail-Closed Denial - Research

**Researched:** 2026-05-30
**Domain:** Elixir — RouteGate evaluation, Companion dispatch, Denial struct, Telemetry spans
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `Decision.transition` broadened to `transition: :activate | :halt | :stay_put | {:redirect, atom()}`. No new struct fields.
- **D-02:** `Decision.status` stays `:deny` in all denial cases. Caller does a single exhaustive `case decision.transition` with four arms.
- **D-03:** `Denial.details` for `:gate_denied`: `%{"flag_key" => Atom.to_string(route.gated_by), "reason" => "DISABLED", "variant" => "off", "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()}`.
- **D-04:** `evaluated_at` stamped by RouteGate as ISO8601 string, not a DateTime struct.
- **D-05:** OpenFeature reason string `"DISABLED"` for Phase 40 binary flag-is-off denial.
- **D-06:** `"off"` is the constant variant for Phase 40.
- **D-07:** `Atom.to_string(route.gated_by)` for `flag_key`.
- **D-08:** `Denial.details` for `:kill_switch_active` is minimal — at minimum `%{"companion_id" => Atom.to_string(companion.companion_id())}`.
- **D-09:** RouteGate iterates ALL enabled companions from `Application.get_env(:crosswake, :companions, [])` for both kill-switch and gate checks. Each companion decides internally whether it applies.
- **D-10:** Kill-switch and gate checks are first-deny-wins (short-circuit on first `true` / `{:deny, finding}`).
- **D-11:** Kill-switch check runs ONLY for gated routes (`gated_by != nil`); non-gated routes skip both steps entirely.
- **D-12:** Proof test file: `test/crosswake/proof/phase40_gate_evaluation_test.exs`, untagged, picked up by `phase34-proof.yml` automatically.
- **D-13:** Fixture companions defined inline as modules within the test file; `Application.put_env(:crosswake, :companions, [...])` in `setup_all` with `on_exit` cleanup; `async: false`.
- **D-14:** Full SC#1–4 coverage in Phase 40 (see Context for exact spec).

### Claude's Discretion

- `finding_to_denial/2` extension vs. direct `Denial.new/1` for gate/kill-switch denials — direct is likely cleaner given `flag_key`/`evaluated_at` come from RouteGate scope.
- Telemetry span implementation: `:telemetry.span/3` per companion callback call.
- `maybe_add_finding`-style helper vs. inline prepend — follow existing patterns.
- Whether to add `prepend_gate_evaluation_findings/3` (mirroring commerce corridor pattern) or a separate `gate_evaluation_step/3`.

### Deferred Ideas (OUT OF SCOPE)

- Doctor gating category + `{:fallback_phoenix}` visibility — Phase 41.
- Runtime gate-state support-matrix column — Phase 41.
- Real rulestead companion implementation — Phase 42.
- `finding.subject` carrying companion-supplied reason/variant — Phase 42+.
- `flag_variant` field on `Finding` struct — Phase 42.
- Multiple companion denials accumulation — Phase 42+.
- `crosswake_openfeature` companion — v3.6+.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-03 | Gate denies with structured `:gate_denied` denial carrying OpenFeature-shaped `details` (`flag_key`, `reason`, `variant`, `evaluated_at`) | D-03 through D-07 fully specify the shape; implementation is a direct `Denial.new/1` call with known fields |
| GATE-04 | Kill switches short-circuit ahead of all gating as `:kill_switch_active`; only fail-open path is explicit `on_unavailable: {:fallback_phoenix, route_id}` | D-08 through D-11 fully specify dispatch; `transition_for/2` reads `route.on_unavailable` to emit `{:redirect, id}` |
</phase_requirements>

---

## Summary

Phase 40 wires two previously-specified-but-unwired companion callbacks — `kill_switch_active?/1` and `route_gated?/2` — into `RouteGate.evaluate/4`, making gated routes fail closed by default. The implementation is additive: three new things get written into the existing module (`RouteGate`, `Denial`, `Decision`) and one new proof test is created. No new modules, no new CI files, no new mix dependencies.

The domain is pure Elixir internal plumbing with no external package research needed. All patterns (companion dispatch, telemetry span, `prepend_..._findings` structure, `maybe_add_finding` helper, `async: false` + `Application.put_env` fixture companion, `Denial.new/1` with details map) already exist in the codebase and are confirmed working. The planner's primary job is sequencing these well-understood steps and ensuring the `transition_for/2` signature change is handled correctly given two existing call sites in `Activation.resolve/2` and `Doctor.phase_19_commerce_corridor_posture/1`.

The most subtle implementation detail is `transition_for/2`: it currently takes `(status, opts)` but now needs `route.on_unavailable` to emit `{:redirect, id}` for `{:fallback_phoenix, id}`. The function signature must be broadened — either by threading `route` through (preferred for clarity) or by reading `on_unavailable` from opts. The existing callers of `RouteGate.evaluate/4` (Activation and Doctor) do not pattern-match on `decision.transition` — they only look at `decision.status` and `decision.denial` — so the type broadening is additive and non-breaking for those callers.

**Primary recommendation:** Follow the `prepend_commerce_corridor_findings/3` pattern exactly — add a `prepend_gate_evaluation_findings/3` function that short-circuit-checks kill switches first, then gate status, for gated routes only. Use direct `Denial.new/1` (not `finding_to_denial/2`) since `flag_key` and `evaluated_at` are RouteGate-scoped, not Finding-scoped. Thread `route` into an updated `transition_for/3` to read `on_unavailable`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Kill-switch short-circuit logic | API / Backend (RouteGate) | — | RouteGate owns evaluation order; companion callbacks are pure synchronous calls |
| Gate evaluation + denial production | API / Backend (RouteGate) | — | Same — evaluation is a local pure function over manifest + registered companion modules |
| Denial struct extension (new reasons) | API / Backend (Shell.Denial) | — | Denial is the shared denial envelope; reason atoms live here |
| Decision typespec broadening | API / Backend (RouteGate.Decision) | — | Decision is an inner module of RouteGate |
| Telemetry span emission | API / Backend (RouteGate) | — | Emit sites specified in Phase 38 companion docs belong to this phase |
| Proof test coverage | Test layer | — | Hermetic, no network, no simulator |

## Standard Stack

### Core — No new dependencies required

This phase installs zero new packages. All required building blocks are already present:

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| `:telemetry` | `~> 1.0` [VERIFIED: mix.exs line 44] | Span emission for companion callback wrapping | Already in mix.exs |
| `ExUnit` | Elixir stdlib | Proof test framework | Already in test infrastructure |

### Environment

| Runtime | Version | Status |
|---------|---------|--------|
| Elixir | 1.19.5 | [VERIFIED: `elixir --version`] |
| Erlang/OTP | 28 | [VERIFIED: `elixir --version`] |

## Package Legitimacy Audit

No new packages are installed in this phase. This section is intentionally omitted.

## Architecture Patterns

### System Architecture Diagram

```
RouteGate.evaluate/4
    │
    ├─ route = manifest.routes[route_id]   (nil-safe: non-existent routes handled by existing Compatibility pipeline)
    │
    ├─ [NEW] prepend_gate_evaluation_findings(findings=[], route, manifest)
    │       │
    │       │  ONLY if route.gated_by != nil
    │       │
    │       ├─ Kill-switch check (short-circuit)
    │       │   for each enabled companion:
    │       │     :telemetry.span([:crosswake,:companion,:kill_switch,...])
    │       │       └─ companion.kill_switch_active?(target)
    │       │           ├─ true  → return [{:kill_switch_active, companion_id}], STOP
    │       │           └─ false → continue
    │       │
    │       └─ Gate evaluation check (first-deny-wins)
    │           for each enabled companion:
    │             :telemetry.span([:crosswake,:companion,:route_gate,...])
    │               └─ companion.route_gated?(route, target)
    │                   ├─ {:deny, finding} → return [{:gate_denied, finding}], STOP
    │                   └─ :pass            → continue
    │
    ├─ [EXISTING] remap_commerce_corridor_findings(route)
    ├─ [EXISTING] prepend_commerce_corridor_findings(route, manifest)
    │
    ├─ denials = Enum.map(findings, &finding_to_denial/2)   [gate findings bypass this — direct Denial.new/1]
    ├─ status = :allow | :deny
    └─ %Decision{transition: transition_for(status, route, opts)}   [UPDATED signature]
                                │
                                ├─ :allow → :activate
                                ├─ :deny + in_app_navigation → :stay_put
                                ├─ :deny + {:fallback_phoenix, id} → {:redirect, id}   [NEW]
                                └─ :deny → :halt
```

### Recommended Project Structure

No new directories. All changes are in-place within existing files:

```
lib/crosswake/
├── compatibility/
│   └── route_gate.ex          # PRIMARY — extend Decision typespec, add kill-switch + gate steps, update transition_for
├── shell/
│   └── denial.ex              # Add :gate_denied and :kill_switch_active to @reasons and reason typespec
test/crosswake/proof/
└── phase40_gate_evaluation_test.exs   # NEW — SC#1-4 hermetic proof
```

### Pattern 1: Kill-switch short-circuit following `prepend_commerce_corridor_findings/3`

**What:** A private function added before the commerce corridor prepend step in the `evaluate/4` pipeline. It returns findings prepended ahead of everything else, mirroring the existing commerce corridor insertion point.

**When to use:** Gated routes only (`route.gated_by != nil`). Non-gated routes: function returns the unchanged findings list immediately (two-clause pattern).

**Example:**
```elixir
# Source: RouteGate.prepend_commerce_corridor_findings/3 (route_gate.ex line 64) — [VERIFIED: codebase]

defp prepend_gate_evaluation_findings(findings, %RouteEntry{gated_by: nil}, _target), do: findings
defp prepend_gate_evaluation_findings(findings, %RouteEntry{} = route, %Target{} = target) do
  companions = Application.get_env(:crosswake, :companions, [])
  enabled = Enum.filter(companions, fn c ->
    config = Application.get_env(:crosswake, c.companion_id(), %{})
    c.enabled?(config)
  end)

  case check_kill_switches(enabled, target) do
    {:killed, companion_id} ->
      denial = Denial.new(
        reason: :kill_switch_active,
        message: "route activation blocked: kill switch active",
        details: %{"companion_id" => Atom.to_string(companion_id)}
      )
      [denial | findings]  # or produce direct Finding equivalent — planner decides

    :ok ->
      case check_gate(enabled, route, target) do
        {:denied, finding} ->
          denial = Denial.new(
            reason: :gate_denied,
            message: finding.message || "route activation blocked: gate denied",
            details: %{
              "flag_key"     => Atom.to_string(route.gated_by),
              "reason"       => "DISABLED",
              "variant"      => "off",
              "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
            }
          )
          [denial | findings]

        :pass ->
          findings
      end
  end
end
```

**Note on direct Denial vs. finding_to_denial path:** The gate/kill-switch findings are prepended BEFORE the `finding_to_denial` mapping step. Options:
- Option A (recommended): Produce `Denial.t()` structs directly in `prepend_gate_evaluation_findings/3` and prepend them to `denials`, bypassing `finding_to_denial/2` entirely. This avoids awkward `finding.axis` mapping for axes that only exist as denial reasons, and keeps `flag_key`/`evaluated_at` stamping in RouteGate scope.
- Option B: Produce `Finding.t()` structs with new `:gate_denied` / `:kill_switch_active` axes and add cases to `finding_to_denial/2`. Requires threading `flag_key`/`evaluated_at` through the `Finding` struct or opts — more coupling.

The planner should pick Option A. The pipeline produces findings first, then maps them to denials — but gate/kill-switch can produce denials directly without the Finding intermediary if the planner structures the pipeline to accumulate denials directly.

### Pattern 2: Telemetry span wrapping companion callbacks

**What:** Each companion callback call is wrapped in `:telemetry.span/3` with static event name and `%{companion_id: atom(), route_id: binary() | nil}` metadata. This is the Keathley convention already used in Phase 38 for `validate_dependency`.

**When to use:** Every `kill_switch_active?/1` and `route_gated?/2` call.

**Example:**
```elixir
# Source: Doctor.phase_38_companion_seam_findings/0 (doctor.ex line 523) — [VERIFIED: codebase]

result =
  :telemetry.span(
    [:crosswake, :companion, :kill_switch],
    %{companion_id: companion.companion_id(), route_id: route.id},
    fn ->
      r = companion.kill_switch_active?(target)
      {r, %{companion_id: companion.companion_id(), route_id: route.id, result: r}}
    end
  )
```

### Pattern 3: Updating `transition_for/2` to `transition_for/3`

**What:** `transition_for/2` currently takes `(status, opts)`. It needs to additionally read `route.on_unavailable` to emit `{:redirect, id}` when `on_unavailable == {:fallback_phoenix, id}`. Thread `route` as the third argument.

**Impact on callers:**
- `RouteGate.evaluate/4` line 50 — call site; update to `transition_for(status, route, opts)`.
- No external callers pattern-match on `Decision.transition` in lib/ or test/ other than `compatibility_test.exs` line 112 (asserts `:stay_put` — still valid, non-gated route).
- `Activation.resolve/2` uses `decision.status`, not `decision.transition` — unaffected.
- `Doctor.phase_19_commerce_corridor_posture/1` uses `decision.denials` — unaffected.

**Example:**
```elixir
# Source: route_gate.ex line 54-62 + 40-CONTEXT.md D-01/D-02 — [VERIFIED: codebase + CONTEXT.md]

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

defp transition_for(:deny, nil, opts) do
  # nil route (unknown route_id) — cannot be gated, no fallback
  if Keyword.get(opts, :activation_source) == :in_app_navigation do
    :stay_put
  else
    :halt
  end
end
```

**Important:** The `{:fallback_phoenix, route_id}` clause must come BEFORE the general `:deny` clause (more specific pattern first in Elixir).

### Pattern 4: Fixture companion pattern for proof tests

**What:** Inline module definitions inside the test file, registered via `Application.put_env` in `setup_all` with `on_exit` cleanup. `async: false` required due to global Application state.

**Example:**
```elixir
# Source: phase38_companion_contract_test.exs + 40-CONTEXT.md D-13 — [VERIFIED: codebase]

defmodule GateCompanion do
  @behaviour Crosswake.Companion
  @impl true; def companion_id, do: :gate_companion
  @impl true; def enabled?(_), do: true
  @impl true; def kill_switch_active?(_target), do: false
  @impl true; def route_gated?(%RouteEntry{gated_by: :my_flag}, _target),
    do: {:deny, %Finding{axis: :gate_denied, route_id: "test", message: "gate denied"}}
  @impl true; def route_gated?(_route, _target), do: :pass
  @impl true; def validate_dependency, do: :ok
  @impl true; def report_state, do: %Crosswake.Companion.State{...}
end

setup_all do
  Application.put_env(:crosswake, :companions, [GateCompanion])
  on_exit(fn -> Application.delete_env(:crosswake, :companions) end)
  :ok
end
```

**Kill-switch spy pattern for SC#2 (route_gated?/2 never called):**
```elixir
# Use Process.put/get or Agent to record whether route_gated? was called
defmodule KillSwitchCompanion do
  @impl true
  def kill_switch_active?(_target) do
    Process.put(:kill_switch_active_called, true)
    true
  end
  @impl true
  def route_gated?(_route, _target) do
    Process.put(:route_gated_called, true)
    :pass
  end
end

# In test:
assert Process.get(:kill_switch_active_called) == true
assert Process.get(:route_gated_called) == nil
```

### Anti-Patterns to Avoid

- **Using `finding_to_denial/2` for gate/kill-switch axis mapping when `flag_key`/`evaluated_at` are in RouteGate scope:** Forces awkward threading of RouteGate context into the Compatibility layer. Produce `Denial.t()` directly instead. [VERIFIED: code review of finding_to_denial/2 at compatibility.ex lines 105-161]
- **Calling `kill_switch_active?` on non-gated routes:** Violates D-11 — only gated routes (`gated_by != nil`) trigger companion evaluation. Non-gated routes skip BOTH steps.
- **Adding `evaluated_at` as a `DateTime` struct to `Denial.details`:** `Types.to_map/1` has no special `DateTime` clause; pre-serialize to ISO8601 string immediately at stamp time. [VERIFIED: denial.ex `to_map/1` + types.ex `to_map/1`]
- **Using `:disabled` (atom) instead of `"DISABLED"` (string) for OpenFeature reason:** `Denial.details` is a plain `map()` that uses string keys/values. No atom-to-string translation happens in `to_map/1` for map values. [VERIFIED: D-05 + denial.ex line 74]
- **`async: true` in the proof test:** Causes Application.put_env race conditions with other proof tests that register companions. Must be `async: false`. [VERIFIED: phase38_companion_contract_test.exs comment + D-13]
- **Adding a `transition` field to `Denial.t()`:** The `Decision.transition` field (not `Denial`) carries routing intent. `Denial.status` stays `:deny` for all denial reasons. [VERIFIED: D-02]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Telemetry span emission | Manual `:start`/`:stop` telemetry.execute calls | `:telemetry.span/3` | Handles exceptions automatically; Keathley convention already used in Phase 38 |
| ISO8601 timestamp serialization | Custom formatter | `DateTime.utc_now() |> DateTime.to_iso8601()` | Stdlib, consistent with Ecto/Phoenix conventions; [VERIFIED: D-04] |
| Companion registry | Custom registry GenServer | `Application.get_env(:crosswake, :companions, [])` | Already established pattern; Doctor.ex line 515 [VERIFIED: codebase] |
| Denial construction | Inline struct literal | `Denial.new/1` keyword list | Runs `ensure_commerce_corridor_payload` guard; enforced keys validated |

## Runtime State Inventory

This is a pure code extension phase — no data migrations, no stored state, no external service registrations.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — manifest is compile-time; companion snapshots are in-process | None |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Common Pitfalls

### Pitfall 1: `transition_for` signature change breaks the existing `compatibility_test.exs` assertion

**What goes wrong:** `transition_for/2` is currently `(status, opts)`. If broadened to `(status, route, opts)` without updating the single internal call site in `evaluate/4`, the compiler produces a function-clause error.

**Why it happens:** The function is private — no compiler warning at call sites outside the module.

**How to avoid:** Update the `evaluate/4` call from `transition_for(status, opts)` to `transition_for(status, route, opts)` in the same task that updates the function definition.

**Warning signs:** Compile-time FunctionClauseError on `transition_for`.

### Pitfall 2: `Denial.new/1` raises because `:gate_denied` / `:kill_switch_active` not in `@reasons`

**What goes wrong:** `struct!(__MODULE__, ...)` in `Denial.new/1` does NOT validate the reason atom against `@reasons` — that list is for documentation/`reasons/0` only. But if a caller validates against `Denial.reasons()`, the new atoms will be absent.

**Why it happens:** `@reasons` is a module attribute list, not an enforced constraint in `struct!`. The `reason` typespec is what matters for Dialyzer.

**How to avoid:** Add `:gate_denied` and `:kill_switch_active` to BOTH `@reasons` and the `reason` typespec in `denial.ex`. The type addition enables Dialyzer checking; the `@reasons` addition ensures `Denial.reasons/0` returns the complete list (Phase 41 doctor will use this).

**Warning signs:** Dialyzer warning on `reason:` field; `refute :gate_denied in Denial.reasons()` test passing when it should fail.

### Pitfall 3: `route` is `nil` when `route_id` is unknown

**What goes wrong:** `RouteGate.evaluate/4` calls `Map.get(manifest.routes, route_id)` which returns `nil` for unknown routes. If `prepend_gate_evaluation_findings/3` is called with a nil route and pattern-matches on `%RouteEntry{}`, it will raise `FunctionClauseError`.

**Why it happens:** The existing `prepend_commerce_corridor_findings/3` already handles this with a second clause `defp prepend_...(findings, _route, _manifest), do: findings` (line 74). Gate evaluation must do the same.

**How to avoid:** Add a nil-guard clause first: `defp prepend_gate_evaluation_findings(findings, nil, _target), do: findings`. Unknown routes are handled by the existing `route_findings` pipeline which produces an `:inactive_route` denial.

**Warning signs:** FunctionClauseError in test with unknown route_id.

### Pitfall 4: `enabled?` config reads the companion's own atom as a nested key

**What goes wrong:** The companion dispatch pattern uses `Application.get_env(:crosswake, companion_id, %{})` to fetch the companion-specific config map (FunWithFlags-style, established in Phase 38 Doctor). This is NOT the same as `Application.get_env(:crosswake, :companions, [])`.

**Why it happens:** The companion registry key is `:companions`; each companion's config key is its `companion_id/0` atom. Easy to conflate.

**How to avoid:** In the gate evaluation loop, call `Application.get_env(:crosswake, c.companion_id(), %{})` to get the config map, then pass it to `c.enabled?(config_map)`.

**Warning signs:** Fixture companions reporting `enabled? == false` in tests when expected to be enabled; `Application.get_env(:crosswake, :gate_companion, %{})` returning `%{}` (empty map, `enabled?` must handle this by returning `true` for missing config).

### Pitfall 5: `{:fallback_phoenix, id}` guard clause ordering in `transition_for`

**What goes wrong:** If the general `:deny` clause comes before the `{:fallback_phoenix, id}` clause, the fallback is never matched.

**Why it happens:** Elixir matches function clauses top-to-bottom; the more specific pattern must precede the general one.

**How to avoid:** Order the clauses: `{:fallback_phoenix, ...}` clause FIRST among deny clauses.

**Warning signs:** SC#3 test assertion for `{:redirect, :home}` failing — getting `:halt` instead.

### Pitfall 6: SC#2 spy verification — `Process.get` returns `nil` when key never set

**What goes wrong:** Asserting `assert Process.get(:route_gated_called) == nil` works (nil means key was never set), but if the Process dictionary is shared between setup and test, a prior call could set a stale value.

**Why it happens:** Process dictionary persists within the test process unless explicitly cleared.

**How to avoid:** Use a unique key per test run, or use an Agent/counter. Alternatively, use `assert_receive`/`refute_receive` with a telemetry subscriber on `:route_gate` spans — if no span fires, `route_gated?` was never called.

## Code Examples

### Extending `Denial.@reasons` and typespec

```elixir
# Source: denial.ex lines 8-40 — extend pattern [VERIFIED: codebase]

@reasons [
  :compatibility_mismatch,
  :undeclared_capability,
  :unavailable_capability,
  :commerce_corridor,
  :origin_denied,
  :inactive_route,
  :external_entry_denied,
  :pack_incompatible,
  :gate_denied,           # NEW Phase 40
  :kill_switch_active     # NEW Phase 40
]

@type reason ::
        :compatibility_mismatch
        | :undeclared_capability
        | :unavailable_capability
        | :commerce_corridor
        | :origin_denied
        | :inactive_route
        | :external_entry_denied
        | :pack_incompatible
        | :gate_denied           # NEW
        | :kill_switch_active    # NEW
```

### Producing a `:gate_denied` Denial directly

```elixir
# Source: D-03, D-04, D-05, D-06, D-07 in 40-CONTEXT.md [VERIFIED: CONTEXT.md]

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

### Producing a `:kill_switch_active` Denial directly

```elixir
# Source: D-08 in 40-CONTEXT.md [VERIFIED: CONTEXT.md]

Denial.new(
  reason: :kill_switch_active,
  message: "route activation blocked: kill switch is active",
  route_id: route.id,
  details: %{
    "companion_id" => Atom.to_string(companion.companion_id())
  }
)
```

### `Decision.t()` typespec update

```elixir
# Source: route_gate.ex lines 18-24 — extend transition type [VERIFIED: codebase + D-01]

@type t :: %__MODULE__{
        route_id: String.t(),
        status: :allow | :deny,
        denial: Denial.t() | nil,
        denials: [Denial.t()],
        transition: :activate | :halt | :stay_put | {:redirect, atom()}
      }
```

### Phase 40 proof test skeleton

```elixir
# Source: D-12, D-13, D-14 in 40-CONTEXT.md + phase38 proof pattern [VERIFIED: codebase + CONTEXT.md]

defmodule Crosswake.Proof.Phase40GateEvaluationTest do
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types.RouteEntry

  # Inline fixture companions defined here
  defmodule GateDenyCompanion do
    @behaviour Crosswake.Companion
    # ... returns {:deny, finding} from route_gated?/2 for :test_flag
  end

  defmodule KillSwitchCompanion do
    @behaviour Crosswake.Companion
    # ... returns true from kill_switch_active?/1
  end

  # Inline gated router fixture
  defmodule GatedRouter do
    use Crosswake.Router
    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gated", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "gated", runtime: :live_view, gated_by: :test_flag]
      end
    end
  end

  setup_all do
    # companion registration done per-test in setup blocks
    :ok
  end

  # SC#1 — :gate_denied denial carries required OpenFeature fields
  test "SC#1: gate denied produces :gate_denied denial with flag_key, reason, variant, evaluated_at" do
    Application.put_env(:crosswake, :companions, [GateDenyCompanion])
    on_exit(fn -> Application.delete_env(:crosswake, :companions) end)
    # ...
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `transition: :activate \| :halt \| :stay_put` | `transition: :activate \| :halt \| :stay_put \| {:redirect, atom()}` | Phase 40 | Callers must handle the new tuple arm; existing non-gated callers (Activation, Doctor) are unaffected |
| `kill_switch_active?/1` and `route_gated?/2` defined but not called from RouteGate | Wired into RouteGate evaluation pipeline | Phase 40 | These callbacks now have live semantics |
| `Companion.State.gate_status` and `kill_switch_status` always `:unconfigured` | Meaningful for Phase 41 doctor reporting after Phase 40 wiring | Phase 40 | Phase 41 can read these statuses from `report_state/0` |

## Assumptions Log

No `[ASSUMED]` claims in this research. All findings are verified against the codebase or CONTEXT.md locked decisions.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (empty) | — | — |

**All claims in this research were verified against the codebase or CONTEXT.md locked decisions — no user confirmation needed.**

## Open Questions

1. **Direct Denial vs. Finding intermediary in the evaluate pipeline**
   - What we know: `evaluate/4` currently maps findings to denials with `Enum.map(findings, &finding_to_denial/2)`. Gate/kill-switch can produce `Denial.t()` directly.
   - What's unclear: Whether to accumulate gate denials separately and merge, or restructure to produce findings first.
   - Recommendation: Planner should produce `Denial.t()` directly in `prepend_gate_evaluation_findings/3` and prepend to the `denials` list (not the `findings` list) — or, equivalently, restructure the pipeline so gate evaluation happens after the findings-to-denials mapping and prepends directly to denials. The cleanest approach depends on exactly where in the pipeline the function is inserted.

2. **`route` nil-safety in `transition_for/3`**
   - What we know: `route` can be `nil` if `route_id` doesn't exist in manifest.
   - What's unclear: Whether `on_unavailable` should be checked for nil routes (it can't, since there's no route).
   - Recommendation: Add explicit nil guard: `defp transition_for(:deny, nil, opts)` → same as no-fallback deny.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Implementation | Yes | 1.19.5 | — |
| Erlang/OTP | Implementation | Yes | 28 | — |
| `:telemetry` | Span emission | Yes | `~> 1.0` in mix.exs | — |
| ExUnit | Proof test | Yes | stdlib | — |
| `phase34-proof.yml` CI | Automated proof gate | Yes | Confirmed at `.github/workflows/phase34-proof.yml` | — |

**Missing dependencies with no fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-03 | SC#1: `:gate_denied` denial with `flag_key`, `reason`, `variant`, `evaluated_at` all present and non-nil | hermetic proof | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` | Wave 0 |
| GATE-04 | SC#2: kill-switch companion returns `true` → `:kill_switch_active` denial; `route_gated?/2` never called | hermetic proof | same | Wave 0 |
| GATE-04 | SC#3: `on_unavailable: :deny` → `transition: :halt`; `on_unavailable: {:fallback_phoenix, :home}` → `transition: {:redirect, :home}` | hermetic proof | same | Wave 0 |
| GATE-02/GATE-04 | SC#4: No network call in evaluation path — pure function over manifest + registered companion modules | hermetic proof (no mock HTTP) | same | Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase40_gate_evaluation_test.exs` — covers SC#1–4 (entire file is new)

## Security Domain

Phase 40 implements the fail-closed gate evaluation that enforces feature-flag-gated route access. Relevant ASVS considerations:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | Yes | Fail-closed default — `:deny` when snapshot unavailable; only explicit `{:fallback_phoenix}` carve-out allowed |
| V5 Input Validation | No | No user input in evaluation path — all data from compiled manifest + companion callbacks |
| V6 Cryptography | No | No crypto in this phase |

**Key security property:** The fail-closed posture (`:deny` when no companion provides a pass, or when snapshot is unavailable) is structurally enforced by the first-deny-wins short-circuit. A companion returning `:pass` does not "open" a route — it simply does not deny it. The gate only opens when ALL enabled companions return `:pass` from `route_gated?/2` AND no kill switch is active. This is the correct AND-semantics for multi-companion gating.

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/compatibility/route_gate.ex` — direct code read; all `prepend_commerce_corridor_findings/3`, `maybe_add_finding/2`, `transition_for/2`, `Decision.t()` patterns verified
- `lib/crosswake/shell/denial.ex` — direct code read; `@reasons`, typespec, `Denial.new/1`, `to_map/1` verified
- `lib/crosswake/companion.ex` — direct code read; callback specs, telemetry event names, companion dispatch contract verified
- `lib/crosswake/companion/state.ex` — direct code read; `gate_status`/`kill_switch_status` fields verified
- `lib/crosswake/manifest/types.ex` — direct code read; `RouteEntry.gated_by`/`on_unavailable` fields verified
- `lib/crosswake/compatibility/compatibility.ex` lines 105-161 — direct code read; `finding_to_denial/2` extension point verified
- `lib/crosswake/shell/activation.ex` lines 91-121 — direct code read; `RouteGate.evaluate` call site; no `transition` pattern-match verified
- `lib/crosswake/doctor/doctor.ex` lines 488-530 — direct code read; Phase 38 telemetry span pattern + RouteGate.evaluate usage verified
- `test/crosswake/proof/phase38_companion_contract_test.exs` — direct code read; `async: false`, `Application.put_env` fixture pattern, telemetry test pattern verified
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` — direct code read; inline router fixture pattern verified
- `test/support/stub_companion.ex` — direct code read; StubCompanion and BrokenCompanion fixture patterns verified
- `.planning/phases/40-runtime-gate-evaluation-and-fail-closed-denial/40-CONTEXT.md` — all locked decisions D-01 through D-14

### Secondary (MEDIUM confidence)
- OpenFeature reason vocabulary (`STATIC`, `DEFAULT`, `TARGETING_MATCH`, `SPLIT`, `CACHED`, `DISABLED`, `UNKNOWN`, `STALE`, `ERROR`) — documented in D-05 of CONTEXT.md as OpenFeature standard; `"DISABLED"` and `"off"`/`"on"` as binary flag conventions are well-established in the OpenFeature ecosystem [CITED: OpenFeature specification via CONTEXT.md D-05/D-06]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing deps verified in codebase
- Architecture: HIGH — all patterns verified in existing codebase (route_gate.ex, doctor.ex, phase38 proof)
- Pitfalls: HIGH — derived from direct code reading of call sites and type signatures

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable internal Elixir plumbing; no external service dependencies)
