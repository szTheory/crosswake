---
phase: 149-saas-admin-showcase
plan: 02
subsystem: fixture-data
tags: [adminpilot, fixtures, reset-digest, auth-posture, exunit]

requires:
  - phase: 149-saas-admin-showcase
    provides: Wave 0 RED contracts from 149-01
provides:
  - Dense deterministic AdminPilot SaaS/admin fixture breadth
  - Read-only account, team, role, settings, and activity context helpers
  - Reset counts and digest components for expanded static SaaS breadth
affects: [phase-149-saas-admin-showcase, phase-152-capability-map, showcase-reset]

tech-stack:
  added: []
  patterns:
    - Deterministic fixture maps remain the source for static SaaS/admin breadth
    - Showcase reset digest delegates static SaaS breadth to SaaSPortal.Fixtures.digest_components/0
    - Read-only AdminPilot context helpers project fixture data without adding CRUD or persistence

key-files:
  created:
    - .planning/phases/149-saas-admin-showcase/149-02-SUMMARY.md
    - .planning/phases/149-saas-admin-showcase/deferred-items.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex
    - examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex
    - examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs
    - examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs

key-decisions:
  - "Kept account, team, role, setting, operational-record, policy, activity, and admin-pressure breadth as deterministic fixture maps; no static SaaS persistence was added."
  - "Delegated SaaS reset digest components to SaaSPortal.Fixtures.digest_components/0 so reset truth changes with static fixture IDs, titles, and roles."
  - "Added Priya Owner to the role vocabulary and kept approval authority role-based through server-owned session helpers."

patterns-established:
  - "AdminPilot static breadth is available through fixture accessors and read-only Accounts projections."
  - "Showcase reset counts now report expanded SaaS breadth instead of only accounts/users/approvals."
  - "Full-suite failures from later RED contracts are logged in phase deferred-items instead of being fixed out of scope."

requirements-completed: [SAAS-01, SAAS-02]

duration: 8 min
completed: 2026-07-11
status: complete
---

# Phase 149 Plan 02: AdminPilot Fixture Breadth Summary

**Deterministic AdminPilot account, team, role, settings, operational, activity, and admin-pressure fixture data with read-only context helpers and reset digest truth.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-11T00:21:44Z
- **Completed:** 2026-07-11T00:30:06Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Expanded `SaaSPortal.Fixtures` from the old two-user Phase 7 sample into AdminPilot fixture breadth covering Northwind account data, one team, three users/roles, settings, approvals, operational records, approval policies, activity events, admin pressure, and deterministic digest components.
- Added read-only `SaaSPortal.Accounts` helpers for account summary, team, role summary, settings, and activity context.
- Updated showcase reset counts and digest components so static SaaS/admin breadth is deterministic and visible to reset tests and the E2E reset endpoint.

## Task Commits

1. **Task 1: Expand deterministic AdminPilot fixture density** - `70d9c140` (feat)
2. **Task 2: Add read context helpers and reset digest coverage for static SaaS breadth** - `033deb3c` (feat)

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` - AdminPilot fixture data and stable digest components.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` - Fixture role vocabulary with owner role and role-based approval helper.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex` - Read-only context helpers over deterministic fixture data.
- `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` - Expanded SaaS reset counts and digest delegation.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Reset count assertion updated to the expanded AdminPilot static shape.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - E2E reset endpoint assertion updated to the expanded AdminPilot static shape.
- `.planning/phases/149-saas-admin-showcase/deferred-items.md` - Out-of-scope later-plan RED failures logged.

## Decisions Made

- Static AdminPilot breadth stays fixture-backed in this plan. Mutable approval/activity persistence remains later-plan work.
- Reset digest truth is source-owned by `SaaSPortal.Fixtures.digest_components/0`, avoiding a duplicate digest list in `Showcase.Fixtures`.
- Owner is part of the fixture role vocabulary and approval authority remains a server-owned role check, not a route param or native signal.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification Bug] Updated stale reset endpoint expectation**
- **Found during:** Plan-level verification after Task 2
- **Issue:** `showcase_reset_controller_test.exs` still asserted the Phase 147 SaaS reset shape with two users and no expanded AdminPilot breadth.
- **Fix:** Updated the E2E reset controller test to assert the same expanded static SaaS count shape as `reset_test.exs`.
- **Files modified:** `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs`
- **Verification:** `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs`
- **Committed in:** `033deb3c`

**Total deviations:** 1 auto-fixed verification bug.
**Impact on plan:** Kept reset truth aligned with the planned expanded fixture breadth; no scope expansion into diagnostics, approval persistence, UI, native controls, or generic admin framework behavior.

## Issues Encountered

- `cd examples/phoenix_host && mix test` fails on six intentionally RED Wave 0 contracts owned by later plans: diagnostics route rows/enrichment, approval persistence/context, and approval queue/detail LiveView states. These are logged in `.planning/phases/149-saas-admin-showcase/deferred-items.md`.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs` - PASS.
- `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` - PASS.
- `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs` - PASS, 7 tests.
- `cd examples/phoenix_host && mix test` - FAIL as expected on six later-plan RED contracts from 149-01.
- `cd examples/phoenix_host && mix test --exclude diagnostics_route_rows --exclude diagnostics_enrichment --exclude approval_schema_persistence --exclude approval_context_workflow --exclude approval_queue_live --exclude approval_detail_live` - PASS, 47 tests, 6 excluded.

## Known Stubs

None. Stub scan found no TODO/FIXME, placeholder UI text, hardcoded empty UI feeds, or mock production data sources in files created or modified by this plan.

## Threat Flags

None. This plan added deterministic fictional `.invalid` fixture records, read-only context projections, and reset digest/count coverage only. It did not add endpoints, schemas, auth paths, native-control APIs, or persistent static SaaS tables.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `149-03-PLAN.md`. AdminPilot static fixture breadth and reset truth are now available for lane-local diagnostics, approval persistence, shared UI, and route-tour proof without reinterpreting SAAS-01/SAAS-02 data requirements.

## Self-Check: PASSED

- `149-02-SUMMARY.md` exists.
- `.planning/phases/149-saas-admin-showcase/deferred-items.md` exists.
- Key implementation files exist on disk.
- Commits `70d9c140` and `033deb3c` exist in git history.
- Focused plan verification passed; full-suite later-plan RED failures are documented.

---
*Phase: 149-saas-admin-showcase*
*Completed: 2026-07-11*
