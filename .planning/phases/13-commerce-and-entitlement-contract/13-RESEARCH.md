# Phase 13: Commerce And Entitlement Contract - Research

**Researched:** 2026-05-19
**Domain:** Phoenix-facing commerce contracts, backend entitlement projections, and storefront reconciliation boundaries
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Commerce vocabulary shape
- **D-01:** Crosswake should expose five typed Phoenix-facing commerce surfaces in `core`: `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence`.
- **D-02:** These surfaces should be represented as small semantic structs plus one thin behaviour/orchestration seam rather than a generic command bus or a monolithic `CommerceSession` workflow object.
- **D-03:** `purchase_intent` and `restore_intent` are requests for reconciliation and provider-handled workflow entry, not direct entitlement mutations.
- **D-04:** `entitlement_snapshot` is a backend-issued read model. Device or storefront observations may inform it, but they do not replace it.
- **D-05:** `reconciliation_evidence` is the normalized input envelope for purchase, restore, webhook, or manual-support evidence. It exists to feed backend reconciliation, not to widen route-local authority.
- **D-06:** Core should define the typed vocabulary, denial atoms, fallback language, and telemetry/outcome names for these surfaces. Provider/store payloads and SDK semantics stay out of the core public contract.

### Entitlement snapshot semantics
- **D-07:** The default snapshot shape should be dual-lane: a backend `authority` verdict plus a bounded `evidence` envelope. Crosswake must not collapse the public seam into one flat `is_subscribed`-style truth value.
- **D-08:** Model `authority_state` and `access_state` separately. An entitlement can be scheduled to end, revoked, stale, or awaiting reconciliation without those states meaning the same thing.
- **D-09:** `canceled_scheduled_end` and `revoked` must remain distinct. Canceled may still grant access until its effective end; revoked means access is denied immediately unless backend rules say otherwise.
- **D-10:** Include explicit freshness and timing fields such as `checked_at`, `stale_after`, `effective_until`, and `reconciliation_state`.
- **D-11:** `pending_purchase`, `pending_restore`, and `awaiting_verification` are reconciliation states, not access grants, unless backend authority explicitly marks access as granted.
- **D-12:** Raw Apple, Google, RevenueCat, or provider-specific status enums must not leak into the core snapshot contract. At most, bounded evidence metadata or companion/debug extensions may retain provider detail.
- **D-13:** Missing or stale evidence must not silently imply denial, and missing device evidence must not silently imply entitlement success. Unknown and stale truth need explicit fail-closed or guidance-backed states.

### Reconciliation flow and event boundaries
- **D-14:** Crosswake should default to a backend reconciliation inbox plus an authoritative entitlement projection.
- **D-15:** The canonical flow is:
  - device or native commerce route emits typed `purchase` or `restore` evidence
  - Phoenix persists a `reconciliation_attempt`
  - backend verification/replay runs through host-owned workers and provider adapters
  - backend updates one authoritative `entitlement_snapshot`
  - Phoenix/native consumers refresh from that snapshot
- **D-16:** Idempotency belongs on the backend. Use provider-aware identity such as provider, original transaction id or purchase token, event id, and event kind. Device correlation ids are useful evidence but not authority.
- **D-17:** Device purchase success, restore success, or native callback success are evidence only. They must never unlock entitlement by themselves.
- **D-18:** Pending, failed, and conflict-like states belong primarily in backend reconciliation records and projected snapshots. Device UI may show transient states such as `submitted` or `awaiting_verification`, but must not own canonical entitlement-pending truth.
- **D-19:** Core owns typed vocabulary and hooks only: intent structs, evidence envelope, reconciliation attempt/outcome vocabulary, snapshot shape, telemetry names, and denial/fallback semantics.
- **D-20:** Companion packages own provider adapters and storefront integration details: StoreKit/Play Billing normalization, webhook helpers, verification clients, native purchase command/event contracts, and native commerce guidance.
- **D-21:** Host apps own Ecto schemas, webhook endpoints, Oban workers or equivalent job orchestration, entitlement mapping and business rules, optimistic locking or version checks, operator tooling, and manual support flows.
- **D-22:** Crosswake should reject split-brain reconciliation paths where device callbacks and server notifications each maintain separate truth. Both must feed the same authoritative reconciliation boundary.
- **D-23:** Commerce support claims must stay online-authoritative. Crosswake should not imply offline purchase replay or device-local entitlement mutation as a supported default.

### Native-screen and companion boundaries
- **D-24:** The default public rule is: Phoenix owns pricing, subscription status, entitlement-gated feature checks, FAQ, billing/account history, and post-reconciliation account surfaces; explicit native screens own storefront-sensitive purchase loops.
- **D-25:** When a flow includes storefront UI, purchase confirmation, restore choreography, offer-code or redeem handling, or provider SDK-owned session logic, Crosswake should bias toward an explicit native commerce corridor instead of a Phoenix-owned route with hidden native behavior.
- **D-26:** Thin Phoenix-owned routes may still trigger one-shot native commerce actions when the native surface is genuinely sheet-like and bounded, but this is the exception rather than the default public story.
- **D-27:** StoreKit, Play Billing, RevenueCat-style SDKs, and other storefront/provider SDK integrations belong in `companion` packages and carry explicit `native or companion rebuild required` posture.
- **D-28:** A declared native commerce route must fail closed with explicit unavailable guidance when the required companion, storefront support, native runtime line, or provider prerequisites are missing. No silent degradation into web checkout or generic WebView fallback for digital goods.
- **D-29:** Crosswake should publish a canonical moment map in docs so teams can quickly classify Phoenix-owned commerce moments versus native-screen-required commerce moments without re-deriving the rule from first principles.

### Product posture, DX, and shift-left rules
- **D-30:** Shift routine commerce contract decisions left within GSD. Downstream agents should not re-ask about struct naming, evidence-vs-authority posture, backend-owned reconciliation, companion classification, denial/fallback semantics, or default native-corridor bias unless a proposal materially changes thesis, entitlement authority, route ownership, or support claims.
- **D-31:** The few decisions that remain meaningfully user-impactful are:
  - whether a given product wants a thin semantic paywall trigger into native UI or a fuller dedicated native commerce corridor
  - whether subscription/account management after purchase stays Phoenix-owned or grows into a broader native module for a commerce-first app
- **D-32:** The contract should optimize for least surprise to Phoenix teams: small typed seams, explicit ownership boundaries, clear rebuild truth, and support wording that tells adopters whether they are looking at Phoenix guidance, companion-required behavior, or a native-screen requirement.

### Claude's Discretion
- Exact module names, struct field names, and telemetry event names, as long as the five typed surfaces and evidence-vs-authority split remain explicit.
- Exact rendering and guide layout for the commerce moment map, as long as the Phoenix-owned versus native-screen-required split stays clear.
- Exact host-side schema names for reconciliation attempts and entitlement projections, as long as backend idempotency and authoritative projection remain the default architecture.

### Deferred Ideas (OUT OF SCOPE)
- Shipping StoreKit, Play Billing, RevenueCat, or other provider-specific adapters in `core`
- Turning Crosswake core into a full billing engine, event store, or hosted commerce workflow system
- Promoting docs-only commerce examples into runnable supported example-host lanes before companion, proof, and support posture land
- Offline purchase replay or device-authoritative entitlement mutation
- Broad native billing modules as the default story for ordinary Phoenix adopters
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMM-01 | Phoenix teams can model paywall entry, purchase intent, restore intent, entitlement snapshot, and reconciliation hooks through a Phoenix-facing Crosswake contract. | Use five small typed structs in `core`, align them with the existing `Manifest.Types` style, and add one thin orchestration behaviour instead of a session object or command bus. [VERIFIED: codebase grep] |
| COMM-02 | Crosswake documents that entitlement truth remains backend-owned and that device purchase events are inputs to reconciliation rather than final authority. | Model device/storefront events as `reconciliation_evidence`, project one backend-owned `entitlement_snapshot`, and document server verification plus notification-driven refresh as the standard flow. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/storekit/determining-service-entitlement-on-the-server] |
| COMM-03 | Adopters can tell which commerce behavior belongs in core contracts, which belongs in companion adapters, and which flows require explicit native screens or storefront guidance. | Preserve `core` for normalized contract vocabulary, keep provider/storefront SDKs in companions, and classify purchase-loop moments with an explicit Phoenix-vs-native corridor map. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/enabling-app-store-server-notifications] |
</phase_requirements>

## Summary

Crosswake should plan Phase 13 as a contract-shaping phase, not a billing implementation phase. The repo already treats commerce surfaces as backend seams with explicit prerequisites, denial behavior, and companion-required posture in the manifest catalog and support matrix, and it already prefers small typed structs over generic buses in `Manifest.Types` and `Offline.Contracts`. [VERIFIED: codebase grep]

Official storefront guidance reinforces the same architecture. Google’s billing flow explicitly includes server verification before granting content, recommends secure-backend acknowledgement, warns not to grant entitlement in `PENDING`, and says subscription state changes must be refreshed from the Developer API before removing or changing access. Apple’s server docs center server notifications, notification recovery, and server-side entitlement determination, while Apple’s original receipt API is now deprecated in favor of newer StoreKit APIs and server flows. RevenueCat’s docs also separate cached client status from freshness and network truth. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.android.com/google/play/billing/lifecycle/subscriptions] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog] [CITED: https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases] [CITED: https://www.revenuecat.com/docs/customers/customer-info]

**Primary recommendation:** Implement Phase 13 around five typed `core` structs plus one thin behaviour, back them with a canonical backend reconciliation model, and document a strict moment map: Phoenix owns status/history/gated checks, while storefront-sensitive purchase loops move into explicit native or companion corridors. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/security]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `paywall_entry` contract vocabulary | API / Backend | Browser / Client | Crosswake already classifies paywall as a `backend_seam`; the public seam should describe intent and prerequisites, not let the client own purchase truth. [VERIFIED: codebase grep] |
| `purchase_intent` and `restore_intent` structs | API / Backend | Frontend Server (SSR) | Google and Apple both require backend verification or server-side entitlement determination before access changes; the browser can initiate, but the backend owns meaning. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.apple.com/documentation/storekit/determining-service-entitlement-on-the-server] |
| `reconciliation_evidence` ingestion | API / Backend | Database / Storage | Evidence arrives from device callbacks, webhooks, or support tools, then needs durable ingestion and replay-safe processing. [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/enabling-app-store-server-notifications] |
| `reconciliation_attempt` persistence and idempotency | Database / Storage | API / Backend | Duplicate purchase tokens, linked replacement tokens, and notification retries require durable keys and conflict handling at the persistence layer. [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] |
| `entitlement_snapshot` projection | Database / Storage | API / Backend | Snapshot truth must be backend-issued, freshness-aware, and independently refreshable from storefront events. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/lifecycle/subscriptions] |
| Storefront purchase UI and restore choreography | Browser / Client | API / Backend | This belongs to explicit native or companion corridors when the store or SDK owns the interaction loop. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] |
| Subscription/account history, pricing, and gating checks | Frontend Server (SSR) | API / Backend | The phase context and current guides keep these Phoenix-owned after reconciliation completes. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | 1.8.7 | Host framework and public Phoenix-facing seam location. [VERIFIED: hex registry] | The repo already targets `~> 1.8`, and this keeps the commerce contract in the same Phoenix-first surface as the rest of Crosswake. [VERIFIED: hex registry] [VERIFIED: codebase grep] |
| Phoenix LiveView | 1.1.30 | Phoenix-owned commerce/status routes and account surfaces. [VERIFIED: hex registry] | Current project baseline is `~> 1.1`; LiveView remains server-owned and route-first in the support matrix. [VERIFIED: hex registry] [VERIFIED: codebase grep] |
| Crosswake typed structs (`Manifest.Types` style) | repo-local | Public contract modeling for small semantic structs. [VERIFIED: codebase grep] | The codebase already centralizes typed contract structs here instead of command-bus abstractions. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto | 3.14.0 | Host-side persistence for `reconciliation_attempt` and `entitlement_snapshot`, including optimistic locking. [VERIFIED: hex registry] | Use whenever the host app persists authoritative projections or reconciliation records. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Oban | 2.22.1 | Host-side reconciliation jobs with unique insertion semantics and `Ecto.Multi` integration. [VERIFIED: hex registry] | Use for purchase-token/webhook replay workers and verification retries. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] |
| App Store Server Notifications V2 + App Store Server API | current service | Apple subscription lifecycle input and recovery channel. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog] | Use in companions/hosts, never in `core`, whenever Apple purchases are supported. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] |
| Google Play Developer API (`purchases.subscriptionsv2.get`, acknowledgement endpoints) | current service | Verification, lifecycle refresh, linked-token handling, and acknowledgement. [CITED: https://developer.android.com/google/play/billing/security] | Use in companions/hosts, never in `core`, whenever Play Billing is supported. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Thin typed structs + behaviour seam | Generic command bus | Rejected because the repo already prefers typed contract structs and the phase context explicitly forbids widening authority into a plugin-like bus. [VERIFIED: codebase grep] |
| Backend projection + reconciliation inbox | Device-local entitlement authority | Rejected because Google and Apple require backend verification or server-side entitlement determination for trustworthy access control. [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/storekit/determining-service-entitlement-on-the-server] |
| Oban uniqueness + DB keys | Ad hoc in-memory dedupe | Rejected because retries, notification replay, and multi-node host apps need durable idempotency. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] |

**Installation:**
```elixir
defp deps do
  [
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:ecto, "~> 3.14"},
    {:oban, "~> 2.22"}
  ]
end
```

**Version verification:** `phoenix` 1.8.7, `phoenix_live_view` 1.1.30, `ecto` 3.14.0, and `oban` 2.22.1 were verified from Hex on 2026-05-19. [VERIFIED: hex registry]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix/LiveView route
  -> emits `paywall_entry` / `purchase_intent` / `restore_intent`
  -> native or companion storefront corridor (when required)
  -> produces `reconciliation_evidence`
  -> Phoenix ingest endpoint / behaviour seam
  -> persist `reconciliation_attempt` with provider-aware idempotency keys
  -> enqueue verification worker
  -> call App Store Server API / Google Play Developer API / webhook replay
  -> compute authoritative entitlement verdict
  -> update `entitlement_snapshot`
  -> Phoenix/native consumers refresh snapshot
  -> gated features read backend authority + bounded evidence freshness
```

This diagram matches the locked backend-owned reconciliation flow, current `backend_seam` classification, and official server-verification guidance. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.android.com/google/play/billing/security]

### Recommended Project Structure

```text
lib/
├── crosswake/commerce/          # typed structs, behaviour, denial/fallback vocabulary
├── crosswake/manifest/          # capability/support wiring for commerce family metadata
└── crosswake/support_matrix/    # package/rebuild/prerequisite truth for commerce seams
```

This matches the current separation between manifest types, capability catalog entries, and support-matrix rendering. [VERIFIED: codebase grep]

### Pattern 1: Small Semantic Structs In Core
**What:** Add one module per public contract surface, each with a small `defstruct`, explicit field types, and no provider enums. [VERIFIED: codebase grep]
**When to use:** For `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence`. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
defmodule HostApp.EntitlementSnapshot do
  use Ecto.Schema

  schema "entitlement_snapshots" do
    field :authority_state, Ecto.Enum, values: [:granted, :denied, :unknown, :stale]
    field :access_state, Ecto.Enum, values: [:active, :scheduled_end, :revoked, :pending]
    field :checked_at, :utc_datetime_usec
    field :stale_after, :utc_datetime_usec
    field :lock_version, :integer, default: 1
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> Ecto.Changeset.cast(attrs, [:authority_state, :access_state, :checked_at, :stale_after])
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end
end
```

### Pattern 2: Provider-Aware Reconciliation Workers
**What:** Insert unique jobs keyed by provider identity, not by transient UI correlation ids. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] [CITED: https://developer.android.com/google/play/billing/security]
**When to use:** For webhook replay, purchase token verification, restore processing, and support-initiated rechecks. [CITED: https://developer.android.com/google/play/billing/lifecycle/subscriptions]
**Example:**
```elixir
# Source: https://hexdocs.pm/oban/2.18.3/Oban.html
defmodule HostApp.Commerce.ReconcilePurchaseWorker do
  use Oban.Worker,
    queue: :commerce,
    unique: [
      period: :infinity,
      fields: [:worker, :args],
      keys: [:provider, :provider_reference, :event_kind],
      states: [:available, :scheduled, :executing, :retryable, :completed]
    ]
end
```

### Anti-Patterns to Avoid

- **Flat `is_subscribed` booleans:** They erase freshness, revocation, scheduled end, and pending-verification nuance that this phase explicitly needs. [VERIFIED: codebase grep]
- **Granting entitlement from client purchase success:** Google explicitly says to verify purchases on the server and only grant entitlement when the purchase is legitimate and in the right state. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.android.com/google/play/billing/security]
- **Separate device truth and webhook truth:** Apple notification retries/history and Google lifecycle refreshes both assume one backend authority path that can recover from missed events. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] [CITED: https://developer.android.com/google/play/billing/lifecycle/subscriptions]
- **Leaking provider enums into core structs:** Current Crosswake docs and support matrix already frame commerce as normalized core vocabulary with provider details outside `core`. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Apple notification transport/retry model | Custom fake webhook semantics in `core` | App Store Server Notifications V2 in host/companion code | Apple already defines retries, notification history, and test notifications. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/enabling-app-store-server-notifications] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] |
| Google purchase verification | Trusting client callbacks or order ids | Google Play Developer API verification + acknowledgement | Google says to verify legitimacy on the backend and not to use `orderId` as a dedupe key. [CITED: https://developer.android.com/google/play/billing/security] |
| Reconciliation dedupe | Hand-made in-memory retry suppression | Oban unique jobs plus DB uniqueness | Durable idempotency must survive retries and multi-node execution. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] |
| Concurrent snapshot updates | Manual compare-and-swap logic everywhere | `Ecto.Changeset.optimistic_lock/3` | Ecto already provides stale-update detection for projections. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Storefront UI fallback | Silent web checkout downgrade for digital goods | Explicit native corridor or explicit unavailable guidance | The phase context and current guides require fail-closed behavior when storefront-sensitive flows need native ownership. [VERIFIED: codebase grep] |

**Key insight:** Crosswake should normalize the contract surface, not reproduce billing-provider infrastructure inside `core`. `core` owns vocabulary and rules; hosts and companions own verification clients, SDK glue, webhooks, and operator tooling. [VERIFIED: codebase grep] [CITED: https://developer.android.com/google/play/billing/security]

## Common Pitfalls

### Pitfall 1: Treating device cache as entitlement authority
**What goes wrong:** A client cache can show stale access after revocation, cancellation, or missed verification. [CITED: https://www.revenuecat.com/docs/customers/customer-info]
**Why it happens:** RevenueCat explicitly documents client caching and five-minute refresh windows, which are useful for UX but not a backend authority substitute. [CITED: https://www.revenuecat.com/docs/customers/customer-info]
**How to avoid:** Keep `entitlement_snapshot` backend-issued and expose freshness fields such as `checked_at` and `stale_after`. [VERIFIED: codebase grep]
**Warning signs:** Core API proposals that collapse to `is_subscribed: boolean` or omit freshness metadata. [VERIFIED: codebase grep]

### Pitfall 2: Granting on `PENDING` or before verification
**What goes wrong:** Users get access before the store confirms a valid purchase, which later causes refund, cancellation, or entitlement clawback flows. [CITED: https://developer.android.com/google/play/billing/security]
**Why it happens:** Teams over-trust client callbacks and under-model pending or awaiting-verification states. [CITED: https://developer.android.com/google/play/billing/security]
**How to avoid:** Separate `reconciliation_state` from `access_state`; only backend authority can transition access to granted. [VERIFIED: codebase grep]
**Warning signs:** Code paths that grant immediately after app-side success callbacks or restore completions. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en]

### Pitfall 3: Weak idempotency keys
**What goes wrong:** Duplicate webhooks, linked replacement purchases, or retry storms create split-brain projections. [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications]
**Why it happens:** Using UI correlation ids, order ids, or route ids as primary dedupe keys is insufficient. Google explicitly warns against using `orderId` as a primary key. [CITED: https://developer.android.com/google/play/billing/security]
**How to avoid:** Key attempts by provider plus original transaction id or purchase token plus event kind, and back them with DB uniqueness or Oban uniqueness. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html]
**Warning signs:** Reconciliation jobs without `unique` semantics or schemas without provider-reference uniqueness constraints. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html]

## Code Examples

Verified patterns from official sources:

### Optimistic Projection Update
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
schema "entitlement_snapshots" do
  field :lock_version, :integer, default: 1
end

def changeset(snapshot, attrs) do
  snapshot
  |> Ecto.Changeset.cast(attrs, [:authority_state, :access_state])
  |> Ecto.Changeset.optimistic_lock(:lock_version)
end
```

### Unique Reconciliation Worker
```elixir
# Source: https://hexdocs.pm/oban/2.18.3/Oban.html
use Oban.Worker,
  unique: [
    period: :infinity,
    fields: [:worker, :args],
    keys: [:provider, :provider_reference, :event_kind],
    states: [:available, :scheduled, :executing, :retryable, :completed]
  ]
```

### Current Crosswake Commerce Extension Point
```elixir
# Source: /Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex
[
  id: "purchase",
  family: "purchase",
  owner: :backend_seam,
  package_class: :example_docs_only,
  prerequisites: ["backend reconciliation", "provider-specific adapter"],
  fallback: "treat purchase events as reconciliation inputs, not entitlement truth"
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| App Store Server Notifications V1 | App Store Server Notifications V2 | Apple changelog documents V1 deprecation and V2 as the implementation target. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog] | Host adapters should plan for V2 notification payloads and history recovery, not a V1-only contract. |
| Original StoreKit receipt-validation API as default | New In-App Purchase API and server APIs | Apple documents the Original API as deprecated. [CITED: https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases] | Do not bake receipt-specific semantics into `core`; normalize around generic evidence and backend authority. |
| Client-only acknowledgement/grant flow | Secure-backend verification and acknowledgement | Current Google docs recommend secure-backend verification and acknowledgement wherever possible. [CITED: https://developer.android.com/google/play/billing/integrate?hl=en] [CITED: https://developer.android.com/google/play/billing/security] | Crosswake docs should treat client success as provisional evidence only. |

**Deprecated/outdated:**
- App Store Server Notifications V1 endpoint and V1 notifications. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog]
- Using `orderId` as a primary dedupe key for Google purchases. [CITED: https://developer.android.com/google/play/billing/security]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Host examples for future phases will likely use Ecto + Oban as the reference reconciliation stack rather than another Elixir persistence/job combination. [ASSUMED] | Standard Stack | Low; the core contract remains valid, but later plan tasks may need different host examples if the maintainer prefers another stack. |

## Open Questions (RESOLVED)

1. **Should `paywall_entry` stay purely semantic or include a bounded presentation hint set?**
   - Resolution: Keep `paywall_entry` purely semantic in `core`. It may carry route-local context or reason metadata needed to explain why Phoenix is entering a commerce flow, but it must not define presentation taxonomies such as placement, campaign, variant, or SDK-facing layout hints. Those belong in companions or host apps where storefront UI is actually owned. [VERIFIED: codebase grep]
   - Planning consequence: `COMM-01` should model `paywall_entry` as semantic entry context plus denial/fallback semantics only. No plan should add visual-paywall configuration vocabulary to `core`.

2. **How much provider detail should `reconciliation_evidence.metadata` allow?**
   - Resolution: Allow only opaque, namespaced metadata intended for correlation or debugging. `core` may preserve this metadata as uninterpreted baggage, but it must not define typed provider enums, provider-specific lifecycle fields, or decision-making semantics based on metadata contents. Provider parsing and strong typing stay outside `core` in companions or host-owned adapters. [VERIFIED: codebase grep]
   - Planning consequence: `COMM-01` and `COMM-02` can expose a bounded `metadata` field, but tests and guide wording must make clear that entitlement authority never depends on typed provider metadata in `core`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Commerce entitlement state is not primarily an auth concern in this phase; defer to host app auth layers. [ASSUMED] |
| V3 Session Management | no | This phase does not define user-session mechanics. [ASSUMED] |
| V4 Access Control | yes | Gate access from backend-issued `entitlement_snapshot`, not client callbacks. [CITED: https://developer.android.com/google/play/billing/security] |
| V5 Input Validation | yes | Validate `reconciliation_evidence` and snapshot updates with typed structs plus Ecto changesets in hosts. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Never hand-roll store verification; rely on Apple/Google signed transaction and server APIs in companions/hosts. [CITED: https://developer.android.com/google/play/billing/security] [CITED: https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases] |

### Known Threat Patterns for Phoenix commerce seams

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged device purchase payload | Tampering | Treat device events as evidence only and verify with provider backend APIs before granting access. [CITED: https://developer.android.com/google/play/billing/security] |
| Duplicate or replayed purchase events | Repudiation | Use provider-aware idempotency keys plus unique worker/DB constraints. [CITED: https://hexdocs.pm/oban/2.18.3/Oban.html] [CITED: https://developer.android.com/google/play/billing/security] |
| Stale cached entitlement shown as active | Elevation of privilege | Carry freshness fields and keep backend snapshot authoritative. [CITED: https://www.revenuecat.com/docs/customers/customer-info] |
| Missed server notifications during outage | Denial of service | Recover with Apple notification history / transaction history or Google lifecycle re-fetch against the authoritative APIs. [CITED: https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications] [CITED: https://developer.android.com/google/play/billing/lifecycle/subscriptions] |

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/offline/contracts.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `guides/capabilities.md`, `guides/support_matrix.md` - existing commerce placeholders, typed-contract style, and package-boundary truth checked directly in the repo. [VERIFIED: codebase grep]
- https://developer.android.com/google/play/billing/integrate?hl=en - purchase flow includes server verification before granting content. [CITED]
- https://developer.android.com/google/play/billing/security - backend verification, acknowledgement, `PENDING` handling, `linkedPurchaseToken`, and `orderId` warning. [CITED]
- https://developer.android.com/google/play/billing/lifecycle/subscriptions - backend refresh before revoking access on expiration and lifecycle handling. [CITED]
- https://hexdocs.pm/ecto/Ecto.Changeset.html - optimistic locking API. [CITED]
- https://hexdocs.pm/oban/2.18.3/Oban.html - unique jobs and `Oban.insert` guidance. [CITED]

### Secondary (MEDIUM confidence)
- https://developer.apple.com/documentation/storekit/determining-service-entitlement-on-the-server - Apple’s server entitlement framing was available through the official result snippet, but the docs page requires JavaScript in the fetch tool. [CITED]
- https://developer.apple.com/documentation/appstoreservernotifications/enabling-app-store-server-notifications - official snippet confirmed HTTPS endpoint setup, V2 testing flow, and notification transport posture. [CITED]
- https://developer.apple.com/documentation/appstoreservernotifications/responding-to-app-store-server-notifications - official snippet confirmed retry schedule and notification-history recovery. [CITED]
- https://developer.apple.com/documentation/appstoreservernotifications/app-store-server-notifications-changelog - official snippet confirmed V1 deprecation and V2 target. [CITED]
- https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases - official snippet confirmed Original API deprecation. [CITED]
- https://www.revenuecat.com/docs/customers/customer-info - client cache, freshness window, and restore/update semantics. [CITED]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - current project versions and Ecto/Oban capabilities were verified directly from Hex and official docs.
- Architecture: HIGH - repo-local contract patterns and official Google/Apple backend-verification guidance strongly align.
- Pitfalls: HIGH - Google security docs, RevenueCat cache docs, and existing Crosswake boundaries all point to the same failure modes.

**Research date:** 2026-05-19
**Valid until:** 2026-06-18
