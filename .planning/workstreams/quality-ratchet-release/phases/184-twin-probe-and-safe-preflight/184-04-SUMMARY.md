---
phase: 184-twin-probe-and-safe-preflight
plan: 04
subsystem: proof_lane
tags: [twin, preflight, run-root, origin-probe]
requires: [184-03]
provides: [TwinRuntime.check/1, TwinRuntime.commit/1, run-root owner check]
key-files:
  modified:
    - /private/tmp/crosswake-phase180-impl/lib/crosswake/proof_lane/twin_runtime.ex
  created:
    - /private/tmp/crosswake-phase180-impl/test/crosswake/proof_lane/twin_runtime_check_test.exs
status: complete
actuals:
  tasks: 2
  commits: 0
plan_head_before: 50fcd5743243c0b20275a7e2bd9338bf25468687
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
---

# Phase 184 Plan 04: TwinRuntime check/commit split Summary

`TwinRuntime.prepare/1` is now `check/1` then `commit/1`. `check/1` is pure and `commit/1` is the only code that creates a run root, holds the origin listener and starts the registry. Changes are uncommitted in the candidate (the single commit is 184-06). Candidate HEAD is unchanged.

## What was built
- `check/1` runs, in order: run root (lstat directory so a symlink is refused, mode private, owner equals the current uid), not_reused, candidate_record, outside_candidate, database_path, origin_port, origin_bindable (bind then close in an after-style release).
- `commit/1`: `maybe_create_root` (mkdir + chmod 0700, the single `File.mkdir(` call), `acquire_origin` (keeps the eaddrinuse to origin_port_occupied mapping), Agent start. A root created by commit is removed if the origin acquire fails.
- `current_uid/1`: `opts[:current_uid]` (non-negative integer, otherwise refused) or `id -u` via `System.cmd`. An unreadable uid or an owner mismatch is `prerequisite_missing` with the existing private-run-root action text. No `run_root_rejected`.
- With no run root, `check/1` returns a prospective root (`create?: true`) and touches nothing. The default database path is accepted, and an explicit one is rejected with `database_path_rejected`.

## Same-causes table (11 rows, check/1 and prepare/1 agree)
root option not a path, 0755 root, symlink root, foreign-owned root (seam), missing record, 0644 record, root inside candidate, malformed origin: `prerequisite_missing`. Reused root (receipt.json): `run_root_reused`. Database path outside root: `database_path_rejected`. Occupied port: `origin_port_occupied`.

## Tests (new file, all top-level tests)
"a refused prepare without a run root leaves nothing in the temp dir", "check/1 creates nothing and holds no port", "commit/1 creates the root and holds the origin until stop_all", "a run root owned by another user is refused", "an unreadable current uid is refused", "check/1 and prepare/1 give the same first cause", "an occupied origin port is blocked by check/1".

## Verification (actual)
- twin_runtime_check_test.exs --trace: 7 tests, 0 failures; all 7 named tests present in the trace.
- verify_twin + twin_fault_boundary + twin_journey: 44 tests, 0 failures.
- `mix compile --warnings-as-errors --force`: exit 0. `mix format --check-formatted` on both files: exit 0.
- `inventory_collection_assertions.exs --check`: OK, 243 sites, ledger matches.
- No `Enum.all?/any?` assertion added. Recovery checkout has no staged paths.

## Deviations from Plan
- The plan's trace gates also pass for the task 1 and task 2 runs, which share one test file. The t1 output files are copies of the final runs, because the whole file was written together.
- Trace lines read `test <name> (` as the plan expects, with no describe wrapper.
- The verify_twin suite needed no edits.

## Known Stubs
None.

## Self-Check: PASSED
