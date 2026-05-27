---
phase: 20-entitlement-lifecycle-semantics
plan: 02
subsystem: commerce
tags: [entitlements, reconciliation, manifest, validation]
requires:
  - phase: 20-01
    provides: entitlement lane contracts and lifecycle vocabulary baseline
provides:
  - bounded reconciliation evidence envelope with normalized source and provenance metadata
  - non-authoritative evidence ingestion contract returning typed evidence-processing results
  - nested provider-vocabulary rejection guards for commerce entitlement/evidence structures
affects: [20-03, reconciliation-example, support-truth]
tech-stack:
  added: []
  patterns:
    - evidence-is-not-authority
    - provider-neutral-core-vocabulary
    - fail-closed-reconciliation-mapping
key-files:
  created: []
  modified:
    - lib/crosswake/commerce/contracts.ex
    - test/crosswake/commerce/contracts_test.exs
    - lib/crosswake/commerce.ex
    - lib/crosswake/commerce/reconciliation.ex
    - test/crosswake/commerce/reconciliation_test.exs
    - lib/crosswake/manifest/validator.ex
    - test/crosswake/manifest/validator_test.exs
key-decisions:
  - "Reconciliation evidence requires bounded provenance fields and deterministic integrity/idempotency metadata."
  - "Evidence ingestion returns reconciliation evidence results and explicitly forbids authority lane mutation from evidence input."
  - "Provider-specific terms are rejected in nested commerce entitlement/evidence structures in route and corridor validation paths."
patterns-established:
  - "Evidence processing maps unverified success-like events to :awaiting_verification and unknown kinds to :verification_failed."
  - "Replay idempotency checks preserve non-granting reconciliation states and never imply :active authority."
requirements-completed: [ENTL-03, ENTL-02]
duration: 4 min
completed: 2026-05-27
---

# Phase 20 Plan 02: Authority Separation and ENTL-03 Invariant Lock Summary

**Bounded reconciliation evidence ingestion now stays non-authoritative by contract, with explicit fail-closed mappings and nested provider-vocabulary rejection in core validation paths.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-27T10:05:00Z
- **Completed:** 2026-05-27T10:08:49Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Normalized `ReconciliationEvidence` to bounded source/provenance metadata and removed unbounded payload-style fields.
- Changed commerce callback seam to return `%Crosswake.Commerce.Reconciliation.EvidenceResult{}` and added explicit authority-mutation blocking.
- Added nested provider-vocabulary guards and tests covering `storekit`, `play_billing`, and `revenuecat` rejection.

## Task Commits

Each task was committed atomically:

1. **Task 1: Normalize reconciliation evidence envelope to bounded provenance fields** - `bf1e8fd` (feat)
2. **Task 2: Keep evidence ingestion non-authoritative in the backend seam and reconciliation module** - `8885cfd` (feat)
3. **Task 3: Harden provider-leak and authority-shortcut checks in core validators/tests** - `05624e9` (feat)

## Files Created/Modified
- `lib/crosswake/commerce/contracts.ex` - expanded bounded evidence envelope and source vocabulary helper.
- `test/crosswake/commerce/contracts_test.exs` - added envelope metadata assertions and normalized source vocabulary lock.
- `lib/crosswake/commerce.ex` - updated ingestion callback return type to evidence-processing result.
- `lib/crosswake/commerce/reconciliation.ex` - added evidence ingestion helpers, fail-closed status mapping, replay tracking, and authority override rejection.
- `test/crosswake/commerce/reconciliation_test.exs` - added negative ENTL-03 assertions for non-authoritative ingestion and replay behavior.
- `lib/crosswake/manifest/validator.ex` - added nested semantic provider-vocabulary guards for commerce entitlement/evidence structures.
- `test/crosswake/manifest/validator_test.exs` - added provider-term rejection tests for nested route/corridor commerce semantics.

## Decisions Made
- Used explicit bounded fields (`provider`, `provider_reference`, `event_kind`, `evidence_ref`, `captured_at`) for reconciliation evidence provenance.
- Treated projection refresh as opt-in via backend verification marker; unverified evidence remains `:awaiting_verification`.
- Scoped unknown evidence kinds to `:verification_failed` to preserve fail-closed behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Initial validator test assumption that fixture corridors were pre-populated failed; resolved by creating explicit corridor fixtures in new rejection tests.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/crosswake/commerce/contracts_test.exs` ✅
- `mix test test/crosswake/commerce/reconciliation_test.exs` ✅
- `mix test test/crosswake/manifest/validator_test.exs` ✅
- `rg "device_callback|storefront|awaiting_verification|verification_failed|storekit|play_billing|revenuecat" lib/crosswake/commerce lib/crosswake/manifest test/crosswake/commerce test/crosswake/manifest` ✅

## Next Phase Readiness
- Phase 20 plan `20-03` can proceed with authority separation and provider-neutral invariant guards already enforced.
- No blockers from this plan remain.

---
*Phase: 20-entitlement-lifecycle-semantics*
*Completed: 2026-05-27*
