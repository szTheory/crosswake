---
phase: 175-rehearsal-and-publish
plan: 59
subsystem: release-candidate
tags: [ios-mirror, preflight, fail-closed, lifecycle]
requires:
  - phase: 175-58
    provides: "Prior lifecycle and Plan58 preflight implementation, retained as immutable evidence"
provides:
  - "Closed Plan59 facts and separate repair-attempt eligibility/release-readiness classification"
  - "A new sanitized preflight and lifecycle record bound to one opaque attempt ID"
affects: [REL-13, REL-17, release-hold]
actuals:
  tokens: unknown
  tasks: 2
  commits: 0
  plan_head_before: unknown
tech-stack:
  added: []
  patterns:
    - "Fail-closed latest-run and complete-job-roster normalization"
    - "Separate aggregate required status from workflow job outcomes"
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan59-preflight.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan59.lifecycle.jsonl
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - lib/crosswake/release_candidate/ios_tag_source_evidence.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
    - test/crosswake/release_candidate/ios_tag_source_evidence_test.exs
key-decisions:
  - "Repair eligibility allows the aggregate Crosswake CI failure only when the complete workflow-job roster proves the parity leaf is the sole failed job and no unrelated required check fails."
  - "Incomplete latest-run, freshness, or tag-ruleset evidence remains UNKNOWN and keeps both classifications BLOCKED."
patterns-established: []
requirements-completed: []
coverage:
  - id: D1
    description: "Plan59 classifier separates repair evidence eligibility from release readiness."
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/ios_tag_source_evidence_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fresh read-only Plan59 attempt record is sanitized, digest-bound, and lifecycle-bound."
    verification:
      - kind: other
        ref: "Plan59 artifact and lifecycle readback validation"
        status: pass
    human_judgment: false
  - id: D3
    description: "An operation-specific decision remains unavailable while freshness and policy facts are UNKNOWN."
    verification: []
    human_judgment: true
    rationale: "The generated preflight is BLOCKED; only continued hold is eligible at the blocking decision."
duration: unknown
completed: 2026-10-01
status: halted
---

# Phase 175 Plan 59: D-75 Preflight Correction Summary

**The new classifier accepts only the single permitted parity-failure shape, while the fresh Plan59 attempt remains blocked because the complete run and tag-policy facts could not be established.**

## Accomplishments

- Added closed Plan59 preflight facts and separate repair-attempt eligibility and candidate release-readiness classifications.
- Added coverage for aggregate Crosswake CI failure explained by the sole parity leaf, unrelated required failures, incomplete job pages, mismatched heads, stale/future runs, and immutable attempt binding.
- Ran the read-only collector once and persisted a new sanitized preflight plus its lifecycle journal.
- Validated the artifact digest/schema and confirmed all lifecycle events use the same attempt ID.

## Fresh Preflight

Artifact: `evidence/175-ios-tag-026-plan59-preflight.json`  
Lifecycle: `evidence/175-ios-tag-026-plan59.lifecycle.jsonl`

- Attempt ID: `715ae99fb28ef5b4aff7a5077bc3fb50`
- Source tag `ios-core-v0.2.6` resolved to expected commit `998742856a37a97ae7247f6c532f9c154ea20885`.
- Target `refs/tags/v0.2.6` was observed absent. PR #219 remained open at expected head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d` and base `e51698528dc667ef89beb951e4b1ec91da74981`.
- Required `Crosswake CI` aggregate was FAILURE. The complete exact-head job roster, latest completed run, completion time, newer in-progress run state, and applicable mirror tag ruleset could not be established and are recorded UNKNOWN. Independent branch merge policy is UNKNOWN. Read-only push permission was TRUE.
- `repair_attempt_eligibility=BLOCKED` and `candidate_release_readiness=BLOCKED`. No operation is eligible.
- The lifecycle contains task-entry, reservation, and preflight-collected only. No source split, push dry-run, tag write, merge, Gate 2, recovery, registry action, or publication occurred.

## Verification

- Focused ExUnit suites: 27 tests, 0 failures.
- Plan59 artifact schema/digest and matching lifecycle attempt ID readback: passed.
- Fresh collector invoked once; UNKNOWN observations were not retried or synthesized.

## Checkpoint and Plan Status

Task 3 reached its designed blocking-human decision boundary. Because eligibility is BLOCKED, only `hold` is available for attempt `715ae99fb28ef5b4aff7a5077bc3fb50`. No option is preselected; no source or release operation was started. REL-13 and REL-17 remain OPEN, Plan 175-55 remains UNKNOWN, and the release hold remains ACTIVE.

The checkout's `.git` path is read-only under the active execution boundary, so task and metadata commits, the plan commit ledger, and standard GSD state SDK writes were not performed. Existing dirty worktree edits were preserved.

## Deviations and Issues

- The live collector could not prove the latest complete workflow roster, freshness, newer-run state, or matched tag-ruleset fact. It correctly persisted these as UNKNOWN and stopped eligibility. No retry was made.
- Commit bookkeeping was unavailable because `.git` is read-only; all local results remain reviewable in the workspace.

## Self-Check: PASSED

- Both Plan59 artifacts exist and reopen with the same attempt ID.
- Focused tests and artifact/lifecycle validation passed.
- No release-side operation or `.git` write occurred.
