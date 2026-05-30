---
phase: 41-gating-doctor-and-support-matrix-truth
plan: "02"
subsystem: support-matrix-gating-truth
tags: [support-matrix, gating, companion, proof, runtime-truth]
requirements-completed: [GATE-05]

dependency-graph:
  requires: [phase-41-plan-01-gating-doctor]
  provides: [phase-41-proof-sc2, support-matrix-gating-truth]
  affects: [lib/crosswake/support_matrix/support_matrix.ex, test/crosswake/proof/phase41_gating_doctor_test.exs]

tech-stack:
  added: []
  patterns: [Application.get_env-runtime-companion-resolution, D-08-locked-display-strings, kill-switch-clause-ordering-precedence, gating_truth_label-runtime-distinct-labeling]

key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - test/crosswake/proof/phase41_gating_doctor_test.exs

decisions:
  - Kill-switch clause placed first in gate_state_display/1 pattern match (RESEARCH critical pitfall) — kill_switch_status: :active overrides gate_status regardless of its value
  - gating_truth_label/0 returns "Runtime Gate State — not build-proof posture" as a public accessor (D-08) so the SC#2 label assertion is testable via a direct function call
  - SC#2d assertion uses String.downcase(label) for case-insensitive "runtime" check since the label uses title-case "Runtime" — correct design, test accommodates casing

metrics:
  duration_minutes: 15
  completed_date: "2026-05-30"
  tasks_completed: 2
  files_changed: 2
---

# Phase 41 Plan 02: Support Matrix Gating Truth Summary

One-liner: gating_truth/0 runtime gate-state accessor maps report_state/0 to D-08 display strings (gated/rolling_out/killed) with kill-switch precedence, labeled runtime-distinct from build-proof posture; SC#2 proof asserts all three display strings plus the label.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add gating_truth/0 accessor and gate_state_display/1 mapping | 50e768d | lib/crosswake/support_matrix/support_matrix.ex |
| 2 | Add SC#2 support-matrix proof coverage | 311a84a | test/crosswake/proof/phase41_gating_doctor_test.exs |

## What Was Built

**Task 1 — gating_truth/0 + gate_state_display/1 + gating_truth_label/0:**

Added three public/private functions to `Crosswake.SupportMatrix`:

- `gating_truth_label/0` (`@spec :: String.t()`) — returns the D-08 runtime-distinct column label `"Runtime Gate State — not build-proof posture"`. Exposed as a public accessor so the SC#2 label assertion can call it directly without hardcoding the string in tests.

- `gating_truth/0` (`@spec :: [map()]`) — reads `Application.get_env(:crosswake, :companions, [])` at call time (NOT compile_env) for test fixture compatibility. Iterates companions, calls `companion.report_state()` per companion, and maps each to `%{companion_id: state.companion_id, gate_state: gate_state_display(state)}`. Documented with the D-08 note that `"rolling_out (N%)"` is never equivalent to "supported."

- `gate_state_display/1` (private, `@spec :: String.t() | nil`) — pattern-matches on `%Crosswake.Companion.State{}`. Clause ordering implements kill-switch precedence (RESEARCH critical pitfall): the `kill_switch_status: :active` clause comes BEFORE any `gate_status` clause, so an active kill switch returns `"killed"` regardless of `gate_status`. Full D-08 mapping:
  - `kill_switch_status: :active` → `"killed"`
  - `gate_status: :active` → `"gated"`
  - `gate_status: {:rolling_out, n}` → `"rolling_out (#{n}%)"`
  - `gate_status: :inactive` → `nil`
  - `gate_status: :unconfigured` → `nil`

**Task 2 — SC#2 proof coverage:**

Extended `test/crosswake/proof/phase41_gating_doctor_test.exs` with SC#2 tests. Added:

- Three inline `@behaviour Crosswake.Companion` fixture modules:
  - `GatingActiveCompanion` — `gate_status: :active`, `kill_switch_status: :inactive`
  - `RollingOutCompanion` — `gate_status: {:rolling_out, 10}`, `kill_switch_status: :inactive`
  - `KillSwitchActiveCompanion` — `gate_status: :active` AND `kill_switch_status: :active` (kill-switch precedence proof)

- Five `@tag :sc2` tests:
  - SC#2a: `gating_truth/0` returns `gate_state: "gated"` for active-gate fixture
  - SC#2b: `gating_truth/0` returns `gate_state: "rolling_out (10%)"` for rolling-out fixture
  - SC#2c: `gating_truth/0` returns `gate_state: "killed"` for kill-switch fixture with non-inactive `gate_status` (proves kill-switch overrides)
  - SC#2d: `gating_truth_label/0` returns string containing `"runtime"` (case-insensitive) and `"not build-proof"`
  - SC#2e: all three display strings present when all three fixture types registered simultaneously

Updated `@moduledoc` to describe both SC#1 and SC#2.

## Verification Results

- `mix compile --warnings-as-errors` exits 0 (64 files compiled, no warnings)
- `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1` exits 0, 6 tests pass
- `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc2` exits 0, 5 tests pass
- `mix test test/crosswake/proof/phase41_gating_doctor_test.exs` exits 0, 12 tests pass (6 SC#1 + 5 SC#2 + 1 hermeticity)
- `mix test --exclude requires_example_host` exits 0, 368 tests, 0 failures (38 excluded)

## Deviations from Plan

### Implementation Refinement

**[Rule 1 - Bug] SC#2d case-sensitivity fix**
- **Found during:** Task 2 verification run
- **Issue:** `gating_truth_label/0` returns `"Runtime Gate State — not build-proof posture"` (title-case `"Runtime"`); test assertion checked for lowercase `"runtime"` with `String.contains?(label, "runtime")` which fails
- **Fix:** Changed assertion to `String.contains?(String.downcase(label), "runtime")` — the label is correct per D-08; the test accommodates the label's casing rather than forcing the public API to use lowercase
- **Files modified:** `test/crosswake/proof/phase41_gating_doctor_test.exs`
- **Commit:** 311a84a (included in Task 2 commit)

## Known Stubs

None — `gating_truth/0` reads live `Application.get_env` companions and calls `report_state()` dynamically. No hardcoded empty returns.

## Threat Flags

No new security-relevant surface introduced beyond what the plan's threat model addressed (T-41-04, T-41-05, T-41-06). T-41-05 mitigation (gate_state_display/1 clauses cover all five D-08 cases) implemented as specified — the pattern match is exhaustive over the `gate_status` union extended in plan 01.

## Self-Check: PASSED

- [x] `lib/crosswake/support_matrix/support_matrix.ex` defines `def gating_truth` with `@spec gating_truth() :: [map()]`
- [x] `gating_truth/0` calls `Application.get_env(:crosswake, :companions, [])` (not compile_env)
- [x] `gate_state_display/1` has `kill_switch_status: :active` clause BEFORE any `gate_status` clause
- [x] Display strings `"killed"`, `"gated"`, `"rolling_out (#{n}%)"` and nil returns all present
- [x] `gating_truth_label/0` returns text containing both "Runtime" and "not build-proof"
- [x] `test/crosswake/proof/phase41_gating_doctor_test.exs` contains `@tag :sc2` on support-matrix tests
- [x] SC#2a/b/c/d/e assertions all present and passing
- [x] Commits 50e768d and 311a84a present in git log
- [x] All verification gates pass (compile, SC#2 tests, full suite)
