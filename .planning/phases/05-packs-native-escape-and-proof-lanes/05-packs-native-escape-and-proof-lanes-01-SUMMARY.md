---
phase: 05-packs-native-escape-and-proof-lanes
plan: 01
subsystem: packs-manifest-contract
tags:
  - phase-5
  - packs
  - manifest
  - tdd
requires:
  - PACK-01
provides:
  - Typed route-policy pack declarations
  - Canonical manifest pack registry
  - Route-local immutable pack references
affects:
  - lib/crosswake/policy/schema.ex
  - lib/crosswake/policy/route.ex
  - lib/crosswake/policy/validator.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/manifest/validator.ex
  - test/support/router_fixtures.ex
  - test/crosswake/policy/schema_test.exs
  - test/crosswake/policy/route_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/manifest/validator_test.exs
  - test/crosswake/policy/compiler_test.exs
  - test/crosswake/router_defaults_test.exs
tech_stack:
  added_patterns:
    - NimbleOptions-backed typed pack normalization
    - Manifest root pack registry keyed by pack_id@version
    - Route entries referencing canonical registry ids instead of duplicating pack payloads
decisions:
  - Keep the public runtime taxonomy at :live_view, :offline_island, and :native_screen.
  - Make Phoenix route policy the only source of pack metadata truth; shells consume manifest output only.
  - Represent route pack requirements as immutable pack references at the manifest route layer.
metrics:
  completed_date: 2026-05-17
  duration: not recorded
  tasks_completed: 2
  files_touched: 13
---

# Phase 5 Plan 1: Manifest-Owned Pack Registry Summary

Typed, versioned route pack declarations now compile into one canonical manifest pack registry, with route entries referencing immutable `pack_id@version` keys instead of carrying duplicate pack payloads.

## Completed Tasks

1. Extended route policy with typed pack declarations that require `id`, `version`, and `kind`, optionally allow integrity metadata, and reject duplicate pack ids while preserving the existing runtime taxonomy.
2. Added a manifest root `pack_registry`, compiled normalized route pack truth into canonical registry entries, and validated that every route pack reference resolves through the registry.

## Verification

- `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs`
  Outcome: passed
- `mix test test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs`
  Outcome: passed
- `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs test/crosswake/policy/compiler_test.exs test/crosswake/router_defaults_test.exs`
  Outcome: `30 tests, 0 failures`

The manifest now exports a root `pack_registry` and route-local immutable pack references, proven by the manifest and validator test coverage above.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated broader policy tests to the new typed pack contract**
- **Found during:** Task 2 verification
- **Issue:** `test/crosswake/policy/compiler_test.exs` and `test/crosswake/router_defaults_test.exs` still asserted older pack and route-fixture shapes, so the expanded verification suite failed after the 05-01 contract changes landed.
- **Fix:** Updated those tests to assert the current managed-router/runtime mix and typed pack structures used by the refreshed fixtures.
- **Files modified:** `test/crosswake/policy/compiler_test.exs`, `test/crosswake/router_defaults_test.exs`
- **Verification:** `mix test test/crosswake/policy/compiler_test.exs test/crosswake/router_defaults_test.exs`
- **Commit:** `0b309b4`

**Total deviations:** 1 auto-fixed (`Rule 1`: 1)
**Impact:** The deviation kept the broader policy suite aligned with the new pack contract without widening the runtime taxonomy or changing plan scope.

## Known Stubs

None.

## Threat Flags

None.

## Commits

- `fc0fd4c` `test(05-01): add failing policy pack contract tests`
- `9f03e1d` `feat(05-01): add typed route pack declarations`
- `218e4f6` `test(05-01): add failing manifest pack registry tests`
- `0b309b4` `feat(05-01): compile manifest-owned pack registry`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/05-packs-native-escape-and-proof-lanes/05-packs-native-escape-and-proof-lanes-01-SUMMARY.md`
- Verified commit `fc0fd4c` exists in git history
- Verified commit `9f03e1d` exists in git history
- Verified commit `218e4f6` exists in git history
- Verified commit `0b309b4` exists in git history
