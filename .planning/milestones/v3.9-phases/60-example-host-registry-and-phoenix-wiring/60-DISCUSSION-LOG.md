# Phase 60: Example Host Registry And Phoenix Wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 60-Example Host Registry And Phoenix Wiring
**Areas discussed:** Registry row shape and uniqueness, Lifecycle transaction semantics, Audit and telemetry posture, Optional worker guidance boundary

---

## Registry Row Shape And Uniqueness

| Option | Description | Selected |
|--------|-------------|----------|
| Single current row per subject/session | Simple, but loses lifecycle history and weakens support truth. | |
| Append-only event ledger only | Strong audit, but poor copyability and lookup DX without projection machinery. | |
| Token-first registry keyed by `token_fingerprint` | Useful dedupe axis, but risks treating token possession as identity if used alone. | |
| Backend binding projection plus append-only audit events | Active/history projection with support-safe audit rows and explicit backend authority. | ✓ |
| Fully normalized installation/device/token/subject tables | Production-shaped, but too broad for Phase 60. | |

**User's choice:** Discuss and consider all; make a cohesive recommendation.
**Notes:** Recommendation locks a mutable `chimeway_token_bindings` projection plus append-only audit events, string-backed `Ecto.Enum`, partial active indexes, and no raw token storage in the example registry.

---

## Lifecycle Transaction Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Upsert-heavy projection | Good for same-token refresh, but overwrites lifecycle truth if used as the main model. | |
| Explicit revoke plus insert `Ecto.Multi` | Clear Phoenix/Ecto lifecycle flow, good audit, but more code. | |
| Append-only events plus projection | Strong audit, too heavy for example-host registry. | |
| Hybrid transaction | Binding projection plus append-only audit plus narrow idempotent same-token refresh. | ✓ |

**User's choice:** Discuss and consider all; make a cohesive recommendation.
**Notes:** Recommendation locks `Ecto.Multi` lifecycle functions for initial bind, same-token refresh, rotation, logout/session revocation, permission loss, provider invalidation, and stale pruning.

---

## Audit And Telemetry Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Durable audit rows only | Durable support truth, but weak diagnostics alone. | |
| Telemetry only | Easy diagnostics, but non-durable and unsafe if emitted before rollback. | |
| Hybrid audit plus post-commit telemetry | Durable lifecycle evidence plus low-cardinality diagnostics. | ✓ |
| Event-sourcing-heavy registry | Complete lineage, but too much machinery for v3.9 example host. | |

**User's choice:** Discuss and consider all; make a cohesive recommendation.
**Notes:** Recommendation locks audit writes inside the transaction and Chimeway telemetry after `Repo.transaction/1` succeeds.

---

## Optional Worker Guidance Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| No worker guidance | Too little guidance for provider feedback and pruning. | |
| Pseudo-code/docs only | Preserves optionality but weak copyability. | |
| Pure registry APIs plus optional Oban recipe | Synchronous audited functions; worker/scheduler snippets call those APIs without dependencies. | ✓ |
| Bundled worker/dependency | Strong for Oban users, but violates Phase 60 scope and overclaims Chimeway readiness. | |

**User's choice:** Discuss and consider all; make a cohesive recommendation.
**Notes:** Recommendation locks synchronous registry APIs and optional non-compiled Oban guidance. No Oban, Quantum, Broadway, GenServer scheduler, or Chimeway worker dependency ships in Phase 60.

---

## the agent's Discretion

- Exact module and table names remain planner discretion within the locked architecture.
- Exact idempotency-key shape remains planner discretion if support-safe and retry-friendly.
- Exact optional worker snippet placement remains planner discretion if non-compiled and host-owned.

## Deferred Ideas

- Fully normalized production registry model.
- Bundled background worker modules or dependencies.
- Notification-open resolver, RouteGate activation, Sigra step-up, and notification denial vocabulary.
- Broad support/doctor/operator/docs expansion.
- Real APNs/FCM delivery adapters and delivery proof.
