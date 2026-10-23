---
phase: 180-bounded-digital-twin-demonstration
plan: 07
subsystem: proof-lane
status: complete
tags: [twin, blocked-run, handoff]
requirements-completed: []
commits: 0
plan_head_before: da53c54db06e54be5a80fb4be144a70d3fed36a5
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
outcome: blocked
run_root: /private/tmp/crosswake-phase180-run/twin-01
exit_status: 2
first_cause: prerequisite_missing
key-files:
  modified:
    - /private/tmp/crosswake-phase180-impl/guides/see_it_run.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
---

# Phase 180 Plan 07: Single Twin Run and Handoff Summary

The one recorded twin run was blocked before it observed anything, so no TWIN requirement is complete and there is no receipt.

## What was checked and what happened

The gate check passed on candidate head `da53c54`. I ran `mix crosswake.proof_lane.verify_twin ios` exactly once under MIX_ENV=test into the fresh run root `/private/tmp/crosswake-phase180-run/twin-01`. It exited 2 (blocked) at once with first cause `prerequisite_missing`. The command wants `--candidate` to name a prepared candidate record (a private mode 0600 JSON file), and I passed the candidate directory, as the plan text literally says. No earlier plan had prepared such a record. This is a harness and plan-wording defect, not a fact about the twin. A local precheck could have caught it before the run, and I missed it. The run root is empty. No simulator, backend or app was started, there is no `receipt.json` or `twin-result.json`, and so no `180-TWIN-RESULT.json` was written. I did not retry, as the plan directs.

What is unknown: whether the twin passes. None of the 49 observations was made.

## Group outcomes

T01 to T10: all `not_observed`, with the run-level cause `prerequisite_missing`.

## Requirements

TWIN-01 through TWIN-06 stay Pending. Complete rows: 0.

## Handoff changes

- STATE.md: the old "Exact Next Action" (execute-phase 180) moved to Handoff history as superseded. One active handoff now holds all ten group lines, the Failed or blocked line, the four fidelity limits, the two residual external gates, and the pending-reconciliation guide hash.
- ROADMAP.md: 180-05, 180-06 and 180-07 are checked as executed, the progress row and active handoff line say the twin run was blocked, and the phase is not marked complete.
- REQUIREMENTS.md: TWIN rows and coverage text say run twin-01 was blocked.
- Guide: the candidate `guides/see_it_run.md` gained a "Run the Reference Twin (Simulator)" section with the shipped command, prerequisites (including that the candidate argument is a record file), exit codes 0/1/2 and the limits. Its SHA-256 is `3e1263b5ceeb1fde37f6a471d0b493b23eedb140b10f4e1250f775f1ac867366`. It uses only "first adopter". It is not in the authoritative tree and needs a separately authorized delivery.

## Next action

Prepare the candidate record file (fields in 180-03-SUMMARY.md), then run the twin once more into a new root `twin-02`. The command is `$gsd-execute-phase 180 --ws quality-ratchet-release --wave 6`. Amend 180-07 Task 1 first so it prepares the record and uses the next fresh root. Phase verification is not eligible until a run produces a receipt.

## Deviations from Plan

None to the plan's actions. The invocation defect above is recorded as the run's truthful cause. The planned check "twin-NN count equals before plus one" holds (one root). The check that expects a populated projection did not apply because the run was blocked with exit 2 and no result file, which the plan accepts.

## Open items

- `OfflineController.index` island route id `study-session` versus the router's `offline-study`: carried open, not renamed.
- Fidelity limits: simulator not physical speaker; simulator not signed device; synthetic_test_authority not real adopter; trusted local runner not cryptographic certification.
- Residual external gates: physical iPhone signed-device run; first adopter sanitized route handoff.

## Leftover resources

None: no simulator booted, port 4790 free, no run process. The empty run root `twin-01` and its `.exit`, `.started`, `.stdout` and `.stderr` files are kept as evidence.

## Self-Check: PASSED

- Run root, `.exit` (value 2) and `.started` exist; no `180-TWIN-RESULT.json`, as expected for exit 2.
- Zero TWIN rows marked Complete; all ten `- Tnn: not_observed` lines are in STATE.md.
- The guide hash in STATE.md matches the candidate file; the recovery `guides/see_it_run.md` is unchanged.
- `git diff --cached --name-only` in the recovery checkout is empty. No commits were made (`commits: 0`).
