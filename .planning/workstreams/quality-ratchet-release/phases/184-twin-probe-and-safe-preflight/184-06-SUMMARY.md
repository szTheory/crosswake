---
phase: 184-twin-probe-and-safe-preflight
plan: 06
status: complete
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
commits: 1
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 1f5d18ee1c637560f7a5b62472dd83db43da7e92
actuals:
  tasks: 3
  commits: 1
---

# Phase 184 Plan 06: Full gates, 27 mutation controls and the single candidate commit

The whole uncommitted Phase 184 change passed every gate against the pre-edit baseline, all 27 mutation controls showed their guard is load-bearing, and the change landed as one candidate commit that the hardened probe finds clean.

## Candidate commit

- Commit `1f5d18ee1c637560f7a5b62472dd83db43da7e92`, tree `3dba1449314ea33f949a4d1856d7fd16f57cd15d`, parent `50fcd5743243c0b20275a7e2bd9338bf25468687`, subject `feat(184-06): harden the twin source probe and add a read-only preflight`, in `/private/tmp/crosswake-phase180-impl`. SHA is in `RUNS/feat-184.commit`. Candidate HEAD is detached (as before); porcelain is empty afterwards; push URL is still `no-push-phase180`.
- Exactly 12 paths (the ledger needed no regeneration): `guides/see_it_run.md`, `lib/crosswake/proof_lane/twin_producers.ex`, `twin_runtime.ex`, `twin_preflight.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `crosswake.proof_lane.twin_preflight.ex`, `test/crosswake/proof_lane/twin_producers_test.exs`, `twin_runtime_check_test.exs`, `twin_source_probe_test.exs`, `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`, `crosswake_proof_lane_twin_preflight_test.exs`, `test/support/twin_git_fixtures.ex`.
- Guide SHA-256 for the STATE reconciliation line: `guides/see_it_run.md` = `c9e9c5e05ecea0dadd88053edc5187dacdd24b2ca42fdfd09e9986ce0fad013d`.
- Planning-doc commits were skipped by design (recovery checkout: nothing staged, committed, branched or tagged; STATE and ROADMAP left to the orchestrator).

## Task 1: gates on the uncommitted tree

- Quick suites (8 files): 162 tests, 0 failures.
- Full suite `mix test --exclude requires_example_host`: 2464 tests, 1 failure, 78 excluded (baseline 2399 tests, 1 failure; the difference is the new tests). The failing set is `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`, `cmp`-identical to `baseline-184.failures` (the same failure as at 183).
- Guides, docs-parity and vacuous-assertion tests: 218 tests, 0 failures. Ledger check, `docs.sync --check`, `compile --warnings-as-errors` and `format --check-formatted` on the 12 files all exit 0. No `assert/refute Enum.all?/any?(` line added (checked in the diff and in the new files).
- No fixes were needed in this task.

### Deviation (orchestrator-directed): adoption-context scan

`mix crosswake.adoption_context.scan` exits 1 at HEAD 50fcd57 already, with five `routing.unclassified_path` findings. Per the orchestrator, the gate was baseline equality instead of exit 0: the scan on the uncommitted candidate exits 1 and its sorted `routing.` findings `cmp`-equal `adoption-scan-head-184.findings`. No file outside the 12 phase paths was edited.

Carried-forward debt (pre-existing, not introduced by Phase 184), all under `examples/phoenix_host/native/ios/crosswake_shell/`:
`CrosswakeHostSettings.xcconfig`, `CrosswakeShell/CrosswakeShell.entitlements`, `CrosswakeShell/PrivacyInfo.xcprivacy`, `CrosswakeShellUnit.xctestplan`, `TwinJourney.xctestplan`.

## Task 2: mutation controls

`RUNS/mutation-184.log` has exactly 28 `control ` lines: control 0 (unmutated copy: 130 tests, 0 failures, over the five phase test files) and controls 1-27, each `failed as expected` in its named test(s) with at least 1 test and 1 failure. Each mutation changed the file's sha256. The throwaway copy was deleted, and `shasum -c candidate-184.pre-mutation.sha256` passes (candidate files byte-identical). Per-control outputs are `RUNS/mut-184-N.out`.

Controls 1-14, 16-19 and 21-24 and 27 were single reverts that failed the cited test directly. Notes on the rest:

- **First harness run:** four controls (15, 20, 25, 26) did not pass; the harness reported them as harness failures and I corrected the harness or mutation, then reran the whole script from scratch (the log reflects only the final run).
- **Control 15 (unknown ls-files tag):** removing only the tag guard was masked by the non-H fresh-index check (control 17's guard). The final mutation treats an unknown tag as clean/H at the parser, so the real-index and fresh-index paths both accept it; the named test then fails.
- **Control 20 (rejected argv):** the stubbed rejected call returns empty output, and every step also fails closed on empty output, so reverting only the exit-status check cannot show up. The final mutation disregards exit status 128/129 and substitutes the real git result. This shows the status check is load-bearing for a rejected call that would otherwise look fine, but it is a stronger revert than the plan's wording ("map 129 to success").
- **Control 25 (core.ignoreStat pin):** needed the masked rule. Removing the pin alone failed only the shared-builder test (`every twin git call goes through the shared builder`), not "an ignoreStat edit blocks"; with control 1's fresh-index revert added, "an ignoreStat edit blocks" fails. Logged as `core.ignoreStat pin (masked by fresh index)`. In plain terms: the pin is defence in depth that no single revert exposes through the behavioural test; its presence is held by the builder test.
- **Control 26 (GIT_CONFIG_GLOBAL scrub):** step a (filemode pin removed alone, single test run) passes; step b (scrub also removed) fails "a global filemode=false mode change blocks while unpinned git is fooled". The log line's "42 tests" in step a is the step b count; step a ran 1 test, 0 failures (`mut-184-26a.out`).
- **Shared revert:** controls 3 and 24 use the same flagged-count revert (24 requires both the skip-worktree and assume-unchanged tests); controls 1 and 27 use the same fresh-index revert (27 requires the checkStat=minimal and trustctime tests). Controls 21-23 each remove one predicate and each fails the single shared refusal test. Control 19 removes both the probe-level and the run_git NUL checks (either alone still refuses).
- Control 13 skips both containment checks; control 12 forces the owner comparison true.

## Task 3: probes and commit

- Pre-commit probe of a throwaway copy of the candidate (real `.git` kept, restored to HEAD 50fcd57, porcelain empty), run with the new code: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (`real-probe-184.pre.out`). Copy removed.
- Post-commit probe of the real candidate: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}` (`real-probe-184.out`).
- Post-commit suites (4 files): 87 tests, 0 failures. `history-184.before.sha256` verifies; no twin-05 entry exists; no twin run, Simulator or xcodebuild was started.

## Other deviations

None beyond the orchestrator-directed scan baseline, the strengthened controls 15 and 20, and the control 25 masked rule above. Control 0 ran five test files (the plan said six; there are five phase test files).

## Known Stubs

None.

## Self-Check: PASSED

Commit `1f5d18ee` is HEAD of the candidate with parent `50fcd57`; mutation log, sha manifest, probe outputs and `feat-184.commit` exist; recovery checkout has no staged paths.
