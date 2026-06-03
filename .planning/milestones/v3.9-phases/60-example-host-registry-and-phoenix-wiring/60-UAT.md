---
status: complete
phase: 60-example-host-registry-and-phoenix-wiring
source: [60-01-SUMMARY.md, 60-02-SUMMARY.md, 60-03-SUMMARY.md]
started: 2026-06-02T00:00:00Z
updated: 2026-06-02T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Boot the example-host repo from scratch. Both `chimeway_token_bindings` and `chimeway_token_binding_events` migrations run cleanly, all named partial unique indexes are created, and a basic registry bind/query returns live data without error.
result: pass

### 2. Token Binding & Rotation Lifecycle
expected: `Registry.bind_or_rotate/3` creates an active binding with an `:initial_bind` reason and a `:bound` audit row. A same-token call refreshes (preserves binding_ref/bound_at, writes `:observed`). A new token supersedes the old one (`:superseded`/`:token_rotated`) and writes both `:rotated` and `:bound` audit rows.
result: pass

### 3. Revocation Flows
expected: Logout, session-revocation (with session_version guard preserving newer bindings), and permission-loss each mark active bindings `:revoked` with the correct reason, write same-transaction audit rows, and audit rows survive the revocation. Repeat logout is idempotent (`{:error, :no_active_bindings}`).
result: pass

### 4. Provider Feedback Normalization
expected: `apply_provider_feedback/2` maps provider events to canonical reasons — `:token_unregistered` → revoked, `:environment_mismatch` → invalid — while non-invalidating events (`:delivery_accepted`, etc.) write audit-only `:feedback` rows and leave the binding `:active`. Provider-native enum names never appear in state/reason.
result: pass

### 5. Stale Pruning
expected: `prune_stale/1` marks eligible active rows `:stale` (reason `:staleness_pruned`) without deleting them; a repeat run with no eligible rows is an idempotent no-op returning empty lists.
result: pass

### 6. Raw Token Never Leaks
expected: MetadataSanitizer drops all raw-token aliases (apns_token, fcm_token, device_token, etc.) from persisted binding metadata, audit metadata, and all returned maps — in both atom- and string-keyed form. The raw-token sentinel is absent from all six production files at source level.
result: pass

### 7. Post-Commit Telemetry Rollback Safety
expected: Telemetry fires only after a successful `Repo.transaction` `{:ok, changes}` commit — never inside the transaction or on the error branch. A constraint-forced rollback leaves the telemetry process mailbox empty.
result: pass

### 8. README Optional Worker Guidance
expected: `examples/phoenix_host/README.md` has an "Optional Chimeway background jobs" section stating synchronous host-owned registry APIs only, naming both registry APIs with module-qualified paths, recommending Oban (primary) and Quantum/cron (secondary), with Broadway explicitly out of scope — and no overclaiming phrases about delivery/route authority.
result: pass

### 9. Merge-Blocking Proof Lane
expected: `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` passes the full merge-blocking proof lane (schema fences, lifecycle, telemetry, dependency denial, scheduler-loop prohibition, raw-token absence) with zero failures.
result: pass

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
