---
phase: 147-arc-fixture-and-showcase-foundation
plan: 05
subsystem: first-run docs and route-tour proof
tags: [docs, bash, playwright, exunit, route-policy, support-truth]

requires:
  - phase: 147-arc-fixture-and-showcase-foundation
    provides: root showcase hub, visible route-owner labels, and gated reset endpoint from plan 147-04
provides:
  - Showcase-first launcher and docs pointing newcomers at http://localhost:4700/
  - Docs-contract guards for showcase-first, proof-secondary, support-truth, and collateral-boundary wording
  - Narrow Playwright route-tour smoke for the root showcase hub before screenshot collateral
affects: [phase-148-saas, phase-149-field-service, phase-150-learning, phase-151-route-tour]

tech-stack:
  added: []
  patterns:
    - Source-derived docs scanners guard first-run copy without broad snapshots
    - Route-tour semantic assertions run before screenshots and avoid domain-lane happy paths

key-files:
  created:
    - .planning/phases/147-arc-fixture-and-showcase-foundation/147-05-SUMMARY.md
  modified:
    - bin/see-it-run.sh
    - README.md
    - guides/see_it_run.md
    - examples/QUICK_START.md
    - examples/phoenix_host/README.md
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - test/crosswake/guides/quick_start_adoption_drift_test.exs
    - test/crosswake/guides/see_it_run_test.exs

key-decisions:
  - "The first-run path now names `http://localhost:4700/` as the showcase hub; proof routes stay one click deeper."
  - "Docs say showcase screenshots explain product surface while route-tour assertions prove route-owner semantics."
  - "The route-tour hub smoke asserts only root hub semantics; Phase 151 still owns full lane happy-path coverage."

patterns-established:
  - "Docs-contract tests use separate missing_showcase_first, missing_proof_secondary, missing_support_truth, and missing_collateral_boundary categories."
  - "The Playwright route tour calls `proveShowcaseHub(page)` before any screenshot capture."
  - "Browser-owned offline reset remains isolated in `resetOfflineStudyDatabase(page)`."

requirements-completed: [SHOW-04, SHOW-01, SHOW-03]

duration: 10 min
completed: 2026-07-09
status: complete
---

# Phase 147 Plan 05: First-Run Showcase Repoint Summary

**Showcase-first first-run path with proof routes kept secondary and a narrow root hub route-tour smoke.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-09T20:10:14Z
- **Completed:** 2026-07-09T20:19:50Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Updated the launcher banner and first-run docs so `http://localhost:4700/` is the product-shaped showcase hub.
- Kept `/offline`, `/bridge-proof`, `/native/claims`, diagnostics, and E2E surfaces explicit but secondary to the showcase.
- Added docs-contract guard categories for showcase-first, proof-secondary, support-truth, and product-collateral vs route-owner-proof wording.
- Added `proveShowcaseHub(page)` to the Playwright route tour before screenshots, asserting the root heading, three lane labels, visible support labels, proof-secondary copy, and root route metadata.

## Task Commits

1. **Task 1: Update docs-contract guards for showcase-first copy** - `10e8b86e` (test, RED)
2. **Task 2: Repoint banner and docs to the showcase hub** - `03d65659` (docs, GREEN)
3. **Task 3: Add narrow route-tour showcase smoke without broadening lane proof** - `bd671c5a` (test, RED)
4. **Task 3: Add narrow route-tour showcase smoke without broadening lane proof** - `346cd3a0` (test, GREEN)

## Files Created/Modified

- `bin/see-it-run.sh` - Banner now opens the showcase hub first and lists proof routes as secondary.
- `README.md` - Public first-run section now frames `/` as the showcase and separates screenshots from route-owner proof.
- `guides/see_it_run.md` - Guided first-run flow now points at the showcase hub while keeping advisory native posture.
- `examples/QUICK_START.md` - Proof command reference now starts with the showcase pointer and support-truth boundary.
- `examples/phoenix_host/README.md` - Example-host boundary now names the showcase, support-truth labels, and collateral/proof separation.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Adds a root showcase semantic smoke before existing screenshots and route proof.
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` - Adds broad first-run docs/banner scanner coverage.
- `test/crosswake/guides/see_it_run_test.exs` - Adds guide-specific scanner coverage and anti-vacuity mutations.

## Decisions Made

- Kept the first-run copy docs-only/bannercopy-only. No route, schema, reset endpoint, or capability surface was widened.
- Kept route-tour scope deliberately narrow: root hub smoke only, no SaaS/admin, field-service, or learning/training workflow steps.
- Kept screenshot language as collateral: route-tour semantic assertions are the correctness evidence for route-owner semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed docs scanner anti-vacuity mutations**
- **Found during:** Task 2
- **Issue:** The newly added guide anti-vacuity checks missed capitalized `Support-truth` and a line-wrapped `route-tour assertions prove route-owner semantics` phrase after docs were updated.
- **Fix:** Switched those synthetic mutations to case-insensitive and whitespace-tolerant regex replacements.
- **Files modified:** `test/crosswake/guides/see_it_run_test.exs`
- **Verification:** `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/guides/see_it_run_test.exs`
- **Committed in:** `03d65659`

**2. [Rule 1 - Bug] Fixed phase-level docs guard compatibility**
- **Found during:** Orchestrator post-plan verification
- **Issue:** The root `mix test` suite still expected README's `/` home route-owner wording and the strategic planning contract required the v20 section heading `**Why now**`.
- **Fix:** Added explicit README root-route owner copy and renamed the v20 MILESTONE-ARC field from `Why next` to `Why now`.
- **Files modified:** `README.md`, `.planning/MILESTONE-ARC.md`
- **Verification:** `mix test test/crosswake/guides/readme_see_it_run_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs`
- **Committed in:** post-summary fix commit

---

**Total deviations:** 2 auto-fixed (Rule 1).
**Impact on plan:** Documentation and test-harness compatibility corrections only. No scope expansion and no production behavior change.

## Issues Encountered

- The first Task 1 RED run initially exposed a nested-list return from the new scanner. This was fixed before the RED commit, so the committed RED gate failed only on missing docs/banner copy.
- The Task 3 RED gate used a missing helper call to prove the route tour now required pre-screenshot showcase coverage; the GREEN commit implemented that helper with semantic assertions.

## Verification

- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/guides/see_it_run_test.exs`
  - Result: PASS, 18 tests, 0 failures.
- `rg "showcase|Proof routes|route-owner semantics|support-truth" bin/see-it-run.sh README.md guides/see_it_run.md examples/QUICK_START.md examples/phoenix_host/README.md`
  - Result: PASS, required terms found across launcher/docs.
- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts`
  - Result: PASS, 1 test, 0 failures.

## Known Stubs

None. Stub scan hits were limited to expected test-helper empty-string assertions and shell color/simulator variable initialization; no placeholder UI data or TODO/FIXME markers were introduced.

## Threat Flags

None. Changes affect first-run copy, docs-contract tests, and route-tour assertions only; no new endpoint, auth path, file access pattern, or schema boundary was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 148 can extend the SaaS/Admin lane from a showcase-first entrypoint that already names route ownership and support posture. Phase 151 can broaden route-tour coverage to one happy path per lane without reworking the root hub smoke or first-run docs.

## Self-Check: PASSED

- `147-05-SUMMARY.md` exists.
- All changed owned files exist on disk.
- Commits `10e8b86e`, `03d65659`, `bd671c5a`, and `346cd3a0` exist.
- Required plan verification commands passed.

---
*Phase: 147-arc-fixture-and-showcase-foundation*
*Completed: 2026-07-09*
