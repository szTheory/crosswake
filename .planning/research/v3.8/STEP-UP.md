# v3.8 Research: Sigra Step-Up Challenge and Return Flow

**Project:** Crosswake  
**Milestone Target:** v3.8 Full Sigra Auth and Session Machinery  
**Date:** 2026-06-01  
**Mode:** Comparison + recommendation  
**Confidence:** MEDIUM-HIGH (HIGH for Phoenix/LiveView/Plug/OAuth/OIDC primitives; MEDIUM for ecosystem synthesis patterns)

## Current Crosswake Baseline (What Exists Now)

Crosswake already has the contract-only auth substrate:

- Route policy keys: `auth_min_level`, `requires_recent_auth` (positive seconds) in policy + manifest.
- Runtime gate semantics: auth predicates produce fail-closed `:step_up_required` denials.
- Denial payload discipline: optional refs are sanitized (`challenge_ref`, `step_up_token_ref`) and no raw secrets are emitted.
- Companion/support posture: Sigra remains explicitly contract-only (no full ceremony/handoff yet).

In-repo anchors:

- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/compatibility/route_gate.ex`
- `lib/crosswake/shell/denial.ex`
- `lib/crosswake/companions/sigra/contracts.ex`
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`
- `guides/companions.md`

## External Patterns That Should Drive v3.8

## 1) Phoenix + LiveView guard model

- LiveView auth must be enforced in `mount`/`on_mount` (not only Plug pipeline), and redirect on halt is the idiomatic shape.  
  Source: https://phoenix-live-view.hexdocs.pm/security-model.html
- `on_mount` redirects must halt.  
  Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html

Implication: step-up checks must exist in both Plug/controller entry and LiveView `on_mount`, using one shared evaluator.

## 2) Session and CSRF boundaries

- Plug exposes session renewal (`configure_session(conn, renew: true)`) for anti-fixation rotation moments.  
  Source: https://hexdocs.pm/plug/Plug.Conn.html
- CSRF protection is expected for mutation endpoints and can be reset/rotated (`delete_csrf_token`/`get_csrf_token`).  
  Source: https://hexdocs.pm/plug/Plug.CSRFProtection.html

Implication: successful challenge completion should rotate/renew session and CSRF material before returning to target.

## 3) Return-target discipline

- Devise’s canonical pattern is stored location then post-auth redirect (`stored_location_for` via `after_sign_in_path_for`).  
  Source: https://www.rubydoc.info/github/plataformatec/devise/Devise%2FControllers%2FHelpers%3Aafter_sign_in_path_for
- Django exposes explicit `next` semantics plus allowlisted host controls (`success_url_allowed_hosts`).  
  Source: https://docs.djangoproject.com/en/3.2/topics/auth/default/
- OWASP explicitly warns against unvalidated redirect targets.  
  Source: https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html

Implication: Crosswake should use signed, server-issued return intent references, not arbitrary user-provided URL redirects.

## 4) Step-up semantics and freshness from standards

- OIDC `max_age` + `auth_time` gives standard freshness semantics; `acr` expresses auth strength requirements.  
  Source: https://openid.net/specs/openid-connect-core-1_0-18.html
- OAuth native-app best current practice: external user-agent + exact redirect URI verification + PKCE for public native clients.  
  Sources: https://www.rfc-editor.org/rfc/rfc8252, https://www.rfc-editor.org/info/rfc7636/
- OAuth security BCP further reinforces PKCE posture.  
  Source: https://www.rfc-editor.org/rfc/rfc9700

Implication: Sigra step-up should model `required_level` + `max_age_seconds` as first-class, and passkey/OAuth return should be strict callback-contract driven.

## 5) Mobile deep-link return safety

- Android App Links verification and host ownership checks are now explicit and operationally testable.  
  Source: https://developer.android.com/training/app-links/verify-applinks?hl=en
- Apple Universal Links rely on associated domain approval and strict matching/debug paths.  
  Source: https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links?changes=_9_5&language=objc

Implication: native return-to-app is not “any deep link”; it must be verified-domain/app-link constrained.

## Viable v3.8 Design Approaches

## Approach A: Query-param return URL (`?return_to=`) through challenge routes

**Pros**
- Minimal implementation effort.

**Cons**
- Open-redirect risk, stale target replay risk, awkward LiveView parity.
- Encourages client-shaped authority over return destination.

**Verdict**
- Reject for Crosswake core.

## Approach B: Session-only stored return target

**Pros**
- Better than raw URL params; simple Phoenix controller implementation.

**Cons**
- Weak multi-tab/mobile handoff behavior.
- Harder to bridge native/OAuth/passkey callback boundaries deterministically.
- Replay/expiry semantics are opaque unless separately modeled.

**Verdict**
- Usable for simple web-only apps, but too weak as Crosswake’s v3.8 canonical model.

## Approach C (Recommended): Server-issued Step-Up Intent + Challenge State Machine + Signed Return Contract

**Pros**
- Matches Crosswake thesis: backend-owned authority, typed semantic contracts, fail-closed.
- Cleanly unifies Plug, LiveView, and native return paths.
- Strong replay protection, expiry, and denial observability.

**Cons**
- More upfront contract and proof complexity.

**Verdict**
- Best fit for v3.8.

## Recommended v3.8 Coherent Design

## 1) Route policy extensions

Keep current fields, add explicit optional challenge policy:

- `step_up: %{mode: :required, challenge_window_seconds: pos_integer(), return_mode: :phoenix | :native_link | :oidc_callback}`
- Keep `auth_min_level` and `requires_recent_auth` as the gate decision primitives.
- `step_up` config only shapes ceremony/return behavior after denial decision.

Non-goal: introducing provider-specific IdP policy keys in route DSL.

## 2) Return contract (server authority)

Introduce a typed server-side contract (Sigra namespace):

- `StepUpIntent`:
  - `intent_id` (opaque, signed reference)
  - `route_id`
  - `target_path` (internal, canonicalized)
  - `required_mfa_level`
  - `max_auth_age_seconds`
  - `issued_at`, `expires_at`
  - `nonce`
  - `source` (`:live_navigation | :external_entry | :native_open`)
  - `status` (`:pending | :challenged | :satisfied | :expired | :canceled`)

Rules:

- Never accept arbitrary absolute return URLs from client.
- Return target must resolve to known manifest route ID/path.
- Intent expires quickly (for example 5-10 minutes) and is one-time consumable.
- Challenge completion consumes intent and rotates session/CSRF before redirect.

## 3) Challenge state machine

State transitions:

`pending -> challenged -> satisfied -> consumed`  
`pending/challenged -> expired`  
`pending/challenged -> canceled`

Failure edges:

- Invalid/expired/consumed intent => deny with generic step-up failure + safe fallback route.
- Challenge success but freshness still fails (clock skew/stale lane) => deny and issue fresh challenge.

## 4) Denial vocabulary (extend, don’t leak)

Keep top-level reason as `:step_up_required` for compatibility.

Add stable subcodes in `details["step_up_code"]`:

- `missing_auth_context`
- `insufficient_mfa_level`
- `auth_too_old`
- `challenge_expired`
- `challenge_invalid`
- `challenge_canceled`
- `return_target_invalid`

Rules:

- End-user visible message remains generic.
- Detailed diagnostics stay in telemetry/doctor/operator inspection, not UI strings.

## 5) LiveView + Plug implementation pattern

- Plug pipeline: initial guard for controller routes; if denied, create `StepUpIntent`, redirect to challenge entry.
- LiveView: shared `on_mount` hook calls same evaluator and halts with redirect when required.
- Post-challenge return:
  - LiveView route target => `push_navigate`/redirect to canonical route path after intent consume.
  - Controller target => `redirect`.

## 6) Native/passkey/OAuth return boundaries

- For OAuth in native shells, follow RFC 8252 + PKCE; accept only registered callback URIs and exact-match callback metadata.
- For deep-link return in shell, require verified app links/universal links; never trust unverified custom schemes as sole authority.
- Sigra/host backend remains authority for marking challenge satisfied, not shell callback alone.

## 7) Great DX for Phoenix authors

## Authoring

- Route-level declaration remains small:
  - `auth_min_level: :mfa`
  - `requires_recent_auth: 600`
  - optional `step_up` override only when needed.

## Challenge integration

- Provide one generator or helper module for:
  - `Crosswake.Sigra.StepUp.on_mount/1`
  - `Crosswake.Sigra.StepUp.challenge_controller`
  - `Crosswake.Sigra.StepUp.consume_return/2`

## Denial handling

- Unified helper for mapping denial to:
  - Challenge redirect
  - Safe fallback route
  - Operator trace reference

## 8) Footguns to explicitly avoid

- Client-only authority over return destinations.
- Any `return_to` that accepts full arbitrary URLs.
- Stale intent reuse after success/failure.
- Leaking sensitive denial detail (provider/user/session internals) to user-facing messages.
- Silent fallback to unsafe routes on challenge errors.
- Treating native callback as equivalent to completed backend challenge.

## 9) Telemetry and operator truth

Add explicit events (names aligned with existing companion telemetry style):

- `[:crosswake, :sigra, :step_up, :intent_issued]`
- `[:crosswake, :sigra, :step_up, :challenge_started]`
- `[:crosswake, :sigra, :step_up, :challenge_satisfied]`
- `[:crosswake, :sigra, :step_up, :challenge_failed]`
- `[:crosswake, :sigra, :step_up, :intent_expired]`
- `[:crosswake, :sigra, :step_up, :return_completed]`

Metadata keys:

- `route_id`, `intent_id_ref` (sanitized/opaque), `step_up_code`, `required_level`, `auth_age_seconds`, `source`, `outcome`.

## 10) Proof strategy for v3.8

- Hermetic (merge-blocking):
  - Route gate + intent issuance/expiry/consume invariants.
  - LiveView `on_mount` halt/redirect behavior.
  - Session renew + CSRF rotation on challenge success path.
  - Open-redirect prevention (invalid host/path rejected).
  - Denial vocabulary stability + non-leaky messaging.
- Advisory:
  - Native deep-link callback integration checks (Android/iOS environment-specific).
  - IdP/provider handshake lanes.

## 11) Recommended scope boundaries and non-goals

v3.8 should **not** include:

- Generic identity-provider adapters for all vendors.
- Token storage guidance that encourages WebView localStorage/sessionStorage authority.
- High-frequency client-auth state streaming over bridge.
- “Magic” automatic fallback from denied secure route to a permissive route.

v3.8 should include:

- One coherent step-up intent/return contract.
- One canonical challenge flow pattern (Plug + LiveView).
- Strict denial/telemetry/operator truth.
- Explicit docs showing passkey/OAuth/native returns as bounded seams, not client authority.

## Summary Recommendation

Adopt **Approach C**: a backend-issued `StepUpIntent` contract with short-lived, one-time return intents; shared Plug + LiveView gating; strict return-target validation; preserved top-level `:step_up_required` denial with subcoded detail; and explicit telemetry/proof lanes.  

This is the only approach that is fully consistent with Crosswake’s Phoenix-first, fail-closed, backend-authoritative thesis while still supporting modern mobile passkey/OAuth return flows.

