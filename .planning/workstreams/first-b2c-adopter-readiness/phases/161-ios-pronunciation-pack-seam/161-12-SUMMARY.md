---
phase: 161-ios-pronunciation-pack-seam
plan: "12"
subsystem: ios-host-provider
tags: [ios, swift, xctest, atomic-publication, pronunciation-pack]
requires:
  - phase: 161-10
    provides: verified installation, persisted inventory, and inventory-write rollback
provides:
  - rollback-safe replacement publication after the old artifact is retained
  - deterministic second-move failure coverage with immediate and relaunch attestation
affects: [phase-162, ios-proof-lane, pronunciation-pack]
tech-stack:
  added: []
  patterns: [private injected publication mover, state-aware rollback cleanup]
key-files:
  created: [.planning/phases/161-ios-pronunciation-pack-seam/161-12-SUMMARY.md]
  modified:
    - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
    - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
key-decisions:
  - "Keep the deterministic move seam private to the host provider while preserving the public PackProvider contract."
  - "Retain last-known-good bytes when rollback itself cannot restore them, and return only the closed atomic-install result."
patterns-established:
  - "Post-retention publication failures share one rollback path and cleanup never deletes recovery bytes."
requirements-completed: [PACK-02, PACK-03, PACK-04]
duration: 12min
completed: 2026-08-03
status: complete
---

# Phase 161 Plan 12: Replacement Publication Rollback Summary

**Replacement promotion now restores and re-attests the exact last-known-good artifact and inventory when the staged-to-live move fails.**

## Accomplishments

- Added a host-private injected publication mover for deterministic failure coverage without widening `PackProvider`.
- Tracked retained, promoted, and committed publication states so all post-retention move and persistence failures invoke the existing rollback authority.
- Made deferred cleanup preserve retained recovery bytes when restoration fails, while returning the closed `atomicInstallFailed` result.
- Added deterministic XCTest coverage for a failure after old-byte retention and before live promotion, including exact immediate and relaunched artifact/inventory attestation.

## Verification

- RED: the new test failed before production support because `publicationMover` did not exist.
- PASS: `xcodebuild clean test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -derivedDataPath .build/phase161-publication-move-rollback -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests CODE_SIGNING_ALLOWED=NO`
  - 12 provider tests passed, including first install, successful replacement, size/digest rejection, inventory-persistence rollback, and the new second-move rollback sequence.
- PASS: production changes are limited to the host-private publication transaction; `PackProvider` and its public status/install/invalidate seam are unchanged.

## Task Commits

1. `f8b03047` — `test(161-12): add failing replacement move rollback test`
2. `ada8b7a6` — `fix(161-12): roll back failed replacement promotion`

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The change introduces no endpoint, auth path, schema, or public filesystem authority.

## Next Phase Readiness

The simulator/reference-host result is advisory only. Phase 162 remains solely responsible for physical-iPhone evidence and promotion.

## Self-Check: PASSED

- Confirmed both modified source files and this summary exist.
- Confirmed commits `f8b03047` and `ada8b7a6` exist in git history.
- Confirmed the clean focused XCTest suite passes without exposing raw filesystem errors, paths, bytes, digests, or inventory content.
