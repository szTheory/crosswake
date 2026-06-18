---
phase: 111-generator-rewire-clean-room-proof-release
plan: 01
subsystem: generator
tags: [mix-task, eex, ios, android, spm, maven]
requires:
  - phase: 110-native-publish-lockstep-infrastructure
    provides: lockstep publish coordinates and target 0.1.2 version truth
provides:
  - Dynamic Crosswake version assign for generated shell templates
  - Published non-local iOS SwiftPM coordinate for the szTheory mirror
  - Published non-local Android Maven coordinate for io.github.sztheory
  - Generator tests covering non-local published coordinates and local regression behavior
affects: [generator, published-dependencies, clean-room-proof, doctor-parity]
tech-stack:
  added: []
  patterns:
    - Application.spec(:crosswake, :vsn) with Mix.Project.config() fallback for generator version truth
    - EEx templates receive explicit version assigns instead of hardcoded satellite versions
key-files:
  created: []
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - test/mix/tasks/crosswake_gen_shell_test.exs
key-decisions:
  - "Use Application.spec(:crosswake, :vsn) first, with Mix.Project.config()[:version] fallback, so installed-dep and source-checkout generation both avoid nil coordinates."
  - "Leave host app MARKETING_VERSION/versionName defaults alone; only native dependency coordinates derive from the Crosswake version."
patterns-established:
  - "Generated native dep coordinates are rendered from one Crosswake version assign."
  - "Local scaffold tests must assert both the published non-local path and the local branch escape hatch."
requirements-completed: [GEN-01, GEN-02]
duration: 5 min
completed: 2026-06-14
---

# Phase 111 Plan 01: Template Rewire Summary

**Generator templates now render published iOS and Android native dependency coordinates from the live Crosswake version while preserving local scaffold mode.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-14T21:56:00Z
- **Completed:** 2026-06-14T22:01:01Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a nil-guarded generator version path that reads `Application.spec(:crosswake, :vsn)` with `Mix.Project.config()[:version]` fallback.
- Rewired the non-local iOS template to `https://github.com/szTheory/crosswake-shell-core-ios.git` with `upToNextMajorVersion` and `<%= @version %>`.
- Rewired the non-local Android template to `io.github.sztheory:crosswake-shell-core-android:<%= @version %>`.
- Expanded generator tests to assert published non-local coordinates, live version rendering, and unchanged `--local` behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Inject nil-guarded version assign into render_template/3** - `3918f49` (`feat(111-01): inject generator version assign`)
2. **Task 2: Rewire iOS and Android non-local template coordinates + dual-surface assertions** - `9d2b48f` (`feat(111-01): rewire shell templates to published deps`)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/mix/tasks/crosswake.gen.shell.ex` - Adds `fetch_version!/0` and passes `version:` into EEx assigns.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` - Points non-local SwiftPM at the szTheory mirror with dynamic minimum version.
- `priv/templates/crosswake/shell/android/app/build.gradle.eex` - Points non-local Gradle dependency at the io.github.sztheory Maven artifact with dynamic version.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - Pins non-local coordinate truth and local branch regression behavior.

## Decisions Made

- Followed the Phase 110 version-source decision: `Application.spec/2` is authoritative, while `Mix.Project.config/0` keeps source-checkout generator use viable.
- Kept the generated host app version fields unchanged because they are adopter app metadata, not Crosswake native dependency coordinates.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial Android negative assertion was too broad because the generated app namespace legitimately contains `dev.crosswake.shell`. It was narrowed to the old dependency coordinate `dev.crosswake:shell-core-android` before the task commit.

## Verification

- `mix test test/mix/tasks/crosswake_gen_shell_test.exs` passed.
- Rendered non-local iOS scaffold contained `github.com/szTheory/crosswake-shell-core-ios` and `upToNextMajorVersion`, and did not contain `XCLocalSwiftPackageReference`, `exactVersion`, `crosswake/crosswake-shell-core-ios`, or `minimumVersion = nil`.
- Rendered non-local Android scaffold contained `io.github.sztheory:crosswake-shell-core-android` and did not contain `dev.crosswake:shell-core-android`.
- Rendered `--local` iOS/Android scaffolds retained `XCLocalSwiftPackageReference` and `project(':crosswake-shell-core-android')` without published-coordinate leakage.

## Self-Check: PASSED

- All tasks in `111-01-PLAN.md` are complete.
- Key files named in frontmatter exist and contain the expected published coordinates/version wiring.
- Requirement IDs `GEN-01` and `GEN-02` are represented in `requirements-completed`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Published coordinate rendering is in place for the Plan 111-02 parity guard and the Plan 111-04 clean-room proof jobs. Plan 111-03 can now reconcile docs to the same published-coordinate truth.

---
*Phase: 111-generator-rewire-clean-room-proof-release*
*Completed: 2026-06-14*
