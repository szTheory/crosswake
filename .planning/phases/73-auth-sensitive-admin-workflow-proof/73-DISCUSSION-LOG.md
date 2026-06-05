# Phase 73: Auth-Sensitive Admin Workflow Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 73-auth-sensitive-admin-workflow-proof
**Areas discussed:** Step-up target authority, Challenge state machine, Return boundary safety, Support truth and UI/DX

---

## Step-Up Target Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Client-controlled redirect (`?return_to=url`) | Use unvalidated query parameters for challenge return targets. | |
| Session-only stored target | Keep target entirely in session without a server-signed challenge state. | |
| Server-issued Step-Up Intent contract | Issue a one-time, signed `StepUpIntent` containing canonical return route, expiry, and required level. | ✓ |

**User's choice:** Discuss and consider all; produce one-shot recommendations.
**Notes:** Research (`STEP-UP.md`) strongly recommends the server-issued `StepUpIntent` contract (Approach C). It matches Crosswake's backend-owned authority and fail-closed posture, preventing open-redirects and stale target replays while unifying LiveView, Plug, and native return boundaries.

---

## Challenge State Machine

| Option | Description | Selected |
|--------|-------------|----------|
| Stateless check | Route checks auth on each hit; no explicit challenge state. | |
| Persistent challenge ticket | Step-up intents live forever until satisfied. | |
| Strict ephemeral state machine | Intent states transition strictly (`pending` -> `challenged` -> `satisfied`/`expired`), with short max-age and one-time consume. | ✓ |

**User's choice:** Discuss and consider all.
**Notes:** To prove strict auth posturing (ADM-01), the state machine must enforce expiry, invalidation on consume, and session rotation upon success to prevent fixation and replay attacks.

---

## Return Boundary Safety

| Option | Description | Selected |
|--------|-------------|----------|
| Broad deep-link trust | Any native scheme callback marks step-up as satisfied. | |
| PKCE + Strict intent verification | OAuth/native callbacks provide evidence, but only the backend verifies the intent and issues session rotation/authority. | ✓ |

**User's choice:** Discuss and consider all.
**Notes:** ADM-02 requires that native shell session persistence does not implicitly grant administrative access. The backend must enforce that step-up evidence is valid against the issued intent before unlocking the admin route.

---

## Support Truth And UI/DX

| Option | Description | Selected |
|--------|-------------|----------|
| Proof-only, no UI | Keep implementation narrowly on tests. | |
| Generic auth error pages | Use standard 401/403 pages without challenge context. | |
| Dedicated Step-up UI component | A focused challenge UI card (matching 73-UI-SPEC.md) that surfaces intent status securely. | ✓ |

**User's choice:** Discuss and consider all.
**Notes:** 73-UI-SPEC.md is already defined. We need to implement the visual hierarchy for the step-up challenge UI element without leaking internal payload details to the user.

---

## The Agent's Discretion

- Exact helper/module names for step-up intents and policy DSL extensions.
- Whether the challenge UI is a separate LiveView or embedded in an existing admin layout, as long as it adheres to 73-UI-SPEC.md.
- Exact CI job names, as long as Phase 73 has a targeted merge-blocking proof lane.

## Deferred Ideas

- Generic identity-provider adapters for all vendors.
- Token storage guidance that encourages WebView localStorage/sessionStorage authority.
- Magic automatic fallback from denied secure route to a permissive route (always fail closed).
