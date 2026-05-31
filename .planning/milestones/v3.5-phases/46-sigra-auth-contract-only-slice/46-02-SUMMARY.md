---
phase: 46-sigra-auth-contract-only-slice
plan: 02
subsystem: auth-manifest-contract
tags: [auth, manifest, fixtures, proof]
completed_at: 2026-05-31
duration: "in-session"
requirements_completed: [AUTH-02]
key_files:
  created:
    - test/crosswake/proof/phase46_sigra_auth_contract_test.exs
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/ios_shell_host/Fixtures/crosswake_manifest.json
    - examples/android_shell_host/app/src/main/assets/crosswake_manifest.json
    - examples/phoenix_host/config/config.exs
    - test/crosswake/policy/schema_test.exs
decisions:
  - "requires_recent_auth is strictly positive integer seconds"
  - "auth_min_level uses Sigra closed MFA vocabulary"
---

# Phase 46 Plan 02: Sigra Auth Contract-Only Slice Summary

Added route-local auth predicate DSL validation and carried auth predicate truth into manifest RouteEntry serialization and checked-in shell fixtures.

## What Changed

- Added `auth_min_level` and `requires_recent_auth` validation in `Crosswake.Policy.Schema`, including strict vocabulary and positive-integer-seconds constraints.
- Extended `Crosswake.Policy.Route` with `auth_min_level` and `requires_recent_auth` fields/types.
- Extended `Crosswake.Manifest.Types.RouteEntry` and `Crosswake.Manifest.Builder` to carry auth predicates from route policy to manifest.
- Updated example-host router `saas-profile-settings` route to declare:
  - `auth_min_level: :mfa`
  - `requires_recent_auth: 900`
- Regenerated checked-in fixture manifests for iOS/Android via canonical generator path.
- Added hermetic proof scaffold:
  - `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`
  - Asserts declared-vs-undeclared auth key serialization and hermeticity.

## Verification

- `mix test test/crosswake/policy/schema_test.exs --trace` ✅
- `cd examples/phoenix_host && mix run gen_manifest.exs` ✅
- `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs --trace` ✅
- `rg -n '"auth_min_level"|"requires_recent_auth"' examples/ios_shell_host/Fixtures/crosswake_manifest.json examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` ✅
- `mix compile --warnings-as-errors` ✅

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking Issue] Fixed pre-existing syntax error preventing canonical manifest generation
- Found during: Task 2 verification
- Issue: `examples/phoenix_host/config/config.exs` had invalid keyword syntax in repo config, causing `mix run gen_manifest.exs` parse failure.
- Fix: Removed invalid trailing config entry shape; kept change narrowly scoped to syntax unblock.
- Files modified: `examples/phoenix_host/config/config.exs`
- Commit: `e5a8b4a`

2. [Rule 3 - Execution Environment] Root `mix run examples/phoenix_host/gen_manifest.exs` cannot resolve `CrosswakeExample.Router` without example-host code path
- Found during: required root verification command
- Handling: executed canonical generator in `examples/phoenix_host`; additionally validated root invocation with explicit preload (`MIX_ENV=test mix run -e 'Crosswake.TestSupport.ExampleHost.load!()' examples/phoenix_host/gen_manifest.exs`).
- Impact: no contract behavior change; fixture output remains canonical-generator produced.

## Commits

- `fa3577d` test(46-02): add failing coverage for auth route predicates
- `b06d1e7` feat(46-02): add auth predicate fields to route policy contracts
- `e5a8b4a` feat(46-02): carry auth predicates into manifest truth and fixtures

## Known Stubs

None.

## Self-Check: PASSED
