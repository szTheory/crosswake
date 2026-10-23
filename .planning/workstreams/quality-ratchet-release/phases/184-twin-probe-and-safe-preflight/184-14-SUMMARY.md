---
phase: 184-twin-probe-and-safe-preflight
plan: 14
subsystem: proof-lane twin source probe
status: complete
tags: [gap-closure, mutation-controls, candidate-commit, probe]
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
commits: 1
candidate_commit: b898e1104b0feafdb569d1ae42972cb4e1c46629
candidate_parent: e4344ca523a56e146d9e8647ec141b9714e8180f
candidate_tree: cf721b0c25b3472e6012d7dcd39b01674c2b1166
actuals:
  tasks: 3
  commits: 1
---

# Phase 184 Plan 14: Prove and land the fourth gap closure Summary

The uncommitted 184-13/184-15 tree passed every gate, 26 mutation controls each failed with their named tests, a full HEAD copy probed clean, and the fix is now one candidate commit on e4344ca5.

## Commit

- SHA `b898e1104b0feafdb569d1ae42972cb4e1c46629`, parent `e4344ca523a56e146d9e8647ec141b9714e8180f`, tree `cf721b0c25b3472e6012d7dcd39b01674c2b1166`.
- Subject: `fix(184-14): fail closed when git cannot read the tree; read attributes, config and letter case as git does`, with the trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Seven paths: lib/crosswake/proof_lane/twin_producers.ex, guides/see_it_run.md, test/crosswake/proof_lane/twin_source_probe_test.exs, test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs, test/crosswake/guides/see_it_run_test.exs, test/crosswake/proof_lane/twin_producers_test.exs, test/support/twin_git_fixtures.ex. The ledger JSON did not change, so it is not included.
- The candidate checkout is a detached HEAD (as for earlier fix commits). Porcelain is empty, the push URL is still `no-push-phase180`, and `RUNS/fix-184-13.commit` holds the SHA.
- guides/see_it_run.md SHA-256 (for the STATE guide-reconciliation line): `a98b62714653d936db0341f63b191dd4f73e40547d8662bc40fe407dba06dd5c`.

## Task 1 gates (all passed, no fixes needed)

- Extractor reproduces `feat-184.failures` byte for byte.
- Quick suites (8 files): 217 tests, 0 failures.
- Full suite (`env -u MIX_BUILD_PATH`): `2520 tests, 1 failure (78 excluded)`. The failure set cmp-equals `baseline-184.failures` (only `phase180_twin_feasibility_test.exs:30`).
- Guides, docs-parity and ledger tests, ledger `--check`, docs sync, `compile --force --warnings-as-errors` and format all exit 0. The ledger did not need regeneration.
- The adoption scan's routing findings cmp-equal `adoption-scan-head-184.findings` (scan exit 1 is carried debt, not gated).
- No added `assert/refute Enum.all?/any?` line. History manifest verified before and after.

## Task 2 mutation controls

`mutate-184-13.sh` (copied from `mutate-184-11.sh`, umask 0022) exited 0. `mutation-184-13.log` has exactly 27 `control ` lines and no HARNESS FAILURE. Control 0 (unmutated): 185 tests, 0 failures. Controls 1-18 all still fail as expected. Controls 19-26 (failures / tests):

| # | Mutation | Failing named tests |
|---|----------|---------------------|
| 19 | `@git_script` back to the e4344ca5 discard text | the three unreadable-folder tests, the status stderr test, and the pipe-capture test (7 failures in 130 tests across PROBE and twin_producers_test) |
| 20 | `@stdin_script` back to the discard text | check-ignore stderr test (2 of 87) |
| 21 | whole e4344ca5 producer file | all eleven new probe tests, including the case-only rename (14 of 87) |
| 22 | whole e4344ca5 producer file, preflight | both new preflight tests (2 of 23) |
| 23 | Unicode `trim_leading` in the attributes predicate | NBSP and other-blank tests (2 of 87) |
| 24 | split on CRLF and LF | CR CR LF test (1 of 87) |
| 25 | `core.ignorecase=false` pin removed | letter-case test and case-only rename test (4 of 87); `case-184-15.out` says insensitive |
| 26 | e4344ca5 truthy/falsy lists in `hiding_entry?` | `00` and `2` config tests (2 of 87) |

Control 19 names two test files because the renamed pipe-capture test lives in twin_producers_test.exs, not in the probe file. The harness `finish` was changed to pass a space-separated file list. No pattern from controls 1-18 needed rewriting. No control was masked. The mutation copy was deleted, and the pre-mutation manifest of the seven changed paths verified afterwards (candidate byte-identical).

## Task 3 probes and evidence

- Pre-commit: a full HEAD copy (real .git, every ignored file, core.ignorecase=true) restored to e4344ca5 probed `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (`real-probe-184-13.pre.out`). The copy was removed.
- Post-commit: the real candidate probes `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (`real-probe-184-13.out`).
- Gitlink count 0 (`gitlinks-184-13.count`), no `.gitmodules`.
- Post-commit suites (five phase files plus the guide test): 197 tests, 0 failures.
- History manifest: 87 OK lines. No twin-05. Recovery checkout has no staged path.
- The five GAP3 rows of 184-REVIEW-DISPOSITION.md now say "closed in 184-13/184-15/184-14" with commit b898e110 and their control numbers, plus one plain paragraph under the table. That file is a plain uncommitted file.

## Deviations from Plan

None in substance. Two harness details: control 19 runs two test files (see above), and `finish` takes an unquoted file list. Recovery-checkout commits skipped per checkout rule.

## Notes for the orchestrator

- WR-05 stays open for Phase 188 TWIN-07. The D-36 deferrals carry their reopen triggers.
- Accepted over-refusals and residuals: D-38 and D-40 (BOM-led attributes lines, unusual safe config spellings) and the D-39 residual (a git that skips a folder without printing a warning).
- STATE.md and ROADMAP.md were not touched. Nothing was pushed, tagged or released; no twin, Simulator or xcodebuild ran; no CI lane added.

## Self-Check: PASSED
Commit b898e110 is HEAD on e4344ca5 in the candidate. All evidence files exist under /private/tmp/crosswake-phase180-run. The SUMMARY is the last write.
