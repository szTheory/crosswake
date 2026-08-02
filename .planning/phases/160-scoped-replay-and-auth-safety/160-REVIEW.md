---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-02T23:30:00Z
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
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-02T23:30:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

The scoped replay flow has useful lifecycle fencing and server-side admission checks, but the submitted client and controller still accept untrusted state in ways that can change replay behavior or execute stored content. Focused core and host test suites passed; the host compile also reports an unused module attribute in the submitted evidence module.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Client controls the persisted replay outcome

**File:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex:54-59`, `examples/phoenix_host/lib/crosswake_example/local_first/study.ex:35-37`, `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex:18-21`

**Issue:** Admission validates only the required event keys, so an event with additional fields is allowed through. `Study.apply_one/3` forwards that original map to the changeset, which permits the client-supplied `status` field. A client can therefore persist an otherwise admitted event as `rejected`, causing the controller to halt replay and retain it forever on every idempotent retry. Replay outcome/status must be assigned by backend authority, not received from the browser.

**Fix:** Make `valid_event/1` require exactly the three wire keys, and construct the persistence attributes from an allowlist instead of passing the request map through:

```elixir
attrs = Map.take(event, ["client_mutation_id", "card_id", "rating"])
ReviewEvent.changeset(%ReviewEvent{}, Map.put(attrs, "scope_ref", scope_ref))
```

### WR-02: Flashcard fields are interpolated into `innerHTML`

**File:** `examples/phoenix_host/priv/static/offline_study.js:573-578`

**Issue:** Card fields are inserted into an HTML template without escaping. If cards later originate from host content, cache hydration, or any learner-controlled source, a stored markup value executes in the offline-island origin. That origin can call the globally exposed offline-study APIs and read its IndexedDB state, undermining the isolation assumptions around scoped replay.

**Fix:** Build the front/back elements with `document.createElement` and assign `textContent` (or escape every interpolated value before assigning `innerHTML`). Keep only constant markup in `innerHTML`.

### WR-03: Evidence module emits a compiler warning

**File:** `lib/crosswake/proof_lane/evidence.ex:29`

**Issue:** `@after_digest_barrier` is declared but never read. The focused host test command emits this warning while compiling Crosswake. The intended test barrier is instead accessed with a separately reconstructed tuple, so future renames can silently disconnect the declaration from its use.

**Fix:** Use `@after_digest_barrier` in `Process.get/1` or remove the unused attribute if no shared key is intended.

---

_Reviewed: 2026-08-02T23:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
