---
phase: 161-ios-pronunciation-pack-seam
plan: "15"
subsystem: ios-host-pack-publication
tags: [swift, xctest, ios, crash-recovery, fsync, pronunciation-pack]
requires:
  - phase: 161-ios-pronunciation-pack-seam
    provides: exception-safe staged pack publication and durable inventory records
provides:
  - crash-safe replacement journal recovery from one construction-time barrier
  - fsynced journal, inventory, move, and cleanup ordering behind private operations
  - deterministic closed recovery tests for malformed topology and volume identity
affects: [161-16, phase-162-device-proof]
tech-stack:
  added: []
  patterns: [host-private publication operations, startup recovery barrier, storage-root volume anchor]
key-files:
  created: []
  modified:
    - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
    - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
key-decisions:
  - "Construction owns exactly one detached, memoized recovery barrier; status only awaits it."
  - "Publication operations own atomic writes, synchronization, moves, and removals for production and recorder tests."
requirements-completed: [PACK-02, PACK-03, PACK-04]
coverage:
  - id: D1
    description: "Interrupted replacement publications converge before provider operations and retain only closed failures."
    requirement: PACK-03
    verification:
      - kind: integration
        ref: "PronunciationPackProviderTests construction bootstrap and invalidation tests"
        status: pass
    human_judgment: false
  - id: D2
    description: "Durability ordering and storage-root identity checks are enforced without widening PackProvider."
    requirement: PACK-02
    verification:
      - kind: unit
        ref: "PronunciationPackProviderTests durability and volume-anchor tests"
        status: pass
    human_judgment: false
status: complete
---

# Phase 161 Plan 15: Crash-Safe Pack Publication Recovery Summary

**Host-private fsynced replacement journaling restores or finalizes pronunciation packs before any provider operation can report state.**

## Performance

- **Tasks:** 1/1
- **Files modified:** 2
- **Verification:** clean focused CrosswakeShell XCTest suite, 33 tests passing

## Accomplishments

- Recovered every durable replacement phase at provider construction through one memoized off-main-actor barrier.
- Added explicit atomic-write, file-sync, directory-sync, move, and cleanup ordering across publication and recovery.
- Proved side-effect-free status, memoized bootstrap failure, recovery-before-invalidation, topology rejection, and absent-destination storage-root anchors.

## Task Commits

1. **Task 1: Recover every interrupted replacement publication before provider use** — `e7d4dba1`, `1abcb266`, `96a907d1`, `fc2fa612`, `6fc91ee9`, `b232f7ab`, `128eb185`, `0abd63c3`, `451efb4c`

## Files Created/Modified

- `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift` — durable publication operations, directory barriers, and crash recovery validation.
- `examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` — deterministic restart, ordering, invalidation, and volume-anchor coverage.

## Decisions Made

- Keep the recovery journal and filesystem abstractions host-private; the public `PackProvider` contract is unchanged.
- Treat recovery failure as a memoized closed result, blocking install and invalidate mutation.

## Verification

Passed the plan’s clean XCTest command with all 21 required named markers observed. The run used a private `mktemp` DerivedData root with an EXIT cleanup trap; no Phase 161 build artifacts remain in `.build`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Route inventory persistence through the publication-operation boundary**
- **Found during:** Task 1
- **Issue:** The injected durability recorder could not observe an inventory atomic write, and invalidation bypassed the operation layer.
- **Fix:** Routed inventory writes and revocation removal through `PublicationOperations`, with explicit file and directory synchronization.
- **Files modified:** `PronunciationPackProvider.swift`
- **Verification:** all recorder-order and invalidation-before-revocation tests pass.
- **Committed in:** `451efb4c`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** required for the plan’s testable durability contract; no public API or scope expansion.

## Known Stubs

None.

## Next Phase Readiness

Crash-safe replacement publication is ready for the remaining Phase 161 reconciliation and Phase 162 device-proof boundary. Physical-iPhone evidence and adopter-instance route inputs remain out of scope and blocked as documented.

## Self-Check: PASSED
