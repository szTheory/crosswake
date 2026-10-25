---
phase: 180-bounded-digital-twin-demonstration
plan: 07
subsystem: proof-lane
status: complete
tags: [twin, blocked-receipt, handoff, run-twin-02]
requirements-completed: []
commits: 0
plan_head_before: da53c54db06e54be5a80fb4be144a70d3fed36a5
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
outcome: blocked_receipt
run_root: /private/tmp/crosswake-phase180-run/twin-02
process_exit_status: 1
projection_exit_status: 2
projection_overall_status: blocked
first_cause: attachment_check_unavailable
supersedes_record: 180-07-SUMMARY.twin-01.md
key-files:
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-TWIN-RESULT.json
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
---

# Phase 180 Plan 07: Twin run twin-02 and Handoff Summary

The second recorded twin run got much further than the first and wrote a receipt, but the receipt has every observation blocked, so no TWIN requirement is complete. The first run's account is kept unchanged in `180-07-SUMMARY.twin-01.md` (byte-for-byte copy), and the twin-01 evidence files in `/private/tmp/crosswake-phase180-run` were not touched.

## What was checked before the run

- I wrote the candidate record `/private/tmp/crosswake-phase180-run/twin-02-candidate.json` (mode 0600, outside any run root): candidate path, head `da53c54`, tree, origin `http://127.0.0.1:4790`, and digests computed from the real files. They match `180-IDENTITY.json`. No secrets or device identifiers.
- Local precheck, no run consumed: the record loaded through the production `TwinRuntime.prepare/1` and `TwinProducers.freeze/3` under MIX_ENV=test (scratch root, since deleted); port 4790 was free; `xcrun`, `xcodebuild`, `sqlite3`, `lsof`, `mix`, `git` and `perl` were present; an iPhone 17 device type and an iOS 26.5 runtime exist; `mix crosswake.gen.shell ios --check` reported current when run from `examples/phoenix_host` under MIX_ENV=test (from the candidate root it refuses, which is just where it must be run); the example host compiles. The `--identity` and `--candidate` argument shapes match the command's option parser. No defect was found in the precheck, so no fix was made. The guide text already described the record-file prerequisite correctly and was left unchanged.

## What happened in twin-02

`mix crosswake.proof_lane.verify_twin ios` ran once, from the candidate with MIX_ENV=test, into the fresh root `/private/tmp/crosswake-phase180-run/twin-02`, for about 19 minutes. It started its own backend, boundary and a fresh simulator, built the app, installed it once and passed the capture canary. Cases 1 and 2 ran and their channel files were collected. For case 3 (rejection and conflict) the journey could not list attachments for the result bundle, so it stopped with cause `attachment_check_unavailable` and wrote all 49 observations as `blocked` (the seven identity joins as `identity_unknown`). Cleanup removed the result bundles, databases and media from the run root, as designed.

A second fault came from the command itself. After writing the receipt and projection it tried to record the cause in a registry that the journey had already shut down, and crashed. The process exited 1, printed no four-line summary and left an Erlang stack trace on stderr. The files it had already written say exit 2 and overall `blocked`. Both numbers are kept as found; this is a harness defect in the candidate, not a finding about the twin.

What is unknown: why case 3 produced no attachment listing. The likely cause is the case hanging until its deadline (a keyboard hang was seen once in c3 during 180-06, and the elapsed time fits), but the case's `xcodebuild` result class was not retained in the receipt and its result bundle was deleted by cleanup, so this is not proven. Whether cases 4 and 5 and the replay, fence and disablement observations pass is also unknown, since they never ran.

## Outcome per group

T01 to T10: all `blocked`. Sub-observations: 49 blocked, 0 failed, 0 passed. 48 carry `attachment_check_unavailable`; TW-T10-02 carries `identity_unknown`.

## Requirements

TWIN-01 through TWIN-06 stay Pending (0 Complete). Phase 180 is not marked complete.

## Recorded results

- `180-TWIN-RESULT.json`: byte copy of the runner's `twin-result.json` (`cmp` equal; `receipt_sha256` equals the SHA-256 of `receipt.json`). Note for the verifier: the plan's check "projection exit_status equals the recorded `.exit` file" does not hold here (2 versus 1) because of the post-receipt crash; the copy was still made since a receipt was written.
- Run root contents after the run: `receipt.json`, `twin-result.json`, `expectations.json` and `obs/c1`, `obs/c2` channel files (closed vocabulary only). No `.xcresult`, database or media file remains. Run-root count went from 1 to 2 (exactly one new root).

## Handoff changes

- STATE.md: the twin-01 handoff moved into history as superseded; one active handoff now lists the ten group lines, the Failed or blocked line, the fidelity limits, the residual external gates and the guide hash.
- ROADMAP.md and REQUIREMENTS.md: text and the six TWIN rows now say twin-02 produced an all-blocked receipt; nothing marked complete.
- Guide: unchanged, SHA-256 `3e1263b5ceeb1fde37f6a471d0b493b23eedb140b10f4e1250f775f1ac867366`, pending a separately authorized delivery.

## Next action

Repair the candidate harness, then run once into a new root `twin-03`. Repairs: (1) stop `verify_twin` reading the registry after the journey shut it down (both the blocked-receipt path and the normal finish path read it, so a pass would crash the same way); (2) retain the per-case `xcodebuild` class in the receipt; (3) diagnose case 3 in a throwaway simulator, not as a recorded run. The command is `$gsd-execute-phase 180 --ws quality-ratchet-release --wave 6` once the repair is planned or amended into 180-07. Phase verification can run now only to report the gaps; it cannot pass.

## Deviations from Plan

- **[Plan wording] Candidate argument.** As in twin-01, the plan text says `--candidate /private/tmp/crosswake-phase180-impl`, but the command needs a record file. This run used the record file, as the orchestrator directed.
- **[Rule 1 - Bug, not fixed] Post-receipt crash in `verify_twin`.** Found at: the command's end. Cause: `TwinRuntime.record_failure/2` and `first_failure/1` use the registry Agent after `stop_all/1` has stopped it. Not fixed because the run is already recorded and a code change would alter the harness after the run; it is a candidate-only repair for the next run, not a core or generator defect.

## Known Stubs

None added.

## Open items

- `OfflineController.index` island route id `study-session` versus the router's `offline-study`: carried open, not renamed.
- Fidelity limits: simulator not physical speaker; simulator not signed device; synthetic_test_authority not real adopter; trusted local runner not cryptographic certification.
- Residual external gates: physical iPhone signed-device run; first adopter sanitized route handoff.

## Leftover resources

None running: no `crosswake-phase180` simulator, port 4790 free, no run xcodebuild or run-owned Phoenix process (an unrelated Elixir 1.17 `phx.server` that was already running before the run is not ours and was not touched). Kept as evidence: the twin-01 and twin-02 run roots and their `.exit/.started/.stdout/.stderr` files, the candidate record, the `run-once-02.sh` wrapper.

## Self-Check: PASSED

- `180-07-SUMMARY.twin-01.md` is byte-identical to the previous summary; twin-01 evidence files unchanged.
- `twin-02.exit` (1) and `twin-02.started` exist; `cmp` and receipt SHA check passed; 49 sub-observations, 10 ordered groups in the projection.
- Zero TWIN rows marked Complete; STATE.md has all ten `- Tnn:` lines, the Failed or blocked, Fidelity limits, Residual external gates and Guide pending reconciliation lines.
- Recovery checkout: `git diff --cached --name-only` empty; no commits (`commits: 0`).
