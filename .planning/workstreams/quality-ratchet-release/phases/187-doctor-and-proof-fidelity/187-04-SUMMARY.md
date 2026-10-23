---
phase: 187-doctor-and-proof-fidelity
plan: 04
subsystem: planning-records
tags: [deferral, seed, requirements]
requires: []
provides:
  - 187-DEFERRALS.md canonical record (CW-REQ-A, CW-REQ-D, compile-time rule, D-09 gaps, 186 WR-01/WR-03)
affects: [187-05, 187-07]
requirements-completed: [DOCTOR-04, DOCTOR-02]
actuals:
  tokens: 6000
  tasks: 2
  commits: 0
  note: "uncommitted by design; the single phase commit belongs to 187-07"
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-DEFERRALS.md]
  modified: [.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md, .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md]
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 04: Deferral Records Summary

The CW-REQ-A, CW-REQ-D and compile-time `:local_first` rule deferrals are now recorded once in 187-DEFERRALS.md, with the seed and requirements file pointing to it.

Precondition held: the candidate HEAD is bd294007. Nothing was staged or committed. The candidate was read only.

## What was recorded

- CW-REQ-A: both readings of the pipeline trigger (published: met; proven: only qualifiedly met), verdict "defer under either reading", the enforcer (`validate_report/1`, `PI-ASSERTIONS-ORDER`, the `evidence.ex` caller, `join_reports/3`), the real numbers (`@schema_version 2`, 19 ids, 2->3 if reopened), and three reopen triggers.
- CW-REQ-D: `RouteUnavailableView.swift:29-30`, two triggers, and the "drop only the Route: line" note.
- Compile-time rule: doctor as single enforcement point, three triggers.
- D-09 known gaps with the exact observable doctor output (supported, `offline_posture_ready`, `routes=[]`), disclosed and not mitigated.
- 186 WR-01 not folded in; WR-03 folded into 187-05 as a recorded deviation.

SEED-014 gained the dated Phase 187 paragraphs (CW-REQ-A, CW-REQ-D) and a CW-REQ-F correction line. Three REQUIREMENTS.md Future Requirements rows now carry the triggers and "see 187-DEFERRALS.md".

## Checks

RUNS/deferrals-187.check has 16 PASS lines and no FAIL. It covers the record's structure, the pointers, the absence of `physical_iphone_contract.ex` and `.swift` paths in the candidate diff and untracked files, privacy (no home path, username or codename), and an empty staging area. The plan's full automated verify greps were also run and all passed.

## Deviations from Plan

None. Every source value matched the plan (19 assertion ids, `@schema_version 2`, run ids, 42/43, closeout disposition). The 187-01 control test for the D-09 shapes was not re-run, since this plan runs no mix commands.

## Known Stubs

None.

## Self-Check: PASSED
