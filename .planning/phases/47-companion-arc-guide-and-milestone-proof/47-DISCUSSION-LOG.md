# Phase 47: Companion Arc Guide And Milestone Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 47-companion-arc-guide-and-milestone-proof
**Areas discussed:** guide structure and narrative, docs-contract parity, milestone hermetic proof

---

## Guide Structure And Narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Single canonical arc | One long contract-first guide. Lowest churn and simplest docs-contract surface, but risks becoming dense and mixing tutorial/how-to/reference concerns. | |
| Diataxis-shaped sections inside one file | One canonical guide structured by reader intent: quick orientation, concepts, how-to/examples, reference/truth, non-goals. Stronger long-term DX without a file split. | ✓ |
| Index plus split companion pages | `companions.md` as a map plus per-companion pages. Scales later, but adds navigation/test surface before Phase 47 needs it. | |

**User's choice:** Discuss all and use subagent-backed recommendation-first synthesis.
**Notes:** Advisor research recommended one canonical guide organized by reader
intent. This preserves the Phase 47 standalone guide requirement while avoiding
per-companion file sprawl before the surface area justifies it.

---

## Docs-Contract Parity

| Option | Description | Selected |
|--------|-------------|----------|
| String anchors plus export guards | Tighten the current `assert content =~` pattern. Easy and idiomatic but catches only shallow drift. | |
| Matrix/doctor-derived parity assertions | Keep readable anchors while adding live-code set parity against support matrix, denial vocabulary, companion IDs, and exported modules/functions. | ✓ |
| Snapshot/fixture-style rendered truth block | Makes broad guide changes visible but risks snapshot-approval drift and weaker semantic intent. | |

**User's choice:** Discuss all and use subagent-backed recommendation-first synthesis.
**Notes:** Advisor research recommended semantic live-code parity with clear
ExUnit assertions. This matches Crosswake's docs-as-product-contract posture
better than keyword-only or snapshot-only tests.

---

## Milestone Hermetic Proof

| Option | Description | Selected |
|--------|-------------|----------|
| New aggregate workflow plus aggregate proof test | Clear single milestone check, but duplicates existing hermetic/advisory CI structure and increases env-bleed risk. | |
| Aggregate ExUnit proof folded into existing hermetic posture | Adds explicit milestone-level assertion while reusing existing proof commands and advisory separation. | ✓ |
| Rely only on current Phase 43/45 lanes | No CI churn, but does not satisfy the roadmap's milestone-level proof intent. | |

**User's choice:** Discuss all and use subagent-backed recommendation-first synthesis.
**Notes:** Advisor research recommended a small untagged
`phase47_companion_arc_test.exs` or equivalent that gets picked up by existing
hermetic lanes, plus only minimal workflow edits if needed.

---

## the agent's Discretion

- Exact guide headings are planner discretion if the one-file, reader-intent
  structure is preserved.
- Exact helper functions and assertion organization inside
  `companions_test.exs` are planner discretion.
- Exact CI hook is planner discretion, with a strong bias toward reusing
  existing hermetic commands instead of creating a duplicate `phase47-proof.yml`.

## Deferred Ideas

- Per-companion guide split.
- Real Rulestead snapshot adapter.
- Real Rindle adapter/transport/storage-provider integration.
- Full Sigra machinery.
- Chimeway seam and Threadline capstone.
