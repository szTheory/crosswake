---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 02
subsystem: ios-shell-generation
tags: [release-gate, xcodebuild, ci-step, contract-test, release-0.2.13, negative-control]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: 200-01 default generation fix (the settings file is written) on fix/default-ios-generation-builds
provides:
  - script/verify_default_ios_generation_build.sh, a pre-release build gate for both default iOS forms with an in-run negative control and one verdict line
  - contract test with a fake xcodebuild (16 tests) and a CI step pin with a removal control
  - blocking step "Build default-generated iOS project (pre-release gate)" in phase79-ios-proof (local mode)
  - measured red on the 0.2.12 generator and green on the fix, for the local form and the no-flag remote form built against the public mirror
affects: [200-03, 200-05]

actuals:
  tokens: 6200
  tasks: 3
  commits: 4
# commits: 1 fix-branch commit (3696f38c, ledger base 53f4338d) plus 3 evidence commits on the docs branch
# (dbe33d4d, 521905f3, 97d885c7; ledger base 2a95e0e8). The summary and tracking commits follow this file.
plan_head_before: 2a95e0e874b91b5cb06a73ee158600343b75f90f
plan_head_after: 97d885c777d6ee39c5b31286b18c396b41c4e066
fix_branch: fix/default-ios-generation-builds
fix_branch_head_before: 53f4338d8bf0e9d0727327abb39a573bb9059548
fix_branch_head_after: 3696f38cd8e4e158a6339eca1984d7b63dd03403

tech-stack:
  added: []
  patterns:
    - "gate with an in-run negative control: the same build with the file removed must fail with the named error, or the gate fails (negative_control_passed)"
    - "remote-mode PASS needs a parsed resolved version equal to the requested one; an unreadable line is ERROR, never PASS"
    - "first_error scrubs the work, project and source roots (given and cd -P form) and HOME, so evidence carries no local path"

key-files:
  created:
    - script/verify_default_ios_generation_build.sh
    - test/crosswake/shell/default_ios_build_script_test.exs
  modified:
    - .github/workflows/crosswake-ci.yml

key-decisions:
  - "The CI step runs local mode only; the no-flag remote form stays a release-time rehearsal (needs network, and on a release PR the candidate core is not on the mirror yet)"
  - "Managed-host refusal (not_default_path) checks both <project>/.crosswake and <project>/../.crosswake, because the real managed metadata lives one level above the Xcode project (native/ios/.crosswake)"
  - "The control copy keeps the same directory depth as the built project, so a --local project's relative package path stays valid in the control"
  - "Three reasons beyond the plan's list, all ERROR and closed: generate_failed, bad_project, work_root_failed"

requirements-completed: [REL-08]

coverage:
  - id: D1
    description: "Local-form gate fails on a project from the exact 0.2.12 generator and passes with the negative control detected on the fix"
    requirement: REL-08
    verification:
      - kind: other
        ref: "bash script/verify_default_ios_generation_build.sh [--source-root main-checkout]; evidence lines before: and after: in 200-EVIDENCE/default-ios-build-200.txt (rc 1 build_failed exit 65, then rc 0 control_rc=65 detected)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No-flag remote form (the post-publish clean-room's form) fails on 0.2.12 generator output and passes on the fix resolving the public mirror at 0.2.12"
    requirement: REL-08
    verification:
      - kind: other
        ref: "bash script/verify_default_ios_generation_build.sh --remote-version 0.2.12; evidence lines remote-rehearsal-before: and remote-rehearsal: (rc 1 build_failed, then rc 0 resolved=0.2.12 control=detected)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The gate cannot pass while asserting nothing, and cannot edit a given project"
    requirement: REL-08
    verification:
      - kind: unit
        ref: "test/crosswake/shell/default_ios_build_script_test.exs (16 tests, 0 failures); four script mutants each turned it red"
        status: pass
    human_judgment: false
  - id: D4
    description: "phase79-ios-proof runs the gate as a blocking step; leaf count, manifest and Phase 170 pins unchanged"
    requirement: REL-08
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase165_ci_integrity_test.exs plus the step pin and its removal control (47 ran, 0 failures); check_ci_leaf_manifest.py --self-test and --maximum-shape rc 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "Fix branch is complete and green locally: full suite, release scanner, format, compile, adoption scan"
    requirement: REL-08
    verification:
      - kind: integration
        ref: "script/mix_test_gate.sh --min 3176 --min-total 3252 (ran=3176 total=3252 failures=0); elixir script/check_release_workflow_integrity.exs (106 of 106, 0 failed); 200-EVIDENCE/suite-200.txt"
        status: pass
    human_judgment: false

duration: about 20 min (first commit 02:44Z; the full suite is 10 min of that)
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 02: Pre-release build gate for both default iOS forms Summary

**`script/verify_default_ios_generation_build.sh` builds a default-generated iOS project with the release clean-room flags, repeats the build with the settings file removed to prove it can see the defect, and was measured failing on the exact 0.2.12 generator and passing on the fix in both the local form and the no-flag remote form built against the public mirror; it is now a blocking step in `phase79-ios-proof`.**

## Performance

- **Duration:** about 20 min (first commit 02:44Z, last gate 02:58Z; the full suite is 10 of those minutes)
- **Tasks:** 3 (one tracer, two auto)
- **Files:** 3 on the fix branch (2 new, 1 workflow edit); 2 evidence files on the docs branch

## What was checked and what happened

- **Local form, before.** The main checkout is the 0.2.12 generator (`lib` and `priv` equal tag `hex-v0.2.12`, checked with `git diff --quiet`, `generator_dirty=no`). The gate returned rc 1, `build_rc=65`, `build_seconds=2`, `reason=build_failed`, and the first error names `CrosswakeHostSettings.xcconfig`. Whole run 3 s.
- **Local form, after.** On the fix branch worktree (generator `53f4338d`): rc 0, `build_rc=0 build_seconds=11`, `control_rc=65 control=detected verdict=PASS`. Whole run 13 s.
- **No-flag remote form, before.** `--source-root` the main checkout, `--remote-version 0.2.12`: rc 1, `remote_from=0.2.11 remote_min=0.2.12`, `build_rc=65`, `reason=build_failed`, first error names the settings file. Whole run 4 s.
- **No-flag remote form, after.** Same flag on the fix: rc 0, `remote_from=0.2.12 remote_min=0.2.12 resolved=0.2.12`, `build_seconds=11`, `control_rc=65 control=detected verdict=PASS`. Whole run 14 s. The public mirror has tag `v0.2.12` (`git ls-remote`). This read the public mirror only; nothing was written, pushed or published.
- **Contract test.** 16 tests on a fake xcodebuild, 0 failures: PASS with the given project byte-unchanged and the release clean-room flags on both builds; `build_failed` with a scrubbed first error; `negative_control_passed`; `resolved_version_mismatch`; `resolved_unreadable` (exit 2, no `verdict=PASS` anywhere in the output); `package_resolution_failed`; `local_copy_unsupported` and `not_remote_form` (no build attempted); `not_default_path`; three `bad_usage` cases; `bad_source`; and the CI pin with a removal control and a `continue-on-error` control, plus a check that `remote-version` is not wired into CI.
- **Does the test have teeth.** Four mutants of the script each turned the contract test red (resolved check removed, version comparison removed, control keeping the settings file, build flags changed); the unmutated script was restored and compared byte for byte. The first run was green with no red run, so the mutants are the evidence that the tests can fail.
- **Fix-branch gates.** Full suite `ran=3176 total=3252 excluded=76 failures=0`, equal to the floor (3155 + 21 ran, 3231 + 21 total), about 10 min. Release scanner 106 of 106, 0 failed. Leaf manifest self-test and maximum-shape both rc 0, `script/ci_leaf_manifest.json` unchanged. `mix format --check-formatted`, `mix compile --warnings-as-errors --force` and `mix crosswake.adoption_context.scan` rc 0. The branch carries 3 commits and 7 paths, none under `.planning/`.
- **Not checked here.** Hosted macOS runner time and cost of the new step (200-03 measures them before the merge; the local build is 11 s of a 13 s run, the hosted figure is unknown). The 0.2.13 core itself: the remote rehearsal proves the generated remote form compiles against the public 0.2.12 core, not 0.2.13, which the post-publish clean-room still proves. Nothing was pushed, no PR opened, no tag, publish or dispatch.

## Accomplishments

- A gate that would have caught 0.2.12 before any irreversible step, for both default forms, with one verdict line and exit codes 0, 1 and 2.
- The gate cannot score absence as success: PASS needs a built project, a detected negative control and, in remote mode, a parsed resolved core version equal to the requested one.
- A blocking CI step with a pin that fails if the step is removed or made non-blocking; no new job, so the leaf count and manifest are unchanged.
- The remote-form rehearsal is the same script and flag that 200-05 runs on the 0.2.13 release PR head.

## Task Commits

1. **Task 1 (tracer): the gate in local mode, red on 0.2.12 and green on the fix** - script written to the working tree and committed with Task 2 as planned; evidence on the docs branch `dbe33d4d`
2. **Task 2: remote-form rehearsal both ways, contract test, CI step** - fix branch `3696f38c` (`ci(ios): build the default-generated iOS project before any release`); evidence on the docs branch `521905f3`
3. **Task 3: full local gates** - evidence on the docs branch `97d885c7`

The fix branch `fix/default-ios-generation-builds` is local at `~/projects/crosswake-200-wt`, 3 commits ahead of `origin/main` 1dcdaad8 (`05b440e6` fix, `53f4338d` guide, `3696f38c` ci). It is not pushed.

## Files Created/Modified

- `script/verify_default_ios_generation_build.sh` - the gate (new, mode 755)
- `test/crosswake/shell/default_ios_build_script_test.exs` - contract test and CI step pin (new, module `Crosswake.Shell.DefaultIOSBuildScriptTest`)
- `.github/workflows/crosswake-ci.yml` - step `Build default-generated iOS project (pre-release gate)` after `Verify iOS Shell`, and a second remediation line in the summary step
- `.planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/default-ios-build-200.txt` and `suite-200.txt` (docs branch)

## Decisions Made

- The CI step uses local mode; remote mode is a release-time rehearsal and is not in CI (contract test pins that `remote-version` is absent from the workflow).
- `not_default_path` checks `<project>/.crosswake` and `<project>/../.crosswake`: the real managed metadata is `native/ios/.crosswake/ios_host_generation.json`, one level above the Xcode project, so checking only inside the project would never fire on a real declared host.
- The negative-control copy sits at the same directory depth as the built project so a local project's relative package path stays valid there.
- Added three closed ERROR reasons the plan did not list (`generate_failed`, `bad_project`, `work_root_failed`) so those failures end in the one-line verdict and not in a raw shell error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in plan facts] The bare leaf-manifest command is a usage error**
- **Found during:** Task 2 (verify command 4) and Task 3
- **Issue:** The plan runs `python3 script/check_ci_leaf_manifest.py` with no arguments after `--self-test`. The script requires `--self-test` or `--maximum-shape`, so the bare form exits 2 with a usage message and checks nothing.
- **Fix:** The leaf-manifest evidence is `--self-test` (which includes the production-contract test) plus the form `script/check_phase165_efficient_ci.sh` already uses: `--maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml --needs-fixture test/fixtures/ci/maximum-shape-needs.json` (pass, jobs=38). Both rc 0. Also run: `script/list_merge_blocking_checks.py --emitters` rc 0, and the Phase 165 CI integrity tests.
- **Files modified:** evidence only (`default-ios-build-200.txt` note line, `suite-200.txt` detail line)
- **Verification:** the plan's literal verify clause was run and exits 2; the measured forms pass.
- **Committed in:** `521905f3`, `97d885c7`

**2. [Rule 1 - Bug in plan facts] Test floor counting**
- **Found during:** Task 3
- **Issue:** `grep -c 'test "'` counts 4 in the 200-01 test file, but its comprehension generates two tests, so the file has 5.
- **Fix:** The floor uses the true count: 3155 + 21 ran and 3231 + 21 total (5 + 16). Measured values equal the floor exactly. The arithmetic is the `floor:` line of `suite-200.txt`.
- **Committed in:** `97d885c7`

---

**Total deviations:** 2 auto-fixed (both plan-fact corrections in verification wording). **Impact on plan:** none on the gate or the fix. The plan's "six references" wording carried from 200-01 did not appear in any check of this plan; the measured shape (four base configurations, six mentions) is the one recorded in 200-01.

## Issues Encountered

- The first contract-test run was green on the first try. To avoid absence scored as success, four deliberate mutants of the script were run and each turned the test red; the first mutant batch showed that changing the xcodebuild flags was not caught because the fake ignored its arguments, so the test now logs the fake's argv and asserts the clean-room flags on both builds (a flags mutant is then red).
- `mix format` reformatted the new test file (formatting only).
- Limitation to carry into 200-05: `upToNextMajorVersion` resolves the newest 0.x tag on the mirror, so `--remote-version` must be the newest mirror tag (0.2.12 until 0.2.13 is published). Once 0.2.13 is public, a rehearsal at 0.2.12 would report `resolved=0.2.13` and FAIL as `resolved_version_mismatch`, which is the intended refusal to claim a core it did not name.

## Known Stubs

None.

## Self-Check

## Self-Check: PASSED

The script, the test and the workflow edit exist in the worktree and are committed in `3696f38c`; the commits `3696f38c` (fix branch) and `dbe33d4d`, `521905f3`, `97d885c7` (docs branch) are ancestors of their branch heads; both evidence files exist; the fix branch diff against `origin/main` lists exactly seven paths with none under `.planning/`; nothing is pushed.

## Next Phase Readiness

Plan 200-03 is ready: it pushes the fix branch as a PR, measures the hosted time and cost of the new `phase79-ios-proof` step with `script/ci_cost_report.sh`, and merges under the standing exception only with Crosswake CI green on the exact head. The privacy scan runs before that push and again after any new commit. On main the gate's only finding is the defect the same PR fixes, so it blocks nothing else.

---
*Phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds*
*Completed: 2026-11-09*
