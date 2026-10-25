---
phase: 194-bearings-reset-and-adr-amendments
plan: 07
subsystem: planning-orientation
status: complete
tags: [bearings-report, sync, pr-classes, local-work, negative-controls, plan-04]
requires:
  - phase: 194-06
    provides: bearings-report core and CI check
provides:
  - check_sync/1 owning git fetch origin main, ahead/behind line
  - check_prs/2 (release-please, dependabot, feature, stale > 14 days; 100 results UNVERIFIED)
  - check_local/2 (worktrees, stashes, unlanded branches on one line)
  - 5 more real captured fixtures, all 10 re-captured in one moment
affects: [194-08, 194-09]
key-files:
  modified:
    - script/bearings_report.exs
    - test/crosswake/bearings_report_test.exs
    - test/fixtures/bearings/
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/scripts/capture-bearings-fixtures-194.sh
decisions:
  - "check_sync takes only deps (not ctx) and returns {fetch_ok, lines}; run/2 passes fetch_ok into ctx for check_ci."
  - "A MANIFEST line starting with # is a note, used for the /repo substitution in the worktree porcelain."
actuals:
  tokens: 50000
  tasks: 2
  commits: 2
plan_head_before: 6bd4e3b7d4827de0b0781c894d0b0018d140c268
plan_head_after: 6d2ec70217e7d85bb5a50385698cace8db7e16da
requirements-completed: []
---

# Phase 194 Plan 07: bearings-report sync, PR classes and local work Summary

`script/bearings-report` now also reports ahead/behind, open PR classes with stale PRs, and worktrees/stashes/unlanded branches, each failing closed under a named negative control.

## What was checked and what happened

- Live tracer run (`194-EVIDENCE/bearings-sync-tracer-194.txt`): `sync: ahead 12 behind 0`, no UNVERIFIED sync or ci line, `prs: open 7 (release-please 1, dependabot 5, feature 1)`, `prs: stale 2: #210 #211`, `local: worktrees 1, stashes 0, unlanded branches 2`, rc 1 (attention is real: unpushed local commits, two stale dependabot PRs, two unlanded local branches).
- `mix test test/crosswake/bearings_report_test.exs`: 40 tests, 0 failures. Ownership and absence guards rc 0 (`bearings-tests-07-194.txt`). `mix test test/crosswake/planning`: 95 tests, 0 failures. `mix format --check-formatted` and `mix compile --warnings-as-errors` rc 0. Fixtures hold no home path; privacy scan clean; no workflow mentions bearings.
- Negative controls (each asserts exact line text): failed fetch on both sync and CI lines; garbage rev-list; 15-day PR stale; exactly 14 days not stale and 14 days + 1 s stale; 99 PRs verified and 100 UNVERIFIED; gh error; zero worktrees; two worktrees, one stash and one unlanded branch each attention; failed stash read. An exact-output test renders the real fixture set byte-identically in fixed order.

## Deviations from Plan

**1. Two tasks, shared edits.** Task 1 and Task 2 edited the same script, test file and fixtures, so commit 3a189905 holds all code, fixtures and the tracer evidence and commit 6d2ec702 holds the test-run evidence. Commit order differs from per-task granularity; content is complete. Also, `base_map` in the tests now overrides sync, PR, stash and unlanded reads to a clean state so CI tests keep a single cause; `fixture_map` is the real-fixture map.

## Known Stubs

None. File checks and 40-line truncation (plan 08) are planned.

## Self-Check: PASSED

Commits 3a189905 and 6d2ec702 present; five new fixtures present.
