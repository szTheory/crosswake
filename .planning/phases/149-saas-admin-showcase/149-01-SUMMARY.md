---
phase: 149-saas-admin-showcase
plan: 01
subsystem: testing
tags: [exunit, playwright, tdd-red, route-tour, adminpilot]

requires:
  - phase: 147-arc-fixture-and-showcase-foundation
    provides: showcase reset endpoint, route-tour semantic proof pattern, and root hub route-owner labels
  - phase: 148-demo-app-brand-fixture-direction
    provides: AdminPilot brand identity and fixture-density brief
provides:
  - Wave 0 RED ExUnit contracts for AdminPilot fixture density, diagnostics, approvals, and LiveView states
  - RED Playwright route-tour contract for the AdminPilot dashboard to approval success path
  - Task-scoped tags for later Phase 149 implementation plans
affects: [phase-149-saas-admin-showcase, phase-152-capability-map, route-tour-proof]

tech-stack:
  added: []
  patterns:
    - RED contracts use Code.ensure_loaded?/1 and function_exported?/3 to fail on behavior gaps, not setup errors
    - Route-tour screenshots remain collateral after semantic route and workflow assertions

key-files:
  created:
    - examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs
    - examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs
    - examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs
    - examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs
    - .planning/phases/149-saas-admin-showcase/149-01-SUMMARY.md
  modified:
    - examples/phoenix_host/e2e/route_tour.spec.ts

key-decisions:
  - "Kept Plan 149-01 intentionally RED-only because Wave 0 defines contracts and later Phase 149 plans implement them."
  - "AdminPilot route-tour screenshots are captured only after route-id, ownership, approval, and diagnostics assertions."
  - "Approval and diagnostics tests require Phoenix/server authority and compiled route metadata instead of native mutation authority or prose-only support truth."

patterns-established:
  - "Task-scoped ExUnit tags: fixture_density, diagnostics_route_rows, diagnostics_enrichment, approval_schema_persistence, approval_context_workflow, approval_queue_live, approval_detail_live."
  - "AdminPilot browser helper uses /_e2e/showcase-reset and the planned /_e2e/saas-session helper before the approval flow."
  - "Mobile reduced-motion route tour now runs the AdminPilot flow with screenshot capture disabled."

requirements-completed: [SAAS-01, SAAS-02, SAAS-03, SAAS-04]

duration: 7 min
completed: 2026-07-11
status: complete
---

# Phase 149 Plan 01: AdminPilot Wave 0 Contracts Summary

**Executable RED contracts for AdminPilot fixture density, route-policy diagnostics, server-owned approval behavior, and route-tour proof ordering.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-11T00:08:40Z
- **Completed:** 2026-07-11T00:16:14Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added four ExUnit contract files under `test/crosswake_example/saas_portal/` covering AdminPilot data density, diagnostics, approval context behavior, and LiveView states.
- Extended the Playwright route tour with `proveAdminPilotApprovalFlow(page)` for dashboard -> approvals queue -> approval detail -> approve -> diagnostics.
- Preserved the Phase 149 boundary: tests are RED contracts only; no production module, route, endpoint, schema, or native-control API was added.

## Task Commits

1. **Task 1: Create RED ExUnit contracts for AdminPilot data, diagnostics, and approval behavior** - `f8e5c9f1` (test)
2. **Task 2: Add RED AdminPilot route-tour assertions before screenshot collateral** - `9c3e06bc` (test)

**Plan metadata:** recorded in the final docs/state/roadmap commit for this plan.

## Files Created/Modified

- `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` - Fixture density, route-id, settings, activity, admin pressure, and digest contract.
- `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` - Compiled router metadata and diagnostics enrichment contract.
- `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` - Approval reset, persistence evidence, activity trail, and scoped authorization contract.
- `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` - Queue/detail LiveView state and optional haptics contract.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - AdminPilot route-tour helper, screenshot names, e2e session expectation, and mobile focus coverage.

## Decisions Made

- Followed the plan's Wave 0 contract shape instead of implementing production code in this plan.
- Kept route-tour proof semantic-first: route IDs, LiveView ownership, cached read-only support truth, approval success, haptics payload, and diagnostics text are asserted before AdminPilot screenshots.
- Left the real `/_e2e/saas-session` endpoint, persisted approval/activity evidence, diagnostics module, and richer fixtures for later Phase 149 plans.
- Kept SAAS-01..04 pending in `REQUIREMENTS.md`; this plan covers those requirements with executable RED contracts but does not complete the user-facing lane.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. One assertion message was tightened before commit so a negative offline-write check could not be mistaken for an offline mutation requirement.

## Verification

- `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs --trace > /tmp/phase149-wave0-exunit-red.log 2>&1; status=$?; test "$status" -ne 0 && rg "AdminPilot fixture density contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot diagnostics route rows contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot approval schema persistence contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot approval queue LiveView contract" /tmp/phase149-wave0-exunit-red.log && ! rg "SyntaxError|CompileError|UndefinedFunctionError|FunctionClauseError|MatchError|ArgumentError|RuntimeError|KeyError|Protocol\\.UndefinedError|CaseClauseError|WithClauseError|BadMapError|BadBooleanError|BadArityError|cannot compile" /tmp/phase149-wave0-exunit-red.log'`
  - Result: PASS. The command failed as expected for RED behavior gaps and the log contained the required contract names with no forbidden setup/runtime failure patterns.
- `cd examples/phoenix_host && rg "proveAdminPilotApprovalFlow" e2e/route_tour.spec.ts && rg "/_e2e/saas-session" e2e/route_tour.spec.ts && rg "saas-dashboard" e2e/route_tour.spec.ts && rg "saas-approvals" e2e/route_tour.spec.ts && rg "saas-approval" e2e/route_tour.spec.ts && rg "Approve request" e2e/route_tour.spec.ts && rg "adminpilot-diagnostics" e2e/route_tour.spec.ts`
  - Result: PASS. All required route-tour contract strings are present.
- `cd examples/phoenix_host && npx playwright test --list e2e/route_tour.spec.ts`
  - Result: PASS. Playwright can parse and list the modified route-tour spec.

## TDD Gate Compliance

This plan is intentionally RED-only. It creates Wave 0 executable contracts for later Phase 149 implementation plans and explicitly forbids production modules in Task 1. No GREEN commit is present by design; Plans 149-02 through 149-07 are expected to satisfy these contracts.

## Known Stubs

None. The new files are tests and route-tour contracts; stub scan found no TODO/FIXME, placeholder UI data, hardcoded empty UI feed, or mock production data source.

## Threat Flags

None. The plan added test expectations only. It references the planned gated `/_e2e/saas-session` helper but does not add a new endpoint, auth path, schema, or production trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `149-02-PLAN.md`. Later plans can run the task-scoped tags to implement fixture breadth, route diagnostics, persisted approval/activity evidence, UI states, the gated e2e session helper, and full browser proof without re-interpreting the Phase 149 decisions.

## Self-Check: PASSED

- `149-01-SUMMARY.md` exists.
- All five plan-owned files exist on disk.
- Commits `f8e5c9f1` and `9c3e06bc` exist in git history.
- Required plan verification commands passed.

---
*Phase: 149-saas-admin-showcase*
*Completed: 2026-07-11*
