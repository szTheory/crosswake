---
status: resolved
trigger: "Phase 175's required Maven fire-drill dispatch ran Release Please housekeeping and advanced PR #164 after all three candidate rehearsals, invalidating the exact-head Gate 2 evidence."
created: "2026-09-21T01:09:21Z"
updated: "2026-09-21T02:04:00Z"
---

# Debug Session: Fire Drill Mutates Release PR

## Symptoms

- Expected: the Maven `android-publish-fire-drill` proves a disposable Central Portal upload reaches `VALIDATED` then `DROP`, without changing the release candidate.
- Actual: dispatching `release-please.yml` run `35549803592` passed the fire drill, but its `Release Please` job created PR #164 head `374ac0cf1af5410a7d6691bf9eef9856837b4542` after the candidate had been rehearsed at `fc6d28dcf176fd68f48b5e858c790fad3e78f526`.
- Reproduction: trigger `release-please.yml` with `workflow_dispatch` and `fire_drill_version=0.2.2` while a release PR is open.

## Current Focus

- bug_class: bohrbug
- reasoning_checkpoint:
    hypothesis: The `release-please` job runs during `workflow_dispatch` because it lacks an event guard, and its action updates the open release PR while the dispatch-only Maven proof runs.
    confirming_evidence:
      - Remote run 35549803592 completed both the Maven fire drill and Release Please, after which PR #164 advanced from the rehearsed head.
      - The agent-authored structural regression test parsed `jobs.release-please.if` as nil and failed, while both proof jobs parsed as dispatch-only.
    falsification_test: The hypothesis would be false if the parsed release job already had a condition excluding workflow_dispatch, or if removing/reapplying the proposed condition did not make the regression test fail/pass respectively.
    fix_rationale: An exact push-only job condition prevents the PR-mutating action from being scheduled by the fire-drill event while preserving the existing push-to-main release housekeeping path.
    blind_spots: A live post-fix dispatch is intentionally not run because it consumes credentials and external Maven Portal state; local verification covers the workflow graph and syntax, not GitHub's live scheduler.
    candidate_causes:
      - code: the release job has no event-level condition separating housekeeping from the fire-drill dispatch
      - config: one workflow exposes both push housekeeping and manual proof dispatch without an explicit job-mode boundary
    and_gate: no — the missing job condition alone fully accounts for the deterministic PR mutation
- next_action: None — fix committed as `6e10d006`; session ready for archival by the parent debugger.

## Evidence

- timestamp: 2026-09-21T01:09:21Z; run `35549803592` showed successful `Android publish fire-drill (validated-upload -> drop)` and successful `Release Please`; PR #164 then pointed to `374ac0cf`.
- timestamp: 2026-09-21T01:35:00Z; checked `.github/workflows/release-please.yml`; found the workflow has both `push` and `workflow_dispatch`, `android-publish-fire-drill` and `lockstep-truth` explicitly require dispatch, but `jobs.release-please` has no `if` condition and invokes `googleapis/release-please-action`; implication: every fire-drill dispatch deterministically schedules the PR-mutating action.
- timestamp: 2026-09-21T01:35:00Z; checked downstream release jobs; found publish/cleanup jobs gate on Release Please outputs and the failure alert gates on actual failure; implication: guarding the Release Please job is the smallest correction for the observed PR mutation, while the dispatch-only proof jobs remain runnable.
- timestamp: 2026-09-21T01:35:00Z; SBFL skipped because there is no failing test yet and therefore no pass/fail coverage spectrum; a structural regression test is the appropriate deterministic reproducer.
- timestamp: 2026-09-21T01:35:00Z; common-pattern scan matched Environment/Config: two event modes share one workflow without isolating the mutating job; classified as a deterministic Bohrbug.
- timestamp: 2026-09-21T01:43:00Z; ran the agent-authored structural regression test before the fix; 6 tests ran and the new test failed because `conditions["release-please"]` was nil instead of the specified push-only condition; implication: the bug is locally reproducible at the workflow contract boundary.
- timestamp: 2026-09-21T01:51:00Z; after adding the condition, the focused module passed 6/6, the test file passed formatting, and actionlint accepted the workflow; implication: the target contract is green and the edited YAML remains valid.
- timestamp: 2026-09-21T02:01:00Z; temporarily removed only the push-only condition and reran the focused module; the new test failed 1/6 with a nil release condition, then passed 6/6 after reapplication; implication: the fix site is causal and the regression test kills the missing-condition mutant.
- timestamp: 2026-09-21T02:01:00Z; focused adjacent tests passed 3/3 (`release workflow integrity script passes`, trigger-map contract, and Release Please authority contract); `git diff --check` passed; implication: neighboring release-policy invariants remain intact.

## Eliminated

## Resolution

- root_cause: `.github/workflows/release-please.yml` multiplexes push release housekeeping and manual fire drills, but `jobs.release-please` had no event guard, so GitHub scheduled the PR-mutating Release Please action for every fire-drill dispatch.
- oracle_type: specified — the workflow contract requires ordinary Release Please housekeeping on push and the Maven/lockstep proof jobs on workflow_dispatch.
- fix: Added an exact push-only condition to `jobs.release-please` and a parsed-YAML regression contract proving Release Please is push-only while both manual proof jobs remain dispatch-only.
- prevention: "why not caught: no structural gate asserted event-mode isolation for the mutating Release Please job; guard: parsed-YAML regression contract for push-only housekeeping and dispatch-only proof jobs"
- verification:
    target_test: {result: pass, detail: "6 tests, 0 failures"}
    mutation_check: {result: skipped, reason_if_skipped: "Stryker is not configured for this Elixir/YAML repository; manual missing-condition mutant was killed by the focused test", mutant_killed: true}
    no_op_deletion: {result: pass, deletion_justified_by_rca: false, detail: "diff adds one scheduling guard and one structural test; no behavior or assertions deleted"}
    adjacent_tests: {result: pass, suites_run: ["phase142 release integrity line 76", "phase169 trigger map line 255", "phase165 release trust line 876", "actionlint", "mix format --check-formatted"]}
    revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
    guardrail_verdict: accepted
- files_changed:
  - .github/workflows/release-please.yml
  - test/crosswake/planning/release_please_config_test.exs
