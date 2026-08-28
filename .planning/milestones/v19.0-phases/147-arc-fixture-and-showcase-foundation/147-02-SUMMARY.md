---
phase: 147-arc-fixture-and-showcase-foundation
plan: 02
subsystem: showcase
tags: [phoenix, exunit, route-policy, support-truth, catalog]

requires:
  - phase: 147-arc-fixture-and-showcase-foundation
    provides: v19 showcase decisions D-03, D-13, D-14, D-15, D-16, D-17, D-18
provides:
  - Curated showcase lane catalog for SaaS/admin, field-service, and learning/training cards
  - ExUnit drift tests comparing catalog route posture to compiled Crosswake router metadata
  - Allowlisted visible support-label vocabulary for hub rendering
affects: [phase-147-hub, phase-148-saas, phase-149-field-service, phase-150-learning, phase-151-capability-map]

tech-stack:
  added: []
  patterns:
    - Static product-facing catalog with compiled route metadata tests as authority
    - Support labels are allowlisted visible text, not color-only or broad support claims

key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex
    - examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs
  modified: []

key-decisions:
  - "Field-service foundation card anchors to the existing selective-native capture route so native pressure remains route-policy-backed."
  - "The catalog stores only a small route_posture snapshot for tests; the compiled router remains the source of truth."

patterns-established:
  - "Catalog cards expose primary route id/path, visible runtime labels, allowed support labels, capability chips, CTA copy, boundary notes, and v20 pressure notes."
  - "Catalog tests use Phoenix.Router.routes/1 plus Crosswake.Policy.RouterMetadata.fetch/1 instead of parsing router source."

requirements-completed: [SHOW-01, SHOW-03]

duration: 5 min
completed: 2026-07-09
status: complete
---

# Phase 147 Plan 02: Showcase Catalog Summary

**Route-policy-backed showcase catalog with visible support labels for the three v19 lanes.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-09T19:46:24Z
- **Completed:** 2026-07-09T19:51:16Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `CrosswakeExample.Showcase.Catalog` with stable SaaS/admin, field-service, and learning/training lane records.
- Added route metadata drift tests that verify catalog route IDs, paths, runtime, offline, security, and capabilities against compiled router metadata.
- Enforced the allowed support-label vocabulary: Available today, Proof-backed example, Demo pressure, Advisory evidence, Future gap, Next-pack candidate.

## Task Commits

1. **Task 1: Write catalog metadata tests before the catalog implementation** - `d53cf6f4` (test)
2. **Task 2: Implement the small product-facing showcase catalog** - `64ef6273` (feat)

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` - Curated lane-card catalog, support label vocabulary, route IDs, CTA copy, capability chips, boundary notes, and v20 pressure notes.
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` - ExUnit proof that catalog entries stay aligned with compiled route metadata and allowlisted labels.

## Decisions Made

- Field-service uses `selective-native-claim-capture` as the route-backed native-pressure anchor, keeping capture/scanning copy honest as demo pressure and next-pack evidence.
- The catalog includes a small `route_posture` map only for testable runtime/offline/security/capability expectations; it does not duplicate the full route-policy DSL.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs`
- Result: PASS, 4 tests, 0 failures.

## Deviations from Plan

None - plan executed exactly as written. Shared `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` updates were intentionally skipped per Wave 1 orchestration instructions.

## Issues Encountered

- Concurrent Plan 147-03 work appeared in `examples/phoenix_host/lib/crosswake_example/showcase/fixtures.ex`, `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex`, `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs`, `examples/phoenix_host/lib/crosswake_example/flashcards.ex`, and `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex`. These files were outside Plan 147-02 ownership and were not staged or modified by this plan.

## Known Stubs

None. The stub scan hit only `label != ""` in the test assertion that enforces non-empty visible labels.

## Threat Flags

None. No new endpoint, auth path, file-access path, or schema boundary was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The catalog is ready for the root hub renderer in Plan 147-04. Fixture/reset work can consume the same lane identifiers without widening support claims.

## Self-Check: PASSED

- `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` exists.
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` exists.
- Commit `d53cf6f4` exists.
- Commit `64ef6273` exists.

---
*Phase: 147-arc-fixture-and-showcase-foundation*
*Completed: 2026-07-09*
