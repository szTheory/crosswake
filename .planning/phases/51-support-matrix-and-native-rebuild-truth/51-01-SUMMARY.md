---
phase: 51-support-matrix-and-native-rebuild-truth
plan: "01"
subsystem: diagnostics
tags: [support-matrix, rebuild-truth, promotion-rules, diagnostics]
requires:
  - phase: 50-doctor-publish-and-readiness-checks
    provides: publish-readiness proof and rebuild fields
provides:
  - typed action-class support truth
  - typed promotion-rule support truth
  - explicit companion and notification deferred-scope support rows
affects: [support_matrix, operator_inspection, publish_readiness, docs]
tech-stack:
  added: []
  patterns: [typed canonical support truth, fail-closed support validation]
key-files:
  created: []
  modified:
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - test/crosswake/support_matrix/support_matrix_test.exs
key-decisions:
  - "Support, proof, diagnostic severity, action class, and rebuild truth remain split axes."
  - "Promotion criteria live in Crosswake.SupportMatrix typed accessors for Phase 51, not generated manifests."
patterns-established:
  - "Action classes are canonical typed rows with machine labels and guide anchors."
  - "Promotion rules include required evidence, freshness, docs anchors, action class, check ids, and demotion trigger."
requirements-completed: [SUPP-01]
duration: 18min
completed: 2026-06-01
---

# Phase 51-01: Canonical Support Truth Summary

**Typed action classes, promotion rules, and deferred support rows now anchor Phase 51 rebuild and promotion truth.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-01T15:24:00Z
- **Completed:** 2026-06-01T15:47:46Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `ActionClassEntry` and `PromotionRuleEntry` typed structs plus constructors and map conversion support.
- Added canonical support-matrix accessors for proof classes, diagnostic severities, action classes, promotion rules, companion truth, and notification truth.
- Added validation that fails closed when action-class or promotion-rule metadata is incomplete or references unknown action classes.

## Task Commits

1. **Task 1: Add failing support-matrix contract tests** - `2abbe62` (test)
2. **Task 2: Implement typed canonical support truth** - `54ddf9f` (feat)

## Files Created/Modified

- `lib/crosswake/manifest/types.ex` - Adds typed action-class and promotion-rule entries.
- `lib/crosswake/support_matrix/support_matrix.ex` - Exposes canonical Phase 51 support truth and validation.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Locks split axes, action classes, promotion rules, and deferred non-claims.

## Decisions Made

- Kept support status, proof class, diagnostic severity, rebuild/action class, and deferred condition truth as separate vocabularies.
- Modeled advisory-to-merge-blocking criteria as typed promotion rules with evidence, freshness, docs anchors, check ids, and demotion triggers.
- Preserved explicit v3.6 non-claims for Sigra contract-only auth, notification-token provider snapshots, and deferred delivery/native-auth surfaces.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

None.

## Verification

- `mix test test/crosswake/support_matrix/support_matrix_test.exs` - 24 tests, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 51-02 can render action classes, promotion rules, and non-claims directly from `Crosswake.SupportMatrix`. Plan 51-03 can reuse the same canonical accessors for operator inspection and publish-readiness metadata.

---
*Phase: 51-support-matrix-and-native-rebuild-truth*
*Completed: 2026-06-01*
