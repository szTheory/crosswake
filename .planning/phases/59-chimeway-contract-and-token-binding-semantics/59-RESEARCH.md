# Phase 59: Chimeway Contract And Token Binding Semantics - Research

**Researched:** 2026-06-02
**Status:** Ready for planning

## Research Question

What does the planner need to know to implement Phase 59 without widening Crosswake into a push delivery platform?

## Summary

Phase 59 should implement a compact, pure-Elixir Chimeway companion contract family under `lib/crosswake/companions/chimeway/`. The existing `notifications.token.get` bridge response is the input evidence source, but it currently carries raw token material and must not become the public Chimeway shape. Chimeway should adapt that bridge evidence into support-safe token evidence and backend-owned binding contracts with closed provider/platform/environment/state/reason vocabularies, safe serialization, and explicit redaction helpers.

The strongest local analogs are:

- `Crosswake.Companions.StoreKit.Evidence` and `Crosswake.Companions.PlayBilling.Evidence` for small provider evidence structs and canonical normalization.
- `Crosswake.Companions.Sigra.Contracts` for backend-owned authority contracts and validation helpers.
- `Crosswake.Companions.Sigra.Telemetry` for stable event names, metadata allowlists, forbidden metadata, and low-cardinality sanitization.
- `Crosswake.Companions.Sigra.DenialCodes` for safe detail allowlists and string-boundary normalization.
- `Crosswake.SupportMatrix` for keeping notification-token support advisory until later diagnostic phases update support truth.

## Codebase Findings

### Existing Notification Bridge Evidence

`lib/crosswake/bridge/commands/notification_token.ex` defines `Crosswake.Bridge.Commands.NotificationToken.Response` with:

- `provider`: normalized string, currently `"apns"` or `"fcm"`.
- `token`: required non-empty raw token.
- `notification_status`: one of `PermissionsStatus.supported_statuses/0`.
- `detail`: unstructured map.

Planning implication: Chimeway should not reuse this response as its public contract because it retains raw token material and lacks installation, app identity, environment, subject/session scope, token ref/fingerprint, lifecycle, audit, and provider feedback fields. It can supply an adapter input for a redaction/fingerprinting helper.

### Permission Snapshot Vocabulary

`lib/crosswake/bridge/commands/permissions_status.ex` supports the `"notifications"` alias with statuses `:granted`, `:denied`, and `:restricted`.

Planning implication: Chimeway token evidence should accept this status vocabulary as notification permission posture, but permission state is evidence/readiness only. `:denied` should map to binding lifecycle reason `:permission_denied` only when backend lifecycle code in Phase 60 receives that event.

### Companion Pattern

`lib/crosswake/companion.ex` defines the six-callback companion behavior and describes companion telemetry as static, low-cardinality events. Existing companion modules are in-tree under `lib/crosswake/companions/`.

Planning implication: Phase 59 can introduce `Crosswake.Companions.Chimeway` as a first-party companion module plus contract modules. Route gating and dependency behavior can remain pass-through/unconfigured in Phase 59 if no route-open logic is implemented yet.

### Provider Evidence Normalization

StoreKit and Play Billing evidence modules share these useful patterns:

- `@enforce_keys` for minimal required provider evidence.
- `@type t` for typed public structs.
- `new/1` accepting maps or keywords.
- Closed environment normalization.
- Required subject/evidence identity separation.
- Provider-native values transformed into canonical evidence records.

Planning implication: Chimeway should follow that shape but be stricter about secrets. Unlike Play Billing's `purchase_token`, Chimeway should not retain raw token in the public struct; use `token_ref` and `token_fingerprint`.

### Sigra Authority And Redaction Patterns

Sigra contracts separate backend-owned authority from evidence lanes and reject evidence maps that try to carry authority fields. Sigra telemetry defines:

- static event names,
- `metadata_keys/0`,
- `forbidden_metadata_keys/0`,
- `metadata/1` sanitizer,
- `to_map/1`,
- bounded safe values.

Sigra denial codes define safe detail keys and drop unsafe values.

Planning implication: Chimeway should add a dedicated telemetry/redaction contract rather than letting unstructured metadata pass through. A `Crosswake.Companions.Chimeway.Telemetry` module should mirror the Sigra pattern with notification-specific events and forbidden keys.

### Current Support Truth

`Crosswake.SupportMatrix` currently has one notification support truth entry: `"notification_token provider snapshot"` with advisory proof and `delivery_supported: false`. Guides state notification-token readiness is provider-snapshot only and Chimeway delivery/open routing is not shipped.

Planning implication: Phase 59 should create contract anchors and tests, but broad support matrix, doctor, operator, and rendered guide expansion belongs to Phase 62. Do not let Phase 59 claim delivery, open routing, provider credentials, or tray behavior.

## Recommended Contract Modules

Planner should strongly consider these modules:

- `lib/crosswake/companions/chimeway.ex`
- `lib/crosswake/companions/chimeway/contracts.ex`
- `lib/crosswake/companions/chimeway/telemetry.ex`

Optional if the plan wants smaller files:

- `lib/crosswake/companions/chimeway/redaction.ex`
- `lib/crosswake/companions/chimeway/provider_feedback.ex`

Recommended structs inside `Contracts`:

- `TokenEvidence`
- `TokenBinding`
- `ProviderFeedback`
- `BindingEvent` or `AuditEvent`
- `BindingResult`

## Required Vocabulary

Provider vocabulary:

- `:apns`
- `:fcm`

Platform vocabulary:

- `:ios`
- `:android`

Environment vocabulary:

- `:sandbox`
- `:production`
- `:development`
- `:unknown`

Binding state vocabulary:

- `:active`
- `:superseded`
- `:revoked`
- `:stale`
- `:invalid`

Binding reason vocabulary:

- `:initial_bind`
- `:token_rotated`
- `:logout_revoked`
- `:session_revoked`
- `:permission_denied`
- `:provider_unregistered`
- `:provider_invalid_token`
- `:environment_mismatch`
- `:app_identity_mismatch`
- `:staleness_pruned`
- `:manual_revocation`

Provider feedback event vocabulary:

- `:token_unregistered`
- `:token_invalid`
- `:environment_mismatch`
- `:app_identity_mismatch`
- `:credentials_invalid`
- `:provider_throttled`
- `:provider_unavailable`
- `:delivery_accepted`
- `:delivery_failed`

Important semantic note: `:delivery_accepted` means provider handoff only. It does not prove user-visible delivery, tray display, open behavior, route activation, or entitlement/auth authority.

## Field Guidance

`TokenEvidence` should require:

- `provider`
- `platform`
- `environment`
- `installation_ref`
- `token_ref`
- `token_fingerprint`
- `notification_status`
- `observed_at`

It should allow safe optional fields:

- `app_identity`
- `correlation_id`
- `metadata`

It should not contain:

- `token`
- `raw_token`
- `device_token`
- `registration_token`
- provider payload bodies
- notification title/body
- route params
- subject/session identifiers unsafe for support output

`TokenBinding` should require:

- `binding_ref`
- `installation_ref`
- `provider`
- `platform`
- `environment`
- `token_ref`
- `token_fingerprint`
- `state`
- `reason`
- `bound_at`
- `last_seen_at`

It should allow backend-owned optional scope:

- `subject_scope`
- `subject_ref`
- `org_ref`
- `session_ref`
- `session_version`
- `app_identity`
- `superseded_at`
- `revoked_at`
- `stale_at`
- `invalidated_at`
- `audit_ref`
- `metadata`

`ProviderFeedback` should keep provider facts separate from backend binding authority. It can carry provider, platform, environment, token ref/fingerprint, feedback event, occurred timestamp, provider evidence ref, correlation id, and safe metadata.

`BindingEvent` or `AuditEvent` should provide support-safe lifecycle truth with state before/after, lifecycle reason, provider feedback event, occurred_at, correlation id, proof class, and audit ref.

## Redaction And Fingerprint Strategy

Phase 59 should provide deterministic helpers that turn host-boundary token material into safe Chimeway fields:

- `token_ref`: host-generated opaque reference or deterministic test reference.
- `token_fingerprint`: prefixed digest such as `hmac-sha256:<hex>`.

Do not store a raw token in public Chimeway structs. If a helper accepts raw token material, it must return only safe evidence and should reject blank tokens. Tests should assert `inspect/1`, `to_map/1`, telemetry metadata, fixtures, and errors do not expose fixture raw token strings.

Prefer a host-supplied fingerprint secret or function in later host wiring. Phase 59 can implement a deterministic pure helper for tests if it is clearly not a credential and does not imply deliverability.

## Telemetry Guidance

Add a Chimeway telemetry module with stable event names. Suggested event names:

- `[:crosswake, :notification, :token, :observed]`
- `[:crosswake, :notification, :token, :bound]`
- `[:crosswake, :notification, :token, :rotated]`
- `[:crosswake, :notification, :token, :revoked]`
- `[:crosswake, :notification, :token, :stale]`
- `[:crosswake, :notification, :token, :invalidated]`
- `[:crosswake, :notification, :provider, :feedback]`

Safe metadata keys should include only low-cardinality and support-safe values:

- `provider`
- `platform`
- `environment`
- `state`
- `reason`
- `feedback_event`
- `notification_status`
- `app_identity_posture`
- `proof_class`
- `correlation_id`

Forbidden metadata keys should include at minimum:

- `token`
- `raw_token`
- `device_token`
- `registration_token`
- `apns_token`
- `fcm_token`
- `provider_payload`
- `raw_payload`
- `notification_title`
- `notification_body`
- `route_params`
- `actor_id`
- `subject_ref`
- `session_ref`
- `device_id`
- `ip`
- `user_agent`
- `email`
- `provider_response_body`

## Tests To Plan

Use focused tests under `test/crosswake/companions/chimeway/` or one phase proof file. Cover:

- token evidence rejects unsupported provider/platform/environment/status,
- token evidence requires token ref and fingerprint,
- bridge response adapter/redaction never retains raw token,
- binding state/reason vocabulary covers TOKN-02 cases,
- provider feedback normalizes APNs/FCM-like events to canonical events,
- `to_map/1` stringifies atoms at JSON/support boundaries,
- telemetry drops forbidden metadata and keeps safe low-cardinality metadata,
- raw token strings do not appear in `inspect/1`, `to_map/1`, errors, telemetry metadata, or fixture maps,
- provider-native enums do not appear as route policy, binding state, or support-matrix states.

## Validation Architecture

### Dimension 1: Requirement Coverage

Plan verification must confirm TOKN-01 and TOKN-02 both appear in plan frontmatter and that tasks explicitly cover `notifications.token.get` evidence adaptation, backend-owned binding semantics, and every lifecycle state named in TOKN-02.

### Dimension 2: Authority Boundary

Validation should assert that no Chimeway public struct treats token possession as auth, session, route, delivery, or identity authority. Evidence structs should be input facts; binding structs should be backend-owned projections with subject/session scope supplied by host/backend context only.

### Dimension 3: Redaction

Validation should seed a recognizable raw token such as `raw_apns_token_should_not_leak_123` and assert it is absent from safe evidence, binding, audit event, telemetry metadata, `to_map/1`, and `inspect/1` output.

### Dimension 4: Vocabulary Closure

Validation should assert canonical provider/platform/environment/state/reason/feedback vocabularies are closed, helper accessors return the expected atoms, and unsupported values return errors or raise in the established local style.

### Dimension 5: Provider-Neutral Normalization

Validation should include APNs-like and FCM-like feedback examples and assert they normalize into Chimeway canonical feedback and binding reasons without provider-native enums becoming public route-policy vocabulary.

### Dimension 6: Telemetry Safety

Validation should assert Chimeway telemetry mirrors Sigra's sanitizer shape: stable event names, safe metadata keys, forbidden metadata keys, safe values only, and no raw tokens, provider payloads, PII, route params, or long arbitrary strings.

### Dimension 7: Phase Boundary

Validation should assert Phase 59 does not implement example-host Ecto registry flows, notification-open route resolution, doctor/support rendered truth changes beyond contract anchors, APNs/FCM provider credentials, delivery adapters, or device/tray behavior.

## Planning Risks

- Over-planning Phase 60 lifecycle storage into Phase 59 would blur pure contracts and host persistence.
- Reusing `NotificationToken.Response` directly would leak raw token material into public Chimeway APIs.
- Flat binding states would fail TOKN-02 because rotated, permission-denied, environment-mismatched, and app-identity-mismatched cases need distinct state/reason semantics.
- Adding support-matrix claims too early would imply delivery/open support before Phase 62.
- Treating provider `delivery_accepted` as actual delivery would violate the milestone non-goal.

## Recommended Plan Shape

One to three plans should be enough:

1. Contract vocabulary and structs for `TokenEvidence`, `TokenBinding`, `ProviderFeedback`, and lifecycle/audit event records.
2. Redaction/fingerprint helpers plus bridge-response adapter and telemetry sanitizer.
3. Contract proof tests and narrow docs anchors, if not merged into the first two plans.

Keep plans pure-Elixir and contract-focused. Phase 60 should own Ecto registry and transaction implementation.

## RESEARCH COMPLETE
