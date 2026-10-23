---
phase: 177-maintenance-and-queue-reconciliation
plan: "04"
subsystem: maintenance
tags: [github, graphql, queue, node, privacy]
requires:
  - phase: 177-maintenance-and-queue-reconciliation
    provides: Scoped decisions D-15 through D-20 and the MAINT-05 acceptance boundary
provides:
  - Read-only paginated collector and fail-closed inventory validator
  - Dated metadata-only inventory for all open issues and pull requests
affects: [MAINT-05, Phase 178 queue handoff]
actuals:
  tokens: 14908
  tasks: 2
  commits: 0
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
tech-stack:
  added: []
  patterns: [Node stdlib subprocess fixtures, separate GraphQL cursor exhaustion, final roster refresh]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/collect_queue.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/queue-inventory.json
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-04-SUMMARY.md
  modified: []
key-decisions:
  - "Use metadata-only GraphQL collection with independent issue and pull-request pagination and a second full roster read."
  - "Keep every current object open in the local inventory until its scoped evidence is checked; do not mutate GitHub."
requirements-completed: []
coverage:
  - id: D1
    description: Read-only collector and inventory checker reject incomplete, duplicated, malformed, denied, or drifting queue data.
    requirement: MAINT-05
    verification:
      - kind: unit
        ref: node --test .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.test.mjs
        status: pass
    human_judgment: false
  - id: D2
    description: Current queue snapshot has one disposition and next action for every observed issue and pull request.
    requirement: MAINT-05
    verification:
      - kind: other
        ref: node .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.mjs .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/queue-inventory.json
        status: pass
    human_judgment: true
    rationale: Final acceptance must confirm the local accountability roles and object-specific actions before MAINT-05 is marked complete.
duration: 18 min
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 04: Current Queue Inventory Summary

**Read-only GraphQL collector and validated current queue inventory: 20 open issues and 3 open pull requests, each with one bounded local disposition.**

## Performance

- **Duration:** About 18 minutes
- **Started:** 2026-10-12 (exact start time was not captured)
- **Completed:** 2026-10-12
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a phase-local Node collector that invokes only `gh api graphql`, exhausts issue and pull-request connections separately, validates counts and cursors, preserves safe relationships and PR head/base/check metadata, and compares a second full read.
- Added a real subprocess fixture and validator covering the successful cross-kind collision and two-page reads plus duplicate, null, malformed, denied, nonzero, incomplete, cursor-loop, stale-refresh, and unsafe-content cases.
- Captured a current metadata-only roster with 20 issues and 3 pull requests; all 23 identities are unique and all 23 have one explicit local disposition, rationale, accountable role, next action, trigger, evidence reference, and release-proposal flag.
- Held the release-proposal PR pending separate selection and fresh exact-candidate evidence. No comments, labels, assignments, closures, merges, force-runs, or publication were attempted.

## Files Created

- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/collect_queue.mjs` — fixed read-only GraphQL subprocess, separate pagination, safe output allowlist, and two-pass roster refresh.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.mjs` — schema, count, uniqueness, ordering, relationship, refresh, privacy, and disposition checks.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.test.mjs` — fake `gh` executable fixture using actual subprocess stdout, stderr, exit status, and production argv.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/queue-inventory.json` — dated live roster and local dispositions; contains no title, body, author, assignee, raw log, or credential fields.

## Decisions Made

- Used two complete metadata reads and required a matched final roster before reporting a complete queue.
- Left MAINT-05 in `requirements-completed` empty for parent final acceptance of the action and accountability semantics.

## Deviations from Plan

- The protected recovery-checkout guard prohibits staging and commits. The five assigned phase-local artifacts remain uncommitted at the unchanged checkout HEAD; no unrelated files were staged or changed by this plan.
- The inventory assigns accountable project roles without inferring GitHub assignees. Parent final acceptance is still required to confirm role routing and mark MAINT-05 complete.

## TDD Gate Compliance

- RED: tests were authored before the collector/checker, but the observed initial failure was a missing-module condition, so it is not valid semantic RED evidence under the strict gate.
- GREEN: all 12 positive and adverse tests pass after implementation.
- RED/GREEN commits were not created because the protected recovery-checkout rule forbids staging and commits; strict commit-gate compliance remains unproven.

## Verification

- `node --test .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.test.mjs` — 12 passed, 0 failed.
- `node .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.mjs .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/queue-inventory.json` — valid.
- Live read and final roster refresh — complete; 20 issues, 3 pull requests; refresh matched.

## Self-Check: PASSED

- Collector, checker, fixture, inventory, and summary files exist.
- All 23 inventory objects have unique `(kind, number)` identities and one validated disposition each.
- No task commits exist; this is required by the protected recovery-checkout guard.
