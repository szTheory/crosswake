# Project Research: Stack Additions For v3.2 Commerce And Entitlement Seams

**Milestone:** v3.2 Commerce And Entitlement Seams
**Date:** 2026-05-27

## Summary

Crosswake already has core commerce vocabulary from Phase 13: `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence`. The stack work for v3.2 should avoid adding a billing engine to core. It should make the existing seam operational through Phoenix-owned behaviours, generated/example integration points, native corridor declarations, support truth, and proof lanes.

## Platform Findings

### Apple StoreKit

- New Apple in-app purchase work should target the Swift-based StoreKit In-App Purchase API when platform baselines allow it; Apple's original receipt API is deprecated.
- Apple provides App Store-signed transaction and subscription data in JWS form, and the App Store Server API lets a backend request transaction history and subscription status independent of whether the app is installed.
- StoreKit can help an app determine current entitlements locally, but Crosswake should continue treating that as device evidence unless a Phoenix backend verifies and projects entitlement truth.

Sources:
- https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases
- https://developer.apple.com/documentation/storekit/in-app-purchase
- https://developer.apple.com/documentation/appstoreserverapi
- https://developer.apple.com/documentation/storekit/validating-receipts-with-the-app-store

### Google Play Billing

- Google Play Billing pushes a similar shape: native Billing Library launches purchase flows and emits purchase tokens; backend verification and entitlement updates are strongly recommended before benefits are granted.
- Pending purchases, subscription lifecycle changes, and out-of-app purchase changes require backend reconciliation through purchase tokens, Google Play Developer API calls, and Real-time Developer Notifications.
- Acknowledgement is part of the provider workflow, not Crosswake core entitlement authority.

Sources:
- https://developer.android.com/google/play/billing/
- https://developer.android.com/google/play/billing/integrate
- https://developer.android.com/google/play/billing/backend
- https://developer.android.com/google/play/billing/lifecycle/subscriptions
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get

## Stack Additions To Consider

| Surface | Classification | Notes |
|---------|----------------|-------|
| Core commerce route declarations | `core` | Route policy should expose `commerce` ownership/corridor truth without provider identifiers. |
| Commerce behaviour callbacks | `core` | Existing `Crosswake.Commerce` callbacks need operational host examples and failure shapes. |
| Reconciliation inbox/projection example | `example/docs-only` or `companion-ready` | Useful to prove host-owned authority without shipping a persistence framework. |
| Native storefront command/event contracts | `companion` by default | StoreKit/Play Billing loops need native SDKs, review guidance, and rebuild truth. |
| Provider adapters | `companion` | Apple, Google, RevenueCat, Accrue, or other adapters should not enter core in v3.2. |
| Review/test-account playbooks | `example/docs-only` | Must be public support truth, not implied runtime support. |

## Recommendation

Use v3.2 to bridge the gap between Phase 13's vocabulary and a usable commerce corridor:

- core: declarations, contract shapes, denial/fallback semantics, host behaviour examples, manifest/support truth
- companion-ready: adapter boundary specifications and native corridor contracts
- example/docs-only: sandbox/reviewer playbooks and a minimal Phoenix reconciliation projection
- defer: real StoreKit/Play Billing adapters, storefront-specific purchase UIs, and broad provider support claims
