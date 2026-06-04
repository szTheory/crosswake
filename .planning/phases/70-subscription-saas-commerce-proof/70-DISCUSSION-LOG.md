# Phase 70: Subscription SaaS Commerce Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 70-subscription-saas-commerce-proof
**Areas discussed:** Proof lane architecture, backend authority boundary, provider facade and restore semantics, Paywall UI/UX and DX

---

## Proof Lane Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse Phase 34 + Phase 48 tests only | Cheapest, but does not prove Phase 70's combined SaaS corridor. | |
| Single new integrated ExUnit proof module | Product-shaped proof over real contracts, inbox, projection, provider facade, and authority fence. | ✓ |
| Phoenix/LiveView E2E proof | Strong user-journey feel, but starts server/runtime machinery and weakens hermeticity. | |
| Broad full-suite lane | Catches unrelated regressions, but buries Phase 70 signal. | |
| Provider sandbox/device required lane | Tests real environments, but violates PROOF-01 hermeticity. | |

**User's choice:** User requested all areas be researched with subagents and asked for one-shot cohesive recommendations so they would not need to choose.
**Notes:** Recommended path is a new `phase70_subscription_saas_commerce_proof_test.exs` plus a Phase 70 workflow with merge-blocking hermetic and advisory provider/device jobs.

---

## Backend Authority Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Keep pure projection + stronger negative tests | Matches current evidence-only and projection-gate contracts. | ✓ |
| Richer fake backend verifier | Provider-shaped but hermetic verifier that emits authority only after backend verification. | ✓ |
| Ecto-backed state | Production-realistic but too much starter-app/backend scope for this phase. | |
| Event/outbox state | Useful future audit/reconciliation model but too broad for Phase 70. | |

**User's choice:** One-shot recommendation requested.
**Notes:** Use existing pure projection as the floor and add a richer example-host fake backend verifier only if needed for adversarial provider lifecycle fixtures. Ecto/outbox remain deferred.

---

## Provider Facade And Restore Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Mock-only corridor | Fast and hermetic, but not enough to prove provider restore identity. | |
| Configured provider facade | Fits existing behaviour and app-env pattern; keeps provider vocabulary fenced. | ✓ |
| Explicit dual-provider matrix | Catches StoreKit/Play purchase and restore drift without making provider proof real. | ✓ |
| Scenario DSL / fixture API | Good for repeated future scenarios, but risks becoming a fake commerce framework. | |

**User's choice:** One-shot recommendation requested.
**Notes:** Keep `StorefrontAdapter`/`ProviderAdapterStorefront`, add StoreKit purchase/restore and Play Billing purchase/restore proof rows, and avoid Stripe/RevenueCat/Paddle adapter vocabulary.

---

## Paywall UI/UX And DX

| Option | Description | Selected |
|--------|-------------|----------|
| Keep paywall unchanged, proof-only | Lowest risk but too sparse for Phase 70's UI hint. | |
| Polish existing Paywall LiveView states | Best fit; improves `:stale`, `:pending`, `:denied`, and `:granted` without creating a product template. | ✓ |
| Add subscription/account status surface | Useful only as a narrow read-only entitlement snapshot block. | ✓ |
| Add route-policy/runtime owner badges | Strong DX if secondary and compact. | ✓ |

**User's choice:** One-shot recommendation requested.
**Notes:** Polish the existing Paywall LiveView, add a compact backend entitlement status block and secondary proof posture row, ensure accessible status updates, and avoid full account-management/cancellation/payment surfaces.

---

## The Agent's Discretion

- Exact proof helper names, fixture naming, and whether the richer verifier is a new module or an extension of `MockBackend`.
- Exact workflow job names and whether Phase 34/48 regressions run as separate context steps.
- Exact Paywall LiveView layout within the locked UI-SPEC constraints.

## Deferred Ideas

- Ecto-backed persisted reconciliation/projection.
- Generic outbox/event-sourcing workflow.
- Full subscription account portal.
- Real provider/device/sandbox merge gate.
- Third-party billing aggregator adapters.
