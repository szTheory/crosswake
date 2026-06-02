# Phase 56: Step-Up Intent And Plug/LiveView Ceremony - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 56-Step-Up Intent And Plug/LiveView Ceremony
**Areas discussed:** Step-up intent lifecycle, shared Plug/LiveView ceremony, successful return/session renewal

---

## Step-Up Intent Lifecycle And Storage Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Session-only `return_to` plus challenge flag | Familiar Phoenix shape, but weak replay/cancel/expiry truth and poor audit. | |
| Self-contained signed step-up token | Easy to issue, but revocation/replay/cancel truth is poor and claims can be overtrusted. | |
| Reuse Phase 55 handoff ticket record | Reuses proven mechanics, but handoff and step-up have different lifecycle and UX semantics. | |
| Server-side `StepUpIntent` record + opaque/signed locator | Backend-owned lifecycle, single-use consumption, fail-closed route target, auditable, fits Plug/LiveView. | yes |
| Generic auth challenge framework | Covers more auth shapes, but too broad and blurs Phase 56 vs Phase 57. | |

**User's choice:** Research all and recommend the best coherent path.
**Notes:** Recommendation locks a separate Sigra-scoped `StepUpIntent` contract modeled after the Phase 55 hybrid pattern: signed/opaque locator plus authoritative server row. Host/example app owns Ecto persistence; core owns pure contracts, validators, denial codes, safe details, and proof posture.

---

## Shared Plug/Controller And LiveView Ceremony

| Option | Description | Selected |
|--------|-------------|----------|
| Shared Sigra evaluator + shared ceremony service + thin adapters | One decision model; idiomatic Plug redirect/halt and LiveView `on_mount` halt; fail-closed and proofable. | yes |
| Duplicate Plug and LiveView logic | Locally simple, but high drift risk and unreliable support/operator truth. | |
| Generic middleware/policy framework | Extensible, but too broad for Crosswake and hides route/runtime ownership. | |
| RouteGate-only ceremony | Keeps one existing module, but `RouteGate` should not issue intents, redirect, or mutate sessions. | |

**User's choice:** Research all and recommend the best coherent path.
**Notes:** Recommendation locks one Sigra ceremony core using `Evaluator`/`RouteGate` decision semantics as input, plus thin Plug and LiveView adapters. `RouteGate` remains route activation logic, not ceremony transport.

---

## Successful Return, Session/CSRF Renewal, And Route Target Validation

| Option | Description | Selected |
|--------|-------------|----------|
| Route-id return target | Manifest-owned, shell-safe, easy to prove, avoids open redirects; params must be typed/allowlisted. | yes |
| Raw `return_to` URL | Familiar and flexible, but creates open redirect, query smuggling, host/scheme, and route-policy bypass risks. | |
| Signed redirect token | Useful as a locator, but dangerous if treated as self-contained redirect authority. | partial |
| Crosswake mutates `Plug.Conn` | One-call DX, but violates host-owned session/CSRF/account boundaries. | |
| Host-owned renewal instructions | Matches Phase 55 contract and Phoenix idioms; host applies session/CSRF changes explicitly. | yes |

**User's choice:** Research all and recommend the best coherent path.
**Notes:** Recommendation locks manifest-known route IDs plus typed params, not raw URLs. Successful step-up consumes the intent, refreshes backend `SessionAuthorityLane`, proves return route authority, returns typed renewal/CSRF/socket invalidation instructions, and leaves actual `Plug.Conn` mutation to the host.

---

## the agent's Discretion

- Exact module names, file splits, Ecto schema names, TTL defaults, challenge UI details, and precise denial subcode names remain planner discretion within the locked Sigra-scoped architecture.
- Planner should bias toward narrow, boring, Phoenix-native APIs and support-matrix/doctor/docs proof over broad auth framework behavior.

## Deferred Ideas

- OAuth/passkey/native auth-return boundaries remain Phase 57.
- Full auth telemetry/security closeout remains Phase 58.
- Refresh-token rotation, provider templates, passkey SDK wrappers, and native auth UI remain future work.
