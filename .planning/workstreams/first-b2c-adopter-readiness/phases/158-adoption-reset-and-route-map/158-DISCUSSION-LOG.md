# Phase 158: Adoption Reset and Route Map - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 158-adoption-reset-and-route-map
**Areas discussed:** Inventory completion, Route-row privacy and granularity,
Capability/support truth migration, Context routing and privacy enforcement

---

## Inventory Completion

| Option | Description | Selected |
|--------|-------------|----------|
| Block Phase 158 until sanitized concrete rows exist | Maximizes literal completeness but lets an external adopter input stall the bounded infrastructure reset. | |
| Close on known-surface defaults plus explicit unknowns | Completes durable Crosswake policy truth while preserving missing adopter facts as visible blockers. | ✓ |
| Close on a contract/template plus external inventory | Keeps git sparse but weakens durable auditability and can lose context across systems. | |

**User's choice:** Approved the research-backed recommendation set as a coherent package.
**Notes:** Policy-contract completeness and adopter-instance completeness are separate. TODO-002
remains open; unknown inputs are `unknown_blocking`; external-host/device support claims remain
blocked until concrete sanitized rows exist. Web-only Alpha triggers a pause after the bounded
reset.

---

## Route-Row Privacy and Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Concrete-path rows | Precise for proof and authority but risky if paths or product taxonomy are copied unsanitized. | |
| Route-family rows | Compact and initially private but too coarse for route-specific auth, replay, media, fallback, and disablement. | |
| Layered family defaults plus concrete rows | Safe defaults reduce repetition while sanitized concrete route patterns preserve route-local authority. | ✓ |

**User's choice:** Approved the research-backed recommendation set as a coherent package.
**Notes:** Require explicit per-route safety fields; use closed status vocabulary; permit only
low-cardinality categories and postures; keep raw data, exact host configuration, and identifying
taxonomy out of durable artifacts.

---

## Capability/Support Truth Migration

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `v20_implication` | No churn, but keeps a stopped milestone as the current conceptual axis. | |
| Hard rename | Clean final shape, but abruptly breaks observable row/map consumers. | |
| Additive compatibility migration | Makes `adoption_implication` canonical while accepting the legacy field through one checked normalizer. | ✓ |
| Neutral roadmap/support vocabulary | More timeless, but weakens the current first-adopter forcing function and public vocabulary. | |

**User's choice:** Approved the research-backed recommendation set as a coherent package.
**Notes:** Reject conflicting dual values; canonical rows use the new field; legacy map input stays
compatible for one window; generated guide wording remains “Adoption implication.”

---

## Context Routing and Privacy Enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Curated matrix plus environment-provided private terms | Small, explicit, and idiomatic for the one-day phase when paired with drift checks. | ✓ |
| Automatic active-surface discovery | Finds new files but creates historical/archive false positives and opaque exclusions. | |
| Hash-only term registry | Avoids storing raw terms but cannot discover an arbitrary leak without comparable runtime input. | |
| External secret scanner as primary control | Mature for credentials but poorly matched to adopter identity and proprietary taxonomy. | |

**User's choice:** Approved the research-backed recommendation set as a coherent package.
**Notes:** Public CI proves generic rules and a synthetic canary. A privileged/local lane receives
real private terms, never prints them, and reports only rule ID plus path. Routing distinguishes
durable git, public guides, codename-only execution issues, host configuration, secrets, and
forbidden raw data.

---

## the agent's Discretion

- Exact internal helper/module boundaries for the routing matrix and implication normalization.
- Exact serialization of the closed inventory statuses.
- Test fixture names and the compatibility-window removal note.
- Small implementation details that preserve the approved privacy, authority, unknown-state, and
  proof-promotion rules.

## Deferred Ideas

- External credential-scanner services remain optional later defense-in-depth.
- Generic inventory frameworks, dashboards, new product UI, generic sync/storage, native-control
  breadth, and Android expansion remain outside Phase 158.
