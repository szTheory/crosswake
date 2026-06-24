---
phase: 126-additive-native-dev-wiring
plan: "01"
subsystem: contract-generator
tags: [elixir, mix-task, json, exunit, dev-fixtures, contract-drift]

requires:
  - phase: 125-docker-port-setup
    provides: canonical PORT=4700 committed in runtime.exs (dev fixture URLs derive from this)

provides:
  - "--dev flag on mix crosswake.contract.gen that generates only the two dev fixtures"
  - "examples/ios_shell_host/Fixtures/route_activation-dev.json pointing at http://localhost:4700"
  - "examples/android_shell_host/app/src/dev/assets/route_activation.json pointing at http://10.0.2.2:4700"
  - "@dev_generated_json_paths + dev-drift test in contract_drift_test.exs"

affects:
  - 126-02-ios-pbxproj (consumes ios dev fixture)
  - 126-03-android-build (consumes android dev fixture)
  - 126-04-proof-posture-guard (references both dev fixtures for D-14 guard test)

tech-stack:
  added: []
  patterns:
    - "OptionParser.parse with strict: [dev: :boolean] for boolean Mix task flags (mirrors crosswake.gen.shell precedent)"
    - "if dev? do/else branch: dev branch writes ONLY dev paths; else branch writes ONLY prod paths (D-13 isolation)"
    - "Separate @dev_generated_json_paths module attribute — never merge with @generated_json_paths (pitfall 7)"

key-files:
  created:
    - examples/ios_shell_host/Fixtures/route_activation-dev.json
    - examples/android_shell_host/app/src/dev/assets/route_activation.json
  modified:
    - lib/mix/tasks/crosswake.contract.gen.ex
    - test/crosswake/contract/contract_drift_test.exs

key-decisions:
  - "Dev fixtures are generated (not hand-authored): bridge_protocol_version stays in lockstep automatically"
  - "D-13 isolation: --dev run never touches prod surfaces; default run never touches dev fixtures"
  - "@dev_generated_json_paths kept separate from @generated_json_paths to preserve prod 'seven surfaces' count assertion"

patterns-established:
  - "Dev builder pattern: mirror prod builder key list verbatim; change only url/origin/_generated_by"
  - "TDD for generator: write tests against committed output (integration-level), not internal functions"

requirements-completed: [NDEV-01, NDEV-02, NDEV-03]

duration: 3min
completed: 2026-06-22
status: complete
---

# Phase 126 Plan 01: Contract Generator --dev Flag + Dev Fixtures Summary

**`mix crosswake.contract.gen --dev` flag generating iOS (localhost:4700) and Android (10.0.2.2:4700) dev activation fixtures, guarded by a separate dev-drift test in contract_drift_test.exs**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-22T16:58:22Z
- **Completed:** 2026-06-22T17:01:23Z
- **Tasks:** 3
- **Files modified:** 4 (1 modified generator, 1 modified test, 2 created fixtures)

## Accomplishments

- Extended `mix crosswake.contract.gen` with `--dev` flag using `OptionParser.parse(args, strict: [dev: :boolean])`
- Added `@ios_dev_activation_path` and `@android_dev_activation_path` module constants + `ios_dev_activation_json/1` and `android_dev_activation_json/1` private builders
- Generated and committed both dev fixtures; each points at correct dev host and carries `_generated_by: "mix crosswake.contract.gen --dev"`
- Proved D-13 isolation: `--dev` run leaves prod surfaces byte-identical; default run leaves dev fixtures byte-identical
- Added `@dev_generated_json_paths` + "dev fixtures carry the canonical bridge_protocol_version" test to `contract_drift_test.exs` (6 tests, 0 failures)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add --dev flag + dev builders + path constants** - `71eed13` (feat)
2. **Task 2: Generate + commit the two dev fixtures** - `b7fdf14` (feat)
3. **Task 3: Add @dev_generated_json_paths + dev-drift test** - `254a807` (feat)

## Files Created/Modified

- `lib/mix/tasks/crosswake.contract.gen.ex` - Added OptionParser --dev flag, if/else branch, two path constants, two dev builders, updated @moduledoc
- `examples/ios_shell_host/Fixtures/route_activation-dev.json` - Generated iOS dev fixture (origin: http://localhost:4700)
- `examples/android_shell_host/app/src/dev/assets/route_activation.json` - Generated Android dev fixture (origin: http://10.0.2.2:4700)
- `test/crosswake/contract/contract_drift_test.exs` - Added @dev_generated_json_paths attribute and dev-drift test

## Decisions Made

- Used `OptionParser.parse` (not `OptionParser.parse!`) matching the crosswake.gen.shell precedent exactly (non-throwing, binding `_invalid`)
- Dev builder key order mirrors prod builders verbatim — only `_generated_by`, `origin`, and `url` differ
- `app/src/dev/assets/` directory auto-created by `write_if_changed/2`'s existing `File.mkdir_p!` call (no extra code needed)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 02 (iOS pbxproj + Info-Dev.plist + Dev.xcscheme) can proceed immediately — the iOS dev fixture it depends on is committed at `examples/ios_shell_host/Fixtures/route_activation-dev.json`
- Plan 03 (Android build.gradle + dev source set) can proceed immediately — the Android dev fixture is committed at `examples/android_shell_host/app/src/dev/assets/route_activation.json`
- Plan 04 (proof-posture guard test) depends on dev files created in Plans 02 and 03; the contract-drift guard from this plan is already green

## Self-Check

Verifying all claims before proceeding:

- `lib/mix/tasks/crosswake.contract.gen.ex` FOUND (modified)
- `examples/ios_shell_host/Fixtures/route_activation-dev.json` FOUND (created)
- `examples/android_shell_host/app/src/dev/assets/route_activation.json` FOUND (created)
- `test/crosswake/contract/contract_drift_test.exs` FOUND (modified)
- Commits: 71eed13, b7fdf14, 254a807 all present
- `mix test test/crosswake/contract/contract_drift_test.exs`: 6 tests, 0 failures

## Self-Check: PASSED

---
*Phase: 126-additive-native-dev-wiring*
*Completed: 2026-06-22*
