---
phase: 20-entitlement-lifecycle-semantics
plan: 04
subsystem: commerce
tags: [entitlement_snapshot, reconciliation, fail-closed, evidence-source, regression-tests]
requires:
  - phase: 20-02
    provides: authority-separation enforcement and ENTL-03 non-authoritative evidence guardrails
  - phase: 20-03
    provides: synchronized lifecycle semantics in docs and support truth
provides:
  - fail-closed source validation at entitlement snapshot construction boundary
  - fail-closed source validation at reconciliation evidence ingestion boundary
  - regression tests locking invalid-source rejection and canonical-source acceptance
affects: [phase-20-verification, phase-21-reconciliation-example, phase-22-commerce-support-proof]
tech-stack:
  added: []
  patterns: [canonical source normalization, boundary validation with explicit error metadata]
key-files:
  created:
    - .planning/phases/20-entitlement-lifecycle-semantics/20-04-SUMMARY.md
  modified:
    - lib/crosswake/commerce/contracts.ex
    - lib/crosswake/commerce/reconciliation.ex
    - test/crosswake/commerce/contracts_test.exs
    - test/crosswake/commerce/reconciliation_test.exs
key-decisions:
  - "Canonical source vocabulary is enforced at runtime boundaries, not only in type declarations and docs."
  - "Canonical string sources are normalized to atoms, while unknown atom/string values return explicit invalid-source errors."
  - "Invalid-source rejection is treated as regression-critical in both snapshot and reconciliation paths."
patterns-established:
  - "Use `Contracts.canonical_reconciliation_evidence_source/1` as the shared source validation contract."
  - "Validate source before constructing externally visible result structs to preserve fail-closed behavior."
requirements-completed: [ENTL-03]
duration: 8 min
completed: 2026-05-27
---

# Phase 20 Plan 04: ENTL-03 Source Validation Gap Closure Summary

**Closed the ENTL-03 verification gap by enforcing canonical evidence-source vocabulary fail-closed in both snapshot construction and reconciliation ingestion paths.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T06:22:00-04:00
- **Completed:** 2026-05-27T06:30:00-04:00
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Added shared canonical source validation with actionable error metadata in `Contracts`.
- Reconciliation ingestion now rejects invalid source values before emitting `%EvidenceResult{}`.
- Added regression tests for invalid-source rejection and canonical-source acceptance across both required test files.

## Task Commits

Each task was committed atomically:

1. **Task 1: Enforce canonical `EvidenceLane.source` in `Contracts.new_entitlement_snapshot/1`** - `08eb04e` (fix)
2. **Task 2: Enforce canonical `ReconciliationEvidence.source` in `Reconciliation.ingest_evidence/2`** - `f15d9ff` (fix)
3. **Task 3: Lock regression coverage for invalid source rejection across both ENTL-03 paths** - `3dc99bf` (test)

## Files Created/Modified
- `lib/crosswake/commerce/contracts.ex` - Added canonical source validation/normalization helpers and fail-closed evidence lane validation.
- `lib/crosswake/commerce/reconciliation.ex` - Added ingestion boundary source validation and explicit invalid-source error return.
- `test/crosswake/commerce/contracts_test.exs` - Added invalid-source rejection and canonical-source acceptance coverage for snapshot construction.
- `test/crosswake/commerce/reconciliation_test.exs` - Added invalid-source rejection and canonical-source acceptance coverage for ingestion.

## Decisions Made
- Reused a shared source-validation function in `Contracts` to avoid drift between snapshot and reconciliation enforcement.
- Kept enforcement provider-neutral by validating only canonical vocabulary (`:device | :storefront | :webhook | :support`) without provider-specific semantics.
- Returned structured invalid-source metadata to keep rejection actionable in tests and downstream diagnostics.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Verification
- `mix test test/crosswake/commerce/contracts_test.exs` ✅
- `mix test test/crosswake/commerce/reconciliation_test.exs` ✅
- `mix test test/crosswake/commerce/contracts_test.exs test/crosswake/commerce/reconciliation_test.exs` ✅
- `rg "new_entitlement_snapshot|ingest_evidence|EvidenceLane|ReconciliationEvidence" lib/crosswake/commerce/contracts.ex lib/crosswake/commerce/reconciliation.ex` ✅
- `rg "device_callback|invalid source|invalid evidence source" test/crosswake/commerce/contracts_test.exs test/crosswake/commerce/reconciliation_test.exs` ✅

## Self-Check: PASSED

## Next Phase Readiness
- ENTL-03 fail-closed source semantics are now runtime-enforced and test-locked in core commerce boundaries.
- Phase 20 can proceed to final verification and completion updates.

---
*Phase: 20-entitlement-lifecycle-semantics*
*Completed: 2026-05-27*
