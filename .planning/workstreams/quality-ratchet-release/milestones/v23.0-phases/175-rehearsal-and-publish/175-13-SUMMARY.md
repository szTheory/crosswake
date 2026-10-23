---
phase: 175-rehearsal-and-publish
plan: 13
subsystem: release-evidence
tags: [release-please, canonical-receipt, hex, ios, maven-central, authorization]
requires:
  - phase: 175-12
    provides: fresh exact-candidate receipt, rehearsal, Maven-drop, and registry-absence evidence
provides:
  - normalized, current Gate 2 evidence bound to PR #196 exact OIDs
  - candidate-specific maintainer authorization bound to iOS rehearsal run 35809832762
affects: [175-14 protected merge and ordinary three-registry publish]
tech-stack:
  added: []
  patterns: [exact-oid-binding, immutable-receipt-validation, one-way typed authorization]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-FRESH-GATE-2.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-gate-2.json
  modified: []
key-decisions:
  - "Gate 2 authorization is valid only for PR #196 / 0.2.3 and fresh iOS rehearsal run 35809832762."
  - "REL-10 remains historically breached at Gate 1; fresh base/head ancestry PASS is not retroactive repair."
requirements-completed: []
metrics:
  duration: 2h 25m
  completed: 2026-09-23
  tasks_completed: 2
status: complete
plan_head_before: f0cef83f6d2102fede45410d3a9a968ed9b2b926
commits: 2
actuals:
  tokens: 1716
  tasks: 2
  commits: 2
---

# Phase 175 Plan 13: Fresh Gate 2 Authorization Summary

Fresh PR #196 / `0.2.3` Gate 2 evidence binds every rehearsal, receipt, runbook check, and registry-absence observation to exact OIDs, and records the new typed authorization required before Plan 175-14 may mutate external state.

## Performance

- **Duration:** 2h 25m
- **Completed:** 2026-09-23T17:10:36Z
- **Tasks:** 2/2
- **Files created:** 2

## Accomplishments

- Refreshed secret-free Gate 2 evidence for exact candidate PR #196, including fresh direct absence at Hex, the iOS mirror, and Maven.
- Proved exact remote base/head runbook ancestry while keeping historic Gate 1 REL-10 accurately marked as breached.
- Recorded the only accepted candidate-specific authorization: `publish fresh core 35809832762`.

## Task Commits

1. **Task 1: Refresh the exact fresh-candidate Gate 2 evidence** — `4ad7e325` (docs)
2. **Task 2: Gate 2 of 3 — authorize the fresh three-registry core publish** — `8a983d30` (docs)

## Verification

- Gate JSON jq predicate passed for exact candidate identity, Hex/iOS/Maven rehearsal values, receipt red/green boundary, runbook ancestry, current registry absence, and historic no-retry/no-bypass facts.
- Gate Markdown required-fact grep and `git diff --check` passed.
- The Gate 2 decision record exact-line predicate passed and binds its typed token to fresh iOS rehearsal run `35809832762`.

## Decisions Made

- The historic `publish core 35554774599` approval is consumed and rejected; only the fresh candidate token is accepted.
- Plan 175-14 is authorized to perform the ordinary graph's first mutation, but this plan performed no merge, publish, tag, retry, dispatch, or bypass.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A supplemental local Mix recovery-test attempt could not open its sandbox PubSub socket. This did not replace or block the plan's specified evidence predicates, which passed using the immutable receipt/rehearsal artifacts and current direct checks.

## Next Phase Readiness

Plan 175-14 may consume only the recorded authorization for PR #196 / `0.2.3`; it must not accept a historic token or mutate a different candidate.

## Self-Check: PASSED

- Both evidence artifacts exist and task commits `4ad7e325` and `8a983d30` exist in git history.
