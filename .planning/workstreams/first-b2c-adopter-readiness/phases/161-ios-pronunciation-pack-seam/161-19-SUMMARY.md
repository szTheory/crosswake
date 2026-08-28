---
phase: 161-ios-pronunciation-pack-seam
plan: "19"
subsystem: ios-pronunciation-pack-recovery
tags: [ios, swift, xctest, recovery, atomic-install]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: restart-recoverable host-private pack publication journal
provides:
  - byte-backed prior-state journal invariant
  - stale-inventory promotion-pending restart recovery
affects: [phase-161-verification, ios-host-pack-provider]
tech-stack:
  added: []
  patterns: [prior metadata is authoritative only with retained bytes, narrow topology-specific recovery]
key-files:
  created: [.planning/phases/161-ios-pronunciation-pack-seam/161-19-SUMMARY.md]
  modified:
    - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
    - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
key-decisions:
  - "Inventory-only prior state is never journaled as a last-known-good record."
  - "Only the validated promotion-pending stale-inventory topology clears stale authority; ambiguous missing-byte states remain closed."
patterns-established:
  - "Recovery validates the recognized file and inventory topology before mutating durable state."
requirements-completed: [PACK-01, PACK-02, PACK-03, PACK-04]
coverage:
  - id: D1
    description: "A stale inventory record with no destination or retained bytes recovers to not-installed, then accepts a fresh verified install after relaunch."
    requirement: PACK-02
    verification:
      - kind: integration
        ref: "examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift#testConstructionBootstrapRecoversStaleInventoryWithoutArtifactAndPermitsReinstall"
        status: pass
    human_judgment: false
  - id: D2
    description: "The provider retains fail-closed journal recovery and real-byte installation behavior across its host test suite."
    requirement: PACK-03
    verification:
      - kind: integration
        ref: "xcodebuild clean test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -only-testing:CrosswakeShellTests/PronunciationPackProviderTests"
        status: pass
      - kind: unit
        ref: "swift test --package-path packages/crosswake-shell-core-ios"
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-04
  tasks_completed: 1
status: complete
---

# Phase 161 Plan 19: Stale Inventory Recovery Summary

The host-private iOS provider now treats a prior journal record as valid only with retained artifact bytes, and recovers the one reachable stale-inventory promotion interruption to an honest not-installed state.

## Performance

- **Duration:** 8 min
- **Started:** 2026-08-04T14:07:00Z
- **Completed:** 2026-08-04T14:15:22Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Coupled `ReplacementJournal.priorRecord` to a real prior destination artifact that will be retained.
- Added a direct relaunch regression for stale inventory, absent destination/retained bytes, valid staging, and a persisted `.promotionPending` journal.
- Kept retained-byte recovery and malformed or ambiguous recovery states fail-closed; the recovered provider can perform a verified fixture reinstall and fresh status check.

## Task Commits

1. **Task 1 RED: stale inventory recovery regression** — `b505996d` (`test`)
2. **Task 1 GREEN: recover stale inventory publication** — `47fecec4` (`fix`)

## Verification

- `swift test --package-path packages/crosswake-shell-core-ios` — passed, 27 tests.
- `xcodebuild clean test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -derivedDataPath <temporary> -destination "platform=iOS Simulator,name=iPhone 17" -only-testing:CrosswakeShellTests/PronunciationPackProviderTests CODE_SIGNING_ALLOWED=NO` — passed.
- `git diff --check -- examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` — passed.

## TDD Gate Compliance

- RED commit `b505996d` added the reachable crash/relaunch regression, which failed against the pre-repair recovery guard.
- GREEN commit `47fecec4` made the regression and full host provider suite pass.

## Decisions Made

- Recovery recognizes only the validated legacy inventory-only `.promotionPending` state (matching stale inventory, absent destination and retained leaves, and a validated staging file).
- A missing retained artifact with any other journal topology remains a memoized closed startup failure before destructive publication mutation.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

- The host Xcode target emits pre-existing Swift 6 actor-isolation and concurrent-capture warnings outside this plan's owned files; test execution still passed. They were not changed because they are unrelated to the recovery repair.

## Next Phase Readiness

Phase verification can now re-run the previously blocked stale-inventory restart path without changing the public three-operation provider seam or host/core ownership boundary.

## Self-Check: PASSED

- Both production and regression files exist.
- Task commits `b505996d` and `47fecec4` exist in git history.
