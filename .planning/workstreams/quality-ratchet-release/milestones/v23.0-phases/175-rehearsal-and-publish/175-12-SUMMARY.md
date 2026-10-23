---
phase: 175-rehearsal-and-publish
plan: 12
subsystem: release-evidence
tags: [release-please, canonical-receipt, hex, ios, maven-central]
requires:
  - 175-11 recovery and fire-drill isolation guards
provides:
  - fresh exact-candidate receipt and rehearsal evidence for Gate 2
  - isolated Maven VALIDATED-to-DROP evidence with candidate-head equality
affects:
  - 175-13 fresh Gate 2 decision
tech-stack:
  added: []
  patterns: [immutable-artifact-validation, exact-oid-binding, independent-registry-absence]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-candidate-pr.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-fresh-registry-absence.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-FRESH-CANDIDATE-EVIDENCE.md
decisions:
  - Fresh candidate evidence is bound to PR 196 and never reuses the historic 0.2.2 intent.
  - Maven rehearsal remains a dedicated disposable VALIDATED-to-DROP flow and must preserve the candidate head.
metrics:
  duration: 2h
  completed: 2026-09-23
  tasks_completed: 3
status: complete
plan_head_before: db7ccc124b118326621da50ede72adf3e5097ed1
commits: 3
actuals:
  tokens: 1923
  tasks: 3
  commits: 3
---

# Phase 175 Plan 12: Fresh Candidate Gate 2 Evidence Summary

Fresh `0.2.3` candidate PR #196 is now backed by exact, zero-mutation Hex/iOS/receipt/Maven rehearsal evidence and independent three-registry absence checks.

## Completed Tasks

1. Recorded the fresh Release Please candidate identity: exact remote base/head/tree, required CI, historic-intent difference, and runbook ancestry.
2. Validated the immutable canonical receipt artifact for the same identity, including the fresh Hex and iOS rehearsal records and the missing-receipt red / matching-receipt green proof.
3. Ran the isolated Maven fire drill once: run `35860341954` reached `VALIDATED`, dropped deployment `46132a1c-6492-43e0-9973-898c693c78bf`, and left the candidate head unchanged; direct Hex, iOS-tag, and Maven checks all remained absent.

## Verification

- Exact receipt JSON and its SHA-256 validated against PR #196’s base/head/tree/version; artifact `10729014450` was unexpired.
- `MIX_ENV=test` focused Phase 175 recovery proof: 5 tests, 0 failures, using the existing dependency cache read-only and an isolated build directory.
- `elixir script/check_release_workflow_integrity.exs`: 76/76 checks passed.
- Evidence predicates passed: all registry `absent` fields are true, and Maven’s recorded before/after heads are identical.

## Deviations from Plan

None - plan executed exactly as written. The focused test reused an existing dependency cache read-only because this isolated execution checkout had no local dependency directory; it wrote build output only to a temporary directory that was removed before commit.

## Self-Check: PASSED

- Fresh candidate JSON, registry-absence JSON, and complete evidence record exist on disk.
- Task commits `1dc33986`, `e1bd0df6`, and `2a91d1c3` exist on the isolated phase branch.
