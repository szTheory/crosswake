# Phase 21: Reconciliation Example - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 21-reconciliation-example
**Areas discussed:** Example artifact shape, inbox lifecycle model, idempotency policy, projection contract, integration boundaries

---

## Example Artifact Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Docs-only walkthrough | Lowest implementation overhead, weakest executable proof and highest interpretation drift | |
| Code-first reference modules only | Strong executable truth but weaker onboarding and boundary explanation | |
| Hybrid docs + executable reference + tests | Balances teachability, proof, and least-surprise adoption while preserving scope boundaries | ✓ |
| Generator/scaffold first | High short-term convenience but premature support/API lock-in | |

**User's choice:** Hybrid docs + executable reference + tests.
**Notes:** Must remain example/docs-only and companion-ready; no accidental core framework mandate.

---

## Reconciliation Inbox Lifecycle Model

| Option | Description | Selected |
|--------|-------------|----------|
| Single mutable attempt row | Minimal schema, weaker evidence trail and replay forensics | |
| Append-only inbox events + canonical attempt + authoritative snapshot projection | Strong auditability and operator clarity with manageable complexity | ✓ |
| Per-source inbox tables | High specialization but duplicated logic and drift risk | |
| Full event-sourced platform | Powerful but too heavy for Phase 21 minimal scope | |

**User's choice:** Append-only events + canonical attempt + authoritative snapshot projection.
**Notes:** Preserve backend-owned authority and explicit non-granting evidence semantics.

---

## Idempotency And Duplicate Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Correlation-ID-first idempotency | Simple but unsafe across retries/sources; violates RECN-02 intent | |
| Simple provider/reference/event triplet only | Better baseline but weak for token replacement and reorder complexity | |
| Provider event-id only | Strong transport dedupe, weak cross-source subject coherence | |
| Dual-key canonical policy (`event_key` + `subject_key`) | Best replay safety, ordering control, and authoritative update serialization | ✓ |

**User's choice:** Dual-key canonical policy with separate event dedupe and subject serialization responsibilities.
**Notes:** Device correlation IDs remain tracing metadata only; duplicate and out-of-order handling must be deterministic and non-granting.

---

## Entitlement Projection Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Lane-only snapshot consumers derive everything | Pure and flexible but encourages consumer drift | |
| Dual-layer projection (derived top-level state + full lane detail) | Best for consistency, operator explainability, and consumer ergonomics | ✓ |
| Flat enum only | Easy to consume but loses essential semantics and observability | |
| Event-stream-first consumer projections | Flexible but too heavy for minimal example scope | |

**User's choice:** Dual-layer projection contract.
**Notes:** Precedence refined to stale/unknown fail-closed first; pending remains explicit non-granting reconciliation posture; monotonic `as_of` guard required.

---

## Integration Boundary Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Core ships runnable persistence/jobs defaults | Convenient but scope-breaking and misleading support claim | |
| Contract-first core + example/docs-only host recipe + companion-ready adapter seam | Aligns with thesis, scope, and long-term support honesty | ✓ |
| First-party companion runtime implementation now | Better than core lock-in but still premature support-surface expansion | |
| Pure conceptual docs without concrete reference | Lowest coupling, highest adopter ambiguity | |

**User's choice:** Contract-first core + host-owned infra + companion/provider ownership model.
**Notes:** Explicit ownership matrix required in docs; provider enums and SDK details stay outside core contracts.

---

## Claude's Discretion

- Exact file/module naming for example-host reference artifacts.
- Specific internal helper decomposition and fixture granularity.
- Reason-code naming details that preserve provider-neutral semantics.

## Deferred Ideas

None.
