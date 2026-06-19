---
phase: 117-route-policy-and-support-truth-guide-foundation
plan: "03"
subsystem: docs
tags: [support-truth, guide-navigation, exdoc, docs-contract]
requires:
  - phase: 117-route-policy-and-support-truth-guide-foundation
    provides: route-policy and web-to-mobile migration guides from plans 01 and 02
provides:
  - Renderer-owned support-truth label legend
  - README/install/user-flow navigation into route-owner and migration guides
  - ExDoc Start/Adopt/Runtime Owners/Truth/Advanced guide grouping
  - TRUTH-01 docs-contract assertions for guide navigation and support-label vocabulary
affects: [phase-118-quick-start, phase-119-native-evidence, phase-120-collateral]
tech-stack:
  added: []
  patterns:
    - Canonical support-truth labels are generated from the support matrix renderer.
    - Public guide navigation is tested through README, guide files, and ExDoc config.
key-files:
  created: []
  modified:
    - README.md
    - mix.exs
    - guides/install.md
    - guides/user_flows.md
    - guides/web_to_mobile_migration.md
    - guides/support_matrix.md
    - lib/crosswake/support_matrix/renderer.ex
    - test/crosswake/support_matrix/renderer_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
key-decisions:
  - "Kept `guides/support_matrix.md` as the canonical support-truth source and linked the README to its legend instead of creating a second support-truth guide."
  - "Added support labels without classifying checked-in native host evidence; Phase 119 still owns local-dev versus generated public-coordinate classification."
  - "Kept quick-start/adoption command guards and collateral checks out of Phase 117."
patterns-established:
  - "Support labels state both what they prove and what they do not prove."
  - "ExDoc extras now group public guides by reader flow: Start, Adopt, Runtime Owners, Truth, and Advanced/Companions."
requirements-completed: [TRUTH-01, GUIDE-01, MIGRATE-01]
duration: 10 min
completed: 2026-06-19
status: complete
---

# Phase 117 Plan 03: Support-Truth Guide Wiring Summary

**Support-truth labels and public guide navigation now make the route-owner docs first-class**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-19T14:27:02Z
- **Completed:** 2026-06-19T14:34:37Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added a renderer-owned `Support-Truth Label Legend` to `guides/support_matrix.md`.
- Defined merge-blocking proof, advisory evidence, local-dev proof, generated public-coordinate proof, JVM hermetic proof, emulator evidence, device evidence, verification-required, and rebuild-required.
- Added non-overclaim assertions for device verification, backend/session authority, cached read-only, offline mutation, bridge authority, local-dev proof, generated public-coordinate proof, and visual collateral.
- Wired README, install, and user-flow docs to `guides/route_policy.md` and `guides/web_to_mobile_migration.md`.
- Added compact README support-label vocabulary linked back to the support matrix legend.
- Added ExDoc extras and groups for Start, Adopt, Runtime Owners, Truth, and Advanced/Companions while keeping README as the main page.
- Added release-boundary tests that fail on missing ExDoc extra files, missing guide links, missing support-label vocabulary, or incorrect guide group order.

## Task Commits

1. **Task 1: Add renderer-owned support-truth legend and repair matrix parity** - `917db7e` (`docs`)
2. **Task 2: Wire README, install/user-flow maps, ExDoc grouping, and guide assertions** - `d56d77f` (`docs`)

## Files Created/Modified

- `lib/crosswake/support_matrix/renderer.ex` - Adds the generated support-truth legend.
- `guides/support_matrix.md` - Regenerated from the renderer with the support-truth legend.
- `test/crosswake/support_matrix/renderer_test.exs` - Pins support-label rendering.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Pins support-label non-overclaim truth.
- `README.md` - Adds route-owner framing, new guide links, and compact support-label vocabulary.
- `mix.exs` - Adds new guides to ExDoc extras and reorganizes guide groups.
- `guides/install.md` - Links route-policy and migration guides.
- `guides/user_flows.md` - Links the migration guide after the route-policy guide.
- `guides/web_to_mobile_migration.md` - Keeps Phase 118 quick-start mention as plain path text to avoid linking a file that does not exist yet.
- `test/crosswake/guides/release_boundaries_test.exs` - Adds public guide navigation and ExDoc assertions.

## Verification

- `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` - passed, 66 tests, 0 failures.
- `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/user_flows_test.exs test/crosswake/guides/route_policy_test.exs test/crosswake/guides/web_to_mobile_migration_test.exs` - passed, 19 tests, 0 failures.
- `mix docs` - passed. Existing hidden/private module reference warnings remain; the new migration guide no longer emits a missing `examples/QUICK_START.md` file warning.

## Decisions Made

- Used README plus support-matrix legend for first-read support truth instead of a new `guides/support_truth.md` source.
- Preserved Phase 118 scope by mentioning `examples/QUICK_START.md` as plain future path text instead of linking it as a current docs extra.
- Preserved Phase 119 scope by naming support labels without deciding checked-in native host evidence class.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix docs` surfaced a missing-file warning for the future Phase 118 `examples/QUICK_START.md` link. The guide now keeps that as path text until Phase 118 creates or rewrites the quick-start surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 118 can now use `guides/route_policy.md`, `guides/web_to_mobile_migration.md`, and the support-truth legend as the stable entry-point vocabulary for the command-verified quick start and adoption rewrite.

---
*Phase: 117-route-policy-and-support-truth-guide-foundation*
*Completed: 2026-06-19*
