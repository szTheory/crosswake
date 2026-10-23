---
phase: 175-rehearsal-and-publish
plan: 61
subsystem: release-candidate
tags: [github-actions, graphql, fail-closed]
requires:
  - phase: 175-57
    provides: "Runnable release-candidate predecessor and maintained runner seam"
provides:
  - "Bounded workflow-scoped Actions run discovery bound to exact head SHA and PR #219 association"
  - "CheckSuite app binding and base-ref declaration normalization against exact OIDs"
affects: [175-62, REL-13, REL-17, release-hold]
actuals:
  tokens: unknown
  tasks: 1
  commits: 0
  plan_head_before: unknown
tech-stack:
  added: []
  patterns:
    - "Bounded per-page collection with strict completeness and identity checks"
    - "Structured app-bound branch checks take precedence over legacy context names"
key-files:
  created: []
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
key-decisions:
  - "Run discovery is limited to the Crosswake CI workflow, exact head SHA, and a complete roster capped at 1,600 records."
  - "Branch protection declarations accept the GraphQL short ref name only when the target OID matches exactly."
requirements-completed: []
coverage:
  - id: D1
    description: "Run, required-check, and branch-declaration normalization now fail closed on incomplete or mixed observations."
    verification:
      - kind: unit
        ref: "mix test test/crosswake/release_candidate/ios_tag_source_runner_test.exs"
        status: pass
    human_judgment: false
duration: unknown
completed: 2026-10-01
status: complete
---

# Phase 175 Plan 61: Exact-SHA Collector Corrections Summary

**Plan60's reproducible Actions and GraphQL collection defects now have bounded implementations and focused regressions.**

## Accomplishments

- Replaced Plan60's branch-wide run history scan with workflow-scoped requests filtered by the validated head SHA. Collection stops at 16 pages or 1,600 runs and rejects incomplete pages, changing totals, duplicate identities, and mismatched workflow, head, base, or status facts.
- Accepted runs must include an associated PR #219 entry with the exact expected `head.sha` and `base.sha`. Other pull request associations are allowed when that exact candidate association is present.
- Moved required check app identity to `CheckSuite.app` and bound it with the suite commit, workflow run ID, and attempt.
- Accepted GraphQL's short base-ref name only when the ref target OID matches the expected base. Structured app-bound contexts win; legacy names fill only contexts missing from that structured set.
- Added local regression coverage for exact-SHA request construction, pagination caps and completeness, candidate PR association, mixed identities, CheckSuite app identity, branch-ref/OID binding, duplicate contexts, and the existing tag-ruleset fixture.

## Verification

- `mix format lib/crosswake/release_candidate/ios_tag_source_runner.ex test/crosswake/release_candidate/ios_tag_source_runner_test.exs`: passed.
- `mix test test/crosswake/release_candidate/ios_tag_source_runner_test.exs`: 26 tests, 0 failures.
- `mix format --check-formatted lib/crosswake/release_candidate/ios_tag_source_runner.ex test/crosswake/release_candidate/ios_tag_source_runner_test.exs`: passed.
- `git diff --check` on the two scoped files: passed.
- No GitHub/API calls, live collector, CI rerun, release operation, or Plan60 evidence/lifecycle write occurred.

## TDD Gate Compliance

- The nested `CheckSuite.app` regression failed on its intended assertion before the normalizer change. `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK` using a temporary TAP wrapper around the ExUnit target, since the gate parser consumes Node TAP output.
- The focused ExUnit suite passed after implementation. RED/GREEN commits were omitted because this delegated execution explicitly prohibited Git metadata writes.

## Deviations and Constraints

- No per-task or summary commit was created. The parent execution boundary forbade staging, commits, and other Git metadata writes; code and documentation remain in the shared working tree for the orchestrator.
- Plan60's BLOCKED artifact and lifecycle remain historical and immutable. Plan55 remains UNKNOWN; REL-13 and REL-17 remain OPEN; the release hold remains ACTIVE.

## Self-Check: PASSED

- The focused verification command passed and the two scoped source/test files are present.
- Plan60's artifact and lifecycle were not written by this task. Their pre-existing untracked status was preserved.
