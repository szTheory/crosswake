---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-02T18:09:27Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/offline-sync-e2e-gate.yml
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
  - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
  - examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/offline/journal.ex
  - lib/crosswake/offline/replay.ex
  - lib/crosswake/offline/runtime.ex
  - lib/crosswake/offline/safe_observation.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/telemetry.ex
  - packages/crosswake_sigra/lib/crosswake/companions/sigra.ex
  - test/crosswake/offline/safe_observation_test.exs
  - test/crosswake/proof/phase160_scoped_replay_privacy_test.exs
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 160: Code Review Report

**Reviewed:** 2026-08-02T18:09:27Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The phase adds useful scope and lifecycle primitives, but the submitted default host path is not safe to ship. It bypasses Sigra's actual route/session evaluation, silently strands pre-upgrade offline work, weakens persisted idempotency for legacy rows, and permits unvalidated values to enter the purportedly closed telemetry projection.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Default replay admission invokes Sigra with nil authority inputs (BLOCKER)

**File:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex:116`
**Issue:** The no-callback production path calls `Crosswake.Companions.Sigra.evaluate_auth(nil, nil, [])`, not the resolved `route` and `session`. `Evaluator.evaluate_route_auth/3` explicitly allows a `nil` route, so this branch always produces an allow and never evaluates the replay route's predicates or the current session. A replay can therefore pass the Sigra layer even when the real route/session should be denied.
**Fix:** Pass a real Sigra `RouteEntry` and `AuthContext` derived from the resolved host route and current session, preferably through `Crosswake.Companions.Sigra.replay_decision(route, session, opts)`. Fail closed unless those values can be built and evaluated; add an integration test for a default-path Sigra denial.

### CR-02: SafeObservation can be forged and emits unvalidated sensitive values (BLOCKER)

**File:** `lib/crosswake/telemetry.ex:362`
**Issue:** `emit_safe_observation/1` accepts any `%SafeObservation{}` and immediately projects it. Elixir callers can construct that public struct directly, bypassing `SafeObservation.new/1` and its route/enum/measurement validation; for example, a sensitive scope or payload can be assigned to `route_id` and will be sent to telemetry and the default Logger. The same bypass exists in `SafeObservation.to_telemetry/1` and `Doctor.static_readiness/1`.
**Fix:** Re-validate struct contents at every public projection/egress boundary (for example, convert `Map.from_struct(observation)` through `SafeObservation.new/1` and return an error on failure), or expose an opaque validated value with projection functions that reject forged structs. Add tests that direct struct construction containing a canary is refused and never logged.

### CR-03: IndexedDB schema upgrade silently makes existing queued mutations unrecoverable (BLOCKER)

**File:** `examples/phoenix_host/priv/static/offline_study.js:122-133`
**Issue:** The v3 upgrade creates `scoped_mutations` but never reads, quarantines, migrates, or visibly reports records in the old `mutations` store. Every replay reader now accesses only `scoped_mutations` (line 213), so offline mutations queued by the prior shipped client are retained in IndexedDB but become permanently invisible and can never replay. This is silent loss of saved learner work during upgrade.
**Fix:** Add an explicit legacy-record migration/recovery state. Do not assign an old record to a scope automatically; retain it in a visible blocked/quarantine state and require fresh host authority to map it safely, or provide a deterministic user-safe recovery/removal flow. Cover an upgrade from DB version 1 containing a mutation.

### CR-04: Migration removes the only legacy idempotency protection without backfilling scope (BLOCKER)

**File:** `examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs:5-10`
**Issue:** Existing `review_events` rows receive `scope_ref = NULL`; the migration then drops the global unique index and creates a nullable `(scope_ref, client_mutation_id)` index. `Study.apply_one/3` only looks up the scoped pair, so a replay of a legacy mutation id under its actual scope cannot see its pre-migration row and can apply the domain effect a second time. NULL also means the database itself does not enforce the required scope invariant.
**Fix:** Perform a safe data migration before replacing the index: backfill each existing row from an authoritative scope mapping, make `scope_ref` `null: false`, then add the scoped unique index. If old rows cannot be mapped safely, preserve a global idempotency guard/quarantine them so they can never be replayed as new effects. Add migration fixtures proving an old id cannot create a second row.

## Warnings

### WR-01: Stale replay callbacks can still overwrite the new scope's status (WARNING)

**File:** `examples/phoenix_host/priv/static/offline_study.js:307-329`
**Issue:** The lease is checked once immediately after parsing a successful response, but several awaited operations and all non-OK handling happen afterward without another check. If `fenceScope()` and a new activation occur after line 309, the old flush can still update shared UI state at lines 319-329 (and the non-OK branch always does), falsely reporting old-scope sync/paused status in the new account.
**Fix:** Check `leaseIsCurrent(lease)` before every status/UI side effect after an await, including the non-OK response path; return without UI mutation when it is stale. Extend the in-flight test to fence after the success check/during deletion and to exercise a delayed forbidden response.

---

_Reviewed: 2026-08-02T18:09:27Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
