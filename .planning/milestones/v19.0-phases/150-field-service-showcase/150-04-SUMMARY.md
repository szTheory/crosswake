---
phase: 150-field-service-showcase
plan: 04
subsystem: database
tags: [ecto, sqlite, evidence, reset, fieldserv]

requires:
  - phase: 150-field-service-showcase
    provides: Fieldserv fixtures/read contexts
  - phase: 150-field-service-showcase
    provides: Fieldserv route IDs and diagnostics metadata
  - phase: 149-saas-admin-showcase
    provides: narrow persistence and deterministic reset pattern
provides:
  - Narrow Fieldserv evidence event and technician job state persistence
  - Server-authoritative evidence workflow context with backend verification status transitions
  - Showcase reset/digest integration for Fieldserv persisted and static state
affects: [phase-150-field-service-showcase, fieldserv-ui, fieldserv-route-tour, showcase-reset]

tech-stack:
  added: []
  patterns:
    - Fieldserv persistence is limited to evidence events and technician job state
    - Evidence transitions use closed vocabularies, sanitized metadata, and Ecto.Multi for event/state writes

key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260711000000_create_field_service_evidence_events.exs
    - examples/phoenix_host/lib/crosswake_example/field_service/evidence_event.ex
    - examples/phoenix_host/lib/crosswake_example/field_service/technician_job_state.ex
    - examples/phoenix_host/lib/crosswake_example/field_service/evidence.ex
    - .planning/phases/150-field-service-showcase/150-04-SUMMARY.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex
    - examples/phoenix_host/lib/crosswake_example/showcase/reset.ex
    - examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs

key-decisions:
  - "Persisted Fieldserv state is intentionally narrow: append-only evidence events plus current technician job state only."
  - "Device evidence remains non-authoritative until explicit backend verification transitions mark it verified."
  - "Showcase reset now reports `field_service` counts for the product-first lane while legacy native fixtures remain separately seedable proof data."

patterns-established:
  - "Fieldserv event statuses: device_evidence_recorded, backend_verification_pending, backend_verified, backend_rejected."
  - "Fieldserv evidence context functions sanitize token/session/provider metadata before persistence."
  - "Showcase field-service digest combines static `FieldService.Fixtures` components with persisted evidence/state row components."

requirements-completed: [FIELD-01, FIELD-02, FIELD-03]

duration: 4 min
completed: 2026-07-11
status: complete
---

# Phase 150 Plan 04: Fieldserv Evidence Persistence and Reset Summary

**Server-authoritative Fieldserv evidence events, technician job state, and deterministic reset truth.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-11T17:46:42Z
- **Completed:** 2026-07-11T17:50:59Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added the `field_service_evidence_events` and `field_service_technician_job_states` tables with unique and lookup indexes.
- Added `EvidenceEvent` and `TechnicianJobState` schemas with closed event/status vocabularies and metadata sanitization.
- Added `FieldService.Evidence` with reset, digest, list, device evidence, backend pending, backend verified, and backend rejected workflow functions.
- Updated showcase reset so the Fieldserv product lane contributes deterministic static and persisted digest/count data while `browser_state_reset` remains `false`.

## Task Commits

1. **Task 1: Create narrow Fieldserv evidence schemas and migration** - `32ac12bc` (feat)
2. **Task 2: Implement evidence context and deterministic reset integration** - `b0d87292` (feat)

**Plan metadata:** recorded in the final docs/state/roadmap commit for this plan.

## Files Created/Modified

- `examples/phoenix_host/priv/repo/migrations/20260711000000_create_field_service_evidence_events.exs` - Creates the two Fieldserv evidence/state tables only.
- `examples/phoenix_host/lib/crosswake_example/field_service/evidence_event.ex` - Append-only evidence event schema and changeset.
- `examples/phoenix_host/lib/crosswake_example/field_service/technician_job_state.ex` - Narrow technician/job state schema and changeset.
- `examples/phoenix_host/lib/crosswake_example/field_service/evidence.ex` - Evidence workflow context and digest/reset helpers.
- `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex` - Fieldserv reset/digest delegation.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` - Adds product-first Fieldserv lane reset counts and digest components.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Updates expected reset counts for the Fieldserv lane.

## Decisions Made

- Did not add persisted jobs, assets, route stops, inspection templates, schedules, maps, inventory, journals, or outboxes.
- Kept evidence availability backend-authoritative: `record_device_evidence/3` records device evidence, while `mark_backend_verified/3` is the explicit availability transition.
- Kept the legacy selective-native seed proof independent from the product-first Fieldserv reset count.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `cd examples/phoenix_host && mix ecto.migrate --quiet`
  - Result: PASS. Migration ran cleanly.
- `cd examples/phoenix_host && mix ecto.migrate --quiet && mix test --warnings-as-errors test/crosswake_example/field_service/evidence_test.exs test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs`
  - Result: PASS. `6 tests, 0 failures`.
- Structural checks:
  - Migration creates only `field_service_evidence_events` and `field_service_technician_job_states`.
  - No broad Fieldserv static persistence or offline journal/outbox table was added.

## Known Stubs

None. The new persistence surface is functional and reset-backed; later UI plans will render it.

## Threat Flags

None. Metadata sanitization strips token, session, session_ref, provider_payload, and secret keys before persistence. Evidence transition functions use closed status/event vocabularies.

## User Setup Required

None - local migration was applied with `mix ecto.migrate --quiet`.

## Next Phase Readiness

Ready for `150-05-PLAN.md`. The UI plans can now render deterministic jobs plus persisted evidence/status state and use `Showcase.Reset.reset!/0` for stable route-tour setup.

## Self-Check: PASSED

- `150-04-SUMMARY.md` exists.
- All plan-owned implementation files exist on disk.
- Commits `32ac12bc` and `b0d87292` exist in git history.
- Migration and focused warnings-as-errors verification passed.

---
*Phase: 150-field-service-showcase*
*Completed: 2026-07-11*
