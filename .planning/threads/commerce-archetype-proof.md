---
slug: commerce-archetype-proof
title: Mocked storefront corridor + paywall archetype proof (v3.4 candidate)
status: completed
created: 2026-05-27
updated: 2026-05-29
resolution: Shipped as milestone v3.4 Commerce Archetype Proof (Phases 33-37) on 2026-05-29.
---

# Thread: Commerce archetype proof (ARCH-02)

## Goal

Turn the v3.2 commerce vocabulary into a runnable adopter lane. Today, adopters can *read* the commerce corridor contracts but cannot *copy* a working paywall_entry + purchase_intent + restore_intent + reconciliation_inbox lane. Close that gap using a **mocked / simulator storefront corridor** — does NOT require shipping StoreKit or Play Billing provider adapters.

Recommended sequencing: ship as **v3.4** after **v3.3 Release Readiness**.

## Context

*Created 2026-05-27 during post-v3.2 milestone-next-step assessment.*

Repo-grounded facts:

- v3.2 shipped commerce contract vocabulary: `Crosswake.Commerce.Contracts` defines `PurchaseIntent`, `RestoreIntent`, `EntitlementSnapshot` (6 lanes: authority, access, reconciliation, freshness, effective, evidence), `ReconciliationEvidence`, `CommerceEvent` (`lib/crosswake/commerce/contracts.ex:363`).
- v3.2 shipped reconciliation inbox structure (`lib/crosswake/commerce/reconciliation.ex:180`) and walkthrough docs (`guides/commerce.md:104-115`).
- **No live `paywall_entry` route exists** in `examples/phoenix_host/lib/crosswake_example/router.ex`. Commerce vocabulary is defined but not wired into a running adopter example.
- Phase 23 commerce proof lane (`test/crosswake/proof/phase23_commerce_support_proof_test.exs`) is hermetic; provider/storefront/device proof is advisory-only in `.github/workflows/phase23-proof.yml`.

The wedge: a Phoenix SaaS dev wanting to ship subscriptions today reads `guides/commerce.md`, sees the vocabulary, and has no concrete "copy this and you'll have a working paywall" example. Mocking a storefront corridor (no real Apple/Google integration) is enough to prove the lane end-to-end and document it adoptably.

## References

- `/Users/jon/projects/crosswake/lib/crosswake/commerce/contracts.ex` — entitlement snapshot, intent, evidence types
- `/Users/jon/projects/crosswake/lib/crosswake/commerce/reconciliation.ex` — reconciliation evidence ingestion
- `/Users/jon/projects/crosswake/guides/commerce.md` — layered guide with reviewer playbooks
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex` — where the paywall_entry route should land
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase23_commerce_support_proof_test.exs` — current hermetic proof
- `/Users/jon/projects/crosswake/.github/workflows/phase23-proof.yml` — split hermetic + advisory pattern
- `.planning/PROJECT.md` § Key Decisions — "Operationalize commerce as backend-owned seam before provider adapters" (2026-05-27)

## Next Steps

- Design mocked storefront corridor protocol: what's the shape of a `MockStorefront` adapter that consumes the v3.2 commerce contracts?
- Add `paywall_entry` route to `examples/phoenix_host/lib/crosswake_example/router.ex` with `commerce: :paywall_entry` policy.
- Add `purchase_intent` + `restore_intent` routes wired to MockStorefront.
- Implement a backend `EntitlementProjection` that converts mock storefront evidence → entitlement snapshot (re-using `Crosswake.Commerce.Reconciliation`).
- Add a merge-blocking proof test that drives the full lane: mock purchase → reconciliation evidence → snapshot → LiveView reflects entitlement.
- Update `guides/commerce.md` to walk through the new example end-to-end. Add docs-contract test to lock the walkthrough against the example.
- Advisory → hermetic promotion criteria: a real StoreKit/Play Billing adapter test that satisfies the 4-condition promotion_path documented in `phase23-proof.yml` would graduate this from mock to real provider proof — defer to v3.6 (provider adapters milestone).
- Blocked until `v3.3 Release Readiness` ships.
