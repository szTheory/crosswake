---
phase: 191-integration-branch-and-local-suite
plan: 06
subsystem: testing
tags: [phase180, inversion, example-host, swift]
requires: [191-05]
provides: [LAND-02 Phase 180 probe inversions G2, G4, G6]
key-files:
  modified:
    - examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs (integration clone)
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift (integration clone)
status: complete
commits: 2
plan_head_before: 64a60effe28c38d0a1ce9741107cc44f570296be
plan_head_after: 6b9a6d9c52ae94fa8f1815256990d8feeda09b27
requirements-completed: []
---

# Phase 191 Plan 06: Phase 180 probe tests inverted Summary

Three Phase 180 probe tests that failed before now assert the facts the gate record decided, and both suites pass: the example host runs 167 tests with 0 failures, and Swift runs 89 tests with 0 failures and the two named G3 skips.

## What failed before and what each test now asserts

- Example host before: exactly two failures, the G2 and G6 gate tests (167 tests).
  - G6: exactly one route declares a host capability, the offline study route with only the host audio command, runtime offline_island (exact list equality).
  - G2: the generated activation for the probe equals the map holding the host audio command at 1.0.0.
  - After (commit HOST-G2G6): 167 tests, 0 failures.
- Swift before: exactly one failure, the G4 gate test (89 tests, 2 skipped).
  - G4: renamed `test_G4_gate_bounded_shell_admits_offline_island_runtime`; requires the offlineIsland result.
  - After (commit SWIFT-G4): 89 tests, 0 failures, exactly the two allowed G3 skips.
- G3 not inverted (A-7). Export-enabled run (example host wrote its own export, then Swift ran with it): 89 tests, 0 skips, 0 failures. This justifies the two default skips.

## Commits (integration clone, branch land/v25-v27)

- HOST-G2G6 `55708e5b` test(example): assert the decided Phase 180 G2 and G6 facts (one file)
- SWIFT-G4 `6b9a6d9c` test(ios): assert the decided Phase 180 G4 fact (one file)

Parent chain: PRIVACY `64a60eff` -> HOST-G2G6 -> SWIFT-G4. Both lines appended to heads-191.txt. No `.planning/` path changed in the clone; the clone status is clean after the export run.

## Evidence

suite-HOST-PRE, suite-HOST-G2G6, suite-SWIFT-PRE, suite-SWIFT-G4, suite-SWIFT-EXPORT, swift-allowed-skips-191.txt, phase180-inversions-191.md (all in 191-EVIDENCE). The inversions record also states that the Phase 180 pins are historical and that no CI lane runs the full example-host suite (a Phase 193 fact).

## Deviations from Plan

- Per amendment A-14, the expected parent of HOST-G2G6 was the PRIVACY commit (last heads line) rather than G1. Verified: the parent is PRIVACY.
- Commit trailers use `Co-Authored-By: Claude Sonnet 5.5` (the model that actually wrote them) instead of the Opus 5.5 text in the plan template.
- The root ledger check was not needed: no root `test/**` file was edited. Format and warnings-as-errors passed for both commits (the example-host file also checked by its own formatter).

## Self-Check: PASSED

The plan's two verify chains' conditions were checked: parents, single-file diffs, PRE failure sets, pass records bound to the new heads, floors met, zero skips in the export run, clean clone, no `.planning` diff.
