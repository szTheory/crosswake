---
phase: 149-saas-admin-showcase
plan: 04
subsystem: persistence
tags: [adminpilot, ecto, approvals, reset-digest, server-authority]

requires:
  - phase: 149-saas-admin-showcase
    provides: deterministic AdminPilot fixture breadth from 149-02
  - phase: 149-saas-admin-showcase
    provides: Wave 0 approval persistence/context contracts from 149-01
provides:
  - Narrow persisted approval status evidence for AdminPilot
  - Append-only approval activity evidence with support-safe metadata
  - Scoped approval context using server-owned user/account authority
  - Showcase reset and digest integration for persisted approval/activity rows
affects: [phase-149-saas-admin-showcase, adminpilot-liveview-workflow, showcase-reset]

tech-stack:
  added: []
  patterns:
    - Ecto persistence is limited to mutable approval/activity evidence only
    - Approval mutations use Ecto.Multi and context-level authorization
    - Showcase reset combines deterministic static fixtures with lane-owned persisted evidence

key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260710000000_create_saas_admin_approvals_and_activity_events.exs
    - examples/phoenix_host/lib/crosswake_example/saas_portal/approval.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/approval_activity_event.ex
    - .planning/phases/149-saas-admin-showcase/149-04-SUMMARY.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex
    - examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex
    - examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs
    - examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs
    - .planning/phases/149-saas-admin-showcase/deferred-items.md

key-decisions:
  - "Persisted SaaS state remains limited to approval status and approval activity evidence; accounts, teams, members, roles, settings, and operational records remain deterministic fixture/read-context data."
  - "Approval mutation authority lives in SaaSPortal.Approvals with server-owned user/account scope and Ecto.Multi writes; LiveViews remain dispatch/render surfaces."
  - "Showcase reset digest now includes persisted approval/activity row counts and stable row components."

patterns-established:
  - "Approval rows expose stable string approval_id values while database surrogate IDs remain internal."
  - "Approval activity rows store event_id, actor, outcome, route, support ref, occurred_at, and low-cardinality metadata only."
  - "Remaining full-suite failures are tracked as later-plan LiveView RED contracts, with regression proof excluding only approval_queue_live and approval_detail_live."

requirements-completed: [SAAS-01, SAAS-04]

duration: 7 min
completed: 2026-07-11
status: complete
---

# Phase 149 Plan 04: AdminPilot Approval Persistence Summary

**Server-authoritative AdminPilot approval persistence with append-only activity evidence and deterministic reset/digest integration.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-11T00:47:19Z
- **Completed:** 2026-07-11T00:54:43Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `saas_admin_approvals` and `saas_admin_approval_activity_events` tables for the narrow mutable evidence trail only.
- Added changeset-validated approval and activity schemas with stable public string IDs, closed vocabularies, indexes, and support-safe metadata.
- Rewrote `SaaSPortal.Approvals` into the scoped context boundary for reset, listing, retrieval, approval mutation, activity lookup, and digest components.
- Wired showcase reset to reseed persisted approval/activity rows idempotently and include persisted counts/digest truth.

## Task Commits

1. **Task 1: Create approval and activity schemas for mutable evidence only** - `2c8a586b` (feat)
2. **Task 2: Implement scoped approval context and reset integration** - `b7bd21d4` (feat)

## Files Created/Modified

- `examples/phoenix_host/priv/repo/migrations/20260710000000_create_saas_admin_approvals_and_activity_events.exs` - Creates approval/activity evidence tables, unique stable IDs, and lookup indexes.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval.ex` - Approval schema and changeset.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_activity_event.ex` - Append-only activity evidence schema and changeset.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex` - Scoped approval context, reset, mutation, activity, and digest functions.
- `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` - SaaS reset delegates persisted evidence to `Approvals.reset!/0` and digest components.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Reset count now includes persisted approval activity rows.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - Reset endpoint count assertion updated for persisted approval activity rows.
- `.planning/phases/149-saas-admin-showcase/deferred-items.md` - Remaining later-plan LiveView RED contracts narrowed to two tags.

## Decisions Made

- Kept static SaaS breadth fixture-backed. No account, team, member, role, settings, or operational-record tables were added.
- Used context-level scope normalization for `%{user, account}`, `%{current_saas_user, current_saas_account}`, and direct test scope maps.
- Used deterministic reset seed timestamps for seeded rows; approval action activity records use server time because they are real mutation evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Verification] Implemented minimal approval context during Task 1**
- **Found during:** Task 1
- **Issue:** The Task 1 verification tag `:approval_schema_persistence` exercised `Approvals.reset!/0`, `list_approvals/1`, `approve_approval/3`, and `activity_events/1`, so schema-only changes could not pass the mandatory verification gate.
- **Fix:** Added the narrow persistence context in `SaaSPortal.Approvals` with the schema commit, then used Task 2 for showcase reset/digest integration and deferred-note cleanup.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex`
- **Verification:** `cd examples/phoenix_host && mix ecto.migrate --quiet && mix test --only approval_schema_persistence test/crosswake_example/saas_portal/approvals_test.exs`
- **Committed in:** `2c8a586b`

**Total deviations:** 1 auto-fixed blocking verification issue.
**Impact on plan:** Kept the implementation narrow and within the plan's mutable approval/activity evidence scope. No native APIs, static SaaS persistence, or local-first mutation behavior were added.

## Issues Encountered

- `cd examples/phoenix_host && mix test` still fails on the two later-plan LiveView RED contracts `:approval_queue_live` and `:approval_detail_live`. These are owned by Plans 149-05/149-06 and are documented in `deferred-items.md`.

## Verification

- `cd examples/phoenix_host && mix ecto.migrate --quiet` - PASS.
- `cd examples/phoenix_host && mix test --only approval_schema_persistence test/crosswake_example/saas_portal/approvals_test.exs` - PASS.
- `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` - PASS, 7 tests.
- `cd examples/phoenix_host && mix test test/crosswake_example/e2e/showcase_reset_controller_test.exs` - PASS, 2 tests.
- `cd examples/phoenix_host && mix run -e '[acceptance probe]'` - PASS for idempotent reset counts, fresh approved read, and no sensitive metadata keys in activity rows.
- `cd examples/phoenix_host && mix test` - FAILS only on later-plan LiveView contracts `:approval_queue_live` and `:approval_detail_live`.
- `cd examples/phoenix_host && mix test --exclude approval_queue_live --exclude approval_detail_live` - PASS, 51 tests, 2 excluded.

## TDD Gate Compliance

The RED tests were created and committed in 149-01 as Wave 0 contracts. This plan reran the relevant RED contract before implementation; Task 1 then made `:approval_schema_persistence` green. Task 2's context workflow contract was already green because Task 1 had to implement the minimal context to satisfy its verification gate.

## Known Stubs

None. Stub scan found no TODO/FIXME, placeholder UI text, hardcoded empty UI feeds, or mock production data sources in files created or modified by this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `149-05-PLAN.md`. The persisted approval/activity evidence and reset truth are available for the AdminPilot shell/pages and later approval queue/detail LiveView workflow. The remaining RED contracts are intentionally UI-only and tracked for Plans 149-05/149-06.

## Self-Check: PASSED

- `149-04-SUMMARY.md` exists.
- All key created implementation files exist on disk.
- Task commits `2c8a586b` and `b7bd21d4` exist in git history.
- Focused verification passed; full-suite residual failures are limited to documented later-plan LiveView RED contracts.

---
*Phase: 149-saas-admin-showcase*
*Completed: 2026-07-11*
