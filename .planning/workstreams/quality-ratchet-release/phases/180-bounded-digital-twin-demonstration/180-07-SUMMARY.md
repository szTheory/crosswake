---
phase: 180-bounded-digital-twin-demonstration
plan: 07
subsystem: proof-lane
status: complete
tags: [twin, passed-receipt, handoff, run-twin-03]
requirements-completed: [TWIN-01, TWIN-02, TWIN-03, TWIN-04, TWIN-05, TWIN-06]
commits: 0
plan_head_before: da53c54db06e54be5a80fb4be144a70d3fed36a5
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
outcome: passed_receipt
run_root: /private/tmp/crosswake-phase180-run/twin-03
process_exit_status: 0
projection_exit_status: 0
projection_overall_status: passed
first_cause: none
run_id: twin-df5de761bf09fe7f
receipt_sha256: 063d668d95a2d3c3376f8831f170cce886f39d64a94d95ea1c6fa9337aca5c67
supersedes_record: 180-07-SUMMARY.twin-02.md
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-TWIN-RESULT.json
  modified:
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
---

# Phase 180 Plan 07: Twin run twin-03 and Handoff Summary

The third recorded twin run passed. `mix crosswake.proof_lane.verify_twin ios` ran once into a new root and exited 0. The receipt is `passed`, with all ten groups and all 49 observations passed and all seven identity joins passed. TWIN-01..TWIN-06 are complete. The earlier runs are kept unchanged: twin-01 (`180-07-SUMMARY.twin-01.md`) and twin-02 (`180-07-SUMMARY.twin-02.md`, `180-TWIN-RESULT.twin-02.json`).

## What was checked before the run

- GATE_CHECK passed.
- The candidate HEAD `da53c54db06e54be5a80fb4be144a70d3fed36a5` equals `expected_head` in the prepared record `/private/tmp/crosswake-phase180-run/twin-02-candidate.json`, so the record was reused unchanged.
- Port 4790 was free and no `crosswake-phase180-*` simulator existed.
- `twin-03` did not exist. `twin-run-count.before` records 2, and `twin-03` was created with mode 0700.

## What happened

- The run started at 2026-10-15T03:15:19Z. It went from a background wrapper (`run-once-03.sh`) and wrote its exit status to `twin-03.exit`.
- It finished in about six minutes:
  - Build, then the capture canary, which failed as required with zero attachments.
  - Cases c1..c5, all with xcodebuild `succeeded` and zero attachments.
  - The receipt, then cleanup.
- Case 3, which stalled for its full deadline in twin-02, finished in about a minute. `run-stages.json` records every stage and lists no stage as not reached.
- The command printed `result: passed (exit 0)` and `first cause: none`.
- The process exit status (0) agrees with the receipt this time, so repair 1 (the post-receipt crash) held.
- All ten `phoenix_ecto` observations passed, so repair 3 (the counter decoding) held.

## Checks after the run

- `180-TWIN-RESULT.json` is a byte copy of the run's `twin-result.json`; `cmp` matches.
- Its `receipt_sha256` equals the SHA-256 of `receipt.json`.
- `exit_status` is 0, `overall_status` is `passed`, there are ten ordered groups, and the 49 sub-observation ids are unique.
- The run root has no `.xcresult` bundle, database or media file. It keeps `expectations.json`, `obs/` (channel files), `receipt.json`, `run-stages.json` and `twin-result.json`.
- Port 4790 is free again and no run simulator remains.
- Exactly one new run root was created.
- Task 1's automated check passed, and nothing is staged in the recovery checkout.

## Group outcomes

T01..T10: all passed. Failed or blocked: none.

Fidelity limits: simulator not physical speaker; simulator not signed device; synthetic_test_authority not real adopter; trusted local runner not cryptographic certification.

Residual external gates: physical iPhone signed-device run; first adopter sanitized route handoff (First B2C Adopter in planning files).

## Guide

The candidate guide section "Run the Reference Twin (Simulator)" already names the shipped command, its prerequisites, the exit codes, the new-run-root rule and the proof limits, using only "first adopter". This run needed no change, so the file is still SHA-256 `3e1263b5ceeb1fde37f6a471d0b493b23eedb140b10f4e1250f775f1ac867366`. It is pending reconciliation into the authoritative tree.

## Deviations

The orchestrator ran the plan inline instead of through an executor subagent. That way the single run and its 90-minute deadline stayed under one owner that could not be interrupted halfway. There were no product changes and no commits.

## Self-Check: PASSED
