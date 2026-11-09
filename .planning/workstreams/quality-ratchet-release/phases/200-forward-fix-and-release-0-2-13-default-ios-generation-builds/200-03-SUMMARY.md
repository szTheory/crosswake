---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 03
subsystem: release-train
tags: [pull-request, ci, hosted-measurement, standing-merge-exception, release-0.2.13, privacy-scan]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: 200-01 default generation fix and 200-02 pre-release build gate on fix/default-ios-generation-builds
provides:
  - fix PR 282 merged to main as merge commit e8d44c6c (parents 1dcdaad8 and the CI-green head 3696f38c)
  - hosted measurement of the new gate step (32 s; phase79-ios-proof 122 s against a 104 s baseline) and the run cost (174 billable min against about 250)
  - issue 281 comment with the diagnosis and the fix PR
  - the build gate is merge-blocking on main from this merge
affects: [200-04, 200-05, 200-09]

actuals:
  tokens: 5800
  tasks: 3
  commits: 3
# commits: MEASURED from the ledger (git rev-list --count 576140be..HEAD, taken before this summary and tracking commits):
# 3 evidence commits on the docs branch (6e281e6f, 6dc768d8, 18f6b7e4). The fix branch took no new commit in this plan;
# the merge commit e8d44c6c on main was created by GitHub. The summary and tracking commits follow this file.
plan_head_before: 576140bed9a5a4148f5299a82710efa14d8356ac
plan_head_after: 18f6b7e4f7a55252d815f542daa4a13e0022c35c
fix_pr: 282
fix_branch: fix/default-ios-generation-builds
fix_head: 3696f38cd8e4e158a6339eca1984d7b63dd03403
ci_run_id: 42554142308
ci_ran_on: 6e511a9a83f2f40872357ebf73a1a9fb8a4c75e7
merge_oid: e8d44c6c907a5f16d333c62df6b8d6dcd4d32e3c

tech-stack:
  added: []
  patterns:
    - "merge only on the head CI passed: head and CI conclusion re-read immediately before, deleteBranchOnMerge read false, gh pr merge --merge --match-head-commit"
    - "a measurement is read from the run's own job log and step timestamps, never typed"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/privacy-200.txt
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/fix-pr-200.json
  modified: []

key-decisions:
  - "The merge ran under the AGENTS.md standing exception for a PR to main: CI green on the exact head, merge commit pinned to that head, auto-delete read off first. The remote fix branch was left in place (its deletion needs its own gate)."
  - "The two advisory cost observations are recorded as flags, not as a reason to hold the merge: the cost report never gates."

requirements-completed: [REL-08]

coverage:
  - id: D1
    description: "Fix PR scanned clean before the push, opened with no planning path, and merged on the exact CI-green head"
    requirement: REL-08
    verification:
      - kind: other
        ref: "privacy-193.sh rc 0 over 7 paths plus the PR body (privacy-200.txt run 1); gh pr view 282 files under .planning/ = 0; merge commit second parent equals head_oid; merge commit is an ancestor of origin/main"
        status: pass
    human_judgment: false
  - id: D2
    description: "The gate passed on the hosted macOS runner with its control build detected, measured before it became merge-blocking"
    requirement: REL-08
    verification:
      - kind: other
        ref: "run 42554142308 job phase79-ios-proof log: default-ios-build line mode=local build_rc=0 control_rc=65 control=detected verdict=PASS; step 32 s, job 122 s vs 104 s baseline (run 42388086844)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Run cost recorded against the baseline and issue 281 points at the fix"
    requirement: REL-08
    verification:
      - kind: other
        ref: "bash script/ci_cost_report.sh 42554142308 (174 billable min, 16.4 min wall, 2 full-suite jobs); issue comment https://github.com/szTheory/crosswake/issues/281#issuecomment-6731425802"
        status: pass
    human_judgment: false

duration: about 20 min (03:01Z to 03:21Z; 18 of those minutes were waiting for the hosted CI run)
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 03: Land the fix PR and measure the gate on the hosted runner Summary

**PR 282 (default iOS generation writes the settings file it references, plus the pre-release build gate) was merged to main as merge commit `e8d44c6c` after Crosswake CI was green on its exact head `3696f38c`; the new gate step passed on the hosted macOS runner with its control build detected in 32 seconds, the run cost 174 billable minutes against a baseline of about 250, and issue 281 now carries the diagnosis and the fix link.**

## Performance

- **Duration:** about 20 min (first action 03:01Z, merge 03:20:47Z; CI ran 03:02Z to about 03:20Z)
- **Tasks:** 3 (one tracer, two auto)
- **Files:** 2 evidence files on the docs branch; the PR itself changed 7 paths, none under `.planning/`

## What was checked and what happened

- **Scan before the push.** `privacy-193.sh` over the 7 changed paths in the worktree plus the PR body: `privacy: clean files 8`, rc 0, head `3696f38c`. No pre-existing file needed the scoped rule. The branch had not moved since 200-02 (`origin/main` still `1dcdaad8`, 3 commits ahead), so no merge and no gate rerun were needed.
- **Push and PR.** `git push -u origin refs/heads/fix/default-ios-generation-builds:refs/heads/fix/default-ios-generation-builds` (feature branch, after the clean scan), then PR 282 against main. `gh pr view 282` reported 0 paths under `.planning/`. The docs branch `docs/199-release-0-2-12` was not pushed.
- **CI on the exact head.** Run 42554142308 (`pull_request`, `headSha` 3696f38c): 39 jobs, 39 success, none skipped or red, nothing re-run. The `phase79-ios-proof` checkout log reads `HEAD is now at 6e511a9 Merge 3696f38c... into 1dcdaad8...`, so **CI ran on the synthetic merge commit `6e511a9a83f2f40872357ebf73a1a9fb8a4c75e7`, not on the head**; the head that was merged is `3696f38cd8e4e158a6339eca1984d7b63dd03403`.
- **The gate on the hosted runner.** Verbatim line from the job log: `default-ios-build: mode=local project=generated generator=6e511a9a83f2f40872357ebf73a1a9fb8a4c75e7 generator_dirty=no remote_from=- remote_min=- resolved=- build_rc=0 build_seconds=29 control_rc=65 control=detected verdict=PASS first_error=none`. The step ran 03:03:55Z to 03:04:27Z, **32 seconds** (the build inside it took 29 s on the hosted runner, 11 s on the developer machine). The control build failed with exit 65, so the gate saw the defect it guards.
- **Time against baseline.** `phase79-ios-proof` ran 03:02:29Z to 03:04:31Z, **122 s**, against **104 s** on PR 236's run 42388086844 (read from that run's job timestamps: 15:47:48Z to 15:49:32Z). That is +18 s.
- **Cost against baseline** (`bash script/ci_cost_report.sh 42554142308`): **174 billable minutes** (baseline about 250), **16.4 min wall clock** (baseline 20 to 44), critical path `proof-requires-example-host` at 16.1 min, **2 jobs with a full-suite step** by the report's name heuristic (baseline about 10). Billable above 250: no. Wall above 44: no. Full-suite count above baseline: no. `phase79-ios-proof` is 30 billed minutes (122 s rounds up to 3 macOS minutes at x10) against 20 at the 104 s baseline.
- **Findings before and after.** `main_findings_before` is 1, counted from the measured `before:` FAIL verdict line (local form on the exact 0.2.12 generator, exit 65) in `default-ios-build-200.txt`; `main_findings_after` is 0 because the hosted line above is PASS.
- **Issue 281.** Comment scanned clean first (privacy-200.txt run 2, rc 0), then posted: https://github.com/szTheory/crosswake/issues/281#issuecomment-6731425802. It says what failed in run 42494651844, the cause, that 0.2.12 stays published and nothing is re-run, the fix PR, and that 0.2.13 follows with its own approvals. The issue stays open until 0.2.13 is complete (200-09). Nothing else on issue 281, PR 280 or PR 262 was touched.
- **The merge.** Immediately before: PR head `3696f38c` (equal to the record), CI conclusion success on that head, `deleteBranchOnMerge` = `false`. Then one call: `gh pr merge 282 --merge --match-head-commit 3696f38cd8e4e158a6339eca1984d7b63dd03403`, rc 0, no output. Afterwards: state MERGED at 03:20:47Z, `mergeCommit` `e8d44c6c907a5f16d333c62df6b8d6dcd4d32e3c`, two parents (`1dcdaad8` and `3696f38c`; the second equals the CI-green head), the merge is an ancestor of `origin/main`, and `origin/main` is exactly that commit. The remote branch `fix/default-ios-generation-builds` still exists (`git ls-remote`, rc 0).
- **Not checked here.** The no-flag remote-form compile is not in PR CI (see the residual below). The 0.2.13 release candidate: the next release PR does not exist yet. The advisory `script/ci_cost_report.sh` figures cover this one run only; they are not a trend. I did not run a second CI run to see run-to-run variation in the 32 s step.

## Requirements and residual

REL-08 is the requirement this plan serves; it stays unchecked until its last declaring plan in this phase finishes.

Residual: the no-flag remote-form compile is not in PR CI; it is a release-time rehearsal (200-02 on the fix, 200-05 on every release candidate). PR CI builds only the `--local` form (the phase79-ios-proof step), and the full suite runs only the file-level reference regression for both forms. The released core on the public mirror is still proven only after publishing, by the release run's clean-room-proof-ios.

The same paragraph is in the body of PR 282 (checked after the merge: the body contains `Residual: ` and `not in PR CI`), so the merge accepted it knowingly.

Cost report advisory flags (advisory only, the report never gates a merge):

1. `uncached`: `phase79-ios-proof` has no dependency cache (setup-beam plus `mix deps.get`, no `setup-elixir-cache`). This is pre-existing in the job and not added by this PR, which adds a step and no job.
2. `info`: `phase79-ios-proof` moved from 104 s (20 billed macOS minutes) to 122 s (30 billed), a +10 billed-minute step caused by the job crossing a whole-minute boundary. Total run cost is still 76 minutes under the baseline.

Neither flag is a new duplicated full-suite run.

## Accomplishments

- The fix and the gate are on main; the gate is a blocking step in a required CI lane from this merge.
- The gate was proven on the hosted runner (PASS with a detected control) before it became merge-blocking, with real time and cost numbers.
- The merge happened only on a head CI had passed, pinned with `--match-head-commit`, with auto-delete read off first.
- The 0.2.13 release PR's base can now contain `e8d44c6c` (key link: `fix-pr-200.json` `merge_oid`).

## Task Commits

1. **Task 1 (tracer): scan, push and open the fix PR** - docs branch `6e281e6f` (`docs(200-03): record fix PR scan and opening`)
2. **Task 2: CI on the exact head, hosted measurement and cost, issue 281 comment** - docs branch `6dc768d8` (`docs(200-03): record fix PR CI, gate measurement and cost`)
3. **Task 3: merge under the standing exception** - docs branch `18f6b7e4` (`docs(200-03): record fix PR merge`); main merge commit `e8d44c6c` (made by GitHub, pinned to head `3696f38c`)

## Files Created/Modified

- `200-EVIDENCE/privacy-200.txt` - two scan blocks (PR files plus body; issue comment), each `rc=0`
- `200-EVIDENCE/fix-pr-200.json` - PR, head, CI run and ran-on commit, gate line, measurement, cost with flags, findings counts, issue comment URL, auto-delete read, merge record

## Decisions Made

- The merge went ahead despite the two advisory cost flags: neither is a gate, neither is a new duplicated full-suite run, and both are stated here and in the evidence.
- The remote fix branch was left in place. Deleting it needs its own displayed gate and is not part of this plan.
- The worktree `~/projects/crosswake-200-wt` is kept for 200-05, 200-08 and 200-09.

## Deviations from Plan

None - plan executed exactly as written. Two small notes, neither a deviation from the plan's outcomes: scratch files (PR body, issue comment, logs) were kept in the session scratchpad instead of `$TMPDIR` (the sandbox's scratch rule); and one wait loop was started twice while waiting for CI (both were read-only `gh run view` polls).

**Total deviations:** 0.

## Issues Encountered

None. Authorization on record was used only as scoped: a feature-branch push after a clean scan and the PR 282 merge under the standing exception. Nothing was published, tagged, dispatched or deployed; PR 280, PR 262, issue 281 (other than this plan's comment), and every release branch were left alone; `docs/199-release-0-2-12` stays local.

## Known Stubs

None.

## Self-Check

## Self-Check: PASSED

- `privacy-200.txt` and `fix-pr-200.json` exist; the plan's verify clauses were run and pass: clean scan line with at least one input and the recorded 40-hex head; PR 282 is the fix branch against main (now MERGED); `ci_conclusion` success, `ci_ran_on` 6e511a9a differs from `head_oid` 3696f38c, the gate line matches the PASS pattern, `phase79_baseline_seconds` 104, `main_findings_after` 0; `main_findings_before` 1 equals the measured count; the PR head equalled the record before the merge; the comment URL matches; `delete_branch_on_merge_read` is false, `merge_oid^2` equals `head_oid`, the merge is an ancestor of `origin/main`; the remote fix branch exists; the merged PR body carries the residual.
- Commits `6e281e6f`, `6dc768d8` and `18f6b7e4` are ancestors of the docs branch head; `e8d44c6c` is an ancestor of `origin/main`.
- The PR has 0 paths under `.planning/`.

## Next Phase Readiness

Plan 200-04 is next: the 0.2.13 candidate. The fix is on main as `e8d44c6c`, so Release Please can form the 0.2.13 release PR from main, and that PR's base must contain this merge commit. Every release gate (core-maven-drill, core-merge, core-tags, core-hex, core-maven, core-ios) still needs its own displayed one-use `allow`; none of today's merge authority carries over to a release PR, a tag, a publish or a dispatch. The remote-form rehearsal in 200-05 must use the newest mirror tag as `--remote-version` (0.2.12 until 0.2.13 is public).

---
*Phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds*
*Completed: 2026-11-09*
