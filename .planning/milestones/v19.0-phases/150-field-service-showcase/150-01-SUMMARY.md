---
phase: 150-field-service-showcase
plan: 01
subsystem: testing
tags: [exunit, playwright, tdd-red, route-tour, fieldserv, capability-map]

requires:
  - phase: 147-arc-fixture-and-showcase-foundation
    provides: showcase reset endpoint, route-tour semantic proof pattern, and route-owner label vocabulary
  - phase: 148-demo-app-brand-fixture-direction
    provides: Fieldserv product identity and fixture-density brief
  - phase: 149-saas-admin-showcase
    provides: deterministic lane fixture, diagnostics, persistence, and route-tour implementation patterns
provides:
  - Wave 0 RED ExUnit contracts for Fieldserv fixture density, read contexts, evidence authority, diagnostics, and components
  - RED LiveView contracts for the jobs -> detail -> inspection -> native capture -> evidence review click path
  - RED Playwright route-tour and evidence-manifest contracts for Fieldserv capability pressure
affects: [phase-150-field-service-showcase, phase-152-capability-map, route-tour-proof]

tech-stack:
  added: []
  patterns:
    - RED contracts use Code.ensure_loaded?/1 and function_exported?/3 to fail on behavior gaps, not setup errors
    - Fieldserv route-tour screenshots remain collateral after route-owner, support-label, backend-verification, and no-overclaim assertions

key-files:
  created:
    - examples/phoenix_host/test/crosswake_example/field_service/fixtures_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/jobs_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/evidence_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/diagnostics_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/components_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/jobs_live_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/job_live_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/inspection_live_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/capture_live_test.exs
    - examples/phoenix_host/test/crosswake_example/field_service/evidence_review_live_test.exs
    - .planning/phases/150-field-service-showcase/150-01-SUMMARY.md
  modified:
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - examples/phoenix_host/e2e/support/evidence_manifest.ts

key-decisions:
  - "Kept Plan 150-01 intentionally RED-only because Wave 0 defines the Fieldserv acceptance boundary and later Phase 150 plans implement it."
  - "Fieldserv route-tour proof is semantic-first: route IDs, native capture metadata, cached read-only posture, backend verification, diagnostics, and no-overclaiming assertions run before screenshots."
  - "Capability-map entries classify capture, scanner, document scan, permissions, media upload, offline inspection, and native rebuild as pressure/future-gap evidence, not shipped native support."

patterns-established:
  - "Task-scoped ExUnit tags: fieldserv_fixture_density, fieldserv_jobs_context, fieldserv_evidence_state, fieldserv_diagnostics_route_rows, fieldserv_diagnostics_enrichment, fieldserv_component_contract."
  - "Fieldserv browser helper uses /_e2e/showcase-reset and walks /fieldserv/jobs through job detail, inspection, capture handoff, and evidence review."
  - "Mobile reduced-motion route tour now re-runs the Fieldserv path with screenshot capture disabled and no-overflow verification."

requirements-completed: [FIELD-01, FIELD-02, FIELD-03, FIELD-04]

duration: 13 min
completed: 2026-07-11
status: complete
---

# Phase 150 Plan 01: Fieldserv Wave 0 Contracts Summary

**Executable RED contracts for realistic Fieldserv data, route ownership, native capture pressure, backend evidence authority, and offline honesty.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-11T17:20:50Z
- **Completed:** 2026-07-11T17:33:55Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Added five ExUnit contract files covering Fieldserv fixture breadth, read helpers, evidence-state authority, diagnostics, and component/CSS requirements.
- Added five LiveView contract files for the planned jobs list, job detail, inspection workspace, native capture handoff, and evidence review route.
- Extended route-tour proof and evidence-manifest metadata so Fieldserv browser evidence must prove support truth before screenshots and feed Phase 152 capability mapping.
- Preserved the Phase 150 boundary: tests are RED contracts only; no production Fieldserv modules, routes, schemas, camera/scanner APIs, permission dashboard, or offline mutation engine were added.

## Task Commits

1. **Task 1: Create RED ExUnit contracts for Fieldserv data, context, evidence, diagnostics, and components** - `f07daffa` (test)
2. **Task 2: Create RED LiveView contracts for the Fieldserv click path** - `a455ee57` (test)
3. **Task 3: Add RED Fieldserv route-tour and evidence-manifest expectations** - `d3b37d05` (test)

**Plan metadata:** recorded in the final docs/state/roadmap commit for this plan.

## Files Created/Modified

- `examples/phoenix_host/test/crosswake_example/field_service/fixtures_test.exs` - Fixture density, route posture, support findings, permission pressure, and deterministic digest contract.
- `examples/phoenix_host/test/crosswake_example/field_service/jobs_test.exs` - Fieldserv read-context contract for job list, lookup, summary, inspection, evidence, and route posture.
- `examples/phoenix_host/test/crosswake_example/field_service/evidence_test.exs` - Evidence status ladder, Ecto.Multi, metadata sanitization, backend authority, and reset digest contract.
- `examples/phoenix_host/test/crosswake_example/field_service/diagnostics_test.exs` - Compiled router metadata, support labels, guide links, and capability-map row contract.
- `examples/phoenix_host/test/crosswake_example/field_service/components_test.exs` - Lane-local component and CSS contract for Fieldserv classes, focus, action targets, reduced motion, and text labels.
- `examples/phoenix_host/test/crosswake_example/field_service/jobs_live_test.exs` - Jobs queue LiveView contract.
- `examples/phoenix_host/test/crosswake_example/field_service/job_live_test.exs` - Job detail LiveView contract.
- `examples/phoenix_host/test/crosswake_example/field_service/inspection_live_test.exs` - Inspection workspace LiveView contract.
- `examples/phoenix_host/test/crosswake_example/field_service/capture_live_test.exs` - Native capture handoff LiveView contract.
- `examples/phoenix_host/test/crosswake_example/field_service/evidence_review_live_test.exs` - Evidence review LiveView contract.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Fieldserv route-tour helper, desktop/mobile coverage, and semantic assertions.
- `examples/phoenix_host/e2e/support/evidence_manifest.ts` - Fieldserv route artifacts and capability-pressure manifest entries.

## Decisions Made

- Followed the plan's Wave 0 contract shape instead of implementing production code in this plan.
- Kept native capture explicit as `runtime: :native_screen` with camera capability and native-capture upload transfer metadata; scanner/document scan/permissions remain visible future pressure only.
- Required cached read-only/degraded wording and negative assertions against shipped local mutation copy.
- Kept FIELD-01..04 pending in `REQUIREMENTS.md`; this plan covers those requirements with executable RED contracts but does not complete the user-facing lane.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Verification

- `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/field_service/jobs_test.exs test/crosswake_example/field_service/evidence_test.exs test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/field_service/components_test.exs --trace > /tmp/phase150-wave0-exunit-red.log 2>&1; status=$?; test "$status" -ne 0 && rg "Fieldserv fixture density contract" /tmp/phase150-wave0-exunit-red.log && rg "Fieldserv jobs context contract" /tmp/phase150-wave0-exunit-red.log && rg "Fieldserv evidence state contract" /tmp/phase150-wave0-exunit-red.log && rg "Fieldserv diagnostics route rows contract" /tmp/phase150-wave0-exunit-red.log && rg "Fieldserv component contract" /tmp/phase150-wave0-exunit-red.log && ! rg "SyntaxError|CompileError|UndefinedFunctionError|FunctionClauseError|MatchError|RuntimeError|KeyError|Protocol\\.UndefinedError|CaseClauseError|WithClauseError|BadMapError|BadBooleanError|BadArityError|cannot compile" /tmp/phase150-wave0-exunit-red.log'`
  - Result: PASS. The command failed as expected for RED behavior gaps and the log contained the required contract names with no forbidden setup/runtime failure patterns.
- `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start test/crosswake_example/field_service/jobs_live_test.exs test/crosswake_example/field_service/job_live_test.exs test/crosswake_example/field_service/inspection_live_test.exs test/crosswake_example/field_service/capture_live_test.exs test/crosswake_example/field_service/evidence_review_live_test.exs --trace > /tmp/phase150-wave0-live-red.log 2>&1; status=$?; test "$status" -ne 0 && rg "Fieldserv jobs LiveView contract" /tmp/phase150-wave0-live-red.log && rg "Fieldserv job detail LiveView contract" /tmp/phase150-wave0-live-red.log && rg "Fieldserv inspection LiveView contract" /tmp/phase150-wave0-live-red.log && rg "Fieldserv capture LiveView contract" /tmp/phase150-wave0-live-red.log && rg "Fieldserv evidence review LiveView contract" /tmp/phase150-wave0-live-red.log && ! rg "SyntaxError|CompileError|UndefinedFunctionError|FunctionClauseError|MatchError|RuntimeError|KeyError|Protocol\\.UndefinedError|CaseClauseError|WithClauseError|BadMapError|BadBooleanError|BadArityError|cannot compile" /tmp/phase150-wave0-live-red.log'`
  - Result: PASS. The command failed as expected for missing Fieldserv LiveViews/routes and the log contained the required RED contract names with no forbidden setup/runtime failure patterns.
- `cd examples/phoenix_host && rg "proveFieldservRoute|/fieldserv/jobs|fieldserv-job-capture|runtime: :native_screen|Backend verification pending" e2e/route_tour.spec.ts && rg "fieldserv" e2e/support/evidence_manifest.ts`
  - Result: PASS. Required Fieldserv route-tour and manifest contract strings are present.
- `cd examples/phoenix_host && npx playwright test --list e2e/route_tour.spec.ts`
  - Result: PASS. Playwright can parse and list the modified route-tour spec.

## TDD Gate Compliance

This plan is intentionally RED-only. It creates Wave 0 executable contracts for later Phase 150 implementation plans and explicitly forbids production Fieldserv modules in Tasks 1 and 2. No GREEN commit is present by design; Plans 150-02 through 150-07 are expected to satisfy these contracts.

## Known Stubs

None. The new files are tests and route-tour contracts; no production placeholder module, fixture source, schema, route, or UI stub was added.

## Threat Flags

None. The plan added test expectations and manifest metadata only. It does not add a new endpoint, auth path, schema, native capability, scanner bridge, permission dashboard, media upload implementation, or offline mutation path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `150-02-PLAN.md` and `150-03-PLAN.md`. Later implementation plans can use the task-scoped tags and route-tour helper to make the Fieldserv contracts green without reinterpreting the Phase 150 route ownership, native capture, backend verification, or offline-honesty boundaries.

## Self-Check: PASSED

- `150-01-SUMMARY.md` exists.
- All twelve plan-owned files exist on disk.
- Commits `f07daffa`, `a455ee57`, and `d3b37d05` exist in git history.
- Required plan verification commands passed.

---
*Phase: 150-field-service-showcase*
*Completed: 2026-07-11*
