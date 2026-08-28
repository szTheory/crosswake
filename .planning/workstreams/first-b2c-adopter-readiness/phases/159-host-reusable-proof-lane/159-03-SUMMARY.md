---
phase: 159-host-reusable-proof-lane
plan: "03"
subsystem: host-reusable proof lane
tags: [playwright, xctest, xcuittest, ios, proof]
requires: [159-01]
provides: [offline-island-semantic-adapter, explicit-native-prerequisites, advisory-ios-target-validation]
affects: [PROOF-01, PROOF-03]
tech-stack:
  added: []
  patterns: [host-owned-adapters, missing-only-generation, closed-native-outcomes]
key-files:
  created:
    - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
    - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  modified:
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
    - lib/crosswake/proof_lane/generator.ex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
decisions:
  - The original browser corpus remains the primary proof while a host callback adapter owns reusable semantic sequencing.
  - Generated native targets return closed blocked or unavailable prerequisites until later auth/replay and pack/audio phases provide host adapters.
  - Local iOS target build results are advisory and do not promote simulator or physical-device support.
metrics:
  tasks_completed: 2
  files_changed: 10
  completed_date: 2026-07-31
status: complete
---

# Phase 159 Plan 03: Host-Reusable Proof Lane Summary

The proof lane preserves the existing browser mutation proof while supplying host-owned TypeScript and iOS XCTest/XCUITest boundaries with explicit non-passing future prerequisites.

## Completed Work

- Extracted `runOfflineIslandProof` behind the LearnLoop wrapper, preserving existing browser exports and the real UI mutation, IndexedDB observation, app reconnect, backend confirmation, empty-outbox, and duplicate-idempotency sequence.
- Added a generated host adapter with an opaque mutation-ID field-path extractor and no example-host product contract.
- Generated a proof-owned Swift app, test-only driver contract, concrete XCTest prerequisite assertions, and XCUITest accessibility lifecycle checks that terminate and relaunch without clearing state.
- Extended the generator and template contracts so browser/native host edits are byte-preserved on rerun.
- Added `--proof-lane` advisory iOS verification: it enumerates the two generated test targets and attempts `build-for-testing` without device promotion.

## Verification

- `mix test test/crosswake/proof_lane/template_contract_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed (9 tests).
- `npm --prefix examples/phoenix_host test -- offline_sync.spec.ts` — passed (1 Playwright test).
- `bash script/verify_generated_ios_shell.sh --proof-lane` — advisory result: local simulator/signing setup did not build the generated targets; no simulator or device support was claimed.
- `bash -n script/verify_generated_ios_shell.sh` — passed.

## TDD Gate Compliance

- RED: `278696f0` and `f45a7088` added failing template contracts.
- GREEN: `87bb33b1` and `99b2e39c` implemented browser and native proof targets.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the declared Playwright script for the focused browser control.**
- **Found during:** Wave verification.
- **Issue:** The plan's `test:e2e` script does not exist in `examples/phoenix_host/package.json`.
- **Fix:** Ran the equivalent declared command, `npm --prefix examples/phoenix_host test -- offline_sync.spec.ts`.
- **Verification:** Passed (1 test).

**Total deviations:** 1 auto-fixed. **Impact:** No behavior or ownership boundary changed.

## Self-Check: PASSED

- Required generated browser, XCTest, and XCUITest templates exist in the final tree.
- Task commits `278696f0`, `87bb33b1`, `f45a7088`, `99b2e39c`, and `93d65025` exist.
