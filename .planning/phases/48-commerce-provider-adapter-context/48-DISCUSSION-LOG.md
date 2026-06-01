# Phase 48: Commerce Provider Adapter Context - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 48-commerce-provider-adapter-context
**Areas discussed:** Adapter Surface Shape, Provider Evidence Normalization, Purchase/Restore Choreography, Proof And Promotion Criteria, Reviewer And Support Truth

---

## Adapter Surface Shape

| Option | Description | Selected |
|--------|-------------|----------|
| First-party companion seams | `Crosswake.Companions.StoreKit` and `Crosswake.Companions.PlayBilling` implement provider seams around core commerce contracts and host-native coordinators. | yes |
| Native-shell adapter hooks only | iOS/Android host code emits normalized evidence into Phoenix endpoints with minimal Elixir API additions. | |
| Core-facing Elixir adapter behaviour | A core `Crosswake.Commerce.ProviderAdapter` behaviour abstracts provider implementations. | |

**User's choice:** Discuss and consider all; use subagent research and synthesize a cohesive recommendation.
**Notes:** Research favored first-party companion seams because they match v3.5 companion posture, keep provider SDK churn out of core, preserve typed Phoenix contracts, and make support/readiness/proof truth explicit.

---

## Provider Evidence Normalization

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal envelope plus conventions | Keep only current `ReconciliationEvidence` fields and document provider conventions. | |
| Provider-specific normalized structs mapped into envelope | StoreKit and Play Billing structs normalize provider identity, environment, signed proof, and event metadata into `ReconciliationEvidence`. | yes |
| Rich canonical event taxonomy | Add a broad closed canonical event model with required identity fields per event family. | |

**User's choice:** Discuss and consider all; use subagent research and synthesize a cohesive recommendation.
**Notes:** Research favored provider-specific structs with a small closed Crosswake event-kind vocabulary. This preserves strong typing and provider identity without turning core into a billing engine.

---

## Purchase/Restore Choreography

| Option | Description | Selected |
|--------|-------------|----------|
| One-shot intent/result evidence | Native returns a result/evidence envelope; backend reconciliation drives the final UI state. | |
| One-shot kickoff plus bounded lifecycle hints | Primary result/evidence handoff plus a small non-authoritative lifecycle-hint taxonomy for UX/recovery. | yes |
| Deep transaction event stream | Native forwards raw StoreKit/Play event streams to Phoenix/LiveView. | |

**User's choice:** Discuss and consider all; use subagent research and synthesize a cohesive recommendation.
**Notes:** Research favored bounded lifecycle hints with hard caps. Raw provider streams conflict with Crosswake's low-frequency bridge and backend-authority posture.

---

## Proof And Promotion Criteria

| Option | Description | Selected |
|--------|-------------|----------|
| Hermetic-only gate | Keep provider/device lanes advisory indefinitely. | |
| Simulator/SDK promotion only | Promote based on simulator/provider SDK unit coverage without sandbox/device requirements. | |
| Two-tier promotion | Merge-block deterministic adapter correctness; keep sandbox/device/storefront proof advisory until criteria pass. | yes |
| Full conformance gate | Require sandbox accounts, physical devices, and storefront/reviewer evidence for merge. | |

**User's choice:** Discuss and consider all; use subagent research and synthesize a cohesive recommendation.
**Notes:** Research favored the two-tier model because it preserves CI reliability and support honesty while allowing real adapter correctness to become merge-blocking.

---

## Reviewer And Support Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical-only truth | Generated support truth and strict non-claims, minimal reviewer guidance. | |
| Layered guide model | Generated canonical truth plus authored advisory reviewer playbooks bound to canonical fields. | yes |
| Checklist-driven readiness | Provider setup/readiness checklist ids surface through doctor and docs. | yes |
| Sample-app-centric guidance | Put most provider guidance in example-host notes. | |

**User's choice:** Discuss and consider all; use subagent research and synthesize a cohesive recommendation.
**Notes:** Research favored combining layered advisory reviewer guides with checklist-driven readiness metadata. Canonical support matrix remains the claim source.

---

## the agent's Discretion

- Exact module names and native file layout remain planner discretion.
- Exact lifecycle-hint and event-kind names remain planner discretion if they stay closed, provider-neutral, and non-authoritative.
- Exact promotion thresholds remain planner discretion, with a fail-closed bias toward advisory.
- Exact guide layout remains planner discretion if canonical truth, advisory playbooks, and docs-contract locks stay separate.

## Deferred Ideas

- RevenueCat adapter.
- Physical-device/storefront conformance as a merge-blocking gate.
- Offline purchase replay or local-first entitlement mutation.
