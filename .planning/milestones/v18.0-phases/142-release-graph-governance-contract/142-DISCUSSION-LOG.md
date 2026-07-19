# Phase 142: Release Graph & Governance Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 142-Release Graph & Governance Contract
**Areas discussed:** phase boundary after worktree drift, release path-gate contract, release-as cleanup timing, proof surface, developer/operator UX

---

## Phase Boundary After Worktree Drift

| Option | Description | Selected |
|--------|-------------|----------|
| Strict RELG-only context | Keep Phase 142 mapped only to RELG-01..03 and defer all spillover to later phases. | |
| Bundled v18 release-integrity slice | Document the current broad worktree as one coherent release-ops slice while preserving per-requirement ownership. | x |
| Split/rehoming artifacts before planning | Perform git/file surgery so each current artifact belongs to one phase before planning continues. | |

**User's choice:** User asked to consider all gray areas and provide a one-shot recommendation.
**Notes:** Subagent research recommended the bundled slice for this dirty worktree. The context preserves the work while requiring phases 144-146 to verify their own requirements later.

---

## Release Path-Gate Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Ban aggregate `releases_created` everywhere downstream | Simplest grep-style policy, but forbids harmless high-level summaries. | |
| Ban aggregate only on publish jobs | Protects irreversible publish jobs, but leaves proof/cleanup/recovery able to cascade from unrelated releases. | |
| Exact gates for all behavioral jobs | Use path/component gates for publish, proof, cleanup, recovery, and mirror jobs; allow aggregate only for non-destructive reporting. | x |

**User's choice:** User deferred to research-backed recommendation.
**Notes:** Release Please documents both aggregate and exact outputs. Crosswake should keep the aggregate output available but never use it for behavior.

---

## Concurrency Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| `cancel-in-progress: false` only | Protects running jobs but leaves pending runs replaceable under current GitHub Actions semantics. | |
| `cancel-in-progress: false` plus `queue: max` | Protects running jobs and lets pending runs queue instead of replacing each other. | x |
| No workflow concurrency | Avoids replacement semantics but permits overlapping release/publish runs. | |

**User's choice:** User deferred to research-backed recommendation.
**Notes:** Official GitHub Actions docs now document `queue: max`. Current workflow has `cancel-in-progress: false` but not `queue: max`, so this is an implementation gap for RELG-02.

---

## Release-As Cleanup Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Cleanup after publish success | Fast and matches the current wiring, but cleanup PR can appear while clean-room proof failed. | |
| Cleanup after publish plus proof success | Cleanup PR means the exact published artifact was proven consumable. | x |
| Manual-only cleanup | Maximum human control but reintroduces the recurring release-as footgun. | |

**User's choice:** User deferred to research-backed recommendation.
**Notes:** Clean-room proof is part of Crosswake's release truth surface. Cleanup should wait for the released component's publish and proof success, with skipped unreleased components allowed.

---

## Proof Surface For Release Workflow Integrity

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight semantic string/job-block scanner | Fast, deterministic, no new dependency, and targeted to Crosswake-specific invariants. | x |
| Structured YAML parser | Better traversal, but adds a dependency and still does not understand GitHub Actions expression semantics. | |
| GitHub Actions tooling such as `actionlint` or `act` | Useful syntax/expression/lint support, but cannot prove Crosswake-specific Release Please gate intent. | |

**User's choice:** User deferred to research-backed recommendation.
**Notes:** Keep the ExUnit-owned scanner as the primary proof and harden it with semantic check IDs and negative controls. Add pinned `actionlint` only as an additive lane if syntax mistakes start escaping.

---

## Developer And Operator UX

| Option | Description | Selected |
|--------|-------------|----------|
| CI-only implementation details | Keep release safety hidden inside workflow YAML and logs. | |
| Mix tasks, named proofs, and actionable copy | Treat release automation, status, doctor, issues, and JSON/text output as product surface. | x |
| Graphical dashboard | Build a UI surface for release state. | |

**User's choice:** User asked to consider UI/UX if applicable.
**Notes:** No graphical UI is needed for Phase 142. UX applies to CLI output, GitHub issue/PR copy, docs, and JSON. Brand guidance says calm, specific, actionable, with `[crosswake]` prefixes where appropriate.

---

## Claude's Discretion

- Selected all gray areas for analysis because the user explicitly asked to "discuss/consider all".
- Used subagent research for four independent gray areas.
- Consulted local `prompts/` guidance and the current `brandbook/BRAND-SPEC.md`.
- Checked current official GitHub Actions, Release Please, Hex, Mix, actionlint, Changesets, Lerna, and Nx docs before finalizing recommendations.

## Deferred Ideas

- Release Please major upgrade.
- Structured YAML parser.
- Live release rehearsal automation beyond the current proof lane.
- Graphical release dashboard.
- Product integrations unrelated to release integrity.
