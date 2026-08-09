---
phase: 160-scoped-replay-and-auth-safety
plan: "04"
subsystem: offline replay safety
tags: [indexeddb, playwright, scope-lease, quarantine, privacy]
requires:
  - phase: 160-03
    provides: scoped outbox lifecycle and privacy-safe replay foundation
provides:
  - Version-4 IndexedDB migration that atomically quarantines legacy unscoped mutations
  - Explicit host recovery guarded by the current exact scope-plus-epoch lease
  - Browser proof for inert migration, exact-scope recovery, replay, and partition preservation
affects: [160-05, 160-08, offline-island]
tech-stack:
  added: []
  patterns: [atomic IndexedDB cursor migration, closed recovery outcomes, exact-scope compound keys]
key-files:
  created: []
  modified:
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
decisions:
  - Legacy IndexedDB mutations remain unassigned in quarantine until an active host lease explicitly recovers them.
metrics:
  duration: 5m
  completed_date: 2026-08-02
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 160 Plan 04: Legacy Quarantine and Exact-Scope Recovery Summary

Legacy offline mutations now migrate into an inert quarantine and become replayable only through an explicit current host scope lease.

## Tasks Completed

1. **Quarantine one legacy mutation during upgrade and keep replay inert**
   - Raised the offline-study IndexedDB schema to version 4.
   - Migrates legacy unscoped records with one upgrade transaction: copy to quarantine, then delete the source only after the copy succeeds.
   - Keeps quarantine out of scoped reads, replay, status detail, and automatic scope activation.
   - Added deterministic browser proof for upgrade, status redaction, relaunch, and unrelated-scope retention.

2. **Recover quarantined work only under an explicit matching host lease**
   - Added the frozen `recoverLegacyMutations(scopeRef)` host bridge method with closed `recovered` or `blocked` outcomes.
   - Requires valid active scope and epoch evidence, rechecks authority during the transaction, and atomically moves only valid records to `(scope_ref, local_ref)`.
   - Proves wrong-scope denial, duplicate-call safety, ordinary accepted replay, and second-partition preservation.

## Verification

- `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "legacy upgrade quarantines unscoped work|legacy quarantine remains inert across relaunch"` — passed.
- `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "explicit host recovery scopes quarantined work|wrong scope cannot recover legacy work"` — passed.
- Focused offline-island regression selection — 7 passed.

## Commits

- `2b6c159c` — `test(160-04): add legacy quarantine upgrade proof`
- `81901884` — `feat(160-04): quarantine legacy offline mutations`
- `63979c85` — `test(160-04): add explicit legacy recovery proof`
- `443729af` — `feat(160-04): require host lease for legacy recovery`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Advance shared IndexedDB proof helpers to schema version 4**
- **Found during:** Task 2
- **Issue:** Existing browser proof helpers explicitly opened version 3 after the migration raised the database schema, producing `VersionError`.
- **Fix:** Updated the shared reader and existing test openings to version 4.
- **Files modified:** `examples/phoenix_host/e2e/support/offline_route_proof.ts`, `examples/phoenix_host/e2e/offline_sync.spec.ts`
- **Verification:** Focused recovery proof and seven-test regression selection passed.
- **Commit:** `443729af`

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** Maintains existing browser-proof compatibility with the deliberate version-4 migration; no product scope expanded.

## Known Stubs

None.

## Self-Check: PASSED

- Verified all three modified implementation/proof files exist.
- Verified all four task commits exist in repository history.
