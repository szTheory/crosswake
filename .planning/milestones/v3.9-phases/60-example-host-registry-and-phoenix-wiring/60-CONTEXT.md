# Phase 60: Example Host Registry And Phoenix Wiring - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide a copyable Phoenix-owned registry path for Chimeway token binding lifecycle management.

**Delivers:**
- Example-host Ecto schemas, migrations, changesets, and registry functions for binding, refreshing, rotating, revoking, invalidating, and pruning notification token bindings.
- Backend-owned lifecycle semantics for TOKN-03: token rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning.
- Support-safe audit rows and sanitized Chimeway telemetry that prove lifecycle transitions without raw token, provider payload, PII, delivery, route, or auth overclaims.
- Optional worker guidance that calls the same synchronous registry functions without adding Oban, Quantum, Broadway, or Chimeway worker dependencies.

**In scope:**
- `examples/phoenix_host` persistence and lifecycle APIs that map Phase 59 `TokenBinding`, `BindingEvent`, `ProviderFeedback`, and `BindingResult` contracts into host-owned Ecto rows.
- `Ecto.Multi` transaction flows for lifecycle transitions and audit writes.
- Contract/proof tests for TOKN-03 lifecycle behavior, idempotency, redaction, and post-commit telemetry posture.

**Out of scope:**
- Notification-open resolver, RouteGate `activation_source: :notification`, Sigra step-up reuse, and notification denial codes; those belong to Phase 61.
- Broad doctor/support/operator/docs expansion; those belong to Phase 62, except narrow Phase 60 anchors needed for copyable registry guidance.
- APNs/FCM delivery adapters, provider credentials, delivery acceptance as delivered/opened truth, notification-tray behavior, topic APIs, and bundled background workers.

</domain>

<decisions>
## Implementation Decisions

### 1. Registry Shape - LOCKED
- **D-01:** Use a hybrid host-owned registry: `chimeway_token_bindings` as the mutable backend-owned projection plus `chimeway_token_binding_events` (or `chimeway_token_audit_events`) as append-only support-safe lifecycle evidence.
- **D-02:** Reject a single current-row table as too thin for TOKN-03. It would hide rotation, revocation, provider invalidation, and staleness history.
- **D-03:** Reject a full event-sourced registry as too heavy for the example host. Keep append-only audit events, but do not require replay/projector semantics.
- **D-04:** Reject fully normalized installation/device/token/subject tables in Phase 60. They are a future production extension, not the copyable v3.9 example-host path.
- **D-05:** The binding row should include `binding_ref`, `subject_scope`, `subject_ref`, `org_ref`, `session_ref`, `session_version`, `installation_ref`, `provider`, `platform`, `environment`, `app_identity_posture`, optional `app_identity_ref`, `token_ref`, `token_fingerprint`, `notification_status`, `state`, `reason`, `bound_at`, `last_seen_at`, `superseded_at`, `revoked_at`, `stale_at`, `invalidated_at`, `audit_correlation_ref`, and sanitized `metadata`.
- **D-06:** Do not store raw APNs/FCM tokens in the example registry. The example stores only `token_ref` and `token_fingerprint`. If a production host needs delivery, raw token material belongs in a separate encrypted/provider-bound secret store keyed by `token_ref`, outside Crosswake support, telemetry, audit, fixtures, and operator output.
- **D-07:** Use `Ecto.Enum` in schemas for closed Chimeway vocabularies, backed by string columns in migrations. Apply this to provider, platform, environment, app identity posture, notification status, subject scope, state, reason, event type, and outcome-style fields.

### 2. Indexes, Constraints, And Idempotency - LOCKED
- **D-08:** Add unique indexes for `binding_ref` and audit `event_ref` or `event_id`.
- **D-09:** Add lookup indexes for `subject_ref/org_ref`, `session_ref`, `installation_ref`, `token_fingerprint`, and `state/last_seen_at`.
- **D-10:** Add a partial unique index for active token fingerprint identity: `token_fingerprint`, `provider`, `platform`, `environment`, and `app_identity_posture` where `state = 'active'`.
- **D-11:** Add a partial unique index for active subject-session delivery authority scope: `subject_ref`, `org_ref`, `session_ref`, `installation_ref`, `provider`, `platform`, `environment`, and `app_identity_posture` where `state = 'active' AND subject_scope = 'subject_session'`.
- **D-12:** If planners include lower-risk subject-installation bindings, use a separate partial unique index for `subject_scope = 'subject_installation'` that excludes nullable `session_ref`. Do not use one giant nullable composite index; null uniqueness semantics are surprising and poor DX.
- **D-13:** Add an idempotency key around token observations or requests, preferably `correlation_id` or `request_ref` when supplied. If no request ref exists, planner may use a deterministic support-safe key built from scope, token fingerprint, and an observed-at/request bucket.
- **D-14:** Changesets should use `validate_required/3`, `Ecto.Enum`, named `unique_constraint/3` calls for the partial/composite indexes, and metadata sanitization before persistence.

### 3. Lifecycle Transactions - LOCKED
- **D-15:** Use `Ecto.Multi` as the primary lifecycle primitive. This is the idiomatic Elixir/Ecto shape for named transactional writes and mirrors existing Sigra host examples.
- **D-16:** Use the hybrid transaction model: authoritative binding row plus append-only audit event plus narrow idempotent upsert/refresh behavior.
- **D-17:** Same-token refresh is the only upsert-like shortcut. If the same active fingerprint exists for the same scope, update `last_seen_at`, notification status, and app/permission posture; return an unchanged or refreshed binding result without overwriting lifecycle history.
- **D-18:** Initial bind requires authenticated backend context. The flow fingerprints/redacts token evidence, inserts an active binding with `state: :active, reason: :initial_bind`, inserts a `:bound` audit event, and emits sanitized telemetry only after commit.
- **D-19:** Token rotation supersedes displaced active rows for the same authority scope with `state: :superseded, reason: :token_rotated`, inserts the new active binding, and appends rotated/bound audit evidence in one transaction.
- **D-20:** Logout revocation updates matching active subject/session rows to `state: :revoked, reason: :logout_revoked` and appends revocation audit evidence. It never deletes rows.
- **D-21:** Session revocation is keyed by `session_ref` and `session_version` when available, uses `state: :revoked, reason: :session_revoked`, and appends revocation audit evidence.
- **D-22:** Permission loss revokes matching active bindings with `state: :revoked, reason: :permission_denied`. Future permission grant must re-bind from fresh token evidence.
- **D-23:** Provider invalidation normalizes APNs/FCM feedback into Chimeway reasons, then marks matching active bindings invalid or revoked as appropriate. Use `:provider_unregistered`, `:provider_invalid_token`, `:environment_mismatch`, and `:app_identity_mismatch` without leaking provider-native enums into public state.
- **D-24:** Staleness pruning marks old active rows `state: :stale, reason: :staleness_pruned`; it does not delete support-safe audit truth.
- **D-25:** Guarded `update_all` is acceptable for lifecycle transitions when followed by `Ecto.Multi.run` checks and explicit audit inserts. Use changeset inserts/updates for normal row creation and validation.

### 4. Audit And Telemetry - LOCKED
- **D-26:** Append-only audit rows are first-class in the example host. They are durable lifecycle/support evidence, not optional diagnostics.
- **D-27:** Audit event fields should be allowlisted: `event_id` or `event_ref`, `event_type`, `binding_ref`, `token_ref`, `token_fingerprint`, `provider`, `platform`, `environment`, `installation_ref`, `subject_scope`, `state_before`, `state_after`, `reason`, `feedback_event`, `notification_status`, `app_identity_posture`, `occurred_at`, `correlation_id` or `request_ref`, `actor_kind`, `proof_class`, and sanitized `metadata`.
- **D-28:** Audit metadata must not contain raw tokens, provider payload bodies, notification title/body, route params, email, IP, user agent, raw subject/session/device identifiers, provider response bodies, or raw provider credentials.
- **D-29:** Write audit rows inside the same `Ecto.Multi` transaction as the binding lifecycle change.
- **D-30:** Emit Chimeway telemetry only after `Repo.transaction/1` returns `{:ok, changes}`. Do not emit success telemetry from inside the transaction and do not emit success telemetry for rolled-back flows.
- **D-31:** Transaction return shapes should expose sanitized result data, for example `{:ok, %{binding: binding, audit_event: audit_event, result: binding_result}}`, so callers can emit telemetry without reopening raw inputs.
- **D-32:** On transaction failure, normalize the failure and return it without success telemetry. Planner may add explicit denied/failure telemetry only if it uses the Phase 59 sanitizer and safe low-cardinality metadata.

### 5. Optional Worker Boundary - LOCKED
- **D-33:** Phase 60 should implement synchronous, transaction-safe registry APIs, not bundled workers. Strong default API names: `bind_or_rotate/2`, `revoke_for_logout/2`, `revoke_for_session_revocation/2`, `revoke_for_permission_loss/2`, `apply_provider_feedback/2`, and `prune_stale/1`.
- **D-34:** Add no Oban, Quantum, Broadway, GenServer scheduler, or Chimeway worker dependency to `crosswake` or `examples/phoenix_host` in Phase 60.
- **D-35:** Provide optional worker guidance as docs or non-compiled snippets that call the same audited registry functions. Oban is the primary optional recipe because it is idiomatic for durable Phoenix background jobs and can insert jobs into `Ecto.Multi`, but it remains host-owned.
- **D-36:** Mention Quantum or cron-style scheduling only as secondary pruning alternatives. Mention supervised `GenServer` loops only as demo-grade or host-local scheduling, not durable provider-feedback handling.
- **D-37:** Do not recommend Broadway in Phase 60 unless a future host ingests provider feedback from high-volume queues such as Kafka/SQS/PubSub/RabbitMQ. That is beyond the copyable example-host registry.

### 6. Ecosystem Lessons And Footguns - LOCKED
- **D-38:** Firebase's token-management posture supports server-side token storage with timestamps, freshness updates, stale pruning, and invalid-token handling. Crosswake should encode that as backend lifecycle state, not as delivery truth.
- **D-39:** Apple's APNs guidance treats device tokens as mutable app/device/environment evidence and warns against cached token assumptions. Chimeway should treat repeated registration and token changes as normal lifecycle evidence.
- **D-40:** Expo/OneSignal-style registries show useful ergonomics around subscription/user mappings, but provider IDs must not replace Phoenix host identity or Crosswake route authority.
- **D-41:** Payment/auth/webhook ecosystems reinforce idempotency and durable audit around provider evidence. Copy the idempotency/audit discipline; do not copy provider evidence as authority.
- **D-42:** Footguns to avoid: pure upsert that overwrites lifecycle truth; deleting invalid/stale rows and losing audit history; emitting telemetry before commit; raw token leakage in changeset errors; provider-native enums in public states; token possession becoming identity; optional worker snippets that imply Crosswake ships delivery orchestration.

### the agent's Discretion
- Exact module names are planner discretion. Strong defaults: `CrosswakeExample.Chimeway.TokenBinding`, `CrosswakeExample.Chimeway.TokenBindingEvent`, and `CrosswakeExample.Chimeway.Registry`.
- Exact migration timestamp and file names are planner discretion.
- Exact event table name is planner discretion. Prefer `chimeway_token_binding_events` for contract alignment or `chimeway_token_audit_events` for clarity; keep the semantics append-only and support-safe either way.
- Exact idempotency-key shape is planner discretion if it remains support-safe, deterministic enough for retries, and does not include raw token or unsafe subject/session/device identifiers.
- Exact optional Oban snippet placement is planner discretion. It must remain non-compiled and clearly host-owned.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.9 goal, constraints, non-goals, and Chimeway companion-first decision.
- `.planning/REQUIREMENTS.md` - TOKN-03 requirement and v3.9 out-of-scope notification delivery/action boundaries.
- `.planning/ROADMAP.md` - Phase 60 goal, success criteria, and adjacent Phase 59/61/62/63 boundaries.
- `.planning/STATE.md` - current workflow position and deferred provider/device proof posture.
- `.planning/research/v3.9/SUMMARY.md` - v3.9 Chimeway research recommendation, contract shape, failure modes, and proof posture.

### Prior Crosswake decisions
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-CONTEXT.md` - Chimeway contract, lifecycle vocabulary, evidence/authority boundary, redaction posture, and Phase 60 transaction handoff.
- `.planning/phases/59-chimeway-contract-and-token-binding-semantics/59-PATTERNS.md` - Chimeway implementation analogs and data flow.
- `.planning/milestones/v3.8-phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` - server-record and audit/projection pattern.
- `.planning/milestones/v3.8-phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md` - `Ecto.Multi` consume/audit/projection and session scope lessons.
- `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-CONTEXT.md` - telemetry registry, forbidden metadata, and security closeout posture.

### Existing Crosswake code
- `lib/crosswake/companions/chimeway/contracts.ex` - Phase 59 token evidence, binding, feedback, binding event, and binding result contracts.
- `lib/crosswake/companions/chimeway/redaction.ex` - raw-token redaction and provider feedback normalization helpers.
- `lib/crosswake/companions/chimeway/telemetry.ex` - stable notification telemetry names, safe metadata keys, and forbidden metadata keys.
- `lib/crosswake/bridge/commands/notification_token.ex` - bounded bridge input evidence source.
- `lib/crosswake/bridge/commands/permissions_status.ex` - notification permission status vocabulary.
- `lib/crosswake/companions/sigra/handoff.ex` - server-record lifecycle and audit analog.
- `lib/crosswake/companions/sigra/step_up.ex` - intent lifecycle and audit analog.
- `lib/crosswake/companions/sigra/telemetry.ex` - telemetry sanitizer analog.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` - example-host `Ecto.Multi` issue/redeem/revoke flow.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex` - example-host lifecycle schema analog.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` - newer `Ecto.Enum`-backed schema style.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/*audit*.ex` - append-only audit schema analogs.
- `examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs` - Sigra lifecycle migration analog.
- `examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs` - Sigra audit migration analog.
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs` - `Ecto.Enum`-friendly auth-return migration analog.
- `guides/companions.md` - Chimeway non-claim anchor and companion docs posture.
- `guides/support_matrix.md` - current notification-token support truth and delivery/open non-claims.

### Prompt corpus
- `prompts/crosswake-brand-book.md` - boundary-aware language and anti-hype product positioning.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, support truth, proof lanes, and narrow public APIs.
- `prompts/crosswake-gsd-project-brief.md` - route policy, bounded bridge, capability registry, and companion context.
- `prompts/crosswake-integrations-and-companions.md` - Chimeway companion classification and notification journey visibility goals.
- `prompts/crosswake-research-synthesis.md` - canonical route-policy/runtime-boundary thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - notification/deep-link boundary and mobile app archetype pressure.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - optional push package/adapter lessons and no-host-consent token storage footgun.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - bridge command/event plane, support truth, DX, and notification token registration context.

### External primary references checked during discussion
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - idiomatic grouping of named Repo operations in a transaction and result shaping.
- `https://hexdocs.pm/ecto/Ecto.Changeset.html` - unique constraint handling through database indexes and changeset errors.
- `https://hexdocs.pm/ecto/Ecto.Enum.html` - atom/string enum persistence for closed vocabularies.
- `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` - partial indexes with `where` options.
- `https://hexdocs.pm/oban/Oban.html` - optional durable job integration and job insertion into `Ecto.Multi`.
- `https://firebase.google.com/docs/cloud-messaging/manage-tokens` - FCM token storage, freshness timestamps, stale pruning, and invalid-token handling.
- `https://firebase.google.com/docs/cloud-messaging/error-codes` - FCM invalid/unregistered/sender-mismatch style feedback.
- `https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:didregisterforremotenotificationswithdevicetoken:)` - APNs token registration callback and token-change caution.
- `https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/HandlingRemoteNotifications.html` - APNs remote notification registration behavior and token refresh guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Chimeway.Contracts` already defines the closed token evidence, binding, feedback, binding event, and binding result vocabulary Phase 60 should map into host persistence.
- `Crosswake.Companions.Chimeway.Redaction` already provides the raw-token boundary and provider feedback normalization helpers.
- `Crosswake.Companions.Chimeway.Telemetry` already defines stable notification telemetry and forbidden metadata.
- Sigra example-host modules provide the closest Ecto schema, migration, transaction, audit, and telemetry analogs.
- `guides/companions.md` and `guides/support_matrix.md` already carry notification non-claims that Phase 60 must preserve.

### Established Patterns
- Core companion contracts remain pure Elixir; host/example persistence and raw secret handling stay in `examples/phoenix_host`.
- Backend context supplies identity/session scope; bridge/provider token evidence never chooses the subject.
- `Ecto.Multi` is the local pattern for lifecycle writes that must succeed or fail together.
- Durable audit rows and diagnostic telemetry are distinct surfaces. Audit writes happen in the transaction; telemetry emits after success.
- Provider/device proof remains advisory until explicit promotion criteria pass.

### Integration Points
- Add example-host Chimeway schemas and registry module under `examples/phoenix_host/lib/crosswake_example/chimeway/` or equivalent.
- Add migrations under `examples/phoenix_host/priv/repo/migrations/`.
- Add tests under `examples/phoenix_host/test/` if that project has its own suite, or under `test/crosswake/proof/`/`test/crosswake/...` following existing example-host proof patterns.
- Phase 61 will consume active bindings/open evidence; do not implement route-open resolution in Phase 60.
- Phase 62 will consume registry/support truth; keep Phase 60 docs narrow and non-claiming.

</code_context>

<specifics>
## Specific Ideas

- Recommended core API:
  ```elixir
  CrosswakeExample.Chimeway.Registry.bind_or_rotate(context, token_evidence)
  CrosswakeExample.Chimeway.Registry.revoke_for_logout(context, opts)
  CrosswakeExample.Chimeway.Registry.revoke_for_session_revocation(session_ref, opts)
  CrosswakeExample.Chimeway.Registry.revoke_for_permission_loss(context, opts)
  CrosswakeExample.Chimeway.Registry.apply_provider_feedback(provider_feedback, opts)
  CrosswakeExample.Chimeway.Registry.prune_stale(opts)
  ```
- Recommended transaction shape:
  ```elixir
  Ecto.Multi.new()
  |> Ecto.Multi.update_all(:supersede_displaced, displaced_query, set: [...])
  |> Ecto.Multi.insert(:binding, TokenBinding.changeset(%TokenBinding{}, attrs))
  |> Ecto.Multi.insert(:audit_event, fn %{binding: binding} -> audit_changeset(binding, attrs) end)
  |> Repo.transaction()
  ```
- Recommended telemetry shape: transaction returns sanitized `binding_result`/`audit_event`; caller emits `Crosswake.Companions.Chimeway.Telemetry.execute/3` after commit.
- Optional Oban guidance should be a host-owned snippet calling `Registry.prune_stale/1` or `Registry.apply_provider_feedback/2`; it must not be compiled into Crosswake or the example host by default.

</specifics>

<deferred>
## Deferred Ideas

- Fully normalized production token/device/installation/subject model remains a future production extension, not Phase 60.
- Bundled Chimeway/Oban/Quantum/Broadway worker modules remain deferred.
- Notification-open resolver, route activation source, Sigra step-up reuse, and notification denial vocabulary remain Phase 61.
- Broad doctor, support matrix, operator inspection, docs-contract parity, and support truth expansion remain Phase 62.
- Real APNs/FCM delivery adapters, provider credentials, tray behavior, provider console metrics, and delivery proof remain advisory/future work.

</deferred>

---

*Phase: 60-Example Host Registry And Phoenix Wiring*
*Context gathered: 2026-06-02*
