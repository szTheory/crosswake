---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-02T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - .github/workflows/offline-sync-e2e-gate.yml
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
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
  - test/crosswake/offline/safe_observation_test.exs
  - test/crosswake/proof/phase160_scoped_replay_privacy_test.exs
findings:
  critical: 2
  warning: 0
  info: 1
  total: 3
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

The host-side replay admission and persistence allowlist correctly reject added event fields before authority callbacks. However, the browser replay client still has two fail-open progress paths: it does not replay retained work after a successful online activation, and it accepts incomplete success envelopes. Both can leave authorized mutations stranded while presenting a non-error state.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Online activation leaves an existing scoped outbox inert

**Classification:** BLOCKER

**File:** `examples/phoenix_host/priv/static/offline_study.js:51-65`

**Issue:** `activateScope` records the lease and sets a ready status but never calls `flushOutbox`. Replay is only started by a later `online` event (line 601) or by creating another review (lines 631-633). Therefore an offline mutation that survives a relaunch, followed by host authorization while the browser is already online, remains in IndexedDB indefinitely unless the user toggles connectivity or creates a new mutation. The existing tests cover an online event after activation but not this normal relaunch/reauthorization ordering.

**Fix:** After `writeLifecycle` succeeds, capture/verify the just-created lease and start a guarded replay when `navigator.onLine` is true. Preserve the current lease checks so a fence or scope switch cannot produce side effects. Add an E2E regression that queues work, reloads while online, activates the scope, and asserts one sync request plus an empty scoped outbox.

### CR-02: A truncated success response is treated as a complete replay

**Classification:** BLOCKER

**File:** `examples/phoenix_host/priv/static/offline_study.js:94-118`

**Issue:** `classifyReplayResponse` validates only that each returned accepted record matches a prefix of the submitted records. With `halted: null`, it accepts an empty or truncated `accepted_records` array and returns `kind: 'complete'`. Lines 529-548 then leave the omitted records queued but clear the error styling and report `Synced 0 - queued N`; because no retry is scheduled, those mutations can remain stranded until another browser online event or new review occurs. A malformed 200 response must fail closed unless it accounts for the complete submitted batch.

**Fix:** Require a complete response to have `acceptedRecords.length === records.length`, no rejected records, and matching IDs in order. For a halted response, require an accepted prefix and validate the terminal rejected/halting shape against the remaining submitted record(s). Return `{ kind: 'blocked' }` for every other cardinality or outcome mismatch, and add a Playwright regression for a 200 response with an omitted accepted record and no `halted` value.

## Info

### IN-01: Compiler warning from unused evidence synchronization attribute

**Classification:** INFO

**File:** `lib/crosswake/proof_lane/evidence.ex:29`

**Issue:** `@after_digest_barrier` is assigned but never read. The reviewed Core and Phoenix test commands both emit this compiler warning, so it obscures new warnings in verification output.

**Fix:** Remove the attribute if the barrier is no longer needed, or consume it at the synchronization point it was intended to protect.

---

_Reviewed: 2026-08-02T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
