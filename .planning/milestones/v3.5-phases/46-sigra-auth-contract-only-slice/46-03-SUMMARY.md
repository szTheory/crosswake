---
phase: 46-sigra-auth-contract-only-slice
plan: 03
subsystem: auth
tags: [sigra, route-gate, denial, auth-context, proof]
requires:
  - phase: 46-02
    provides: auth predicate DSL and manifest route-entry auth fields
provides:
  - fail-closed :step_up_required denial reason for route activation
  - RouteGate auth predicate enforcement with backend auth_context checks
  - hermetic AUTH-02 proof for missing, weak, stale auth and precedence
affects: [phase-46-04, doctor-output, support-matrix-truth]
tech-stack:
  added: []
  patterns: [deny-by-default auth predicates, precedence-locked gate chain]
key-files:
  created: [.planning/phases/46-sigra-auth-contract-only-slice/46-03-SUMMARY.md]
  modified:
    - lib/crosswake/shell/denial.ex
    - lib/crosswake/compatibility/route_gate.ex
    - test/crosswake/proof/phase46_sigra_auth_contract_test.exs
    - test/crosswake/doctor/doctor_test.exs
key-decisions:
  - "Auth predicates evaluate only after kill-switch and companion gate checks, and before compatibility/commerce findings."
  - "RouteGate uses Crosswake.Companions.Sigra.Contracts helpers for MFA ordering and auth-age normalization."
  - "step_up_required denial payload stays on an explicit minimal allowlist."
patterns-established:
  - "Route auth checks are additive denials only; they cannot reopen denied routes."
  - "Backend auth_context validation failure maps to fail-closed step-up denial."
requirements-completed: [AUTH-02]
duration: 28min
completed: 2026-05-31
---

# Phase 46 Plan 03: Sigra Auth Contract-Only Slice Summary

**RouteGate now enforces auth predicates with fail-closed `:step_up_required` denials using backend auth context and locked denial precedence.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-05-31T16:50:00Z
- **Completed:** 2026-05-31T17:18:00Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Added first-class `:step_up_required` denial vocabulary in `Crosswake.Shell.Denial`.
- Wired `RouteGate.evaluate/4` auth checks after kill-switch/gate denials and before compatibility/commerce denials.
- Extended hermetic Phase 46 proof coverage for missing auth context, weak MFA, stale auth age, and precedence guarantees.
- Updated doctor denial-reason snapshot additively for `step_up_required`.

## Task Commits

1. **Task 1 (TDD RED): auth denial proof + snapshot update** - `90d146e` (test)
2. **Task 1 (TDD GREEN): RouteGate auth enforcement + denial reason** - `c8ca922` (feat)

## Files Created/Modified
- `lib/crosswake/shell/denial.ex` - added `:step_up_required` to denial reason vocabulary and types.
- `lib/crosswake/compatibility/route_gate.ex` - added backend `auth_context` evaluation and fail-closed auth denial creation.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` - added AUTH-02 runtime-denial and precedence proof cases.
- `test/crosswake/doctor/doctor_test.exs` - additive denial-reason snapshot update for `step_up_required`.

## Decisions Made
- Kept auth checks dependent on explicit backend `auth_context`, validating with Sigra contracts before evaluation.
- Preserved locked precedence by skipping auth evaluation when gate denials already exist.
- Limited step-up denial details to typed, non-sensitive fields plus optional backend reference ids.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan listed `mix test ... -x`; in this project `-x` is unsupported. Verification used `--trace` per required verification command.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Runtime auth predicate enforcement is complete and proven; Phase 46-04 can add doctor/support-matrix auth surface truth on top of stable RouteGate behavior.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/46-sigra-auth-contract-only-slice/46-03-SUMMARY.md`.
- Task commits exist in git history: `90d146e`, `c8ca922`.

---
*Phase: 46-sigra-auth-contract-only-slice*
*Completed: 2026-05-31*
