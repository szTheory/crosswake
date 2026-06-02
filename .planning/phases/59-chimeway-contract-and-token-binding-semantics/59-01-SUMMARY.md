---
phase: 59-chimeway-contract-and-token-binding-semantics
plan: "01"
subsystem: notifications
tags: [chimeway, companion, token-binding, contracts, redaction]
requires: []
provides:
  - Chimeway companion entrypoint with contract-only support posture
  - TokenEvidence, TokenBinding, ProviderFeedback, BindingEvent, and BindingResult contracts
  - Closed provider/platform/environment/state/reason/feedback vocabularies
affects: [phase-60-token-registry, phase-61-notification-open, phase-62-diagnostics]
tech-stack:
  added: []
  patterns: [typed-companion-contracts, backend-owned-binding-projection, safe-serialization]
key-files:
  created:
    - lib/crosswake/companions/chimeway.ex
    - lib/crosswake/companions/chimeway/contracts.ex
    - test/crosswake/companions/chimeway_test.exs
    - test/crosswake/companions/chimeway/contracts_test.exs
  modified: []
key-decisions:
  - "Chimeway reports notification contract readiness without claiming delivery or notification-open support."
  - "Public token contracts expose token_ref and token_fingerprint, never raw token aliases."
patterns-established:
  - "State plus reason models token-binding lifecycle semantics for TOKN-02."
  - "Atoms stay internal while to_map/1 stringifies public support/JSON boundary values."
requirements-completed: [TOKN-01, TOKN-02]
duration: 15min
completed: 2026-06-02
---

# Phase 59-01: Chimeway Companion Contract And Lifecycle Vocabulary Summary

**Chimeway contract-only companion entrypoint plus provider-neutral token evidence and backend binding contracts**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-02T18:34:12Z
- **Completed:** 2026-06-02T18:52:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Crosswake.Companions.Chimeway` as an in-tree first-party companion with pass-through route gating and explicit `delivery_support: :not_shipped` / `open_routing: :not_shipped` state.
- Added `Crosswake.Companions.Chimeway.Contracts` with typed evidence, binding, provider feedback, binding event, and binding result structs.
- Locked TOKN-02 lifecycle semantics through state plus reason mappings and tests for public raw-token alias rejection.

## Task Commits

1. **Tasks 59-01-01 and 59-01-02:** `40a9c97` (`feat(59-01): add chimeway token contracts`)

## Files Created/Modified

- `lib/crosswake/companions/chimeway.ex` - Chimeway companion entrypoint and contract-only runtime state.
- `lib/crosswake/companions/chimeway/contracts.ex` - Closed vocabularies, typed contract structs, constructors, validators, and safe `to_map/1`.
- `test/crosswake/companions/chimeway_test.exs` - Companion callback and non-claim state coverage.
- `test/crosswake/companions/chimeway/contracts_test.exs` - Vocabulary, lifecycle, serialization, and raw-token alias coverage.

## Decisions Made

Followed the plan-specified contract shape. `TokenBinding` carries backend-owned subject/session scope as optional fields, while `TokenEvidence` remains provider/device evidence only.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope drift.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/crosswake/companions/chimeway_test.exs test/crosswake/companions/chimeway/contracts_test.exs --trace` — passed, 11 tests all passing.

## Self-Check: PASSED

## Next Phase Readiness

Phase 59-02 can build raw-token redaction and telemetry on top of the Chimeway contract structs.

---
*Phase: 59-chimeway-contract-and-token-binding-semantics*
*Completed: 2026-06-02*
