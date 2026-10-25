---
phase: 194-bearings-reset-and-adr-amendments
plan: 03
subsystem: release-landing
tags: [pr, merge, adr-01, adr-02]
requires:
  - phase: 194-02
    provides: ADR amendments and SC4 evidence on docs/v28-adr-amendments
provides:
  - PR #247 merged into main with a merge commit (28b2e71a)
  - PR #246 reconciled (merged by inclusion)
  - Branch docs/v28-bearings-reset at fresh origin/main
affects: [194-04]
actuals:
  tokens: 0
  tasks: 3
  commits: 0
plan_head_before: 6fea7251f9d997e2db86608d37da933b1a805af7
plan_head_after: 28b2e71a8ddd95f868b26740ce418341c6a97d5c
requirements-completed: [ADR-01, ADR-02]
status: complete
---

# Phase 194 Plan 03: Land PR1 Summary

PR #247 (ADR amendments) was merged to main with a merge commit after one displayed, one-use approval; the PR2 branch now starts from the fresh main.

## Results

- pr1 approval: allow, bound to #247 6fea725 (head 6fea7251f9d997e2db86608d37da933b1a805af7), Crosswake CI success 49/49 on that head, merge-commit method, no --admin. Used once.
- Head re-read before the merge matched the approved head; one `gh pr merge 247 --merge --match-head-commit` call, rc 0. No retry.
- Merge commit: 28b2e71a8ddd95f868b26740ce418341c6a97d5c, merged 2026-10-25T13:41:09Z; confirmed ancestor of origin/main after fetch.
- PR #246: already MERGED (its head 7e794f01 was carried by #247). No close needed; remote branch kept (deletion needs its own allow; Phase 195 HYG-02).
- Tags on origin: 94 before, 94 after. No tag, release, or remote branch deletion.
- Branch docs/v28-bearings-reset created at 28b2e71a (origin/main), not stacked on PR1.
- Evidence (untracked, to be committed by plan 04): 194-EVIDENCE/privacy-pr1-194.txt, pr1-ci-194.txt, pr1-merge-194.txt.

## Deviations from Plan

None. The `commits:` count is 0 because this plan made no commits of its own beyond this tracking commit; the plan_head fields bracket the merge.

## Known Stubs

None.

## Self-Check: PASSED
