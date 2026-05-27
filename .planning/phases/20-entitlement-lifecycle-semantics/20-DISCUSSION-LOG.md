# Phase 20: Entitlement Lifecycle Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-27T09:47:20Z
**Phase:** 20-entitlement-lifecycle-semantics
**Areas discussed:** Snapshot model shape, Lifecycle state taxonomy, Evidence envelope boundaries, Provider state mapping boundary

---

## Snapshot Model Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Single lifecycle enum snapshot | One top-level state field for all lifecycle and freshness semantics | |
| Flat multi-field snapshot | Add more top-level fields on current struct | |
| Axis-separated lane model | Separate authority/access/reconciliation/freshness/effective/evidence lanes | ✓ |
| Snapshot + embedded timeline | Include event timeline inside snapshot contract | |

**User's choice:** Axis-separated lane model (recommended one-shot selection).
**Notes:** Chosen for strongest alignment with ENTL-01/02/03, provider-neutrality, and fail-closed clarity without enum explosion.

---

## Lifecycle State Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Single flat lifecycle enum | One status axis for all semantics | |
| Orthogonal state axes | Authority, access, reconciliation, freshness are separate axes with explicit invariants | ✓ |
| Two-axis + qualifier flags | Core axes plus additive flags | |
| Event-first only | No stable taxonomy; derive from event stream | |

**User's choice:** Orthogonal state axes (recommended one-shot selection).
**Notes:** Pending states remain reconciliation-only, freshness remains independent, and access stays explicit with reason metadata.

---

## Evidence Envelope Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Thin core envelope | Minimal core metadata, most evidence context left in adapters | |
| Tiered canonical envelope + secure references | Core stores provenance/integrity/idempotency + refs; raw payloads remain adapter-private | ✓ |
| Rich normalized envelope | Core includes broad mapped provider hints | |
| Snapshot-only ingestion | Skip first-class evidence contract | |

**User's choice:** Tiered canonical envelope + secure references (recommended one-shot selection).
**Notes:** Balances provider-neutral core with replay/debug integrity. Core evidence remains non-authoritative and append-only.

---

## Provider State Mapping Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Companion adapters own all mapping | Mapping fully delegated to adapters | |
| Host app owns all mapping | Adapters pass raw statuses/events to host | |
| Mixed anti-corruption model | Adapter normalizes provider events; host reconciliation/projector maps final entitlement semantics | ✓ |
| Core maps provider enums directly | Provider mapping logic in core contracts | |

**User's choice:** Mixed anti-corruption model (recommended one-shot selection).
**Notes:** Preserves core purity while allowing host-owned authority policy and explicit no-leak testing of provider terms.

---

## Claude's Discretion

- Exact struct/module naming for lane-oriented snapshot fields.
- Exact reason-code identifiers and helper predicate naming.
- Projection metadata field naming (`as_of`, version marker, equivalent) as long as monotonic ordering is guaranteed.

## Deferred Ideas

None.
