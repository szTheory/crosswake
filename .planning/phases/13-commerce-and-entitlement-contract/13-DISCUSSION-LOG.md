# Phase 13 Discussion Log

**Date:** 2026-05-19
**Mode:** Full-area discussion with parallel research agents

## Areas Discussed

### 1. Commerce vocabulary shape
- Recommended: five typed `core` surfaces rather than a generic event bus or a monolithic commerce session object.
- Locked direction:
  - `paywall_entry`
  - `purchase_intent`
  - `restore_intent`
  - `entitlement_snapshot`
  - `reconciliation_evidence`
- Main rationale:
  - Best fit with current capability-family vocabulary
  - Most idiomatic for Elixir/Phoenix `%Struct{}` and Ecto-backed contracts
  - Strongest least-surprise posture for backend-owned truth

### 2. Entitlement snapshot semantics
- Recommended: dual-lane snapshot separating backend authority from device/store evidence.
- Locked direction:
  - separate `authority_state` and `access_state`
  - include freshness and timing fields
  - treat pending restore/purchase as reconciliation states, not access grants
- Main rationale:
  - avoids boolean entitlement drift
  - preserves backend truth while still supporting good UX
  - keeps provider churn out of the core public contract

### 3. Reconciliation flow and event boundaries
- Recommended: backend reconciliation inbox plus authoritative entitlement projection.
- Locked direction:
  - one ingestion path for device evidence, webhooks, and manual support inputs
  - backend-owned idempotency keys
  - host-owned verification workers and entitlement projection
- Main rationale:
  - strongest operator clarity and auditability
  - best fit with Phoenix/Ecto/Oban patterns
  - consistent with Crosswake’s Phase 4 reconciliation posture

### 4. Native-screen and companion boundaries
- Recommended: explicit native commerce corridor for storefront-sensitive purchase loops, with Phoenix-owned surrounding account and entitlement surfaces.
- Locked direction:
  - Phoenix owns pricing, subscription status, FAQ, account history, and post-reconciliation screens
  - native screens own storefront-sensitive purchase and restore choreography
  - companions own provider SDK bindings and carry rebuild-required truth
- Main rationale:
  - strongest route-owner honesty
  - best store-policy realism
  - clearest support and rebuild story

## Shift-Left Defaults

- Keep struct naming, denial atoms, fallback wording, and evidence-vs-authority semantics as GSD defaults.
- Keep backend-owned reconciliation, companion classification, and native-corridor bias as GSD defaults.
- Re-ask only when a proposal materially changes:
  - route ownership
  - entitlement authority
  - package boundary
  - support truth

## Remaining High-Impact Choices

- Whether a specific app wants a thin semantic paywall trigger into native UI or a fuller dedicated native commerce corridor.
- Whether post-purchase account and subscription management stays Phoenix-owned or expands into a more native-heavy commerce module for subscription-first products.

## Deferred Ideas

- Full provider adapters in core
- Hosted or generic billing-engine abstractions
- Runnable example-host commerce lanes before companion/support/proof posture is ready
- Offline purchase replay or device-authoritative entitlement mutation

