---
phase: 187-doctor-and-proof-fidelity
plan: 05
subsystem: proof-lane
tags: [loopback-harness, evidence, wr-03]
requires: [187-03]
provides:
  - loopback harness refuses empty and bare --evidence with LOOP-IOS-EVIDENCE JSON, exit 2
affects: [187-06, 187-07, 188]
actuals:
  tasks: 2
  commits: 0
  note: "uncommitted by design; the single phase commit belongs to 187-07"
key-files:
  modified: [script/verify_loopback_origin_simulator.sh, test/crosswake/proof_lane/loopback_origin_harness_test.exs, .planning/workstreams/quality-ratchet-release/phases/186-host-seam-and-harness-honesty/186-REVIEW-DISPOSITION.md]
requirements-completed: []
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 05: Loopback Harness --evidence Refusals Summary

**The loopback harness now refuses `--evidence ""` and a bare trailing `--evidence` through `block()` after the EXIT trap, printing one JSON object (outcome blocked, rule LOOP-IOS-EVIDENCE) and exiting 2.**

## Deviation statement (D-19)

This plan is outside DOCTOR-01..04. It closes 186 review WR-03 because Phase 188 runs the harness and may not change code. `requirements: [DOCTOR-03]` is a schema placeholder only; this plan must NOT count as DOCTOR-03 completion (`requirements-completed` is empty). WR-01 (`physical_iphone_preflight.ex`) is untouched; no CI lane or workflow was added (D-18).

## Evidence (RUNS = /private/tmp/crosswake-phase180-run, build path _build_187_05_test, MIX_ENV=test)

| Step | Result |
|------|--------|
| Task 1 red (red-187-05-t1.out, exit 2) | 16 tests, 1 failure: "evidence: an empty evidence value blocks with LOOP-IOS-EVIDENCE before any build" |
| Task 1 green (t1-187-05.out, exit 0) | 16 tests, 0 failures; bash -n exit 0 |
| Task 2 red (red-187-05-t2.out, exit 2) | 17 tests, 1 failure: "evidence: a bare evidence flag blocks with LOOP-IOS-EVIDENCE and still prints one JSON object"; the empty-value test passed as control |
| Green (green-187-05.out, exit 0) | harness + guide tests: 23 tests, 0 failures |
| bash -n (bashn-187-05b), mix format --check-formatted (format-187-05) | both exit 0 |

## What changed

- Script: `EVIDENCE_REQUESTED=0` beside `EVIDENCE=""`; the `--evidence` arm sets it to 1, takes `$2` and `shift 2` only when a second argument exists, else `shift` (never exits in the loop). The first statement of the evidence precheck (after `trap cleanup_and_emit EXIT`) blocks `LOOP-IOS-EVIDENCE` "--evidence needs a path" when requested and empty. Runs without `--evidence` behave as before.
- Tests: W_E1 and W_E2 (exact names above); `run_harness/3` gained an `:argv` option (default `["--evidence", evidence_arg]`, stderr still redirected to the per-run file via a `shift`/`"$@"` wrapper).
- 186-REVIEW-DISPOSITION.md: only the WR-03 row status cell changed to "fixed by 187-05 (lands in the fix(187) commit; ...)" naming both refusal behaviours.

## Deviations from Plan

None beyond D-19 itself. The `:argv` plumbing changed the bash wrapper in `run_harness` so stderr file is positional `$1`; existing tests still pass.

## Known Stubs

None.

## Threat Flags

None. T-187-17 and T-187-18 mitigated; 187-06 supplies mutation controls (remove the block; restore `shift 2`).

## Self-Check: PASSED

status-187-05.txt equals status-187-03.txt plus exactly the two harness files; preflight file and .github unchanged; no RUNS output contains the home path; nothing staged in the recovery checkout or candidate; HEAD unchanged at bd294007.
