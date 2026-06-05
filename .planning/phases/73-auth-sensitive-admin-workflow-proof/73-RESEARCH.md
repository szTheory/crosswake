# Phase 73: Auth-Sensitive Admin Workflow Proof - Research

**Researched:** 2026-06-05
**Domain:** Elixir/Phoenix Auth Posturing & State Machines
**Confidence:** HIGH

## Summary

This research phase defines the strict implementation of a step-up authentication ceremony protecting administrative routes within Crosswake (Phase 73, Requirements ADM-01 and ADM-02). A backend-issued `StepUpIntent` serves as the sole authority for challenge states, overriding any native or client-cached token validity.

**Primary recommendation:** Use a rigorous `pending -> challenged -> satisfied -> consumed` ephemeral intent lifecycle, ensuring `on_mount` / Plug layers deny and redirect using route IDs rather than raw URLs, avoiding open redirects and session fixation vulnerabilities.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Implement a server-issued `StepUpIntent` contract. This intent is a one-time, backend-signed reference containing the canonical return route, expiry, and required MFA level.
- **D-02:** Do not accept arbitrary absolute return URLs (`?return_to=url`) from the client. The return target must resolve to a known manifest route ID/path.
- **D-03:** Enforce a strict ephemeral state machine for step-up intents: `pending -> challenged -> satisfied -> consumed`, with explicit `expired` and `canceled` failure edges.
- **D-04:** Successful challenge completion must consume the intent and rotate session/CSRF material before returning to the target route.
- **D-05:** Denials must emit the generic `:step_up_required` reason, adding stability subcodes in `details["step_up_code"]` for operator observability (e.g. `auth_too_old`, `challenge_expired`) without leaking sensitive details to the end-user.
- **D-06:** Enforce that step-up evidence is valid against the issued intent before unlocking the admin route. For native passkey/OAuth returns, the backend remains the strict authority, verifying the callback metadata against the intent.
- **D-07:** Implement shared LiveView `on_mount` and Plug pipeline gating. If denied, create the `StepUpIntent` and redirect to the challenge entry.
- **D-08:** Emit structured telemetry events matching the companion telemetry style: `[:crosswake, :sigra, :step_up, :intent_issued]`, `[:crosswake, :sigra, :step_up, :challenge_satisfied]`, etc., to provide the audit trail required by ADM-02.
- **D-09:** Create a dedicated step-up challenge UI following the `73-UI-SPEC.md` visual hierarchy and copywriting contract. Use the "Verify Admin Identity" primary CTA and the designated visual priority without generic 401 pages.
- **D-10:** Build a targeted merge-blocking proof file (`test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs`) verifying route gates, intent issuance/consume invariants, session rotation, and denial vocabulary stability.
- **D-11:** Add a targeted CI workflow (`.github/workflows/phase73-proof.yml`) following archetype proof precedent.

### the agent's Discretion
- None

### Deferred Ideas (OUT OF SCOPE)
- Generic identity-provider integration.
- Silent fallbacks to unsafe routes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | The system must prove an auth-sensitive admin workflow, successfully triggering and verifying Sigra step-up ceremonies (e.g. strict auth posturing). | Addressed by D-01 through D-06, ensuring strict state machines and intent issuance. |
| ADM-02 | The workflow must enforce that native shell session persistence does not implicitly grant administrative route access, requiring handoff tickets and audit trails. | Addressed by D-08, D-10, proving route gating rejects cached native sessions without backend step-up. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| StepUp Intent Issuance | API / Backend | — | The backend maintains strict authority over return targets and challenge requirements to prevent open-redirect and replay attacks. |
| Challenge State Machine | Database / Storage | API / Backend | Intents must be one-time consumable and handle expiration/cancellation securely. |
| Route Gating | Frontend Server (SSR) | API / Backend | `on_mount` and Plug pipelines block access to admin routes before rendering or acting, verifying auth context against required MFA level/age. |
| Challenge UI | Frontend Server (SSR) | Browser / Client | LiveView renders the challenge (e.g. "Verify Admin Identity") keeping auth logic safe on the server. |
| Audit Telemetry | API / Backend | — | Backend ensures all transitions (pending, challenged, consumed) generate secure immutable audit trails. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | ~> 1.7 | Web routing and Plug pipeline gating | Built-in foundation for Elixir web layers. |
| Phoenix LiveView | ~> 0.20 | Challenge UI and `on_mount` hook | Provides real-time rendering and secure session hooks without client-side state authority. |
| Telemetry | ~> 1.0 | Audit trail emission | Standard for Elixir observability, matches Sigra companions. |

## Architecture Patterns

### System Architecture Diagram

```
(Client Request to Admin Route)
          │
          v
[ LiveView on_mount / Plug Pipeline ] ────(allow)───> [ Original Admin Route ]
          │
      (denied via RouteGate)
          │
          v
[ Backend StepUp Generator ] ──(Issues StepUpIntent)──> [ Telemetry Event: intent_issued ]
          │
(Redirects to Challenge Entry)
          │
          v
[ Challenge UI (73-UI-SPEC.md) ]
          │
  (User Completes Verify)
          │
          v
[ Backend Challenge Verifier ] ──(Consumes Intent)──> [ Telemetry Event: challenge_satisfied ]
          │
(Rotates Session/CSRF)
          │
(Redirects to Canonical Admin Route ID)
          │
          v
[ Admin Access Allowed ]
```

### Pattern 1: Shared Plug/LiveView Gating
**What:** Centralized evaluator used by both Plug and LiveView hooks.
**When to use:** Whenever protecting routes that could be accessed directly (Plug) or via live navigation (LiveView).
**Example:**
```elixir
# Source: Internal Crosswake Patterns
def on_mount({:require_step_up, opts}, _params, _session, socket) do
  case StepUpCeremony.evaluate_or_issue(route, auth_context, expected_session_version) do
    {:allow, _} -> {:cont, socket}
    {:challenge, _intent, challenge} -> {:halt, redirect(socket, to: challenge_path(challenge))}
    {:deny, denial} -> {:halt, redirect(socket, to: denied_path(denial))}
  end
end
```

### Anti-Patterns to Avoid
- **Arbitrary client-provided `return_to` URLs:** Do not pass literal URLs to be redirected upon success. Always use the server-issued `intent_id` which maps internally to the known route ID.
- **Leaking denial details:** Do not display raw failure causes ("auth_too_old", "insufficient_mfa_level") directly in the UI. Map them to `:step_up_required` for the user while emitting the real detail via telemetry.
- **Client-side auth state mutation:** Do not let a native client callback or passkey success dictate success by itself; the backend must verify the payload against the intent and update the projected session lane.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session Rotation | Custom cookie tracking | `Plug.Conn.configure_session(conn, renew: true)` | Prevents session fixation securely using battle-tested Phoenix primitives. |
| CSRF Rotation | Custom tokens | `Plug.CSRFProtection.delete_csrf_token/0` | Ensures challenge completions cleanly invalidate old mutation paths. |
| Challenge State Machine | Cookie-based state tracking | Backend-persisted `StepUpIntent` records | Cookie-based intents are vulnerable to replay, manipulation, and multi-device desync. |

**Key insight:** Auth ceremonies require strict backend authority. Rely on Phoenix's built-in session renewal while the overarching Step-Up intent remains stored on the backend, immune to client tampering.

## Common Pitfalls

### Pitfall 1: Session Fixation
**What goes wrong:** After a successful step-up, the user retains the same session ID.
**Why it happens:** The developer forgets to explicitly renew the session upon completing the ceremony.
**How to avoid:** Always call `Plug.Conn.configure_session(conn, renew: true)` and reset CSRF upon consuming the `StepUpIntent`.

### Pitfall 2: Replay of Consumed Intents
**What goes wrong:** A step-up challenge is fulfilled twice.
**Why it happens:** The intent state machine is not enforced, or `consumed_at` is not checked.
**How to avoid:** Enforce strict `pending -> challenged -> satisfied -> consumed` paths. Any attempt to use a non-pending/challenged intent must hard-fail.

### Pitfall 3: Implicit Native Trust
**What goes wrong:** The admin route trusts the native shell's cached session unconditionally.
**Why it happens:** `RouteGate` accepts `cached: true` without enforcing the `:requires_recent_auth` strict posture.
**How to avoid:** Map `ADM-02` correctly; native cached sessions trigger the StepUp ceremony automatically until the strict age criteria are met.

## Code Examples

Verified patterns from official sources:

### Session and CSRF Rotation
```elixir
# Source: Phoenix Plug Documentation (https://hexdocs.pm/plug/Plug.Conn.html)
conn
|> Plug.Conn.configure_session(renew: true)
|> Plug.CSRFProtection.delete_csrf_token()
|> put_session("crosswake_session_version", new_version)
|> redirect(to: target_path)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `?return_to=/url` open redirects | Signed `StepUpIntent` referencing route IDs | v3.8 Auth Design | Eliminates open-redirect phishing and enforces backend return authority. |
| Client evaluates auth state | `RouteGate` server evaluation | v3.8 Auth Design | Ensures native shells cannot bypass admin rules simply by caching tokens. |

**Deprecated/outdated:**
- Generic 401 pages for step-up: Replaced by dedicated Challenge UI conforming strictly to `73-UI-SPEC.md`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADM-01 | Step-up intent lifecycle/gating | integration | `mix test test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` | ✅ Wave 0 (partially complete) |
| ADM-02 | Native shell session strictness | unit/integration | `mix test test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Implement LiveView Challenge UI exactly per `73-UI-SPEC.md` if not completely present in the host.
- [ ] Add Github Actions `.github/workflows/phase73-proof.yml` (or ensure existing covers the CI proof).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Backend-issued `StepUpIntent` with short expiry |
| V3 Session Management | yes | `configure_session(renew: true)`, strictly ephemeral challenge intents |
| V4 Access Control | yes | Shared `RouteGate` evaluation blocking admin routes |
| V5 Input Validation | yes | Strict matching of intent properties, no open URL redirects |
| V6 Cryptography | yes | `Plug.CSRFProtection.delete_csrf_token/0` |

### Known Threat Patterns for Elixir/Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open Redirect | Spoofing/Elevation | Use signed Route IDs in intents instead of absolute URL parsing. |
| Session Fixation | Spoofing | Renew session ID on successful challenge completion. |
| Challenge Replay | Tampering/Elevation | Ephemeral state machines (`:consumed` status) and database locks around intent execution. |

## Sources

### Primary (HIGH confidence)
- [Internal Crosswake Design Contract] `.planning/research/v3.8/STEP-UP.md` - Shared Gate/Intent Model
- [Official docs URL] https://hexdocs.pm/plug/Plug.Conn.html - Session manipulation
- [Official docs URL] https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - LiveView redirect from `on_mount`

### Secondary (MEDIUM confidence)
- Internal Reference: `.planning/phases/73-auth-sensitive-admin-workflow-proof/73-UI-SPEC.md`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix principles.
- Architecture: HIGH - Dictated by Crosswake's strict backend authority paradigm.
- Pitfalls: HIGH - Standard session fixation and replay vulnerabilities known in auth workflows.

**Research date:** 2026-06-05
**Valid until:** 30 days
