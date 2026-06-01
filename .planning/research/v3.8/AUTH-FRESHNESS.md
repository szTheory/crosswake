# v3.8 Sigra Auth Freshness, Session Expiry, and Route-Gate Semantics

Date: 2026-06-01  
Scope: Crosswake v3.8 Full Sigra Auth and Session Machinery  
Confidence: MEDIUM-HIGH (high on Phoenix/Plug/OIDC/session-security primitives, medium on cross-ecosystem posture synthesis)

## 1) Baseline: what Crosswake already ships

Current v3.5/v3.6 Sigra posture is intentionally contract-only:
- Typed backend-owned `AuthContext`, `SessionAuthorityLane`, and `StepUpChallenge` exist.
- Route predicates exist: `auth_min_level`, `requires_recent_auth`.
- Runtime gate denies fail-closed with `:step_up_required`.
- Doctor/support matrix explicitly say handoff/ceremony/passkey/OAuth/refresh-token are deferred.

Local references:
- `lib/crosswake/companions/sigra/contracts.ex`
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/publish_readiness.ex`
- `guides/companions.md`
- `guides/support_matrix.md`

This is the correct launch point for v3.8: keep backend authority, widen machinery.

## 2) External primitives we should align with

## Phoenix/Plug idioms
- Phoenix auth generators now include “sudo mode” (`require_sudo_mode`) for sensitive routes, i.e., recent-auth gating is first-class in Phoenix-auth ergonomics.  
  Source: https://phoenix.hexdocs.pm/mix_phx_gen_auth.html
- Plug session lifecycle supports:
  - `configure_session(conn, renew: true)` (session ID rotation)
  - `configure_session(conn, drop: true)` (hard drop)
  - session cookie security attributes through `Plug.Session` options.
  Sources:
  - https://plug.hexdocs.pm/Plug.Conn.html
  - https://plug.hexdocs.pm/Plug.Session.html
- Plug cookie store is encrypted/signed, but still cookie-bound unless app chooses server-side session storage.  
  Source: https://hexdocs.pm/plug/Plug.Session.COOKIE.html
- Phoenix tokens support `max_age` verification and fail as `:expired`, useful for bounded handoff tickets.  
  Source: https://phoenix.hexdocs.pm/Phoenix.Token.html

## OIDC/step-up/freshness idioms
- OIDC `max_age` requires `auth_time` in ID token when used.
- OIDC `acr`/`amr` represent assurance context and methods.
- `prompt=login` alone is weaker as proof of freshness; relying party should validate `auth_time`.
  Sources:
  - https://openid.net/specs/openid-connect-core-1_0-18.html
  - https://auth0.com/docs/authenticate/login/max-age-reauthentication

## Session security baseline
- OWASP strongly recommends idle timeout + absolute timeout + renewal/rotation timeout, enforced server-side.  
  Source: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Comparable ecosystem expression patterns
- Django exposes per-session expiry control (`set_expiry`), and expiration is based on modification time (easy footgun if people assume reads refresh).  
  Source: https://docs.djangoproject.com/en/4.2/topics/http/sessions/
- Spring Security separates remember-me vs fully authenticated trust levels (excellent model for route gates).  
  Source: https://docs.spring.io/spring-security/reference/servlet/authentication/rememberme.html
- Laravel has “password confirmation” timeout middleware for sensitive actions (same conceptual class as recent-auth gates).  
  Source: https://laravel.com/docs/10.x/authentication

## 3) Viable approaches for v3.8

## Approach A: Stateless token-only freshness (JWT claims only)

How:
- Route gates use only claims (`auth_time`, `acr`, `exp`) from bearer/session token.
- No backend session projection read at gate time.

Pros:
- Lower DB pressure, simple horizontal scaling.

Cons / footguns:
- Harder immediate revocation across devices.
- Harder “log out all sessions” semantics.
- Token replay windows become policy-critical.
- Conflicts with Crosswake’s backend-authority thesis.

Verdict:
- Reject for Crosswake core semantics.

## Approach B: Fully stateful server sessions only

How:
- Session id maps to backend row; gate always reads backend state.
- Freshness/assurance/expiry all computed server-side from row.

Pros:
- Strong revocation posture.
- Coherent multi-device and support/doctor diagnostics.

Cons:
- Requires careful mobile handoff and potentially sticky integration effort.
- Higher operational coupling (store availability impacts auth gates).

Verdict:
- Strong fit, but should allow bounded signed tickets for handoff choreography.

## Approach C (recommended): Hybrid backend-authority projection + bounded signed handoff tickets

How:
- Authoritative gate decision is always from backend `SessionAuthorityLane` projection.
- Signed tickets (`Phoenix.Token`/equivalent) are transport envelopes only, short-lived, one-time/nonce-bound when needed.
- Claims from IdP/provider are evidence; backend projection promotes to authority.

Pros:
- Preserves Crosswake “evidence vs authority” doctrine.
- Supports explicit revocation/session versioning.
- Works with passkey/OAuth return flows without client authority drift.
- Gives route DSL a stable semantic surface.

Cons:
- More moving parts than pure stateless.
- Needs strict diagnostics and proof lanes.

Verdict:
- Best alignment with Crosswake architecture and milestone goals.

## 4) Recommended coherent v3.8 design

## 4.1 Typed state model (authoritative projection)

Keep existing structs and extend (names illustrative, maintain current naming discipline):

`SessionAuthorityLane` authoritative fields:
- `session_id :: binary`
- `subject_id :: binary` (actor)
- `org_id :: binary`
- `assurance_level :: :none | :password | :mfa | :phishing_resistant`
- `authn_methods :: [atom()]` (amr-like, optional but useful)
- `authenticated_at :: DateTime`
- `last_seen_at :: DateTime`
- `idle_expires_at :: DateTime`
- `absolute_expires_at :: DateTime`
- `renew_after :: DateTime | nil` (rotation horizon)
- `session_version :: non_neg_integer` (global revocation vector)
- `state :: :active | :step_up_required | :expired | :revoked | :suspended`
- `remembered :: boolean` (remember-me/non-fresh posture)
- `reauth_required_reasons :: [atom()]`
- `as_of :: DateTime`

`AuthContext` route-evaluation view:
- `mfa_level` -> rename/alias to `assurance_level` for consistency.
- `auth_age_seconds` derived from `authenticated_at` and trusted `as_of`.
- include `session_version`, `state`, and explicit expiry timestamps.

## 4.2 Route predicate semantics

Route policy DSL should support:
- `auth_min_level: :mfa | :phishing_resistant | ...`
- `requires_recent_auth: seconds`
- `session_max_idle: seconds | :default`
- `session_max_absolute: seconds | :default`
- `allow_remembered: boolean` (default false for sensitive routes)

Evaluation order (keep fail-closed precedence discipline):
1. kill switch / gate conditions
2. route existence + compatibility
3. auth/session gate:
   - missing authority lane -> deny
   - `state != :active` -> deny
   - expiry reached (idle/absolute) -> deny
   - `session_version` mismatch/revoked -> deny
   - assurance below `auth_min_level` -> deny
   - auth_age beyond `requires_recent_auth` -> deny
4. proceed

## 4.3 Denial vocabulary

Preserve `:step_up_required` for assurance/freshness failures, but add typed details and sibling reasons:
- `:session_missing`
- `:session_expired_idle`
- `:session_expired_absolute`
- `:session_revoked`
- `:session_suspended`
- `:session_version_mismatch`
- `:step_up_required`
- `:reauth_required`

Security posture:
- shell/client denial details stay minimal (no sensitive internals).
- operator/doctor surfaces get richer detail via trusted channels.

## 4.4 Expiration model (recommended defaults)

Use three clocks:
- Idle timeout (activity-bound): default 30m.
- Absolute timeout (hard cap): default 12h (or org policy).
- Renewal timeout (session-id/token rotation): default 30-60m.

Sensitive routes layer:
- `requires_recent_auth` default nil globally.
- For high-risk routes, set 5-15m.

Remember-me:
- Never satisfies `requires_recent_auth` by itself.
- Can satisfy low-assurance non-sensitive routes when explicitly allowed.
- Any step-up success should rotate session (`renew: true`) and refresh recency markers.

## 4.5 DB vs token state posture

Authoritative truth:
- DB/session store projection.

Token truth:
- bounded envelope for transport/handoff only (`max_age`, nonce, audience/purpose scoping).

Rules:
- Token validity is necessary, never sufficient.
- Backend projection check is mandatory for route gate allow.
- Revocation/session-version checks are server-side.

## 4.6 Security + UX tradeoffs

Fail-closed vs graceful challenge:
- Gate evaluation fails closed.
- UX can gracefully redirect to step-up flow with opaque challenge refs.

Clock skew:
- apply small skew tolerance (e.g. 60-120s) when comparing times.
- record `evaluated_at` in denial/operator details.

Offline/cached routes:
- Never promote stale cached auth context to authority.
- Offline cached route may render read-only shell, but any sensitive mutation/entry requiring fresh auth must deny and challenge online.

Mobile shell re-entry:
- App foreground/resume should trigger lightweight authority refresh before opening sensitive gated routes.

Multi-tab/multi-device:
- session_version and per-session revocation required.
- “logout all devices” increments global user session version and revokes active rows.

## 4.7 Developer ergonomics: DSL, diagnostics, support matrix, tests/docs

DSL ergonomics:
- Keep route declarations declarative and small.
- Prefer explicit knobs over hidden policy inference.

Doctor/support matrix:
- Add auth/session readiness claims similar to existing promotion-rule style:
  - contract shipped vs machinery shipped
  - proof class (merge-blocking vs advisory)
  - rebuild requirements (companion/native)
- Add explicit non-claims until each sub-surface ships (e.g., provider-specific passkey UX).

Diagnostics output:
- stable check ids for each denial class and policy posture.
- include route ids, required vs observed levels, freshness threshold, evaluation timestamp.

Testing/proof strategy:
- Merge-blocking hermetic:
  - auth freshness comparisons
  - idle/absolute expiry behavior
  - session version revocation
  - denial reason/details sanitization
  - evaluation order short-circuit invariants
- Advisory lanes:
  - provider/device passkey flows
  - OAuth return choreography

Docs:
- Distinguish “reauth freshness” from “session still valid”.
- Distinguish remember-me from fully authenticated.
- Document exact denial reasons and fallback UX contract.

## 5) Common footguns and mitigations

- Footgun: `prompt=login` treated as proof of freshness.
  - Mitigation: require `auth_time`/backend projection check; use `max_age`.
- Footgun: relying only on cookie expiry.
  - Mitigation: server-side idle/absolute enforcement and revocation.
- Footgun: remember-me accidentally grants sensitive route access.
  - Mitigation: explicit `allow_remembered` default false on sensitive routes.
- Footgun: stale snapshot allowed offline for sensitive actions.
  - Mitigation: sensitive routes deny when authority not freshly online-verified.
- Footgun: session fixation around privilege changes.
  - Mitigation: `configure_session(conn, renew: true)` at login and step-up transitions.

## 6) Recommended non-goals for v3.8

- No universal IdP abstraction that hides assurance semantics.
- No client-authoritative auth freshness decisions.
- No high-frequency bridge auth state stream.
- No broad claim that offline mode supports sensitive auth-gated mutation.
- No passkey/OAuth provider UX guarantees beyond explicitly proven lanes.

## 7) Suggested implementation shape (incremental)

1. Extend Sigra contracts with explicit expiry/version/assurance fields and validators.  
2. Implement gate evaluator with deterministic ordering + typed denials.  
3. Add session rotation/revocation hooks (`renew`/drop + backend versioning).  
4. Add doctor/support-matrix rows and non-claims updates.  
5. Add hermetic proof suite, then advisory provider/mobile lanes.  
6. Publish companion/auth guide with parity tests against live truth surfaces.

## Sources

- Phoenix `mix phx.gen.auth` (sudo mode, auth scaffolding): https://phoenix.hexdocs.pm/mix_phx_gen_auth.html
- Plug session and cookie controls:
  - https://plug.hexdocs.pm/Plug.Conn.html
  - https://plug.hexdocs.pm/Plug.Session.html
  - https://hexdocs.pm/plug/Plug.Session.COOKIE.html
- Phoenix token max-age verification: https://phoenix.hexdocs.pm/Phoenix.Token.html
- OIDC core (`max_age`, `auth_time`, `acr`, `amr`): https://openid.net/specs/openid-connect-core-1_0-18.html
- Auth0 reauth guidance (`prompt=login` caveat, validate `auth_time`): https://auth0.com/docs/authenticate/login/max-age-reauthentication
- OWASP session timeout guidance: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- Django session expiry semantics: https://docs.djangoproject.com/en/4.2/topics/http/sessions/
- Spring Security remember-me vs fully-authenticated posture: https://docs.spring.io/spring-security/reference/servlet/authentication/rememberme.html
- Laravel password-confirm timeout middleware: https://laravel.com/docs/10.x/authentication
