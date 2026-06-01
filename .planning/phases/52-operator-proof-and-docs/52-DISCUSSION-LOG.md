# Phase 52: Operator Proof and Docs-Contract Locks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 52-Operator Proof and Docs-Contract Locks
**Areas discussed:** Proof lane topology, Docs-contract lock shape, Drift failure ergonomics, Coverage boundary

---

## Proof Lane Topology

| Option | Description | Selected |
|--------|-------------|----------|
| Single aggregate workflow | One required Phase 52 workflow/job runs all proof; simple branch protection but coarser failure locality. | |
| Extend existing per-surface workflows | Add Phase 52 locks to inspection, doctor, support/docs workflows; local ownership but fragmented PROOF-01/02 contract. | |
| Dedicated layered workflow | New Phase 52 workflow with merge-blocking hermetic operator proof plus advisory native/device/provider visibility. | ✓ |
| Mix aliases only | Excellent local DX but insufficient as the CI contract by itself. | |

**User's choice:** User asked the agent to research all options and make a cohesive one-shot recommendation.
**Notes:** Selected dedicated layered workflow because it preserves Crosswake's hermetic/advisory split while making v3.6 operator truth discoverable as one phase proof lane.

---

## Docs-Contract Lock Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Byte-identical generated docs | Strong for canonical generated tables, brittle for authored prose. | |
| Anchor/vocabulary parity tests | Good for public non-claims and authored docs, weak as the only structural lock. | |
| Live-code assertions across guides | Strong for statuses, denial reasons, action classes, promotion rules, and doctor codes. | |
| JSON schema/golden snapshots | Strong for machine contracts if volatile fields are normalized. | |
| Hybrid generated-table + prose assertions | Byte-lock generated truth, live-code-lock vocabularies, normalized JSON-lock machine output, and semantic-lock authored prose. | ✓ |

**User's choice:** User asked for one perfect recommendation set.
**Notes:** Selected hybrid approach because Crosswake already has generated support-matrix parity and authored guide tests; Phase 52 should strengthen those patterns without making all prose brittle.

---

## Drift Failure Ergonomics

| Option | Description | Selected |
|--------|-------------|----------|
| Raw ExUnit asserts only | Idiomatic and simple, but failures force maintainers to infer support-truth drift manually. | |
| Helper assertions with stable proof IDs | Domain-specific failure messages with ids, subjects, expected source, drift, guide/module path, and remediation. | ✓ |
| Generated drift reports | Useful CI artifact, but should not become a second contract. | |
| Snapshot diffing and annotations | Useful presentation layer for docs/JSON diffs, risky if used as the source of truth. | |

**User's choice:** User asked the agent to research and decide.
**Notes:** Selected stable id/domain helper assertions as the merge-blocking source of truth, with reports/summaries/diffs as optional renderers.

---

## Coverage Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| v3.6 operator surfaces only | Tight scope but risks missing historical dependencies that operator truth relies on. | |
| Aggregate all historical proof | Broad story but high churn, slow CI, and scope creep into settled milestones. | |
| Cross-milestone smoke rollup | Useful sentinel, but not deep enough for PROOF-01/PROOF-02. | |
| Requirement-mapped selective rollup | Core v3.6 surfaces plus only historical dependencies required by PROOF-01/PROOF-02. | ✓ |

**User's choice:** User asked the agent to make the decision.
**Notes:** Selected requirement-mapped selective rollup to keep Phase 52 scoped while still catching denial/support/docs drift that crosses phase boundaries.

---

## the agent's Discretion

- Exact file layout, Mix alias names, workflow job names, normalized fixture shape, and stable proof id names are planner discretion.
- Planner should bias toward existing ExUnit/Mix patterns and avoid new dependencies unless schema validation materially improves the machine contract.

## Deferred Ideas

- Provider/device/storefront proof promotion remains future adapter work.
- Full Sigra, Chimeway delivery, and standalone shell package release choreography remain future milestone work.
