# v3.8 Research: Passkey/OAuth Native-Return Boundaries and Adapter Seams

**Date:** 2026-06-01  
**Scope:** Crosswake v3.8 Sigra auth/session machinery  
**Question:** Guidance-only vs adapter seams vs first-party implementation

## Executive Recommendation

Ship **adapter seams with strict guidance and fail-closed defaults** in v3.8.  
Do **not** ship provider-specific first-party OAuth/passkey implementations in core v3.8.

Why:
- Crosswake already encodes Sigra as `contract_only` with explicit non-goals (`:passkey`, `:oauth`, `:handoff`, `:refresh_tokens`) and `:step_up_required` fallback; this is visible in policy, doctor, support matrix, and operator inspection.
- Native auth correctness is mostly about boundary discipline (redirect validation, PKCE/state/nonce correlation, external user-agent, link verification, backend token exchange), which maps cleanly to typed seam contracts and diagnostics.
- First-party provider templates would widen scope and violate current project posture (Phoenix-first, route-owned runtime, no provider-specific claims without proof lanes).

## Current Crosswake Baseline (What Exists)

- Route auth predicates exist now: `auth_min_level`, `requires_recent_auth` in route policy schema.
- Runtime route gate already fails closed with `:step_up_required` if auth context is missing/weak.
- Sigra contracts already model:
  - `AuthContext`
  - `SessionAuthorityLane`
  - `StepUpChallenge`
  - evidence lane that rejects authority keys.
- Docs/support/doctor truth explicitly says Sigra is contract-only and defers handoff/ceremony/passkey/oauth.

Key anchors:
- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/compatibility/route_gate.ex`
- `lib/crosswake/companions/sigra/contracts.ex`
- `lib/crosswake/operator_inspection.ex`
- `guides/companions.md`

## Ecosystem Ground Truth (Idiomatic Patterns)

### OAuth/OIDC Native Return

- Native apps should use **authorization code + PKCE** with **external user-agent**, not embedded webviews (RFC 8252 + RFC 7636 + OAuth Security BCP RFC 9700).
- Redirect return options are custom URI schemes and claimed HTTPS links (Universal Links / App Links), with strict redirect URI matching and correlation of state/session data.
- iOS idiom: `ASWebAuthenticationSession` for browser/session handoff.
- Android idiom: App Links domain verification + explicit troubleshooting/verification commands.
- AppAuth ecosystem encodes these patterns and is widely used as reference implementation for native clients.

### Passkeys / WebAuthn

- Passkeys are WebAuthn credentials; server must validate challenge/origin/RP-bound assertions (WebAuthn L3).
- For Crosswake, passkey ceremonies should remain backend-authoritative via Sigra contracts; native shells should only carry return artifacts/tickets, never become authority.

## Option Comparison

## 1) Guidance-Only

**What it means:** Docs only, no new runtime seam contracts.

Pros:
- Minimal v3.8 effort.
- No new API surface risk.

Cons:
- Too weak for Crosswake’s “proof + support truth” bar.
- Hard to encode denial/doctor/operator truth for broken return flows.
- Leaves app authors to invent unsafe return parsing and callback validation.

Verdict: **Insufficient** for v3.8 goals.

## 2) Adapter Seams (Recommended)

**What it means:** Add typed Sigra auth-return/session seams and diagnostics; host app plugs provider-specific implementations.

Pros:
- Preserves Crosswake thesis: typed, low-frequency boundaries; route-local ownership; backend authority.
- Enables safe defaults and deterministic hermetic tests without shipping provider SDKs.
- Matches prior successful pattern (v3.7 commerce adapters): evidence normalization + backend authority + advisory provider proof.

Cons:
- Requires careful seam design to avoid “leaky abstraction”.
- Some adopter teams still need provider-specific integration work.

Verdict: **Best fit for v3.8**.

## 3) First-Party Provider Implementations

**What it means:** Crosswake ships full OAuth/passkey integrations for specific IdPs.

Pros:
- Fast path for specific adopters.

Cons:
- Scope explosion and template lock-in.
- Hard to keep support truth honest across provider drift.
- Conflicts with current non-goals and route/runtime boundary posture.

Verdict: **Defer**.

## Recommended v3.8 Design (Concrete)

### A) Contract Shape

Keep contracts **semantic and low-frequency**:

- `Sigra.AuthReturnTicket` (new)
  - fields: `ticket_id`, `route_id`, `return_kind` (`:oauth_code | :oidc_frontchannel | :passkey_assertion`), `issued_at`, `expires_at`, `correlation_ref`
  - must not contain access/refresh tokens.
- `Sigra.NativeReturnEnvelope` (new)
  - fields: `activation_source` (`:deep_link | :notification | ...`), `return_uri`, `state_ref`, `nonce_ref`, `pkce_ref`, `received_at`
  - validation includes exact redirect match against declared return contract.
- `Sigra.SessionExchangeResult` (new)
  - backend result only: `authority_state`, `mfa_level`, `auth_age_seconds`, `session_id_ref`, `step_up_required?`, `reason`

### B) Route Declarations (Auth Return as Explicit Route Surface)

Add explicit auth-return declaration under route policy (not capability command):

- Example concept:
  - `auth_return: [provider: :oidc, entry: :external, callback_path: "/auth/return", require_pkce: true, require_state: true, require_nonce: true, allowed_origins: [...]]`
- Keep runtime ownership explicit:
  - return route can stay Phoenix-owned (`:live_view`) or native-screen orchestration, but authority promotion stays backend-only.

### C) Denial and Diagnostic Vocabulary

Keep `:step_up_required` as final user-facing gate reason for sensitive routes, but add machine-actionable internal reasons:

- `auth_return_state_mismatch`
- `auth_return_nonce_mismatch`
- `auth_return_pkce_missing_or_invalid`
- `auth_return_redirect_mismatch`
- `auth_return_link_unverified`
- `auth_return_expired_or_replayed`

Map these into doctor/operator inspection/support matrix, then collapse to safe UX denial posture.

### D) Native Shell Boundary Rules

- Shell handles activation/deep link ingestion only.
- No token parsing/storage in bridge payloads.
- No WebView-owned OAuth login.
- Return URI must map to declared route + declared return contract.
- iOS/Android link verification failures become explicit unavailable/denied surfaces.

### E) Proof Strategy

Merge-blocking hermetic:
- contract validation for return envelopes/tickets
- route gate failure/allow matrix
- replay/expiry/state mismatch handling
- docs-contract parity for support truth and non-goals

Advisory lanes:
- real iOS Universal Links + Android App Links verification/device checks
- provider-specific IdP callbacks (Auth0/Okta/etc.) as non-blocking until promotion rules are met

## What Ships in v3.8 vs Deferred

### Ship in v3.8

- Sigra auth-return/session seam contracts (typed)
- Route declaration for auth return boundary
- Denial/doctor/operator/support matrix extensions
- Hermetic proof suite for callback validation and fail-closed posture
- Guidance docs with explicit examples (AppAuth-style flow, PKCE/state/nonce discipline, deep link verification checklist)

### Defer

- First-party IdP templates (Auth0/Okta/etc.)
- First-party passkey SDK wrappers
- Token refresh orchestration SDKs
- Native auth UI frameworks beyond boundary/reference examples

## Crosswake-Specific Tradeoff Resolution

- **Low-frequency typed bridge:** preserved; auth returns are envelopes/tickets, not streaming state.
- **Route-local ownership:** preserved; each auth-sensitive route declares predicates and return boundary.
- **Backend authority:** preserved; only backend session exchange can move `SessionAuthorityLane` to `:active`.
- **No provider template lock-in:** preserved via adapter seams.
- **Support/doctor truth:** improved with explicit readiness classes and internal denial reasons.
- **Advisory vs merge-blocking proof:** follows established Crosswake pattern.

## Developer Ergonomics Requirements

- Minimal config defaults:
  - PKCE required
  - state required
  - nonce required for OIDC/passkey-attached flows
  - external user-agent required
- Explicit return contract per route group (not global magic).
- Clear warnings when using custom URI schemes without claimed HTTPS link verification.
- Copyable examples:
  - “Phoenix callback controller + Sigra ticket exchange”
  - “iOS/Android deep link verification checklist”
  - “step-up retry UX with `:step_up_required`”

## Non-Goals (v3.8)

- Crosswake becoming an IdP SDK layer
- Direct token authority in shell/bridge
- Generic high-frequency auth bridge
- Silent fallback when callback validation fails

## Confidence

**Overall: MEDIUM-HIGH**

- HIGH on standards and native-return security posture (RFCs, platform docs, AppAuth references).
- MEDIUM on Phoenix-specific library convergence details (ecosystem is fragmented between Ueberauth/Assent/custom implementations).

## Sources

Standards / primary:
- RFC 8252 (OAuth 2.0 for Native Apps): https://www.rfc-editor.org/rfc/rfc8252
- RFC 7636 (PKCE): https://www.rfc-editor.org/rfc/rfc7636
- RFC 9700 (OAuth 2.0 Security BCP): https://www.rfc-editor.org/rfc/rfc9700
- W3C WebAuthn Level 3: https://www.w3.org/TR/webauthn-3/

Platform / ecosystem:
- Apple `ASWebAuthenticationSession`: https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession
- Apple associated domains / universal links: https://developer.apple.com/documentation/xcode/supporting-associated-domains
- Android App Links verification: https://developer.android.com/training/app-links/verify-applinks
- AppAuth overview: https://appauth.io/
- AppAuth Android: https://github.com/openid/appauth-android
- AppAuth iOS: https://openid.github.io/AppAuth-iOS/

Provider guidance:
- Auth0 auth code + PKCE flow: https://auth0.com/docs/flows/guides/auth-code-pkce/call-api-auth-code-pkce
- Okta auth code + PKCE guide: https://developer.okta.com/docs/guides/implement-grant-type/authcodepkce/main/

Phoenix/Elixir ecosystem references:
- Ueberauth docs: https://hexdocs.pm/ueberauth/readme.html
- Assent OIDC strategy: https://assent.hexdocs.pm/Assent.Strategy.OIDC.html

Crosswake code/docs anchors:
- `/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex`
- `/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex`
- `/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex`
- `/Users/jon/projects/crosswake/lib/crosswake/operator_inspection.ex`
- `/Users/jon/projects/crosswake/guides/companions.md`
- `/Users/jon/projects/crosswake/guides/native_shell.md`
