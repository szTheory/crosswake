---
phase: "60"
plan: "02"
title: "Chimeway Registry Lifecycle APIs, Audit Writes, And Telemetry"
subsystem: example-host
status: complete
completed: "2026-06-02"
duration: "~30 minutes"
tasks_completed: 2
tasks_total: 2
files_created: 1
files_modified: 1
requirements-completed: [TOKN-03]
tags: [chimeway, ecto, multi, lifecycle, audit, telemetry, provider-feedback, revocation]
key-decisions:
  - "Post-commit telemetry only: Telemetry.execute/3 fires only inside the {:ok, changes} branch of Repo.transaction/1 result pattern-match, never inside the transaction or in error branches (D-30)"
  - "Named Ecto.Multi steps for every lifecycle path: existing_same_token, displaced_bindings, supersede_displaced, binding, audit_events (D-15)"
  - "Session version guard in revoke_for_session_revocation/2: bindings with session_version > supplied version survive revocation (D-21)"
  - "Provider feedback normalizes to canonical Chimeway reasons in feedback_to_lifecycle/1 without leaking provider-native enum names into public state (D-23)"
  - "Non-invalidating feedback (delivery_accepted, delivery_failed, provider_throttled, etc.) writes audit-only :feedback rows without mutating binding state"
  - "Telemetry rollback safety proved by forcing constraint failure and asserting no success events reach the process mailbox"
dependency-graph:
  requires:
    - phase: "60-01"
      provides: "CrosswakeExample.Chimeway.TokenBinding and TokenBindingEvent schemas, MetadataSanitizer, migrations"
  provides:
    - CrosswakeExample.Chimeway.Registry with bind_or_rotate/3
    - CrosswakeExample.Chimeway.Registry with revoke_for_logout/2
    - CrosswakeExample.Chimeway.Registry with revoke_for_session_revocation/2
    - CrosswakeExample.Chimeway.Registry with revoke_for_permission_loss/2
    - CrosswakeExample.Chimeway.Registry with apply_provider_feedback/2
    - CrosswakeExample.Chimeway.Registry with prune_stale/1
    - All TOKN-03 lifecycle paths proved in phase60_chimeway_registry_test.exs
  affects:
    - Phase 61 (notification-open resolver will consume active bindings from this registry)
    - Phase 62 (doctor/support truth will reference registry API surface)
tech-stack:
  added: []
  patterns:
    - Named Ecto.Multi lifecycle transactions with :existing_same_token/:displaced_bindings/:supersede_displaced/:binding/:audit_events steps
    - Same-token refresh preserves binding_ref and bound_at, updating only last_seen_at and mutable posture fields
    - Rotation supersedes displaced rows in same transaction before inserting new active binding
    - Post-commit-only telemetry emission via Telemetry.execute/3 after Repo.transaction {:ok, changes}
    - Provider feedback normalization via feedback_to_lifecycle/1 mapping to canonical Chimeway reasons
    - Session-version-guarded revocation where version <= supplied version
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex
  modified:
    - test/crosswake/proof/phase60_chimeway_registry_test.exs
---

# Phase 60 Plan 02: Chimeway Registry Lifecycle APIs, Audit Writes, And Telemetry Summary

## One-Liner

Host-owned synchronous Chimeway registry with named Ecto.Multi lifecycle APIs for bind/refresh/rotate/revoke/invalidate/prune, append-only audit writes, canonical provider feedback normalization, and post-commit-only telemetry proved safe against transaction rollbacks.

## What Was Built

### Task 60-02-01 — Bind, refresh, and rotation flows with transactional audit evidence

**`CrosswakeExample.Chimeway.Registry`** (`examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`):
- `bind_or_rotate/3` accepts backend-owned context and `%TokenEvidence{}` or safe attrs
- Named Ecto.Multi steps: `:existing_same_token`, `:displaced_bindings`, `:supersede_displaced`, `:binding`, `:audit_events`
- Same-token refresh (D-17): updates `last_seen_at`, `notification_status`, `app_identity_posture`, `metadata` only; `binding_ref` and `bound_at` are preserved; writes `:observed` audit row
- Initial bind (D-18): inserts active binding with `state: :active, reason: :initial_bind`; writes `:bound` audit row
- Token rotation (D-19): supersedes displaced active rows with `state: :superseded, reason: :token_rotated, superseded_at: now` before inserting new active binding; writes `:rotated` audit rows for displaced bindings and `:bound` row for new binding
- All returned maps (`{:ok, %{binding: ..., audit_event: ..., result: ...}}`) expose only sanitized data from `MetadataSanitizer.sanitize/1`
- Raw token aliases (`apns_token`, `fcm_token`, etc.) drop from binding metadata, audit metadata, and returned maps

**Proof extensions** (`test/crosswake/proof/phase60_chimeway_registry_test.exs`):
- Initial bind: asserts state, reason, binding_ref, audit event type, result status
- Same-token refresh: asserts `binding_ref` unchanged, `bound_at` unchanged, `:observed` event type
- Token rotation: asserts new binding active, old binding `:superseded` with `:token_rotated` reason, ≥2 audit events including `:rotated` and `:bound` types, 2 total binding rows
- Raw token absence: asserts `raw_apns_token_should_not_leak_123` absent from metadata, inspect output, and returned maps

### Task 60-02-02 — Revoke, invalidate, prune, and post-commit telemetry flows

**Extended `CrosswakeExample.Chimeway.Registry`**:
- `revoke_for_logout/2` (D-20): guarded `update_all` targeting active session-scoped rows, `state: :revoked, reason: :logout_revoked`, same-transaction audit inserts; idempotent repeat returns `{:error, :no_active_bindings}`
- `revoke_for_session_revocation/2` (D-21): keyed by `session_ref`; `session_version` guard preserves bindings with `session_version > supplied_version`; `state: :revoked, reason: :session_revoked`
- `revoke_for_permission_loss/2` (D-22): `state: :revoked, reason: :permission_denied`, `notification_status: :denied`; same-transaction audit inserts
- `apply_provider_feedback/2` (D-23): accepts `%ProviderFeedback{}` or raw attrs via `Redaction.feedback_from_provider_attrs/1`; normalizes via `feedback_to_lifecycle/1`:
  - `:token_unregistered` → `{:revoked, :provider_unregistered}`
  - `:token_invalid` → `{:invalid, :provider_invalid_token}`
  - `:environment_mismatch` → `{:invalid, :environment_mismatch}`
  - `:app_identity_mismatch` → `{:invalid, :app_identity_mismatch}`
  - Non-invalidating events (`:delivery_accepted`, `:delivery_failed`, `:provider_throttled`, `:provider_unavailable`, `:credentials_invalid`) → audit-only `:feedback` row, binding state unchanged
- `prune_stale/1` (D-24): accepts `stale_before:` DateTime; marks active rows `state: :stale, reason: :staleness_pruned, stale_at: now` without deleting; idempotent noop when no eligible rows
- Post-commit telemetry (D-30/D-31/D-32): `Crosswake.Companions.Chimeway.Telemetry.execute/3` fires only inside `{:ok, changes}` match; never inside transaction, never in `{:error, ...}` branch

**Proof extensions**:
- Logout revocation: asserts all session bindings revoked, audit rows survive
- Session revocation with session_version guard: v1 bindings revoked, v2 bindings survive
- Permission loss: `state: :revoked, reason: :permission_denied, notification_status: :denied`
- Provider invalidation (token_unregistered): binding becomes `:revoked, :provider_unregistered`; provider-native enums absent from state/reason
- Non-invalidating feedback (delivery_accepted): binding remains `:active`
- Environment mismatch: binding becomes `:invalid, :environment_mismatch`
- Staleness pruning: rows marked `:stale` not deleted; idempotent repeat returns empty lists
- Forced rollback: telemetry process mailbox asserted empty after 100ms timeout following constraint-forced transaction rollback

## Verification

```
mix test test/crosswake/proof/phase60_chimeway_registry_test.exs
12 tests, 0 failures
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Elixir string interpolation escapes in proof script strings**
- **Found during:** Task 60-02-02 (first test run)
- **Issue:** Three `#{...}` expressions inside triple-quoted script strings were interpolated as Elixir compile-time expressions, causing compile errors: `token_fingerprint`, `b.binding_ref`, and `event_name`
- **Fix:** Escaped to `\#{...}` in the relevant script string positions
- **Files modified:** `test/crosswake/proof/phase60_chimeway_registry_test.exs`
- **Verification:** Compilation succeeds; test passes

**2. [Rule 1 - Bug] Fixed telemetry mailbox flush for rollback safety assertion**
- **Found during:** Task 60-02-02 (rollback safety test failed with spurious `:revoked` telemetry)
- **Issue:** The `receive` block for the rollback assertion was receiving `:revoked` telemetry from the `apply_provider_feedback` call earlier in the same test script; single pre-flush was insufficient
- **Fix:** Added thorough mailbox flush (50 receives + `timer.sleep(50)`) before the rollback test, and similar flush after the setup bind
- **Files modified:** `test/crosswake/proof/phase60_chimeway_registry_test.exs`
- **Verification:** Rollback safety assertion passes cleanly

## Known Stubs

None. All lifecycle APIs are fully wired; no placeholder behavior.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: spoofing | `registry.ex` context validation | Mitigated: `validate_context/1` enforces backend-owned `subject_ref` and `org_ref`; token evidence never supplies identity fields (T-60-02A) |
| threat_flag: tampering | `registry.ex` all lifecycle flows | Mitigated: named Ecto.Multi steps plus guarded `update_all` plus row-count checks plus same-transaction audit inserts (T-60-02B) |
| threat_flag: repudiation | `registry.ex` audit event creation | Mitigated: `TokenBindingEvent` rows inserted in same transaction as every lifecycle change; rows survive revocation and pruning (T-60-02C) |
| threat_flag: information_disclosure | `registry.ex` returned maps and telemetry | Mitigated: MetadataSanitizer drops raw token aliases from all persisted and returned data; Telemetry.execute uses sanitized metadata keys only (T-60-02D) |
| threat_flag: information_disclosure | `registry.ex` provider feedback mapping | Mitigated: `feedback_to_lifecycle/1` normalizes all provider-native events to canonical Chimeway reasons; provider-native enum names never appear in state or reason fields (T-60-02E) |

## Self-Check: PASSED

Files confirmed present:
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` — FOUND
- `test/crosswake/proof/phase60_chimeway_registry_test.exs` — FOUND (modified)
- `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-02-SUMMARY.md` — FOUND

Commits verified:
- `1904905` (task 60-02-01) — FOUND
- `4d7430f` (task 60-02-02) — FOUND
