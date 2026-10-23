---
phase: 175-rehearsal-and-publish
plan: 19
subsystem: release-pipeline
tags: [candidate-identity, rehearsal, receipt-attestation, release-gate]
requires:
  - phase: 175-18
    provides: "Read-only recovery reconciliation and 0.2.4 candidate eligibility"
provides:
  - "Fresh exact-candidate preflight and Hex/iOS/Maven rehearsal evidence for PR #201"
  - "Explicit pending, unauthorized Gate 2 record and a documented canonical-receipt producer gap"
affects: [175-20, release-pipeline]
actuals:
  tokens: 5215
  tasks: 1
  commits: 3
plan_head_before: 58ac8bf6fbfbea5b63921a32828932dad3a414f5
tech-stack:
  added: []
  patterns:
    - "Reconcile only normalized workflow artifacts and exact remote OIDs; do not retain raw logs or secret-bearing output."
    - "Keep Gate 2 pending when the attestation workflow has no trusted source for its required canonical payload."
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-FRESH-CANDIDATE-0.2.4.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-FRESH-GATE-2-0.2.4.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-candidate-0.2.4.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-gate-2-0.2.4.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-19-SUMMARY.md
  modified: []
key-decisions:
  - "Did not dispatch canonical receipt attestation: the workflow accepts and validates a payload but does not produce it, and the standalone Mix task has no wired observation input."
  - "Did not synthesize or locally author canonical receipt JSON; the plan explicitly forbids it. Gate 2 remains PENDING, unauthorized, and null."
requirements-completed: [REL-11]
coverage:
  - id: D1
    description: "Fresh exact-candidate preflight and all three isolated rehearsals passed without publishing the 0.2.4 coordinates."
    requirement: REL-11
    verification:
      - kind: integration
        ref: "CI 35927192087; Hex 35946263493; iOS 35946390085; Maven 35946548359"
        status: pass
      - kind: other
        ref: "Runbook ancestry checks for exact base/head and PR #201 Maven head before/after equality"
        status: pass
    human_judgment: false
  - id: D2
    description: "Canonical receipt attestation could not run because no trusted repository-owned payload producer is available."
    verification:
      - kind: other
        ref: "Repository search and inspection of mix task, attestation workflow, and candidate CI artifacts"
        status: unknown
    human_judgment: false
    rationale: "This is an automation integration gap, not a human-verification task; the producer must be added or identified before Gate 2."
duration: 24m
completed: 2026-09-24
status: halted
---

# Phase 175 Plan 19: Fresh Candidate Rehearsal and Gate 2 Preparation

**PR #201's exact `0.2.4` candidate passed fresh CI/ancestry/absence preflight and all three safe rehearsals; canonical receipt attestation remains blocked by the missing trusted payload producer, so Gate 2 stays pending and unauthorized.**

## Performance

- **Duration:** approximately 24 minutes
- **Started:** 2026-09-24T02:02:00Z
- **Completed:** 2026-09-24T02:26:00Z
- **Tasks:** Task 1 complete; Task 2 rehearsals and controls complete, receipt-attestation substep halted
- **Files modified:** 5 (four evidence outputs plus this summary)

## Accomplishments

- Refreshed PR #201's exact base/head/tree/version, branch, strict required-check policy, green CI, runbook ancestry, and independent Hex/iOS/Maven absence observations.
- Ran Hex candidate rehearsal `35946263493`: exact identity, six packages, no external state change.
- Ran iOS mirror rehearsal `35946390085`: PASS/PROVEN, deterministic split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, no external state change.
- Ran Maven fire drill `35946548359`: disposable coordinate reached `VALIDATED -> DROP`; candidate PR head remained `2fdf71b917e3538c6ecc74d1894602e82926281e` before and after.
- Ran the focused recovery test (5 tests, 0 failures) and release workflow integrity scanner (76/76 checks pass).
- Persisted Gate 2 as pending, unauthorized, with null authorization. No merge, ordinary publish, recovery, or Gate 2 decision was dispatched.

## Task Commits

1. **Candidate preflight, rehearsals, and pending Gate 2 evidence** — `0eabd2d3` (docs)

The summary is committed separately as plan metadata.

## Files Created/Modified

- `175-FRESH-CANDIDATE-0.2.4.md` and `evidence/175-fresh-candidate-0.2.4.json` — fresh candidate, CI, absence, ancestry, and rehearsal observations.
- `175-FRESH-GATE-2-0.2.4.md` and `evidence/175-fresh-gate-2-0.2.4.json` — exact candidate/run binding and explicit pending/unauthorized Gate 2 state.
- `175-19-SUMMARY.md` — this execution record.

## Decisions Made

- Used the exact candidate CI receipt digest as the rehearsals' shape-validated capture input; no canonical receipt was claimed from that CI artifact.
- Did not dispatch attestation because its required canonical payload has no trusted producer in the repository. The workflow requires `payload_base64` and SHA in its input envelope, then validates the supplied payload; it does not create one. `mix crosswake.release.candidate` has no CLI-wired `input` or `input_adapter` and raises `candidate observations are unavailable` without one. The fresh CI artifact contains a CI receipt, not the required `phase168-candidate-receipt-<head>` artifact.
- Did not locally synthesize or edit canonical receipt JSON. The missing producer is a real automation gap and must be repaired in a separately planned change before Gate 2.

## Deviations from Plan

**1. Task 2 halted before receipt attestation — canonical payload producer is absent.**

- **Found during:** Task 2, after all three rehearsals completed.
- **Issue:** `ios-mirror-backfill.yml`'s attestation dispatch requires a Base64 receipt payload, but no workflow or CLI command in the repository generates that payload from the exact CI/Hex/iOS observations.
- **Resolution:** Read-only inspection confirmed there is no approved producer; did not fabricate or locally create a receipt. Recorded receipt/artifact as unavailable and kept Gate 2 `PENDING`, `authorized=false`, `authorization=null`.
- **Verification:** Focused regression tests passed 5/5; structural integrity scanner passed 76/76. These do not stand in for a live matching receipt.
- **Impact:** Plan 175-20 must not present or consume Gate 2 until a trusted producer supplies a receipt bound to this exact candidate and rehearsals.

## Issues Encountered

- The workspace `.git` directory is read-only, so exact public objects were fetched only into a disposable `/private/tmp` repository for the runbook ancestry helper. The helper passed for both candidate base and head. No workspace ref was changed by that fetch.
- No GH authentication or API throttling issue occurred. All three rehearsal dispatches completed successfully.

## Next Phase Readiness

The three rehearsals and candidate identity evidence are ready. Gate 2 is **not** ready: a trusted canonical receipt payload producer is missing. Do not merge PR #201, start the ordinary release graph, or reuse the consumed `publish fresh core 35809832762` token. Resolve the producer integration, re-attest the exact candidate, and only then use a fresh blocking Gate 2 decision.

## Self-Check: PASSED

- All four Plan 175-19 evidence artifacts and this summary exist.
- Evidence commit `0eabd2d3` exists.
- Both JSON evidence files parse; explicit Gate 2 assertions confirm `PENDING`, `authorized=false`, and `authorization=null`.
- Focused regression suite passed (5 tests, 0 failures); workflow integrity scanner passed (76/76).

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-24*
