---
phase: 199-release-0-2-12
plan: 07
subsystem: release
tags: [release-gates, privacy-scan, merge, proposal-run, release-pr-head, predicate, controls, mutants, rel-07]

requires:
  - phase: 199-release-0-2-12
    provides: "199-01 and 199-03 to 199-06 gate pipeline on ci/199-release-gates; D-01..D-08 in 199-DECISIONS.md"
provides:
  - "The per-step approval gate pipeline is on main (PR 278, merge commit a9c4ff74) after green CI on its exact head"
  - "A real proposal run (Release Please run 42387805006) showing ordinary pushes still flow and the hosted-runner environment preflight reads PASS"
  - "scripts/release-pr-head-199.sh, the one shared zero-hand-edit predicate for release PR heads, proven by 19 controls and 11 mutant runs"
  - "PR 236 (0.2.12) and PR 262 (threadline 0.1.1) refreshed on the new main, each passing the predicate with CI green on its head"
affects: [199-08, 199-13]

plan_head_before: c897b689fe05b21cf68c9533885b4b9dd88761e0
plan_head_after: 04e8160a38e2a06724a1f574791ffe32b207448e
commits: 2

actuals:
  tokens: 21000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "scoped privacy scan: whole-file for new files; for pre-existing files, hit set no larger than origin/main and added lines clean"
    - "predicate rules each end with a trailing rule: comment so a mutant run can delete one rule at a time"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/scripts/release-pr-head-199.sh
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/scripts/release-pr-head-controls-199.sh
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/suite-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/privacy-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/ci-pipeline-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/proposal-run-199.txt
  modified:
    - test/crosswake/release_candidate/mirror_release_tag_test.exs

key-decisions:
  - "Privacy scan scoped (orchestrator decision): five pre-existing files already on main carry email-shaped text; recorded as same hit count as origin/main plus clean added lines, new files whole-file clean"
  - "actionlint SC2129 at crosswake-ci.yml:869 is pre-existing and identical on origin/main; recorded, not edited"
  - "Evidence files from Tasks 2 and 3, the privacy rescan lines and the two scripts stay uncommitted for 199-08, as the plan directs"

requirements-completed: []

coverage:
  - id: D1
    description: "Gate pipeline merged to main after local gates, privacy scan and green CI on the exact head"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "ci-pipeline-199.txt: PR 278 head 04e8160a, run 42386280292, 39 of 39 checks not red, merged a9c4ff74 with --match-head-commit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ordinary push after the merge flows: guard passes with linked_release not true, tag gate skipped, Release Please succeeds, all publishers and the mirror tag check skipped, no pending deployment"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "proposal-run-199.txt: run 42387805006 job lines; pending_deployments: 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hosted-runner anonymous environment read passes before any release depends on it"
    requirement: REL-07
    verification:
      - kind: integration
        ref: "proposal-run-199.txt: env_preflight_ci: PASS run=42387805006; env_preflight: rc=0 locally"
        status: pass
    human_judgment: false
  - id: D4
    description: "Release-PR-head predicate proven both ways and used on PR 236 and PR 262"
    requirement: REL-07
    verification:
      - kind: other
        ref: "bash scripts/release-pr-head-controls-199.sh: 19 of 19 ok, verdict=PASS (bash 5.2.37 and /bin/bash 3.2.57); 11 rph-mutant lines each rc=1 verdict=FAIL; live runs exit 0 on both PRs"
        status: pass
    human_judgment: false

duration: "about 1h 20m this session (15:30Z to 16:10Z, 2026-11-07) after a first attempt stopped on a safety-check denial"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 07: Gate Pipeline Landed, Proposal Path and Release PR Heads Proven Summary

**The per-step release approval gates are on main (PR 278, merge commit a9c4ff74), the first post-merge Release Please run flowed with a PASS hosted-runner environment preflight, and a git-only predicate proven by 19 controls and 11 mutants shows PR 236 (0.2.12) and PR 262 (threadline 0.1.1) are untouched Release Please commits with CI green on their heads.**

## What was checked

- Local gates at `c897b689` (full suite 3231 total, 3155 ran, 0 failures, floor 3148/3224; scanner 106 of 106, 0 failed; shellcheck on the three new scripts rc 0; companion attestation harness 9 tests OK; format, `compile --warnings-as-errors` and `docs.sync --check` rc 0). actionlint reported only SC2129 at `crosswake-ci.yml:869`, which is byte-identical on `origin/main` and gives rc 0 with that one code ignored.
- Privacy scan (scoped, see Deviations): new files and PR body clean over the whole file; five pre-existing files keep the same single email-shaped hit as `origin/main`; every line this branch adds to them scans clean. Final recorded line `privacy: rc 0`, rescanned after the evidence commit.
- PR 278: Crosswake CI green on the exact head `04e8160a` (run 42386280292, 39 of 39 checks, none red). CI ran on the synthetic merge `40e9cbf9`, not on the head. Merged with a merge commit pinned to the head (`gh pr merge --merge --match-head-commit`): `a9c4ff74` at 2026-11-07T15:44:03Z. `delete_branch_on_merge` is false and no branch was deleted.
- Cost report (advisory): 154 billable minutes (baseline about 250), 18 minutes wall clock (baseline 20 to 44), critical path `proof-requires-example-host`, 2 full-suite jobs (baseline about 10). No new duplicated full-suite run or uncached job flagged.
- Proposal run 42387805006 on the merge commit: guard success, `release-tag-gate` skipped, `release-please` success, every `publish-*`, the mirror tag check and all proofs skipped, rollups success, `pending_deployments: 0`. The guard log shows `release-env: verdict=PASS` for all four environments on a hosted runner (`env_preflight_ci: PASS run=42387805006`); no ADVISORY warning.
- Predicate: 19 of 19 controls ok under bash 5.2.37 and `/bin/bash` 3.2.57; 11 mutant runs (always-PASS stub and ten one-rule-deleted copies) each exit 1 with verdict FAIL and exactly the WRONG controls the plan names (17 for the stub). Live: PR 236 head `efbc7912` over base `a9c4ff74`, 10 changed paths in a 13-path managed set, PASS, CI green (39 checks, ran on `f96a2856`); PR 262 head `76aee3f3`, 3 paths, PASS, CI green (39 checks, ran on `2cb4c5e8`). Authors logged as `szTheory`, never a condition. Local `check_release_environments.sh` rc 0.

## What is unknown, and why

- The guard output `linked_release` is not echoed in the job log; "not true" is inferred from `release-tag-gate` being skipped (its condition needs it true) and from the script emitting `linked_release=false` on this non-release push.
- The predicate cannot see what its stated residuals hide (a section omitting or reordering bullets Release Please would write, an exactly rendered qualifying commit Release Please left out, a hand-chosen heading date, a byte-identical recommit). The no-push rule on release branches covers those.

## Task Commits

1. **Task 1 (tracer): local gates, scoped privacy scan, push, PR** - `19ff7859` (test: non-email-shaped fixture identity in the mirror tag test) and `04e8160a` (docs: record gates and scoped privacy scan); PR 278 opened.
2. **Task 2: CI green, cost, merge pinned to head** - no commit by design; `ci-pipeline-199.txt` is left uncommitted for 199-08. Merge commit on main: `a9c4ff74`.
3. **Task 3: proposal run, preflight, predicate** - no commit by design; `proposal-run-199.txt` and the two scripts are left uncommitted for 199-08 Task 1.

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixture identity matched the privacy email class**
- **Found during:** Task 1 (privacy scan, rc 1)
- **Issue:** `mirror_release_tag_test.exs`, added by 199-05, set git author and committer to an email-shaped value.
- **Fix:** replaced with `fixture-no-address` (git accepts it); 11 tests rerun through the shared gate, 0 failures; `mix format` clean.
- **Files modified:** test/crosswake/release_candidate/mirror_release_tag_test.exs
- **Commit:** `19ff7859`

**2. [Rule 1 - Bug] Predicate repeat-rule extraction pattern**
- **Found during:** Task 3 (first control run showed `changelog_earlier_release_bullet` passing)
- **Issue:** my first `sed` expression for the commit link in a bullet was unbalanced and then matched one parenthesis too few, so the earlier-release rule never fired. The control caught it, as designed.
- **Fix:** corrected the expression in the predicate (not the control); all 19 controls then ok.
- **Files modified:** scripts/release-pr-head-199.sh (uncommitted, 199-08)

### Plan variances

- **Scoped privacy scan (orchestrator decision).** The plan's whole-file scan returned rc 1 on five files already on `origin/main` (a public SSH remote URL and `example.invalid` git-config fixtures), none introduced here. `privacy-199.txt` records the whole-file result, then the scoped rule and its per-file counts, then `privacy: rc 0`. The plan's literal verify (last line `privacy: rc 0`) is satisfied only under this reading.
- The plan's zsh `files=(${(f}...)` form was replaced by a plain `git diff --name-only` list written to a file and passed as separate absolute-path arguments.
- Only the one test file was rerun after the fix commit; the full-suite verdict is the one measured at `c897b689`.

**Total deviations:** 2 auto-fixed (Rule 1) and 3 variances. **Impact:** no scope change; no gate loosened except the scoped privacy rule the orchestrator set.

## Issues Encountered

- First attempt stopped on an automatic safety-check denial (zsh-specific expansion); nothing was committed or pushed then.

## Known Stubs

None.

## Threat Flags

None. The two scripts are phase-local, read git and (live mode) `gh pr view`, and write only under their own temp directory.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-08. PRs 236 and 262 were read only; nothing was merged, tagged, published or approved, and no release branch was touched.
- Still uncommitted for 199-08 to commit: `ci-pipeline-199.txt`, `proposal-run-199.txt`, the privacy rescan lines in `privacy-199.txt`, and the two scripts. The local branch `ci/199-release-gates` is now behind main by PR 278's merge commit.
- PR 236 sits on base `a9c4ff74` with head `efbc7912`, 0.2.12, CI green. Re-read both heads and CI in 199-08 before any gate display.

## Self-Check: PASSED

- Files present: both scripts (executable), `suite-199.txt`, `privacy-199.txt`, `ci-pipeline-199.txt`, `proposal-run-199.txt`.
- Commits `19ff7859` and `04e8160a` are on `ci/199-release-gates` and on main via `a9c4ff74`; the measured count from the plan ledger is 2.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
