---
phase: 159-host-reusable-proof-lane
plan: "09"
subsystem: native proof verification
tags: [ios, xcodebuild, xctest, xcuitest, proof-lane]
requires:
  - phase: 159-08
    provides: descriptor-confined proof-lane generation
provides:
  - host-adapter-backed native proof probe
  - shared XCTest/XCUITest scheme and fail-closed executed-test verifier
affects: [proof-lane, PROOF-01, PROOF-03]
tech-stack:
  added: [shared Xcode scheme]
  patterns: [closed adapter state, bundle-qualified native test evidence, operation-scoped package resolution]
key-files:
  created:
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/crosswake/proof_lane/ios_verifier_test.exs
decisions:
  - "Native passed requires a successful shared-scheme test-without-building run and bundle-qualified evidence from both XCTest and XCUITest."
  - "The repository provides no host adapter by default, so the generated probe remains unavailable until a host supplies closed state and a real retry action."
  - "Verifier-local Git rewrite and SwiftPM caches are operation-scoped; no global Git or SwiftPM configuration is written."
metrics:
  completed: 2026-08-01
  tasks_completed: 2
  files_changed: 10
status: complete
---

# Phase 159 Plan 09: Honest Native Proof Summary

Native proof now requires executed XCTest and XCUITest evidence through a generated shared scheme; it cannot pass from a build-only placeholder.

## Completed Work

- Generated the shared `CrosswakeProofLane` scheme with both test bundles in its test action.
- Replaced fixed SwiftUI proof copy and no-op reconnect behavior with a default-unavailable host adapter contract and optional real retry closure.
- Added XCTest adapter-state coverage plus lifecycle, accessibility-size, text, and conditional retry-target XCUITest coverage.
- Changed `--proof-lane` verification to select an already-installed iPhone simulator, run `build-for-testing`, then run `test-without-building`; both bundle-qualified test-case markers are required before `passed`.
- Removed persistent global Git and SwiftPM mutation; package cache, transcript, and generated host state are operation-owned and cleaned on exit.
- Named each generated app/test product and Swift module explicitly, with a concrete app product reference and a configured XCTest host, so current Xcode build graphs cannot collapse outputs into empty `.app` or `.xctest` paths.

## Task Commits

1. Task 1 RED — `d4504416` test(159-09): reject build-only native proof success
2. Task 1 GREEN — `76bf3a65` feat(159-09): execute shared native proof tests
3. Task 2 RED — `e86baba7` test(159-09): cover native lifecycle proof contract
4. Task 2 GREEN — `8634c434` feat(159-09): prove adapter lifecycle and hermetic native checks
5. Follow-up Xcode graph correction — `2f4f53bd` and `67d50d06`

## Verification

- `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — passed (11 tests).
- `bash -n script/verify_generated_ios_shell.sh` — passed.
- Fresh non-mocked `--proof-lane` verifier — passed with exit 0 after generating a clean scaffold, selecting the installed concrete iPhone simulator, building the shared scheme, and executing both XCTest and XCUITest. The verifier emitted only its closed `passed` JSON outcome and discarded its operation-owned transcript.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected generated Xcode product and module output names.
- **Found during:** Non-mocked native proof verification after Tasks 1 and 2.
- **Issue:** Current Xcode resolved unset generated target product names to empty values, producing an app-product collision and then an incompatible app module for XCTest.
- **Fix:** Added concrete app/test product and module names, an `.app` product reference, Debug app testability, and the XCTest host/bundle loader settings; added a template contract regression.
- **Files modified:** `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex`, `test/crosswake/proof_lane/template_contract_test.exs`
- **Verification:** Focused ExUnit suites, shell syntax, and a fresh non-mocked proof-lane execution all passed.
- **Commits:** `2f4f53bd`, `67d50d06`

**Total deviations:** 1 auto-fixed (Rule 1 - Bug). **Impact:** Restored a real native test execution path without broadening the proof-lane contract.

## Known Stubs

None. The default missing-host-adapter outcome is intentional fail-closed behavior, not a stub.

## Self-Check: PASSED

- All declared implementation artifacts exist in the working tree.
- Task and follow-up commits `d4504416`, `76bf3a65`, `e86baba7`, `8634c434`, `2f4f53bd`, and `67d50d06` exist in Git history.
- Focused tests, shell syntax validation, and the required fresh non-mocked native verifier pass.
