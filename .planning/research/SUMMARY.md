# Research Summary: v3.2 Commerce And Entitlement Seams

**Date:** 2026-05-27

## Stack Additions

- Keep `crosswake` core focused on normalized commerce declarations, route ownership, manifest/support truth, host behaviours, and denial/fallback semantics.
- Treat native storefront SDK loops and provider verification clients as companion or example/docs-only surfaces until an adapter milestone explicitly chooses them.
- Use the existing Phase 13 commerce modules as substrate, not as new work.

## Feature Table Stakes

- Commerce route/corridor declarations.
- Paywall entry and purchase/restore intent flow.
- Backend-owned reconciliation inbox and entitlement projection example.
- Rich entitlement snapshot lifecycle vocabulary.
- Doctor, support matrix, reviewer, and storefront guidance.
- Split proof posture: hermetic contract proof is merge-blocking; StoreKit/Play Billing environment proof is advisory.

## Watch Out For

- Do not turn device callbacks into entitlement authority.
- Do not leak raw StoreKit/Play Billing states into core public vocabulary.
- Do not imply web checkout fallback for unsupported native commerce.
- Do not re-solve Phase 13's vocabulary work; v3.2 should make it usable and provable.

## Primary Sources Consulted

- Apple StoreKit In-App Purchase documentation: https://developer.apple.com/documentation/storekit/in-app-purchase
- Apple App Store Server API: https://developer.apple.com/documentation/appstoreserverapi
- Apple receipt validation guidance: https://developer.apple.com/documentation/storekit/validating-receipts-with-the-app-store
- Google Play Billing integration: https://developer.android.com/google/play/billing/integrate
- Google Play backend integration: https://developer.android.com/google/play/billing/backend
- Google Play subscription lifecycle: https://developer.android.com/google/play/billing/lifecycle/subscriptions
