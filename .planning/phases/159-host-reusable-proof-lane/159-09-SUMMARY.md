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
  files_changed: 9
status: blocked
---

# Phase 159 Plan 09: Honest Native Proof Summary

Native proof now requires executed XCTest and XCUITest evidence through a generated shared scheme; it cannot pass from a build-only placeholder.

## Completed Work

- Generated the shared `CrosswakeProofLane` scheme with both test bundles in its test action.
- Replaced fixed SwiftUI proof copy and no-op reconnect behavior with a default-unavailable host adapter contract and optional real retry closure.
- Added XCTest adapter-state coverage plus lifecycle, accessibility-size, text, and conditional retry-target XCUITest coverage.
- Changed `--proof-lane` verification to select an already-installed iPhone simulator, run `build-for-testing`, then run `test-without-building`; both bundle-qualified test-case markers are required before `passed`.
- Removed persistent global Git and SwiftPM mutation; package cache, transcript, and generated host state are operation-owned and cleaned on exit.

## Task Commits

1. Task 1 RED — `d4504416` test(159-09): reject build-only native proof success
2. Task 1 GREEN — `76bf3a65` feat(159-09): execute shared native proof tests
3. Task 2 RED — `e86baba7` test(159-09): cover native lifecycle proof contract
4. Task 2 GREEN — `8634c434` feat(159-09): prove adapter lifecycle and hermetic native checks

## Verification

- `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — passed (9 tests).
- `bash -n script/verify_generated_ios_shell.sh` — passed.
- Fresh non-mocked `--proof-lane` verifier — correctly returned `{"outcome":"unavailable","rule_id":"PL-IOS-SIMULATOR","scope":"generated-proof-targets"}` with exit 3 because this developer machine has no installed concrete iPhone simulator. It did not report `passed`.

## Deviations from Plan

None - implementation followed the planned contract. The real native execution gate remains blocked by the absent installed simulator, which the verifier intentionally does not download.

## Known Stubs

None. The default missing-host-adapter outcome is intentional fail-closed behavior, not a stub.

## Deferred Issues

- A concrete installed iPhone simulator is required to execute and close the non-mocked native XCTest/XCUITest gate. No simulator platform download was attempted by design.

## Self-Check: FAILED

- All declared implementation artifacts and four TDD commits exist.
- Focused tests and shell syntax validation pass.
- The required real native verifier cannot run to completion until an installed concrete iPhone simulator is available.
