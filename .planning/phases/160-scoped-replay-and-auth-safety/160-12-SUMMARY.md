---
phase: 160-scoped-replay-and-auth-safety
plan: "12"
subsystem: Phoenix replay admission and persistence authority
tags: [phoenix, replay, authority, ecto, security, validation]
requires:
  - phase: 160-11
    provides: fresh scoped-replay final-tree baseline
provides:
  - Exact three-string-key replay-wire admission before authority callbacks
  - Server-constructed persistence attributes and server-owned accepted replay status
  - Fresh SCOPE-03 regression and complete same-tree evidence
affects: [scoped-replay, phoenix-host, replay-security]
tech-stack:
  added: []
  patterns:
    - Exact allowlisted wire keys are checked before any authority callback.
    - Persistence reconstructs Ecto attributes from admitted wire fields plus host scope.
key-files:
  created:
    - .planning/phases/160-scoped-replay-and-auth-safety/160-12-SUMMARY.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
    - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
    - examples/phoenix_host/test/crosswake_example/local_first/study_test.exs
    - examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
    - .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
key-decisions:
  - "Replay-wire admission requires exactly client_mutation_id, card_id, and rating before session resolution."
  - "Study reconstructs persisted attributes and ReviewEvent always assigns accepted for newly authorized replay rows."
metrics:
  duration: 2m 25s
  completed: 2026-08-02
  status: complete
---

# Phase 160 Plan 12: Scoped Replay Status Authority Summary

**Phoenix now rejects every extra replay-wire key before authority callbacks and persists only server-owned accepted replay outcomes.**

## Accomplishments

- Added exact three-string-key admission before session, route, feature, Sigra, domain, or persistence work.
- Rebuilt ReviewEvent attributes from the approved replay fields plus host-resolved scope; caller status and outcome no longer reach Ecto changeset casting.
- Forced newly authorized rows to `accepted` while retaining existing internal rejected tombstone behavior.
- Added hostile controller, admission-table, and direct Study defense-in-depth regressions.
- Replaced the post-160-09/10 validation gate with fresh post-160-12 focused and complete same-tree evidence.

## Task Commits

1. **Task 1: Trace a hostile extra-field replay map to a closed denial and zero persistence**
   - `7fd44c9b` — `feat(160-12): close replay status authority boundary`
2. **Task 2: Pin both authority layers and reconcile fresh complete same-tree evidence**
   - `ead611f8` — `test(160-12): pin replay authority defenses`

## Verification

- RED: the hostile-status controller test initially failed because it reached the authority chain and persisted an accepted row.
- Focused tracer: `MIX_ENV=test mix test test/crosswake_example/local_first/sync_controller_test.exs` — PASS (4 tests).
- Focused host suite: ReplayAdmission, Study, and SyncController tests — PASS (21 tests).
- Complete Phase 160 current-tree chain — PASS: 118 core tests, 15 Sigra contracts, 21 Phoenix local-first tests, 18 browser proofs, generated-host proof, asserted blocked/unavailable iOS prerequisite, 36 planning/adoption tests, and scoped formatting.

## Decisions Made

- Unknown string, atom, authority-shaped, outcome, status, and nested replay keys are all invalid envelopes and never trigger an authority callback.
- Existing rejected rows remain host-created tombstones through the explicit internal changeset seam; browser replay cannot select that status.
- TODO-002 and adopter-instance completeness remain `unknown_blocking`; generated iOS/device proof and independent Phase 160 security remain non-passing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted the expanded Study regression**
- **Found during:** Task 2 focused verification
- **Issue:** The new multi-line test signature did not meet Mix formatter output.
- **Fix:** Applied the project formatter, then reran focused and complete Phoenix verification.
- **Files modified:** `examples/phoenix_host/test/crosswake_example/local_first/study_test.exs`
- **Commit:** `ead611f8`

## Known Stubs

None. The validation ledger's TODO-002, generated iOS/device proof, and independent-security entries are explicit external non-passing boundaries, not implementation stubs.

## Self-Check: PASSED

- Verified all seven runtime, test, and validation artifacts exist.
- Verified task commits `7fd44c9b` and `ead611f8` exist in git history.
- No task-created stubs, skipped tests, or unrun planned verification remain.
