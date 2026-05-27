# Commerce & Entitlement Contracts

Crosswake does not ship a billing engine or storefront provider SDKs. Instead, it defines a standard vocabulary and explicit backend-owned reconciliation flow for Phoenix apps. This ensures that Phoenix teams can handle native commerce requirements without compromising the security and truth of their entitlement rules.

## Normalized Commerce Vocabulary

Crosswake exposes five core typed surfaces:

1. `paywall_entry`: Semantic definition of pricing and intent.
2. `purchase_intent`: A request for reconciliation and provider workflow entry.
3. `restore_intent`: A request to restore purchases and begin reconciliation.
4. `entitlement_snapshot`: A backend-issued read model of access truth.
5. `reconciliation_evidence`: The normalized input envelope for purchase, restore, webhook, or support evidence.

## Commerce Corridor Ownership

Crosswake keeps corridor ownership explicit and matrix-first so route authors can see where Phoenix stays in control and where native or companion choreography is mandatory.

| corridor_role | owner_posture | phase_19_truth |
| --- | --- | --- |
| `paywall_entry` | `phoenix_owned` | Keep paywall entry routes Phoenix-owned and declarative. |
| `account_management` | `phoenix_owned` | Keep post-reconciliation account surfaces Phoenix-owned. |
| `purchase_intent` | `native_or_companion_required` | Storefront confirmation and purchase execution require native or companion choreography. |
| `restore_intent` | `native_or_companion_required` | Restore workflows require native or companion choreography. |

For Phase 19, provider adapters are out of scope. Crosswake defines seam vocabulary and fallback posture, while StoreKit, Play Billing, and other adapter implementations stay companion or future work.

## Entitlement Snapshot Lanes

Crosswake models `entitlement_snapshot` as six explicit semantic lanes:

1. `authority`: backend-owned entitlement verdict (`none`, `active`, `grace`, `billing_retry`, `canceled_scheduled_end`, `revoked`, `refunded`, `expired`).
2. `access`: the route-facing decision (`granted` or `denied`) with reason metadata.
3. `reconciliation`: workflow posture (`pending_purchase`, `pending_restore`, `awaiting_verification`, `projection_refreshed`, `conflict`, `verification_failed`, `stale_authority`).
4. `freshness`: projection confidence (`fresh`, `stale`, `unknown`).
5. `effective`: effective-from / effective-until timing metadata.
6. `evidence`: bounded provenance envelope for reconciliation inputs.

The lanes are orthogonal: pending and verification workflow states belong to reconciliation and never imply direct authority grants.

## Authority vs Evidence

An `entitlement_snapshot` keeps authority and evidence separate by design. Device, storefront, webhook, and support signals are evidence sources that can advance reconciliation, but they cannot directly grant authority.

Device success is evidence, not entitlement. Missing or stale evidence must not silently imply denial, and missing device evidence must not silently imply entitlement success.

States such as `pending_purchase`, `pending_restore`, `awaiting_verification`, `grace`, `billing_retry`, `canceled_scheduled_end`, `revoked`, `refunded`, and `expired` require explicit backend projection semantics. You must evaluate `authority_state`, `access_state`, and freshness posture together rather than treating pending or evidence signals as grants.

## Commerce Moment Map

To keep boundaries explicit, Crosswake classifies commerce moments into these ownership corridors:

- **Phoenix-owned:** pricing, subscription status, entitlement-gated checks, FAQ, billing/account history, post-reconciliation account surfaces.
- **Native-screen required or strong default:** storefront purchase confirmation, restore choreography, offer-code / redeem flows, provider SDK-owned session loops.
- **Thin exception case:** bounded one-shot trigger from a Phoenix-owned route into native commerce UI, only when the surface is genuinely sheet-like (and not a complex multi-step native stack).

## Canonical Corridor Denial And Fallback Codes

Crosswake uses canonical `commerce.corridor.*` IDs across route gates, support matrix, doctor output, and docs:

| denial_code | fail_closed_reason | fallback |
| --- | --- | --- |
| `commerce.corridor.undeclared` | route declared commerce without a canonical corridor profile | `return_to_phoenix_guidance` |
| `commerce.corridor.unsupported` | corridor role or manifest-source posture is unsupported for activation | `return_to_phoenix_guidance` |
| `commerce.corridor.prerequisite_missing` | required corridor prerequisites are missing | `return_to_phoenix_guidance` |
| `commerce.corridor.runtime_incompatible` | route runtime does not satisfy corridor ownership posture | `return_to_phoenix_guidance` |
| `commerce.corridor.entry_denied` | external entry posture conflicts with corridor policy | `return_to_phoenix_guidance` |
| `commerce.corridor.origin_denied` | origin allowlist posture conflicts with corridor policy | `return_to_phoenix_guidance` |
| `commerce.corridor.policy_blocked` | role declaration conflicts with canonical corridor policy | `return_to_phoenix_guidance` |
| `commerce.corridor.pack_incompatible` | required pack/runtime posture is incompatible for the corridor | `return_to_phoenix_guidance` |

## The Canonical Reconciliation Flow

Crosswake requires a backend reconciliation inbox plus an authoritative entitlement projection. The canonical flow is:

1. device or native commerce route emits typed purchase or restore evidence
2. Phoenix persists a reconciliation_attempt
3. backend verification/replay runs through host-owned workers and provider adapters
4. backend updates one authoritative entitlement_snapshot
5. Phoenix/native consumers refresh from that snapshot

## Minimal Reconciliation Inbox Example

Use this minimal sequence when you need a runnable Phoenix-owned reconciliation inbox that stays backend-authoritative:

1. A `purchase`, `restore`, `webhook`, or `support` signal arrives as normalized `reconciliation_evidence`.
2. Phoenix persists append-only evidence events plus a canonical reconciliation attempt record.
3. Host-owned verification workers/processes run provider checks and replay handling.
4. One backend projection updates `entitlement_snapshot` as the single authority source.
5. Phoenix and native surfaces read that snapshot for route decisions.

Ingestion outcomes are non-authoritative by contract: they can move reconciliation work forward, but they do not grant access or set entitlement authority directly.

This reconciliation walkthrough is `example/docs-only` and companion-ready. It is guidance for host implementations, not a required persistence schema, queue layout, or job framework contract.

## Backend Idempotency

Idempotency belongs on the backend. Attempt keys should use provider-aware identity such as provider, original transaction id or purchase token, event id, and event kind. Transient device correlation ids are useful evidence but do not define idempotency keys. Duplicate webhook retries or replacement tokens must be safely handled by your host-owned workers.

## Non-Goals & explicit Rejections

Crosswake intentionally explicitly avoids:
- **offline purchase replay**: There is no supported way to replay a local device purchase while entirely offline to unlock new permanent entitlements. Commerce requires an online verification step.
- **device-local authority**: Storefront device callbacks cannot directly transition access state in the core. They provide evidence to the backend.
- **split-brain truth**: We explicitly reject split-brain paths where client callbacks and server notifications maintain separate truths. Both must feed the same authoritative reconciliation boundary.
- **provider-specific core logic**: Raw Apple, Google, or RevenueCat enum details must not leak into core snapshot contracts.

## Reviewer/Storefront Notes

Commerce requires explicit reviewer playbooks. Storefront reviewers will scrutinize purchase and restore flows. Adopters must prepare clear reviewer notes explaining how to trigger paywalls, how test accounts are provisioned, and how the backend handles sandbox vs. production receipts. Crosswake core limits its scope to the reconciliation envelope, meaning the storefront adapter's behavior must be documented and proven by the host app team before submission.

## Fallback Behavior

When commerce capabilities are unavailable, undeclared, or missing evidence, the fallback involves returning to a Phoenix-owned baseline or graceful degradation. Fallback remains a Phoenix-owned guidance or a deliberate native-screen requirement without device authority. Never fail open. If the native commerce shell is unreachable, fall back to Phoenix-owned paywall guidance without attempting unsafe web-based native billing bridges.

*See [guides/capabilities.md](capabilities.md) for the broader capabilities contract and ownership rubric.*
