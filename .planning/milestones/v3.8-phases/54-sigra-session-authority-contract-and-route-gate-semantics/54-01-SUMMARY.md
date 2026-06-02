---
phase: 54-sigra-session-authority-contract-and-route-gate-semantics
plan: "01"
subsystem: auth
tags: [sigra, session-authority, denial-codes, route-gate]
requires:
  - phase: 46-sigra-auth-contract-only-slice
    provides: contract-only Sigra AuthContext, SessionAuthorityLane, and step-up denial anchors
provides:
  - Rich backend-owned Sigra SessionAuthorityLane lifecycle contract
  - Canonical auth.step_up.* denial-code registry and safe detail sanitizer
  - Phase 54 proof scaffold for session-authority and denial-taxonomy truth
affects: [phase-54, phase-55, phase-56, phase-57, phase-58, sigra]
tech-stack:
  added: []
  patterns: [plain-struct contract validation, canonical denial-code registry, allowlisted shell details]
key-files:
  created:
    - lib/crosswake/companions/sigra/denial_codes.ex
    - test/crosswake/proof/phase54_sigra_session_authority_test.exs
  modified:
    - lib/crosswake/companions/sigra/contracts.ex
    - test/crosswake/companions/sigra/contracts_test.exs
key-decisions:
  - "SessionAuthorityLane is the backend-owned authority projection; client evidence cannot set authority fields."
  - "Auth route failures keep public shell reason :step_up_required while using canonical auth.step_up.* subcodes."
patterns-established:
  - "Sigra denial details are allowlisted through Crosswake.Companions.Sigra.DenialCodes."
  - "Phase 46 mfa/auth-age aliases remain migration-safe but derive from richer session authority when present."
requirements-completed: [SESS-01, DIAG-01]
duration: 22min
completed: 2026-06-02
---

# Phase 54-01: Sigra Authority Contract And Denial Registry Summary

**Backend-owned Sigra session authority contract with canonical auth.step_up denial subcodes and sanitized shell details**

## Performance

- **Duration:** 22 min
- **Started:** 2026-06-02T01:10:00Z
- **Completed:** 2026-06-02T01:32:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Expanded `SessionAuthorityLane` with explicit lifecycle, assurance, freshness, expiry, remembered/cached, version, and revocation fields.
- Added `Crosswake.Companions.Sigra.DenialCodes` as the canonical auth denial-code and shell-safe detail registry.
- Added Phase 54 proof coverage for backend authority shape, evidence authority-smuggling rejection, denial taxonomy, and later-phase non-claims.

## Task Commits

1. **Task 1/2: Contract tests and implementation** - `036b13d` (`feat(54-01): expand Sigra session authority contracts`)

## Verification

- `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs --trace` — 16 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial focused test run caught a normalizer argument-order bug and a self-matching non-claim assertion. Both were fixed before the production commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`54-03` can consume `SessionAuthorityLane`, assurance/time helpers, and `DenialCodes` for evaluator and RouteGate denial construction.

---
*Phase: 54-sigra-session-authority-contract-and-route-gate-semantics*
*Completed: 2026-06-02*
