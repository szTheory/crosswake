---
phase: 175-rehearsal-and-publish
plan: 68
subsystem: release-diagnostics
tags: [exact-head, read-only-collection, fail-closed]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan67 manifest-aligned aggregate evaluator
provides:
  - Closed Plan68 exact-head evidence schema and lifecycle validation
  - One bounded read-only collection result for PR #219
affects: [quality-ratchet-release, phase-175-release-diagnostics]
actuals:
  tokens: 22879
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns: [injected read-only provider seam, exclusive attempt lifecycle, sanitized derived evidence]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan68-exact-head.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan68-exact-head.lifecycle.jsonl
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-SUMMARY.md
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - lib/crosswake/release_candidate/ios_tag_source_evidence.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
    - test/crosswake/release_candidate/ios_tag_source_evidence_test.exs
key-decisions:
  - "Treat the observation as UNKNOWN when any required exact-head source cannot be completely reconciled; do not retry the reviewed collection."
  - "Keep candidate readiness BLOCKED, release hold ACTIVE, and merge-policy status UNKNOWN regardless of observation completeness."
requirements-completed: []
duration: not measured in delegated execution context
completed: 2026-10-02
status: complete
---

# Phase 175 Plan 68: Exact-Head Evidence Collection Summary

**Plan68 adds a bounded exact-head collector and retained one UNKNOWN result for PR #219 because a complete exact run and policy observation could not be established.**

## Accomplishments

- Added the `crosswake-plan68-exact-head/v1` closed evidence schema, pure classifier, bounded projection, and private injected read adapter.
- Added exhaustive run/job/check pagination checks, exact head/run/attempt bindings, REST and GraphQL required-declaration union with source provenance, and same-byte workflow digest/classification handling.
- Added an opaque exclusive attempt lifecycle and artifact writer with fsync, readback, canonical digest verification, and replay/path rejection.
- Added local fakes for valid and stalled multi-page connections, duplicate identities, additive and contradictory declarations, GraphQL partial errors, oversized workflow responses, projection consistency, and occupied-path replay.
- The temporary `Mix.Tasks.Crosswake.Release.Plan68` entrypoint was removed after the local artifact validator passed, as required by Task 3.

## Collection Outcome

Exactly one reviewed `mix crosswake.release.plan68 --pr 219 --json` invocation ran. The collector read the PR identity, then could not produce a complete normalized run/check/policy/workflow observation. Its terminal result is `UNKNOWN`; raw provider responses were intentionally discarded, so the specific failing source was not retained and cannot be distinguished from the bounded aggregate reason set. No retry or second collection was made.

- **Artifact SHA-256:** `2a19820aaa55a0fd19a970e9f959919f35a95869a0d7c3794aa8f127e371123c`
- **PR:** #219, OPEN; observed head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`; base `e51698528dc667ef89beb951e4eb1ec91da74981`.
- **Retained run/job/check counts:** 0/0/0; run ID and workflow digest are UNKNOWN.
- **Reason codes:** `identity_mismatch`, `run_roster_incomplete`, `stale_run`, `job_roster_incomplete`, `check_roster_incomplete`, `declarations_incomplete`, `declaration_mismatch`, `workflow_unavailable`. These are fail-closed unknown indicators, not claims that each source was individually observed to be wrong.
- **Authority:** Plan55 remains UNKNOWN; REL-13 and REL-17 remain OPEN; candidate readiness is BLOCKED; release hold is ACTIVE; merge-policy status is UNKNOWN.

The collector was invoked once; the number of underlying read API requests was not retained. No write request, CI rerun, source operation, tag, merge, Gate 2, recovery, registry write, or publication was performed.

## Verification

- `mix format` on the two source files, temporary task module, and two focused test files — passed.
- `mix test test/crosswake/release_candidate/ios_tag_source_runner_test.exs test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` — 81 tests, 0 failures.
- One reviewed collection command — emitted a sanitized UNKNOWN projection; no retry.
- `mix run -e 'Crosswake.ReleaseCandidate.IosTagSourceRunner.validate_plan68_artifacts!()'` — passed with exit code 0; artifact and five-event lifecycle agree on attempt, classification, reason, and digest.

## Task Commits

No task or metadata commits were made. Git writes were prohibited by the execution boundary; existing user modifications were preserved.

## Deviations from Plan

None in execution flow. The plan explicitly permits a terminal UNKNOWN artifact when any observation is incomplete. The temporary Mix task was removed after validation; Plan68’s private evidence handling and focused fake tests remain.

## Self-Check: PASSED

- Both new evidence files and this summary exist.
- The local Plan68 artifact/lifecycle validator passed.
- The required focused suites passed, and no second remote collection occurred.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-02*
