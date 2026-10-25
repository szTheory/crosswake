---
phase: 177-maintenance-and-queue-reconciliation
reviewed: 2026-10-12T16:59:55Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - README.md
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - docs/RELEASE-INCIDENT-RESPONSE.md
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/release_candidate/companion_receipt_test.exs
  - test/crosswake/release_candidate/evidence_gate_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_active_guidance.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_active_guidance.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_maintenance_review.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_maintenance_review.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_queue_inventory.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/collect_queue.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/maintenance-review.json
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/queue-inventory.json
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/phase-acceptance.json
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json
  - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 177: Code Review Report

**Reviewed:** 2026-10-12T16:59:55Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

Reviewed the six paths actually changed in the pinned source clone against `d0dbdf7`, plus the Phase177 evidence helpers and selected JSON evidence structures. The acceptance checker can accept stale PR check metadata and incomplete queue dispositions, so its green result does not reliably establish the recorded queue actions. The actual source diff contains `test/crosswake/release_candidate/companion_receipt_test.exs`; `test/mix/tasks/crosswake_release_candidate_test.exs` is unchanged and outside the reviewed source diff. No tests were run during this review.

## Narrative Findings (AI reviewer)

### CR-01: [BLOCKER] Final queue refresh ignores changed PR evidence

**File:** `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.mjs:89-91`

**Issue:** The refresh comparison only checks each object's `kind:number` key and `updatedAt`. GitHub check runs can change without changing the pull request's `updatedAt`; a PR can therefore move from a failing check to success, receive a new failing check, or change head/base/mergeability while the recorded queue object still passes the final refresh. The accepted inventory can then preserve a stale diagnosis or next action despite a changed live state.

**Fix:** Compare a normalized projection of each complete live object with the recorded object, including head OID, base ref, mergeability, check state, failed check names, and issue/PR relationships. Add an acceptance fixture that changes `checkState` or `failedChecks` while keeping the same key and `updatedAt`, and require it to fail.

### CR-02: [BLOCKER] Acceptance skips the required queue disposition schema

**File:** `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.mjs:88`

**Issue:** The phase acceptance check requires only nonempty `category` and `nextAction` strings. It does not call `validateQueueInventory` from `check_queue_inventory.mjs`, so an object with an arbitrary category or without `rationale`, `accountableRole`, `trigger`, `evidenceRef`, or the explicit `releaseProposal` flag can still satisfy acceptance. Those fields are required to give each open issue/PR a bounded owner, disposition reason, reopening condition, evidence reference, and release-authority boundary.

**Fix:** Run the strict inventory validator as part of acceptance and fail when it returns any errors. Keep the live queue comparison as a separate check so both schema completeness and current-state agreement are required.

### WR-01: [WARNING] Source binding digest and per-row dispositions are not verified

**File:** `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.mjs:48-50`

**Issue:** Acceptance checks that `bindingDigest` is merely nonempty and verifies row IDs/counts, but never recomputes the digest or checks each row's status against `semantic.rows[].sourceOwned`. Changing a row status while leaving the old digest intact still passes these binding checks. This permits a malformed source-binding artifact to be reported as qualified.

**Fix:** Recompute the SHA-256 over the binding payload with `bindingDigest` removed and compare it to the stored value. Also require each bound row status to be `source-retained-privately` for source-owned rows and `preserved-out-of-source-scope` otherwise.

---

_Reviewed: 2026-10-12T16:59:55Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
