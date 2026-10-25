---
phase: 180-bounded-digital-twin-demonstration
plan: 03
status: complete
gate_verdict: existing_path_supported
candidate_head: 12f84cd950d4574921767df823faed6797c17c26
commits: 0
plan_head_before: none (working-tree edits only in the candidate; no commits by D-27)
plan_head_after: none
requirements_completed: []
actuals:
  tasks: 2
  commits: 0
---

# Phase 180 Plan 03: Twin receipt, owned runtime and verify_twin command Summary

## Plain-language result

I built the three pieces the twin run will need to report a result safely: a closed receipt format, a runner that owns its own folder, database path, port and child processes, and the `mix crosswake.proof_lane.verify_twin ios` command that ties them together. None of the twin journey itself runs yet; the command still has no real producers, so run on its own it reports every observation as missing and exits 2. Those producers come in 180-06.

All work is uncommitted working-tree files in `/private/tmp/crosswake-phase180-impl`. Nothing was staged or edited in the recovery checkout.

## What was checked

- The plan's gate check passed before any edit (existing_path_supported, decision not_required bound to head 12f84cd9, candidate path, top level and ancestry).
- Task 1 verify, run verbatim: `twin_receipt_test.exs` 11 tests, 0 failures, exit 0. Codename fragment count in the receipt module is 0.
- Task 2 verify, run verbatim: both files together 25 tests (11 receipt + 14 command), 0 failures, exit 0.
- `PhysicalIphoneContract` count in the receipt module is 0; `gen.shell` count in the command is 0; `mix format --check-formatted` is clean on all five files; no leftover `sleep` children after the tests.
- `git diff --cached` in the recovery checkout is empty.

## What was built (all in the candidate)

- `lib/crosswake/proof_lane/twin_receipt.ex`: fixed roster of ten groups and 49 sub-observation ids with owners; `freeze_expectations/1`, `observation/1`, `derive/3`, `validate/1`, `status/1`, `roster/0`, `encode!/decode`, `project/2`, `exit_status_for/1`, `safe_cause/1`. Status folds failed over blocked over passed. TW-T10-02 is derived from seven frozen identity joins (source, dependency lock, generated resources, served static, installed media, installed build, backend build). Owner, stale run, reused run, duplicate, sensitive-name and physical/adopter relabel inputs each have a named rule id and a test.
- `lib/crosswake/proof_lane/twin_runtime.ex`: `prepare/1` (private 0700 run root, fresh database path inside it checked before any migration, exclusive loopback listener on the exact declared origin held open until `stop_all/1`), `start_child/3`, `await_exit/2`, `stop_all/1`, `env_for_backend/3`, `first_failure/1`. Children start as their own process group (via a short perl `setpgrp` then exec) and only those groups are signalled; nothing is found by port.
- `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`: strict `ios --candidate --run-root`, `execute/2` (returns exit status and the four printed lines) and `run/1` (prints, then halts on non-zero). Writes `receipt.json` and `twin-result.json` at mode 0600, re-reads and re-validates both after writing.
- `test/crosswake/proof_lane/twin_receipt_test.exs` (11) and `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` (14).

## Exit-code contract

0 complete pass, 1 observed failure, 2 missing prerequisite, missing observation, rule violation or unknown rule id. A run root that already holds `receipt.json` exits 2 with `run_root_reused` and the file is untouched. An occupied origin port exits 2 with `origin_port_occupied` and the occupant is never contacted or signalled. The summary is exactly four lines: result, first cause, report path, next action.

## Decisions made where the plan left room

- The prepared candidate is a private (mode 0600) JSON record: `candidate_path`, `expected_head`, `expected_tree`, `origin`, `resource_digests`, `fixture_digests`. Lock digests come from `mix.lock` (and the example host's, when present) in the candidate path. 180-06 can extend this record and add `--identity`.
- `--run-root` is optional on the runtime (it creates one under the temp dir if absent); the command always requires an existing private root when it is given.
- Pinned probe answers: measures are integers 0..1_000_000 inclusive, roster order is fixed T01..T10, empty or single-entry receipts are rejected. The TWIN-05/06 coverage-probe rows stay flagged for gsd-verifier as the plan says.

## Deviations from Plan

None. Rules 1-3 fixes: none needed. Notes: the producer list is an injected function argument (as the plan states); the ambient `DATABASE_PATH` environment variable, if set, is treated as a request and checked against the run root, so a stale value in a shell makes the command exit 2 rather than being ignored.

## Known Stubs

The default producers return nothing, so a real invocation blocks until 180-06 supplies them. This is intentional and owned by 180-06.

## Threat Flags

None beyond the plan's register.

## Self-Check: PASSED

- Five files exist in the candidate; both verify commands exit 0.
- Recovery index has no staged files; no commits were made.
