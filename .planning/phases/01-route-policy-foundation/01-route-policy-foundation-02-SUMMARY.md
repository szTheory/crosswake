---
phase: 01-route-policy-foundation
plan: 02
subsystem: routing
tags: [phoenix, phoenix_live_view, router, metadata, route-policy]
requires:
  - phase: 01-route-policy-foundation
    provides: typed route policy structs, schema validation, and normalization defaults
provides:
  - router-local `crosswake:` authoring beside Phoenix routes
  - nested scope-default rewriting with deterministic route-local overrides
  - compiled Crosswake policy attached to Phoenix route metadata
  - integration fixtures covering `:live_view`, `:offline_island`, and `:native_screen`
affects: [manifest, diagnostics, validation, generators]
tech-stack:
  added: [phoenix, phoenix_live_view]
  patterns: [router-adjacent DSL, metadata-backed policy introspection, AST-based scope default rewriting]
key-files:
  created:
    [
      lib/crosswake/router.ex,
      lib/crosswake/router/scope_defaults.ex,
      lib/crosswake/policy/merge.ex,
      lib/crosswake/policy/router_metadata.ex,
      test/support/router_fixtures.ex,
      test/crosswake/router_test.exs,
      test/crosswake/router_defaults_test.exs
    ]
  modified: [mix.exs, mix.lock]
key-decisions:
  - "Crosswake policy is authored only through router-local metadata and defaults, not a parallel registry."
  - "Compiled policy is stored alongside raw Phoenix metadata under explicit keys for authoritative introspection."
  - "Scope defaults are applied by AST rewriting so nested router declarations stay local and deterministic."
patterns-established:
  - "Route metadata pattern: raw `:crosswake` options plus normalized `:crosswake_policy` struct on Phoenix metadata."
  - "Default precedence pattern: scope defaults fill secondary axes while route-local declarations remain authoritative."
requirements-completed: [ROUTE-01, ROUTE-02, ROUTE-03]
duration: 5min
completed: 2026-05-13
---

# Phase 1 Plan 02: Route Policy Foundation Summary

**Phoenix router macros now own Crosswake route truth through `crosswake:` metadata, nested defaults, and compiled route-policy structs on Phoenix route metadata.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-13T23:43:31+02:00
- **Completed:** 2026-05-13T23:48:44+02:00
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Added a Phoenix-native router DSL that accepts `crosswake:` options on routes and `crosswake_defaults` blocks for nested defaults.
- Attached normalized `Crosswake.Policy.Route` structs to Phoenix route metadata while preserving raw Crosswake route options.
- Proved router-local authoring, inherited defaults, route-local overrides, and unmanaged-route passthrough with integration tests.

## Task Commits

1. **Task 1: Add router-adjacent `crosswake:` route metadata and scope defaults** - `029bba2` (`feat`)
2. **Task 2: Attach compiled Crosswake policy to Phoenix route metadata** - `b4c6763` (`test`), `9a1edea` (`feat`)
3. **Task 3: Prove default merging and route-local authoring behavior** - `0fc8ff7` (`test`), `29acd0f` (`feat`)

## Files Created/Modified
- `mix.exs` and `mix.lock` - added Phoenix and LiveView dependencies required for router compilation and reflection.
- `lib/crosswake/router.ex` - Crosswake router wrapper macros for HTTP and LiveView routes.
- `lib/crosswake/router/scope_defaults.ex` - AST rewriting for nested `crosswake_defaults` inheritance.
- `lib/crosswake/policy/merge.ex` - deterministic keyword merge helper where route-local values win.
- `lib/crosswake/policy/router_metadata.ex` - raw and compiled metadata attachment plus fetch helpers.
- `test/support/router_fixtures.ex` - managed and defaults fixture routers across all public runtimes.
- `test/crosswake/router_test.exs` and `test/crosswake/router_defaults_test.exs` - integration coverage for metadata attachment and default precedence.

## Decisions Made
- Used explicit metadata keys `:crosswake` and `:crosswake_policy` so later manifest and diagnostics work can inspect both authored and normalized policy.
- Applied scope defaults before route compilation rather than through a runtime registry, preserving router locality and Phoenix introspection as the source of truth.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added Phoenix router dependencies**
- **Found during:** Task 1
- **Issue:** The planned router integration could not compile because the project only depended on `nimble_options`.
- **Fix:** Added `:phoenix` and `:phoenix_live_view` to the Mix dependencies and fetched the lockfile updates.
- **Files modified:** `mix.exs`, `mix.lock`
- **Verification:** `mix deps.get`, `mix compile`
- **Committed in:** `029bba2`

**2. [Rule 1 - Bug] Fixed router macro visibility inside Phoenix scopes**
- **Found during:** Task 2 RED
- **Issue:** `crosswake_defaults` and wrapped route macros were ambiguous or unavailable inside `scope`, blocking router fixture compilation.
- **Fix:** Reworked the router wrapper imports so Crosswake macros are the active route surface and `crosswake_defaults` expands correctly in scoped blocks.
- **Files modified:** `lib/crosswake/router.ex`
- **Verification:** `mix test test/crosswake/router_test.exs`
- **Committed in:** `f20026c`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both fixes were required for the planned DSL to compile and for the TDD coverage to execute. No scope creep beyond the router contract.

## Issues Encountered
None beyond the auto-fixed dependency and macro import issues.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Route-local policy authoring and route metadata introspection are ready for compile-time validation and diagnostics work.
- Later validation plans can build directly on `Crosswake.Policy.RouterMetadata` without inventing a second route registry.

## Self-Check: PASSED
