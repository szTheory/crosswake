---
phase: 117-route-policy-and-support-truth-guide-foundation
plan: "02"
subsystem: docs
tags: [migration, phoenix-saas, route-inventory, docs-contract]
requires:
  - phase: 117-route-policy-and-support-truth-guide-foundation
    provides: route-policy owner guide from plan 01
provides:
  - Web-to-mobile migration guide for existing Phoenix SaaS teams
  - MIGRATE-01 docs-contract test for LiveView default and promotion reasons
affects: [phase-118-quick-start, phase-119-native-evidence, phase-120-collateral]
tech-stack:
  added: []
  patterns:
    - Migration docs start from route inventory and promote only for explicit owner reasons.
    - Later-phase hands-on and native evidence surfaces are linked with scope labels instead of rewritten.
key-files:
  created:
    - guides/web_to_mobile_migration.md
    - test/crosswake/guides/web_to_mobile_migration_test.exs
  modified: []
key-decisions:
  - "Framed migration as an operational Phoenix SaaS route inventory, not a generic mobile rewrite."
  - "Kept quick-start command verification, adoption offline rewrite, native host classification, and collateral capture out of Phase 117."
patterns-established:
  - "Migration pass order: inventory routes, assign initial owner, add required seams, run doctor/support checks, capture evidence for used owner classes."
  - "Promotion reasons remain explicit: bounded native affordance, cached read-only, local mutation/replay, native-owned device session, backend/provider authority, or defer."
requirements-completed: [MIGRATE-01]
duration: 3 min
completed: 2026-06-19
status: complete
---

# Phase 117 Plan 02: Web-To-Mobile Migration Guide Summary

**Phoenix SaaS route-inventory guide defaults to LiveView and promotes only for explicit owner reasons**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-19T14:24:05Z
- **Completed:** 2026-06-19T14:27:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `guides/web_to_mobile_migration.md` as an operational route inventory guide for existing Phoenix SaaS teams.
- Defaulted most routes to `:live_view` and named each allowed promotion reason.
- Added a worksheet covering Phoenix-owned, bounded bridge, cached read-only, offline island, native-screen, backend/provider, and defer examples.
- Added a "Do Not Migrate This" section for common overreach cases.
- Added `Crosswake.Guides.WebToMobileMigrationTest` to pin MIGRATE-01 behavior.

## Task Commits

1. **Task 1: Create the web-to-mobile migration docs-contract test** - `857ba04` (`test`)
2. **Task 2: Add the Phoenix SaaS web-to-mobile migration guide** - `d8b283f` (`docs`)

## Files Created/Modified

- `guides/web_to_mobile_migration.md` - New route inventory and migration pass guide.
- `test/crosswake/guides/web_to_mobile_migration_test.exs` - Docs-contract coverage for default owner, promotion reasons, pass structure, rejection cases, and reference links.

## Verification

- `bash -lc 'test -f test/crosswake/guides/web_to_mobile_migration_test.exs && if mix test test/crosswake/guides/web_to_mobile_migration_test.exs > /tmp/crosswake-web-to-mobile-red.log 2>&1; then echo "expected web-to-mobile migration docs-contract test to fail before guides/web_to_mobile_migration.md exists" >&2; exit 1; fi; grep -q "guides/web_to_mobile_migration.md" /tmp/crosswake-web-to-mobile-red.log'` - passed before guide implementation.
- `mix test test/crosswake/guides/web_to_mobile_migration_test.exs test/crosswake/guides/adopter_profiles_test.exs` - passed, 8 tests, 0 failures.

## Decisions Made

- Mentioned `examples/QUICK_START.md` and `guides/adoption.md` only as Phase 118 follow-up surfaces.
- Avoided checked-in native host evidence classification; Phase 119 still owns that decision.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial verification caught a line-break mismatch for the required `default most routes to Phoenix/LiveView` phrase. The guide sentence was tightened and the same targeted test command passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 117-03 can now wire README, ExDoc groups, guide maps, and support-truth labels against both new guide files.

---
*Phase: 117-route-policy-and-support-truth-guide-foundation*
*Completed: 2026-06-19*
