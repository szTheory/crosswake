# Phase 60 Pattern Map: Example Host Registry And Phoenix Wiring

## Purpose

Phase 60 should give Phoenix hosts a copyable, host-owned Chimeway token binding registry. The implementation belongs in `examples/phoenix_host`, maps Phase 59 Chimeway contracts into Ecto persistence, and preserves Crosswake's core boundary: notification token evidence is provider/runtime evidence only, never auth, session, route, delivery, or notification-open authority.

## New Files To Plan

### `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex`

- Role: mutable backend-owned projection of current and historical notification token binding lifecycle state.
- Closest analog: `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` for `Ecto.Enum` schema style; `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex` for host-owned lifecycle record shape.
- Concrete pattern to preserve: use explicit required and optional field lists, `Ecto.Enum` for closed Chimeway vocabularies, named unique constraints, support-safe metadata sanitation before persistence, and no raw token fields in the schema or changeset.

### `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex`

- Role: append-only support-safe lifecycle audit event table for observed, bound, rotated, revoked, stale, invalidated, and provider feedback evidence.
- Closest analog: `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex`; older handoff audit files remain useful for support-safe audit field posture.
- Concrete pattern to preserve: audit rows are durable evidence written by registry transactions, have a unique event ref, carry only allowlisted lifecycle fields, and keep raw token material, provider payloads, notification content, route params, PII, raw session/subject/device identifiers, and provider response bodies out of metadata.

### `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`

- Role: synchronous Phoenix-owned lifecycle API for binding, refreshing, rotating, revoking, invalidating, and pruning token bindings.
- Closest analog: `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`.
- Concrete pattern to preserve: use named `Ecto.Multi` operations, guarded `update_all` for lifecycle transitions, `Ecto.Multi.run` checks where row counts matter, audit inserts inside the same transaction, sanitized return shapes, and telemetry emission only after `Repo.transaction/1` returns `{:ok, changes}`.

### `examples/phoenix_host/priv/repo/migrations/<timestamp>_create_chimeway_token_bindings.exs`

- Role: creates the host-owned mutable binding projection table.
- Closest analog: `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs`, with index lessons from `20260602060000_create_sigra_handoff_tickets.exs`.
- Concrete pattern to preserve: store enum fields as string columns, add unique `binding_ref`, add lookup indexes for subject/org, session, installation, token fingerprint, and state/last_seen_at, and add partial unique indexes for active token identity and active authority scopes.

### `examples/phoenix_host/priv/repo/migrations/<timestamp>_create_chimeway_token_binding_events.exs`

- Role: creates the append-only lifecycle audit table.
- Closest analog: `examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs`.
- Concrete pattern to preserve: string-backed enum columns, unique `event_ref` or `event_id`, audit lookup indexes on binding ref, event type, occurred_at, and request/correlation ref, and no foreign-key-driven cascade behavior that could erase audit truth.

### `test/crosswake/proof/phase60_chimeway_registry_test.exs`

- Role: merge-blocking proof that the example host registry preserves TOKN-03 lifecycle behavior and safety boundaries.
- Closest analog: `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` for temporary example-host Repo/migration setup and `test/crosswake/proof/phase59_chimeway_contract_test.exs` for Chimeway contract/redaction/telemetry assertions.
- Concrete pattern to preserve: run example-host migrations against a temporary SQLite database, exercise the real registry APIs, assert lifecycle state transitions and audit rows, and prove raw token input is absent from persisted rows, audit rows, changeset-visible output, telemetry metadata, and inspected sanitized result maps.

### Optional Non-Compiled Worker Guidance

- Role: narrow docs or recipe showing how a Phoenix host could call the same registry functions from a worker or scheduler.
- Closest analog: none in compiled code; keep this as documentation only.
- Concrete pattern to preserve: no Oban, Quantum, Broadway, GenServer scheduler, or Chimeway worker dependency in `crosswake` or `examples/phoenix_host`; any Oban example must be host-owned and call `Registry.apply_provider_feedback/2` or `Registry.prune_stale/1` rather than duplicating lifecycle writes.

## Existing Files To Read Before Editing

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-CONTEXT.md`
- `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-RESEARCH.md`
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-CONTEXT.md`
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-PATTERNS.md`
- `lib/crosswake/companions/chimeway/contracts.ex`
- `lib/crosswake/companions/chimeway/redaction.ex`
- `lib/crosswake/companions/chimeway/telemetry.ex`
- `lib/crosswake/bridge/commands/notification_token.ex`
- `lib/crosswake/bridge/commands/permissions_status.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex`
- `examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs`
- `examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs`
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs`
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`
- `test/crosswake/proof/phase59_chimeway_contract_test.exs`

## Data Flow: Token Evidence To Telemetry

1. Token evidence enters from bounded bridge/provider input and is normalized through `Crosswake.Companions.Chimeway.Redaction`.
2. Redaction converts raw APNs/FCM token material into support-safe `token_ref` and `token_fingerprint`; raw token aliases must not cross into registry attrs.
3. Authenticated Phoenix backend context supplies `subject_scope`, `subject_ref`, `org_ref`, `session_ref`, `session_version`, actor/request/correlation data, and any authority scope. Token possession does not choose these fields.
4. `Registry.bind_or_rotate/2` validates backend context separately from token evidence and builds binding attrs with provider, platform, environment, installation, app identity posture, notification status, token ref, token fingerprint, lifecycle state, reason, timestamps, and sanitized metadata.
5. `Ecto.Multi` performs the lifecycle transaction:
   - same-token refresh updates `last_seen_at`, notification status, posture, and metadata only;
   - initial bind inserts one active binding;
   - rotation supersedes displaced active bindings in the same authority scope and inserts the new active binding;
   - revocation, provider invalidation, and staleness pruning update active rows with explicit terminal state/reason timestamps.
6. The same `Ecto.Multi` appends one or more `TokenBindingEvent` audit rows describing the binding lifecycle change with support-safe state_before/state_after, reason, event type, feedback event, proof class, and request/correlation refs.
7. `Repo.transaction/1` returns a sanitized result shape such as `{:ok, %{binding: binding, audit_event: event, result: binding_result}}` or `{:ok, %{bindings: bindings, audit_events: events, result: binding_result}}`.
8. Only after a successful commit should the caller emit Chimeway telemetry through `Crosswake.Companions.Chimeway.Telemetry.execute/3`.
9. Failed transactions return normalized errors without success telemetry and without exposing changeset params that may have included unsafe raw input.

## Implementation Notes For The Planner

- Use `Ecto.Enum` in new schemas for provider, platform, environment, app identity posture, notification status, subject scope, binding state, binding reason, event type, provider feedback event, proof class, and any outcome-style field; migrations should use string columns.
- Keep the registry hybrid: one mutable `chimeway_token_bindings` projection plus append-only `chimeway_token_binding_events`; do not plan full event sourcing or a single-row-only upsert table.
- Add unique indexes for `binding_ref` and audit `event_ref` or `event_id`.
- Add lookup indexes for `subject_ref, org_ref`, `session_ref`, `installation_ref`, `token_fingerprint`, `state, last_seen_at`, audit `binding_ref`, audit `event_type`, audit `occurred_at`, and audit request/correlation ref.
- Add a partial unique active token identity index on `token_fingerprint`, `provider`, `platform`, `environment`, and `app_identity_posture` where `state = 'active'`.
- Add a partial unique active subject-session authority index on `subject_ref`, `org_ref`, `session_ref`, `installation_ref`, `provider`, `platform`, `environment`, and `app_identity_posture` where `state = 'active' AND subject_scope = 'subject_session'`.
- If subject-installation binding is included, add a separate partial unique index for `subject_scope = 'subject_installation'` that excludes nullable `session_ref`; do not use one giant nullable composite index.
- Use `Ecto.Multi` as the lifecycle primitive for `bind_or_rotate/2`, `revoke_for_logout/2`, `revoke_for_session_revocation/2`, `revoke_for_permission_loss/2`, `apply_provider_feedback/2`, and `prune_stale/1`.
- Use append-only audit rows as product surface, not optional diagnostics; do not delete invalid, stale, superseded, or revoked lifecycle evidence.
- Emit telemetry after commit only. Never emit success telemetry inside the transaction and never emit success telemetry for rolled-back flows.
- Never store raw APNs/FCM token material in binding rows, audit rows, metadata, telemetry, support output, fixtures, or changeset-visible error paths. Production delivery secrets, if needed, belong in a separate encrypted provider-bound store keyed by `token_ref`.
- Keep provider feedback normalized to Chimeway reasons such as `:provider_unregistered`, `:provider_invalid_token`, `:environment_mismatch`, and `:app_identity_mismatch`; do not leak provider-native enum names into public lifecycle state.
- Keep optional workers out of compiled code. Phase 60 should ship synchronous registry functions only; worker guidance can show host-owned calls into those functions without adding dependencies.
- Preserve Phase 61 and Phase 62 boundaries: do not implement notification-open resolution, RouteGate activation source handling, delivery adapters, provider credentials, support-matrix expansion beyond narrow anchors, or broad doctor/operator surfaces in this phase.

## PATTERN MAPPING COMPLETE
