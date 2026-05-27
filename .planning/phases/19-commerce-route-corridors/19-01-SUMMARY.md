---
phase: 19-commerce-route-corridors
plan: 01
subsystem: policy
tags: [commerce, corridors, manifest, validation, provider-neutral]
requires:
  - phase: 13-commerce-and-entitlement-contract
    provides: normalized commerce vocabulary and backend-owned entitlement authority boundaries
provides:
  - provider-neutral route commerce DSL with corridor and role bindings
  - canonical corridor profile source compiled into manifest root commerce_corridors
  - additive manifest compatibility coverage for corridor_ref and commerce_corridors fields
affects: [phase-20-entitlement-lifecycle-semantics, phase-22-commerce-support-review-proof, doctor-support-truth]
tech-stack:
  added: []
  patterns: [registry-plus-reference commerce corridors, additive manifest compatibility, provider-neutral vocabulary validation]
key-files:
  created:
    - lib/crosswake/policy/corridor_profiles.ex
    - test/crosswake/policy/corridor_profiles_test.exs
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex
    - lib/crosswake/policy/compiler.ex
    - lib/crosswake/policy/validator.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - lib/crosswake/manifest/validator.ex
    - test/crosswake/policy/schema_test.exs
    - test/crosswake/policy/route_test.exs
    - test/crosswake/policy/compiler_test.exs
    - test/crosswake/manifest/manifest_test.exs
    - test/crosswake/manifest/validator_test.exs
key-decisions:
  - "Kept manifest schema at 1.0.0 and treated commerce corridor fields as additive, enforced only when route commerce is declared."
  - "Introduced Crosswake.Policy.CorridorProfiles as the single canonical corridor declaration source consumed by manifest assembly."
  - "Used provider-neutral rejection checks in both policy and manifest validation layers to block StoreKit/Play Billing vocabulary leakage."
patterns-established:
  - "Canonical profile source -> root registry -> route reference linkage for commerce corridor truth."
  - "Validator guidance distinguishes additive compatibility from declaration-required errors."
requirements-completed: [COMM-04, COMM-05]
duration: 7 min
completed: 2026-05-27
---

# Phase 19 Plan 01: Commerce Corridor Contract Foundation Summary

**Crosswake now compiles explicit provider-neutral route commerce corridor declarations into a canonical manifest registry with strict referential validation and additive schema compatibility coverage.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-27T09:08:10Z
- **Completed:** 2026-05-27T09:15:10Z
- **Tasks:** 4
- **Files modified:** 12

## Accomplishments
- Added `commerce` route DSL semantics (`corridor` + bounded `role`) with compile-time guidance and provider-specific rejection paths.
- Added canonical `Crosswake.Policy.CorridorProfiles` declarations and manifest root `commerce_corridors` plus route `corridor_ref` linkage.
- Added proof-chain tests for positive declarations, provider-vocabulary failures, canonical profile linkage, and undeclared corridor references.
- Locked explicit no-bump compatibility behavior (`manifest_schema_version` remains `1.0.0`) with additive coverage for routes that do and do not declare commerce.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add provider-neutral corridor DSL fields and route semantics** - `0562919` (feat)
2. **Task 2: Declare corridor profiles and emit root registry/references** - `90d2b43` (feat)
3. **Task 3: Prove COMM-04/COMM-05 profile-to-manifest chain with tests** - `b901f70` (test)
4. **Task 4: Lock additive manifest compatibility strategy (no bump)** - `109e733` (test)

## Verification Results
- `mix test test/crosswake/policy/corridor_profiles_test.exs test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs test/crosswake/policy/compiler_test.exs` -> pass (29 tests, 0 failures)
- `mix test test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs` -> pass (24 tests, 0 failures)
- `rg "commerce_corridors|corridor_ref|paywall_entry" lib/crosswake/policy lib/crosswake/manifest` -> pass

## Files Created/Modified
- `lib/crosswake/policy/corridor_profiles.ex` - canonical provider-neutral corridor profile declarations.
- `lib/crosswake/policy/schema.ex` - `commerce` DSL option schema and bounded role vocabulary.
- `lib/crosswake/policy/route.ex` - route-level semantic gates for corridor/role completeness.
- `lib/crosswake/policy/compiler.ex` - actionable commerce hint mapping for compiler diagnostics.
- `lib/crosswake/policy/validator.ex` - provider-specific corridor vocabulary rejection path.
- `lib/crosswake/manifest/types.ex` - root `commerce_corridors` and route `commerce` types/serialization.
- `lib/crosswake/manifest/builder.ex` - canonical profile registry assembly and route `corridor_ref` emission.
- `lib/crosswake/manifest/validator.ex` - corridor referential integrity, denial/fallback posture, and additive guidance.
- `test/crosswake/policy/corridor_profiles_test.exs` - canonical profile provider-neutral and posture assertions.
- `test/crosswake/policy/schema_test.exs` - valid commerce declaration normalization coverage.
- `test/crosswake/policy/route_test.exs` - provider-specific role rejection coverage (`:storekit`).
- `test/crosswake/policy/compiler_test.exs`, `test/crosswake/manifest/manifest_test.exs`, `test/crosswake/manifest/validator_test.exs` - profile-to-manifest linkage and undeclared `corridor_ref` failures.

## Decisions Made
- Kept Phase 19 corridor fields additive under schema `1.0.0` to preserve compatibility for non-commerce routes.
- Made canonical corridor profiles the manifest source of truth to avoid per-route duplication and drift.
- Required deterministic, explicit errors for provider-specific vocabulary and undeclared corridor references.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Plan `19-02` can build lifecycle semantics on top of route-local corridor ownership and manifest linkage now in place.
- No blockers identified for subsequent Phase 19 plan execution.

---
*Phase: 19-commerce-route-corridors*
*Completed: 2026-05-27*
