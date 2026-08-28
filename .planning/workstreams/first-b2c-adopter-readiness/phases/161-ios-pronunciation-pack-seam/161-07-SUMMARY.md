---
phase: 161-ios-pronunciation-pack-seam
plan: "07"
subsystem: ios-pack-provider
tags: [ios, swift, pack-store, route-gating, concurrency, revocation]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: closed provider lifecycle and activation-required pack gate
provides:
  - Total ordered validation for every manifest-required pack reference.
  - Per-pack generation fencing for asynchronous provider operations and durable revocation.
affects: [ios-shell-host, phase-161-verification, phase-162-device-proof]
tech-stack:
  added: []
  patterns: [total-reference-resolution, per-pack-operation-generation, continuation-scheduled-concurrency-tests]
key-files:
  created: []
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
key-decisions:
  - "Required pack references are validated in manifest order; malformed input is represented only by a stable closed status."
  - "Only the current per-pack mutation may apply provider results or clear persisted revocation after fresh exact reconciliation."
metrics:
  duration: 9m
  completed_date: 2026-08-03
status: complete
---

# Phase 161 Plan 07: Required-Pack Safety Summary

Required-pack activation is now total and fail-closed, while generation-fenced provider work prevents stale reconciliation from re-enabling revoked pronunciation media.

## Accomplishments

- Replaced lossy required-pack parsing with ordered validation that blocks empty, malformed, unknown, unsupported-contract, and version-incompatible entries before runtime selection.
- Added stable closed statuses that never echo rejected references or provider-private input.
- Added per-pack operation generations so stale reconciliation and older invalidations cannot write status or clear revocation.
- Restricted revocation clearance to current-operation fresh absence after invalidation, or current-operation verified reinstall followed by fresh exact installed status.
- Added deterministic continuation barriers for stale reconciliation, overlapping invalidation, relaunch persistence, and verified reinstall tests.

## Verification

- `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` — passed (9 tests).
- `swift test --package-path packages/crosswake-shell-core-ios --filter ActivationConformanceTests` — passed (4 tests).
- `swift test --package-path packages/crosswake-shell-core-ios` — passed (27 tests).

## Task Commits

1. **Task 1: Block every invalid required-pack reference before runtime selection**
   - `4372e0e0` — RED reference and route activation regressions
   - `fa4e8ccb` — total ordered reference resolution
2. **Task 2: Fence stale reconciliation and preserve revocation through overlapping invalidation**
   - `8fca990d` — RED deterministic overlap regressions
   - `d9b0bab1` — generation fencing and restricted revocation clearance

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the newly added route-level XCTest to be asynchronous before its RED run.
- **Found during:** Task 1
- **Fix:** Declared the test `async` so it can reconcile its exact installed provider before asserting route presentation.
- **Files modified:** `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift`
- **Commit:** `4372e0e0`

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all three production/test files exist.
- Confirmed task commits `4372e0e0`, `fa4e8ccb`, `8fca990d`, and `d9b0bab1` exist in Git history.
