# Phase 51: Support Matrix and Native Rebuild Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 51-Support Matrix and Native Rebuild Truth
**Areas discussed:** Support status vocabulary, native rebuild taxonomy, advisory promotion and docs guardrails

---

## Support Status Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Split canonical axes | Keep support status, proof class, severity, rebuild requirement, denial, and condition status separate. | Yes |
| Unified lifecycle status | Collapse surface state into a concise `ready/degraded/blocked/deferred`-style lifecycle. | |
| Hybrid split axes plus derived conditions | Keep raw axes canonical and expose condition-like records as derived CI/support views. | Yes |

**User's choice:** Discuss/consider all and produce one cohesive recommendation.
**Notes:** Advisor research recommended split canonical axes as the source of truth, with derived condition-like records only as wrappers. This avoids false "green" support claims and matches Crosswake's Phase 49/50 direction.

---

## Native Rebuild Taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Route-derived only | Compute rebuild/actionability entirely from route inspection rows. | |
| Two-axis change/action contract | Keep `change_class` for what changed and add `action_class` for who must do what. | Yes |
| Ledger-first matrix | Maintain an explicit curated support handbook table with route data only as annotation. | |

**User's choice:** Discuss/consider all and produce one cohesive recommendation.
**Notes:** Advisor research recommended the two-axis contract. Route-derived truth is necessary but misses non-route release surfaces such as shell templates, compatibility windows, native dependencies, provider SDKs, and docs-only claims.

---

## Advisory Promotion And Docs Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Criteria-as-code promotion contract | Add typed promotion rules per claim with evidence, freshness, platform/provider, docs, rebuild, and demotion criteria. | Yes |
| Governance-first promotion | Use maintainer checklist, ADR, changelog gate, and minimal new schema. | |
| Dual-track advisory/merge-blocking contract | Keep environment-sensitive lanes advisory until narrow promotion bundles harden. | Yes |

**User's choice:** Discuss/consider all and produce one cohesive recommendation.
**Notes:** Advisor research recommended criteria-as-code as the primary contract, implemented with lane separation for provider/device/storefront proof. This gives Phase 52 a machine-readable target for docs-contract and proof locks.

---

## the agent's Discretion

- Exact module and struct names.
- Exact `action_class` labels, if they preserve the subject/action split.
- Exact promotion thresholds per claim, with a conservative bias.
- Exact support guide layout, as long as generated/canonical truth stays visible.

## Deferred Ideas

None.
