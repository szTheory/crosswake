# Phase 57: OAuth, Passkey, And Native Return Boundaries - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship provider-neutral Sigra auth-return boundary contracts for OAuth, passkey, and native auth returns while preserving backend-owned session authority.

**Delivers:**
- Route-local `auth_return` policy and manifest truth for OAuth, passkey, and native auth-return routes.
- Pure Sigra `AuthReturn` contracts for evidence envelopes, protocol-specific evidence, validation requests, host-owned attempt records, completions, and audit events.
- Stable `auth.return.*` denial codes and safe detail allowlists under the existing public `:step_up_required` shell reason.
- Example-host Ecto attempt/audit record posture that proves replay, expiry, binding, audit, and authority promotion are host/backend-owned.
- Support, doctor, operator, guide, and proof truth that ships boundary contracts without claiming provider templates, passkey SDK wrappers, refresh-token orchestration, native auth UI, or device/provider proof.

**Satisfies:** RETN-01, RETN-02, RETN-03.

**In scope:**
- Provider-neutral route declarations: `kind`, `transport`, `return_route_id`, and `validates`.
- OAuth/OIDC evidence posture: state, nonce, PKCE, redirect/callback matching, issuer/audience/auth-time/acr evidence, expiry, and replay posture.
- Passkey/WebAuthn evidence posture: challenge, origin, RP ID, user verification, sign-count/risk posture, expiry, and replay posture.
- Native return evidence posture: verified HTTPS link status, callback binding, transport, platform, expiry, and replay posture.
- Host-owned one-time auth-return attempt records, append-only audit events, and backend projection into `SessionAuthorityLane`.
- Hermetic proof for contracts, denial sanitization, route policy/manifest truth, no-smuggling, server-record authority, and support/docs parity.

**Out of scope:**
- Provider-specific OAuth templates such as Google, GitHub, Apple, Okta, Auth0, or Microsoft.
- First-party passkey SDK wrappers, native auth UI, embedded WebView token authority, refresh-token rotation/orchestration, and generic auth plugin-bus behavior.
- Merge-blocking provider/device proof for AppAuth, Universal Links/App Links device behavior, provider SDK behavior, native passkey ceremonies, or shell event delivery.
- Phase 58 stable auth telemetry taxonomy, security closeout, and final proof consolidation.

</domain>

<decisions>
## Implementation Decisions

### 1. Route-Local Auth Return Seam - LOCKED
- **D-01:** Keep one route-policy key, `auth_return`, rather than global provider registries, bridge/capability declarations, or separate keys like `oauth_return`, `passkey_return`, and `native_auth_return`.
- **D-02:** `auth_return` is a route-local boundary declaration, not provider configuration and not route authority. It should carry only `kind`, `transport`, `return_route_id`, and `validates`.
- **D-03:** Keep `kind` provider-neutral and closed: `:oauth`, `:passkey`, `:native_auth`. Reject provider-specific route-policy vocabulary such as `:google`, `:github`, `:apple`, `:okta`, `:auth0`, `:google_oauth`, or `:apple_passkey`.
- **D-04:** Keep transport vocabulary semantic and closed: `:http_callback`, `:verified_https_link`, `:custom_scheme`, `:bridge_event`.
- **D-05:** Require `return_route_id` as a manifest-known Crosswake route id. Do not accept raw `return_to` URLs or provider callback URLs as route authority.
- **D-06:** Serialize `auth_return` into manifest route entries so shells, doctor, operator inspection, and support truth can see the route-local boundary.
- **D-07:** Auth-return routes should default to sensitive `:strict_recent` posture unless explicitly proven otherwise. Sensitive auth-return routes reject `:custom_scheme`; they require `:verified_https_link` or `:http_callback`.
- **D-08:** Required validations are kind-specific and fail closed:
  - OAuth: `:state`, `:pkce`, `:redirect_uri`, `:expiry`, `:replay`; include `:nonce` for OIDC-style returns and `:link_verification` for verified-link transports.
  - Passkey: `:challenge`, `:origin`, `:rp_id`, `:user_verification`, `:expiry`, `:replay`; include `:link_verification` for native-link transports.
  - Native auth: `:callback_binding`, `:link_verification`, `:expiry`, `:replay`.
- **D-09:** Reject global provider registries because they hide route ownership, leak provider vocabulary into core policy, and invite magic callback behavior.
- **D-10:** Reject capability/bridge-first auth declarations because bridge events are evidence, not route authority or session authority.

### 2. Evidence Envelope And Server Attempt Boundary - LOCKED
- **D-11:** Use a three-layer contract: route-local declaration, evidence-only envelope, and host-owned one-time attempt record.
- **D-12:** `AuthReturn.Envelope` may carry bounded facts such as `typ`, `return_ref`, version, issuer/audience, kind, route id, return route id, transport, expected/received callback, issued/expires timestamps, replay posture, link verification posture, validation posture, safe refs/digests, and nested provider-neutral evidence.
- **D-13:** `AuthReturn.Envelope` must reject raw access tokens, refresh tokens, ID tokens, authorization codes, credential IDs, authenticator data, client data JSON, PKCE verifiers, CSRF tokens, raw nonces, subject/org/session/device refs, raw provider payloads, raw `return_to`, and authority-setting fields.
- **D-14:** `AuthReturn.AttemptRecord` is the replay, expiry, revocation, binding, audit, and authority-promotion source of truth. It should include attempt ref/digest, kind, lifecycle state, subject/org/source-session refs, expected session version, route/return route ids, transport, link verification, state/nonce/PKCE digests, expected callback, provider audience, expiry, audit correlation, return params, and projected `SessionAuthorityLane`.
- **D-15:** Lifecycle states should stay closed and boring: `:issued`, `:consumed`, `:expired`, `:revoked`. Expiry must be enforced from `expires_at` even before cleanup marks rows expired.
- **D-16:** Signed or opaque return artifacts are acceptable as locators/correlation artifacts only. They must not be self-contained session authority, route authority, or replay authority.
- **D-17:** Promotion requires backend validation plus a host-owned transaction that atomically consumes an issued, unexpired, unreplayed attempt row, writes audit evidence, projects a fresh `SessionAuthorityLane`, and returns explicit session-renewal instructions.
- **D-18:** Use an idiomatic Phoenix/Ecto host shape: pure Crosswake contracts in core; Ecto schemas, provider library calls, Repo transaction, session key policy, CSRF/session renewal, and route redirect remain host/example-owned.
- **D-19:** The adopter-facing mental model should be: callback/deep-link/passkey success is evidence; only backend projection into `SessionAuthorityLane` satisfies route gates.

### 3. Protocol Validation And Denial Vocabulary - LOCKED
- **D-20:** OAuth/OIDC evidence must validate exact callback/redirect binding, state, PKCE posture, expiry, replay, issuer/audience, and nonce/auth-time/acr when present. `prompt=login`, provider SDK success, or native callback delivery cannot count as freshness or authority without backend validation.
- **D-21:** Passkey/WebAuthn evidence must validate challenge, origin, RP ID, user verification posture, signature/assertion posture, replay, and sign-count/backup posture as risk evidence. The shell or native client can collect an assertion, but cannot promote authority.
- **D-22:** Native return evidence must validate link verification posture and callback binding. Verified HTTPS links are preferred for sensitive native returns; custom schemes and bridge events are evidence-only lower-assurance transports.
- **D-23:** Preserve public shell reason `:step_up_required`. Do not add broad public reasons like `:auth_return_denied`.
- **D-24:** Use stable low-cardinality subcodes under `auth.return.*`. Required taxonomy:
  - `auth.return.oauth.missing_return`
  - `auth.return.oauth.invalid_return`
  - `auth.return.oauth.expired_return`
  - `auth.return.oauth.replayed_return`
  - `auth.return.oauth.state_mismatch`
  - `auth.return.oauth.nonce_mismatch`
  - `auth.return.oauth.pkce_missing`
  - `auth.return.oauth.redirect_mismatch`
  - `auth.return.passkey.missing_return`
  - `auth.return.passkey.invalid_return`
  - `auth.return.passkey.expired_return`
  - `auth.return.passkey.replayed_return`
  - `auth.return.passkey.challenge_mismatch`
  - `auth.return.passkey.origin_mismatch`
  - `auth.return.passkey.rp_id_mismatch`
  - `auth.return.passkey.user_verification_missing`
  - `auth.return.native_auth.missing_return`
  - `auth.return.native_auth.invalid_return`
  - `auth.return.native_auth.expired_return`
  - `auth.return.native_auth.replayed_return`
  - `auth.return.native_auth.link_unverified`
  - `auth.return.native_auth.callback_mismatch`
  - `auth.return.native_auth.projection_failed`
- **D-25:** Consider adding `projection_failed` parity for OAuth and passkey if planning finds support/operator truth needs symmetric promotion-failure reporting. If not added, docs should be explicit that `invalid_return` covers backend validation failures other than named mismatch cases.
- **D-26:** Safe shell/operator details are allowlisted: `auth_return_ref`, `auth_return_kind`, `auth_return_transport`, `auth_return_state`, `return_route_id`, `link_verification`, `validation_posture`, `return_expires_at`, `return_age_seconds`, and evaluated timestamps. They must not expose tokens, provider payloads, credential IDs, raw nonces, raw PKCE material, session refs, actor/org/device identifiers, IPs, or user agents.

### 4. Native Transport And Proof Posture - LOCKED
- **D-27:** Phase 57 is verified-link-first for sensitive native auth returns. `:verified_https_link` is the preferred native return posture because it binds app return to a domain; device verification remains advisory until promoted by explicit device/provider proof.
- **D-28:** `:http_callback` is the supported Phoenix/backend callback route posture for provider or web callback completion. It is merge-blocking when hermetically proven through exact redirect/callback, state, nonce, PKCE, expiry, replay, attempt-record, and route-binding checks.
- **D-29:** `:custom_scheme` is allowed only as an advisory fallback. It must remain lower-assurance because custom schemes can conflict or be intercepted; PKCE, state/nonce, replay checks, and backend attempt records are still mandatory.
- **D-30:** `:bridge_event` is internal shell evidence after manifest-first activation. It is not an OAuth redirect receiver, not passkey authority, not token transport, and not route authority.
- **D-31:** Loopback HTTP is desktop/CLI prior art and should not enter the v3.8 mobile-first support posture.
- **D-32:** Merge-blocking proof should cover provider-neutral contracts, route policy, manifest serialization, envelope no-smuggling, exact binding checks, denial-code/detail sanitization, server-record authority, example-host attempt/audit records, docs/support/operator parity, and explicit non-claims.
- **D-33:** Provider setup, provider SDK behavior, device link verification, AppAuth device runs, native passkey SDK wrappers, refresh-token helpers, native auth UI, and shell/device event delivery remain advisory or deferred.

### 5. Support Truth, Docs, And Example UX - LOCKED
- **D-34:** Public docs, doctor, support matrix, operator inspection, and proof fixtures should say Phase 57 ships provider-neutral auth-return boundary contracts and host-owned replay/attempt posture, not provider-specific auth support.
- **D-35:** Recommended public wording: "Sigra auth-return boundaries are provider-neutral contracts. Crosswake validates OAuth, passkey, and native auth-return envelopes before backend promotion, but OAuth providers, passkey SDK wrappers, native auth UI, refresh-token rotation, and device/provider proof remain deferred or advisory. Verified HTTPS links are required for sensitive native return claims; custom schemes and bridge events are evidence only. Route authority comes only from backend validation into `SessionAuthorityLane`."
- **D-36:** Doctor/operator truth should expose structured fields for `auth_return.status`, `authority_source`, `envelope_authority`, `route_policy_seam`, `sensitive_transport`, `custom_scheme_posture`, proof class, deferred provider/device/native surfaces, denial codes, and safe detail keys.
- **D-37:** The example-host UX should stay boring and provider-neutral. A useful future example is an "Auth Return Lab" with route-local selector (`oauth`, `passkey`, `native_auth`), mock evidence fields, verified-link status, replay/expiry/mismatch outcomes, and success copy that says backend session authority was projected. It must not claim Google login, Apple passkeys, provider support, native login support, or refresh-token support.
- **D-38:** Documentation should emphasize: "callback validated" does not mean "user authorized"; "native link delivered" does not mean "auth complete"; "passkey assertion received" does not mean "authority granted." Only backend validation and projection update route authority.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-39:** Phoenix/Plug lesson: session and CSRF mutation belongs at the host boundary after backend validation succeeds. Crosswake returns typed renewal instructions; it does not mutate `Plug.Conn` in core.
- **D-40:** Ecto lesson: consume + audit + projection should be one transaction, using `Ecto.Multi` or equivalent host-owned transaction composition. Avoid check-then-update races.
- **D-41:** OAuth/OIDC lesson: exact redirect matching, state, nonce, PKCE, issuer/audience validation, and generic user-facing failure modes are table stakes. External user agents are preferred for native OAuth; embedded WebView token authority is out of scope.
- **D-42:** WebAuthn/passkey lesson: server validation of challenge, origin, RP ID, user verification, and assertion details is authority-relevant; native collection is only evidence.
- **D-43:** AppAuth/native-platform lesson: custom schemes are widely used and useful, but verified HTTPS links are a stronger sensitive-default posture; provider/device success must not widen merge-blocking support claims by itself.
- **D-44:** Crosswake prompt-corpus lesson: keep core route policy narrow, typed, and provider-neutral; make support claims exact; split hermetic proof from advisory provider/device proof; make host-owned versus library-owned responsibilities clear.

### the agent's Discretion
- Exact module names are planner discretion if they stay clearly Sigra-scoped. Strong defaults are already present: `Crosswake.Companions.Sigra.AuthReturn`, `Envelope`, `OAuthEvidence`, `PasskeyEvidence`, `NativeEvidence`, `AttemptRecord`, `ValidationRequest`, `Completion`, and `AuditEvent`.
- Exact example-host module names and migration timestamps are planner discretion. Preserve host-owned Ecto persistence and audit shape.
- Exact wording in guides/support matrix can be refined, but must preserve provider-neutral shipped contract posture, verified-link-first sensitive posture, custom-scheme advisory posture, and backend-authority-only promotion.
- Exact provider evidence field names may be refined, but raw secrets/identifiers must remain forbidden in shell-safe details, envelopes, docs fixtures, and telemetry-ready metadata.
- Exact example UX may be deferred to Phase 58 or later if Phase 57 remains contract-only, but any example included should be provider-neutral and support-truth-aligned.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.8 milestone goal, constraints, key decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - RETN-01/02/03 requirements and adjacent DIAG/PROOF boundaries.
- `.planning/ROADMAP.md` - Phase 57 goal and success criteria; Phase 58 diagnostic/proof boundary.
- `.planning/STATE.md` - current workflow position, dirty-tree caveats, and known proof/test caveats.
- `.planning/research/v3.8/SUMMARY.md` - milestone-level research synthesis for auth returns, diagnostics, proof, and non-claims.

### Prior Sigra decisions
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` - backend-owned `SessionAuthorityLane`, evaluator, denial-code/detail sanitization, and evidence-vs-authority boundary.
- `.planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` - signed envelope plus server one-time record pattern, host-owned renewal instructions, denial posture, and audit truth.
- `.planning/phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md` - server-owned step-up intent, route-id return targets, Plug/LiveView ceremony boundary, and Phase 57 non-claims.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - original Sigra contract-only scope and `:step_up_required` route-auth posture.

### Existing Crosswake code
- `lib/crosswake/policy/schema.ex` - `auth_return` policy schema, provider-neutral kinds/transports/validations, and provider-specific term rejection.
- `lib/crosswake/policy/route.ex` - route-level validation for auth-return required fields, required validation sets, sensitive defaults, strict posture, and custom-scheme rejection.
- `lib/crosswake/manifest/types.ex` - `RouteAuthReturn` manifest type and route entry serialization target.
- `lib/crosswake/manifest/builder.ex` - manifest builder serialization for route-local `auth_return`.
- `lib/crosswake/companions/sigra/auth_return.ex` - pure Sigra auth-return evidence/envelope/attempt/completion/audit contracts and validators.
- `lib/crosswake/companions/sigra/denial_codes.ex` - canonical `auth.return.*` denial subcodes and safe auth-return detail allowlist.
- `lib/crosswake/companions/sigra/contracts.ex` - `SessionAuthorityLane`, `AuthContext`, and authority-fence validation.
- `lib/crosswake/companions/sigra/handoff.ex` - `SessionRenewalInstructions` and prior signed-envelope/server-record pattern.
- `lib/crosswake/companions/sigra/step_up.ex` and `lib/crosswake/companions/sigra/step_up_ceremony.ex` - Phase 56 intent/ceremony analogs for lifecycle, renewal, and support truth.
- `lib/crosswake/shell/denial.ex` - public shell denial vocabulary; preserve `:step_up_required`.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical Sigra support truth, shipped/deferred surfaces, proof class, and auth-return posture.
- `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, and `lib/crosswake/operator_inspection/types.ex` - diagnostic/operator surfaces to keep aligned.

### Example host and proof
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` - host-owned Ecto attempt-record schema.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex` - host-owned append-only audit event schema.
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs` - example-host attempt-record migration.
- `examples/phoenix_host/priv/repo/migrations/20260602080100_create_sigra_auth_return_audit_events.exs` - example-host audit-event migration.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` - Phase 57 proof anchors for denial vocabulary, safe details, route policy, manifest truth, no-smuggling, backend promotion, support truth, and example-host Ecto records.
- `test/crosswake/doctor/doctor_test.exs`, `test/crosswake/doctor/publish_readiness_test.exs`, `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/support_matrix/renderer_test.exs`, and `test/crosswake/guides/companions_test.exs` - docs/support/doctor parity targets touched by Phase 57 truth.

### Guides and prompt corpus
- `guides/companions.md` - canonical companion/Sigra guide and Phase 57 public non-claims.
- `guides/support_matrix.md` - support matrix row and public proof/non-claim language.
- `guides/native_shell.md` - shell/native support posture and bridge non-authority language.
- `prompts/crosswake-brand-book.md` - boundary-aware language, no hidden bridge magic, and honest support-claim posture.
- `prompts/crosswake-research-synthesis.md` - route policy/runtime boundary thesis and support-proof guardrails.
- `prompts/crosswake-integrations-and-companions.md` - Sigra companion classification and auth/session handoff/passkey/MFA integration context.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: install truth, public contract honesty, proof lanes, support matrices, and host-owned boundaries.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - sensitive route/cache/auth and bridge-security lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Phoenix-native session defaults, bridge security, route manifest, and sensitive route DX/operator lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - route-policy/bridge/security proof posture and ecosystem anti-patterns.

### External ecosystem references considered during discussion
- `https://www.rfc-editor.org/rfc/rfc8252` - OAuth 2.0 for Native Apps: external user-agent, claimed HTTPS redirects, custom scheme risks, and PKCE posture.
- `https://www.rfc-editor.org/rfc/rfc9700` - OAuth 2.0 Security Best Current Practice: exact redirect matching, replay/open-redirect/token-risk lessons.
- `https://www.rfc-editor.org/rfc/rfc7636` - PKCE: code interception mitigation.
- `https://openid.net/specs/openid-connect-core-1_0-18.html` - OIDC nonce, `auth_time`, `acr`, issuer/audience evidence concepts.
- `https://www.w3.org/TR/webauthn-3/` - WebAuthn/passkey server validation of challenge, origin, RP ID, user verification, and assertion.
- `https://hexdocs.pm/plug/Plug.Conn.html` - host-owned `configure_session/2` and session mutation boundary.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - idiomatic transaction shape for consume + audit + projection.
- `https://hexdocs.pm/phoenix/Phoenix.Token.html` - signed token integrity lessons; useful locator pattern, not backend authority.
- `https://phoenix-live-view.hexdocs.pm/security-model.html` - LiveView security model and shared backend auth evaluation.
- `https://developer.apple.com/documentation/xcode/supporting-associated-domains` - Universal Links/associated-domain verification posture.
- `https://developer.android.com/training/app-links/verify-applinks` - Android App Links verification posture.
- `https://appauth.io/` - mature native OAuth mechanics; useful prior art but not core support proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Sigra.AuthReturn` already defines the likely Phase 57 core contracts: `OAuthEvidence`, `PasskeyEvidence`, `NativeEvidence`, `Envelope`, `AttemptRecord`, `ValidationRequest`, `Completion`, and `AuditEvent`.
- `Crosswake.Companions.Sigra.DenialCodes` already includes `auth.return.*` codes and safe auth-return detail keys.
- `Crosswake.Policy.Schema` and `Crosswake.Policy.Route` already expose and validate route-local `auth_return`.
- `Crosswake.Manifest.Types.RouteAuthReturn` and `Crosswake.Manifest.Builder.route_auth_return/1` already provide manifest binding.
- Example-host `AuthReturnAttempt` and `AuthReturnAuditEvent` schemas already establish the host-owned persistence direction.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` already encodes many target proof assertions for this context.

### Established Patterns
- Core Crosswake contracts stay pure Elixir. Host/example apps own Ecto, Repo, provider SDK/library calls, Phoenix session keys, CSRF/session renewal, and redirects.
- Public shell reason vocabulary stays compact; richer low-cardinality subcodes live in Sigra denial-code registries and support/operator surfaces.
- Evidence-only companion/provider inputs never mutate authority directly. Backend projection into `SessionAuthorityLane` remains the authority boundary.
- Support truth is canonicalized through `SupportMatrix`, doctor, operator inspection, docs, fixtures, and proof tests.
- Environment-sensitive provider/device/native proof stays advisory unless promotion criteria explicitly pass.

### Integration Points
- Route policy/manifest: `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`.
- Sigra contracts: `lib/crosswake/companions/sigra/auth_return.ex`, `lib/crosswake/companions/sigra/denial_codes.ex`, and existing handoff/step-up renewal patterns.
- Example host: `examples/phoenix_host/lib/crosswake_example/saas_portal/` plus migrations under `examples/phoenix_host/priv/repo/migrations/`.
- Truth surfaces: `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/support_matrix/renderer.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, `guides/companions.md`, `guides/support_matrix.md`, and `guides/native_shell.md`.
- Proof: Phase 57 proof test plus existing doctor/support/guide parity tests.

</code_context>

<specifics>
## Specific Ideas

### Recommended route declaration

```elixir
live "/auth/oauth/return", OAuthReturnLive,
  crosswake: [
    id: "oauth-return",
    runtime: :live_view,
    auth_return: [
      kind: :oauth,
      transport: :verified_https_link,
      return_route_id: "billing-settings",
      validates: [
        :state,
        :nonce,
        :pkce,
        :redirect_uri,
        :link_verification,
        :expiry,
        :replay
      ]
    ]
  ]
```

### Recommended promotion flow

```elixir
parse_return
-> validate envelope shape and no-smuggling
-> lookup host attempt row by digest/ref
-> validate provider/protocol evidence
-> Ecto.Multi transaction:
     consume issued, unexpired, unreplayed attempt
     write audit event
     project SessionAuthorityLane
-> return SessionRenewalInstructions
-> host renews Phoenix session and redirects to manifest-known route
```

### Recommended support wording

Sigra auth-return boundaries are provider-neutral contracts. Crosswake validates OAuth, passkey, and native auth-return envelopes before backend promotion, but OAuth providers, passkey SDK wrappers, native auth UI, refresh-token rotation, and device/provider proof remain deferred or advisory. Verified HTTPS links are required for sensitive native return claims; custom schemes and bridge events are evidence only. Route authority comes only from backend validation into `SessionAuthorityLane`.

### Rejected approaches

- Global provider registry: hides route ownership and leaks provider-specific vocabulary into core policy.
- Capability/bridge-first declaration: makes shell evidence look like auth authority.
- Separate per-kind route keys: bloats the policy surface and creates parallel manifest shapes.
- Stateless signed return authority: too weak for one-time replay, revocation, audit, and support truth.
- Generic provider plugin bus: invites plugin sprawl and weakens typed route-local seams.

</specifics>

<deferred>
## Deferred Ideas

- Provider-specific OAuth templates and first-party identity-provider integrations.
- First-party passkey SDK wrappers and native passkey ceremony implementations.
- Refresh-token rotation/orchestration helpers.
- Native auth UI framework or native login screens.
- Merge-blocking AppAuth, Universal Links/App Links, provider SDK, native passkey, or device proof.
- Phase 58 auth telemetry taxonomy, security closeout, and final diagnostics/proof consolidation.

</deferred>

---

*Phase: 57-OAuth, Passkey, And Native Return Boundaries*
*Context gathered: 2026-06-02*
