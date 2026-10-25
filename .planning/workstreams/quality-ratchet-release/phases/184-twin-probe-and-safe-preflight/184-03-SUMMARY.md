---
phase: 184-twin-probe-and-safe-preflight
plan: 03
subsystem: twin-proof-lane
tags: [git, source-gate, plain-language, measure, privacy]
requires: [184-01, 184-02]
provides:
  - TwinProducers.source_gate/3 (read-only freeze prefix)
  - TwinProducers.dirty_counts/2, source_block_action/1, max_dirty_count/0
  - observe_identities/3 and checked_identities/3 threading probe options
  - verify_twin blocked receipt with M+F+X measure and shared line 4
affects: [184-04, 184-05, 184-06]
key-files:
  modified:
    - /private/tmp/crosswake-phase180-impl/lib/crosswake/proof_lane/twin_producers.ex
    - /private/tmp/crosswake-phase180-impl/lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
    - /private/tmp/crosswake-phase180-impl/test/crosswake/proof_lane/twin_source_probe_test.exs
    - /private/tmp/crosswake-phase180-impl/test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
status: complete
commits: 0
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
actuals:
  tasks: 2
  commits: 0
---

# Phase 184 Plan 03: Shared git builder everywhere, separate counts, plain line 4 Summary

Every twin git call now goes through the one pinned builder, freeze is a read-only `source_gate/3` plus its writing tail, and a blocked source reports changed, flagged and exclude counts separately in plain language with a typed measure and no path. Nothing is committed (single candidate commit is 184-06); the recovery checkout was not staged, committed or branched.

## What was built

- `source_gate/3`: identity read, `rev-parse HEAD` and `HEAD^{tree}` (via `git/3` with probe options), head and tree comparison, `clean_tree/2` (with `:run_root`), lock digests, study-script digest. Takes a plain map (a runtime struct also matches); never writes. `freeze/3` now calls it first, then `backend_digest`, `freeze_expectations`, `write_expectations` unchanged. The D-18 digest comparison is not in the gate.
- `observe_identities/3` (arity 2 still works) passes `:git_cmd`, `:git_timeout_ms`, `:tmp_dir`, `:remove_dir` to all four `git/3` calls and `clean_tree`; `checked_identities/3` threads the same. `git/3` lost its unused default arg. `twin_journey.ex` untouched.
- `dirty_counts/2` (map or nil), `dirty_count/2` as its sum, `max_dirty_count/0` (`@doc false`).
- `source_block_action/1`: M, F, X clauses joined with `; and `, zero counts dropped, singular/plural, remedies joined with `; `, shared tail `, then write a new prepared record and run into a new run root.`; separate hiding-config and not-toplevel texts (not-toplevel never says "remove it"); a single digit-free unknown text for unavailable, over-bound and all-zero. Docs state counts are findings, not distinct files, a staged rename is two.
- verify_twin `blocked_receipt/2`: one `probe_source/2` call (with `run_root`), measure = M+F+X or nil, line 4 from `source_block_action(probe)`. `next_action/2` source_dirty clause now returns the unknown text, with a comment explaining it is a defensive fallback; `source_dirty_action/1` and `source_dirty_steps/0` deleted (old "run git status" advice retired). `record_failure(` has exactly its 4 known lines in lib/.

## Tests

- New in `twin_source_probe_test.exs` (35 -> 42): "every twin git call goes through the shared builder" (explicit pin literal, wrapper prefix, env check, freeze >= 10 calls, at least one call per entry point), "source_gate checks identity, head, tree and cleanliness without writing", "a raising spawn in freeze or observe_identities leaks no path", "line-4 text for each probe outcome is exact", "a candidate that is not the top-level directory gets its own next action", "dirty_counts reports modified, flagged and excludes separately", "the dirty bound equals the receipt measure bound". (The plan's count of 42 holds; its "3 + 4 named" are these 7.)
- `crosswake_proof_lane_verify_twin_test.exs`: the two source_dirty tests (below line 338) now assert exact lines; added "a flag-hidden edit reports separate counts and measure two" and "no source_dirty output carries the candidate path or home directory".
- Totals: probe file 42 tests, 0 failures (trace); verify_twin 24, 0 failures; producers + journey 51, 0 failures; producers + receipt + phase170 ledger 74, 0 failures. Inventory `--check` exit 0; compile with warnings-as-errors clean; format check clean; no `assert/refute Enum.all?/any?(` added.
- Full suite not run in this plan (not required by it).

## Deviations from Plan

None in behaviour. One test-scope note: the plan's named verify_twin tests for the privacy scan and the flag-hidden edit use the existing `dirty_producers/0` stub (which returns `{:blocked, :source_dirty}`) with a real git candidate, so the real probe runs in `blocked_receipt/2` as in the existing tests.

## Known Stubs

None.

## Threat Flags

None. Mitigations T-184-06 (one builder, recorder test, one `git_cmd.(` site), T-184-07 (marker and privacy scans) and T-184-08 (exact separate counts, digit-free unknown text) are covered by tests.

## Self-Check: PASSED

Candidate HEAD still 50fcd57; recovery index empty; all gates ran with exit code 0 captured separately (files under /private/tmp/crosswake-phase180-run: quick-184-03-t1/t2, trace-184-03-t1/t2/vt, ledger-184-03, compile-184-03).
