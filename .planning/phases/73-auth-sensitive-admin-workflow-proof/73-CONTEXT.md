# Phase 73: Auth-Sensitive Admin Workflow Proof - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove an auth-sensitive admin workflow by stress-testing Sigra step-up ceremonies and strict auth posturing. The proof must demonstrate that native shell session persistence does not implicitly grant administrative route access. It requires a backend-issued handoff ticket (`StepUpIntent`) and an audit trail to unlock admin routes.

This phase is an archetype proof lane focused on strict auth posturing (ADM-01) and boundary safety (ADM-02). It is not a generic identity-provider implementation nor an open-redirect proxy.
</domain>

<decisions>
## Implementation Decisions

### Step-Up Target Authority
- **D-01:** Implement a server-issued `StepUpIntent` contract. This intent is a one-time, backend-signed reference containing the canonical return route, expiry, and required MFA level.
- **D-02:** Do not accept arbitrary absolute return URLs (`?return_to=url`) from the client. The return target must resolve to a known manifest route ID/path.

### Challenge State Machine
- **D-03:** Enforce a strict ephemeral state machine for step-up intents: `pending -> challenged -> satisfied -> consumed`, with explicit `expired` and `canceled` failure edges.
- **D-04:** Successful challenge completion must consume the intent and rotate session/CSRF material before returning to the target route.
- **D-05:** Denials must emit the generic `:step_up_required` reason, adding stability subcodes in `details["step_up_code"]` for operator observability (e.g. `auth_too_old`, `challenge_expired`) without leaking sensitive details to the end-user.

### Return Boundary Safety
- **D-06:** Enforce that step-up evidence is valid against the issued intent before unlocking the admin route. For native passkey/OAuth returns, the backend remains the strict authority, verifying the callback metadata against the intent.
- **D-07:** Implement shared LiveView `on_mount` and Plug pipeline gating. If denied, create the `StepUpIntent` and redirect to the challenge entry.

### Telemetry and Audit Trail
- **D-08:** Emit structured telemetry events matching the companion telemetry style: `[:crosswake, :sigra, :step_up, :intent_issued]`, `[:crosswake, :sigra, :step_up, :challenge_satisfied]`, etc., to provide the audit trail required by ADM-02.

### Support Truth and UI/DX
- **D-09:** Create a dedicated step-up challenge UI following the `73-UI-SPEC.md` visual hierarchy and copywriting contract. Use the "Verify Admin Identity" primary CTA and the designated visual priority without generic 401 pages.

### Proof Spine
- **D-10:** Build a targeted merge-blocking proof file (`test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs`) verifying route gates, intent issuance/consume invariants, session rotation, and denial vocabulary stability.
- **D-11:** Add a targeted CI workflow (`.github/workflows/phase73-proof.yml`) following archetype proof precedent.
</decisions>

<canonical_refs>
## Canonical References

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, backend-owned authority.
- `.planning/milestones/v4.1-REQUIREMENTS.md` - ADM-01, ADM-02 traceability.
- `.planning/ROADMAP.md` - Phase 73 goal and success criteria.

### Auth Research and Contracts
- `.planning/research/v3.8/STEP-UP.md` - Sigra Step-Up Challenge and Return Flow recommendations.
- `.planning/phases/73-auth-sensitive-admin-workflow-proof/73-UI-SPEC.md` - Step-up UI design system and copywriting constraints.
- `lib/crosswake/companions/sigra/contracts.ex` - Auth contracts.
</canonical_refs>

<code_context>
## Existing Code Insights

### Established Patterns
- Archetype proofs are product-shaped, adversarial, deterministic, and CI-hermetic.
- Client/device evidence is never the authority; backend-issued intents and route gates control access.
- Denial vocabulary is stable, typed, and support-safe.
</code_context>

<specifics>
## Specific Ideas

- **Proof story:** User with active session attempts Admin route access -> denied by `auth_min_level` / `requires_recent_auth` -> backend issues `StepUpIntent` -> redirects to challenge UI -> user submits verification -> backend verifies intent, consumes it, rotates session -> user is redirected to Admin route, access granted.
- **Negative cases:** Challenge timeout (expired intent), spoofed intent ID, invalid return path requested, re-use of consumed intent.
</specifics>

<deferred>
## Deferred Ideas

- Generic identity-provider integration.
- Silent fallbacks to unsafe routes.
</deferred>
