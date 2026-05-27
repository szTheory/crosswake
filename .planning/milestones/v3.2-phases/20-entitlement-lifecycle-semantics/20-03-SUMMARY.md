---
phase: 20-entitlement-lifecycle-semantics
plan: 03
subsystem: docs
tags: [commerce, entitlement_snapshot, support_matrix, provider-neutral, verification]
requires:
  - phase: 20-01
    provides: explicit entitlement lane taxonomy and lifecycle vocabulary
  - phase: 20-02
    provides: non-authoritative evidence handling and provider-vocabulary guardrails
provides:
  - explicit lane and lifecycle semantics in public commerce guidance
  - generated support truth for stale and pending non-granting posture
  - parity tests that lock scope fences and provider-neutral wording
affects: [phase-21-reconciliation-example, phase-22-commerce-support-proof]
tech-stack:
  added: []
  patterns: [renderer-driven support docs, parity tests for doc-contract semantics]
key-files:
  created:
    - .planning/phases/20-entitlement-lifecycle-semantics/20-03-SUMMARY.md
  modified:
    - guides/commerce.md
    - guides/support_matrix.md
    - lib/crosswake/support_matrix/support_matrix.ex
    - test/crosswake/guides/commerce_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
key-decisions:
  - "Keep lifecycle semantics authoritative in docs while preserving provider-neutral core wording."
  - "Encode stale/unknown fail-closed and pending non-granting posture in canonical support matrix capability rows."
  - "Lock scope fences with parity tests that reject provider-specific vocabulary in lifecycle sections."
patterns-established:
  - "Lifecycle semantics are enforced in docs through literal-vocabulary tests."
  - "Support guide changes flow through `SupportMatrix.Renderer`, then parity tests verify generated truth."
requirements-completed: [ENTL-01, ENTL-02, ENTL-03]
duration: 2 min
completed: 2026-05-27
---

# Phase 20 Plan 03: Entitlement Lifecycle Semantics Docs Parity Summary

**Published explicit entitlement lane semantics and synchronized renderer-generated support truth so stale or pending evidence states remain non-authoritative across public guidance and test-locked outputs.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-27T06:10:13-04:00
- **Completed:** 2026-05-27T06:12:02-04:00
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added an `Entitlement Snapshot Lanes` section to `guides/commerce.md` with required lane names and lifecycle states.
- Updated canonical support matrix capability entries so stale snapshots fail closed and reconciliation evidence stays non-authoritative.
- Added parity tests that enforce scope fences (`provider adapters are out of scope`) and reject provider terms in lifecycle guide/support sections.

## Task Commits

Each task was committed atomically:

1. **Task 1: Publish explicit lane model and lifecycle taxonomy in commerce guide** - `b4f8744` (feat)
2. **Task 2: Align generated support matrix entries with freshness and reconciliation semantics** - `8a0b13a` (feat)
3. **Task 3: Add parity tests that lock scope fences and provider-neutral vocabulary** - `0917d1f` (test)

## Files Created/Modified
- `guides/commerce.md` - Added explicit lane taxonomy and authority-vs-evidence language including required lifecycle terms.
- `lib/crosswake/support_matrix/support_matrix.ex` - Added entitlement and reconciliation lifecycle posture overrides for capability support rows.
- `guides/support_matrix.md` - Regenerated from renderer with updated stale/pending non-granting semantics.
- `test/crosswake/guides/commerce_test.exs` - Locked lane heading/vocabulary and provider-term refutes in lifecycle section.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Added stale/pending/awaiting wording assertions in docs and generated output.
- `test/crosswake/support_matrix/renderer_test.exs` - Added semantic assertions and direct-authority-grant rejection checks in rendered support output.

## Decisions Made
- Lifecycle vocabulary stays explicit and Crosswake-owned in public guidance, while provider-specific terms are only referenced as out-of-scope context.
- `SupportMatrix.canonical/1` remains the source of truth for support semantics; `guides/support_matrix.md` is regenerated instead of hand-edited.
- Pending and awaiting verification states are enforced as non-granting in both source semantics and rendered docs tests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Verification
- `mix test test/crosswake/guides/commerce_test.exs` ✅
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` ✅
- `mix test test/crosswake/guides/commerce_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` ✅
- `rg "Entitlement Snapshot Lanes|awaiting_verification|billing_retry|provider adapters are out of scope|storekit|play_billing|revenuecat" guides test/crosswake/guides test/crosswake/support_matrix lib/crosswake/support_matrix` ✅

## Self-Check: PASSED

## Next Phase Readiness
- Phase 20 Plan 03 completed with provider-neutral lifecycle wording synchronized across docs and generated support truth.
- Ready for the next plan/phase step in v3.2 without widening into provider adapter implementation.

---
*Phase: 20-entitlement-lifecycle-semantics*
*Completed: 2026-05-27*
