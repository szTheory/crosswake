---
phase: 199-release-0-2-12
plan: 20
subsystem: release-train
tags: [rel-07, closeout, merge, d-29, sc4, privacy]
requires:
  - phase: 199-19
    provides: the cleared, unpushed closeout branch and the applied D-29 answer
provides:
  - PR 293 merged to main as merge commit 323227b5 (0.2.14 recorded as published, threadline 0.1.1 deferral D-31 recorded, AGENTS.md condensed, planning record landed)
  - the local docs branch retired after a zero-gap per-path proof (D-29)
  - worktrees reduced to the main checkout, no stash
  - the closeout record closeout-final-199.txt and closeout-pr-199.json (untracked) and one handoff
affects: [milestone-audit]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/closeout-pr-199.json (untracked)
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/closeout-final-199.txt (untracked)
  modified:
    - .planning/workstreams/quality-ratchet-release/STATE.md (uncommitted on main)
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md (uncommitted on main; SC4 annotation)
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/privacy-199.txt (carried, uncommitted)
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/landing-privacy-199.txt (carried, uncommitted)
decisions:
  - "Pushed five unmerged local branches as preserve/<name> after a clean scan; kept two whose commit history (not their final files) has privacy-class hits"
  - "Did not work around the permission system's refusal of `git branch -D` on the five preserved branches; SC4 is annotated as unmet instead"
requirements-completed: [REL-07]
actuals:
  tokens: 12000
  tasks: 3
  commits: 2
plan_head_before: 57e4ef882f57a0a0fed82237a02ff55fd7479256
plan_head_after: e540a41d6970fdce5827dbac4c193bf2300831c1
status: complete_with_open_items
completed: 2026-11-10
---

# Phase 199 Plan 20: Closeout merge, local cleanup and the docs-branch retirement Summary

**PR 293 recording 0.2.14 as published is merged under the standing exception (CI green on head 2c722930, merge commit 323227b5), the docs branch is retired with a zero-gap proof (267 paths), and SC4 is annotated as unmet because seven local branches remain: five preserved on origin but not deleted locally (the permission system refused `git branch -D`) and two kept for privacy hits.**

`commits: 2` is measured as the docs-branch commit made here (`57e4ef88..e540a41d` is 1, the privacy-scan evidence) plus the one closeout-branch commit (2c722930, the 199-19 summary and state copy) that PR 293 carries; the ledger range cannot count the second because that branch lived in a worktree that is now removed. `actuals.tokens` is chars/4 over what this plan authored (the PR body, the two evidence files and this summary).

## What was checked and what happened

- **Landing the last copies (Task 1).** Four paths were newer on the docs branch than the closeout branch (STATE.md, ROADMAP.md, the state archive, the new 199-19-SUMMARY.md). They were copied with the home prefix written as `~`, scanned (the only hit is the generic SSH clone-URL form that was already dispositioned in 199-19, not in the new lines) and committed as 2c722930. Then every changed path of the closeout branch (104; 61 clean, 43 with a recorded disposition, 0 undispositioned), the PR body and the messages of all 10 commits were scanned: rc 0. `final_docs_head` is 57e4ef88; the two evidence lines went in one trailing docs commit (e540a41d) after it.
- **Push, PR, CI.** One push, PR 293. Crosswake CI run 42764123305 finished green in 20 minutes (11 reads, 2-minute interval, bound 45) on the exact head `2c7229302145108a55b268b7fb1097c139ba3b6c`. CI ran on the synthetic merge commit `6514719e409f1b0272b8c6291593297ba7b661be` (parents: main cbb90031 and the head), not on the head itself. 39 jobs, all success. Cost: 182 billable minutes against the about 250 baseline, wall clock 19.7 minutes, 2 jobs with a full-suite step against about 10; no flag.
- **Merge.** `deleteBranchOnMerge` read false. One `gh pr merge 293 --merge --match-head-commit 2c7229302145108a55b268b7fb1097c139ba3b6c`; merge commit `323227b52af8deefebbc2b20cf835870e48200cf`, second parent equal to the head. The three post-merge checks pass on origin/main: 25 explicit planning paths present, the qualifier test gone, AGENTS.md 99 lines (cap 102), the support matrix no longer says unpublished; the changed-path check passes with `script/collection_assertion_ledger.json` allowed.
- **PR 258** is CLOSED (since 2026-11-07), recorded as already settled; nothing was done to it.
- **Worktrees and branches.** The three extra worktrees (the closeout worktree, the agents worktree and the agent worktree under `.claude/worktrees/`) were each clean, merged and unused (`lsof` empty) and were removed without force. Five merged local branches were deleted with `git branch -d`. No stash exists.
- **Unmerged local branches (7).** The scan covered each branch's changed files and also its whole commit history (`git log -p`) and messages. Five were clean in both (the history scan's one email-class hit on two of them is an added at-sign include line for AGENTS.md, not an address) and were pushed as `preserve/<name>`; each `git ls-remote` equals its tip. The local `git branch -D` for these five was refused by the permission system. They stay local (see deviation 2). Two were kept as `kept_privacy_hits`: `docs/197-public-docs-truth` (4 hits in files and history) and `docs/196-uat` (final files clean, history has home-path, private-string, account, credential-assignment and email class hits).
- **Docs-branch retire (D-29).** Equivalence over every path the docs branch authored (`git diff --diff-filter=AM` from the merge base to `final_docs_head`, 267 paths, all under `.planning/`, none deleted): equal 157, redacted_equal 38, raw_equal 72, gaps 0 (`retire_blocked` false). The two trailing evidence files were carried into the main checkout's working tree and left uncommitted. Then `git branch -D docs/199-release-0-2-12` ran (tip `e540a41d6970fdce5827dbac4c193bf2300831c1`).
- **Bearings (SC4).** `bash script/bearings-report` on main (0 ahead, 0 behind): `BEARINGS: ATTENTION (1)`, rc 1, the single item `local: worktrees 1, stashes 0, unlanded branches 7`, no UNVERIFIED line. The seven are exactly the kept items; ROADMAP SC4 carries the annotation. The full output is in `closeout-final-199.txt`.

## Deviations from Plan

**1. [Plan wording] `199-13-SUMMARY.md` and `199-14-SUMMARY.md` do not exist.** 13 ended BLOCKED (`199-13-BLOCKED.md`) and 14 was not executed, so the explicit-path check used `199-13-BLOCKED.md` and the PLAN files 13 to 20, SUMMARY files 15 to 19 and the other named paths (25 in total, none missing).

**2. [Permission] The local deletion of the five preserved branches was refused.** After the push and the `ls-remote` match, `git branch -D` on `chore/codex-model-profile`, `chore/v27-milestone-close`, `ci/199-release-gates`, `docs/195-closeout` and `fix/spec-structure-ratchet` was denied by the permission system (no reason given). I did not look for another way to delete them (no `update-ref`, no upstream rewiring). The docs branch `git branch -D`, which the user authorized by D-29, was allowed. Their content is safe on `origin/preserve/<name>`. The record uses a new action word, `preserved_local_delete_denied`, so the Task 2 branch verify (which allows only `kept_privacy_hits` for a remaining branch) fails for these five until they are deleted; I did not relabel them to make it pass.

**3. [Judgement] History scan on top of the per-file scan.** The plan scans each file a branch changes. I also scanned the whole patch and message history because a pushed branch publishes its history. By the plan's literal rule `docs/196-uat` (files clean) would have been pushed; I kept it.

**4. [Rule 1, own slip] The first push attempts failed on a zsh modifier.** `"$b:refs/..."` was read as a path modifier, so four pushes failed with a refspec error and nothing was pushed; I confirmed with `git ls-remote` that no `preserve/*` ref existed and then pushed with `${b}`.

**5. [Own correction] The PR body first named 0.2.14 as the first release for the seam.** The guides say 0.2.12; the body was fixed before the push.

**6. [Scope] Two extra merged local branches deleted** (`ci/dedupe-full-suite-runs` and its agent branch) because their worktree was removed; both were merged into origin/main.

## Auth gates

None. No remote branch was deleted, no tag pushed, no force push, no re-run.

## Known Stubs

None.

## Threat Flags

None. T-199-46 held: nothing was pushed as `preserve/*` without a clean file and history scan; T-199-82 held: deletion only after 267 paths, 0 gaps.

## Open items (all in STATE's handoff)

- Seven local branches (above). Receiver: the user's allow for the five, the user's decision for the two.
- Remote branches left, each deletion needs the user's own allow: listed in `closeout-final-199.txt` (`remote_branch_left:` lines, 33 incl. the five `preserve/*` and `docs/199-record-0-2-14-published`, `ci/199-ci-timeout-headroom`, `docs/todo-013-014-record-ledger-and-201-hardening`).
- Threadline 0.1.1 stays deferred (D-31); PR 290's CI bound (merge 00f39995) is on main.
- This phase's post-merge files (this summary, STATE, ROADMAP, the two carried evidence files, `closeout-pr-199.json`, `closeout-final-199.txt`) are uncommitted on main and go to the milestone close by PR.

## Self-Check: PASSED

Checked: merge 323227b5 is an ancestor of origin/main and its second parent equals the CI head; `closeout-pr-199.json` verifies; the equivalence proof was re-run after the merge (gaps 0); the docs branch no longer exists; `git worktree list` shows only the main checkout; `git stash list` is empty; local main equals origin/main with no commit of its own.
