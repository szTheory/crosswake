---
phase: 54-sigra-session-authority-contract-and-route-gate-semantics
plan: "03"
subsystem: auth
tags: [sigra, evaluator, route-gate, denial-codes]
requires:
  - phase: 54-sigra-session-authority-contract-and-route-gate-semantics
    provides: 54-01 session authority contract and denial registry
  - phase: 54-sigra-session-authority-contract-and-route-gate-semantics
    provides: 54-02 route auth_posture manifest truth
provides:
  - Pure Crosswake.Companions.Sigra.Evaluator route-auth decision seam
  - RouteGate delegation to the Sigra evaluator
  - Runtime proof for missing, invalid, inactive, expired, revoked, version-mismatched, weak, stale, remembered, and cached auth denials
affects: [phase-54, route-gate, sigra, phase-56]
tech-stack:
  added: []
  patterns: [pure Sigra evaluator seam, fail-closed auth denial delegation]
key-files:
  created:
    - lib/crosswake/companions/sigra/evaluator.ex
    - test/crosswake/compatibility/route_gate_test.exs
  modified:
    - lib/crosswake/compatibility/route_gate.ex
    - lib/crosswake/companions/sigra/denial_codes.ex
    - test/crosswake/proof/phase54_sigra_session_authority_test.exs
key-decisions:
  - "RouteGate now delegates Sigra auth policy to a pure evaluator after kill-switch/gate checks."
  - "Legacy AuthContext-only denials preserve Phase 46 minimal details while SessionAuthorityLane denials expose richer sanitized facts."
patterns-established:
  - "Sigra evaluator returns allow/deny decisions without transport behavior or ceremony side effects."
  - "Lifecycle/posture failures deny with one canonical code; assurance and freshness failures aggregate safe details for compatibility."
requirements-completed: [SESS-02, SESS-03, DIAG-01]
duration: 28min
completed: 2026-06-02
---

# Phase 54-03: Sigra Evaluator And RouteGate Summary

**Pure Sigra route-auth evaluator wired into RouteGate with canonical fail-closed denial codes**

## Performance

- **Duration:** 28 min
- **Started:** 2026-06-02T01:48:00Z
- **Completed:** 2026-06-02T02:16:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Crosswake.Companions.Sigra.Evaluator.evaluate_route_auth/3` as the single Phase 54 auth policy core.
- Updated `RouteGate.evaluate/4` to preserve kill-switch/gate precedence and delegate auth checks before compatibility/commerce findings.
- Added focused route-gate tests for canonical codes, remembered/cached posture behavior, lifecycle failures, and precedence.

## Task Commits

1. **Task 1/2: Evaluator and RouteGate runtime proof** - `c7c3f36` (`feat(54-03): route auth through Sigra evaluator`)

## Verification

- `mix test test/crosswake/compatibility/route_gate_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/proof/phase46_sigra_auth_contract_test.exs --trace` — 20 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first implementation returned at the first assurance failure; Phase 46 proof expected weak-assurance and stale-auth details to aggregate. The evaluator now aggregates those two safe detail classes while keeping lifecycle/posture denials single-code.
- The denial detail allowlist now includes legacy `required_mfa_level` and `current_mfa_level` aliases so Phase 46 shell-detail compatibility remains intact.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`54-04` can surface evaluator-backed auth posture, denial codes, and route-level `auth_posture` in doctor, support matrix, and operator inspection.

---
*Phase: 54-sigra-session-authority-contract-and-route-gate-semantics*
*Completed: 2026-06-02*
