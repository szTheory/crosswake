---
phase: "60"
plan: "01"
title: "Chimeway Registry Schemas, Migrations, And Proof Scaffold"
subsystem: example-host
status: complete
completed: "2026-06-02"
duration: "~18 minutes"
tasks_completed: 2
tasks_total: 2
files_created: 5
files_modified: 1
requirements-completed: [TOKN-03]
tags: [chimeway, ecto, migration, audit, metadata-sanitizer, proof]
key-decisions:
  - "Use separate partial unique indexes for subject_session and subject_installation scopes rather than a nullable composite index (D-12)"
  - "Keep MetadataSanitizer as a standalone module that drops both atom and string-keyed forbidden metadata without calling String.to_atom/1"
  - "TokenBindingEvent actor_kind locked to [:backend, :provider, :maintenance]; proof_class locked to [:hermetic, :advisory, :not_applicable]"
dependency-graph:
  requires: []
  provides:
    - chimeway_token_bindings table with partial unique indexes
    - chimeway_token_binding_events append-only audit table
    - CrosswakeExample.Chimeway.MetadataSanitizer
    - CrosswakeExample.Chimeway.TokenBinding
    - CrosswakeExample.Chimeway.TokenBindingEvent
    - test/crosswake/proof/phase60_chimeway_registry_test.exs proof scaffold
  affects:
    - examples/phoenix_host Ecto migration stack
    - Phase 60 Plan 02 (Registry lifecycle API will consume these schemas)
tech-stack:
  added: []
  patterns:
    - Ecto.Enum for closed Chimeway vocabularies backed by string columns
    - Partial unique indexes with WHERE clause for active token identity and authority scopes
    - Append-only audit rows with no cascade-delete path
    - Metadata sanitizer module with explicit atom + string forbidden-key lists
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex
    - examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex
    - examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex
    - examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs
    - examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs
  modified:
    - test/crosswake/proof/phase60_chimeway_registry_test.exs
---

# Phase 60 Plan 01: Chimeway Registry Schemas, Migrations, And Proof Scaffold Summary

## One-Liner

Backend-owned Chimeway token binding projection and append-only audit schema with named partial unique indexes for active fingerprint/session/installation scopes, plus a merge-blocking proof scaffold that boots the example-host repo and validates schema safety fences under SQLite.

## What Was Built

### Task 60-01-01 — MetadataSanitizer, TokenBinding schema, binding migration, and initial proof scaffold

**`CrosswakeExample.Chimeway.MetadataSanitizer`** (`examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex`):
- `forbidden_keys/0` returns the full atom list of disallowed keys
- `sanitize/1` drops both atom-keyed and string-keyed forbidden metadata without calling `String.to_atom/1`
- Forbidden keys cover: `:token`, `:raw_token`, `:device_token`, `:registration_token`, `:apns_token`, `:fcm_token`, `:provider_payload`, `:raw_payload`, `:notification_title`, `:notification_body`, `:route_params`, `:provider_response_body`, `:email`, `:ip`, `:user_agent`, `:device_id`

**`CrosswakeExample.Chimeway.TokenBinding`** (`examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex`):
- `schema "chimeway_token_bindings"` with 28 fields
- `Ecto.Enum` for: `subject_scope`, `provider`, `platform`, `environment`, `app_identity_posture`, `notification_status`, `state`, `reason`
- Scope consistency validation: `:subject_session` requires `session_ref` and validates `session_version >= 0`; `:subject_installation` does not require `session_ref`
- Named `unique_constraint/3` calls matching the migration index names exactly
- `sanitize_metadata/1` private function calls `MetadataSanitizer.sanitize/1` on changeset changes

**Binding migration** (`examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs`):
- No raw token columns (`token`, `raw_token`, `device_token`, `apns_token`, `fcm_token`)
- Partial unique index: `:chimeway_token_bindings_active_token_identity_index` (D-10)
- Partial unique index: `:chimeway_token_bindings_active_subject_session_scope_index` (D-11)
- Partial unique index: `:chimeway_token_bindings_active_subject_installation_scope_index` (D-12)
- Lookup indexes on `subject_ref/org_ref`, `session_ref`, `installation_ref`, `token_fingerprint`, `state/last_seen_at`

**Proof scaffold** (`test/crosswake/proof/phase60_chimeway_registry_test.exs`):
- Source-level assertions for migration column exclusions and index name presence
- Script-based changeset test via `System.cmd` in `examples/phoenix_host`
- MetadataSanitizer atom-key and string-key redaction tests
- No-worker-dependency assertions

### Task 60-01-02 — TokenBindingEvent append-only audit schema and migration

**`CrosswakeExample.Chimeway.TokenBindingEvent`** (`examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex`):
- `schema "chimeway_token_binding_events"` with 22 fields
- `Ecto.Enum` for: `event_type`, `provider`, `platform`, `environment`, `subject_scope`, `state_before`, `state_after`, `reason`, `feedback_event`, `notification_status`, `app_identity_posture`, `actor_kind`, `proof_class`
- `actor_kind` locked to `[:backend, :provider, :maintenance]`
- `proof_class` locked to `[:hermetic, :advisory, :not_applicable]`
- Metadata sanitization via `MetadataSanitizer.sanitize/1`

**Audit migration** (`examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs`):
- Unique `:chimeway_token_binding_events_event_ref_index`
- Lookup indexes on `binding_ref`, `event_type`, `occurred_at`, `correlation_id`, `request_ref`
- No `references/2` or `on_delete: :delete_all` — no cascade-delete escape hatch

**Proof extensions**:
- SQLite boot harness confirms both tables exist after migration run
- Both partial unique index sets are confirmed by name
- No extra `chimeway_*` tables beyond the two required
- TokenBindingEvent changeset and metadata sanitization tested via script

## Verification

```
mix test test/crosswake/proof/phase60_chimeway_registry_test.exs
10 tests, 0 failures
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All fields are wired; no placeholder data or stub behaviour.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: information_disclosure | `token_binding.ex`, `metadata_sanitizer.ex` | Mitigated: `token_ref`/`token_fingerprint` only; sanitizer drops all raw-token aliases in both atom and string form (T-60-01A) |
| threat_flag: spoofing | `token_binding.ex` scope validation | Mitigated: `subject_scope` enum and scope-consistency validator ensures backend-owned identity (T-60-01B) |
| threat_flag: tampering | binding migration partial unique indexes | Mitigated: three named partial unique indexes prevent silent multi-authority active rows (T-60-01C) |
| threat_flag: repudiation | `token_binding_event.ex`, audit migration | Mitigated: append-only schema with no cascade-delete path (T-60-01D) |

## Self-Check: PASSED

All files confirmed present and all commits verified in git log:
- `examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex` — FOUND
- `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex` — FOUND
- `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex` — FOUND
- `examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs` — FOUND
- `examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs` — FOUND
- `test/crosswake/proof/phase60_chimeway_registry_test.exs` — FOUND
- commit `4d96a69` (task 60-01-01) — FOUND
- commit `80197e9` (task 60-01-02) — FOUND
