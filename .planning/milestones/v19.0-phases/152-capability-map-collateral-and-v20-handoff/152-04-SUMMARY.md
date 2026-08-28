---
phase: 152-capability-map-collateral-and-v20-handoff
plan: 04
subsystem: docs-handoff
tags: [readme, capability-map, v20-handoff, support-truth, final-proof]
requires:
  - phase: 152-capability-map-collateral-and-v20-handoff
    provides: 152-02 typed capability map and generated guide
  - phase: 152-capability-map-collateral-and-v20-handoff
    provides: 152-03 generalized route-tour evidence and CI proof
provides:
  - Public README capability-map entry point
  - Example-host README capability-map entry point
  - Planning-only v20 Native Controls Pack 1 handoff
  - Final Phase 152 support-truth and route-tour proof verification
affects: [public-docs, v20-planning, capability-map, support-truth]
tech-stack:
  added: []
  patterns: [light-doc-entrypoint, planning-only-handoff, support-truth-closeout]
key-files:
  created:
    - .planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md
  modified:
    - README.md
    - examples/phoenix_host/README.md
key-decisions:
  - "README entry points link to the generated capability map instead of duplicating the full support table."
  - "The v20 handoff is planning-only and names Pack 1 candidates, exclusions, later packs, promotion criteria, and support-truth constraints."
  - "Pack 1 stays bounded to low-frequency route-local controls; capture/device, commerce, offline sync/native storage, and dashboard work are deferred."
patterns-established:
  - "Public capability-map links use the exact `Read Capability Map` CTA and keep screenshots as collateral after route-tour assertions."
  - "v20 planning starts from v19 evidence sources and explicit exclusions rather than broad native capability promises."
requirements-completed:
  - CAPMAP-04
  - PROOF-03
  - PROOF-04
duration: 10 min
completed: 2026-07-12
status: complete
---

# Phase 152 Plan 04: Public Entry Points and v20 Handoff Summary

**Phase 152 is complete: capability truth is public, evidence-backed, and ready for v20 planning.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-07-12
- **Tasks:** 3
- **Files modified:** 3 plus planning closeout metadata

## Accomplishments

- Added concise `Read Capability Map` entry points to the root README and example-host README.
- Created `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` with Pack 1 candidates, explicit exclusions, named later packs, promotion criteria, evidence sources, support-truth constraints, and v20 planning questions.
- Verified the public claim scanner accepts the new README copy.
- Ran the final Phase 152 closeout checks across capability map tests, renderer parity, public claim scanner, evidence manifest schema, collateral table guard, reset proof, and route-tour/LearnLoop Playwright proof.

## Task Commits

Each implementation task was committed atomically:

1. **Task 1: Add public capability-map entry points** - `017af46f` (docs)
2. **Task 2: Add the v20 Native Controls Pack 1 handoff** - `0fee76cb` (docs)

**Task 3 and plan metadata:** committed with this summary.

## Files Created/Modified

- `README.md` - light capability-map entry point near first-run support-truth copy.
- `examples/phoenix_host/README.md` - example-host capability-map entry point and boundary copy.
- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` - planning-only v20 Native Controls Pack 1 handoff.

## Decisions Made

- Kept README changes as links plus short boundary copy; the generated `guides/capability_map.md` remains the canonical public capability map.
- Scoped v20 Pack 1 to alert/confirm, menu/action-button affordances, haptics, share, toast/review prompt, plus read-only `permissions.status` and `notification_token` evidence surfaces.
- Deferred camera, scanner, document scan, media upload, native storage, reusable sync helpers, commerce provider integration, notification delivery assurance, operator dashboard, and plugin catalog work.

## Deviations from Plan

None.

---

**Total deviations:** 0.
**Impact on plan:** The plan stayed within docs and planning scope; no native-control APIs, commerce providers, storage/sync productization, schemas, dashboards, or plugin catalogs were introduced.

## Issues Encountered

None.

## Verification

- `mix test test/crosswake/guides/capability_claims_test.exs` - passed, 5 tests.
- `test -s .planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` - passed.
- `mix test test/crosswake/capability_map test/crosswake/guides/capability_claims_test.exs test/crosswake/guides/evidence_manifest_test.exs test/crosswake/guides/collateral_table_test.exs` - passed, 29 tests.
- `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/showcase/reset_test.exs` - passed, 4 tests.
- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts` - passed, 4 tests.
- `git diff --check` - passed.

## User Setup Required

None.

## Phase 152 Closeout

Phase 152 completed all 4 plans. CAPMAP-01 through CAPMAP-04 and PROOF-01 through PROOF-04 are complete. v19.0 is ready for milestone audit/closeout.

---
*Phase: 152-capability-map-collateral-and-v20-handoff*
*Completed: 2026-07-12*
