# Phase 60 Research: Example Host Registry And Phoenix Wiring

**Question:** What do I need to know to PLAN this phase well?
**Phase:** 60 - Example Host Registry And Phoenix Wiring
**Requirement:** TOKN-03
**Status:** Research complete for planning

## Executive Summary

Phase 60 should implement a copyable Phoenix-owned Chimeway token registry in `examples/phoenix_host`, not Crosswake core. The key deliverable is a small Ecto persistence layer plus synchronous registry module that maps Phase 59 Chimeway contracts into durable backend lifecycle state.

The plan should be centered on:

- two host-owned tables: mutable `chimeway_token_bindings` and append-only `chimeway_token_binding_events`;
- Ecto schemas using `Ecto.Enum` backed by string columns;
- `Ecto.Multi` lifecycle flows for bind/refresh/rotate/revoke/invalidate/prune;
- audit rows written in the same transaction as binding changes;
- Chimeway telemetry emitted only after commit;
- no raw APNs/FCM token storage in these rows;
- no Oban, Quantum, Broadway, or scheduler dependency in compiled code.

The biggest planning risk is accidentally making token possession authoritative. Every registry function must take authenticated backend context separately from token evidence, and subject/session fields must come from backend context only.

## Canonical Inputs

Read and preserve these decisions while planning:

- `.planning/phases/60-example-host-registry-and-phoenix-wiring/60-CONTEXT.md`
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-CONTEXT.md`
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-PATTERNS.md`
- `lib/crosswake/companions/chimeway/contracts.ex`
- `lib/crosswake/companions/chimeway/redaction.ex`
- `lib/crosswake/companions/chimeway/telemetry.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex`
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs`
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs`
- `test/crosswake/proof/phase59_chimeway_contract_test.exs`

## Existing Patterns To Reuse

The closest example-host patterns are Sigra handoff, step-up, and auth-return:

- `Handoff.issue/1`, `Handoff.redeem/2`, and `Handoff.revoke/2` show named `Ecto.Multi` flows, guarded `update_all`, `Ecto.Multi.run` count checks, and audit inserts.
- `AuthReturnAttempt` and `AuthReturnAuditEvent` show the newer local schema style using `Ecto.Enum` with string migrations.
- Sigra audit modules write durable support-safe events and keep raw authority/credential material out of audit metadata.
- Root proof tests spawn a temporary SQLite DB, point `CrosswakeExample.Repo` at it, run all example-host migrations, then exercise the example-host modules. There is no separate `examples/phoenix_host/test` directory today.

For Phase 60, follow the auth-return schema style rather than older handoff string-only schemas, because Phase 60 context explicitly locks `Ecto.Enum`.

## Files To Plan

Primary files:

- `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex`
- `examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex`
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`
- `examples/phoenix_host/priv/repo/migrations/<timestamp>_create_chimeway_token_bindings.exs`
- `examples/phoenix_host/priv/repo/migrations/<timestamp>_create_chimeway_token_binding_events.exs`
- `test/crosswake/proof/phase60_chimeway_registry_test.exs`

Optional narrow docs/snippet file if the plan wants worker guidance in this phase:

- `examples/phoenix_host/priv/crosswake/chimeway_oban_recipe.md` or `guides/companions.md` narrow anchor

Do not plan compiled Oban worker modules. Do not add dependencies to root `mix.exs` or `examples/phoenix_host/mix.exs`.

## Schema Shape

### `TokenBinding`

Recommended table: `chimeway_token_bindings`.

Fields to plan:

- `binding_ref`, string, required, unique.
- `subject_scope`, enum, required. Use at least `:subject_session` and `:subject_installation`.
- `subject_ref`, `org_ref`, string, required for subject-scoped rows.
- `session_ref`, string, required for `:subject_session`.
- `session_version`, integer, optional but should be set when session context has it.
- `installation_ref`, string, required.
- `provider`, enum from `Contracts.providers/0`.
- `platform`, enum from `Contracts.platforms/0`.
- `environment`, enum from `Contracts.environments/0`.
- `app_identity_posture`, enum from `Contracts.app_identity_postures/0`, default `:unknown`.
- `app_identity_ref`, string, optional support-safe ref.
- `token_ref`, string, required support-safe token locator.
- `token_fingerprint`, string, required HMAC/digest ref.
- `notification_status`, enum from `Contracts.notification_statuses/0`.
- `state`, enum from `Contracts.binding_states/0`.
- `reason`, enum from `Contracts.binding_reasons/0`.
- `bound_at`, `last_seen_at`, required datetimes.
- `superseded_at`, `revoked_at`, `stale_at`, `invalidated_at`, optional datetimes.
- `audit_correlation_ref`, string, required support ref.
- `metadata`, map, default `%{}`.
- `timestamps(type: :utc_datetime)`.

Changeset requirements:

- Use `cast/3` with explicit required/optional lists.
- Use `validate_required/2`.
- Use `Ecto.Enum` fields rather than manual `validate_inclusion/3`.
- Add custom validation for scope/session consistency:
  - `:subject_session` requires `subject_ref`, `org_ref`, `session_ref`, and preferably `session_version`.
  - `:subject_installation` requires `subject_ref`, `org_ref`, and no required `session_ref`.
- Sanitize metadata before persistence.
- Reject metadata with raw token/provider/body/PII keys.
- Add named `unique_constraint/3` calls for `binding_ref`, active fingerprint identity, and active authority-scope indexes.

### `TokenBindingEvent`

Recommended table: `chimeway_token_binding_events`.

Fields to plan:

- `event_ref`, string, required, unique. Prefer `event_ref` to align Phase 59 contracts, or use `event_id` if preserving Sigra naming consistency.
- `event_type`, enum from `Contracts.binding_event_types/0`.
- `binding_ref`, `token_ref`, `token_fingerprint`, strings.
- `provider`, `platform`, `environment`, enums.
- `installation_ref`, string.
- `subject_scope`, enum.
- `state_before`, `state_after`, enums from binding states.
- `reason`, enum from binding reasons.
- `feedback_event`, enum from provider feedback events.
- `notification_status`, enum.
- `app_identity_posture`, enum.
- `occurred_at`, datetime, required.
- `correlation_id` or `request_ref`, string, required enough for idempotent proof.
- `actor_kind`, enum/string. Strong values: `:backend`, `:provider`, `:maintenance`.
- `proof_class`, enum. Strong values: `:hermetic`, `:advisory`, `:not_applicable`.
- `metadata`, map, default `%{}`.
- `timestamps(type: :utc_datetime)`.

Audit row posture:

- Append-only in normal API behavior.
- No raw token, provider payload body, notification title/body, route params, email, IP, user agent, raw subject/session/device ids in metadata.
- It is acceptable that `subject_ref`/`session_ref` live on binding rows for host-owned backend lookup, but do not put them in telemetry and do not overuse them in audit rows unless the context file explicitly allows the field. Phase 60 context allows audit `subject_scope`, not raw subject/session refs.

## Migration Details

Use string columns for all enum fields, matching the `AuthReturnAttempt` and `AuthReturnAuditEvent` migration style.

Indexes to plan:

- unique `binding_ref`;
- unique `event_ref` or `event_id`;
- lookup indexes on `subject_ref, org_ref`;
- lookup index on `session_ref`;
- lookup index on `installation_ref`;
- lookup index on `token_fingerprint`;
- lookup index on `state, last_seen_at`;
- audit lookup indexes on `binding_ref`, `event_type`, `occurred_at`, and `correlation_id` or `request_ref`.

Partial unique indexes:

- Active token fingerprint identity:
  - columns: `token_fingerprint`, `provider`, `platform`, `environment`, `app_identity_posture`;
  - where: `state = 'active'`.
- Active subject-session authority:
  - columns: `subject_ref`, `org_ref`, `session_ref`, `installation_ref`, `provider`, `platform`, `environment`, `app_identity_posture`;
  - where: `state = 'active' AND subject_scope = 'subject_session'`.
- Optional active subject-installation authority:
  - columns: `subject_ref`, `org_ref`, `installation_ref`, `provider`, `platform`, `environment`, `app_identity_posture`;
  - where: `state = 'active' AND subject_scope = 'subject_installation'`.

Do not combine session and installation scopes into one nullable composite unique index. SQLite and Postgres null uniqueness semantics will surprise adopters.

SQLite note: the example host uses `ecto_sqlite3`. Ecto migrations support `create(index(..., where: "..."))`; keep the `where` string simple and SQLite-compatible.

## Registry API Shape

Strong module name:

```elixir
CrosswakeExample.Chimeway.Registry
```

Recommended public functions:

```elixir
bind_or_rotate(context, token_evidence_or_attrs, opts \\ [])
revoke_for_logout(context, opts \\ [])
revoke_for_session_revocation(session_ref, opts \\ [])
revoke_for_permission_loss(context, opts \\ [])
apply_provider_feedback(provider_feedback_or_attrs, opts \\ [])
prune_stale(opts \\ [])
```

Context must be backend-owned. Recommended fields:

- `subject_ref`
- `org_ref`
- `session_ref`
- `session_version`
- `subject_scope`
- optional `actor_kind`
- optional `request_ref` or `correlation_id`

Token evidence must already be safe Chimeway evidence or attrs that become safe evidence through `Crosswake.Companions.Chimeway.Redaction`. Do not accept and persist raw token fields in `TokenBinding.changeset/2`.

Return shape should be sanitized and useful for telemetry:

```elixir
{:ok, %{binding: binding, audit_event: event, result: binding_result}}
{:ok, %{bindings: bindings, audit_events: events, result: binding_result}}
{:error, reason}
```

For failed transactions, return normalized errors without success telemetry. Do not leak changeset params that may include raw token input.

## Lifecycle Flow Details

### Initial Bind

Inputs:

- backend context with authenticated subject/session scope;
- `TokenEvidence` with provider/platform/environment/installation/token refs/fingerprint/status.

Flow:

1. Validate backend context separately from token evidence.
2. Build attrs with `state: :active`, `reason: :initial_bind`, `bound_at`, `last_seen_at`.
3. Insert `TokenBinding`.
4. Insert `TokenBindingEvent` with `event_type: :bound`, `state_after: :active`, `proof_class: :hermetic`.
5. Commit.
6. Emit `[:crosswake, :notification, :token, :bound]` using `Chimeway.Telemetry.execute/3`.

Planning note: this may share implementation with token rotation through `bind_or_rotate/3`.

### Same-Token Refresh

Definition: same active fingerprint already exists for the same authority scope.

Flow:

1. Find active binding by scope plus token fingerprint.
2. Update only `last_seen_at`, `notification_status`, `app_identity_posture`, `metadata`, `updated_at`.
3. Insert audit event with `event_type: :observed` or `:bound` depending on planner preference. `:observed` is clearer for unchanged binding.
4. Return `BindingResult` with status `:bound` or a local result marker. If using Phase 59 `BindingResult`, stay within `binding_result_statuses/0`; do not invent unsupported atoms unless Phase 59 is updated.
5. Emit `[:crosswake, :notification, :token, :observed]` or `:bound` after commit.

Footgun: do not overwrite `bound_at`, `binding_ref`, or lifecycle history on refresh.

### Token Rotation

Definition: new token fingerprint appears for the same authority scope.

Flow:

1. Query active bindings for same subject/session or subject/installation authority scope, excluding the incoming token fingerprint.
2. `Ecto.Multi.update_all(:supersede_displaced, query, set: [state: :superseded, reason: :token_rotated, superseded_at: now, updated_at: now])`.
3. Optionally run a fetch step before or after update to collect displaced binding refs for audit rows. Planner should prefer fetching displaced rows before update if it needs exact `state_before`.
4. Insert new active binding.
5. Insert audit events:
   - `:rotated` for each superseded row or one summary event if keeping proof narrow;
   - `:bound` for the new row.
6. Commit.
7. Emit `[:crosswake, :notification, :token, :rotated]` after commit, plus optional bound telemetry if low-cardinality.

Footgun: a pure upsert on active fingerprint or active scope will erase rotation history. The plan should explicitly avoid this.

### Logout Revocation

Definition: current authenticated session logs out.

Flow:

1. Query active rows matching backend context, usually `subject_ref`, `org_ref`, `session_ref`, `subject_scope: :subject_session`.
2. Guarded `update_all` to `state: :revoked`, `reason: :logout_revoked`, `revoked_at: now`.
3. Insert audit event(s) with `event_type: :revoked`.
4. Commit.
5. Emit `[:crosswake, :notification, :token, :revoked]` after commit.

Idempotency: a repeat logout should not create endless duplicate state changes. Either return zero changed rows with a safe idempotent result, or insert one audit event only when rows changed.

### Session Revocation

Definition: backend invalidates a session independent of a user logout path.

Flow:

1. Query active rows by `session_ref`, and by `session_version` when supplied.
2. Set `state: :revoked`, `reason: :session_revoked`, `revoked_at: now`.
3. Insert audit event(s).
4. Emit revocation telemetry after commit.

Planning edge: if `session_version` is supplied, do not revoke newer session versions accidentally.

### Permission Loss

Definition: native permission status becomes denied/restricted or host has equivalent proof.

Flow:

1. Validate backend context.
2. Query active rows matching subject/session or installation scope.
3. Set `state: :revoked`, `reason: :permission_denied`, `revoked_at: now`, `notification_status: :denied` or observed status.
4. Insert audit event(s).
5. Emit revocation telemetry after commit.

Future permission grant must re-bind from fresh token evidence. Do not reactivate revoked rows from permission loss.

### Provider Invalidation

Inputs: `ProviderFeedback` or attrs normalized through `Redaction.feedback_from_provider_attrs/1`.

Feedback mapping:

- `:token_unregistered` -> `state: :revoked`, `reason: :provider_unregistered`.
- `:token_invalid` -> `state: :invalid`, `reason: :provider_invalid_token`.
- `:environment_mismatch` -> `state: :invalid`, `reason: :environment_mismatch`.
- `:app_identity_mismatch` -> `state: :invalid`, `reason: :app_identity_mismatch`.
- `:credentials_invalid`, `:provider_throttled`, `:provider_unavailable`, `:delivery_accepted`, `:delivery_failed` should insert feedback audit evidence but should not automatically revoke unless the plan justifies a lifecycle reason from Phase 59 vocabulary.

Flow:

1. Normalize provider feedback.
2. Find active rows by `token_ref` or `token_fingerprint` plus provider/platform/environment/app posture when available.
3. Apply lifecycle update only for invalidating feedback.
4. Insert `event_type: :feedback` audit row, and `:invalidated` if lifecycle changed.
5. Commit.
6. Emit `[:crosswake, :notification, :provider, :feedback]` and, when lifecycle changed, `[:crosswake, :notification, :token, :invalidated]`.

Footgun: provider feedback is evidence, not delivery truth or route-open truth. `:delivery_accepted` does not mean delivered/opened.

### Stale Pruning

Definition: host marks active rows old enough to stop using as notification authority.

Flow:

1. Determine cutoff from opts, for example `stale_before: DateTime.add(now, -90, :day)`.
2. Query active rows with `last_seen_at < stale_before`.
3. Set `state: :stale`, `reason: :staleness_pruned`, `stale_at: now`.
4. Insert audit events.
5. Commit.
6. Emit `[:crosswake, :notification, :token, :stale]`.

Boundary: pruning marks state. It must not delete binding or audit rows.

## Idempotency Strategy

Plan an idempotency helper, but keep it support-safe.

Best input key:

- `request_ref` or `correlation_id` supplied by backend/host.

Fallback deterministic key:

- hash/fingerprint of safe values only: subject scope, support-safe subject/org/session refs if host-owned, installation ref, token fingerprint, provider/platform/environment/app posture, and a coarse observed-at bucket.

Do not include raw token material. Do not include provider payload body. Do not use notification title/body or route params.

The minimal Phase 60 implementation can rely on partial unique indexes plus transaction retries for the same-token case, but the plan should still specify request/correlation refs in audit rows so a future host can dedupe externally.

## Telemetry Posture

Use `Crosswake.Companions.Chimeway.Telemetry.execute/3`.

Allowed event names are already defined:

- `[:crosswake, :notification, :token, :observed]`
- `[:crosswake, :notification, :token, :bound]`
- `[:crosswake, :notification, :token, :rotated]`
- `[:crosswake, :notification, :token, :revoked]`
- `[:crosswake, :notification, :token, :stale]`
- `[:crosswake, :notification, :token, :invalidated]`
- `[:crosswake, :notification, :provider, :feedback]`

Emit success telemetry only after `Repo.transaction/1` returns `{:ok, changes}`. This is not cosmetic: emitting inside the transaction can report success for a rolled-back lifecycle write.

Telemetry metadata should come from committed rows/result structs, not raw input attrs. The sanitizer allows low-cardinality keys such as provider, platform, environment, state, reason, feedback event, notification status, app identity posture, subject scope, proof class, and correlation id. It drops raw token aliases, provider payload bodies, subject/session refs, IPs, user agents, emails, route params, and notification body/title.

## Raw Token And Metadata Redaction

Phase 60 should not store raw token material. Store only:

- `token_ref`
- `token_fingerprint`

If a production host needs APNs/FCM delivery, the raw deliverable token belongs in a separate encrypted/provider-bound secret store keyed by `token_ref`. That store is not Crosswake support output, audit output, telemetry, fixtures, or Phase 60 scope.

Plan a local metadata sanitizer for schemas/events. It should reject/drop at least:

- `:token`
- `:raw_token`
- `:device_token`
- `:registration_token`
- `:apns_token`
- `:fcm_token`
- `:provider_payload`
- `:raw_payload`
- `:notification_title`
- `:notification_body`
- `:route_params`
- `:provider_response_body`
- `:email`
- `:ip`
- `:user_agent`
- `:device_id`

Careful with string keys as well as atom keys. Do not call `String.to_atom/1`; use an allowlist or `String.to_existing_atom/1` only when safe.

## Optional Worker Guidance Boundary

Phase 60 should ship synchronous registry APIs only.

Allowed guidance:

- A non-compiled markdown recipe or code block showing an Oban worker calling `Registry.prune_stale/1` or `Registry.apply_provider_feedback/2`.
- Mention that durable providers can enqueue jobs in host-owned `Ecto.Multi` if the host already uses Oban.
- Mention cron/Quantum as host scheduling alternatives for pruning only.

Forbidden in compiled Phase 60 code:

- adding Oban dependency;
- adding Quantum dependency;
- adding Broadway dependency;
- adding a Chimeway worker behaviour;
- adding a GenServer scheduler that implies Crosswake owns provider feedback/delivery orchestration.

Broadway belongs only to future high-volume provider-feedback queue ingestion, not this copyable example-host registry.

## Cross-Phase Boundaries

Do not plan:

- notification-open resolver;
- RouteGate `activation_source: :notification`;
- Sigra step-up reuse for notification opens;
- notification denial codes;
- APNs/FCM delivery adapters;
- provider credentials;
- notification topics/subscriptions;
- tray/display/open proof;
- doctor/support/operator broad expansion.

Those belong to Phases 61-63 or future provider-delivery milestones.

Phase 60 may include narrow anchors required to explain that the example registry exists, but it must not claim delivery support or notification-open support.

## Edge Cases And Footguns

Plan tests or code guards for:

- same token observed twice for same scope should refresh, not rotate;
- same token observed for different subject/session should be rejected or supersede according to active fingerprint uniqueness, not silently bind to two active authorities;
- new token for same session should supersede old active row and insert new active row;
- logout revocation should be idempotent and should not delete rows;
- session revocation with `session_version` should not revoke newer session versions;
- permission loss should require fresh evidence to rebind later;
- provider feedback without token ref/fingerprint should return safe error or audit feedback only, not broad invalidate;
- non-invalidating provider feedback should not revoke;
- stale pruning should not mark already revoked/invalid/stale rows again;
- changeset errors should not echo raw token params;
- partial unique index names must match `unique_constraint/3`;
- telemetry must not fire on rolled-back insert/update;
- metadata sanitizers must handle atom and string keys;
- audit rows must be inserted in the same transaction as lifecycle changes.

## Validation Architecture

Phase 60 is the merge-blocking proof for TOKN-03. Plan a root proof test:

```elixir
test/crosswake/proof/phase60_chimeway_registry_test.exs
```

Use the existing Sigra proof pattern:

1. Build an Elixir script string inside the root ExUnit test.
2. Configure a unique temporary SQLite DB path.
3. `Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)`.
4. Start `CrosswakeExample.Repo`.
5. Run `Ecto.Migrator.run(CrosswakeExample.Repo, "priv/repo/migrations", :up, all: true)` from `examples/phoenix_host`.
6. Exercise `CrosswakeExample.Chimeway.Registry`.
7. Assert lifecycle rows, audit rows, telemetry messages, and raw-token absence.

Minimum TOKN-03 proof cases:

- initial bind inserts one active binding and one support-safe audit event;
- same-token refresh updates `last_seen_at` without changing `binding_ref` or `bound_at`;
- token rotation supersedes displaced active binding, inserts a new active binding, and writes rotated/bound audit evidence;
- logout revocation marks active subject-session rows `:revoked` with `:logout_revoked`;
- session revocation marks matching session rows `:revoked` with `:session_revoked` and respects `session_version`;
- permission loss marks rows `:revoked` with `:permission_denied`;
- provider invalidation maps APNs/FCM feedback to canonical Chimeway state/reason without provider-native enums in binding state;
- stale pruning marks old active rows `:stale` with `:staleness_pruned`;
- no lifecycle flow deletes binding rows or audit rows;
- no persisted binding/audit/metadata/telemetry contains a seeded raw token.

Telemetry proof:

- Attach test telemetry handlers for Chimeway event names.
- Force one transaction failure, for example duplicate `binding_ref` or invalid required attrs, and assert no success telemetry was received.
- Assert success telemetry metadata contains only allowed keys and omits raw token, provider payload, subject ref, session ref, IP, user agent, and notification body/title.

Source/proof assertions:

- Assert new example-host source files exist.
- Assert migrations include the expected table names and partial unique indexes.
- Assert `examples/phoenix_host/mix.exs` does not include Oban, Quantum, Broadway.
- Assert no compiled example-host Chimeway file defines `use Oban.Worker`, `Quantum`, or `Broadway`.
- Assert any worker guidance is markdown/non-compiled if included.

Recommended command for verification:

```bash
mix test test/crosswake/proof/phase60_chimeway_registry_test.exs
```

Full regression after implementation:

```bash
mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs test/crosswake/proof/phase60_chimeway_registry_test.exs
```

## Planning Slice Recommendation

Plan this phase in three small implementation slices:

1. Schema and migration slice:
   - add `TokenBinding`, `TokenBindingEvent`, migrations, constraints, metadata sanitizer, and simple changeset tests/proof assertions.
2. Registry lifecycle slice:
   - add `Registry` with `bind_or_rotate/3`, revocation, provider feedback, stale pruning, Ecto.Multi flows, audit inserts, and post-commit telemetry.
3. Proof and guidance slice:
   - add TOKN-03 root proof, raw-token/telemetry checks, no-worker-dependency assertions, and optional non-compiled Oban recipe.

This order keeps database constraints available before transaction logic and lets proof cover the real example-host path adopters will copy.

## Research Conclusion

To plan Phase 60 well, treat it as Phoenix host infrastructure, not Chimeway core. The core Chimeway contract already exists; the missing value is a durable, auditable, copyable Ecto registry that proves token lifecycle transitions are backend-owned and support-safe. The plan should be precise about transaction boundaries, partial indexes, same-token refresh versus rotation, post-commit telemetry, raw-token exclusion, and worker non-dependencies.

## RESEARCH COMPLETE
