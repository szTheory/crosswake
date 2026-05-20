# Commerce & Entitlement Contracts

Crosswake does not ship a billing engine or storefront provider SDKs. Instead, it defines a standard vocabulary and explicit backend-owned reconciliation flow for Phoenix apps. This ensures that Phoenix teams can handle native commerce requirements without compromising the security and truth of their entitlement rules.

## Normalized Commerce Vocabulary

Crosswake exposes five core typed surfaces:

1. `paywall_entry`: Semantic definition of pricing and intent.
2. `purchase_intent`: A request for reconciliation and provider workflow entry.
3. `restore_intent`: A request to restore purchases and begin reconciliation.
4. `entitlement_snapshot`: A backend-issued read model of access truth.
5. `reconciliation_evidence`: The normalized input envelope for purchase, restore, webhook, or support evidence.

## Authority vs Evidence

An `entitlement_snapshot` is a dual-lane record: it carries both a strict backend `authority` verdict and a bounded `evidence` envelope. Device or storefront observations inform the snapshot but do not replace it. 

Device success is evidence, not entitlement. Missing or stale evidence must not silently imply denial, and missing device evidence must not silently imply entitlement success.

States such as `pending_purchase`, `pending_restore`, and `awaiting_verification` are reconciliation states, not automatic access grants. You must explicitly evaluate `authority_state` vs `access_state` to know if a user can access a feature.

## Commerce Moment Map

To keep boundaries explicit, Crosswake classifies commerce moments into these ownership corridors:

- **Phoenix-owned:** pricing, subscription status, entitlement-gated checks, FAQ, billing/account history, post-reconciliation account surfaces.
- **Native-screen required or strong default:** storefront purchase confirmation, restore choreography, offer-code / redeem flows, provider SDK-owned session loops.
- **Thin exception case:** bounded one-shot trigger from a Phoenix-owned route into native commerce UI, only when the surface is genuinely sheet-like (and not a complex multi-step native stack).

## The Canonical Reconciliation Flow

Crosswake requires a backend reconciliation inbox plus an authoritative entitlement projection. The canonical flow is:

1. device or native commerce route emits typed purchase or restore evidence
2. Phoenix persists a reconciliation_attempt
3. backend verification/replay runs through host-owned workers and provider adapters
4. backend updates one authoritative entitlement_snapshot
5. Phoenix/native consumers refresh from that snapshot

## Backend Idempotency

Idempotency belongs on the backend. Attempt keys should use provider-aware identity such as provider, original transaction id or purchase token, event id, and event kind. Transient device correlation ids are useful evidence but do not define idempotency keys. Duplicate webhook retries or replacement tokens must be safely handled by your host-owned workers.

## Non-Goals & explicit Rejections

Crosswake intentionally explicitly avoids:
- **offline purchase replay**: There is no supported way to replay a local device purchase while entirely offline to unlock new permanent entitlements. Commerce requires an online verification step.
- **device-local authority**: Storefront device callbacks cannot directly transition access state in the core. They provide evidence to the backend.
- **split-brain truth**: We explicitly reject split-brain paths where client callbacks and server notifications maintain separate truths. Both must feed the same authoritative reconciliation boundary.
- **provider-specific core logic**: Raw Apple, Google, or RevenueCat enum details must not leak into core snapshot contracts.
