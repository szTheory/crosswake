---
phase: 150-field-service-showcase
plan: 02
subsystem: fixtures
tags: [elixir, fixtures, read-context, fieldserv, offline-honesty]

requires:
  - phase: 150-field-service-showcase
    provides: Wave 0 Fieldserv fixture and read-context contracts
  - phase: 149-saas-admin-showcase
    provides: deterministic fixture/read-context pattern for showcase lanes
provides:
  - Deterministic Fieldserv fixture breadth for jobs, assets, technicians, inspection templates, notes, evidence, route posture, support findings, and permission pressure
  - Read-only Fieldserv job, inspection, evidence, and route posture context helpers
  - Cached read-only and future offline-island requirement copy without runnable local mutation behavior
affects: [phase-150-field-service-showcase, fieldserv-ui, fieldserv-reset, fieldserv-evidence]

tech-stack:
  added: []
  patterns:
    - Static Fieldserv breadth remains deterministic fixture maps, not broad Ecto persistence
    - Read contexts return product-ready maps for LiveViews while preserving cached read-only/offline honesty

key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex
    - examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex
    - .planning/phases/150-field-service-showcase/150-02-SUMMARY.md
  modified: []

key-decisions:
  - "Kept Fieldserv jobs/assets/templates/static breadth as fixture/read-context data; persisted evidence remains Plan 150-04 scope."
  - "Encoded future offline inspection as requirements text, not a runnable offline island or local mutation workflow."
  - "Used Fieldserv product language first while keeping route/support posture available for later diagnostics and UI badges."

patterns-established:
  - "Fieldserv digest components are lane-scoped with `field_service.` prefixes and include stable IDs, titles, statuses, route posture, and pressure rows."
  - "Jobs context exposes `list_jobs/0`, `get_job!/1`, `job_summary!/1`, `inspection_context!/1`, `evidence_context!/1`, and `route_posture!/1` over fixtures only."
  - "Inspection context names local draft storage, journal/outbox, replay outcomes, conflict review, and reconciliation proof as future requirements."

requirements-completed: [FIELD-01, FIELD-03]

duration: 4 min
completed: 2026-07-11
status: complete
---

# Phase 150 Plan 02: Fieldserv Fixtures and Read Contexts Summary

**Deterministic Fieldserv jobs, assets, technicians, inspection, evidence, and cached-read-only context data.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-11T17:36:22Z
- **Completed:** 2026-07-11T17:40:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `CrosswakeExample.FieldService.Fixtures` with three jobs, three assets, three technicians, dispatcher/adjuster personas, inspection checklist data, notes, evidence items across the backend authority ladder, route postures, support findings, and seven permission/capability-pressure rows.
- Added `CrosswakeExample.FieldService.Jobs` as a read-only context for job queue/detail, inspection, evidence, and route posture data.
- Preserved offline honesty: Fieldserv inspection is a future offline-island candidate with explicit required infrastructure, while current route data remains cached read-only.

## Task Commits

1. **Task 1: Create deterministic Fieldserv fixture breadth** - `76b06082` (feat)
2. **Task 2: Add read-only Fieldserv job and inspection context helpers** - `c483ed5b` (feat)

**Plan metadata:** recorded in the final docs/state/roadmap commit for this plan.

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/field_service/fixtures.ex` - Deterministic Fieldserv domain records, route posture rows, pressure rows, and digest components.
- `examples/phoenix_host/lib/crosswake_example/field_service/jobs.ex` - Fixture-backed read helpers for jobs, inspection, evidence, and route posture.

## Decisions Made

- Left mutable evidence persistence to Plan 150-04, matching the Phase 149 hybrid pattern.
- Kept scanner, document scan, media upload, permission, offline inspection, and native rebuild entries as pressure/future-gap data, not available support.
- Used stable route-tour IDs (`job-1`, `asset-windshield-1`, `tech-rivera`, `evidence-1`) for downstream LiveView and Playwright proofs.

## Deviations from Plan

### Verification Scope Adjustment

The plan's task-level command includes `components_test.exs`, but `FieldService.Components` and Fieldserv CSS are explicitly Plan 150-05 artifacts. I ran that broader command and confirmed the only failures are the expected later component/CSS contract gaps. The plan-owned fixture and jobs contracts pass.

**Total deviations:** 1 documented scope adjustment.
**Impact on plan:** No implementation scope creep; the remaining component/CSS RED contracts stay with Plan 150-05.

## Issues Encountered

- An initial attempt ran two Mix test commands concurrently, causing one test process to hit the existing endpoint/build lock. Rerunning the fixture/jobs command by itself passed.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/field_service/jobs_test.exs`
  - Result: PASS. `2 tests, 0 failures`.
- `cd examples/phoenix_host && mix test test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/field_service/jobs_test.exs test/crosswake_example/field_service/components_test.exs`
  - Result: EXPECTED RED for later Plan 150-05 component/CSS artifacts only. Fixture and jobs tests pass; failures are missing `CrosswakeExample.FieldService.Components` and `.fieldserv-*` CSS selectors.

## Known Stubs

None. The new modules are production fixture/read-context code for the showcase lane; no placeholder module, random data source, broad schema, device API, or offline mutation path was added.

## Threat Flags

None. Fixture data is fictional and avoids tokens, session references, provider payloads, real addresses, or real customer data. Route posture rows remain supplementary until Plan 150-03 derives authoritative route truth from compiled router metadata.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `150-03-PLAN.md`. Diagnostics can now enrich compiled Fieldserv route metadata with stable fixture-backed route/support posture and capability-pressure evidence.

## Self-Check: PASSED

- `150-02-SUMMARY.md` exists.
- Both plan-owned implementation files exist on disk.
- Commits `76b06082` and `c483ed5b` exist in git history.
- Plan-owned fixture/jobs verification passed.

---
*Phase: 150-field-service-showcase*
*Completed: 2026-07-11*
