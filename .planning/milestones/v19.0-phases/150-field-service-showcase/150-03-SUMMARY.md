---
phase: 150-field-service-showcase
plan: 03
subsystem: routing
tags: [phoenix-router, diagnostics, route-policy, fieldserv, capability-map]

requires:
  - phase: 150-field-service-showcase
    provides: Wave 0 Fieldserv route/diagnostics contracts
  - phase: 150-field-service-showcase
    provides: deterministic Fieldserv fixtures and read contexts
  - phase: 149-saas-admin-showcase
    provides: compiled-router diagnostics pattern
provides:
  - Product-first `/fieldserv/*` route ownership metadata for jobs, job detail, inspection, native capture, and evidence review
  - Showcase catalog/hub Field Service entry repointed to `/fieldserv/jobs`
  - Compiled-router-derived Fieldserv diagnostics and capability-map pressure rows
affects: [phase-150-field-service-showcase, fieldserv-ui, route-tour-proof, phase-152-capability-map]

tech-stack:
  added: []
  patterns:
    - Fieldserv diagnostics derive raw route facts from `Phoenix.Router.routes/1` plus `Crosswake.Policy.RouterMetadata.fetch/1`
    - Native capture metadata mirrors the existing native-screen camera/media/upload transfer contract without adding camera or scanner bridge commands

key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex
    - .planning/phases/150-field-service-showcase/150-03-SUMMARY.md
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex
    - examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex
    - examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs

key-decisions:
  - "Moved the Field Service showcase primary path to `/fieldserv/jobs`; legacy `/native/claims` routes remain reachable as secondary proof routes."
  - "Declared capture as a native-screen route with camera capability, media pack, native-capture upload transfer, cached read-only posture, and sensitive security."
  - "Kept diagnostics lane-local and route-derived; no URL-addressable inspector route or crosswake_dashboard surface was added."

patterns-established:
  - "Fieldserv route IDs: fieldserv-jobs, fieldserv-job, fieldserv-inspection, fieldserv-job-capture, fieldserv-evidence-review."
  - "Fieldserv diagnostics expose packs, transfers, support labels, rough edges, guide links, and capability-map rows."
  - "Capability-map rows classify capture, scanner, document scan, permissions, media upload, offline inspection, and native rebuild as pressure/future-gap evidence, not shipped support."

requirements-completed: [FIELD-02, FIELD-04]

duration: 4 min
completed: 2026-07-11
status: complete
---

# Phase 150 Plan 03: Fieldserv Route Ownership and Diagnostics Summary

**Product-first `/fieldserv/*` route metadata plus route-derived diagnostics and capability-pressure evidence.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-11T17:41:31Z
- **Completed:** 2026-07-11T17:45:07Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a `/fieldserv` router scope for jobs, job detail, inspection, native capture handoff, and evidence review.
- Repointed the Field Service catalog/hub card from the legacy native proof route to `/fieldserv/jobs` while keeping `/native/claims` available in the secondary proof strip.
- Added `CrosswakeExample.FieldService.Diagnostics` with route-derived rows, support labels, guide links, rough-edge copy, native capture metadata, and Phase 152 capability-map pressure rows.

## Task Commits

1. **Task 1: Add product-first Fieldserv routes and repoint showcase entry** - `e2a7ca21` (feat)
2. **Task 2: Implement compiled-router Fieldserv diagnostics and capability evidence rows** - `4d9dff0c` (feat)

**Plan metadata:** recorded in the final docs/state/roadmap commit for this plan.

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/router.ex` - Added `/fieldserv/*` route metadata and narrow no-warning forward references for later Fieldserv LiveViews.
- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - Repointed Field Service card to `/fieldserv/jobs` and updated visible route posture/capability copy.
- `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` - Removed the special-case redirect to `/native/claims`.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` - Updated the primary Fieldserv path expectation to `/fieldserv/jobs`.
- `examples/phoenix_host/lib/crosswake_example/field_service/diagnostics.ex` - Added route diagnostics and capability-pressure rows.

## Decisions Made

- Preserved `/native/claims` as a proof route rather than deleting or hiding it completely.
- Added `@compile {:no_warn_undefined, ...}` entries for the five planned Fieldserv LiveViews so router metadata can compile cleanly with `--warnings-as-errors` before Plans 150-05 and 150-06 define those modules.
- Kept support labels allowlisted and avoided “supported” wording for future scanner/document-scan/permission/offline pressure.

## Deviations from Plan

### Test Expectation Update

The existing hub test asserted the old Field Service card path `/native/claims/:id/capture`. Repointing the product-first lane required updating that expectation to `/fieldserv/jobs`; the secondary proof-route assertion for `/native/claims` remains in place.

**Total deviations:** 1 small test-alignment update.
**Impact on plan:** Required to keep tests aligned with D-01/D-03. No production scope expansion.

## Issues Encountered

- Initial compile emitted warnings for the planned but not-yet-built Fieldserv LiveViews. Added narrow router `no_warn_undefined` entries for those five modules so intermediate warnings-as-errors verification stays clean.

## Verification

- `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs`
  - Result: PASS. `11 tests, 0 failures`.
- `cd examples/phoenix_host && mix test --only fieldserv_diagnostics_route_rows test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs`
  - Result: PASS. Fieldserv route row contract passes with other tests excluded.
- Structural checks:
  - Fieldserv route IDs, native-screen capture metadata, camera capability, native-capture transfer source, and required verification are present in `router.ex`.
  - Field Service catalog primary path/route ID/CTA point to `/fieldserv/jobs`.
  - No camera bridge, scanner bridge, document-scan bridge, camera/scanner permission alias expansion, or location support was added.

## Known Stubs

None. The route references point to planned LiveViews implemented in later plans and are explicitly tracked by Wave 0 contracts. No placeholder LiveView module or fake device implementation was added.

## Threat Flags

None. Diagnostics expose route policy, support posture, guide paths, and short rough-edge text only; they do not expose payloads, session data, provider data, tokens, or a new inspector route.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `150-04-PLAN.md`. Fieldserv persistence can now use the route IDs and diagnostics rows added here, and later UI plans can render route/support truth from `FieldService.Diagnostics`.

## Self-Check: PASSED

- `150-03-SUMMARY.md` exists.
- All plan-owned files exist on disk.
- Commits `e2a7ca21` and `4d9dff0c` exist in git history.
- Focused warnings-as-errors verification passed.

---
*Phase: 150-field-service-showcase*
*Completed: 2026-07-11*
