# Project Research: Feature Shape For v3.2 Commerce And Entitlement Seams

**Milestone:** v3.2 Commerce And Entitlement Seams
**Date:** 2026-05-27

## Table Stakes

### Commerce Route Contract

- Phoenix teams can declare commerce-sensitive routes that distinguish pricing/paywall presentation from storefront-owned purchase loops.
- Route policy can require commerce capabilities without implying that the bridge owns entitlement truth.
- Manifest/support output names missing commerce prerequisites and native rebuild requirements.

### Paywall And Purchase Intent

- Phoenix can issue a typed `paywall_entry` with pricing/features display metadata.
- A user purchase action becomes a `purchase_intent` with correlation, entry/product identity, and expected native/provider corridor.
- Native/storefront confirmation remains explicit native-screen or companion territory unless the operation is a narrow one-shot sheet.

### Restore And Reconciliation

- Restore is modeled as an explicit `restore_intent`, not as a generic "refresh state" action.
- Device callbacks, server notifications, support actions, and provider API results feed one `reconciliation_evidence` path.
- Reconciliation creates or updates a backend-owned `entitlement_snapshot`.

### Entitlement Snapshot

- The snapshot separates authority state, access state, freshness, effective dates, and evidence metadata.
- Stale or missing evidence must not silently grant access or silently deny access.
- Pending, grace, billing retry, revoked, refunded, expired, and canceled-at-period-end states need explicit projection vocabulary.

### Support And Review Truth

- Commerce support docs name which flows are core, companion, native-screen required, example/docs-only, or deferred.
- Doctor/support matrix output distinguishes missing backend reconciliation, missing native commerce adapter, unsupported platform, and unverified proof lanes.
- Reviewer/storefront guidance explains test accounts, sandbox setup, restore behavior, and fallback behavior.

## Differentiators

- Phoenix-first commerce model where server truth is not an afterthought.
- Capability/routing vocabulary that prevents provider-specific SDK details from leaking into core route policy.
- Honest native corridor classification for purchase loops rather than pretending WebView fallback is valid for digital goods.
- Proof posture that can grow from hermetic contract tests into advisory StoreKit/Play Billing lanes.

## Anti-Features

- No universal billing engine in `crosswake` core.
- No device-local entitlement source of truth.
- No generic plugin bus for arbitrary provider callbacks.
- No offline purchase replay that grants permanent access.
- No silent fallback from native purchase prerequisites to unsafe web checkout.
