---
phase: 71-notification-driven-workflow-proof
plan: "02"
subsystem: notifications
tags: [chimeway, sigra, route_gate, denial_codes, example_host]
requires:
  - phase: 71-notification-driven-workflow-proof
    provides: 71-01 red proof contract
provides:
  - Canonical Chimeway action-mismatch and binding-revoked denial normalization
  - Example-host stored action-ref validation for one-time notification-open intents
  - Notification-source RouteGate denials that halt before fallback redirects
affects: [phase-71, notification-open, route-gate, support-truth]
tech-stack:
  added: []
  patterns: [closed denial-code mapping, route-source transition guard, backend intent action validation]
key-files:
  created: []
  modified:
    - lib/crosswake/companions/chimeway/denial_codes.ex
    - lib/crosswake/companions/chimeway/resolver.ex
    - lib/crosswake/compatibility/route_gate.ex
    - examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex
    - test/crosswake/proof/phase71_notification_workflow_proof_test.exs
    - test/crosswake/companions/chimeway/resolver_test.exs
    - test/crosswake/companions/chimeway/denial_codes_test.exs
    - test/crosswake/compatibility/route_gate_test.exs
    - examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
key-decisions:
  - "Unknown intent states fail closed as notification.open.policy_denied rather than interpolating public codes."
  - "Notification-source auth denials always halt before configured fallback redirects."
patterns-established:
  - "Resolver preserves Sigra step-up denials while normalizing only Chimeway intent states."
requirements-completed: [NOTF-01, NOTF-02]
duration: 34 min
completed: 2026-06-04
---

# Phase 71 Plan 02: Resolver And RouteGate Closure Summary

**Chimeway notification opens now preserve backend auth authority and fail closed through canonical route-policy denials**

## Performance

- **Duration:** 34 min
- **Started:** 2026-06-04T22:08:00Z
- **Completed:** 2026-06-04T22:08:00Z
- **Tasks:** 4
- **Files modified:** 9

## Accomplishments

- Added `notification.open.action_mismatch` and closed Chimeway intent-state normalization.
- Validated example-host one-time open intents against stored `action_ref`.
- Changed RouteGate so notification-source denials halt before Phoenix fallback redirects.
- Greened the Phase 71 proof and targeted resolver/RouteGate/example-host regressions.

## Task Commits

1. **Task 71-02-01..04: Resolver, registry, and RouteGate closure** - `6878faf` (fix)

## Files Created/Modified

- `lib/crosswake/companions/chimeway/denial_codes.ex` - Added action-mismatch code.
- `lib/crosswake/companions/chimeway/resolver.ex` - Closed intent-state to public-code mapping.
- `lib/crosswake/compatibility/route_gate.ex` - Notification activation denials halt.
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` - Stored action refs must match incoming evidence.
- Targeted tests under `test/crosswake/...` and `examples/phoenix_host/test/...`.

## Decisions Made

Preserved existing Sigra denial pass-through. Chimeway handles notification-open intent failures; RouteGate/Sigra remain the authority for route activation.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

The root Mix project cannot compile example-host Ecto tests directly. The registry test was verified from `examples/phoenix_host`, which is the correct Mix project for that lane.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 71-03 CI, support matrix, guide, and operator truth.

---
*Phase: 71-notification-driven-workflow-proof*
*Completed: 2026-06-04*
