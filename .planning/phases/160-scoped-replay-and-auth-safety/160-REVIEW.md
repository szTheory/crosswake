---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-02T19:31:40Z
depth: standard
files_reviewed: 24
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
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-02T19:31:40Z
**Depth:** standard
**Files Reviewed:** 24
**Status:** issues_found

## Summary

The scoped browser outbox, Phoenix admission path, idempotency schema, SafeObservation projections, and proof/CI surfaces were reviewed. The phase has two defects that violate its privacy and durable replay guarantees. Focused safe-observation tests and Phoenix host local-first tests passed, but neither suite covers the rejected-idempotency state or the server/browser scope-validator mismatch.

## Critical Issues

### CR-01: Server accepts non-opaque scope references and persists them

**Classification:** BLOCKER

**File:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex:47`

**Issue:** `valid_scope/1` accepts any binary beginning with `v1.` whose remaining byte length is 8–120. Unlike the browser and library validators, it permits whitespace, delimiters, and account-like values. A host callback that supplies the same value then admits it and `Study.apply_one/3` persists it in `review_events.scope_ref`. This breaks the explicit opaque-scope/privacy boundary and gives the three layers incompatible admission rules.

**Fix:** Use the same anchored opaque-reference grammar as `Crosswake.Offline.Journal` and the browser (or expose one shared validator), and add rejection tests for spaces, punctuation, and identifier-shaped values.

```elixir
@scope_ref_pattern ~r/^v[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}$/

defp valid_scope(scope_ref) when is_binary(scope_ref) do
  if Regex.match?(@scope_ref_pattern, scope_ref), do: :ok, else: {:error, :invalid_envelope}
end
```

### CR-02: A rejected idempotency record is replayed as accepted

**Classification:** BLOCKER

**File:** `examples/phoenix_host/lib/crosswake_example/local_first/study.ex:18`

**Issue:** Any existing row for the same scope is classified as `:duplicate` regardless of `ReviewEvent.status`; both the transaction path (line 25) and recovery path (lines 69–70) report `outcome: :accepted`. Since the schema explicitly allows `status: "rejected"`, a retry of a rejected mutation is falsely acknowledged as accepted and the browser deletes its retained outbox item. That loses the only client-side signal requiring attention and violates truthful replay outcomes.

**Fix:** Branch on the persisted status and return a rejected outcome (or a closed halt that retains the record) for rejected rows; cover both the normal and race-recovery paths.

```elixir
%ReviewEvent{scope_ref: ^scope_ref, status: "accepted"} -> {:ok, :duplicate}
%ReviewEvent{scope_ref: ^scope_ref, status: "rejected"} -> {:ok, :rejected}
```

Then translate `:rejected` to `{:ok, %{client_mutation_id: id, outcome: :rejected}}` rather than the unconditional accepted result.

## Warnings

### WR-01: Network changes while inactive create an unhandled rejected promise

**Classification:** WARNING

**File:** `examples/phoenix_host/priv/static/offline_study.js:448`

**Issue:** The `online` listener passes `flushOutbox` directly (line 582). When no lease is active, `requireActiveLease()` at line 452 throws before `flushScopedOutbox`'s `try/finally` exists; event listeners do not await that rejected async promise. A normal reconnect after launch, logout, or a fence therefore produces an unhandled rejection instead of an inert no-op.

**Fix:** Treat inactive replay as an explicit no-op before creating the invocation, and catch unexpected listener failures.

```javascript
async function flushOutbox() {
  if (!isScopeRef(activeScopeRef) || activeEpoch < 1) return;
  // existing invocation setup
}

window.addEventListener('online', () => { void flushOutbox().catch(renderPausedStatus); });
```

---

_Reviewed: 2026-08-02T19:31:40Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
