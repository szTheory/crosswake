---
phase: 161-ios-pronunciation-pack-seam
plan: "06"
subsystem: ios-pack-provider
tags: [ios, swift, pack-provider, integrity, swiftui]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: host pack provider, closed PackStore lifecycle, and recovery-view presentation contract
provides:
  - Bundled host declarations are validated into exact PackRequirement values before provider use.
  - Reference-host staged media verification streams SHA-256 off the main actor before promotion.
  - Recovery view spacing follows the approved 24pt/8pt rhythm without semantic changes.
affects: [phase-161-verification, phase-162-device-proof, ios-shell-host]
tech-stack:
  added: []
  patterns: [validated-host-private-integrity-declaration, staged-file-streaming-verification, source-pinned-swiftui-layout-contract]
key-files:
  created: []
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
    - examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
    - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
    - examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift
    - examples/ios_shell_host/Fixtures/declared_pack_requirements.json
    - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
    - examples/ios_shell_host/CrosswakeShellTests/RequiredPackViewTests.swift
key-decisions:
  - "Exact integrity authority is decoded only from host-private bundled configuration, never calculated from provider-acquired bytes."
  - "The provider hashes the staged file in a detached utility task before atomic promotion and inventory persistence."
  - "The UI change is constrained to the approved 24pt top-level and 8pt diagnostic spacing values."
requirements-completed: [PACK-01, PACK-02, PACK-03, PACK-04, PACK-05]
coverage:
  - id: D1
    description: Bundled reference-host construction preserves pinned pack integrity through verified installation and reconciliation.
    requirement: PACK-03
    verification:
      - kind: integration
        ref: examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift#testBundledConstructionPropagatesExactRequirementThroughConcreteProvider
        status: pass
    human_judgment: false
  - id: D2
    description: Staged-file verification uses bounded off-main streaming before promotion.
    requirement: PACK-03
    verification:
      - kind: unit
        ref: examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift#testStreamedVerifierUsesMultipleBoundedReads
        status: pass
    human_judgment: false
  - id: D3
    description: Required pack recovery view retains its closed accessible action contract at approved spacing.
    requirement: PACK-01
    verification:
      - kind: automated_ui
        ref: examples/ios_shell_host/CrosswakeShellTests/RequiredPackViewTests.swift
        status: pass
    human_judgment: false
metrics:
  duration: 4m
  completed_date: 2026-08-03
status: complete
---

# Phase 161 Plan 06: iOS Pronunciation Pack Seam Summary

Bundled exact pack declarations now reach the concrete reference iOS provider and reconcile as available only after staged-byte verification and atomic promotion.

## Accomplishments

- Replaced bundled zero/empty integrity construction with validated current-contract host declarations, rejecting empty, duplicate, malformed, unsupported, and non-positive inputs.
- Moved concrete provider integrity checking to bounded staged-file streaming in a detached utility task before replacement/move and inventory persistence.
- Added real production-constructor, streaming, and recovery-view layout regressions; aligned the view to the approved 24pt/8pt spacing values.

## Verification

- `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` — passed (4 tests).
- Focused iPhone 17 simulator XCTest for `PronunciationPackProviderTests` and `RequiredPackViewTests` — passed (10 tests).

## Task Commits

1. **Task 1: Carry the exact bundled requirement through the real reference-host constructor**
   - `8382bbb9` — RED regression
   - `3908334e` — validated declaration and staged-file verifier
2. **Task 2: Align the approved recovery surface spacing and preserve every UI state contract**
   - `a45875c7` — RED layout regression
   - `8b091eaf` — approved spacing correction

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected a Swift test assertion that attempted to await inside XCTest's non-async autoclosure.
- **Found during:** Task 1
- **Fix:** Awaited the provider result before asserting it.
- **Files modified:** `examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift`
- **Verification:** Focused provider XCTest passed.
- **Committed in:** `3908334e`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the seven declared production and test files exist.
- Confirmed task commits `8382bbb9`, `3908334e`, `a45875c7`, and `8b091eaf` exist.
