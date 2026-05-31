---
phase: 47-companion-arc-guide-and-milestone-proof
plan: "02"
subsystem: companions
tags: [companions, proof, hermetic, sigra, doctor]
requires: []
provides:
  - aggregate milestone hermetic proof for Rulestead, Rindle, and Sigra contract posture
affects: [PROOF-02]
tech-stack:
  added: []
  patterns: [aggregate companion proof, hermetic lane guard assertions, contract-only auth posture checks]
key-files:
  created:
    - .planning/phases/47-companion-arc-guide-and-milestone-proof/47-02-SUMMARY.md
  modified:
    - test/crosswake/proof/phase47_companion_arc_test.exs
key-decisions:
  - "Keep Phase 47 proof untagged and lane-neutral so existing hermetic workflow picks it up automatically."
  - "Prove Sigra via auth-contract support truth and :step_up_required RouteGate behavior only."
requirements-completed: [PROOF-02]
duration: 21min
completed: 2026-05-31
---

# Phase 47 Plan 02: Companion Arc Guide And Milestone Proof Summary

**Closed the milestone-proof half of PROOF-02 with one untagged aggregate hermetic test that proves fail-closed optional-dependency behavior for Rulestead and Rindle and contract-only Sigra auth posture.**

## Performance

- **Duration:** 21 min
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `test/crosswake/proof/phase47_companion_arc_test.exs` as an untagged ExUnit proof module.
- Proved enabled+missing optional dependencies produce separate doctor `companion.dependency_missing` `:error` findings for `companion.rulestead` and `companion.rindle`.
- Proved disabled companion configs suppress `companion.dependency_missing` findings.
- Added Sigra-side assertions through `SupportMatrix.auth_contract_truth/0` plus `RouteGate.evaluate/4` `:step_up_required` denial behavior.
- Added hermeticity guard tests for no `@moduletag :advisory_only`, no example-host dependency, no `Code.require_file/2`, and no advisory-env assumptions.

## Verification

- `mix test test/crosswake/proof/phase47_companion_arc_test.exs` (pass)
- `mix test --exclude requires_example_host --exclude advisory_only` (pass; 455 tests, 0 failures)

## Task Commits

1. **Task 1: Create aggregate fail-closed companion dependency proof** - `1630e5a` (test)
2. **Task 2: Fold Sigra auth posture and hermetic lane guards into proof** - `bed585a` (test)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Auth test used non-contract auth context shape**
- **Found during:** Task 2 verification
- **Issue:** RouteGate denial detail assertions failed because test passed a plain map instead of `Sigra.Contracts.AuthContext`.
- **Fix:** Switched to `struct!(AuthContext, ...)` before `RouteGate.evaluate/4`.
- **Files modified:** `test/crosswake/proof/phase47_companion_arc_test.exs`
- **Verification:** `mix test test/crosswake/proof/phase47_companion_arc_test.exs`
- **Commit:** `bed585a`

**2. [Rule 1 - Bug] Hermetic guard checks self-matched literal strings**
- **Found during:** Task 2 verification
- **Issue:** String-contains assertions falsely matched literals present inside the guard test itself.
- **Fix:** Replaced with regex/concatenated-token checks that validate actual prohibited patterns without self-matching.
- **Files modified:** `test/crosswake/proof/phase47_companion_arc_test.exs`
- **Verification:** `mix test test/crosswake/proof/phase47_companion_arc_test.exs`
- **Commit:** `bed585a`

## Known Stubs

None.

## Threat Flags

None.

## Next Phase Readiness

- Phase 47 is complete after this plan close-out; milestone proof and companion guide are both in place.

## Self-Check: PASSED

- Summary file exists: `.planning/phases/47-companion-arc-guide-and-milestone-proof/47-02-SUMMARY.md`
- Task commits exist in git history: `1630e5a`, `bed585a`
