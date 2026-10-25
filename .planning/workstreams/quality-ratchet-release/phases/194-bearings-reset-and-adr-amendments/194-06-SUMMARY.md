---
phase: 194-bearings-reset-and-adr-amendments
plan: 06
subsystem: planning-orientation
status: complete
tags: [bearings-report, ci-check, negative-controls, plan-04]
requires:
  - phase: 194-05
    provides: trimmed AGENTS.md and STATE
provides:
  - script/bearings-report launcher (mode 100755) and script/bearings_report.exs (Crosswake.BearingsReport)
  - CI check for the main tip read from its merged PR head
  - 5 real captured gh/git fixtures plus MANIFEST and capture script
  - 21-test ExUnit file with a named negative control per CI read
affects: [194-07, 194-08, 194-09]
key-files:
  created:
    - script/bearings-report
    - script/bearings_report.exs
    - test/crosswake/bearings_report_test.exs
    - test/fixtures/bearings/
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/scripts/capture-bearings-fixtures-194.sh
decisions:
  - "run/2 fetches origin main first and stores fetch_ok; plan 07 moves the fetch into the sync check."
  - "Unparseable gh output, a read error, an empty list where data is required and zero or several merged PRs are all UNVERIFIED with fixed reason strings."
actuals:
  tokens: 45000
  tasks: 2
  commits: 2
plan_head_before: f935c0ec7b6c0d20c5188f1e31ede4aaf64ea4e5
plan_head_after: a6dbedadbf06a9f371e9fb8fa39a043989dfd706
requirements-completed: []
---

# Phase 194 Plan 06: bearings-report core and CI check Summary

`script/bearings-report` runs through its launcher and, for the origin/main tip, names the PR head commit CI actually ran on; every CI read failure renders UNVERIFIED with exit 2.

## What was checked and what happened

- Live tracer run: `BEARINGS: ATTENTION (1)`, `ci: success on 6fea725 (PR #247 head; main 28b2e71 is its merge commit, tested only as a synthetic merge)` and `ci: CI has not run on HEAD f935c0e`, rc 1 (`194-EVIDENCE/bearings-tracer-194.txt`). The attention line is correct: local HEAD is an unpushed docs commit.
- `mix test test/crosswake/bearings_report_test.exs`: 21 tests, 0 failures. Ownership and absence guards rc 0 (`bearings-tests-06-194.txt`). `mix test test/crosswake/planning`: 95 tests, 0 failures. `mix format --check-formatted` and `mix compile --warnings-as-errors` rc 0.
- Negative controls (each asserts the exact line): gh error on commit-pulls, zero / unmerged-only / two merged PRs, empty run list, run list for another commit, failed fetch, unparseable JSON, always-empty runner never OK, empty render never OK, invalid `--ws`, HEAD without a CI run. Source has no `File.write/rm/mkdir/cp/rename`; no workflow mentions bearings; fixtures hold no home path; privacy scan clean.

## Deviations from Plan

None - plan executed as written. Notes: the capture script reads the slug with `jq` from the captured repo-view file because `gh repo view --jq` needs `--json`; fixture HEAD in the tests is the HEAD at capture time and the HEAD run list is built per test, since the captured run list belongs to the PR head only.

## Known Stubs

None. The report currently has only the CI check; ahead/behind, PR classes, local work (plan 07) and file checks plus the 40-line truncation (plan 08) are planned, not stubs.

## Self-Check: PASSED

Files and commits verified present (script/bearings-report 100755, ab6acd11, a6dbedad).
