# Phase 58: Auth Diagnostics, Proof, And Security Closeout - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Make full Sigra machinery inspectable, documented, telemetry-backed, proof-backed, and security-reviewed without overstating provider/device support.

**Delivers:**
- Stable `[:crosswake, :auth, ...]` telemetry events with low-cardinality, allowlisted metadata for session evaluation, denial, handoff, step-up, OAuth return, passkey return, and native auth-return flows.
- Doctor, support matrix, operator inspection, guides, and docs-contract truth that distinguishes full Sigra contract machinery from v3.5 contract-only truth, host route readiness, and advisory provider/device proof.
- Merge-blocking hermetic proof for deterministic Sigra contracts, route gates, replay/expiry/revocation, step-up returns, auth-return validation, denial sanitization, telemetry/docs parity, and security-sensitive non-claims.
- A bounded STRIDE-style security closeout artifact that reviews token/locator handling, handoff, step-up, auth-return, telemetry, denial, session renewal, support truth, and proof posture.

**In scope:**
- Provider-neutral Sigra telemetry registry and metadata sanitizer.
- Support/operator/doctor wording for shipped contract truth versus host/provider/device readiness.
- Layered proof lane posture: hermetic required lane plus advisory provider/device lane.
- Security closeout artifact quality and evidence model.

**Out of scope:**
- Provider-specific OAuth templates, passkey SDK wrappers, native auth UI, refresh-token helpers, direct shell/WebView token authority, and provider/device proof promotion.
- New route authority mechanisms. Backend `SessionAuthorityLane` and host-owned records remain authoritative.
- Treating telemetry, bridge events, deep links, provider payloads, handoff envelopes, step-up locators, or auth-return envelopes as authority.

</domain>

<decisions>
## Implementation Decisions

### 1. Telemetry Contract Shape - LOCKED
- **D-01:** Keep `Crosswake.Companions.Sigra.Telemetry` as the canonical registry for stable auth telemetry event names, metadata keys, forbidden metadata keys, flows, outcomes, freshness buckets, and proof classes.
- **D-02:** Use the current flow/lifecycle event shape rather than provider-specific event names, one generic auth event, audit-first telemetry, or an OpenTelemetry-first semantic-convention clone.
- **D-03:** Locked event families:
  - `[:crosswake, :auth, :session, :evaluate, :start]`
  - `[:crosswake, :auth, :session, :evaluate, :stop]`
  - `[:crosswake, :auth, :session, :evaluate, :exception]`
  - `[:crosswake, :auth, :denial]`
  - `[:crosswake, :auth, :handoff, :issue]`
  - `[:crosswake, :auth, :handoff, :redeem]`
  - `[:crosswake, :auth, :handoff, :deny]`
  - `[:crosswake, :auth, :step_up, :issue]`
  - `[:crosswake, :auth, :step_up, :challenge]`
  - `[:crosswake, :auth, :step_up, :consume]`
  - `[:crosswake, :auth, :step_up, :deny]`
  - `[:crosswake, :auth, :return, :validate]`
  - `[:crosswake, :auth, :return, :consume]`
  - `[:crosswake, :auth, :return, :deny]`
- **D-04:** Telemetry metadata must remain low-cardinality and allowlisted: route id, flow, return kind, transport, outcome, denial code, shell reason, authority state, auth posture, assurance levels, freshness bucket, lifecycle state, binding result, link verification, validation posture, proof class, and safe correlation id.
- **D-05:** Telemetry must drop or reject secret/high-risk metadata: access tokens, refresh tokens, ID tokens, authorization codes, raw nonces, PKCE verifiers, credential IDs, provider payloads, raw `return_to`, session refs, subject/actor/org/device identifiers, email, IP, and user agent.
- **D-06:** Telemetry is diagnostic evidence only. It is not the audit source, lifecycle source, replay source, session authority source, or route authority source.
- **D-07:** Use `:telemetry.execute/3` for discrete lifecycle facts. Use `:telemetry.span/3` only around real duration boundaries such as session route evaluation or host-owned redemption/consume wrappers. Do not emit telemetry from pure constructors unless an action actually happened.
- **D-08:** OpenTelemetry mappings may be added later as adapters from the registry. Do not bake OTel-specific naming into the core Sigra contract in Phase 58.

### 2. Support Doctor Operator Truth - LOCKED
- **D-09:** Use a two-axis truth model everywhere:
  - Contract proof: full provider-neutral Sigra contract machinery is shipped and merge-blocking proven.
  - Host/provider/device readiness: host route readiness is verification-required; provider/device proof remains advisory until explicit promotion criteria pass.
- **D-10:** Support matrix truth should expose `contract_surface: :full_sigra_machinery`, `contract_proof_class: :merge_blocking`, `route_authority_source: :session_authority_lane`, `host_readiness: :verification_required`, and `provider_device_proof: :advisory`.
- **D-11:** Doctor findings should be actionable and safe: route predicates, fail-closed `:step_up_required`, backend-owned authority, shipped telemetry/security closeout, host verification needed, and advisory provider/device proof. They must not report provider/device setup success as a support claim.
- **D-12:** Operator inspection should preserve per-route auth truth instead of reducing auth to supported/unsupported. Include contract surface, proof class, host readiness, provider/device proof, evidence-authority map, telemetry registry, security closeout, denial codes, and safe detail keys.
- **D-13:** Guides should use consistent wording: Sigra's full provider-neutral session machinery is shipped for backend-owned route authority; host apps still own persistence, provider validation, Phoenix session renewal, CSRF rotation, LiveView invalidation, and route deployment verification; provider/device proof and provider/native UI surfaces remain advisory or deferred.
- **D-14:** Avoid provider/device overclaims. "Provider-neutral OAuth boundary" must not read as Google/Auth0/Okta support. "Verified HTTPS link contract" must not read as device link verification proven on iOS/Android. "Passkey return boundary" must not read as passkey SDK wrapper shipped. "Telemetry shipped" must not read as audit or authority source.

### 3. Proof Lane Posture - LOCKED
- **D-15:** Keep the Phase 58 proof posture layered: hermetic merge-blocking auth closeout proof plus advisory provider/device proof.
- **D-16:** The merge-blocking lane should cover deterministic Sigra contract truth, route gate behavior, replay/expiry/revocation, step-up returns, auth-return validation, denial sanitization, telemetry/docs/support/operator parity, and security closeout.
- **D-17:** The advisory lane should report provider/device OAuth, passkey, verified-link, native auth UI, refresh-token, and shell/WebView token-authority posture without promoting support claims.
- **D-18:** Advisory proof cannot become support truth by passing once. Promotion requires explicit scoped requirement/roadmap change, shipped provider/device implementation, sustained stability evidence, docs/support-matrix update, and branch-protection/workflow update.
- **D-19:** Reject one giant merge-blocking full suite that includes provider/device auth proof. It would create flaky OSS CI, require environment secrets/device setup, and make green CI look like provider/device support.
- **D-20:** Reject mostly manual closeout as the only proof posture. Manual security judgment is useful, but Phase 58 needs deterministic regression guards for telemetry, denial vocabulary, secret bans, route authority fences, docs parity, and non-claims.
- **D-21:** Planning should harden workflow parity if needed: the research found `test/crosswake/planning/closeout_ci_parity_test.exs` still appears Phase-52-oriented. That is an implementation caveat for Phase 58 proof wiring, not a change to the proof posture.

### 4. Security Closeout Model - LOCKED
- **D-22:** Treat `58-SECURITY.md` as a bounded adversarial STRIDE review plus remediation ledger, not just a checklist.
- **D-23:** Preserve the existing required section set because proof/verifier artifacts depend on it: token/locator handling, handoff tickets, step-up ceremony, auth-return boundaries, telemetry and diagnostics, denial sanitization, session renewal and LiveView invalidation, doctor/support/operator/docs truth, proof/non-claims, and findings disposition.
- **D-24:** Under each security surface, planning should prefer compact rows with: surface, STRIDE category, adversarial scenario, existing control, evidence/code refs, residual risk, and disposition.
- **D-25:** The security review must directly challenge whether any envelope, locator, deep link, bridge event, OAuth/passkey return, telemetry event, or provider payload can set `SessionAuthorityLane` directly. The answer must remain no.
- **D-26:** The security review must challenge replay/double-consume/expiry/revocation/route mismatch/session mismatch for handoff tickets, step-up intents, and auth-return attempts. Server-side host-owned records plus atomic consume/audit/projection remain the control.
- **D-27:** The security review must verify Phoenix session renewal, CSRF rotation/deletion posture, and LiveView invalidation stay host-owned and happen only after backend validation succeeds.
- **D-28:** The security review must verify Plug/controller and LiveView paths share auth semantics so one transport cannot bypass step-up.
- **D-29:** The security review must verify denial and telemetry sanitization excludes raw tokens, authorization codes, credential IDs, PKCE verifiers, nonces, session refs, actor/org/device IDs, IPs, user agents, provider payloads, emails, and raw `return_to`.
- **D-30:** Findings disposition should be severity-disciplined. High/critical unresolved findings block closeout. Medium residual provider/device uncertainty can remain mitigated/advisory when support truth explicitly does not claim provider/device proof.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-31:** Phoenix/Plug lesson: session mutation belongs at the host boundary after backend validation, using host-owned `configure_session(conn, renew: true)` and explicit CSRF/session handling.
- **D-32:** Ecto lesson: consume + audit + projection belongs in one transaction (`Ecto.Multi` or equivalent), not in check-then-update flows and not in telemetry handlers.
- **D-33:** LiveView lesson: HTTP and LiveView entry points need the same auth decision semantics with transport-specific redirect/halt mechanics.
- **D-34:** Telemetry/Phoenix lesson: event names and metadata become public observability API. Keep names stable, maps small, and high-cardinality/secret facts out.
- **D-35:** OWASP/OAuth/WebAuthn lesson: user-facing failures stay generic, operator details are typed and sanitized, and bearer/provider/passkey artifacts are not authority or metric labels.
- **D-36:** Hotwire Native/AppAuth/mobile lesson: external/native auth handoff and verified-link posture are useful evidence channels, but bridge/native/provider success must not become route or session authority.
- **D-37:** Crosswake prompt-corpus lesson: proof lanes, support matrices, doctor diagnostics, operator surfaces, telemetry, route policy, and security constraints are product surface. Keep them narrow, explicit, and docs-contractable.

### the agent's Discretion
- Exact wording in guides, doctor messages, and operator output is planner discretion if the two-axis truth model remains visible.
- Exact telemetry helper APIs are planner discretion if the registry, event names, metadata allowlist, forbidden metadata, and diagnostic-evidence-only posture remain locked.
- Exact security ledger row count is planner discretion. Keep it bounded and evidence-backed rather than sprawling or purely theoretical.
- Exact CI hardening for Phase 58 workflow parity is planner discretion, but avoid widening advisory provider/device proof into merge-blocking support truth.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` - Crosswake thesis, v3.8 milestone goal, constraints, key decisions, and non-goals.
- `.planning/REQUIREMENTS.md` - DIAG-02, DIAG-03, and PROOF-01 requirements plus v3.8 out-of-scope provider/native auth surfaces.
- `.planning/ROADMAP.md` - Phase 58 goal and success criteria.
- `.planning/STATE.md` - current workflow position and upstream Phase 57 completion state.
- `.planning/research/v3.8/SUMMARY.md` - milestone-level Sigra architecture and proof/diagnostics recommendation.
- `.planning/research/v3.8/DENIAL-TELEMETRY-DX.md` - dual-surface denial, telemetry, doctor/support truth, and docs-contract guidance.

### Prior Sigra decisions
- `.planning/phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-CONTEXT.md` - backend-owned `SessionAuthorityLane`, route gate semantics, denial sanitization, and deferred full machinery.
- `.planning/phases/55-session-handoff-tickets-and-authority-projection/55-CONTEXT.md` - handoff envelope/server-record pattern, atomic redemption, audit, and renewal boundary.
- `.planning/phases/56-step-up-intent-and-plug-liveview-ceremony/56-CONTEXT.md` - step-up intent, shared Plug/LiveView ceremony, return target, renewal, and CSRF posture.
- `.planning/phases/57-oauth-passkey-and-native-return-boundaries/57-CONTEXT.md` - route-local auth-return boundaries, evidence envelope, denial vocabulary, and provider/device non-claims.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - original Sigra contract-only route-auth posture.

### Phase 58 artifacts and proof
- `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md` - security closeout artifact to strengthen into bounded adversarial STRIDE plus remediation ledger.
- `.github/workflows/phase58-proof.yml` - Phase 58 hermetic merge-blocking and advisory provider/device proof lane split.
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` - proof anchors for telemetry, support truth, doctor/operator inspection, guides, security closeout, and secret bans.
- `test/crosswake/companions/sigra/telemetry_test.exs` - telemetry registry, sanitizer, and serialization proof.
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs` - route authority proof baseline.
- `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` - handoff lifecycle/replay/revocation proof baseline.
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs` - step-up ceremony proof baseline.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` - auth-return boundary proof baseline.
- `lib/crosswake/planning/closeout_verifier.ex` - closeout verifier and security artifact validation.
- `test/mix/tasks/closeout_verify_test.exs` - closeout task behavior and security artifact proof.
- `test/crosswake/planning/closeout_ci_parity_test.exs` - CI parity hardening target; verify Phase 58 wiring during planning.

### Existing Crosswake code
- `lib/crosswake/companions/sigra/telemetry.ex` - canonical Phase 58 telemetry registry and metadata sanitizer.
- `lib/crosswake/companions/sigra/denial_codes.ex` - canonical auth denial subcodes and safe detail allowlist.
- `lib/crosswake/companions/sigra/contracts.ex` - `SessionAuthorityLane`, `AuthContext`, and authority contracts.
- `lib/crosswake/companions/sigra/evaluator.ex` - route-auth evaluator and denial source for session evaluation.
- `lib/crosswake/companions/sigra/handoff.ex` - handoff ticket/envelope/renewal/audit contract analog.
- `lib/crosswake/companions/sigra/step_up.ex` and `lib/crosswake/companions/sigra/step_up_ceremony.ex` - step-up intent, ceremony, and lifecycle analogs.
- `lib/crosswake/companions/sigra/auth_return.ex` - OAuth/passkey/native auth-return evidence and attempt contracts.
- `lib/crosswake/compatibility/route_gate.ex` - canonical route activation pipeline and `:step_up_required` integration.
- `lib/crosswake/shell/denial.ex` - public shell denial vocabulary; preserve compact public reasons.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support truth including auth contract, telemetry, security closeout, host readiness, provider/device proof, and deferred surfaces.
- `lib/crosswake/support_matrix/renderer.ex` - rendered support matrix wording parity.
- `lib/crosswake/doctor/doctor.ex` and `lib/crosswake/doctor/publish_readiness.ex` - doctor/publish readiness truth surfaces.
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex` - per-route operator inspection truth and serialization.

### Example host and docs
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex` - host-owned Phoenix session renewal pattern.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex` - Ecto-backed handoff issue/redeem/revoke proof path.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex` - host-owned auth-return attempt record shape.
- `examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex` - auth-return audit record shape.
- `examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs` - handoff persistence proof.
- `examples/phoenix_host/priv/repo/migrations/20260602070000_create_sigra_step_up_intents.exs` - step-up persistence proof.
- `examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs` - auth-return attempt persistence proof.
- `guides/companions.md` - canonical companion/Sigra guide and public non-claims.
- `guides/support_matrix.md` - rendered support matrix wording and auth support row.
- `guides/native_shell.md` - shell/native support posture and direct shell/WebView authority non-claims.

### Prompt corpus and project guidance
- `prompts/crosswake-gsd-project-brief.md` - proof lanes, support matrix, operator surface, and Sigra companion positioning.
- `prompts/crosswake-elixir-oss-dna.md` - maintainer house style: deterministic proof, doctor diagnostics, support truth, and OSS DX.
- `prompts/crosswake-research-synthesis.md` - route policy/runtime boundary thesis, bridge constraints, and support proof guardrails.
- `prompts/crosswake-integrations-and-companions.md` - Sigra companion context and auth/session/mobile account boundaries.
- `prompts/crosswake-brand-book.md` - boundary-aware language, telemetry, typed contracts, and honest support-claim posture.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - mobile auth/security, bridge, telemetry, and provider/device footguns.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Phoenix-native route manifest, bridge security, telemetry, doctor, and DX lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - route-policy/bridge/security proof posture and ecosystem anti-patterns.

### External ecosystem references from v3.8 research
- `https://hexdocs.pm/telemetry/1.4.1/telemetry.html` - Elixir telemetry event/span model and stable instrumentation posture.
- `https://hexdocs.pm/phoenix/1.7.5/telemetry.html` - Phoenix telemetry conventions.
- `https://hexdocs.pm/plug/Plug.Conn.html` - `configure_session/2` and host-owned session mutation.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transaction composition for consume + audit + projection.
- `https://phoenix-live-view.hexdocs.pm/security-model.html` - shared HTTP/LiveView auth semantics.
- `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html` - generic auth failure responses and reauthentication posture.
- `https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html` - safe security logging posture.
- `https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html` - session renewal, timeout, and server-side lifecycle guidance.
- `https://www.rfc-editor.org/rfc/rfc8252` - OAuth native-app external-user-agent and redirect posture.
- `https://www.rfc-editor.org/rfc/rfc9700` - OAuth security BCP.
- `https://www.rfc-editor.org/rfc/rfc7636` - PKCE.
- `https://openid.net/specs/openid-connect-core-1_0-18.html` - OIDC nonce/auth-time/acr evidence.
- `https://www.w3.org/TR/webauthn-3/` - WebAuthn/passkey server validation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companions.Sigra.Telemetry` already exposes the likely Phase 58 registry: event names, metadata keys, forbidden keys, flows, return kinds, outcomes, freshness buckets, proof classes, sanitizer, `to_map/1`, and `execute/3`.
- `Crosswake.Companions.Sigra.DenialCodes` already centralizes `auth.step_up.*`, `auth.handoff.*`, `auth.step_up_intent.*`, and `auth.return.*` codes plus safe detail keys.
- `SupportMatrix.auth_contract_truth/0` already carries the desired two-axis truth: full Sigra contract surface, merge-blocking proof class, host readiness verification-required, provider/device advisory, telemetry registry, security closeout, evidence-authority map, and deferred surfaces.
- `OperatorInspection` already projects auth truth route-by-route for predicated routes.
- `phase58-proof.yml` already contains the recommended split between hermetic merge-blocking closeout proof and advisory provider/device proof.
- `58-SECURITY.md` already has the required section set, but should be strengthened from terse checklist to adversarial STRIDE ledger.

### Established Patterns
- Core Crosswake/Sigra contracts stay pure Elixir. Host/example apps own Ecto persistence, provider validation, Phoenix session renewal, CSRF rotation, LiveView invalidation, and redirects.
- Support claims are canonicalized through support matrix accessors and locked through rendered guides, doctor, operator inspection, fixtures, and proof tests.
- Public shell denial reasons stay compact; operator/developer detail uses stable low-cardinality subcodes and allowlisted details.
- Environment-sensitive provider/device proof stays advisory unless promotion criteria explicitly pass.
- Telemetry and diagnostics are product surface, but they are evidence only and cannot be route/session/audit authority.

### Integration Points
- Telemetry registry and docs parity: `lib/crosswake/companions/sigra/telemetry.ex`, `test/crosswake/companions/sigra/telemetry_test.exs`, `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs`.
- Support/doctor/operator truth: `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/support_matrix/renderer.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/operator_inspection.ex`, `guides/companions.md`, `guides/support_matrix.md`, and `guides/native_shell.md`.
- Security closeout: `.planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md`, `lib/crosswake/planning/closeout_verifier.ex`, `test/mix/tasks/closeout_verify_test.exs`.
- Proof lane: `.github/workflows/phase58-proof.yml` plus Phase 54-58 proof tests.

</code_context>

<specifics>
## Specific Ideas

### Coherent Phase 58 Public Wording

Use this shape consistently:

> Sigra's full provider-neutral session machinery is shipped for backend-owned route authority: `SessionAuthorityLane` evaluation, handoff ticket/server-record redemption, server-owned step-up intents with Plug/LiveView ceremony, route-local OAuth/passkey/native auth-return boundaries, stable `[:crosswake, :auth, ...]` telemetry, and Phase 58 security closeout. Host apps still own persistence, provider validation, Phoenix session renewal, CSRF rotation, LiveView invalidation, and route deployment verification. Provider/device proof, provider templates, passkey SDK wrappers, refresh-token helpers, direct shell/WebView token authority, and native auth UI remain advisory or deferred.

### Good Telemetry Example

```elixir
Crosswake.Companions.Sigra.Telemetry.execute(
  [:crosswake, :auth, :return, :deny],
  %{count: 1},
  %{
    route_id: "oauth-return",
    flow: :auth_return,
    return_kind: :oauth,
    transport: :verified_https_link,
    outcome: :deny,
    denial_code: "auth.return.oauth.state_mismatch",
    shell_reason: :step_up_required,
    validation_posture: :failed,
    proof_class: :hermetic,
    correlation_id: "support:ret.safe"
  }
)
```

### Bad Telemetry Example

```elixir
%{
  access_token: "...",
  authorization_code: "...",
  id_token: "...",
  session_ref: "sess_123",
  actor_id: "user_123",
  provider_payload: raw_provider_payload
}
```

### Security Ledger Row Shape

```text
Surface | STRIDE category | Adversarial scenario | Existing control | Evidence/code refs | Residual risk | Disposition
```

</specifics>

<deferred>
## Deferred Ideas

- Provider/device auth proof promotion remains deferred until explicit promotion criteria pass.
- Provider-specific OAuth templates, passkey SDK wrappers, native auth UI, and refresh-token helpers remain future milestone work.
- OpenTelemetry semantic-convention adapter can be considered later as a mapping from the stable Sigra telemetry registry.
- Richer provider/device capability matrices should wait until provider/device implementations exist.

</deferred>

---

*Phase: 58-auth-diagnostics-proof-and-security-closeout*
*Context gathered: 2026-06-02*
