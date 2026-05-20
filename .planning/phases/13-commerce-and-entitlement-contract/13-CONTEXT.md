# Phase 13: Commerce And Entitlement Contract - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Define a Phoenix-facing commerce seam that preserves backend-owned entitlement truth, keeps storefront/provider logic outside `core`, and makes route ownership explicit when commerce moments require native control. This phase locks contract shape, reconciliation vocabulary, and boundary rules. It does not ship StoreKit/Play Billing adapters, a full billing engine, or broad runnable commerce examples.

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact module names, struct field names, and telemetry event names, as long as the five typed surfaces and evidence-vs-authority split remain explicit.
- Exact rendering and guide layout for the commerce moment map, as long as the Phoenix-owned versus native-screen-required split stays clear.
- Exact host-side schema names for reconciliation attempts and entitlement projections, as long as backend idempotency and authoritative projection remain the default architecture.

</decisions>

<specifics>
## Specific Ideas

- The strongest mental model is not “Crosswake supports billing.” The right model is “Crosswake gives Phoenix teams a typed commerce seam, explicit native route ownership where storefront policy demands it, and backend-owned entitlement truth.”
- Good lessons to learn from:
  - Hotwire Native: keep most routes web-owned and make native ownership explicit per route instead of hiding native authority behind a generic bridge.
  - Apple/Google billing ecosystems: treat device purchase success as provisional evidence and server verification/lifecycle events as part of the real entitlement system.
  - RevenueCat and similar tooling: cached client state is useful for UX, but freshness and backend verification remain critical.
  - Elixir/Phoenix idioms: typed structs, Ecto-backed projections, and Oban-style reconciliation jobs are a cleaner fit than a generic plugin bus or a giant billing session abstraction.
- Footguns to avoid:
  - `is_subscribed` booleans that hide stale, pending, revoked, or canceled nuance
  - purchase success unlocking access before backend verification
  - separate device and webhook truth paths
  - generic `commerce` or `billing` payload blobs in core
  - silent fallback from a native storefront route into a web checkout flow

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/PROJECT.md` — v3.0 milestone framing, Phoenix-first thesis, and explicit no-wrapper / no-client-authority constraints
- `.planning/REQUIREMENTS.md` — `COMM-01`, `COMM-02`, `COMM-03`, commerce scope guard, packaging ledger, proof posture gate, and support truth gate
- `.planning/ROADMAP.md` — Phase 13 goal, plans, and success criteria
- `.planning/STATE.md` — current milestone position and active concerns around commerce breadth and support honesty

### Prior locked decisions
- `.planning/phases/04-honest-offline-contract/04-CONTEXT.md` — append-only evidence, explicit reconciliation, backend authority, and fail-closed replay posture
- `.planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md` — explicit `:native_screen` corridor precedent and fail-closed native ownership rules
- `.planning/phases/11-capability-taxonomy-and-contract-rubric/11-CONTEXT.md` — backend-seam commerce classification, ownership rubric, and family vocabulary
- `.planning/phases/12-packaging-ledger-and-release-boundaries/12-CONTEXT.md` — `core` versus `companion` boundary, rebuild truth, and release posture for commerce seams

### Existing contract surfaces
- `guides/capabilities.md` — current backend-seam commerce framing, docs-only boundary, and denial/fallback expectations
- `guides/support_matrix.md` — current commerce family rows, package classification, prerequisites, denial, fallback, and rebuild posture
- `guides/native_shell.md` — native runtime boundary and rebuild-required posture for native-heavy changes
- `guides/bridge.md` — bounded bridge contract and anti-patterns around widening route-local authority
- `guides/compatibility.md` — compatibility and rebuild truth that commerce companions must obey
- `guides/adopter_profiles.md` — current non-goals and examples that Phase 13 must stay coherent with

### Existing code truth
- `lib/crosswake/manifest/builder.ex` — current paywall/purchase/restore/entitlement_snapshot catalog rows and commerce prerequisites/fallbacks
- `lib/crosswake/manifest/types.ex` — typed contract surfaces and reconciliation-related manifest types
- `lib/crosswake/offline/contracts.ex` — existing explicit reconciliation model and typed contract style
- `lib/crosswake/support_matrix/support_matrix.ex` — current package and commerce support rendering model
- `lib/crosswake/support_matrix/renderer.ex` — generated support output shape
- `lib/crosswake/policy/validator.ex` — current provider-capability vocabulary boundary

### Research and design inputs
- `prompts/crosswake-gsd-project-brief.md` — product framing, billing-policy boundaries, and companion context
- `prompts/crosswake-integrations-and-companions.md` — billing and companion classification heuristics
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — subscription/paywall lane pressure, native-screen billing examples, and entitlement footguns
- `prompts/elixir-mobile-oss-lib-deep-research.md` — paywall UX, verification, audit, fixtures, and companion-billing guidance
- `prompts/crosswake-elixir-oss-dna.md` — install truth, support honesty, proof posture, and package-boundary discipline

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Manifest.Builder.capability_catalog/0` already defines `paywall`, `purchase`, `restore`, and `entitlement_snapshot` as backend seams with explicit prerequisites and fallbacks.
- `Crosswake.Manifest.Types` already gives Crosswake a typed-contract style that Phase 13 can extend without inventing a plugin-like payload bus.
- `Crosswake.Offline.Contracts` demonstrates the project’s existing preference for explicit authority, append-only evidence, and named reconciliation semantics.
- `Crosswake.SupportMatrix` already renders package/rebuild/prerequisite truth and can absorb commerce-specific rules later in Phase 14.

### Established Patterns
- Crosswake prefers small typed structs and registries over generic command surfaces.
- Backend-owned truth, explicit denial behavior, and fail-closed support claims are already project-wide norms.
- Native-heavy or provider-heavy capabilities are classified into explicit companions with rebuild truth rather than hidden inside `core`.
- Example/docs-only surfaces teach boundaries first and avoid implying runnable support before proof exists.

### Integration Points
- Commerce structs and vocabularies should connect to manifest capability metadata and support-matrix rendering.
- Reconciliation vocabulary should align with existing offline contract semantics so the project speaks one language about evidence, replay, and authority.
- Future companion work will need to plug into native route ownership, compatibility lines, and support-matrix rendering without redefining the contract.

</code_context>

<deferred>
## Deferred Ideas

- Shipping StoreKit, Play Billing, RevenueCat, or other provider-specific adapters in `core`
- Turning Crosswake core into a full billing engine, event store, or hosted commerce workflow system
- Promoting docs-only commerce examples into runnable supported example-host lanes before companion, proof, and support posture land
- Offline purchase replay or device-authoritative entitlement mutation
- Broad native billing modules as the default story for ordinary Phoenix adopters

</deferred>

---

*Phase: 13-commerce-and-entitlement-contract*
*Context gathered: 2026-05-19*
