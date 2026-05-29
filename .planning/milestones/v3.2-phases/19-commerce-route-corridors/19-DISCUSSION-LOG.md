# Phase 19: Commerce Route Corridors - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 19-commerce-route-corridors
**Areas discussed:** Corridor Declaration Shape, Manifest Corridor Truth Surface, Fail-Closed Denial Vocabulary, Public Guidance Boundaries

---

## Corridor Declaration Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Inline route-local commerce block | Maximum local clarity; repeated declarations per route | |
| Named corridor profiles + per-route binding | Reusable and consistent corridor truth with route-local visibility | ✓ |
| Scope-level defaults | Concise for large route trees, but can hide precedence complexity | |
| Intent-surface explicit declarations | Highly explicit but verbose for most teams | |

**User's choice:** Discuss all areas and receive one-shot cohesive recommendations; accept recommended approach unless conflicting with project guardrails.
**Notes:** Recommendation emphasized idiomatic Elixir DSL ergonomics, fail-closed correctness, and keeping provider vocabulary out of core.

---

## Manifest Corridor Truth Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Route-embedded corridor metadata only | Simple but repetitive and drift-prone | |
| Corridor registry + route references | Canonical registry truth with per-route binding and easier doctor/support derivation | ✓ |
| Global moment matrix | Auditable but indirect for route authors | |
| Full corridor graph/state-machine | Powerful but over-complex for Phase 19 | |

**User's choice:** One-shot recommendations with deep tradeoff analysis and ecosystem lessons.
**Notes:** Recommendation aligns to existing Crosswake registry/reference manifest patterns and additive schema evolution.

---

## Fail-Closed Denial Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal reason set only | Low change cost, low diagnostic precision | |
| Two-layer taxonomy (family + canonical code IDs) | Balanced precision and maintainability, backward-compatible messaging | ✓ |
| Highly expressive granular taxonomy | Rich observability but reason explosion risk | |

**User's choice:** Prefer coherent defaults and least-surprise diagnostics over exploratory decision loops.
**Notes:** Recommended canonical code family: `commerce.corridor.*` with explicit fallback IDs and no implicit fallback behavior.

---

## Public Guidance Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Matrix-first docs structure | Fast ownership/support truth decisions and consistent operator posture | ✓ |
| Scenario-first docs structure | Better onboarding narrative, weaker boundary rigor alone | |
| Policy-first docs structure | Strong contract rigor, heavier first-read cognitive load | |

**User's choice:** Optimize for developer ergonomics and user-friendly documentation while preserving strict architecture boundaries.
**Notes:** Recommended docs layering: matrix-first spine, scenario walkthroughs, then policy invariants and anti-footgun guidance.

---

## Claude's Discretion

- Exact field naming and internal struct decomposition for corridor manifest types.
- Exact validator error text, as long as messages remain explicit and actionable.
- Exact ordering of docs sections while preserving matrix-first semantics.

## Deferred Ideas

None.
