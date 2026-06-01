# v3.8 Research: Session Handoff Ticket Contract (Sigra)

**Date:** 2026-06-01  
**Scope:** Crosswake v3.8 Full Sigra Auth and Session Machinery  
**Confidence:** HIGH (Phoenix/Plug/Ecto primitives), MEDIUM (cross-ecosystem patterns)

## Executive recommendation

Use a **hybrid handoff contract**:

1. **Signed short-lived handoff envelope** (Phoenix/Plug crypto) for transport integrity and typed claims.
2. **DB-backed one-time ticket row** as the replay/authority source of truth.
3. **Phoenix session rotation on redemption** (`configure_session(conn, renew: true)`) and explicit session-token binding.

This gives least-surprise Phoenix ergonomics, one-time replay safety, auditability, and a clean fail-closed route-gate story that matches Crosswake’s backend-authority thesis.

## Why this fits Crosswake

- Keeps **backend authority explicit**: bridge/mobile signals never become authority; only backend redemption mints/updates session authority.
- Preserves **route-local ownership**: routes keep using `auth_min_level`/`requires_recent_auth`; ticket redemption just upgrades backend auth context.
- Maintains **typed low-frequency bridge**: handoff is a bounded event (`issue` -> `redeem`), not streaming auth state.
- Supports **doctor/support truth**: ticket modes, TTL, replay posture, and deferred surfaces can be surfaced as explicit diagnostics.

## Candidate approaches

### A) Stateless signed token only (no DB row)

Example: `Phoenix.Token.sign(...)`/`verify(max_age: ...)` with claims only.  
Pros: simple, no DB IO.  
Cons: weak one-time replay guarantees unless you add extra state anyway; poor audit trail.  
Verdict: good for low-risk links, not ideal for v3.8 security posture.  
Refs: Phoenix.Token docs ([hexdocs](https://hexdocs.pm/phoenix/Phoenix.Token.html)).

### B) Encrypted token only (no DB row)

Example: `Plug.Crypto.MessageEncryptor` to hide claims and verify authenticity.  
Pros: confidentiality + integrity in one blob.  
Cons: still stateless replay weakness; revocation/audit hard.  
Verdict: better secrecy, but still insufficient for one-time session handoff authority.  
Refs: Plug.Crypto encryptor/verifier ([encryptor](https://hexdocs.pm/plug_crypto/Plug.Crypto.MessageEncryptor.html), [verifier](https://hexdocs.pm/plug_crypto/Plug.Crypto.MessageVerifier.html), [high-level Plug.Crypto](https://hexdocs.pm/plug_crypto/Plug.Crypto.html)).

### C) DB one-time ticket only (opaque random ID)

Example: random `ticket_id` persisted; client submits opaque ID once.  
Pros: strongest replay control + revocation + audit.  
Cons: no self-describing claims at edge; slightly more plumbing.  
Verdict: strong baseline; can be improved with signed envelope for typed transport assertions.

### D) **Hybrid recommended**: signed envelope + DB one-time ticket

Pros: combines tamper-evident typed envelope with server-authoritative one-time semantics and auditability.  
Cons: more moving parts than pure stateless.  
Verdict: best tradeoff for Crosswake v3.8.

## Recommended contract (exact shape)

### 1) Ticket issuance contract (backend only)

`Sigra.SessionHandoff.issue_ticket/1` input:

- `actor_id`, `org_id`
- `required_mfa_level`
- `max_auth_age_seconds`
- `intent` (`:session_bootstrap | :step_up_return | :oauth_return | :passkey_return`)
- `return_to_route_id` (Crosswake route id, not arbitrary URL)
- `client_binding` (optional typed hints: `device_nonce`, `pkce_binding`, `native_session_ref`)
- `expires_in_seconds` (default 120; hard max 300)

Output:

- `ticket`: signed envelope string
- `ticket_id`: opaque stable id (for logs/doctor only; not needed by client if embedded)
- `expires_at`

### 2) Signed envelope claims

Use `Phoenix.Token` or `Plug.Crypto.sign/encrypt` with dedicated salt/secret namespace.  
Claims (minimal):

- `v` contract version (`"1"`)
- `tid` ticket id
- `iat` issued-at
- `exp` expiry
- `intent`
- `rid` return route id
- `cbh` optional client-binding hash

Do not include PII/session secrets in clear signed blobs. If sensitive metadata is needed, store in DB row and only expose references.

### 3) DB ticket row (authoritative)

`sigra_session_handoff_tickets`:

- `id` (opaque random, unique)
- `actor_id`, `org_id`
- `intent`
- `required_mfa_level`
- `max_auth_age_seconds`
- `return_to_route_id`
- `client_binding_hash` (nullable)
- `issued_at`, `expires_at`
- `redeemed_at` (nullable)
- `redeemed_by_session_id` (nullable)
- `revoked_at` (nullable)
- `revoke_reason` (nullable)
- `audit_meta` (jsonb, bounded)

Indexes:

- unique on `id`
- partial unique on `id where redeemed_at is not null` (or enforce with atomic update condition)
- index on `expires_at` for cleanup

### 4) Redemption lifecycle

`Sigra.SessionHandoff.redeem_ticket/2`:

1. Verify envelope signature and TTL.
2. Load ticket row by `tid`.
3. Atomically mark redeemed (`redeemed_at`) only if:
   - not expired
   - not revoked
   - not already redeemed
   - optional client binding matches
4. Rotate Phoenix session id (`configure_session(conn, renew: true)`).
5. Mint/refresh server-side session authority lane and auth context.
6. Return sanitized success payload: upgraded auth lane + allowed return route id.

Use `Ecto.Multi` / transaction for atomic consume+session-authority write.  
Refs: Ecto.Multi ([hexdocs](https://hexdocs.pm/ecto/Ecto.Multi.html)); Plug session renew/drop ([Plug.Conn](https://hexdocs.pm/plug/Plug.Conn.html)); Phoenix guidance on renewal and fixation mitigation ([Phoenix contexts guide excerpt](https://hexdocs.pm/phoenix/1.4.3/contexts.html)).

## Denial vocabulary (v3.8 additions)

Keep fail-closed and user-safe:

- `:step_up_required` (existing, preserved)
- `:handoff_ticket_missing`
- `:handoff_ticket_invalid`
- `:handoff_ticket_expired`
- `:handoff_ticket_replayed`
- `:handoff_ticket_revoked`
- `:handoff_ticket_binding_mismatch`
- `:handoff_intent_mismatch`
- `:handoff_route_not_allowed`

User-facing copy should stay minimal (“Session handoff expired. Please retry.”) while logs capture typed reason codes.

## Replay protection strategy

- One-time DB consume is mandatory.
- TTL short by default (120s).
- Optional tiny overlap window only for network race retries, but only for last pending state and with strict idempotency key semantics.
- Log replay attempts as security events.
- Rotate post-redeem session id to reduce fixation risk.

Security alignment refs: OWASP session management/fixation guidance ([Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html), [Session Fixation](https://owasp.org/www-community/attacks/Session_fixation)).

## Integration with Phoenix session + Sigra contracts

- `AuthContext` and `SessionAuthorityLane` remain canonical runtime inputs for Crosswake route gates.
- Handoff redemption writes a stronger/fresher `SessionAuthorityLane`; route gate continues to evaluate `auth_min_level` and `requires_recent_auth`.
- `challenge_ref`/`step_up_token_ref` pattern from phase 46 remains sanitized reference-only output; never expose bearer artifacts in denial details.

## OAuth/passkey return boundaries

- Treat OAuth/passkey completion as **evidence until redeemed through backend ticket**.
- Use PKCE/state discipline in external-browser flows; never rely on raw WebView local token storage as authority.
- Handoff ticket should be the boundary object that converts provider callback success into backend session authority.

Refs: RFC 7636 PKCE ([IETF](https://datatracker.ietf.org/doc/html/rfc7636)); OAuth threat/state guidance ([RFC 6819](https://datatracker.ietf.org/doc/html/rfc6819)).

## Developer ergonomics

- Public API:
  - `issue_ticket/1`
  - `redeem_ticket/2`
  - `revoke_ticket/2`
  - `ticket_status/1` (operator/debug safe)
- Keep option defaults secure and boring:
  - `expires_in_seconds: 120`
  - `single_use: true` (non-configurable in v3.8)
  - `max_ticket_lifetime_seconds: 300` hard cap
- Typed errors return stable atoms + metadata map for doctor/support surfaces.

## Proof strategy for v3.8

Merge-blocking hermetic tests:

1. Valid issue->redeem success upgrades authority lane.
2. Expired ticket denied.
3. Replayed ticket denied on second redeem.
4. Revoked ticket denied.
5. Binding mismatch denied.
6. Route mismatch denied.
7. Session id renewal asserted on successful redeem.
8. Fail-closed behavior when Sigra machinery disabled/misconfigured.

Advisory (non-blocking) lanes:

- External browser return simulations (OAuth/passkey providers) if environment-sensitive.

## Footguns to avoid

- Stateless-only handoff tokens for privileged transitions.
- Long TTL handoff artifacts.
- Including raw tokens/PII in ticket payloads or denial details.
- Letting native shell/provider callback directly set auth authority without redemption.
- Weak/implicit denial reasons that break support/doctor truth.

## Non-goals (v3.8 boundary)

- Full identity-provider template zoo.
- Generic mobile auth UI framework.
- High-frequency auth bridge streaming.
- Device-local authority over session/auth freshness.

## Sources

- Phoenix.Token docs: https://hexdocs.pm/phoenix/Phoenix.Token.html  
- mix phx.gen.auth docs: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.Auth.html  
- Plug.Conn session renew/drop: https://hexdocs.pm/plug/Plug.Conn.html  
- Plug.Session docs: https://hexdocs.pm/plug/Plug.Session.html  
- Plug.Crypto verifier/encryptor: https://hexdocs.pm/plug_crypto/Plug.Crypto.MessageVerifier.html , https://hexdocs.pm/plug_crypto/Plug.Crypto.MessageEncryptor.html , https://hexdocs.pm/plug_crypto/Plug.Crypto.html  
- Ecto.Multi docs: https://hexdocs.pm/ecto/Ecto.Multi.html  
- Phoenix context auth/session fixation example: https://hexdocs.pm/phoenix/1.4.3/contexts.html  
- OWASP Session Management Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html  
- OWASP Session Fixation: https://owasp.org/www-community/attacks/Session_fixation  
- RFC 7636 (PKCE): https://datatracker.ietf.org/doc/html/rfc7636  
- RFC 6819 (OAuth threat model/state): https://datatracker.ietf.org/doc/html/rfc6819  
