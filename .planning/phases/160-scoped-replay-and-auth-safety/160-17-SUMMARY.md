---
phase: 160-scoped-replay-and-auth-safety
plan: "17"
subsystem: offline replay safety
tags: [indexeddb, phoenix, ecto, playwright, scoped-replay, sigra]
requires:
  - phase: 160-16
    provides: request-bound replay authority and fresh Phase 160 evidence seams
provides:
  - Unowned legacy browser mutations remain quarantined and recovery-required.
  - Nil-scope persisted ReviewEvent history denies scoped acknowledgement authority.
  - Per-card rating submission is serialized before IndexedDB persistence.
affects: [phase-160-verification, first-adopter-offline-study]
tech-stack:
  added: []
  patterns: [closed legacy recovery without inferred ownership, nil-scope conflict mapping, synchronous UI submission ownership]
key-files:
  created: [.planning/phases/160-scoped-replay-and-auth-safety/COVERAGE.md]
  modified: [examples/phoenix_host/priv/static/offline_study.js, examples/phoenix_host/e2e/offline_sync.spec.ts, examples/phoenix_host/lib/crosswake_example/local_first/study.ex, examples/phoenix_host/test/crosswake_example/local_first/study_test.exs, .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md]
key-decisions:
  - "Without a host-owned per-record binding, legacy recovery remains recovery-required and never derives ownership from an active lease."
  - "Nil-scope historical ReviewEvents map to scope conflict before any persisted accepted or rejected outcome mapping."
  - "Rating controls acquire synchronous per-card ownership before IndexedDB work begins."
patterns-established:
  - "Historical unscoped state is retained but never promoted by current session state."
requirements-completed: [SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05]
coverage:
  - id: D1
    description: "Closed legacy-quarantine and nil-scope replay behavior"
    requirement: "SCOPE-01"
    verification:
      - kind: unit
        ref: "examples/phoenix_host/test/crosswake_example/local_first/study_test.exs"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/offline_sync.spec.ts#unscoped legacy work remains recovery-required across account switch"
        status: pass
    human_judgment: false
  - id: D2
    description: "One-card mutation serialization across IndexedDB persistence"
    requirement: "SCOPE-02"
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/offline_sync.spec.ts#rapid ratings queue one mutation for one card"
        status: pass
    human_judgment: false
  - id: D3
    description: "Complete Phase 160 same-tree safety gate"
    requirement: "SCOPE-05"
    verification:
      - kind: integration
        ref: "160-VALIDATION.md#fresh-same-tree-gate--2026-08-03-post-160-17"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-08-03
status: complete
---

# Phase 160 Plan 17: Scoped Replay Gap Closure Summary

**Legacy IndexedDB work remains quarantined without host-owned ownership proof, nil-scope history is conflict-only, and rapid ratings create one scoped mutation per card.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-08-03T02:32:52Z
- **Completed:** 2026-08-03T02:39:01Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Replaced active-lease legacy promotion with a closed recovery-required result that preserves quarantined bytes through account switches.
- Mapped nil-scope ReviewEvent rows to scope conflict in idempotency and race recovery paths before outcome mapping.
- Added deterministic browser proof for competing rating controls and recorded a fresh, complete Phase 160 gate.

## Task Commits

1. **Task 1 RED: closed legacy regressions** - `ac34055d` (test)
2. **Task 1 GREEN: retain unowned legacy replay history** - `ba8a5b33` (feat)
3. **Task 2 RED: rapid rating submission race** - `217c1154` (test)
4. **Task 2 GREEN: serialize rating submission per card** - `187d5e3f` (feat)
5. **Task 3: fresh scoped replay gate** - `0d27a488` (docs)

## Files Created/Modified

- `examples/phoenix_host/priv/static/offline_study.js` - Closed legacy recovery and per-card submission ownership.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` - Shared-device legacy and rapid-rating browser regressions.
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` - Nil-scope conflict mapping.
- `examples/phoenix_host/test/crosswake_example/local_first/study_test.exs` - Nil-scope retained-history assertions.
- `.planning/phases/160-scoped-replay-and-auth-safety/COVERAGE.md` - Exact no-external-API declaration.
- `.planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md` - Aggregate-only post-160-17 evidence.

## Decisions Made

- Legacy records have no recoverable ownership in this example host without a server-verifiable per-record binding.
- Scoped retries never grant acknowledgement or deletion authority to nil-scope history.
- Existing browser controls remain the UI surface; the repair adds only private submission ownership.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the browser regression's scope capture**
- **Found during:** Task 1 verification
- **Issue:** The new browser assertion referenced scope fixtures outside its page-evaluation closure.
- **Fix:** Passed the two scope fixtures explicitly into the evaluation.
- **Files modified:** `examples/phoenix_host/e2e/offline_sync.spec.ts`
- **Verification:** Focused legacy browser proof passed.
- **Committed in:** `ba8a5b33`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Test-only correction; no scope expansion.

## Issues Encountered

- Existing locked dependency advisories were emitted during the established dependency check. They are deferred to the independent Phase 160 security audit; no dependency change was made.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SCOPE-01 through SCOPE-05 have fresh automated same-tree evidence.
- Generated iOS/device proof, TODO-002/adopter-instance inputs, and independent Phase 160 security remain explicitly non-passing or `unknown_blocking`.

## Self-Check: PASSED

- Required implementation, test, coverage, and validation files exist.
- All five task commits exist in git history.
