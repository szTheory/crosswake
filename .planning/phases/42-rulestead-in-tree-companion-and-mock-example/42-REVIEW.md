---
phase: 42-rulestead-in-tree-companion-and-mock-example
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - examples/phoenix_host/config/config.exs
  - examples/phoenix_host/lib/crosswake_example/application.ex
  - examples/phoenix_host/lib/crosswake_example/beta_feature_live.ex
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - lib/crosswake/companions/rulestead.ex
  - lib/crosswake/companions/rulestead/mock_flag_source.ex
  - test/crosswake/proof/phase42_rulestead_companion_test.exs
findings:
  critical: 2
  warning: 3
  info: 3
  total: 8
status: issues_found
---

# Phase 42: Code Review Report

**Reviewed:** 2026-05-30
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This phase delivers the Rulestead in-tree companion (`Crosswake.Companions.Rulestead`), a `MockFlagSource` named Agent for local dev and hermetic tests, and proof tests covering SC#1 (gate state translation) and SC#3 (Doctor dependency findings). The core state-machine logic and RouteGate integration are sound. Two blocking defects were found: `route_gated?/2` will crash if `MockFlagSource` is not running (no nil-guard, unlike `kill_switch_active?/1`), and `report_state/0` hardcodes `enabled: true` instead of reading `Application.get_env`, causing it to misreport state when the companion is disabled. Three warnings cover a nil-usage/typespec mismatch for `set_flag/2`, a misleading denial message for `{:rolling_out, _}`, and `show_sensitive_data_on_connection_error: true` living in the only config file (all environments).

---

## Critical Issues

### CR-01: `route_gated?/2` crashes if `MockFlagSource` is not running

**File:** `lib/crosswake/companions/rulestead.ex:33`

**Issue:** `route_gated?/2` calls `MockFlagSource.get_flag(route.gated_by)` directly via `Agent.get/2`. If the named Agent process is not running, `Agent.get` raises `** (EXIT) no process` and the caller crashes. By contrast, `kill_switch_active?/1` (line 72) and `report_state/0` (line 122) both guard with `Process.whereis(MockFlagSource)` before touching the Agent. The asymmetry means a supervisor restart race, a test that calls `stop_supervised!/1`, or any deployment where `MockFlagSource` was never started will crash the RouteGate pipeline at route evaluation time instead of failing gracefully.

The test suite includes an explicit nil-guard test for `kill_switch_active?/1` (`"kill_switch_active?/1 is nil-guarded — returns false when MockFlagSource not running"`) but has no equivalent for `route_gated?/2`.

**Fix:**

```elixir
@impl true
@doc false
def route_gated?(route, _target) do
  case Process.whereis(MockFlagSource) do
    nil ->
      # MockFlagSource not running — fail-open for gate (do not block requests)
      :pass

    _pid ->
      case MockFlagSource.get_flag(route.gated_by) do
        :gated ->
          {:deny,
           %Finding{
             axis: :gate_denied,
             route_id: route.id,
             message: "#{route.gated_by} is gated",
             subject: "GATED"
           }}

        {:rolling_out, _pct} ->
          {:deny,
           %Finding{
             axis: :gate_denied,
             route_id: route.id,
             message: "#{route.gated_by} is rolling out",
             subject: "ROLLING_OUT"
           }}

        _ ->
          :pass
      end
  end
end
```

---

### CR-02: `report_state/0` hardcodes `enabled: true` regardless of Application config

**File:** `lib/crosswake/companions/rulestead.ex:159`

**Issue:** `report_state/0` constructs the `State` struct with `enabled: true` unconditionally. It never reads `Application.get_env(:crosswake, :rulestead, %{})` to determine the runtime-configured value. This means:

1. When the companion is disabled in config (`%{enabled: false}`), `report_state/0` still reports `enabled: true` — the state snapshot is wrong.
2. The SC#3b test (`"no companion.dependency_missing finding when rulestead companion is disabled"`) sets `Application.put_env(:crosswake, :rulestead, %{enabled: false})` and then calls `Doctor.run`. Doctor calls `companion.enabled?(config_map)` correctly, so the Doctor test passes. But any consumer of `report_state/0` (monitoring dashboard, telemetry, etc.) receives a falsified enabled status.

**Fix:**

```elixir
def report_state do
  config = Application.get_env(:crosswake, :rulestead, %{})
  enabled = Map.get(config, :enabled, false)

  # ... existing dependency_status and gate_status logic ...

  %State{
    companion_id: :rulestead,
    enabled: enabled,   # reads actual config instead of hardcoding true
    dependency_status: dependency_status,
    gate_status: gate_status,
    kill_switch_status: kill_switch_status,
    checked_at: System.monotonic_time(:millisecond)
  }
end
```

The `report_state` test (`"report_state/0 returns a fully-populated Crosswake.Companion.State struct"`) asserts `is_boolean(state.enabled)` which passes for either value. Add a direct assertion:

```elixir
assert state.enabled == true  # setup sets %{enabled: true}
```

---

## Warnings

### WR-01: `set_flag/2` typespec excludes `nil` but `config.exs` documents `set_flag(:rulestead, nil)` as the "clear flag" pattern

**File:** `lib/crosswake/companions/rulestead/mock_flag_source.ex:36` and `examples/phoenix_host/config/config.exs:31`

**Issue:** The `@type gate_state` (line 17) and `@spec set_flag(atom(), gate_state())` (line 36) exclude `nil`. The `@doc` for `set_flag/2` says "must be `:gated`, `{:rolling_out, n}`, or `:killed`". Yet the config.exs comment at line 31 documents `MockFlagSource.set_flag(:rulestead, nil)` as the way to "clear flag". Dialyzer will warn on the `nil` call. At runtime, `set_flag(:rulestead, nil)` succeeds silently (no guard), stores `nil` in the map, and `get_flag/1` returns `nil` — which happens to produce `:pass` in `route_gated?/2`. This works by accident but violates the stated contract, and a future code change that relies on the typespec will be misled.

**Fix — Option A** (preferred): add a `delete_flag/1` function and update the config.exs comment:

```elixir
@doc "Removes the stored gate state for the given flag key."
@spec delete_flag(atom()) :: :ok
def delete_flag(flag_key) when is_atom(flag_key) do
  Agent.update(@name, &Map.delete(&1, flag_key))
end
```

Update `config.exs` line 31:
```elixir
#   MockFlagSource.delete_flag(:rulestead)              # clear flag
```

**Fix — Option B**: widen the typespec to `gate_state() | nil` and document the nil-stores-nil-returns-pass behavior explicitly. Less preferred because the doc still says "must be one of three values".

---

### WR-02: `{:rolling_out, _}` denial message says "is disabled" — inaccurate

**File:** `lib/crosswake/companions/rulestead.ex:52-53`

**Issue:** The `{:rolling_out, _pct}` arm returns a `Finding` with `message: "#{route.gated_by} is disabled"` and `subject: "DISABLED"`. A route under rolling-out is not disabled — it is intentionally gating a percentage of traffic. While `RouteGate.check_gate/3` discards this `Finding` and builds its own `Denial` (line 148 pattern `{:deny, _finding} -> ...`), the inaccurate message is observable if `route_gated?/2` is called directly (e.g., from a companion unit test, a future monitoring hook, or the Phase 43 real adapter). This will mislead debugging.

**Fix:**

```elixir
{:rolling_out, _pct} ->
  {:deny,
   %Finding{
     axis: :gate_denied,
     route_id: route.id,
     message: "#{route.gated_by} is rolling out (partial gate)",
     subject: "ROLLING_OUT"
   }}
```

---

### WR-03: `show_sensitive_data_on_connection_error: true` in the only config file — applies to all Mix environments

**File:** `examples/phoenix_host/config/config.exs:12`

**Issue:** `config.exs` is the single config file for the `crosswake_example` Phoenix host (confirmed: no `dev.exs`, `prod.exs`, or `runtime.exs` exist). The `show_sensitive_data_on_connection_error: true` Ecto/SQLite option exposes connection credentials in error messages. With only one config file, this setting applies to `MIX_ENV=prod` as well. Even for an example app that is unlikely to be deployed, this is a correctness error: `start_permanent: Mix.env() == :prod` in `mix.exs` indicates the project has production intent.

**Fix:** Either split config into `config/dev.exs` and keep this option there, or remove it from `config.exs`:

```elixir
# Remove or move to dev.exs only:
# show_sensitive_data_on_connection_error: true
```

---

## Info

### IN-01: `CrosswakeExample.CameraLive` defined in `router.ex` but never routed — dead code

**File:** `examples/phoenix_host/lib/crosswake_example/router.ex:14-20`

**Issue:** `CrosswakeExample.CameraLive` is defined inline in `router.ex` (lines 14-20) but is not referenced by any route in the file. It will compile and load but is never reachable.

**Fix:** Remove the unused module definition from `router.ex`, or add a route if the intent was to include it.

---

### IN-02: The `Finding` struct fields returned from `route_gated?/2` are silently discarded by `RouteGate`

**File:** `lib/crosswake/companions/rulestead.ex:36-54`

**Issue:** `RouteGate.check_gate/3` matches `{:deny, _finding}` (discarding the `Finding`) and constructs its own `Denial` from the route and companion context. The `message`, `subject`, `axis`, and `hint` fields built inside `route_gated?/2` are never surfaced through the standard routing flow. This is not wrong — the `Companion` behaviour contract only requires `{:deny, Finding.t()}` to signal a denial — but the dead fields add maintenance cost and confusion for anyone adding Phase 43 adapter logic who might expect these fields to appear in denial output.

**Fix (low priority):** Add a code comment to `route_gated?/2` noting that the `Finding` payload is consumed only by direct callers; `RouteGate` uses only the `:deny` tag:

```elixir
# NOTE: RouteGate.check_gate/3 pattern-matches {:deny, _finding} and builds
# its own Denial struct — the fields below are only observable to direct callers
# (unit tests, Phase 43 adapter wrappers). Keep them accurate for debuggability.
```

---

### IN-03: `report_state` test assertion for `gate_status` is overly permissive

**File:** `test/crosswake/proof/phase42_rulestead_companion_test.exs:267-270`

**Issue:** The `"report_state/0 returns a fully-populated Crosswake.Companion.State struct"` test asserts `gate_status in [:active, :inactive, :unconfigured] or match?({:rolling_out, _}, ...)`. Because the setup does not set any flags, `gate_status` will always be `:unconfigured` at test time. The permissive assertion allows `:active` or `:inactive`, which would indicate a leaked flag state from a concurrent test — precisely the class of bug `async: false` is meant to prevent, but the assertion would not catch it.

**Fix:** Tighten the assertion to match the known setup state:

```elixir
# No flags set in setup -> gate should be unconfigured
assert state.gate_status == :unconfigured
assert state.kill_switch_status == :unconfigured
```

---

_Reviewed: 2026-05-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
