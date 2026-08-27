---
phase: 162
slug: physical-iphone-adoption-proof
status: pending_independent_verification
validated: 2026-08-27
---

# Phase 162 — Corrected-Provenance Recovery Validation

## Aggregate Recovery Results

| Gate | Aggregate result | Authority |
| --- | --- | --- |
| Corrected physical transaction | one completed run; one immutable ledger | physical code authority remains `e649e6ed` |
| Wrapper recovery | RED/GREEN isolated-Git regression passed | wrapper repair is retention logic only |
| Retained evidence | exact two regular leaves, marker, canonical schema, closed assertions, privacy, and provenance gates passed | one evidence-only commit follows the wrapper fix |
| Deterministic current-tree suite | 132 core tests, 21 host tests, and 1 browser test passed | recovery, parser/join, Phoenix authority, and support parity |
| Support and planning parity | requirements, roadmap, state, renderer, and generated guide agree | one first-adopter flow on one recorded iOS runtime line |

## Scope and Privacy

- Durable records contain only commit hashes, stable identifiers, aggregate counts, closed outcomes, and topology relationships.
- The independent verifier remains required authority. This file does not replace `162-VERIFICATION.md`.
- TODO-002 remains open. Android, background or generic sync, generic storage, multiple islands, simulator substitution, and every-iPhone coverage remain non-claims.

