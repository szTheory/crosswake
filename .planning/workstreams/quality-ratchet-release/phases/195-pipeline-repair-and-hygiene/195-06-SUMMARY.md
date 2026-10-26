---
phase: 195-pipeline-repair-and-hygiene
plan: 06
subsystem: infra
tags: [ci, github-actions, schedules, weekly-canary, contract-test]
requires:
  - phase: 195-05
    provides: recurring-lanes contract test with pending list, set-A schedules removed
provides:
  - "phase70/71/73/74/96-advisory/130/132 workflows dispatch-only"
  - "ci_recurring_lanes_test.exs asserts no scheduled phase proof lane (floor 14) plus canary predicates"
  - ".github/workflows/weekly-canary.yml (advisory, non-required)"
affects: [195-09]
requirements-completed: [REL-04]
actuals:
  tokens: 25000
  tasks: 2
  commits: 2
  plan_head_before: 19c3dfdcd5bfa5742b86d3a77d534ed83aa47fc9
  plan_head_after: 47d783ed454ebf155077a83cac6f346a9231c7f6
completed: 2026-10-25
status: complete
---

# Phase 195 Plan 06: Recurring lanes (second half) and weekly canary Summary

**No phase proof workflow carries a schedule any more (15 matched files, floor 14, fixture control kept), and one advisory read-only Weekly Canary runs the root proof on main each week.**

Branch `ci/recurring-lanes-and-secret-masking`, local only, not pushed.

## Commits

- 52f1cfb7 ci: drop the second-half phase proof schedules
- 47d783ed ci: add one advisory weekly canary on main

## Evidence

- Task 1 gate (ci_recurring_lanes, phase165, phase169, bearings_report): rc 0, 114 tests, 0 failures.
- Task 2 gate (ci_recurring_lanes, bearings_report): rc 0, 78 tests, 0 failures.
- `mix test test/crosswake/proof test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/bearings_report_test.exs`: rc 0, 920 tests, 0 failures (67 excluded).
- Shell verify: 15 phase proof workflows checked, none scheduled, all keep workflow_dispatch; exactly one `name: Weekly Canary`; not in required_check_policy.json.
- lanes-195.txt: seven `schedule removed` lines (cron `0 6 * * 1` for 70/71/73/74/96, `0 8 * * 1` for 130/132), 14 distinct files across plans 05+06; `guard: ci_recurring_lanes class delta_only_blocking findings_on_origin_main 14 findings_on_branch 0`; `guard: weekly_canary class report_mode_advisory not_required`.
- Blocking checks hash before and after both `f1dd556db36ba0e28c4ace016c957e7a457c5c5b14f1179e4d6612ca90b23e2a`, `unchanged yes`.
- Privacy scan on all changed files: rc 0 (both commits).

## Deviations from Plan

**1. [Substitution] proof directory run** - ran `mix test test/crosswake/proof test/crosswake/release_candidate/evidence_live_test.exs ...` instead of `test/crosswake/proof` alone, because of the known pre-existing Phase175LinkedAuthorizationTest helper dependency (see 195-05 summary). Not fixed here.

**2. [Rule 1 - formatting] ran `mix format` on ci_recurring_lanes_test.exs** - a line added in plan 05 was not formatter-clean; formatted it in the task 2 commit.

**3. [Comments] Updated stale comments** in phase96/130/132 that said the lane runs on schedule. Left the `if: github.event_name == 'schedule' || ...` job conditions as they are (harmless, unreachable).

**4. [Assumption] Plan 09 still owes the first dispatched canary run on main** (flagged assumption: root-proof on a bare runner). Not run here since nothing is pushed.

## Known Stubs

None.

## Threat Flags

None. The canary has `permissions: contents: read`, no secrets, and a SHA-pinned checkout (T-195-16).

## Self-Check: PASSED

weekly-canary.yml, ci_recurring_lanes_test.exs and lanes-195.txt exist; commits 52f1cfb7 and 47d783ed are ancestors of HEAD.
