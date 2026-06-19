---
phase: 119-native-evidence-classification
plan: "03"
subsystem: testing
tags: [exunit, drift-guard, docs-scanner, native-proof]
requires:
  - phase: 119-native-evidence-classification
    provides: normalized native coordinate and label vocabulary
provides:
  - native evidence drift guard
  - synthetic regression coverage for stale native truth
affects: [phase-119-closeout, phase-120-collateral]
tech-stack:
  added: []
  patterns:
    - Source-derived ExUnit scanner fails closed on native proof regressions.
    - Synthetic regressions cover stale coordinates, missing labels, and device-support overclaims.
key-files:
  created:
    - test/crosswake/guides/native_evidence_drift_test.exs
  modified: []
requirements-completed: [DRIFT-03]
duration: 0h 25m
completed: 2026-06-19
status: complete
---

# Phase 119 Plan 03 Summary

**A source-derived ExUnit scanner now blocks stale native coordinates and missing evidence labels**

## Performance

- **Duration:** 25 min
- **Started:** 2026-06-19T21:10:00Z
- **Completed:** 2026-06-19T21:35:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `Crosswake.Guides.NativeEvidenceDriftTest` as a source-derived ExUnit scanner for checked-in hosts, docs, support matrix surfaces, and generated README templates.
- Derived the current version from `Application.spec(:crosswake, :vsn)` and used it in the scan rules.
- Added synthetic regressions for stale iOS local refs, stale Android coordinates, dynamic Android dependency versions, missing labels, stale Android UAT version wording, and device-support overclaims.
- Kept the scanner prose-loose and line-aware instead of turning it into an executable markdown snapshot.

## Task Commits

- Not recorded in this session.

## Files Created/Modified

- `test/crosswake/guides/native_evidence_drift_test.exs`

## Decisions Made

- Surface drift should fail closed with file/line/category/detail output.
- Label and coordinate truth belong in source-derived checks, not in ad hoc manual review.

## Deviations from Plan

- None.

## Issues Encountered

- The first pass needed rule-order and regex fixes so the scanner reported the intended stale-truth categories instead of only missing-term fallout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 119 is ready for final state/roadmap reconciliation or phase-closeout handling.

---
*Phase: 119-native-evidence-classification*
*Completed: 2026-06-19*
