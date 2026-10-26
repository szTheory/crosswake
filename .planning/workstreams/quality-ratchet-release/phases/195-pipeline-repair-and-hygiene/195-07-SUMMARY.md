---
phase: 195-pipeline-repair-and-hygiene
plan: 07
subsystem: infra
tags: [ci, github-actions, retirement, ci-monitor, absence-guard]
requires:
  - phase: 195-06
    provides: recurring-lanes contract test, weekly canary
provides:
  - "Cancel Obsolete controller workflow and selector script removed"
  - "ci_monitor.cjs verify-remote-default-source and probe-phase165 retired (exit 2, not executed)"
  - "absence assertion with negative control in ci_recurring_lanes_test.exs"
affects: [195-09]
requirements-completed: [REL-04]
actuals:
  tokens: 35000
  tasks: 2
  commits: 2
  plan_head_before: 68b500454f6e345f2663efa72582995e6200d3ea
  plan_head_after: 1c59f28ebdc9591f2eb15158b389004c23daa1c6
completed: 2026-10-25
status: complete
---

# Phase 195 Plan 07: Retire the Cancel Obsolete controller Summary

**The controller workflow and its selector are deleted, the two monitor routes that depended on them refuse with exit 2, and a test with a negative control keeps both names out of the live tree.**

Branch `ci/recurring-lanes-and-secret-masking`, local only, not pushed.

## Commits

- c7747136 ci: retire the controller-bound monitor subcommands explicitly
- 1c59f28e ci: remove the Cancel Obsolete controller and its selector

## Evidence

- Absence grep before: rc 0, 6 files (as planned). After: rc 1, 0 files. Both recorded in lanes-195.txt.
- `node scripts/ci_monitor.cjs probe-phase165` and `verify-remote-default-source`: rc 2 each with `retired in Phase 195 (REL-04): obsolete-run controller removed; not executed`. `test-evidence`: rc 0. `validate-evidence` on the archived live-observation.json (`.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/165-efficient-and-maintainable-ci/evidence/live-observation.json`): rc 0 (`evidence: valid`).
- `bash script/check_phase165_efficient_ci.sh`: rc 0, no cancellation-policy section.
- `mix test test/crosswake/proof test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/bearings_report_test.exs`: rc 0, 918 tests, 0 failures (67 excluded).
- `node --test test/js/*.mjs`: rc 0 (monitor is not covered there; run as a safety check).
- Blocking-check hash before and after: `f1dd556db36ba0e28c4ace016c957e7a457c5c5b14f1179e4d6612ca90b23e2a`, unchanged yes.
- Privacy scan on all changed files: rc 0 (both commits).
- Guard class: `delta_only_blocking findings_on_origin_main 6 findings_on_branch 0`.

## Deviations from Plan

**1. [Substitution] proof directory run** - ran with `test/crosswake/release_candidate/evidence_live_test.exs` added, because of the known pre-existing Phase175LinkedAuthorizationTest helper dependency. Not fixed here.

**2. [Rule 1 - Bug] Phase 170 vacuous-assertion ledger drift** - removing lines from the phase165 tests shifted line numbers of 5 ledger rows, failing 5 Phase170VacuousAssertionLedgerTest tests. My first re-key used `assert Enum.all?`, which created a new unclassified site and broke the raw-grep reconciliation; rewrote it as a `for` comprehension (no new site). Re-emitted `script/collection_assertion_ledger.json` (5 rows, display line and rationale line numbers only; no reclassification). Check: `elixir script/inventory_collection_assertions.exs --check` rc 0, 243 sites.

**3. [Cleanup] unreferenced monitor helpers removed** - besides the planned functions, deleted `ghSoft`, `sleepMs`, `findRun`, `readRun`, `runJobs`, `assertProbeJobs`, `createProbeRef`, `putProbeFile`, `openProbePr`, `waitForRun`, `waitForRunState` and `REMOTE_SOURCE_FIELDS` (each had zero call sites after the retirement). Kept `gitBlob` and `apiJson` (still used). Dropped the `PHASE165_REMOTE_DEFAULT_SHA` and `waitForControllerResult` assertions because the strings no longer exist in the monitor.

**4. [Formatting] `mix format` on the two touched phase165 test files** inserted a few blank lines near pre-existing comments from earlier plans (whitespace only).

**5. [Note] orphan fixture** - `test/fixtures/ci/cancellation/cases.json` is no longer read by any test. Left in place (not named by the absence grep, not in the plan); candidate for later removal.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

195-07 commits c7747136 and 1c59f28e are ancestors of HEAD; the controller and selector are absent; lanes-195.txt and ci_recurring_lanes_test.exs exist.
