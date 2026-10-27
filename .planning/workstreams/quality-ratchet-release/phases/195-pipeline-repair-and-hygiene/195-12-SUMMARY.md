---
phase: 195-pipeline-repair-and-hygiene
plan: 12
subsystem: release-hygiene
tags: [pr3, root-hygiene, clean-room, merge-gate, bandit]
requires: [195-10, 195-11]
provides: ["PR3 (#255) merged to main", "root tree on main holds only allowlisted files"]
affects: [195-13]
status: complete
requirements-completed: [HYG-01, REL-06]
commits: 1
plan_head_before: 3b170221
plan_head_after: 88727aea
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/privacy-pr3-195.txt
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/pr3-ci-195.txt
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/pr3-merge-195.txt
actuals:
  tasks: 3
  commits: 1
---

# Phase 195 Plan 12: PR3 root hygiene, setup guide move, clean-room command Summary

PR #255 merged into main by merge commit `ff63e5d8` after a one-use approval, leaving main's root with only allowlisted files and no checkpoint bundle.

pr3: state MERGED

## What was checked and what happened

- Privacy scan of 25 changed files at head 88727ae: rc 0 (re-run independently by the orchestrator: rc 0).
- Crosswake CI run 40366309125 (pull_request) concluded success and reports head 88727ae; GitHub also tests a synthetic merge commit, which is not the head.
- Bundle re-check: `24c8389` is an ancestor of origin/main (re-checked at display, origin/main 0b28e6d).
- Merge: `gh pr merge 255 --merge --match-head-commit 88727aeae158b96519fc3985acf010e6e8d2c8f1` ran once, rc 0, no retry. Read-back: state MERGED, merge commit ff63e5d84f459cb89f65e28a0bea7a87eb81d042, head unchanged. No `--admin`, no `--auto`.
- Main after merge (origin/main): no scratch file, no `.bundle` path (`bundle_paths_on_main 0`), root `SETUP.md` and `fix_public2.py` absent, `docs/SETUP.md` present. Local `main` fast-forwarded to ff63e5d8.
- Tags: 94 before, 94 after. No tag created.

## Approval record

pr3 approval: allow, bound to PR #255 at head 88727aeae158b96519fc3985acf010e6e8d2c8f1 (one-use, consumed by this merge).
Displayed scope: 13 root scratch file deletions; removal of crosswake-checkpoint-24c8389.bundle; SETUP.md moved to docs/SETUP.md with contact lines replaced; root allowlist guard; published clean-room command; SEED-003 closure; example-host bandit 1.13.1 to 1.14.0 security bump plus formatting fix-forward; inspect-test flake disclosed as open.
bundle removal: crosswake-checkpoint-24c8389.bundle heads 24c8389 on_origin_main yes (re-checked at display)

## Task 1 history

First CI run 40361272003 on 3b170221 failed: format-proof, proof-dependency-security (bandit advisories), and one `test/mix/tasks/crosswake_inspect_test.exs:136` failure. Fixed forward in 88727aea (formatting, bandit 1.14.0). The second run was green.

## Deviations from Plan

**1. [Observed, not caused by the agent] PR branch auto-deleted on merge.** The plan says `pr3: remote branch kept (plan 13)`. The repo has `delete_branch_on_merge: true`, so GitHub removed `origin/chore/root-hygiene-and-cleanroom` at merge. Remote head count went 20 to 19 (exactly that one ref); no other head and no tag changed. The agent ran no delete. The recorded line `pr3: remote branch kept (plan 13)` in pr3-merge-195.txt therefore describes intent; the head-count lines show the true outcome. Plan 13 should treat this branch as `already_absent`. The local branch still exists.

**2. [Rule 1 - CI fix-forward] bandit and format.** Commit 88727aea, described above.

## Open follow-up

- Flaky or unexplained failure: `test/mix/tasks/crosswake_inspect_test.exs:136`, seen once in run 40361272003 (head 3b170221), did not recur on 88727ae. Cause unknown. Not investigated; needs its own look before it can be called a flake or a real intermittent defect.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Merge commit is an ancestor of origin/main; the three evidence files exist (untracked, plan 13 commits them); `docs/SETUP.md` present and root `SETUP.md` absent on origin/main.
