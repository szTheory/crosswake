---
phase: 195-pipeline-repair-and-hygiene
plan: 05
subsystem: infra
tags: [ci, github-actions, schedules, contract-test]
requires:
  - phase: 195-04
    provides: secret masking, branch ci/recurring-lanes-and-secret-masking at 0ea8916c
provides:
  - "test/crosswake/proof/ci_recurring_lanes_test.exs with exact @pending_schedule_removal (7 set-B files)"
  - "phase23/34/43/45/48/52/58 proof workflows dispatch-only"
  - "195-EVIDENCE/lanes-195.txt"
affects: [195-06, 195-09]
requirements-completed: []
actuals:
  tokens: 30000
  tasks: 2
  commits: 2
  plan_head_before: 0ea8916c
  plan_head_after: 98892efa
completed: 2026-10-25
status: complete
---

# Phase 195 Plan 05: Recurring lanes (first half) Summary

**One contract test now owns the phase-proof schedule rule (floor >= 14 files, fixture control, exact pending list), and seven of the 14 weekly phase proof schedules are removed while `workflow_dispatch` is kept.**

Branch `ci/recurring-lanes-and-secret-masking` (local only, not pushed). REL-04 is only half done here (plan 06 removes set B and adds the canary), so the requirement is not marked complete.

## Commits

- b11675b9 ci: add recurring-lanes contract test and drop the phase23 proof schedule
- 98892efa ci: drop the first-half phase proof schedules

## Evidence

- RED: with the pending list at 13 entries the live test failed (phase23 still scheduled). With the list temporarily `[]` the failure reported 14 scheduled files: `guard: ci_recurring_lanes red_on_origin_main_tree 14`. List restored afterwards.
- Test: floor `>= 14` on matched files (15 matched live, phase68 is unscheduled), exact list equality, fixture negative control and dispatch-only control.
- phase165 schedule assertions retired at lines 252, 321, 480, 521, 555, each with the "retired, not executed" comment naming the new owner.
- Blocking checks: `f1dd556db36ba0e28c4ace016c957e7a457c5c5b14f1179e4d6612ca90b23e2a` before and after, `unchanged yes`.
- Task 1 gate (ci_recurring_lanes, phase165, phase169, bearings_report): rc 0, 114 tests, 0 failures.
- `mix test test/crosswake/proof test/crosswake/release_candidate/evidence_live_test.exs`: rc 0, 845 tests, 0 failures (67 excluded).
- Scheduled phase proof lanes remaining: 7 (set B). Seven `schedule removed` lines in lanes-195.txt, each with the removed cron `0 6 * * 1`.
- Privacy scan on all changed files: rc 0.

## Deviations from Plan

**1. [Out of scope, deferred] `mix test test/crosswake/proof` alone fails 2 tests** - `Phase175LinkedAuthorizationTest` (lines 131, 147) calls `Crosswake.ReleaseCandidate.EvidenceLiveTest.fixture/1`, a helper module defined in `test/crosswake/release_candidate/evidence_live_test.exs`, which is not loaded when only the proof directory is run. It passes when that file is loaded (28 tests, 0 failures) and in the combined run above. The cause is a pre-existing cross-directory test dependency, unrelated to this plan; the plan's "mix test test/crosswake/proof rc 0" wording is satisfied in the combined run. The full-suite run in CI loads both. Not fixed here.

**2. [Evidence formatting] Guard line count** - the first write carried `wc -l` padding; normalized to `... red_on_origin_main_tree 14` and folded into the first commit (unpushed amend).

## Notes

- The `echo` notice text in phase23-proof.yml still says "scheduled/manual lane"; left unchanged because it is a runtime string, not a comment.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files exist: ci_recurring_lanes_test.exs, lanes-195.txt. Commits b11675b9 and 98892efa are ancestors of HEAD.
