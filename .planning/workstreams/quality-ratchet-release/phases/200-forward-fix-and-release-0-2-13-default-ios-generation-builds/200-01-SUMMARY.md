---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 01
subsystem: ios-shell-generation
tags: [mix-task, xcodebuild, regression-test, release-0.2.13, ios]

requires:
  - phase: 199-release-0-2-12
    provides: the 0.2.12 PARTIAL run whose iOS clean-room proof exposed the defect
provides:
  - default `mix crosswake.gen.shell ios` (no-flag remote and `--local`) writes the CrosswakeHostSettings.xcconfig its project references
  - regression test on the real generator for both default forms, with a negative control
  - measured red on the 0.2.12 generator and green after the fix, including one real `--local` xcodebuild
affects: [200-02, 200-03, 200-04, 200-05]

actuals:
  tokens: 2400
  tasks: 2
  commits: 4
# commits: 2 fix-branch commits (05b440e6, 53f4338d; ledger base 1dcdaad8) plus 2 evidence commits on the docs branch
# (f2b0ce1f, 37d5bae0; ledger base 7abcfe6c). The summary and tracking commits follow this file.
plan_head_before: 7abcfe6ca3e88c414b596ecef6f8d836269ee975
plan_head_after: 37d5bae0264b36fa171d62ec9a7395c8ca2a1b70
fix_branch: fix/default-ios-generation-builds
fix_branch_head_before: 1dcdaad8dea087ddebd62bf7ca0515988d2d3f9c
fix_branch_head_after: 53f4338d

tech-stack:
  added: []
  patterns:
    - "default-path settings file is a host-owned scaffold written once through ensure_file/2, never a managed output"
    - "reference-integrity test resolves PBX group path chains with the existing Crosswake.Shell.PBXProject parser"

key-files:
  created:
    - test/mix/tasks/crosswake_gen_shell_default_references_test.exs
  modified:
    - lib/crosswake/shell/ios_host_generation.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - guides/native_shell.md

key-decisions:
  - "Write the settings file on the default path (placeholder identity dev.crosswake.shell, Automatic signing, empty team) rather than dropping the references: the pbxproj also sets PRODUCT_BUNDLE_IDENTIFIER from it, and no template or hash fixture moves"
  - "Evidence records the measured count of 4 baseConfigurationReference entries and 6 file-name mentions; the plan called all 6 base configuration references"

requirements-completed: [REL-08]

coverage:
  - id: D1
    description: "Both default forms of gen.shell ios write every file their Xcode project references, including CrosswakeHostSettings.xcconfig"
    requirement: REL-08
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake_gen_shell_default_references_test.exs (5 tests, 0 failures after the fix, 5 failures before)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The --local default project builds with the release clean-room xcodebuild flags (exit 65 before, exit 0 after)"
    requirement: REL-08
    verification:
      - kind: other
        ref: "xcodebuild -project ... -scheme CrosswakeShell -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build; evidence lines red: xcodebuild and green: xcodebuild"
        status: pass
    human_judgment: false
  - id: D3
    description: "Output for a host that declares :ios_host is unchanged"
    requirement: REL-08
    verification:
      - kind: unit
        ref: "8 declared-path test files, ran=61 before and after, no template, hash fixture or declared test edited (git diff origin/main HEAD)"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/native_shell.md says what the default path writes and that it is host-owned"
    requirement: REL-08
    verification:
      - kind: unit
        ref: "test/crosswake/guides (ran=258, 0 failures)"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 01: Default iOS generation writes the settings file it references Summary

**The default `mix crosswake.gen.shell ios` now writes `CrosswakeHostSettings.xcconfig` once, so a plain generated project builds (xcodebuild exit 65 before, 0 after), proven by a regression test that failed on the 0.2.12 generator and passes on the fix.**

## Performance

- **Duration:** about 35 min
- **Completed:** 2026-11-09T02:40Z
- **Tasks:** 2
- **Files modified:** 4 on the fix branch (3 lib/guide, 1 new test); 1 evidence file on the docs branch

## What was checked and what happened

- Source: fix branch cut from `origin/main` `1dcdaad8dea087ddebd62bf7ca0515988d2d3f9c`; `lib` and `priv` are equal to tag `hex-v0.2.12` (yes), so the red run is the 0.2.12 behavior.
- Red, on the unfixed tree: the new test file ran 5 tests with 5 failures (gate `rc=2 ... verdict=FAIL reason=mix_rc`); both default-form tests and the negative control reported `["CrosswakeHostSettings.xcconfig"]` missing. A generated `--local` project had 4 `baseConfigurationReference` entries and 6 mentions of the file with the file absent, and the release clean-room xcodebuild flags failed with exit 65 in 2 s: `Unable to open base configuration reference file '<work>/.../CrosswakeHostSettings.xcconfig'`.
- Green, after the fix: the same test file ran 5 tests, 0 failures. The same `--local` build ran in 8 s and ended `BUILD SUCCEEDED`, exit 0.
- Declared-path guard: the 8 declared-path test files ran 61 tests, 0 failures, before and after. The diff against `origin/main` touches no template, no production hash fixture and no declared-path test. A wider run of `test/mix` and `test/crosswake/shell` also passed (396 ran, 0 failures).
- Guide tests (`test/crosswake/guides`): 258 ran, 0 failures. `mix format --check-formatted` rc 0. `mix compile --warnings-as-errors --force` rc 0.
- Not checked here: the no-flag remote form is covered by the reference test only; its real build against the public mirror is plan 200-02. Nothing was pushed, no PR opened, no tag, publish or dispatch.

## Accomplishments

- `Crosswake.Shell.IOSHostGeneration.render_default_settings/0` renders the same `CrosswakeHostSettings.xcconfig.eex` with `dev.crosswake.shell`, `Automatic` and an empty team; `render_settings/1` (the declared path) now shares one private evaluator and produces the same bytes.
- `generate_ios_shell/6` writes the file with `ensure_file/2` only when no `:ios_host` outputs exist, so a host edit survives a second run and the default path stays outside managed-output tracking (no `.crosswake/ios_host_generation.json`).
- The regression test parses the generated `project.pbxproj` with `Crosswake.Shell.PBXProject`, walks every PBXGroup path chain from the main group, requires at least 10 `<group>` file references to exist, requires 4 base configurations that each resolve to the settings file, checks the remote or local package reference per form, and includes a negative control, a settings-content test and a scaffold-once test.
- The guide states what the default path writes, that it is a host-owned scaffold and not a managed output, and that declaring `:ios_host` hands identity and signing to Crosswake.

## Task Commits

1. **Task 1 (tracer): default generation, regression test and real xcodebuild** - fix branch `05b440e6` (`fix(gen.shell): write the settings file the default iOS project references`); evidence on the docs branch `f2b0ce1f`
2. **Task 2: guide sentence, guide tests, format and compile** - fix branch `53f4338d` (`docs(guides): say what default iOS generation writes`); evidence on the docs branch `37d5bae0`

The fix branch `fix/default-ios-generation-builds` is local at `~/projects/crosswake-200-wt`, 2 commits ahead of `origin/main`, with no `.planning/` path. It is not pushed.

## Files Created/Modified

- `test/mix/tasks/crosswake_gen_shell_default_references_test.exs` - regression test on the real generator (new)
- `lib/crosswake/shell/ios_host_generation.ex` - shared evaluator and `render_default_settings/0`
- `lib/mix/tasks/crosswake.gen.shell.ex` - default-path write in `generate_ios_shell/6`
- `guides/native_shell.md` - default-path paragraph
- `.planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/default-ios-fix-200.txt` - before and after lines (docs branch)

## Decisions Made

- Write the file rather than drop the references: the project template also sets the bundle identifiers from the settings file, so dropping the references would leave an empty bundle id, and the 0.2.11 literal was `dev.crosswake.shell`. No template, `@template_version` or hash fixture changes.
- The test asserts exactly 4 base configurations (two targets, Debug and Release). If the project template ever adds a target, that number is a deliberate pin to update with it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in plan facts] "six baseConfigurationReference entries" is four**
- **Found during:** Task 1 (counting references on the unfixed `--local` project)
- **Issue:** The plan, its behavior list and its first verify command say exactly 6 `baseConfigurationReference` entries. Measured on the real output: 4 `baseConfigurationReference` entries; the 6 is the total number of mentions of `CrosswakeHostSettings.xcconfig` (4 base configurations, 1 file reference, 1 group child). The context's "six references" is the mention count.
- **Fix:** The test pins 4 base configurations (each resolved to an existing file). The evidence line is `red: refs baseConfigurationReference=4 xcconfig_mentions=6 xcconfig=absent`, and a `note:` line explains the difference.
- **Verification:** the plan's first automated verify command, run literally, fails on `baseConfigurationReference=6` (exit 1); every other clause of it and all other verify commands pass. The measured form of that clause passes. Recording `=6` would have been false.
- **Files modified:** test file, evidence file
- **Committed in:** `05b440e6`, `f2b0ce1f`

---

**Total deviations:** 1 auto-fixed (1 plan-fact correction). **Impact on plan:** none on the fix; the evidence is the measured value. Later plans that cite "six base configuration references" should say "six mentions, four base configurations".

## Issues Encountered

None beyond the deviation above. `mix format` rewrote the new test file once (formatting only).

## Self-Check

## Self-Check: PASSED

All four code/guide files exist in the worktree, the four commits (`05b440e6`, `53f4338d`, `f2b0ce1f`, `37d5bae0`) are ancestors of their branch heads, the evidence file exists, and the fix branch diff against `origin/main` lists exactly the four expected paths (no `.planning/` path).

## Next Phase Readiness

Plan 200-02 is ready: the fixed worktree (`~/projects/crosswake-200-wt`, branch `fix/default-ios-generation-builds`, head `53f4338d`) is the base for the build-gate script, which must show red on the 0.2.12 behavior and green here, and must build the no-flag remote form against the public mirror.

---
*Phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds*
*Completed: 2026-11-09*
