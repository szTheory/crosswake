---
phase: 13-commerce-and-entitlement-contract
plan: 02
subsystem: commerce
tags:
  - commerce
  - contracts
  - backend-authority
  - documentation
depends_on:
  - 13-01
requires:
  - core
provides:
  - commerce-reconciliation-vocabulary
  - backend-authority-guide
affects:
  - core
  - docs
tech_stack_added: []
tech_stack_patterns:
  - explicit evidence vs authority vocabulary
  - backend-owned idempotency fields
key_files_created:
  - lib/crosswake/commerce/reconciliation.ex
  - test/crosswake/commerce/reconciliation_test.exs
  - guides/commerce.md
  - test/crosswake/guides/commerce_test.exs
key_files_modified: []
key_decisions:
  - "D-13-02-01: Encode reconciliation vocabulary distinguishing attempt, evidence result, and idempotency key from correlation id."
  - "D-13-02-02: Create canonical backend-authority commerce guide documenting explicit non-goals for offline replay and split-brain."
duration: "5 minutes"
completed_date: "2026-05-19"
---

# Phase 13 Plan 02: Backend-Truth Entitlement Flow Summary

Implement D-14 through D-23 so COMM-02 is enforceable, testable, and hard to misread.

## Completed Tasks

1. **Task 1: Encode backend-owned reconciliation vocabulary and evidence-only outcomes**
   - Defined `Attempt`, `EvidenceResult`, and `IdempotencyKey` to strictly model evidence vs authority.
   - Kept transient `correlation_id` supplementary rather than part of the provider-aware idempotency keys.
   - Verified that outcome vocabulary explicitly separates reconciliation states (`pending_purchase`, `awaiting_verification`) from actual entitlement access.
2. **Task 2: Publish one canonical backend-truth entitlement guide and lock it mechanically**
   - Authored `guides/commerce.md` with explicit language emphasizing that device success is evidence, not entitlement.
   - Documented the canonical backend reconciliation flow.
   - Created `test/crosswake/guides/commerce_test.exs` to enforce that exact wording for "authority", "evidence", "split-brain", and "offline purchase replay" exists.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None found.

## Self-Check: PASSED

