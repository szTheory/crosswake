---
phase: 01-route-policy-foundation
plan: 03
subsystem: diagnostics
tags: [elixir, phoenix, route-policy, diagnostics, warnings, validation]
requires:
  - phase: 01-route-policy-foundation
    provides: router-local Crosswake metadata, normalized route structs, and metadata introspection
provides:
  - compile pipeline from router metadata to normalized policy output
  - aggregated compile diagnostics with route-local context and fix hints
  - non-blocking unmanaged-route adoption warnings
affects: [manifest, doctor-tooling, generators, support-matrix-validation]
tech-stack:
  added: []
  patterns: [structured-compile-diagnostics, semantic-policy-validation, opt-in-adoption-warnings]
key-files:
  created:
    - lib/crosswake/policy/compiler.ex
    - lib/crosswake/policy/validator.ex
    - lib/crosswake/policy/diagnostic.ex
    - lib/crosswake/policy/error.ex
    - lib/crosswake/policy/warning.ex
    - test/crosswake/policy/compiler_test.exs
    - test/crosswake/policy/compile_error_test.exs
    - test/crosswake/policy/warning_test.exs
    - test/support/compile_router_case.ex
  modified: []
key-decisions:
  - "Keep compile-time enforcement limited to local declarative contradictions and avoid environment-truth claims."
  - "Reserve `:adapter` through explicit diagnostics instead of widening the public Phase 1 runtime taxonomy."
  - "Make unmanaged-route adoption warnings opt-in so hard validation stays strict while incremental adoption remains possible."
patterns-established:
  - "Compiler result pattern: successful compiles return normalized routes plus optional warnings; failed compiles return an aggregated Diagnostic struct."
  - "Diagnostic pattern: each compile error carries route path, helper, verb, source location, offending key, reason, and fix hint."
requirements-completed: [ROUTE-01, ROUTE-02, ROUTE-03, ROUTE-04]
duration: 6min
completed: 2026-05-13
---

# Phase 1 Plan 03: Route Policy Foundation Summary

**Compile-time route-policy enforcement with aggregated Phoenix-style diagnostics, duplicate/contradiction checks, and opt-in unmanaged-route adoption warnings**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-13T21:53:01Z
- **Completed:** 2026-05-13T21:58:48Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Added a compiler that walks Crosswake-managed route metadata, normalizes policy declarations, and rejects duplicate ids plus semantic contradictions at compile time.
- Introduced structured `Error` and `Diagnostic` types that aggregate multiple route failures and render route-local fix hints with file and line context.
- Added an opt-in warning path for unmanaged routes so incremental adoption can be surfaced without weakening hard validation failures.

## Task Commits

1. **Task 1: Build the route-policy compiler and semantic validator** - `f8af12c` (`test`), `3f1d383` (`feat`)
2. **Task 2: Format aggregated compile-time diagnostics with fix hints** - `8ba0e38` (`test`), `10e88c7` (`feat`)
3. **Task 3: Emit non-blocking adoption warnings for uncovered routes** - `dfb6328` (`test`), `b6f1c23` (`feat`)

## Files Created/Modified
- `lib/crosswake/policy/compiler.ex` - compiles managed router metadata, aggregates errors, and emits optional warnings.
- `lib/crosswake/policy/validator.ex` - enforces local declarative invariants for runtime, offline, sync, capability, and security combinations.
- `lib/crosswake/policy/diagnostic.ex` - formats aggregated compile diagnostics into Phoenix/Ecto-like error output.
- `lib/crosswake/policy/error.ex` - structured route-local compile error payload.
- `lib/crosswake/policy/warning.ex` - unmanaged-route adoption warning struct and formatter.
- `test/crosswake/policy/compiler_test.exs` - compiler contract tests for valid routes, reserved runtime rejection, duplicates, and contradictions.
- `test/crosswake/policy/compile_error_test.exs` - diagnostic formatting tests for source context, offending keys, and aggregated failures.
- `test/crosswake/policy/warning_test.exs` - warning-path tests proving incremental adoption guidance stays non-blocking.
- `test/support/compile_router_case.ex` - helper to capture emitted warning output during compile-time style tests.

## Decisions Made
- Kept unmanaged-route warnings behind `warn_on_unmanaged?` and `emit_warnings?` options so existing compile callers stay strict and quiet by default.
- Modeled diagnostics and warnings as explicit structs so later manifest and doctor phases can build on machine-readable compile results instead of reparsing strings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Realigned semantic checks with the existing Phase 1 router contract**
- **Found during:** Task 1 (Build the route-policy compiler and semantic validator)
- **Issue:** The initial validator incorrectly rejected the already-established `offline_island + cached_read_only + sync` fixture from Plan 02.
- **Fix:** Narrowed the contradiction checks to reject `offline_island + :unavailable` and `sync + offline: :unavailable` while allowing the previously proven cached-read-only case.
- **Files modified:** `lib/crosswake/policy/validator.ex`, `test/crosswake/policy/compiler_test.exs`
- **Verification:** `mix test test/crosswake/policy/compiler_test.exs`
- **Committed in:** `3f1d383`

**2. [Rule 1 - Bug] Fixed the warning test helper so RED targeted the intended missing feature**
- **Found during:** Task 3 (Emit non-blocking adoption warnings for uncovered routes)
- **Issue:** The new helper used `flunk/1` without importing the ExUnit assertions module, so the first RED failure came from the test harness instead of the missing warning implementation.
- **Fix:** Imported `ExUnit.Assertions` in the helper and reran the warning test to confirm the failure moved to the absent warning struct/path.
- **Files modified:** `test/support/compile_router_case.ex`
- **Verification:** `mix test test/crosswake/policy/warning_test.exs`
- **Committed in:** `dfb6328`

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes were required for correctness and TDD signal quality. No scope creep beyond the planned compiler, diagnostics, and warning surfaces.

## Issues Encountered
None beyond the auto-fixed validator and test-helper issues.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 1 now has a compile-time enforcement layer that later manifest and doctor tooling can consume directly.
- Route diagnostics, reserved-runtime handling, and adoption warnings are all covered by focused negative-path tests, so Plan 04 can build setup generators against a stable policy compiler.

## Self-Check: PASSED
