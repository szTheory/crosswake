# Phase 55: Session Handoff Tickets And Authority Projection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 55-Session Handoff Tickets And Authority Projection
**Areas discussed:** Ticket Record And Envelope Shape, Atomic Redemption And Session Renewal Boundary, Handoff Denial Codes And Safe Details, Audit And Replay Source Of Truth

---

## Ticket Record And Envelope Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Self-contained signed ticket | Signed envelope carries all useful authority/session claims. Simple and stateless, but replay, revocation, stale claims, and shell/client authority confusion are serious risks. | |
| Opaque server ticket only | Client carries a high-entropy opaque token; all data lives in the server record. Strong backend authority, but weaker diagnostics and less self-describing DX. | |
| Hybrid signed envelope + authoritative server record | Client carries a short-lived signed locator/purpose envelope; server row remains replay/revocation/expiry/binding/audit authority. | yes |
| Device-bound native shell token | Hard-bind ticket to native device/shell. Useful only when host has registered device identity; brittle as a default and risks implying shell authority. | |
| Route/action capability token | Ticket directly grants one route/action. Bypasses `SessionAuthorityLane` and conflicts with Crosswake's authority model. | |

**User's choice:** Discuss all and let subagent-backed research produce one cohesive recommendation.
**Notes:** Research converged on the hybrid model. Envelope is a redemption credential only; server record is authority. Device binding is optional and backend-owned, not a shell default.

---

## Atomic Redemption And Session Renewal Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Crosswake renews Phoenix sessions directly | Easy adopter story but oversteps host ownership of session keys, Repo, CSRF policy, sockets, and account model. | |
| Example-host-only flow | Honest and copyable, but too weak for HAND-02 because no stable typed contract guides adopters. | |
| Typed result only, renewal deferred | Keeps Phase 55 small but punts the explicit requirement that redemption renews the Phoenix session and projects authority. | |
| Host callback/contract plus concrete example-host implementation | Crosswake defines contracts/results and example proof; host owns persistence and `Plug.Conn` mutation. | yes |

**User's choice:** Discuss all and let subagent-backed research produce one cohesive recommendation.
**Notes:** The selected boundary matches Phoenix/Plug/Ecto idioms: backend transaction first, `configure_session(conn, renew: true)` after success, and no ceremony UX until Phase 56.

---

## Handoff Denial Codes And Safe Details

| Option | Description | Selected |
|--------|-------------|----------|
| Keep all codes under `auth.step_up.*` | Minimal churn, but conflates route-auth freshness with ticket redemption and muddies Phase 56 step-up intent codes. | |
| Add `auth.handoff.*` subcodes under public `:step_up_required` | Stable shell UX plus precise operator/developer diagnostics for handoff-specific failures. | yes |
| One generic handoff code | Safer surface but poor DX and weak HAND-03 traceability. | |
| Add new shell reason `:handoff_denied` | Semantically pure but churns public shell vocabulary and encourages native branching on auth internals. | |

**User's choice:** Discuss all and let subagent-backed research produce one cohesive recommendation.
**Notes:** The locked taxonomy keeps public `:step_up_required` and adds `auth.handoff.missing_ticket`, `invalid_ticket`, `expired_ticket`, `replayed_ticket`, `revoked_ticket`, `binding_mismatch`, `intent_mismatch`, `route_mismatch`, and `projection_failed`.

---

## Audit And Replay Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Stateless signed ticket only | Simple, but fails replay/revoke/audit requirements. | |
| Opaque server ticket only | Strong source of truth, but less DX than a signed envelope plus server record. | |
| Signed envelope + one-time server record + audit events | Record owns lifecycle state; append-only audit events preserve issue/redeem/revoke/expire evidence. | yes |
| Event-sourced ledger as primary state | Strong audit but overbuilt for Phase 55 and easy to overcomplicate. | |
| Telemetry-first lifecycle | Useful later, but telemetry is not durable authority. | |

**User's choice:** Discuss all and let subagent-backed research produce one cohesive recommendation.
**Notes:** Ticket record is current lifecycle state; audit events are durable evidence; telemetry/export/security closeout is deferred to Phase 58.

---

## the agent's Discretion

- Exact module names, field names, default TTLs, digest helper shape, and example-host persistence details are left to downstream research/planning as long as the locked authority, denial, and audit boundaries hold.
- Exact support/doctor/operator wording is flexible, but it must distinguish Phase 55 handoff contracts from deferred Phase 56 ceremony, Phase 57 return boundaries, and Phase 58 telemetry/security closeout.

## Deferred Ideas

- Step-up ceremony and return UX: Phase 56.
- OAuth/passkey/native return boundaries: Phase 57.
- Telemetry taxonomy, audit export, and security closeout: Phase 58.
- Provider-specific identity templates, native auth UI, and refresh-token helpers: future requirements only.
