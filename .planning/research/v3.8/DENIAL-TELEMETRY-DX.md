# v3.8 Sigra Auth/Session Research: Denial, Telemetry, Doctor/Support Truth, and DX Cohesion

**Project:** Crosswake  
**Scope date:** 2026-06-01  
**Confidence:** MEDIUM-HIGH (high for Elixir/Phoenix + security standards; medium for cross-ecosystem DX synthesis)

## Executive Recommendation

Adopt a **dual-surface denial posture** with one canonical vocabulary:
1. **Client/user surface:** minimal, generic, non-enumerating denial messages.
2. **Operator/developer surface:** rich structured reason codes, typed metadata, and correlation handles in telemetry/doctor/operator inspection.

For v3.8 Sigra, keep Crosswake’s existing fail-closed sequence (`kill_switch_active`/`gate_denied` before auth checks, then auth/session checks) and extend it into full session machinery with:
- a **canonical auth denial namespace** (`auth.*`) mapped to existing `Crosswake.Shell.Denial` reasons,
- **stable Telemetry event families** under `[:crosswake, :auth, ...]` using low-cardinality names and typed metadata,
- **doctor/support-matrix promotion rules** that distinguish contract truth vs advisory/provider/device truth,
- **docs-contract proof tests** that parity-lock guides, denial vocabulary, telemetry keys, and doctor findings,
- **example-host UX states** for step-up/handoff/passkey/OAuth return that never leak secrets but remain actionable.

## Current Crosswake Baseline (What v3.8 must preserve)

- Canonical denial envelope already exists in `Crosswake.Shell.Denial` with reasons including `:step_up_required`, `:gate_denied`, `:kill_switch_active`.
- Sigra today is contract-only (`AuthContext`, `SessionAuthorityLane`, `auth_min_level`, `requires_recent_auth`) with explicit deferred full machinery in docs/support truth.
- RouteGate already short-circuits gate/kill-switch before auth and sanitizes optional challenge refs.
- Doctor/support truth already uses stable finding codes and promotion-rule posture.

## External Evidence (Primary Sources)

- Elixir telemetry model (`attach`, `attach_many`, `execute`, `span`) and span convention support stable event naming and metadata contracts: https://hexdocs.pm/telemetry/1.4.1/telemetry.html
- Phoenix telemetry posture (endpoint/router lifecycle events) supports layered instrumentation: https://hexdocs.pm/phoenix/1.7.5/telemetry.html
- Plug error handling/status mapping (`Plug.ErrorHandler`, `Plug.Exception`) supports safe user output with internal diagnostics: https://hexdocs.pm/plug/Plug.ErrorHandler.html and https://hexdocs.pm/plug/1.4.5/Plug.Exception.html
- OWASP recommends generic auth failure responses and logging auth/authz/session failures: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html and https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- OAuth error vocab + bearer-denial semantics (`invalid_request`, `invalid_token`, `insufficient_scope`) and `WWW-Authenticate` guidance: https://datatracker.ietf.org/doc/html/rfc6749 and https://datatracker.ietf.org/doc/html/rfc6750
- OIDC auth error extensions (e.g., unmet auth requirements) and structured return semantics: https://openid.net/specs/openid-connect-unmet-authentication-requirements-1_0.html
- WebAuthn L3 current ceremony model for passkey flows: https://www.w3.org/TR/webauthn-3/
- OpenTelemetry semantic conventions reinforce stable event names + typed attributes: https://opentelemetry.io/docs/specs/semconv/general/events/

## Approach Comparison

## Approach A: User-detailed denials everywhere

**Example:** “Session expired 37m ago; MFA level password < required mfa; challenge ref abc123.”

**Pros**
- Fast local debugging.

**Cons**
- High leakage/enumeration risk.
- Contradicts OWASP generic-response guidance.
- Couples client copy to internals; brittle docs/support.

**Verdict:** Reject.

## Approach B: Opaque client denials + opaque internals

**Example:** always “Access denied”, minimal logs.

**Pros**
- Lowest leak risk.

**Cons**
- Poor operator support, weak incident triage, poor DX.
- Violates Crosswake “diagnostics as product surface.”

**Verdict:** Reject.

## Approach C (Recommended): Dual-surface, typed denial contract

**Example:**
- User sees: “Verification required to continue.”
- Operator/dev gets: `reason=:step_up_required`, `denial_code=auth.step_up_required`, `required_mfa_level=mfa`, `max_auth_age_seconds=600`, `correlation_id=...`.

**Pros**
- Aligns with OWASP + OAuth patterns.
- Matches Crosswake thesis: explicit boundaries, typed support truth.
- Strongest DX/security balance.

**Tradeoff**
- Slightly more implementation surface (taxonomy + docs-contract tests), but consistent with existing Crosswake playbook.

## Integrated v3.8 Design

## 1) Canonical Denial Vocabulary

Keep `Crosswake.Shell.Denial.reason` concise, add **Sigra session/auth codes** in `code` field (not exploding top-level reasons):

- `auth.step_up_required`
- `auth.session_missing`
- `auth.session_expired`
- `auth.session_suspended`
- `auth.freshness_required`
- `auth.handoff_required`
- `auth.handoff_invalid`
- `auth.oauth_return_invalid`
- `auth.passkey_assertion_failed`

Mapping posture:
- Top-level `reason` stays mostly `:step_up_required` for auth-denial UX consistency.
- `code` carries precise operator/dev classification.
- `details` remain allowlisted typed fields only (no raw token/credential/provider payloads).

## 2) Telemetry Contract (Idiomatic Elixir)

Event namespace:
- `[:crosswake, :auth, :session, :evaluate]`
- `[:crosswake, :auth, :session, :deny]`
- `[:crosswake, :auth, :step_up, :challenge_issued]`
- `[:crosswake, :auth, :step_up, :challenge_completed]`
- `[:crosswake, :auth, :handoff, :issued]`
- `[:crosswake, :auth, :handoff, :consumed]`
- `[:crosswake, :auth, :oauth_return, :accepted]`
- `[:crosswake, :auth, :oauth_return, :rejected]`
- `[:crosswake, :auth, :passkey, :assertion_verified]`
- `[:crosswake, :auth, :passkey, :assertion_denied]`

Metadata allowlist (low-cardinality first):
- `route_id`, `denial_reason`, `denial_code`, `authority_state`, `required_mfa_level`, `current_mfa_level`, `freshness_bucket`, `challenge_type`, `return_surface`, `companion_id`, `correlation_id`, `evaluated_at`

Do not emit:
- raw JWT/refresh/access tokens
- email/phone/PII claims
- passkey credential IDs or OAuth authorization codes

Pattern:
- Use `:telemetry.span/3` for evaluation/challenge flows.
- Emit explicit `...:deny` events for security triage.
- Keep event names stable and documented (OpenTelemetry-style event naming discipline).

## 3) Doctor + Support Matrix Truth

Add v3.8 doctor checks:
- `auth.session.handoff_contract`
- `auth.step_up.ceremony_contract`
- `auth.freshness.policy_contract`
- `auth.oauth_return.boundary_contract`
- `auth.passkey.boundary_contract`
- `auth.telemetry.schema_parity`
- `auth.denial.vocabulary_parity`

Support-matrix claim row:
- New claim id: `auth.sigra.full_session_machinery`
- Proof class split:
  - merge-blocking hermetic: denial taxonomy, telemetry schema, route-gate behavior, docs parity
  - advisory: provider/device specific passkey/OAuth return runtime proofs

Promotion rule should mirror commerce/provider pattern already used by Crosswake.

## 4) Docs-Contract Proof

Add merge-blocking tests asserting parity across:
- `Crosswake.Shell.Denial.reasons/0` + auth denial `code` vocabulary doc table
- telemetry event list + metadata keys in guide/operator docs
- doctor finding codes + support matrix claim IDs + guide anchors
- example-host denial/challenge copy fixtures

This follows Crosswake’s existing docs-contract lock style (companions/support matrix).

## 5) Example-Host UX and Operator Clarity

User-facing states:
- `step_up_required`: “Verification required to continue.”
- `session_expired`: “Session expired. Sign in again.”
- `handoff_required`: “Continue in secure sign-in.”
- `oauth_return_invalid`: “Sign-in couldn’t be completed. Try again.”

UI behavior:
- never show raw provider/protocol error strings
- always include support action path (“Try again” / “Go to sign in”)
- preserve safe route fallback (`stay_put` / explicit redirect)

Operator surface:
- show denial code, route, correlation_id, challenge lifecycle state, and replay-safe timestamp
- include “what user saw” copy key for support alignment

## Cohesion Rules for Session Handoff / Step-Up / Freshness / Passkey/OAuth

- **Backend authority only:** client/native signals remain evidence until backend validates and projects authority.
- **Single decision point:** RouteGate remains canonical enforcement path.
- **Challenge refs are handles, not secrets:** keep current sanitization model; extend allowlist, never log secret material.
- **Freshness is explicit policy:** bucketed freshness in telemetry, exact thresholds in policy/support docs.
- **Return surfaces are bounded:** passkey/OAuth returns must resolve into typed outcomes (`accepted`/`rejected` + denial code), never silent fallback.

## Non-Goals (v3.8)

- No identity-provider-specific templates in core.
- No token storage guidance that implies WebView localStorage authority.
- No high-frequency client authority channel over bridge.
- No fail-open behavior when telemetry/doctor hooks are missing.

## Concrete Next Implementation Slice (Suggested)

1. Add auth denial `code` taxonomy constants and allowlisted detail keys.
2. Add `[:crosswake, :auth, ...]` telemetry module with exported event/metadata registries.
3. Add doctor checks and support-matrix claim/promotion rows for full Sigra machinery.
4. Add docs-contract tests for denial/telemetry/doctor/support parity.
5. Add example-host safe denial/challenge screens and operator inspection fields.

## Confidence Notes

- **HIGH:** Telemetry/Phoenix/Plug idioms and security response posture (OWASP + RFC patterns).
- **MEDIUM:** Exact passkey/OAuth UX microcopy defaults (needs product-specific iteration during v3.8 implementation).
- **MEDIUM:** Advisory-lane promotion thresholds; Crosswake should calibrate with actual CI/device reliability data.
