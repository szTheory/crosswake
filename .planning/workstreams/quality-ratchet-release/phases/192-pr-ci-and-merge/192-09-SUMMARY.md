---
phase: 192-pr-ci-and-merge
plan: 09
status: complete
requirements: [LAND-04]
completed: 2026-10-23
---

# Plan 192-09 Summary: merge after the user's allow

The user was shown PR #242 (https://github.com/szTheory/crosswake/pull/242) at head `9f33c07`
("fix(192): stop a fast-exiting child from being reported as a missing executable"), with what
was checked, the three lines of checks-summary-192.txt, the R-1 meaning of "CI on main is green",
and what `allow` and `hold` do. The user answered `allow`.

The PR was merged once with a merge commit at exactly that head:
merge commit `d12aed7567b6bddc6800806e4269e0e87bcd4aac`, merged at 2026-10-23T23:39:29Z.
Main's push-triggered runs on the merge commit are checked next (Plan 10).

## What ran

- Task 1: fresh live-shape self-tests (selftest-ci 15 of 15, selftest-merge 17 of 17),
  `postmerge-192.sh baseline before`, `merge-gate-192.sh propose 242` (`proposal ready`),
  checks-summary re-checked against the scan record bound to the head (A-14; 2 personal values),
  privacy check over the proposal, baseline and summary: `privacy: clean files 3`.
- Task 2: the decision checkpoint, answered `allow` by the user.
- Task 3: `merge-gate-192.sh answer allow` (`allowed`), then `merge-gate-192.sh merge` once
  (`merged`, rc 0). Binding consumed; exactly one `pr_merge ... --merge --match-head-commit` line
  in gh-writes-192.txt; no forbidden option; live PR reads MERGED at the bound head.

## Deviations

- The Task 1 automated verify first failed when run under zsh (unquoted `set -- $T` does not
  word-split there). Run under POSIX `sh`, as the plan's scripts assume, it passed. No input changed.

## Self-Check: PASSED

Commit skipped in the recovery checkout (phase rule).
