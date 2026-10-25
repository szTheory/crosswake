---
phase: 184-twin-probe-and-safe-preflight
plan: 05
subsystem: proof_lane
tags: [twin, preflight, read-only, guide]
requires: [184-04]
provides: [TwinPreflight.check/1, mix crosswake.proof_lane.twin_preflight]
requirements: [PROBE-04]
key-files:
  created:
    - /private/tmp/crosswake-phase180-impl/lib/crosswake/proof_lane/twin_preflight.ex
    - /private/tmp/crosswake-phase180-impl/lib/mix/tasks/crosswake.proof_lane.twin_preflight.ex
    - /private/tmp/crosswake-phase180-impl/test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs
  modified:
    - /private/tmp/crosswake-phase180-impl/guides/see_it_run.md
status: complete
actuals:
  tasks: 3
  commits: 0
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
---

# Phase 184 Plan 05: Read-only twin preflight Summary

A maintainer can now ask whether a twin run would be allowed without writing a receipt or creating, consuming or leaving behind a run root. All changes are uncommitted in the candidate; the single commit is 184-06. Candidate HEAD is unchanged.

## What was built
- `Crosswake.ProofLane.TwinPreflight.check/1` returns `{:allowed, text} | {:blocked, atom, text}`. Default checks, in order: `:run_root_given`, `:run_checks` (`TwinRuntime.check/1`, including owner check and bind-and-release), `:source_gate` (`TwinProducers.source_gate/3` with the checked record's path, head, tree and the run root; a `source_dirty` block is re-probed and worded by `source_block_action/1`), `:identity_digests`. `checks: []` and unknown check names are blocked with `prerequisite_missing` ("No preflight checks were configured; nothing was checked."). A missing or non-string identity is `identity_unknown`. Nothing records a pass.
- `Mix.Tasks.Crosswake.ProofLane.TwinPreflight`: `run/1` (halts only for status 2, one occurrence) and `execute/2` returning `{0 | 2, four_lines}`; strict options candidate, run_root, identity; `ios` the only positional; never raises, never exits 1; reads `DATABASE_PATH` like verify_twin.
- Exact lines: `result: allowed|blocked`, `first cause: none|<atom>`, `report: none written; no run root was created or consumed`, `next action: <text>`. Allowed line 4: "Source and run root pass and the origin port is free at this moment; the backend build and the live journey are checked only by the real run." Missing run root line 4: "Name the private run root you plan to use". Mismatch line 4: "The prepared record's resource or fixture digests do not match the identity file and candidate; write a new prepared record and run the preflight again".
- Guide: the 183 clean-tree sentence kept, followed by the hidden-changes / refused-configuration / git 2.41 sentence and the disclosed .gitignore limit; a preflight command block and a paragraph with the four-line contract, exit codes, what allowed does and does not cover, findings-not-files, and the disclosed behaviour changes. Guide SHA-256: `c9e9c5e05ecea0dadd88053edc5187dacdd24b2ca42fdfd09e9986ce0fad013d`.

## Reconciliations (stated explicitly)
- D-18: D-18 names manifest, activation and media digests, while the real prepared record keeps manifest, activation and the study script in `resource_digests` and media in `fixture_digests` (RESEARCH L13). The preflight therefore compares `[manifest, activation, study_js]` with `resource_digests` and `[media]` with `fixture_digests`, which covers every digest D-18 names. The moduledoc discloses that the real run still re-derives these digests and that enforcing the comparison in the real run is left to Phase 188's scripted check.
- D-19/D-14: line 4 keeps the user-locked D-14 text unchanged (it names the backend build and the live journey as unchecked). The D-19 disclosure that no write happens is carried by line 3 ("report: none written; no run root was created or consumed") and by the guide's statement that the preflight writes no receipt and never creates or consumes a run root.

## Tests (new file, 14 top-level tests)
"an allowed preflight prints four exact lines, exits 0 and changes nothing", "a dirty candidate is blocked and nothing changes", "a reused run root is blocked and nothing changes", "a missing run root is blocked and nothing changes", "a bad candidate record is blocked and nothing changes", "bad options and an unreadable identity exit 2 without raising", "an identity that does not match the record digests is blocked", "a head that does not match the record is blocked", "a configuration that can hide changes is blocked", "an occupied origin port is blocked", "a run root owned by another user is blocked", "an empty check list is blocked", "no preflight output carries the candidate path or home directory", "the preflight never calls the effectful run path". Listings (path, type, size, mode, mtime) of run root, candidate, candidate/.git and the TMPDIR sandbox are compared before and after.

## Verification (actual)
- Task 1: preflight file --trace, 1 test, 0 failures; all task-1 gates exit 0.
- Task 2: preflight --trace 14 tests, 0 failures, all 13 named tests in trace; runtime check + probe suites 49 tests, 0 failures; source refutation count 0; System.halt 1 in task file and 0 in twin_preflight.ex; Mix.raise 0 in both; inventory --check OK (243 sites); no Enum.all?/any? assertion added.
- Task 3: guides + phase69 + phase170 suites 218 tests, 0 failures (7 excluded); `crosswake.docs.sync --check` exit 0; compile --warnings-as-errors exit 0; format check exit 0; inventory --check exit 0; guide has no go/no-go, B2C, System.halt or Mix.raise.
- `mix crosswake.adoption_context.scan` exits 1: five `routing.unclassified_path` findings under examples/phoenix_host/native/ios/crosswake_shell (xcconfig, entitlements, PrivacyInfo, two xctestplan). Not caused by this plan: it fails identically with the guide reverted to HEAD (base run exit 1), and none of those paths were touched. Deferred, not fixed.
- Recovery checkout has no staged paths; candidate HEAD still 50fcd57.

## Deviations from Plan
- [Out of scope, deferred] adoption_context.scan failure above is pre-existing at candidate HEAD; the Task 3 verify chain therefore does not run to completion as a single command, and its remaining gates (inventory, compile, format, staged check) were run separately and pass. Needs a classification fix for those five paths (likely 184-06 or a separate repair).
- The t1 and t2 test output files come from runs after the test file was built in two stages; the t1 run used the one-test file, the t2 trace the final 14-test file.
- Trace lines read `test <name> [L#n]` then `test <name> (time)`; the plan's `test <name> (` match works.
- A guard for a missing identity option (identity_unknown) was added so a nil path never reaches File.read.

## Known Stubs
None.

## Self-Check: PASSED
