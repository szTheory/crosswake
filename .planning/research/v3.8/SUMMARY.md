# v3.8 Research Summary: Full Sigra Auth and Session Machinery

**Date:** 2026-06-01
**Milestone:** v3.8 Full Sigra Auth and Session Machinery
**Inputs:** SESSION-HANDOFF.md, STEP-UP.md, AUTH-FRESHNESS.md, PASSKEY-OAUTH-RETURN.md, DENIAL-TELEMETRY-DX.md, `.planning/MILESTONE-ARC.md`, existing v3.5 Sigra contracts, and `prompts/` project guidance.

## Executive Recommendation

Build v3.8 around one coherent architecture:

> Backend-authoritative session projection, upgraded through short-lived one-time server-issued intents/tickets, enforced by route-local predicates, and surfaced through dual-layer safe denials plus rich operator diagnostics.

This keeps Crosswake Phoenix-first and route-policy-first. The native shell, OAuth callback, passkey ceremony, and mobile bridge may carry evidence or return envelopes, but they never become session authority. The backend validates, consumes, rotates, and projects authority into `SessionAuthorityLane`; `RouteGate` remains the canonical allow/deny point.

## Core Design Decisions

### 1. Session Handoff

Use a hybrid handoff contract:

- A signed short-lived envelope for transport integrity and typed claims.
- A DB-backed one-time ticket row for replay prevention, revocation, expiry, and auditability.
- Phoenix session renewal on successful redemption with `configure_session(conn, renew: true)`.
- `Ecto.Multi` or equivalent transaction around consume + authority-lane update.

Reject stateless-only handoff tokens for privileged transitions. They are easy to ship but weak on one-time replay, revocation, and operator support.

### 2. Step-Up Flow

Use a server-issued `StepUpIntent`, not raw `return_to` query params and not session-only stored redirects.

The intent should carry an opaque reference to:

- route id and canonical internal return target,
- required assurance level,
- max auth age,
- source (`:live_navigation`, `:external_entry`, `:native_open`),
- issued/expires timestamps,
- nonce/correlation reference,
- lifecycle status.

Challenge completion consumes the intent, rotates session/CSRF material, refreshes backend authority, and returns only to a manifest-known route target.

### 3. Auth Freshness and Expiry

Extend `SessionAuthorityLane` from the v3.5 contract-only shape into a fuller backend projection:

- `state`: `:active | :step_up_required | :expired | :revoked | :suspended`
- assurance level, auth methods, authenticated-at, last-seen-at
- idle expiry, absolute expiry, renewal horizon
- session id reference and session version/revocation vector
- remembered/non-fresh posture

Route policy should stay small:

- `auth_min_level`
- `requires_recent_auth`
- optional `session_max_idle`, `session_max_absolute`, `allow_remembered`

Remembered sessions must not satisfy sensitive recent-auth gates by default.

### 4. Passkey and OAuth Return

Ship adapter seams plus strict guidance, not provider-specific first-party implementations.

v3.8 should define typed boundaries:

- `AuthReturnTicket`
- `NativeReturnEnvelope`
- `SessionExchangeResult`
- explicit auth-return route policy metadata

Default posture:

- OAuth native flows use external user-agent, authorization code + PKCE, exact redirect matching, state, and nonce where applicable.
- Passkey/WebAuthn success is evidence until the backend validates and projects authority.
- iOS Universal Links and Android App Links verification are advisory/device proof surfaces unless hermetically simulated.

Do not ship Auth0/Okta/passkey SDK product templates in core v3.8.

### 5. Denials, Telemetry, Doctor, and DX

Use a dual-surface denial model:

- Client/user surface: generic, safe, non-enumerating copy.
- Developer/operator surface: typed denial codes, sanitized metadata, correlation handles, doctor/support truth.

Keep top-level `Crosswake.Shell.Denial.reason` compact, especially preserving `:step_up_required`. Put precise classification in `code`, for example:

- `auth.step_up_required`
- `auth.session_missing`
- `auth.session_expired`
- `auth.session_suspended`
- `auth.freshness_required`
- `auth.handoff_required`
- `auth.handoff_invalid`
- `auth.oauth_return_invalid`
- `auth.passkey_assertion_failed`

Add stable telemetry under `[:crosswake, :auth, ...]` with low-cardinality metadata. Never emit raw access tokens, refresh tokens, OAuth authorization codes, passkey credential IDs, emails, phone numbers, or provider payloads.

## Recommended v3.8 Scope

Ship:

- Full typed Sigra session authority contract expansion.
- Session handoff ticket issuance, redemption, revocation, expiry, replay detection, and authority-lane projection.
- Server-issued step-up intent and challenge return contract.
- Shared Plug/controller and LiveView/on_mount evaluation helpers that route through one evaluator.
- Auth freshness, idle expiry, absolute expiry, session version/revocation, and remembered-session semantics.
- Passkey/OAuth native-return adapter seams and route declarations, with hermetic validation and advisory provider/device proof posture.
- Denial code taxonomy, telemetry schema, doctor checks, support-matrix row, operator inspection fields, and docs-contract parity.
- Example-host safe step-up/handoff UX states and copy.

Defer:

- Identity-provider-specific templates.
- Full first-party passkey SDK wrappers.
- Refresh-token orchestration SDKs.
- Generic native auth UI framework.
- WebView localStorage/sessionStorage token authority.
- High-frequency bridge auth state streaming.
- Offline sensitive mutation under stale cached auth.

## Suggested Requirement Groups

### Session Authority

- Host apps can model backend-owned session authority with explicit state, assurance, expiry, freshness, remembered, and revocation/version fields.
- Route gates evaluate the backend-projected session lane fail-closed before allowing sensitive routes.

### Handoff Tickets

- Host apps can issue, redeem, revoke, expire, and audit single-use handoff tickets without exposing raw session secrets to the client or shell.
- Replay, binding mismatch, route mismatch, expiration, and revocation deny with stable auth codes.

### Step-Up Ceremony

- Host apps can create server-owned step-up intents for routes requiring stronger or fresher auth.
- Plug/controller and LiveView entry points share the same intent, challenge, consume, and return semantics.

### Auth Return Boundaries

- Host apps can declare OAuth/passkey/native return boundaries as typed route-local seams.
- Return envelopes validate state/nonce/PKCE/redirect/link posture before backend authority promotion.

### Diagnostics and Proof

- Doctor, support matrix, operator inspection, telemetry, guides, and docs-contract tests expose full Sigra machinery truth without overstating provider/device support.
- Hermetic proof covers contracts, route gates, replay/expiry/revocation, step-up return, denial sanitization, and docs parity; device/provider checks remain advisory until promotion rules pass.

## Implementation Order Recommendation

1. Extend Sigra contracts and validators around session authority/freshness.
2. Add denial code taxonomy and telemetry registry so later slices use stable vocabulary.
3. Implement handoff tickets and backend authority projection.
4. Implement step-up intents and shared Plug/LiveView flow.
5. Add auth-return adapter seams for OAuth/passkey/native callbacks.
6. Wire doctor/support/operator/docs-contract truth and example-host UX.
7. Run security review before milestone closeout.

## Key Footguns to Avoid

- Treating `prompt=login` as freshness without validating `auth_time` or backend projection.
- Using query-param return URLs or accepting arbitrary absolute URLs.
- Allowing remembered sessions to pass sensitive recent-auth gates.
- Letting native callbacks, WebViews, or provider SDK events directly set authority.
- Logging raw credentials, tokens, OAuth codes, passkey credential IDs, or PII.
- Silent fallback from denied sensitive routes to permissive routes.
- Claiming provider/device auth proof as merge-blocking before promotion criteria are satisfied.

## Sources

- Phoenix Token: https://hexdocs.pm/phoenix/Phoenix.Token.html
- Phoenix auth generator and sudo mode: https://phoenix.hexdocs.pm/mix_phx_gen_auth.html
- Phoenix LiveView security model: https://phoenix-live-view.hexdocs.pm/security-model.html
- Plug.Conn session lifecycle: https://hexdocs.pm/plug/Plug.Conn.html
- Plug.Session: https://hexdocs.pm/plug/Plug.Session.html
- Plug.CSRFProtection: https://hexdocs.pm/plug/Plug.CSRFProtection.html
- Ecto.Multi: https://hexdocs.pm/ecto/Ecto.Multi.html
- Telemetry: https://hexdocs.pm/telemetry/1.4.1/telemetry.html
- OWASP Session Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OWASP Unvalidated Redirects and Forwards Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html
- OIDC Core: https://openid.net/specs/openid-connect-core-1_0-18.html
- OAuth 2.0 for Native Apps (RFC 8252): https://www.rfc-editor.org/rfc/rfc8252
- PKCE (RFC 7636): https://www.rfc-editor.org/rfc/rfc7636
- OAuth 2.0 Security BCP (RFC 9700): https://www.rfc-editor.org/rfc/rfc9700
- WebAuthn Level 3: https://www.w3.org/TR/webauthn-3/
- Apple ASWebAuthenticationSession: https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession
- Apple associated domains: https://developer.apple.com/documentation/xcode/supporting-associated-domains
- Android App Links verification: https://developer.android.com/training/app-links/verify-applinks
- AppAuth: https://appauth.io/
