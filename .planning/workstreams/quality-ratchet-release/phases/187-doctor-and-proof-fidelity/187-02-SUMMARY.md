---
phase: 187-doctor-and-proof-fidelity
plan: 02
subsystem: proof-lane
tags: [evidence, provenance, sentinel, validator]
requires: [187-01]
provides:
  - Evidence rejects all-zero commit refs (40 or 64 zeros) with PL-EVIDENCE-COMMIT
  - exact provenance sentinels git-unknown / unknown accepted for advisory evidence only
  - Evidence.provenance_known?/1 single predicate
affects: [187-03, 187-06, 187-07]
actuals:
  tasks: 2
  commits: 0
  note: "uncommitted by design; the single phase commit belongs to 187-07"
key-files:
  modified: [lib/crosswake/proof_lane/evidence.ex, test/crosswake/proof_lane/evidence_test.exs]
requirements-completed: [DOCTOR-03]
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 02: Evidence Validator Provenance Summary

**The proof-lane evidence validator now rejects the fake all-zero commit and accepts unknown provenance only as three exact sentinels that can never become physical proof.**

Edits are uncommitted in the candidate checkout; nothing was staged or committed. Preconditions held: HEAD bd294007, push URL no-push-phase180, 187-01 summary present, no BLOCKED file, tree limited to 187-01's paths.

## Red and green evidence (RUNS = /private/tmp/crosswake-phase180-run)

| Task | Red (exit 2) failure headers | Green |
|------|------------------------------|-------|
| 1 tracer | T_Z only; control T_NM passed (red-187-02-t1.out) | evidence_test.exs 31 tests, 0 failures (t1-187-02.out) |
| 2 | T_S, T_K, T_PHY, T_PROM (red-187-02-t2.out, 35 tests, 4 failures) | evidence_test.exs 35 tests, 0 failures (t2-187-02.out) |

T_PROM case (b), a validated struct skipping validation with commit_ref git-unknown, is covered by the removed device_class-only promotion clause.

## What changed

- `evidence.ex`: attributes `@unknown_commit` and `@unknown_version`; `git_ref/1` takes the exact sentinel first, then an all-zero check (`0{40}|0{64}`, PL-EVIDENCE-COMMIT), then generic hex (`git_ref_hex/1`); `semver/1` and `decimal_version/2` (template_version only) take the exact `"unknown"`; `schema_version` never matches. Public `provenance_known?/1` with @doc and @spec (false for missing keys and empty map). `valid_physical_fields/1` requires `provenance_known?`; `promotion_class/2` is one clause that, for a `physical_iphone` basename, requires device_class `:physical_iphone` and known provenance before the hook runs. No new rule id; no entropy heuristic.
- `evidence_test.exs`: six tests T_Z, T_NM, T_S, T_K, T_PHY, T_PROM (names exact).

## Other gates

- compile --force --warnings-as-errors: exit 0 (compile-187-02). mix format --check-formatted on both files: exit 0 (format-187-02).
- Navigation-shell task test (nav-187-02, not gated, exit 2): 2 tests, 1 failure, `navigation_shell.verification_failed`. Expected: the task still writes the all-zero placeholder, which the validator now rejects. Fixed by 187-03; the task was not edited here.
- status-187-02.txt lists only the cumulative 187-01/187-02 allowlist. No 187-02 RUNS output contains the home path.

## Deviations from Plan

**1. [Gate note] `mix test test/crosswake/proof_lane` as one run exits 2 (295 tests, 87 failures, green-187-02.out/.exit).**
All 87 failures are `Crosswake.ProofLane.TwinSourceProbeTest` with `TwinGitFixtures ... module not available`. Not caused by this plan: the same 87 fail when evidence_test.exs is excluded (noevidence-187-02.out), the test file passes alone (twin-probe-187-02.out, 87 tests, 0 failures), and an earlier phase 184 run (fix-184-09b.full.out) showed the same module-unavailable symptom in the combined run. Cause not investigated (out of scope). Evidence instead: the rest of the directory, 208 tests, 0 failures, exit 0 (green-rest-187-02.out/.exit), which includes evidence_test.exs. The plan's verify command requires green-187-02.exit = 0 and would fail literally; the orchestrator should treat green-rest-187-02 plus twin-probe-187-02 as the equivalent gate. Candidate for deferred-items / 187-07 attention.

Otherwise the plan was executed as written.

## Known Stubs

None.

## Threat Flags

None. T-187-05/06/07 mitigations are in place and tested; T-187-08 accepted (old all-zero placeholder evidence now fails check; CHANGELOG line is 187-03).

## Self-Check: PASSED

evidence.ex and evidence_test.exs changed and formatted; red exits non-zero, t1/t2 green runs exit 0; compile and format exit 0; no commits or staged files; HEAD unchanged.

## Orchestrator gate reconciliation (2026-10-16)

The executor's directory-wide run (`green-187-02.out`, exit 2, 87 `TwinGitFixtures is not available` failures) was a stale build, not a code fault: `_build_187_02_test` contains no compiled `Crosswake.ProofLane.TwinGitFixtures` beam (the `test/support` path was never compiled into it), while a fresh build does.

- Baseline: a `git archive` export of `bd29400` ran `mix test test/crosswake/proof_lane` on a fresh build: 289 tests, 0 failures, exit 0 (scratch evidence, outside RUNS).
- Candidate, fresh build `_build_187_02_fresh`, seed 120057: 295 tests, 0 failures, exit 0 (`orch-fresh-187-02.out` / `.exit`).
- Candidate, fresh build, the executor's seed 388341: 295 tests, 0 failures, exit 0 (`orch-fresh-seed-187-02.out` / `.exit`).

The plan's directory gate is therefore met (`orch-fresh-187-02.exit` = 0); the executor's "pre-existing" explanation was wrong and is superseded. Later plans should use a fresh MIX_BUILD_PATH, or one compiled first under MIX_ENV=test.
