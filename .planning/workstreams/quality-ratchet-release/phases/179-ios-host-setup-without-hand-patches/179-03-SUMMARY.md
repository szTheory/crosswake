---
phase: 179
plan: "03"
subsystem: ios-host-settings
tags: [ios, xcode, proof-lane, settings-verification]
dependency_graph:
  requires: [179-01, 179-02]
  provides: [IOS-01, IOS-02, declaration-backed-ios-settings-matrix]
  affects: [phase-179-ios-host-setup]
tech_stack:
  added: [Node.js 22.14 effective-settings checker]
  patterns: [managed-xcconfig, in-memory-declaration-oracle, safe-subprocess-projection]
key_files:
  created:
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofSettings.xcconfig.eex
    - script/verify_ios_host_settings.mjs
    - test/crosswake/shell/ios_host_effective_settings_test.mjs
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - lib/crosswake/shell/ios_host_project_migration.ex
    - lib/mix/tasks/crosswake.gen.proof_lane.ex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
    - priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
decisions:
  - "The ordinary iOS host declaration is the sole identity and device-signing authority for shell and proof targets."
  - "Expected values cross the Mix-to-Node boundary through stdin and remain in memory; checker output is a safe allowlisted projection."
  - "A passing device settings matrix reports configuration only, not signing, installation, or physical-device support."
metrics:
  duration: "22m"
  completed_date: "2026-10-13"
status: complete
plan_head_before: 0b025646fdef3ea6250d2414cef474b99856d9a9
plan_head_after: eac3bd8ff2fc184f80cadf6c3cf899c017b7af2f
commits: 2
actuals:
  tokens: 15140
  tasks: 2
  commits: 2
---

# Phase 179 Plan 03: Declaration-backed iOS settings summary

The generated shell and proof projects now resolve app, test, simulator-signing, and device-signing settings from one host declaration, with an independent checker for all 20 Xcode matrix cells.

## Completed Tasks

1. Projected the declared host app and proof identities into managed Xcode settings, preserved the legacy proof `--config` path, added recognized proof-project migration and recovery, and kept the xcconfig out of app resources.
2. Added an in-memory declaration oracle and checked five targets across Debug/Release and simulator/device SDKs. Manual and automatic declarations each produced 20 distinct real Xcode observations.

## Verification

- `MIX_ENV=test mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs --seed 0` — 17 tests, 0 failures.
- Node 22.14.0 `--test test/crosswake/shell/ios_host_effective_settings_test.mjs` — 3 tests passed. Both host modes resolved 20/20 actual Xcode cells; the production Mix `--check` pipe passed.
- Negative controls rejected coherent managed-settings corruption, a target-level bundle-identity mask, a device unsigned fallback, xcconfig resource membership, interrupted generation, malformed/missing expected input, and duplicate or missing Xcode rows. A subprocess diagnostic retained the allowlisted `macos_service_denied` cause while excluding its private canary and setting values.
- `mix format --check-formatted` on edited Elixir files and `git diff --check` passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored device signing capability in the shell template**
- **Found during:** Task 2 real Xcode matrix
- **Issue:** Existing shell target settings forced code signing off for device SDKs, masking the declared device signing mode and team.
- **Fix:** Removed the forced signing-off values; simulator-only unsigned settings remain in the managed host xcconfig.
- **Files modified:** `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex`
- **Commit:** `0933457`

### TDD Gate Compliance

Workflow `tdd_mode` was false. The Task 1 assertion RED and a RED commit were not captured before implementation; Task 2 also has no qualifying assertion RED record. Earlier checker integration runs exposed Port EOF and script-path failures, but those were not retained as valid semantic RED evidence. The implementation and final verification are complete; this TDD limitation is recorded for review rather than reconstructed after the fact.

## Auth Gates

None.

## Known Stubs

None.

## Commits

- `0933457` — `feat(179-03): project declared iOS host settings`
- `eac3bd8` — `test(179-03): verify host settings matrix controls`

## Self-Check: PASSED

The summary file exists and both task commits are ancestors of the candidate `HEAD`.
