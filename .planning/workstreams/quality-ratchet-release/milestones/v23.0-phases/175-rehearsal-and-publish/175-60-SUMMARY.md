---
phase: 175-rehearsal-and-publish
plan: 60
subsystem: release-candidate
tags: [ios-mirror, preflight, fail-closed, lifecycle]
requires:
  - phase: 175-57
    provides: "Runnable release-candidate predecessor and maintained runner seam"
provides:
  - "Fail-closed Plan60 exact-attempt classifier, collector, and artifact readback"
  - "New immutable Plan60 preflight and lifecycle record ending in a blocked hold"
affects: [REL-13, REL-17, release-hold]
actuals:
  tokens: unknown
  tasks: 3
  commits: 0
  plan_head_before: unknown
tech-stack:
  added: []
  patterns:
    - "Fresh source identity and latest completed-attempt facts; missing values remain UNKNOWN"
    - "Exhaustive check and declaration reconciliation blocks on incomplete observations"
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-60-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan60-preflight.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan60.lifecycle.jsonl
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - lib/crosswake/release_candidate/ios_tag_source_evidence.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
    - test/crosswake/release_candidate/ios_tag_source_evidence_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/continue.md
key-decisions:
  - "Plan60 repair eligibility is BLOCKED because the current attempt roster, completion freshness, aggregate proof, observed/declaration check reconciliation, and target tag ruleset are UNKNOWN."
  - "The sole available Task 3 disposition was hold; no source or release operation was authorized."
patterns-established: []
requirements-completed: []
coverage:
  - id: D1
    description: "CLI transport, exact-attempt roster, GraphQL/effective declaration reconciliation, freshness, and tag policy fail closed."
    verification:
      - kind: unit
        ref: "paired focused ExUnit suites"
        status: pass
    human_judgment: false
  - id: D2
    description: "A new sanitized Plan60 attempt artifact and lifecycle reopen with one matching opaque ID."
    verification:
      - kind: other
        ref: "Plan60 read-only artifact validator"
        status: pass
    human_judgment: false
  - id: D3
    description: "The exact source-operation decision is blocked while required live facts are UNKNOWN."
    verification: []
    human_judgment: true
    rationale: "Repair eligibility is BLOCKED; only continued hold is available."
duration: unknown
completed: 2026-10-01
status: halted
---

# Phase 175 Plan 60: D-76 Exact-Attempt Preflight

**The corrected Plan60 collector produced a fresh, sanitized attempt, but incomplete CI, required-check, and tag-policy observations keep repair eligibility BLOCKED and the release hold ACTIVE.**

## Accomplishments

- Corrected the paginated GitHub CLI JSON transport and implemented the Plan60 collector, classifier, lifecycle, and readback validation.
- Removed historical source-OID fallbacks and bound eligibility to a freshly resolved valid source OID. Missing or malformed identities remain UNKNOWN and cannot qualify through `nil == nil`.
- Derived attempt completion from exact-attempt job completion data. Missing or malformed completion remains UNKNOWN.
- Added aggregate/job roster checks, GraphQL observed-check and effective declaration reconciliation, guarded one-shot rerun handling, and inherited tag-rule evaluation.
- Fixed a fixture collision caused by a numeric temporary-path suffix repeating across Mix VM invocations; focused test helpers now use random suffixes.
- Ran the live collector exactly once, then ran the read-only Plan60 artifact validator.

## Exact Plan60 Attempt and Decision

Artifact: `evidence/175-ios-tag-026-plan60-preflight.json`  
Lifecycle: `evidence/175-ios-tag-026-plan60.lifecycle.jsonl`

- Attempt ID: `50d72eab13580c476df0079a6515a83f`.
- Fresh source tag `ios-core-v0.2.6` resolved to commit `998742856a37a97ae7247f6c532f9c154ea20885`. Target `refs/tags/v0.2.6` is ABSENT.
- PR #219 is OPEN. Its live head and base match the candidate identity recorded in the artifact.
- Run ID, attempt number, completion timestamp/age, exact job roster, latest-run status, newer same-head activity, and aggregate proof are UNKNOWN. No run jobs were normalized.
- The GraphQL observed-check total and unique count are both zero, while observed-check completeness is UNKNOWN. Effective declaration count is zero, declaration completeness is UNKNOWN, and required-check reconciliation is UNKNOWN.
- Tag-ruleset completeness and target creation restriction are UNKNOWN. Independent branch policy is UNKNOWN. Read-only push permission is TRUE.
- CI rerun is `NOT_REQUESTED`. The lifecycle contains task-entry, reservation, and preflight-collected only; it has no rerun intent or request. No CI rerun was dispatched.
- `repair_attempt_eligibility=BLOCKED` and `candidate_release_readiness=BLOCKED`.

Task 3 therefore had only one eligible disposition: **hold**. No source split, push dry-run, tag write, merge, Gate 2, recovery, registry write, or publication occurred. Plan 175-55 remains UNKNOWN, REL-13 and REL-17 remain OPEN, and the release hold remains ACTIVE. Plan58/59 evidence bytes and IDs remain unchanged.

## Verification

- `mix format` on the four scoped source and test files: passed.
- Paired focused ExUnit suites: 44 tests, 0 failures, three consecutive runs after the fixture-path correction.
- `validate_plan60_artifacts!()`: passed.
- Plan58/59 pre/post artifact and lifecycle byte comparisons: unchanged.
- Durable lifecycle readback confirmed no CI rerun intent/request. The collector was not repeated.

## Deviations and Constraints

- The collector could not establish the exact current run/jobs, freshness, aggregate relation, complete observed/declaration check sets, or applicable target tag-ruleset facts. These were persisted as UNKNOWN and eligibility remained BLOCKED; no retries or historical facts were substituted.
- The `.git` directory is read-only for this execution. No task or metadata commits, staging, plan-head ledger, or git metadata writes were performed. Existing dirty worktree edits were preserved.

## Self-Check: PASSED

- Summary, Plan60 artifact, and lifecycle exist.
- The artifact validator passed and the lifecycle is bound to the same attempt ID.
- Plan58/59 artifacts remain unchanged; no rerun or release-side operation occurred.
