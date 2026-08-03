---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-03T02:05:15Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - .github/workflows/offline-sync-e2e-gate.yml
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex
  - examples/phoenix_host/lib/crosswake_example/e2e/replay_session_controller.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs
  - examples/phoenix_host/priv/repo/migrations/20260802170000_restore_review_event_idempotency_guard.exs
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
  - examples/phoenix_host/test/crosswake_example/local_first/study_test.exs
  - examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/offline/journal.ex
  - lib/crosswake/offline/replay.ex
  - lib/crosswake/offline/runtime.ex
  - lib/crosswake/offline/safe_observation.ex
  - lib/crosswake/offline/telemetry.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/telemetry.ex
  - packages/crosswake_sigra/lib/crosswake/companions/sigra.ex
  - packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs
  - test/crosswake/offline/proof_lane_test.exs
  - test/crosswake/offline/safe_observation_test.exs
  - test/crosswake/proof/phase160_scoped_replay_privacy_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-03T02:05:15Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

The scoped replay and evidence paths were reviewed in full, including their Phoenix host integration and browser behavior. `MIX_ENV=test mix test test/crosswake_example/local_first --warnings-as-errors` passes, but it does not cover migration of an unowned legacy record across users. The legacy recovery API can assign unscoped work to whichever scope is currently active, defeating the account-switch boundary. The rating controls also permit concurrent submissions for the same visible card.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unscoped legacy mutations can be claimed and replayed by a different account

**Classification:** BLOCKER

**File:** `examples/phoenix_host/priv/static/offline_study.js:242`

**Issue:** `recoverLegacyMutations/1` promotes every quarantined legacy record to any currently active scope after checking only that the caller supplied that scope. A legacy record has no reliable account/scope binding, so a person who signs into a shared/reused device can replay another account's old offline mutation into their own account. The replay layer compounds this: existing unscoped server rows are treated as successful duplicates for every scope ([`study.ex:18`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/study.ex:18) and [`study.ex:78`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/study.ex:78)), causing the new scope to delete its local mutation even though no effect was committed for that scope. This violates the required fail-closed account-switch/logout behavior and can both cross account boundaries and lose the current account's review.

**Fix:** Do not auto-promote unscoped records based on the active lease. Keep them quarantined unless a host-owned recovery flow supplies a server-verifiable ownership binding for each record; otherwise expose a retained blocked/recovery-required state. Treat a persisted `scope_ref: nil` idempotency tombstone as `:scope_conflict` (or a closed migration-required rejection), never as `:duplicate`/accepted for a scoped replay. Add an E2E case that creates an unscoped record under one session, switches account, and proves it cannot enter the second scope or be acknowledged as accepted.

## Warnings

### WR-01: Rapid repeated rating clicks queue multiple reviews for one card

**Classification:** WARNING

**File:** `examples/phoenix_host/priv/static/offline_study.js:614`

**Issue:** `handleReview` awaits IndexedDB before advancing `currentCardIndex` or hiding/disabling the rating controls. Multiple click events can therefore run concurrently against the same `cards[currentCardIndex]`, each minting a different mutation ID. Both events can be persisted and the index can advance twice, producing duplicate/conflicting ratings for a single card. Idempotency does not prevent this because the IDs differ.

**Fix:** Serialize a card submission or synchronously disable both rating buttons before the first `await`, then re-enable only after a failed queue operation. Capture the card/index once and advance exactly once on successful persistence. Add a browser test that double-clicks a rating while IndexedDB is delayed and asserts one queued mutation and one card advance.

---

_Reviewed: 2026-08-03T02:05:15Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
