# Phase 48: Strategic Signal and Milestone Memory - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 48-Strategic Signal and Milestone Memory
**Areas discussed:** Strategic arc shape, Closeout checklist enforcement, Future queue rationale

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All three | Cover arc refresh, closeout checklist, and future queue rationale with subagent-backed research. | ✓ |
| Checklist focus | Focus on milestone closeout enforcement and artifact parity, assuming the strategic queue is mostly right. | |
| Arc focus | Focus on `MILESTONE-ARC.md` structure and future milestone sequencing, with a lighter closeout checklist. | |

**User's choice:** Discuss and consider all areas.
**Notes:** User requested subagent research, pros/cons/tradeoffs, idiomatic Elixir/Phoenix ecosystem lessons, cross-ecosystem lessons, DX emphasis, least surprise, coherent recommendations, and prompt corpus consideration.

---

## Strategic Arc Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Prose-only refreshed arc | Fast and low ceremony, but repeats drift risk and weakens decision forensics. | |
| ADR-like decision ledger | Durable why-memory, but can fragment strategy if not linked tightly from the arc. | |
| Roadmap-adjacent queue with proof/support gates | Strong planner alignment, but can duplicate roadmap detail and under-capture rationale. | |
| Hybrid canonical narrative plus structured fields and decision notes | Keeps one readable source while making required queue/closeout fields explicit and parity-checkable. | ✓ |

**User's choice:** Delegated to advisor synthesis; hybrid selected.
**Notes:** Subagent recommendation: keep `MILESTONE-ARC.md` canonical, require stable milestone fields, and use dated decision notes instead of silent rewrites.

---

## Closeout Checklist Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Prose checklist only | Cheapest to maintain, but repeats v3.5 artifact parity failures. | |
| Machine-readable closeout ledger | Deterministic and CI-consumable, but can become false confidence if not checked. | |
| `gsd-sdk`-enforced hard closeout gate | Strongest guard, but risks workflow brittleness and exception-handling debt. | |
| Hybrid human checklist plus audit-backed gates | Human judgment for lessons/release narrative; machine gates for parity-critical facts. | ✓ |
| Closeout as code plus PR/hook ergonomics | Useful left-shift enhancement to the hybrid approach. | ✓ as extension |

**User's choice:** Delegated to advisor synthesis; hybrid selected with left-shift DX controls.
**Notes:** v3.5 evidence: missing Phase 44 verification, stale Phase 43 roadmap status, open thread residue, and uneven Nyquist ledgers. The selected posture requires explicit exceptions with reasons.

---

## Future Queue Rationale

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed linear sequence | Easy to read, but hides dependency debt and false readiness signals. | |
| Dependency graph with optional branches | Accurate, but harder to scan and prone to graph entropy. | |
| Risk-tiered queue | Strong safety signaling, but weaker delivery-order narrative. | |
| Now/Next/Later only | Contributor-friendly, but too coarse for STRAT-01 dependency discipline. | |
| Hybrid dependency DAG plus Now/Next/Later view and risk tags | Balances readability with dependency truth and deferred-scope honesty. | ✓ |

**User's choice:** Delegated to advisor synthesis; hybrid selected.
**Notes:** Locked dependency gates: v3.7 depends on v3.6 operator truth; v3.8 precedes auth-sensitive notification-open claims; v4.0 shell runtime evidence precedes v4.1 production-shaped archetypes; Threadline remains later until audited event surfaces are stable.

---

## the agent's Discretion

- Exact closeout ledger filename and schema mechanics are planner discretion.
- Exact parity-check implementation is planner discretion, with bias toward simple deterministic tests or existing `gsd-sdk` queries.
- Exact prose organization in `MILESTONE-ARC.md` is planner discretion if the field contract and dependency gates remain explicit.

## Deferred Ideas

- Full closeout verification tooling may be implemented in Phase 53 if Phase 48 only defines the contract.
- Repository branch-protection setup may need manual configuration outside the repo.
