# Phase 59: Chimeway Contract And Token Binding Semantics - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Define the first-party Chimeway companion contract for provider-neutral notification token evidence and backend-owned token binding.

**Delivers:**
- A small Chimeway contract family for token evidence, token binding, provider feedback, binding audit/events, safe telemetry metadata, and redaction helpers.
- Explicit proof that `notifications.token.get` remains provider/device evidence only, never auth, session, delivery, route, or identity authority.
- Backend-owned token binding semantics that cover provider, platform, environment, installation ref, app identity, subject/session scope, token ref/fingerprint, lifecycle state, reason, timestamps, and safe audit fields.
- Canonical Chimeway vocabulary that normalizes APNs/FCM facts without leaking provider-specific enums into route policy.
- A raw-token boundary: token material is host-owned and excluded from telemetry, fixtures, denials, support output, and docs.

**In scope:**
- Pure Elixir contract structs/constructors/validators under the Chimeway companion namespace.
- Closed provider/platform/environment/state/reason/feedback vocabularies.
- Safe serialization/redaction posture for support, telemetry, fixtures, and proof.
- Contract-level tests and docs anchors for TOKN-01/TOKN-02.

**Out of scope:**
- Example-host Ecto registry implementation, rotation/revocation/pruning flows, and worker guidance; those belong to Phase 60.
- Notification-open route resolver, RouteGate activation source, and Sigra step-up reuse; those belong to Phase 61.
- Doctor/support/docs/telemetry expansion beyond contract anchors; those belong to Phase 62.
- APNs/FCM delivery adapters, provider credentials, real token issuance, tray behavior, and delivery guarantees; those remain advisory and belong to later proof/promotion work.

</domain>

<decisions>
## Implementation Decisions

### 1. Contract Surface Shape - LOCKED
- **D-01:** Ship Chimeway as an in-tree first-party companion contract family, not as a generic core notification abstraction, not as a provider plugin bus, and not as a push delivery platform.
- **D-02:** Define the contract family around `TokenEvidence`, `TokenBinding`, `ProviderFeedback`, `BindingEvent` or `AuditEvent`, and `BindingResult` under a namespace such as `Crosswake.Companions.Chimeway.Contracts`.
- **D-03:** `TokenEvidence` represents observed provider/device facts from the bounded bridge or provider feedback. It is not authority and does not prove identity, session, route activation, or delivery.
- **D-04:** `TokenBinding` represents the backend-owned projection record or row shape. It is the contract downstream Phase 60 should map into an Ecto schema and transaction flow.
- **D-05:** `ProviderFeedback` represents APNs/FCM provider facts that can invalidate, stale, revoke, or explain bindings. Provider feedback remains evidence and cannot prove user-visible delivery.
- **D-06:** Reject a minimal wrapper around `Crosswake.Bridge.Commands.NotificationToken.Response` as the Chimeway contract. The bridge response contains raw token evidence and lacks subject scope, installation, environment, app identity, lifecycle, revocation, stale, and audit semantics.
- **D-07:** Reject provider-evidence-only and binding-only designs. Evidence-only loses backend authority; binding-only loses provenance. The combined family keeps the same separation that v3.7 commerce and v3.8 Sigra already proved.
- **D-08:** Keep the Phase 59 contract compact and closed. Do not pull forward delivery providers, topic/subscription APIs, notification action registries, route-open resolver behavior, or worker dependencies.

### 2. Token Evidence And Binding Fields - LOCKED
- **D-09:** `TokenEvidence` should carry provider, platform, environment, installation ref, token ref, token fingerprint, notification/permission status, app identity posture, observed timestamp, correlation ref, and safe metadata.
- **D-10:** `TokenEvidence` should not expose a normal public `token` field. If a helper accepts raw token material, the helper must immediately produce a redacted safe evidence shape and must not retain raw token in a public struct.
- **D-11:** `TokenBinding` should carry binding ref, subject ref or support-safe subject scope, optional org scope, optional session ref/version for auth-sensitive bindings, installation ref, provider, platform, environment, app identity, token ref, token fingerprint, lifecycle state, lifecycle reason, bound/last-seen/superseded/revoked/stale/invalidated timestamps, audit ref, and safe metadata.
- **D-12:** Subject/session fields are backend context, not bridge evidence. Planners should preserve host-owned lookup/projection and avoid letting shell token possession choose the subject.
- **D-13:** App identity should be low-cardinality and support-safe: bundle id/package id posture, environment, topic/sender/project posture, or a stable app identity ref. Do not include raw provider credentials or provider payload bodies.
- **D-14:** Exact struct/module names are planner discretion, but the shape should be explicit typed structs with `@enforce_keys`, `@type t`, constructor/validator helpers, and safe `to_map/1` serialization mirroring existing Crosswake contract style.

### 3. Authority Boundary - LOCKED
- **D-15:** Token possession is never registration authority. `notifications.token.get` produces provider token evidence; Chimeway validates and redacts/fingerprints it; the Phoenix backend binds only when authenticated backend context exists.
- **D-16:** Default user-targeted binding requires authenticated backend context and should include subject plus installation scope. Auth-sensitive notification eligibility later reuses Sigra session authority; Phase 59 only records the binding semantics.
- **D-17:** Session scope may be present for auth-sensitive bindings so logout/session revocation can revoke affected bindings. Session scope may be nullable only for explicitly lower-risk install-level readiness or future install-only notification classes.
- **D-18:** Installation-only records may exist as unassociated evidence/readiness records, but they are not user delivery authority and must not silently promote to subject authority without backend auth.
- **D-19:** Self-contained signed binding artifacts are allowed only as optional locators/correlation artifacts. They do not replace server-side lifecycle records and do not become binding authority.
- **D-20:** Provider-owned identity mappings such as Expo tokens, OneSignal external ids, or Firebase token tables are useful prior art but remain provider facts. Phoenix host identity and Crosswake route policy remain authoritative.
- **D-21:** Phase 60 should use an `Ecto.Multi`-style host transaction for bind/rotate/revoke flows: validate backend context, fingerprint token, revoke displaced active binding, insert/upsert current binding, insert safe audit event, and emit sanitized telemetry after transaction success.

### 4. Lifecycle And Provider Vocabulary - LOCKED
- **D-22:** Use a lifecycle state plus reason split for backend-owned token bindings rather than a flat state enum that mixes lifecycle and cause.
- **D-23:** Canonical binding states:
  - `:active`
  - `:superseded`
  - `:revoked`
  - `:stale`
  - `:invalid`
- **D-24:** Canonical binding reasons:
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
- **D-25:** This split satisfies TOKN-02 without semantic confusion:
  - active -> `state: :active`
  - rotated -> old binding `state: :superseded, reason: :token_rotated`
  - revoked -> `state: :revoked`
  - stale -> `state: :stale, reason: :staleness_pruned`
  - invalid -> `state: :invalid, reason: :provider_invalid_token`
  - permission-denied -> `state: :revoked, reason: :permission_denied`
  - environment-mismatched -> `state: :invalid, reason: :environment_mismatch`
  - app-identity-mismatched -> `state: :invalid, reason: :app_identity_mismatch`
- **D-26:** Provider feedback should use a separate canonical event taxonomy, initially:
  - `:token_unregistered`
  - `:token_invalid`
  - `:environment_mismatch`
  - `:app_identity_mismatch`
  - `:credentials_invalid`
  - `:provider_throttled`
  - `:provider_unavailable`
  - `:delivery_accepted`
  - `:delivery_failed`
- **D-27:** `:delivery_accepted` means the provider accepted handoff, not user-visible delivery, tray display, open behavior, or route activation.
- **D-28:** Provider-native APNs/FCM/Expo values may appear only inside sanitized evidence metadata or mapping tests. Do not expose provider-native enums as binding state, route policy vocabulary, denial vocabulary, or public support-matrix states.
- **D-29:** Use atoms internally for closed vocabularies, strings at JSON/support/manifest boundaries, explicit vocabulary helpers, canonical atom/string normalizers, and safe serialization that stringifies atoms.

### 5. Raw Token Redaction And Safe Audit - LOCKED
- **D-30:** Raw APNs/FCM token material is host-owned secret material. Crosswake public structs, telemetry, denials, support output, guide text, proof fixtures, and operator surfaces must not contain raw tokens.
- **D-31:** Public Chimeway evidence should carry both an opaque `token_ref` and a `token_fingerprint`; `token_ref` is the support-safe host reference, and `token_fingerprint` supports dedupe, rotation, invalidation matching, audit joins, and fixture proof.
- **D-32:** Prefer HMAC-SHA256 or a host-configured digest helper for token fingerprints. Do not treat the fingerprint as a deliverable credential, and document digest-secret rotation implications.
- **D-33:** Provide or specify a redaction helper shape such as `redact_token_evidence/2` that accepts host boundary input and returns only safe Chimeway evidence.
- **D-34:** If any temporary boundary struct can carry raw material, implement a redacting `Inspect` protocol. Better default: avoid raw-token fields in Crosswake structs entirely.
- **D-35:** Changesets that cast raw token material belong only in host/example app schemas or provider-send adapters, never in Crosswake support/doctor/operator structs. Avoid changeset errors that echo raw params.
- **D-36:** Safe audit fields should be allowlisted. Strong initial set: event id, event type, binding ref, token ref, token fingerprint, provider, platform, environment, installation ref, state before/after, lifecycle reason, provider feedback reason, app identity posture, permission posture, occurred_at, correlation id, and proof class.
- **D-37:** Forbidden fields include token, raw token, device token, registration token, APNs token, FCM token, provider payload, raw payload, notification title/body, route params, actor id, subject ref where unsafe for support output, session ref where unsafe for support output, device id, IP, user agent, email, and provider response body.
- **D-38:** Telemetry is diagnostic evidence only, not durable audit or binding authority. Follow Sigra's registry/sanitizer pattern: stable event names, `metadata_keys/0`, `forbidden_metadata_keys/0`, `metadata/1`, and low-cardinality safe values.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-39:** Firebase's current token-management guidance treats registration tokens as mutable app-instance delivery addresses that must be stored server-side with timestamps, periodically refreshed, pruned when stale, and removed on invalid-token responses. Chimeway should encode this as backend lifecycle semantics, not a delivery guarantee.
- **D-40:** Apple's APNs guidance treats device tokens as app/device/environment evidence that can change and can fail when entitlements, network, or APNs conditions are wrong. Chimeway should model environment/app-identity mismatch as safe lifecycle reasons.
- **D-41:** Expo/OneSignal-style provider registries show useful subscription and external-id ergonomics, but their provider identity mappings must not replace Phoenix host identity or Crosswake route authority.
- **D-42:** Payment/auth ecosystems reinforce the same boundary: raw secrets are usable only at the provider boundary; public diagnostics log ids, refs, states, outcomes, and fingerprints.
- **D-43:** Phoenix/Ecto idioms favor explicit structs, closed vocabularies, changesets at host persistence boundaries, `Ecto.Multi` for transactional lifecycle transitions, and `:telemetry` for low-cardinality instrumentation.
- **D-44:** The prompt corpus reinforces the product thesis: route policy and bounded bridge contracts are valuable because they keep ownership explicit. Chimeway should continue that line, not become a hidden bridge magic or write-once push platform.

### the agent's Discretion
- Exact module names are planner discretion. Strong defaults: `Crosswake.Companions.Chimeway`, `Crosswake.Companions.Chimeway.Contracts`, `TokenEvidence`, `TokenBinding`, `ProviderFeedback`, `BindingEvent`, `BindingResult`, and `Telemetry`.
- Exact required keys may be refined during planning if the evidence/binding split, backend authority boundary, token redaction, and TOKN-02 lifecycle coverage remain intact.
- Exact token fingerprint helper implementation is planner discretion. Prefer host-configurable secret input and deterministic test fixtures without raw token material.
- Exact telemetry event names are planner discretion. Preserve stable names, low-cardinality metadata, forbidden-key sanitization, and diagnostic-only posture.
- Exact guide wording is planner discretion. Preserve the non-claim: Phase 59 does not ship delivery support, notification-open routing, topic APIs, provider credentials, or device proof.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.9 goal, constraints, non-goals, and Chimeway companion-first decision.
- `.planning/REQUIREMENTS.md` - TOKN-01/TOKN-02 active requirements and v3.9 out-of-scope delivery/action boundaries.
- `.planning/ROADMAP.md` - Phase 59 goal, success criteria, and adjacent Phase 60/61/62/63 boundaries.
- `.planning/STATE.md` - current workflow position and deferred provider/device proof posture.
- `.planning/research/v3.9/SUMMARY.md` - v3.9 Chimeway research recommendation, contract shape, failure modes, and proof posture.

### Prior Crosswake decisions
- `.planning/milestones/v3.5-phases/38-companion-seam-contract/38-CONTEXT.md` - shared companion contract, optional-dependency posture, in-tree companion convention, and telemetry pattern.
- `.planning/milestones/v3.7-phases/48-commerce-provider-adapter-context/48-CONTEXT.md` - provider evidence normalization, backend authority invariants, support truth, and advisory provider proof posture.
- `.planning/milestones/v3.8-phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` - backend-owned session authority and shell/client evidence non-authority.
- `.planning/milestones/v3.8-phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` - hybrid locator/server-record pattern and host-owned projection.
- `.planning/milestones/v3.8-phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md` - Ecto.Multi-style consume/audit/projection and session scope lessons.
- `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-CONTEXT.md` - telemetry registry, forbidden metadata, support truth, and security closeout posture.

### Existing Crosswake code
- `lib/crosswake/bridge/commands/notification_token.ex` - existing `notifications.token.get` bridge response; input evidence only.
- `lib/crosswake/bridge/commands/permissions_status.ex` - current notification permission snapshot vocabulary.
- `lib/crosswake/companion.ex` - shared companion behaviour and telemetry/doc posture.
- `lib/crosswake/companions/store_kit/evidence.ex` - provider-specific evidence normalization analog.
- `lib/crosswake/companions/play_billing/evidence.ex` - provider-specific evidence normalization analog.
- `lib/crosswake/companions/sigra/contracts.ex` - backend authority contract analog.
- `lib/crosswake/companions/sigra/handoff.ex` - server-record/locator and host projection analog.
- `lib/crosswake/companions/sigra/step_up.ex` - intent lifecycle and transition analog.
- `lib/crosswake/companions/sigra/telemetry.ex` - telemetry registry, metadata allowlist, forbidden-key sanitizer analog.
- `lib/crosswake/companions/sigra/denial_codes.ex` - safe detail allowlist and denial-code vocabulary analog.
- `lib/crosswake/support_matrix/support_matrix.ex` - current notification-token provider-snapshot support truth and promotion rule.
- `guides/support_matrix.md` - rendered support truth language to preserve and later update.
- `guides/companions.md` - canonical companion guide and current Chimeway non-claim anchor.

### Prompt corpus
- `prompts/crosswake-brand-book.md` - boundary-aware language and anti-hype product positioning.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, support truth, proof lanes, and narrow public APIs.
- `prompts/crosswake-gsd-project-brief.md` - route policy, bounded bridge, capability registry, and companion context.
- `prompts/crosswake-integrations-and-companions.md` - Chimeway as a companion candidate and integration classification model.
- `prompts/crosswake-research-synthesis.md` - canonical route-policy/runtime-boundary thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - capability ladder, native adapter boundaries, and mobile provider footguns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - bridge command/event plane, manifest truth, telemetry, and support-matrix lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Phoenix Hotwire-style shell/bridge lessons and push/deep-link boundary context.

### External primary references checked during discussion
- `https://firebase.google.com/docs/cloud-messaging/manage-tokens` - FCM token storage, freshness timestamps, stale pruning, invalid-token handling, and update cadence.
- `https://firebase.google.com/docs/cloud-messaging/error-codes` - FCM invalid/unregistered/sender-mismatch style feedback that must normalize into Chimeway evidence.
- `https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns` - APNs registration, app entitlement, network/provider failure, and app/device token evidence.
- `https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:didregisterforremotenotificationswithdevicetoken:)` - APNs token registration callback and token-change caution.
- `https://ecto.hexdocs.pm/Ecto.Multi.html` - idiomatic grouping of host-owned lifecycle writes into one transaction.
- `https://phoenix.hexdocs.pm/telemetry.html` - Phoenix/Elixir telemetry event and metadata posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Bridge.Commands.NotificationToken` already defines APNs/FCM bridge response evidence. Phase 59 should adapt from it, not promote it to authority.
- `Crosswake.Bridge.Commands.PermissionsStatus` already defines the narrow notification permission snapshot alias and status vocabulary.
- `Crosswake.Companion` establishes in-tree companion conventions, fail-closed optional dependency posture, and companion telemetry framing.
- StoreKit and Play Billing evidence modules prove a small provider-specific evidence struct can normalize provider facts without leaking provider enums into core contracts.
- Sigra contracts, handoff, step-up, telemetry, and denial-code modules provide the closest authority, lifecycle, audit, telemetry, and sanitizer analogs.
- `Crosswake.SupportMatrix.notification_support_truth/0` and the notification-token promotion rule already separate provider snapshot readiness from Chimeway delivery/open support.

### Established Patterns
- Core companion contracts stay pure Elixir. Host/example persistence, raw secret handling, and `Repo`/`Ecto.Multi` execution stay host-owned.
- Device/provider/native facts are evidence only until backend validation/projection promotes them into a backend-owned state.
- Public support truth derives from canonical accessors and rendered docs-contracts, not independent guide prose.
- Telemetry metadata is a public observability API and must stay stable, low-cardinality, and sanitized.
- Provider/device proof remains advisory until explicit promotion criteria pass.

### Integration Points
- Add Chimeway contracts under `lib/crosswake/companions/chimeway/`.
- Add tests under `test/crosswake/companions/chimeway/` and/or `test/crosswake/proof/phase59_chimeway_contract_test.exs`.
- Use `lib/crosswake/bridge/commands/notification_token.ex` as the source evidence adapter.
- Prepare Phase 60 example-host wiring to map `TokenBinding` into Ecto schema/migration/modules.
- Prepare Phase 62 support/doctor/operator/docs updates to consume Chimeway support truth without claiming delivery support.

</code_context>

<specifics>
## Specific Ideas

- Recommended architecture: `TokenEvidence -> TokenBinding -> BindingEvent/AuditEvent`, with `ProviderFeedback` as a separate evidence lane.
- Recommended safe evidence shape:
  ```elixir
  %Crosswake.Companions.Chimeway.Contracts.TokenEvidence{
    provider: :apns,
    platform: :ios,
    environment: :production,
    installation_ref: "inst_...",
    token_ref: "tokref_...",
    token_fingerprint: "hmac-sha256:...",
    notification_status: :granted,
    app_identity: %{bundle_id: "com.example.app"},
    observed_at: "2026-06-02T18:00:00Z",
    correlation_id: "corr_..."
  }
  ```
- Recommended backend binding shape:
  ```elixir
  %Crosswake.Companions.Chimeway.Contracts.TokenBinding{
    binding_ref: "ntb_...",
    subject_scope: :authenticated_subject,
    installation_ref: "inst_...",
    provider: :fcm,
    platform: :android,
    environment: :production,
    token_ref: "tokref_...",
    token_fingerprint: "hmac-sha256:...",
    state: :active,
    reason: :initial_bind,
    bound_at: "2026-06-02T18:00:00Z",
    last_seen_at: "2026-06-02T18:00:00Z"
  }
  ```
- Recommended forbidden fields list should include raw token aliases (`:token`, `:raw_token`, `:device_token`, `:registration_token`, `:apns_token`, `:fcm_token`), provider payloads, notification title/body, route params, PII, and unsafe subject/session/device identifiers.

</specifics>

<deferred>
## Deferred Ideas

- Example-host Ecto registry, migrations, changesets, `Ecto.Multi` bind/rotate/revoke/prune flows, and optional worker recipes are deferred to Phase 60.
- Notification-open envelopes, resolver evaluation, RouteGate `activation_source: :notification`, and Sigra step-up integration are deferred to Phase 61.
- Doctor, support matrix, operator inspection, guides, docs-contract parity, and telemetry rollout are deferred to Phase 62.
- APNs/FCM delivery adapters, real token issuance proof, provider credentials, notification-tray behavior, Focus/Doze/background behavior, topics/subscriptions, and provider console metrics remain advisory/deferred beyond Phase 59.

</deferred>

---

*Phase: 59-Chimeway Contract And Token Binding Semantics*
*Context gathered: 2026-06-02*
