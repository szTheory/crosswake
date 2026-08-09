---
phase: 159-host-reusable-proof-lane
plan: "15"
subsystem: native proof verification
tags: [ios, xctest, xcuitest, proof-lane, host-adapter, accessibility]
requires:
  - phase: 159-14
    provides: fresh final-tree proof-lane gate
provides:
  - exact host-adapter evidence gate for generated iOS proof
  - deterministic nil-adapter blocked regression
affects: [proof-lane, PROOF-01, PROOF-03]
tech-stack:
  added: []
  patterns: [exact bundle-qualified test markers, adapter-derived UI lifecycle, accessibility reflow contract]
key-files:
  created: []
  modified:
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/crosswake/proof_lane/ios_verifier_test.exs
decisions:
  - "Generated iOS proof exits passed only after exact host-adapter XCTest, adapter-derived lifecycle XCUITest, and accessibility-reflow XCUITest markers."
  - "A nil host adapter is a deterministic blocked proof outcome; unavailable and blocked remain rendered but non-passing states."
metrics:
  duration: 10m
  completed: 2026-08-01
  tasks_completed: 1
  files_changed: 5
status: complete
---

# Phase 159 Plan 15: Host Adapter Evidence Summary

Generated iOS proof now fails closed until the shared scheme records exact adapter-backed XCTest and XCUITest evidence, including accessibility reflow coverage.

## Completed Work

- Replaced the generated XCTest fixture acceptance with a non-nil host-adapter assertion requiring a booted, adapter-derived `passed` state.
- Replaced the UI lifecycle acceptance of `Unavailable` with launch/relaunch assertions for adapter-derived `Passed` state.
- Added generated accessibility-size assertions for 24pt horizontal containment, full untruncated labels, no scroll views, and the conditional 44x44pt retry target.
- Tightened the verifier to require all three exact bundle-qualified completion markers before emitting its closed passed JSON outcome.
- Added hermetic regressions proving generic bundle output and an untouched generated nil-factory lane both exit blocked with `PL-IOS-TEST-EVIDENCE`.

## Task Commits

1. Task 1 RED — `cce4808f` test(159-15): reject generic iOS proof evidence
2. Task 1 GREEN — `11a4fda9` feat(159-15): require host adapter proof evidence

## Verification

- `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — passed (12 tests).
- `bash -n script/verify_generated_ios_shell.sh` — passed.
- `mix format --check-formatted test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — passed.

Actual simulator/XCUITest execution remains advisory under D-14 and was not used to promote this plan.

## TDD Gate Compliance

- RED commit `cce4808f` records the generic-evidence false-pass regression before the verifier implementation.
- GREEN commit `11a4fda9` follows it with the minimal exact-evidence gate and generated test assertions.

## Decisions Made

- Passed proof requires exact named, bundle-qualified host-adapter, lifecycle, and accessibility-reflow assertion completions; generic test execution is insufficient.
- The generated default factory remains host-owned and nil, so an untouched lane is honestly blocked rather than reported as passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Created the generated-host root in the deterministic nil-adapter regression.
- **Found during:** Task 1 GREEN verification.
- **Issue:** The generator correctly rejects a nonexistent host root, preventing the regression from exercising the untouched generated lane.
- **Fix:** Created the temporary host root before generation in the test fixture.
- **Files modified:** `test/crosswake/proof_lane/ios_verifier_test.exs`
- **Commit:** `cce4808f`

## Known Stubs

None. The nil default host-adapter factory is intentional fail-closed behavior, not a stub.

## Self-Check: PASSED

- All five declared implementation artifacts exist in the working tree.
- Task commits `cce4808f` and `11a4fda9` exist in Git history.
