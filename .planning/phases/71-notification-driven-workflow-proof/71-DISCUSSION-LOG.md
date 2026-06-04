# Phase 71: Notification-Driven Workflow Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 71-notification-driven-workflow-proof
**Areas discussed:** proof spine, Sigra/RouteGate authority, adversarial denials, DX/operator/UI truth

---

## Proof Spine

| Option | Description | Selected |
|--------|-------------|----------|
| Pure contract-only ExUnit proof | Fast and hermetic, but too close to existing resolver/unit coverage and does not prove the archetype workflow. | |
| Example-host Ecto registry proof | Exercises real token binding and one-time open intent lifecycle, but is slower and more brittle as the merge gate. | |
| Hermetic product-shaped proof with inline stateful intent consumer | Uses real Chimeway resolver, RouteGate, and Sigra contracts while mocking only backend/provider storage edges. | Yes |
| Full Phoenix endpoint/LiveView or native/APNs/FCM proof | More realistic externally, but too broad, non-hermetic, and likely to overclaim delivery/tray behavior. | |

**User's choice:** Discuss all areas with subagent-backed research and provide a one-shot recommendation set.
**Notes:** Four subagents researched proof shape, auth authority, denial matrix, and DX/operator/UI posture. The final recommendation reconciles the example-host precedent with the need for a fast hermetic merge gate by choosing an inline stateful intent consumer for Phase 71.

---

## Sigra And RouteGate Authority

| Option | Description | Selected |
|--------|-------------|----------|
| Direct notification open to RouteGate only | Simple but too thin; weak one-time/audit story and risks implying payload authority. | |
| Server-issued one-time Chimeway open intent to resolver to RouteGate with Sigra AuthContext | Keeps notification tap as evidence, backend intent as state, and RouteGate/Sigra as activation authority. | Yes |
| Add full Sigra step-up continuation in this phase | Stronger product story but introduces double-consume/continuation lifecycle risk. | |
| Let shell/native deep link carry session/token and open route directly | Familiar mobile shortcut, but violates backend authority and Phoenix security posture. | |

**User's choice:** Agent recommendation requested.
**Notes:** Phase 71 should prove step-up denial and fresh-auth allow behavior, not design the whole continuation ceremony.

---

## Adversarial Denials

| Option | Description | Selected |
|--------|-------------|----------|
| Small happy-path proof | Demonstrates activation but misses the security value of the phase. | |
| Resolver/unit denial matrix only | Fast but not enough workflow pressure. | |
| Product-shaped proof with explicit positive and negative matrix | Covers auth failures, intent lifecycle failures, route/action policy failures, fallback bypass, and redaction. | Yes |

**User's choice:** Agent recommendation requested.
**Notes:** Research highlighted two likely fix targets: revoked-binding denial vocabulary drift and missing action-ref binding between issued intent and evidence.

---

## DX, Operator Truth, And UI

| Option | Description | Selected |
|--------|-------------|----------|
| Pure test-only proof | Lowest risk, but weak adopter-facing workflow signal. | |
| Full notification UX surface | Strong demo but high scope creep and delivery overclaim risk. | |
| Hermetic proof plus narrow Phoenix/operator/docs truth | Best balance: proof is public-contract evidence, docs explain Chimeway + Sigra boundaries, UI stays tiny if touched. | Yes |
| Native shell notification tap simulation | More realistic but advisory/device/provider proof, not merge-blocking. | |

**User's choice:** Agent recommendation requested.
**Notes:** If UI is touched, keep it Phoenix-owned and compact. Avoid notification center, delivery dashboard, provider metrics, and tray behavior.

---

## The Agent's Discretion

- Exact proof helper and fixture names.
- Whether a narrow example-host proof/status panel is worth adding or whether docs/operator truth is enough.
- Exact CI job names and proof command shape.
- Exact stable denial-code spelling for revoked binding and action mismatch, provided public vocabulary is canonical and support-safe.

## Deferred Ideas

- Full step-up continuation/resume flow after notification-open denial.
- Real APNs/FCM/device/tray proof.
- Full Phoenix endpoint/LiveView E2E proof.
- Notification center, topic APIs, delivery dashboard, and generic action registry.
- Threadline-style durable audit capstone for notification-open decisions.
