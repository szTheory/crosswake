---
phase: 05-packs-native-escape-and-proof-lanes
plan: 04
subsystem: transfer-manifest-contract
tags:
  - phase-5
  - transfer
  - manifest
  - tdd
requires:
  - PACK-04
provides:
  - Typed route-local upload, download, import, and export declarations
  - Route-local transfer state vocabulary and runtime status contract
  - Manifest-owned transfer seam truth per route before bridge or shell execution
affects:
  - lib/crosswake/policy/schema.ex
  - lib/crosswake/policy/route.ex
  - lib/crosswake/policy/validator.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/manifest/validator.ex
  - lib/crosswake/transfer/contracts.ex
  - lib/crosswake/transfer/runtime.ex
  - test/support/router_fixtures.ex
  - test/crosswake/policy/schema_test.exs
  - test/crosswake/policy/route_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/manifest/validator_test.exs
  - test/crosswake/transfer/contracts_test.exs
tech_stack:
  added_patterns:
    - Typed Crosswake transfer declarations with semantic source and destination metadata
    - Route-local transfer runtime status scoped to the active route
    - Manifest route entries projecting canonical transfer seams with versioned contract truth
decisions:
  - Keep upload, download, import, and export seams route-local and semantic instead of exposing generic WebView file behavior.
  - Reuse one versioned transfer contract across policy normalization, runtime status, and manifest projection.
  - Stop this plan at declaration and manifest truth; defer bridge command expansion and shell execution to later plans.
requirements_completed:
  - PACK-04
metrics:
  completed_date: 2026-05-16
  duration: 8m 26s
  tasks_completed: 2
  files_touched: 14
---

# Phase 5 Plan 04: Transfer Declaration And Manifest Truth Summary

Typed route-local transfer seams now cover upload, download, import, and export, and the manifest carries that canonical truth per route before any bridge or native shell execution is added.

## Completed Tasks

1. Extended route policy with typed `transfers` declarations, a canonical transfer state vocabulary, runtime-scoped status helpers, and validation that rejects ambiguous or runtime-inconsistent seam metadata.
2. Added manifest transfer seam types, projected normalized route transfer truth into manifest route entries, and validated malformed or runtime-drifted seams before any shell can consume them.

## Verification

- `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs test/crosswake/transfer/contracts_test.exs`
  Outcome: passed
- `mix test test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs`
  Outcome: passed
- `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs test/crosswake/transfer/contracts_test.exs`
  Outcome: `33 tests, 0 failures`

The plan now proves that transfer seams remain route-local, versioned, semantic, and manifest-owned, with no bridge or shell expansion in this slice.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.

## Commits

- `d5fa6a7` `test(05-04): add failing transfer declaration tests`
- `ca20bfc` `feat(05-04): add route-local transfer contracts`
- `58f75cd` `test(05-04): add failing manifest transfer seam tests`
- `6ee0c27` `feat(05-04): compile transfer seams into manifest truth`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/05-packs-native-escape-and-proof-lanes/05-packs-native-escape-and-proof-lanes-04-SUMMARY.md`
- Verified commit `d5fa6a7` exists in git history
- Verified commit `ca20bfc` exists in git history
- Verified commit `58f75cd` exists in git history
- Verified commit `6ee0c27` exists in git history
