---
phase: 41-gating-doctor-and-support-matrix-truth
plan: "01"
subsystem: doctor-gating
tags: [doctor, companion, gating, typespec, proof]
requirements-completed: [GATE-05]

dependency-graph:
  requires: [phase-38-companion-seam, phase-39-route-policy-gating, phase-40-gate-evaluation]
  provides: [phase-41-gating-doctor-findings, phase-41-proof-sc1]
  affects: [lib/crosswake/companion/state.ex, lib/crosswake/doctor/doctor.ex, test/crosswake/proof/phase41_gating_doctor_test.exs]

tech-stack:
  added: []
  patterns: [per-phase-doctor-function, nil-guard-clause, flat_map-per-route-findings, Application.get_env-runtime-companion-resolution, MapSet-companion-id-lookup, hermetic-proof-with-inline-companion-fixtures]

key-files:
  created:
    - test/crosswake/proof/phase41_gating_doctor_test.exs
  modified:
    - lib/crosswake/companion/state.ex
    - lib/crosswake/doctor/doctor.ex

decisions:
  - Use :advisory (not :info) for per-route gating findings — :info is not in Check.severity() typespec; :advisory carries identical informational semantics without formatter changes
  - Extract gating_advisory_finding/1, gating_flag_reference_error/2, gating_fallback_route_warning/2 as private helpers for readability
  - Empty companions list triggers :error per gated route (D-05 — no separate top-level error, per-route pattern consistent)

metrics:
  duration_minutes: 25
  completed_date: "2026-05-30"
  tasks_completed: 3
  files_changed: 3
---

# Phase 41 Plan 01: Gating Doctor and Support Matrix Truth Summary

One-liner: Gating doctor category with per-route :advisory/:error/:warning findings, rolling_out typespec arm, and hermetic SC#1 proof — wired into Doctor.run/1.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend gate_status typespec with rolling_out arm | 90b1211 | lib/crosswake/companion/state.ex |
| 2 | Implement phase_41_gating_findings/1 and wire into run/1 | 1394f87 | lib/crosswake/doctor/doctor.ex |
| 3 | Create Wave 0 hermetic proof scaffold for SC#1 | ba7b6a6 | test/crosswake/proof/phase41_gating_doctor_test.exs |

## What Was Built

**Task 1 — gate_status typespec extension (D-06):**
Extended `@type gate_status` in `Crosswake.Companion.State` from `:active | :inactive | :unconfigured` to add `{:rolling_out, non_neg_integer()}` as a fourth arm. Purely additive; `kill_switch_status` is unchanged. Mirrors the `{:fallback_phoenix, atom()}` tagged-tuple pattern used in `RouteEntry.on_unavailable`.

**Task 2 — phase_41_gating_findings/1 (D-01 through D-05, D-09, D-10):**
Added a dedicated "Gating" doctor category via `defp phase_41_gating_findings/1` with:
- Nil-guard clause (`phase_41_gating_findings(nil), do: []`) per established nil-manifest convention
- Filters `manifest.routes` on `gated_by != nil`, then `flat_map`s three potential findings per route:
  1. `:advisory` `"gating.route_gated"` — one per gated route; surfaces posture (nil → fail-closed/implicit deny, :deny → explicit, {:fallback_phoenix, id} → redirect with non-nil hint per D-09)
  2. `:error` `"gating.flag_reference_unknown"` — when `gated_by` atom is not in the `MapSet` of registered companion ids (fires per-route including when companions list is empty, per D-05)
  3. `:warning` `"gating.fallback_route_unknown"` — when `{:fallback_phoenix, fallback_id}` target route is absent from `manifest.routes` (D-10; :warning not :error because gate is still fail-closed)
- Uses `Application.get_env(:crosswake, :companions, [])` (not `compile_env`) for test fixture compatibility
- Does NOT call `validate_dependency` or `report_state` (Phase 38 owns dependency validation)
- Wired into `run/1` after `phase_38_findings`, appended to findings accumulator

Three private helper functions extracted for readability: `gating_advisory_finding/1`, `gating_flag_reference_error/2`, `gating_fallback_route_warning/2`.

**Task 3 — hermetic proof scaffold (SC#1):**
Created `test/crosswake/proof/phase41_gating_doctor_test.exs` with `Crosswake.Proof.Phase41GatingDoctorTest`:
- `async: false` (shared `Application.put_env(:crosswake, :companions, ...)` key)
- Inline `GatingFixtureCompanion` (companion_id: `:test_gating_companion`)
- `GatedRoutesRouter` with 3 gated routes (resolvable, unresolvable, fallback-missing)
- 6 `@tag :sc1` tests covering all finding codes and edge cases
- 1 hermeticity self-assertion test (refutes example-host router and `Code.require_file`)
- All 7 tests pass; full suite 363 tests, 0 failures

## Verification Results

- `mix compile --warnings-as-errors` exits 0
- `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1` exits 0, 6 tests pass
- `mix test --exclude requires_example_host` exits 0, 363 tests pass (38 excluded)

## Deviations from Plan

### Severity Decision Applied

**[Plan directive] Use :advisory not :info for per-route gating findings**
- The plan's `<severity_decision>` section explicitly resolved this: `Check.severity()` typespec is `:error | :warning | :advisory` only; `:info` atom would raise `FunctionClauseError` at the formatter's `severity_order/1`. Used `:advisory` throughout. No deviation from plan — this was a pre-resolved ambiguity.

### Implementation Refinement

**[Rule 2 - Missing pattern] Extracted private helper functions**
- Split the flat_map body into three private functions (`gating_advisory_finding/1`, `gating_flag_reference_error/2`, `gating_fallback_route_warning/2`) instead of an inline anonymous function. This matches the readability of Phase 38/19 patterns and keeps each finding's construction logic separately testable. Plan's `<action>` described the logic inline; helper extraction is a style improvement within scope.

## Known Stubs

None — all findings are wired to live manifest data via `Doctor.run/1`.

## Threat Flags

No new security-relevant surface introduced. T-41-02 mitigation (`phase_41_gating_findings(nil), do: []` nil-guard) implemented as specified in the plan's threat model.

## Self-Check: PASSED

- [x] `lib/crosswake/companion/state.ex` contains `{:rolling_out, non_neg_integer()}`
- [x] `lib/crosswake/doctor/doctor.ex` contains `phase_41_gating_findings` (2 clauses) and all three finding codes
- [x] `test/crosswake/proof/phase41_gating_doctor_test.exs` exists and defines `Phase41GatingDoctorTest`
- [x] Commits 90b1211, 1394f87, ba7b6a6 all present in git log
- [x] All 3 verification gates pass (compile, SC#1 tests, full suite)
