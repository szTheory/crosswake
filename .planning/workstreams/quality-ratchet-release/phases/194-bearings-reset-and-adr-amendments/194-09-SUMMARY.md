---
phase: 194-bearings-reset-and-adr-amendments
plan: 09
subsystem: planning-orientation
status: complete
tags: [pr2, merge, bearings-report, closeout, plan-01, plan-02, plan-03, plan-04, plan-05]
requires:
  - phase: 194-08
    provides: bearings-report complete
provides:
  - PR #248 merged to main as ff70560c82aecddbe2411baa58adbab4cfe40268
  - bearings-report run on merged main (no UNVERIFIED line)
  - closeout branch docs/194-closeout with evidence and this summary
affects: [195]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-EVIDENCE/pr2-merge-194.txt
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-EVIDENCE/bearings-main-194.txt
decisions:
  - "Fix-forward after first PR2 head 71b790e was red (extensionless script/bearings-report unclassified); 106e5a5 went green; the approval was bound to 106e5a5 only."
actuals:
  tokens: 60000
  tasks: 3
  commits: 5
plan_head_before: 656f93f7
requirements-completed: [PLAN-01, PLAN-02, PLAN-03]
---

# Phase 194 Plan 09: Land PR2 and run bearings-report on main Summary

PR #248 (rolling roadmap, bearings, personas, STATE and AGENTS.md trim, bearings-report) is merged to main, and the report reads the merged main without any UNVERIFIED line.

## What was checked and what happened

- Crosswake CI was green (49 of 49) on PR head 106e5a5407b2301664e00bf4fdb44ca02131d86a. The first head 71b790e was red (routing.unclassified_path for the extensionless script) and was fixed forward in 106e5a5. Pull-request runs also test a synthetic merge commit that is not the head; the result is for the head.
- The new ExUnit tests at that exact head: 84 tests, 0 failures (`pr2-ci-194.txt`).
- The user answered `allow` for PR #248 at head 106e5a5 only. One call `gh pr merge 248 --merge --match-head-commit 106e5a5...` succeeded: merge commit ff70560c82aecddbe2411baa58adbab4cfe40268, merged 2026-10-25T15:31:15Z, present on origin/main. No retry, no admin, no branch deletion, no tag. Remote tags: 94 before and after. Remote branch docs/v28-bearings-reset still exists.
- `script/bearings-report` on fresh main (`bearings-main-194.txt`, local run): BEARINGS: ATTENTION (2), rc 1, no UNVERIFIED line. Attention items are stale dependabot PRs #210 and #211 (Phase 195 owns them); one worktree, one unlanded local branch. Caps ok: ROLLING 67/120, BEARINGS 35/60, STATE 39/40, AGENTS.md 102/102. Personas 30/30 tagged. The ci line reports success on 106e5a5, naming it as the PR head with main only tested as a synthetic merge.
- PLAN-01..03 marked Complete (PLAN-04, 05 were already), ROADMAP plan list ticked, STATE kept at 39 lines.

## Deviations from Plan

- Evidence file for the main run is `bearings-main-194.txt` with absolute home paths scrubbed; `main: rc 1` appended.
- The per-plan commit ledger file was not present, so `plan_head_before` is the head after plan 08 (656f93f7); `commits: 5` counts the plan 09 commits (71b790ee, 106e5a54, the evidence commit, this summary commit) plus the PR merge commit.
- Task 3 step order: the closeout branch was cut after pulling merged main, equivalent to origin/main.

## Known Stubs

None.

## Next action

Merging the closeout PR (`docs/194-closeout`) needs its own one-use `allow`; no approval is carried over from PR #248.

## Self-Check: PASSED
