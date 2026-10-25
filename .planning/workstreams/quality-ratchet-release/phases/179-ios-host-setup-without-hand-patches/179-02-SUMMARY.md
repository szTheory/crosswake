---
phase: 179-ios-host-setup-without-hand-patches
plan: 02
subsystem: ios-shell
tags: [phoenix, mix, ios, xcode, generation, recovery]

requires:
  - phase: 179-01
    provides: Declared Phoenix host configuration and first generated iOS shell
provides:
  - Closed ownership and nonwriting inspection for generated iOS host resources
  - Staged publication, interrupted-generation detection, and explicit recovery
  - Xcode pre-build denial while a managed generation is pending
  - Bounded opt-in migration for recognized PBX target settings
affects: [179-03, 179-04, ios-host-generation]

actuals:
  tokens: 12144
  tasks: 2
  commits: 2

plan_head_before: ea003e773f573ac4aea07c161b3af016298141b9
plan_head_after: 0b025646fdef3ea6250d2414cef474b99856d9a9

tech-stack:
  added: []
  patterns:
    - Recognize managed outputs from private digest metadata rather than path names alone
    - Stage all desired and prior bytes before publishing, then retain a pending marker through verification
    - Keep PBX migration limited to known configuration IDs and preserve unrelated project bytes

key-files:
  created:
    - lib/crosswake/shell/ios_host_project_migration.ex
  modified:
    - lib/crosswake/shell/managed_outputs.ex
    - lib/crosswake/shell/ios_host_generation.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - test/crosswake/shell/managed_outputs_test.exs
    - test/mix/tasks/crosswake_gen_shell_host_test.exs

key-decisions:
  - "Keep check and diff read-only and classify only the closed managed-output allowlist."
  - "Inject the test crash after replacing the manifest first, leaving Xcode settings syntactically valid so the actual PBX guard runs."
  - "Require explicit recovery and an opt-in migration command; ordinary regeneration leaves edited PBX content untouched."

requirements-completed: []
commits: 2
duration: 45min
completed: 2026-10-13
status: complete
---

# Phase 179 Plan 02: iOS Host Setup Without Hand Patches Summary

**Managed iOS resources now regenerate safely, interrupted updates block Xcode builds until recovery, and recognized PBX wiring can be migrated by explicit opt-in.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-10-13T17:05:02Z
- **Completed:** 2026-10-13T17:49:54Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added ownership metadata and a closed set of managed iOS outputs. `--check` and host `--diff` inspect missing, stale, conflicting, unsafe, and interrupted states without writing files, stamps, or recovery artifacts.
- Regeneration preserves edited Swift, entitlements, and PBX bytes. A real Phoenix host rerun refreshed the declared origin and recognized resources while keeping native edits byte-identical.
- Publication stages prior and desired output bytes, writes a pending marker before replacing files, verifies the final set, and removes the marker last. Explicit recovery restored the complete prior set after the deterministic crash point.
- Added a PBX shell build phase that fails with a safe, specific interruption message while the pending marker exists. The generated project passed an actual Xcode build after explicit recovery.
- Added a bounded migration preview/apply path for the six recognized PBX build configurations. The command removes known identity overrides and keeps unrelated host comments; unfamiliar configurations are denied.
- Preserved Android and existing development/local generation behavior.

## Task Commits

1. **Task 1: Inspect and regenerate only recognized managed resources** — `abc51e7` (feat)
2. **Task 2: Reject mixed generations and migrate edited project wiring by opt-in** — `0b02564` (feat)

Plan commits were measured from `ea003e773f573ac4aea07c161b3af016298141b9` to `0b025646fdef3ea6250d2414cef474b99856d9a9`: **2 commits**.

## Files Created/Modified

- `lib/crosswake/shell/managed_outputs.ex` — managed-output inspection, ownership, staged publication, recovery, and generation guard.
- `lib/crosswake/shell/ios_host_generation.ex` — stable generation metadata and the desired managed-output set.
- `lib/crosswake/shell/ios_host_project_migration.ex` — closed-structure PBX preview and bounded migration.
- `lib/mix/tasks/crosswake.gen.shell.ex` — `--check`, recovery, migration, and host diff actions.
- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` — actual Xcode pre-build marker guard.
- `test/crosswake/shell/managed_outputs_test.exs` — nonwriting checks, conflict/symlink denial, interruption/recovery, and PBX migration controls.
- `test/mix/tasks/crosswake_gen_shell_host_test.exs` — native edit preservation, real Xcode denial and recovered build, and migration apply.

## Decisions Made

- The marker remains until recovery has restored and verified one coherent generation. The implementation does not claim the per-file renames are a filesystem-wide atomic transaction.
- The deterministic interruption occurs after the manifest replacement. This keeps the xcconfig syntactically valid and lets the generated Xcode phase itself prove the denial.
- PBX migration applies only to the six known build-configuration objects and rejects unknown identities or base-configuration references.

## TDD Gate Compliance

- **Task 1 RED:** New managed-output API tests failed because the inspection and publication functions were undefined. The new host `--check` behavior also failed before its option was implemented.
- **Task 2 RED:** The migration tests failed before the preview API existed. The host build assertion was tightened to require the exact guard diagnostic after an earlier word-only check could match a DerivedData path.
- **GREEN:** The Task 1 focused suite passed **16 tests, 0 failures**. The final Task 2 focused suite passed **19 tests, 0 failures**, including actual Xcode builds before and after the explicit `--recover` command and a real migration apply.
- **Reporter limitation:** GSD's local RED classifier has no ExUnit console adapter. ExUnit output and named assertion failures were inspected directly; no automated classifier verdict is claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Make the interrupted-build assertion prove the Xcode guard ran**
- **Found during:** Task 2
- **Issue:** A word-only assertion passed because the word “interrupted” occurred in the DerivedData path, and the first interrupted replacement could alter xcconfig before Xcode read it.
- **Fix:** Assert the distinct guard message and publish the manifest first at the deterministic crash point. Point the PBX phase at the generated project root's pending marker.
- **Files modified:** `lib/crosswake/shell/managed_outputs.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `test/mix/tasks/crosswake_gen_shell_host_test.exs`
- **Verification:** The actual interrupted build exited nonzero with `CROSSWAKE_IOS_GENERATION_INTERRUPTED`; after `--recover`, the actual Xcode build succeeded and the managed-output check reported current.
- **Committed in:** `75658d2`

**2. [Rule 3 - Blocking] Limit PBX recognition to build-configuration objects**
- **Found during:** Task 2
- **Issue:** The initial bounded scanner considered unrelated PBX object IDs while inspecting the generated project.
- **Fix:** Restrict migration recognition to the six known `XCBuildConfiguration` objects and retain the unrecognized-structure denial.
- **Files modified:** `lib/crosswake/shell/ios_host_project_migration.ex`
- **Verification:** The generated PBX preview and the unknown-configuration negative test passed.
- **Committed in:** `75658d2`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 3)  
**Impact on plan:** Both fixes made planned real-build and migration gates exercise the intended checks.

## Verification

- `MIX_ENV=test mix test test/crosswake/shell/managed_outputs_test.exs test/mix/tasks/crosswake_gen_shell_host_test.exs test/mix/tasks/crosswake_gen_shell_diff_test.exs test/mix/tasks/crosswake_gen_shell_stamp_test.exs --seed 0` — **19 tests, 0 failures**. This included a changed valid manifest as the first interrupted replacement, actual Xcode denial while pending, explicit `--recover`, a successful Xcode build after recovery, and bounded migration apply.
- The earlier Task 1 scoped run passed **16 tests, 0 failures**, including the preserved diff/stamp behavior.
- `mix format --check-formatted` passed for all changed Elixir source and test files.
- `git diff --check` passed before the Task 2 commit; both task commits are ancestors of candidate HEAD. The Task 2 commit contains no file deletions.
- The unrelated `placeholder host` string found by the source scan is an existing test fixture label, not an unimplemented product stub.

## Issues Encountered

- A real Xcode build first exposed that the PBX phase referenced the pending marker one directory too high; the path was corrected and the actual interrupted build then failed for the intended reason.
- Running both real Xcode builds exceeded ExUnit's default 60-second test timeout. The host test now allows 120 seconds; the complete focused suite passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 02 is complete. Managed host output regeneration, read-only inspection, interruption recovery, build denial, and opt-in PBX migration are available for the remaining Phase 179 work. No signing, installation, physical-device, or adopter proof is claimed.

---
*Phase: 179-ios-host-setup-without-hand-patches*
*Completed: 2026-10-13*

## Self-Check: PASSED

- The Task 2 summary exists at the required phase path.
- Candidate commits `abc51e7` and `0b02564` are ancestors of candidate HEAD `0b025646fdef3ea6250d2414cef474b99856d9a9`.

