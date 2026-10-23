---
phase: 175-rehearsal-and-publish
plan: 120
subsystem: release-candidate-collector
tags: [timeout, subtree-split, fail-closed, local-only]
dependency_graph:
  requires: [175-119]
  provides: [bounded-subtree-split-timeout]
  affects: [plan105-mirror-tag-collector]
tech_stack:
  added: []
  patterns: [stage-specific process budgets, injected fake process runner]
key_files:
  created: [175-120-SUMMARY.md]
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
decisions:
  - Only SUBTREE_SPLIT receives the longer process cap; all caps remain clipped to the existing overall deadline.
  - Local verification does not establish candidate, permission, readiness, or release authority.
metrics:
  duration: not measured
  completed: 2026-10-09
status: complete
actuals:
  tokens: 4400
  tasks: 2
  commits: 0
---

# Phase 175 Plan 120: SUBTREE_SPLIT Timeout Repair Summary

Only the Plan105 `SUBTREE_SPLIT` process can use a per-process timeout up to 240,000 ms, clipped to the existing overall deadline; all other Git processes remain capped at 15,000 ms.

## Tasks

1. Added fake-runner assertions for the split-only cap, deadline clipping, unchanged ordinary-process cap, and no process start after expiry.
2. Added timeout and uncertain-exit preflight regressions. Both preserve `UNKNOWN` Git-operation accounting, emit safe process diagnostics, invoke the split once, perform no dry run or tag attempt, and redact sentinel output/errors.

## Verification

- `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs` — passed, 66 tests, 0 failures.
- Tests use injected process and transport callbacks with deadline values; no long timeout wait or provider request occurred.

## TDD Record

- **RED:** Before implementation, the four new budget/deadline cases failed at their intended stage/timeout assertions: the test seam did not expose stage identity or a timeout budget, and the expired-deadline helper still used its fixed future deadline. The observed TAP report named those failing assertions; the full RED report was not persisted separately.
- **GREEN:** Added an explicit `SUBTREE_SPLIT` budget of 240,000 ms and passed the computed, deadline-clipped budget to the fake seam and native process timer. The existing no-start-after-deadline guard and process classification were retained.
- **REFACTOR:** No additional refactor.
- **Commit gate:** No commits were made. The execution instruction prohibited git metadata writes because `.git` is read-only. The TDD report classifier and commit-ledger checks were not run under the constraint to use only the named local test command.

## Release Posture and Handoff

Phase174 remains the last completed phase; Phase175 remains IN PROGRESS and INCOMPLETE. Plan106 remains held. REL-13/14/15/17 remain OPEN; readiness is BLOCKED; write permission and merge policy are UNKNOWN; tag authority is NONE; the release hold is ACTIVE. No release facts or authority changed.

Plan119's attempt and ALLOW are spent. This local repair performed no credential lookup, scope preparation, provider request, CI, dry run, tag, merge, registry, or publication action. Any future live read requires a new scope, displayed exact card, and separate exact ALLOW. The five unclassified fallback items and all 23 unresolved spec-less probe edge rows remain unresolved and visible.

The next planning command is `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan any fresh bounded read scope. This repair itself authorizes no read. Changes remain uncommitted.

## Deviations from Plan

- **Commit and ledger steps omitted by environment constraint:** `.git` is read-only in this execution environment. No task or metadata commits were possible or attempted; `actuals.commits` is 0.

## Self-Check: PASSED

The collector, test file, Plan120 summary, and three Phase175 handoff/index files exist. The named test command passed. No commit claims are made; repository changes remain uncommitted.
