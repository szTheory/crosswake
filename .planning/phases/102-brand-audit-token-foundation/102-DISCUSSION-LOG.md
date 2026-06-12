# Phase 102: Brand Audit & Token Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 102-brand-audit-token-foundation
**Areas discussed:** Palette remediation posture, Token naming & structure, Audit boldness
**Mode:** Advisor (minimal_decisive) — 3 parallel gsd-advisor-researcher agents, synthesized into one coherent recommendation set per the user's research-then-recommend instruction

---

## Palette remediation posture

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal hue-preserving hex shift | Add Stone 600 #756D63 as muted-text token; narrow Stone 500 to subtle/large-text roles; encode Wake 500 / Mist 200 restrictions in DTCG $description | ✓ |
| Role reassignment only | Keep all hexes; demote Stone 500 — leaves no passing muted-text token; adopter misuse near-certain (Primer fg.muted lesson) | |
| Full scale expansion (USWDS/Radix-style steps) | Structural contrast guarantees — over-engineering for one failing pair; violates no-thrash | |

**User's choice:** Lock all three recommendations (single confirmation).
**Notes:** Researcher computed the real matrix: only Stone 500/Foam 50 (4.09:1) truly fails as a text pair; Brass 700 (4.74:1) and Wake 700 (4.85:1) pass — suspected failures cleared. Wake 500 (2.95:1) and Mist 200 (1.35:1) on light are role-definition issues.

---

## Token naming & structure

| Option | Description | Selected |
|--------|-------------|----------|
| Flat `--cw-` primitive-only | Zero migration, but no semantic layer → grep-replace churn, dark mode impossible | |
| `--cw-` two-tier DTCG + generator | Primitive (internal) → semantic (~23 public tokens incl. runtime.*); compile-tokens.js <80 LOC; committed generated tokens.css; prefers-color-scheme + [data-theme] theming | ✓ |
| `--crosswake-` three-tier with component tokens | Verbose; component tokens flagged anti-feature; breaks shipped app.css names | |

**User's choice:** Lock all three recommendations (single confirmation).
**Notes:** Continuity with the 16 shipped `--cw-*` variables in examples/phoenix_host resolved explicitly: keep prefix, no breaking change.

---

## Audit boldness (typography / palette latitude)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep Space Grotesk + mandatory wake-cuts rider | Elixir/devtools space has near-zero Space Grotesk saturation; w/k/g letterforms are the best cut material; font question closes at 102 ratification | ✓ |
| Switch to DM Sans | Cleaner but conventional w/k = less distinctive cuts; only warranted if quirk reads "AI startup" in context — evidence doesn't support | |
| Switch to Geist | Vercel-brand confusion; same "LLM-default" cluster; displaces JetBrains Mono | |

**User's choice:** Lock all three recommendations (single confirmation).
**Notes:** Honest finding recorded: Space Grotesk is named in 2026 "LLM-default design" criticism — counterweighed by zero ecosystem saturation and the mandatory-customization rider (wordmark must not be typesettable in unmodified Space Grotesk).

## Claude's Discretion

- Contrast tooling (area 4 from initial presentation): user accepted recommendation implicitly by selecting only the other three for discussion — zero-dep Node `brandbook/tools/contrast.mjs`, matrix as AUDIT.md appendix
- AUDIT.md verdict calls within the locked latitude policy; copy-block wording; token file organization; typography/spacing/radius token values from brand book §9/§13

## Deferred Ideas

- NORM-01: normalize v8.0 generator templates + example CSS onto tokens.css (future milestone; 102 flags drift only)
- Multi-library suite brand rollout — audit notes implications only
- Landing page build — blueprint only (AUDIT.md §11)
