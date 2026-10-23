---
phase: 184-twin-probe-and-safe-preflight
plan: 08
status: complete
gap_closure: true
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
commits: 1
plan_head_before: 1f5d18ee1c637560f7a5b62472dd83db43da7e92
plan_head_after: 3786de95b2b2b8435c3378fd1d194e0fecd84df5
actuals:
  tasks: 3
  commits: 1
---

# Phase 184 Plan 08: Prove and land the review-gap closure Summary

The 184-07 gap closure passed every gate against the 184-01 baseline, all thirteen mutation controls failed their named tests, a full copy of the candidate at HEAD probed clean under the new code, and it is now one candidate commit on top of 1f5d18ee.

## Commit

- SHA: 3786de95b2b2b8435c3378fd1d194e0fecd84df5 (candidate /private/tmp/crosswake-phase180-impl, detached HEAD as before)
- Parent: 1f5d18ee1c637560f7a5b62472dd83db43da7e92; tree 20c4eaaa07a675d395dcfdc29c03dd7f2c1055b2
- Subject: fix(184-08): close the Phase 184 review gaps (candidate hooks, untracked ignore files, raise paths); trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` present
- Nine paths: guides/see_it_run.md, lib/crosswake/proof_lane/twin_preflight.ex, twin_producers.ex, twin_runtime.ex, lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex, test/crosswake/proof_lane/twin_runtime_check_test.exs, twin_source_probe_test.exs, test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs, test/support/twin_git_fixtures.ex. The ledger was not regenerated and is not in the commit (ledger check passed unchanged).
- Candidate porcelain empty afterwards; push URL still no-push-phase180; nothing pushed, tagged or merged; nothing staged in the recovery checkout.

## Task 1: gates on the uncommitted tree (real exit codes)

| Gate | Exit | Result |
|---|---|---|
| Extractor self-check vs feat-184.failures | cmp 0 | reproduces byte for byte |
| Quick suites (8 files) | 0 | 178 tests, 0 failures |
| Full suite `mix test --exclude requires_example_host` | 2 (expected, one baseline failure) | 2480 tests, 1 failure (78 excluded) |
| Failure set vs baseline-184.failures | cmp 0 | only test/crosswake/proof/phase180_twin_feasibility_test.exs:30 |
| Guides + docs-parity + vacuous-ledger tests | 0 | pass |
| Ledger check | 0 | 243 sites, ledger matches live tree exactly (no regeneration) |
| docs sync --check | 0 | pass |
| compile --warnings-as-errors (forced) | 0 | pass |
| format --check-formatted on changed paths | 0 | pass |
| Adoption scan | 1 (carried debt, not gated) | sorted routing findings cmp-equal adoption-scan-head-184.findings (5 findings) |
| Forbidden Enum.all?/any? assertion added | none | clean |

New guide SHA-256 for the orchestrator's STATE guide-reconciliation line: 603976aedda6c4fc0879252a8b05a9db3d20e00fe1acc6bb230783504e65e0f3 (unchanged from 184-07's recorded value).

## Task 2: mutation controls (RUNS/mutation-184-07.log, 14 control lines, harness exit 0)

- control 0 unmutated: passed (146 tests, 0 failures)
- 1 hooksPath pin (probe and source gate): 3 named tests failed (53 tests, 4 failures)
- 2 hooksPath pin (preflight): "a candidate hook never runs during the preflight" failed (18 tests, 1 failure)
- 3 unattributed-ignore count forced to 0: both untracked-ignore tests failed (53 tests, 2 failures)
- 4 raising lock_digests: unreadable-lock test failed (1 failure)
- 5 GIT_ prefix scrub removed: GIT_TRACE test failed (1 failure)
- 6 spawn body narrowed: caller-survives test failed (1 failure)
- 7 root removal on every failure: run-root test failed (8 tests, 1 failure)
- 8 task backstop removed: raising-check test failed (18 tests, 1 failure)
- 9 temp index left behind: four-line allowed test failed (18 tests, 4 failures)
- 10, 11, 13 aliased call, apply/3 atom, capture reference: "the preflight never calls the effectful run path" failed each time (18 tests, 1 failure)
- 12 file_digest mid-read error revert: mid-stream test failed (1 failure)

Every control changed the target file's sha256, ran N >= 1 tests, and all named tests appeared among the failure headers. No control needed strengthening and none was masked. Candidate changed paths were byte-identical afterwards (shasum -c exit 0). The throwaway copy was removed; no leftover temporary index directories. The mutation control for "unattributed-ignore count" was implemented as forcing the returned count in `hidden_by_uncommitted_rules` to 0 (the plan wording was ambiguous).

## Task 3: probes and commit

- Pre-commit: a full copy of the candidate (real .git, ignored files kept), restored to HEAD 1f5d18ee, probed `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`. The plan's literal grep text lists the keys in a different order (`excludes, flagged, modified`); Elixir prints this map in the order shown, so the check was done on the term, which is the same all-zero result. Copy removed.
- Post-commit: the real candidate probed the same all-zero term (RUNS/real-probe-184-07.out).
- Post-commit five phase test files: 146 tests, 0 failures.
- History manifest: 87 OK lines, exit 0; no twin-05 entry.

## Bookkeeping (plain uncommitted planning edits)

- 184-REVIEW-DISPOSITION.md CR-01 row: closed in 184-07/184-08, pin only, with rationale and SHA.
- 184-CONTEXT.md: new "Gap-closure amendments (2026-10-15)" section with D-34 (amends D-05; `core.hooksPath=/dev/null` pinned, local `core.hooksPath` not refused).
- Planning-doc commits were skipped by instruction.

## Notes for the orchestrator

- Keep WR-05 (the real run does not compare record and identity digests, D-31) as an explicit open item against REQUIREMENTS.md TWIN-07 ("matching digests") for Phase 188's scripted pre-run check.
- Record the IN-02 orphan-process deferral (an OS git child may outlive a timed-out task). Reopen trigger: a hung or leftover git process observed during a preflight or twin run.
- 184-07 recorded that check-ignore output is parsed by newline/tab, not -z, and that red-before-green was not separately run; the controls above are the real proof that each new test fails without its fix.

## Deviations from Plan

None in behavior. The only adjustment was the probe-term key order noted above.

## Known Stubs

None.

## Self-Check: PASSED

Commit 3786de95 exists with parent 1f5d18ee; nine allowed paths; fix-184-07.commit equals HEAD; mutation log has 14 control lines; history manifest verifies; recovery index empty.
