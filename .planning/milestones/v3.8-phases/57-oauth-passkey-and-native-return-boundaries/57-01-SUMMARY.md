---
phase: 57-oauth-passkey-and-native-return-boundaries
plan: "01"
subsystem: auth
tags: [sigra, auth-return, route-policy, manifest]
requires:
  - phase: 54-session-authority-contracts-and-route-gates
    provides: [SessionAuthorityLane, auth posture route predicates]
provides:
  - Route-local `auth_return` policy schema with closed provider-neutral vocabulary
  - Manifest-visible `RouteAuthReturn` serialization
  - Fail-closed return-route binding and sensitive transport defaults
affects: [phase-57, phase-58, sigra, support-truth]
tech-stack:
  added: []
  patterns: [route-local-contract, closed-vocabulary, manifest-known-binding]
key-files:
  created:
    - test/crosswake/proof/phase57_auth_return_boundaries_test.exs
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
key-decisions:
  - "Auth returns use one route-local `auth_return` key, not provider registries or capability-first bridge authority."
  - "`return_route_id` is a manifest-known Crosswake route id; raw return URLs are not route authority."
  - "Sensitive auth-return routes default to strict recent posture and reject custom schemes."
requirements-completed: [RETN-01]
duration: 32 min
completed: 2026-06-02
---

# Phase 57 Plan 01: Route Policy, Manifest, And Boundary Vocabulary Summary

**Provider-neutral route-local auth-return policy and manifest serialization**

## Performance

- **Duration:** 32 min
- **Started:** 2026-06-02T09:15:40Z
- **Completed:** 2026-06-02T09:47:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added route-local `auth_return` schema support for `:oauth`, `:passkey`, and `:native_auth`.
- Locked transport vocabulary to `:http_callback`, `:verified_https_link`, `:custom_scheme`, and `:bridge_event`.
- Required kind-specific validation atoms and rejected provider-specific policy terms.
- Serialized `auth_return` into manifest route entries while keeping route authority tied to manifest-known route ids.
- Proved sensitive defaults and sensitive custom-scheme rejection in the Phase 57 proof lane.

## Task Commits

1. **Task 57-01-01: Audit and harden route-local auth_return schema vocabulary** - `4b9d19b` (feat)
2. **Task 57-01-02: Enforce kind-specific validations, strict sensitive defaults, and manifest serialization** - `4b9d19b` (feat)

## Files Created/Modified

- `lib/crosswake/policy/schema.ex` - Added `auth_return` schema validation and closed vocabulary.
- `lib/crosswake/policy/route.ex` - Added route validation, sensitive defaults, and custom-scheme rejection.
- `lib/crosswake/manifest/types.ex` - Added manifest auth-return type.
- `lib/crosswake/manifest/builder.ex` - Serialized route-local auth-return metadata.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` - Added route/manifest proof coverage.

## Decisions Made

No new decisions beyond the locked Phase 57 context. Implementation followed D-01 through D-10.

## Deviations from Plan

Implementation was committed as one integrated Phase 57 production commit because the shared proof file and support truth span all four plans.

---

**Total deviations:** 1 documentation/commit-shaping deviation.
**Impact on plan:** No behavior or scope change.

## Issues Encountered

None.

## User Setup Required

None.

## Verification

- `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` - passed, 8 tests.
- `mix test` - passed, 660 tests, 0 failures, 2 excluded.

## Next Phase Readiness

Ready for Plan 57-02 envelope and validation contract execution.

