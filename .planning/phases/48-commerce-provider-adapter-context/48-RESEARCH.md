# Phase 48: Commerce Provider Adapter Context - Research

**Researched:** 2026-06-01
**Status:** Complete

## Research Question

What do we need to know to plan first-party StoreKit and Play Billing adapter seams without violating Crosswake's backend-owned commerce authority boundary?

## Platform Findings

### StoreKit / App Store

- Apple exposes StoreKit as the in-app purchase framework and App Store Server API / Notifications as the server-side transaction verification and lifecycle surface.
- `originalTransactionId` is the stable purchase lineage key for App Store Server API calls. Apple notes it can come from the app, notifications, or receipts, and StoreKit 2 exposes it as `Transaction.originalID`. Use this as Crosswake's StoreKit `provider_reference`.
- StoreKit transaction IDs and App Store Server Notification identifiers are event-instance evidence, not subject authority. Use them for `evidence_ref` or integrity provenance.
- App Store Server API and StoreKit purchase APIs use JWS-signed transaction/subscription status payloads. Preserve JWS or digest provenance in normalized evidence; do not expose raw signed payloads as the public core contract.
- App Store Server Notifications include environment information such as sandbox/production; Crosswake provider evidence should carry environment explicitly.

Primary references:
- https://developer.apple.com/documentation/storekit
- https://developer.apple.com/documentation/storekit/transaction/originalid
- https://developer.apple.com/documentation/appstoreserverapi/originaltransactionid
- https://developer.apple.com/documentation/appstoreserverapi/transactioninforesponse
- https://developer.apple.com/documentation/appstoreservernotifications/receiving-app-store-server-notifications
- https://developer.apple.com/documentation/appstoreservernotifications/data

### Play Billing / Google Play

- Google recommends a backend-backed purchase status system using RTDN and Play Developer APIs to keep entitlement state current across device states.
- Play Billing purchase flow returns purchase tokens. Google describes purchase tokens as unique identifiers for user/product purchases and uses them to query current state from Play Developer APIs.
- For subscriptions, the purchase token is the backend lookup key for `purchases.subscriptionsv2.get` and remains valid until 60 days after expiration. Use purchase-token lineage as Crosswake's Play Billing `provider_reference`.
- Order IDs and RTDN message IDs are useful event or trace context, but they should not become the subject authority key.
- Acknowledgement/consumption is provider duty after entitlement processing. Crosswake should model this as adapter/native coordinator responsibility and evidence/proof posture, not as entitlement authority.
- Pending purchases must not grant entitlement. Google explicitly distinguishes pending and purchased states, and says entitlement should be granted only after verification and purchased state.

Primary references:
- https://developer.android.com/google/play/billing/integrate
- https://developer.android.com/google/play/billing/lifecycle
- https://developer.android.com/google/play/billing/lifecycle/subscriptions
- https://developer.android.com/google/play/billing
- https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products

## Existing Crosswake Surfaces

### Contracts

- `lib/crosswake/commerce/contracts.ex` already defines `ReconciliationEvidence` with `source`, `provider`, `provider_reference`, `event_kind`, `evidence_ref`, `captured_at`, `integrity_digest`, and `idempotency_ref`.
- `lib/crosswake/commerce/reconciliation.ex` already turns success-like evidence into `:awaiting_verification`, rejects direct authority lane mutation, and keeps `outcome_implies_authority_grant?/1` and `outcome_implies_access_granted?/1` false for every reconciliation outcome.
- The current idempotency struct omits `evidence_ref`, while the phase context wants dual keys: event key includes `evidence_ref`, subject key excludes it. Plan should either add an explicit event-key helper in core or preserve the example-host `ReconciliationKeys` pattern without weakening replay detection.

### Example Host

- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` is the exact swap target: `simulate_purchase/2` and `simulate_restore/2` emit `ReconciliationEvidence` while downstream inbox/projection stays provider-neutral.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` already distinguishes `event_key` from `subject_key` and keeps correlation IDs trace-only.
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` should remain Phoenix-owned. Provider adapters should replace the evidence emitter, not the backend projection or LiveView authority model.

### Support / Doctor / Operator Truth

- `Crosswake.SupportMatrix` already has provider-adapter promotion rules for StoreKit and Play Billing purchase/restore claims and a `provider_adapter` action class.
- `Crosswake.OperatorInspection` already attaches promotion rule IDs to `purchase_intent` and `restore_intent` routes.
- `Crosswake.Doctor.PublishReadiness` currently treats provider adapters as not shipped. Phase 48 should update this to distinguish shipped adapter seams from advisory proof posture, not collapse everything into "ready."
- Existing Phase 23 and Phase 52 proof tests enforce provider-neutral merge-blocking commerce surfaces, proof-class labels, stable IDs, and generated/authored docs parity.

## Recommended Architecture

### Namespaces

- `Crosswake.Companions.StoreKit`
- `Crosswake.Companions.StoreKit.Evidence`
- `Crosswake.Companions.StoreKit.Result`
- `Crosswake.Companions.PlayBilling`
- `Crosswake.Companions.PlayBilling.Evidence`
- `Crosswake.Companions.PlayBilling.Result`
- Optional shared helper: `Crosswake.Commerce.ProviderEvidence`

### Evidence Contract

Provider-specific structs should normalize to `Crosswake.Commerce.Contracts.ReconciliationEvidence`.

StoreKit fields to model:
- `original_transaction_id` as subject lineage.
- `transaction_id`, notification UUID, or JWS digest as event evidence.
- `environment` as `:sandbox | :production`.
- `product_id`, `signed_transaction_info_digest`, `verification_source`, `captured_at`.

Play Billing fields to model:
- `purchase_token` as subject lineage.
- RTDN message ID, order context, or payload digest as event evidence.
- `environment` as `:sandbox | :production | :license_test`.
- `product_id`, `package_name`, `purchase_state`, `acknowledgement_state`, `captured_at`.

Shared closed vocabularies:
- Provider names: `"storekit"`, `"play_billing"`.
- Event kinds: `"purchase"`, `"restore"`, `"renewal"`, `"grace_period"`, `"billing_retry"`, `"refund"`, `"revoked"`.
- Result statuses: `:submitted`, `:user_canceled`, `:pending`, `:provider_error`, `:prerequisite_missing`, `:reconcile_required`.
- Lifecycle hints: `:flow_opened`, `:flow_closed`, `:pending_external`, `:reconcile_required`, `:reconcile_timeout`.

### Bridge Choreography

The route should initiate one-shot `purchase_intent` / `restore_intent` workflows. Native or companion code returns a typed result and normalized evidence. Continuous transaction streams, StoreKit `Transaction.updates`, and Play Billing callback streams should remain adapter-private or backend-ingested, not public Phoenix bridge events.

### Proof Posture

Merge-blocking:
- Struct validation and normalization fixtures.
- Backend authority invariants.
- Event/subject key stability.
- Support matrix, doctor, operator inspection, changelog, and guide parity.
- Hermetic proof workflow.

Advisory:
- StoreKit sandbox/simulator/device checks.
- Play Billing license-test/device checks.
- App-review screenshots or manual evidence.

Promotion:
- Keep existing four claim IDs.
- Enrich required evidence/check IDs from `diag.provider.adapters_not_shipped` to provider-specific shipped/advisory IDs.
- Preserve demotion triggers and freshness windows.

## Validation Architecture

Framework: ExUnit plus docs-contract fixture tests and GitHub Actions proof lanes.

Quick command:

```bash
mix test test/crosswake/commerce test/crosswake/companions test/crosswake/doctor/publish_readiness_test.exs
```

Full command:

```bash
mix test
```

Phase-specific proof target:

```bash
mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs
```

The phase needs a hermetic proof file that asserts:
- StoreKit and Play Billing evidence fixtures normalize into `ReconciliationEvidence`.
- Pending/provider evidence never grants authority or access.
- Raw provider enums do not leak into core event kinds.
- SupportMatrix promotion rules expose provider-specific evidence, docs, checks, and demotion triggers.
- Doctor/readiness and operator inspection report shipped seam truth separately from advisory storefront proof.
- Public guides and changelog distinguish adapter seams from provider certification.

## Planning Implications

1. Start with shared provider evidence vocabulary and StoreKit normalization.
2. Add Play Billing normalization against the same contract.
3. Add one-shot purchase/restore result contracts and example-host swap target wiring.
4. Update support, doctor, operator, changelog, and guides.
5. Add hermetic proof and advisory workflow scaffolding.

## Research Complete

The phase is ready for planning. The high-risk areas are provider identity keys, proof-class wording, and avoiding client-authoritative entitlement claims.
