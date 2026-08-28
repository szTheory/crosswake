# Phase 147: Arc, Fixture, and Showcase Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-09
**Phase:** 147-Arc, Fixture, and Showcase Foundation
**Areas discussed:** Showcase hub shape, Fixture/reset ownership, Route-owner/support labels, First-run discovery path

---

## Showcase Hub Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Make `/` the full polished hub | Best first-run DX; current launcher already opens `/`; strongest fit for SHOW-01/04. Must avoid marketing-only clutter and overclaiming. | yes |
| Create `/showcase` and link/redirect from `/` | Clear namespace and easier isolation, but adds recall burden and splits the first-run message. | |
| Keep `/` lightweight and use route-specific hubs | Keeps lanes focused, but repeats the current problem where value is scattered across routes/docs. | |

**User's choice:** Discuss/consider all; produce a research-backed, one-shot recommendation.
**Notes:** Recommendation is to make `/` the polished showcase hub, with diagnostics/proof routes one level deeper.

---

## Fixture and Reset Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Keep per-lane fixture modules plus `priv/repo/seeds.exs` only | Lowest churn, but no single SHOW-02/PROOF-01 reset contract and higher drift/duplication risk. | |
| Add example-host-local `Showcase.Fixtures` and `Showcase.Reset` orchestrator | One deterministic contract for CI and DX while preserving lane-local ownership. Must stay out of core and avoid becoming a fixture engine. | yes |
| Model real Ecto schemas for all showcase data now | More production-shaped but too broad for foundation phase; risks schema churn and fake maturity. | |
| Add thin reset task/endpoint wrapper only | Improves ergonomics but can hide fragmented ownership if not backed by a shared contract. | |

**User's choice:** Discuss/consider all; produce a research-backed, one-shot recommendation.
**Notes:** Recommendation is a local reset orchestrator that delegates to lane-owned fixtures/context APIs. Browser IndexedDB remains reset by browser/Playwright helpers.

---

## Route-Owner and Support Labels

| Option | Description | Selected |
|--------|-------------|----------|
| Hand-written visible badges per card | Fast and designer-friendly, but high drift and support-overclaim risk. | |
| Shared showcase metadata helper rendered by hub | Central vocabulary and reusable UI metadata, but can become a shadow source without verification. | |
| Derive labels directly from route policy/support matrix/manifest | Canonical truth, but raw manifest/support data is too implementation-facing for the hub. | |
| Hybrid curated metadata plus derived verification/enrichment | Product-facing labels stay clear while tests verify route/runtime/offline/capability truth. | yes |

**User's choice:** Discuss/consider all; produce a research-backed, one-shot recommendation.
**Notes:** Recommendation is curated visible text badges backed by route/manifest/support verification tests. Full derivation belongs to Phase 151 capability map work.

---

## First-Run Discovery Path

| Option | Description | Selected |
|--------|-------------|----------|
| Point launcher/docs primarily to the showcase now | Strong newcomer JTBD, but must not overclaim before lanes exist. | |
| Preserve old route-owner tour as proof path, add showcase as next step | Low disruption, but weak first impression. | |
| Split user-facing showcase from maintainer proof route-tour | Best audience fit: product-shaped first run while proof truth remains explicit. | yes |
| Expand Playwright route-tour to cover hub plus one path per lane in Phase 151 | Correct proof hardening later, but too broad for Phase 147 alone. | deferred |

**User's choice:** Discuss/consider all; produce a research-backed, one-shot recommendation.
**Notes:** Recommendation is product-shaped showcase first, maintainer proof path second, and full showcase route-tour expansion deferred to Phase 151.

---

## Claude's Discretion

- Exact module names, function component names, reset task naming, and test decomposition may be chosen by planner/executor as long as they preserve the locked decisions.
- Planner may choose LiveView vs controller-backed HEEx for the hub if implementation constraints require it, though LiveView is recommended.

## Deferred Ideas

- Full capability map and v20 Native Controls Pack 1 handoff remain Phase 151.
- Broad native controls, scanner/document capture, biometrics, NFC, location production APIs, live storefront/paywall SDK support, operator dashboard, and generic offline-sync productization remain future milestone scope.
