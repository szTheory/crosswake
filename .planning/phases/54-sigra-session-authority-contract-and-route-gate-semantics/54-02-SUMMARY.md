---
phase: 54-sigra-session-authority-contract-and-route-gate-semantics
plan: "02"
subsystem: auth
tags: [route-policy, manifest, auth-posture, sigra]
requires:
  - phase: 46-sigra-auth-contract-only-slice
    provides: route-local auth predicate declarations
provides:
  - Route-local auth_posture DSL validation and normalization
  - Manifest-visible auth_posture route truth
  - Regenerated iOS and Android shell fixture manifests with explicit auth posture
affects: [phase-54, route-policy, manifest, operator-inspection]
tech-stack:
  added: []
  patterns: [route-local auth posture validation, manifest truth serialization]
key-files:
  created: []
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/ios_shell_host/Fixtures/crosswake_manifest.json
    - examples/android_shell_host/app/src/main/assets/crosswake_manifest.json
    - test/crosswake/policy/schema_test.exs
key-decisions:
  - "auth_posture uses the explicit values :strict_recent, :remembered_ok, and :cached_read_only_ok."
  - "Routes with recent-auth predicates, sensitive posture, or auth predicates default to :strict_recent unless explicitly weakened where allowed."
patterns-established:
  - "Auth weakening is route-local, validated, normalized, and serialized into manifest truth."
  - "Cached auth posture fails closed unless the route is provably cached read-only/degraded and non-sensitive."
requirements-completed: [SESS-03]
duration: 16min
completed: 2026-06-02
---

# Phase 54-02: Route Auth Posture Summary

**Route-local auth_posture validation and manifest serialization for remembered/cached auth weakening**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-02T01:32:00Z
- **Completed:** 2026-06-02T01:48:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `auth_posture` to the policy schema, normalized route struct, manifest route entry type, manifest builder, and JSON serialization.
- Added fail-closed cross-field validation for `:cached_read_only_ok`, sensitive routes, and `requires_recent_auth`.
- Regenerated iOS and Android fixture manifests from `examples/phoenix_host/gen_manifest.exs`.

## Task Commits

1. **Task 1/2: Route posture tests and implementation** - `d2606a3` (`feat(54-02): expose route auth posture`)

## Verification

- `mix test test/crosswake/policy/schema_test.exs --trace` — 16 tests, 0 failures.
- `cd examples/phoenix_host && mix run gen_manifest.exs` — regenerated both shell fixture manifests.
- `rg 'auth_posture|auth_min_level|requires_recent_auth' examples/ios_shell_host/Fixtures/crosswake_manifest.json examples/android_shell_host/app/src/main/assets/crosswake_manifest.json -n` — confirmed explicit `auth_posture` appears in both shell manifests.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The cached-read-only rejection test initially expected the later generic cached posture message when the earlier sensitive-route guard correctly fired first. The assertion was aligned to the intended fail-closed ordering.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`54-03` can evaluate route auth with manifest-visible `auth_posture` and the canonical `DenialCodes` registry.

---
*Phase: 54-sigra-session-authority-contract-and-route-gate-semantics*
*Completed: 2026-06-02*
