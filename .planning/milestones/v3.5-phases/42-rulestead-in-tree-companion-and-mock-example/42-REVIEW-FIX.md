---
phase: 42-rulestead-in-tree-companion-and-mock-example
fixed_at: 2026-05-30T00:00:00Z
review_path: .planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 42: Code Review Fix Report

**Fixed at:** 2026-05-30
**Source review:** `.planning/phases/42-rulestead-in-tree-companion-and-mock-example/42-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (CR-01, CR-02, WR-01, WR-02, WR-03)
- Fixed: 5
- Skipped: 0

All 13 proof tests pass after fixes (`mix test test/crosswake/proof/phase42_rulestead_companion_test.exs`).

## Fixed Issues

### CR-01: `route_gated?/2` crashes if `MockFlagSource` is not running

**Files modified:** `lib/crosswake/companions/rulestead.ex`
**Commit:** 8016889
**Applied fix:** Wrapped the `case MockFlagSource.get_flag(...)` in a `case Process.whereis(MockFlagSource)` nil-guard that returns `:pass` when the Agent is not running. This mirrors the identical pattern already present in `kill_switch_active?/1` and `report_state/0`. Now a supervisor restart race or test teardown will not crash the RouteGate pipeline.

---

### CR-02: `report_state/0` hardcodes `enabled: true` regardless of Application config

**Files modified:** `lib/crosswake/companions/rulestead.ex`, `test/crosswake/proof/phase42_rulestead_companion_test.exs`
**Commit:** 8016889 (source), afda320 (test)
**Applied fix:** Added `config = Application.get_env(:crosswake, :rulestead, %{})` and `enabled = Map.get(config, :enabled, false)` at the top of `report_state/0`, replacing the hardcoded `enabled: true` in the `%State{}` struct with `enabled: enabled`. Test assertion tightened from `is_boolean(state.enabled)` to `assert state.enabled == true` (setup puts `%{enabled: true}` in Application env).

---

### WR-01: `set_flag/2` typespec excludes `nil` but `config.exs` documents `set_flag(:rulestead, nil)` usage

**Files modified:** `lib/crosswake/companions/rulestead/mock_flag_source.ex`, `examples/phoenix_host/config/config.exs`
**Commit:** 4ae964b
**Applied fix:** Added `delete_flag/1` function to `MockFlagSource` (Option A from review):
```elixir
@doc "Removes the stored gate state for the given flag key."
@spec delete_flag(atom()) :: :ok
def delete_flag(flag_key) when is_atom(flag_key) do
  Agent.update(@name, &Map.delete(&1, flag_key))
end
```
Updated `config.exs` IEx workflow comment from `MockFlagSource.set_flag(:rulestead, nil)` to `MockFlagSource.delete_flag(:rulestead)` — the contract-compliant way to clear a flag.

---

### WR-02: `{:rolling_out, _}` denial message says "is disabled" — inaccurate

**Files modified:** `lib/crosswake/companions/rulestead.ex`
**Commit:** 8016889
**Applied fix:** Changed the `{:rolling_out, _pct}` branch `Finding` fields from `message: "#{route.gated_by} is disabled"` / `subject: "DISABLED"` to `message: "#{route.gated_by} is rolling out (partial gate)"` / `subject: "ROLLING_OUT"`. Applied as part of the same edit as CR-01 since both changes were in `route_gated?/2`.

---

### WR-03: `show_sensitive_data_on_connection_error: true` applies to all Mix environments

**Files modified:** `examples/phoenix_host/config/config.exs`
**Commit:** 4ae964b
**Applied fix:** Commented out `show_sensitive_data_on_connection_error: true` with an explanatory note:
```elixir
# show_sensitive_data_on_connection_error: true  # dev only — omitted (applies to all Mix envs)
```
This removes the credential-exposure risk while preserving the dev intent in a comment.

## Skipped Issues

None — all 5 in-scope findings were fixed.

---

_Fixed: 2026-05-30_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
