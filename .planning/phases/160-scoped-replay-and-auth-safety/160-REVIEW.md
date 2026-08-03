---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-03T02:44:48Z
depth: standard
files_reviewed: 37
files_reviewed_list:
  - examples/phoenix_host/config/test.exs
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex
  - examples/phoenix_host/lib/crosswake_example/e2e/replay_session_controller.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/replay_auth.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs
  - examples/phoenix_host/priv/repo/migrations/20260802170000_restore_review_event_idempotency_guard.exs
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
  - examples/phoenix_host/test/crosswake_example/local_first/replay_auth_test.exs
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
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/offline/journal_test.exs
  - test/crosswake/offline/replay_test.exs
  - test/crosswake/offline/runtime_test.exs
  - test/crosswake/offline/safe_observation_test.exs
  - test/crosswake/offline/telemetry_test.exs
  - test/crosswake/operator_inspection/json_formatter_test.exs
  - test/crosswake/proof/phase160_scoped_replay_privacy_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/telemetry_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-03T02:44:48Z
**Depth:** standard
**Files Reviewed:** 37
**Status:** issues_found

## Summary

Reviewed the scoped replay authorization, persistence, browser outbox, safe-observation, proof, and test surfaces. Backend replay admission fails closed and the persistence constraints preserve scope ownership. One browser lifecycle race leaves the study UI unable to submit after a fence occurs during an in-flight local save.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Fencing during IndexedDB save permanently locks review controls

**File:** `examples/phoenix_host/priv/static/offline_study.js:585`

**Issue:** `handleReview` sets `reviewSubmissionOwned` and disables the rating buttons at lines 572–573. If `fenceScope()` runs while `queueMutation()` is pending, the lease check at line 585 returns early. That bypasses both resets at lines 591–592 and the `catch` reset at lines 599–600. After a fresh host activation, all later rating clicks return at line 567, leaving the user unable to queue any more work without reloading the page. The existing switch/fence replay tests cover outbox flushing but not this local-submission race.

**Fix:** Release the submission ownership and re-enable controls in a `finally` block, while retaining the lease check to prevent stale visual/state effects. For example:

```javascript
try {
  const lease = requireActiveLease();
  await queueMutation(lease.scopeRef, mutation);
  if (!leaseIsCurrent(lease)) return;
  // advance card and update status only for the current lease
} catch (error) {
  // existing safe error status handling
} finally {
  reviewSubmissionOwned = false;
  setReviewControlsDisabled(false);
}
```

Add a browser test that delays `queueMutation`, fences the scope, activates a new scope, then verifies a rating can be queued.

---

_Reviewed: 2026-08-03T02:44:48Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
