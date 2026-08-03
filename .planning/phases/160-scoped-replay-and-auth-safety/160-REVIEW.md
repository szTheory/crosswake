---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-03T01:06:16Z
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
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-03T01:06:16Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

The browser worker’s new exact-scope activation and complete-acknowledgement checks are fail-closed, but the Phoenix replay endpoints do not establish backend authority from the request. They are publicly reachable JSON endpoints and use a generated fixture identity instead. This defeats the phase’s session/replay reauthorization boundary. The host test run also emits a compilation warning from a reviewed module, which risks the configured warnings-as-errors CI gate on a clean dependency compile.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Replay endpoint authorizes an unauthenticated fixture instead of the requesting account

**File:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex:89`
**Issue:** `default_resolution(:session, _conn)` ignores the connection and constructs a permissive configured fixture session. `default_resolution(:route, _conn)` and `domain_allows?/4` likewise default to a fixed route and `:allow`. Both `/study/sync` and `/learnloop/sync` use only the `:api` pipeline, which merely accepts JSON ([router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:119)). Therefore any unauthenticated caller can POST the fixture scope and create/replay review events; logout, account switching, revocation, and per-account scope authority are never checked server-side. This is an authorization bypass and directly violates the required backend-authoritative replay fence.

**Fix:** Put the sync endpoints behind a host authentication/session plug and resolve the current server-owned session, route policy, feature state, and domain authorization from `conn`. Fail closed when that authority is absent. The fixture resolver must be test-only, injected explicitly by tests, or the demo endpoint must be compiled out of production.

```elixir
defp default_resolution(:session, conn) do
  case CrosswakeExample.Auth.current_replay_session(conn) do
    {:ok, %{scope_ref: _scope_ref, auth_context: %AuthContext{}} = session} -> {:ok, session}
    _ -> {:error, :authority_unavailable}
  end
end
```

Add request-level tests proving anonymous, logged-out, switched-account, and revoked-session requests are rejected before persistence.

## Warnings

### WR-01: Conditional test hook attribute produces a compiler warning in the host build

**File:** `lib/crosswake/proof_lane/evidence.ex:29`
**Issue:** `@after_digest_barrier` is declared unconditionally but is referenced only inside `if Mix.env() == :test`. Compiling the Crosswake dependency through `examples/phoenix_host` emits `module attribute @after_digest_barrier was set but never used`. A clean `mix compile --warnings-as-errors` can turn this into a failing required CI build.

**Fix:** Declare the attribute only in the test branch, alongside the test-only helper.

```elixir
if Mix.env() == :test do
  @after_digest_barrier {__MODULE__, :after_digest_barrier}
  defp run_after_digest_barrier, do: # existing test implementation
else
  defp run_after_digest_barrier, do: :ok
end
```

### WR-02: Online submit starts an unobserved replay promise

**File:** `examples/phoenix_host/priv/static/offline_study.js:635`
**Issue:** `handleReview/1` calls the async `flushOutbox()` without awaiting it or attaching a rejection handler. If the immediate replay fails after the local write (for example, IndexedDB read/delete failure), the promise rejects as an unhandled browser rejection. Unlike the reconnect path at lines 480–482, it neither converts the failure into the visible paused state nor protects the console/error channel. This makes a recoverable replay failure look like a broken client and conflicts with the explicit blocked-state contract.

**Fix:** Route this call through the existing guarded worker entry point, or attach the same lease-aware catch used by `replayOnOnline/0`.

```js
if (navigator.onLine) {
  replayOnOnline();
}
```

---

_Reviewed: 2026-08-03T01:06:16Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
