# Phase 70: Subscription SaaS Commerce Proof - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove a production-shaped subscription SaaS commerce lane over the real Crosswake commerce contracts: provider-shaped purchase and restore evidence flows through the example-host storefront facade, reconciliation inbox, backend verification/projection, and Paywall LiveView state without ever granting entitlement authority from client/device/storefront success alone.

This phase is an archetype proof lane, not a starter billing app and not a new commerce abstraction. The output should be a deterministic, CI-hermetic proof that SAAS-01 and SAAS-02 hold across purchase, restore, backend verification, and UI/status presentation.

</domain>

<spec_lock>
## Design Contract (locked via UI-SPEC.md)

The Phase 70 UI design contract is locked in `70-UI-SPEC.md`. Downstream agents MUST read it before planning or implementing any UI work.

**Locked posture:** Phoenix LiveView defaults, Heroicons if icons are needed, system sans font, restrained light/system styling, accent reserved for subscribe/restore/active entitlement affordances, and no shadcn or external component library.

**Important correction for planning:** the UI-SPEC copy is a draft contract, not permission to implement unscoped subscription management. Cancellation, invoice history, payment method editing, plan changes, hosted portals, and billing account management remain out of scope unless already present as read-only proof/status metadata.

</spec_lock>

<decisions>
## Implementation Decisions

### Proof Lane Architecture
- **D-01:** Build a new targeted hermetic proof module: `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`.
- **D-02:** The Phase 70 proof should be one integrated product-shaped SaaS story, not a rerun of Phase 34 plus Phase 48. Prior tests remain regression context, but Phase 70 must prove the combined purchase/restore -> reconciliation -> backend projection -> entitlement state lane.
- **D-03:** Keep the merge-blocking lane pure ExUnit with `Code.require_file` for the needed example-host commerce modules. Do not start Endpoint, Repo, PubSub, LiveView server infrastructure, network calls, simulators, provider SDKs, or device lanes.
- **D-04:** Use deterministic inline fixtures or narrowly scoped fixture helpers with fixed timestamps, stable IDs, and explicit provider-shaped evidence. Add a small hermeticity self-scan guard similar to Phase 34.
- **D-05:** Add `.github/workflows/phase70-proof.yml` shaped like Phase 48: pinned actions, `permissions: contents: read`, compile with warnings as errors, a targeted merge-blocking job running the Phase 70 proof file, and an advisory provider/device job that never gates merge.

### Backend Authority Boundary
- **D-06:** Keep `ReconciliationInbox` evidence-only and `EntitlementProjection.project_snapshot/2` as the authority gate. `ReconciliationInbox.ingest_evidence/2` may produce `:awaiting_verification`; it must not mutate authority or derive `:granted`.
- **D-07:** Introduce a richer example-host fake backend verifier only if needed to make the proof adversarial. It may consume normalized `ReconciliationEvidence` and deterministic provider-shaped fixtures, but it must emit authority only as verified `%EntitlementSnapshot{}` outputs.
- **D-08:** Do not add Ecto schemas, migrations, persisted inbox tables, an outbox, or a generic event-sourcing workflow in Phase 70. In production guidance, Ecto unique constraints and `Ecto.Multi` are idiomatic for persisted reconciliation/projection, but this phase is a hermetic archetype proof.
- **D-09:** Add hard negative tests proving authority does not move for storefront success alone, device evidence alone, pending purchase, pending restore, duplicate replay with a different `correlation_id`, stale `as_of`, revoked/refunded/expired provider result, invalid provider vocabulary, and direct authority override attempts.
- **D-10:** Projection remains monotonic and backend-owned. A stale incoming authority snapshot should fail closed as `:stale_authority`, not overwrite a fresher granted state.

### Provider Facade And Restore Semantics
- **D-11:** Use the existing configured provider facade as the Phase 70 spine: `CrosswakeExample.Commerce.StorefrontAdapter` behaviour, `MockStorefront` as default, and `ProviderAdapterStorefront` selected by `:paywall_storefront_provider` for provider-shaped proof.
- **D-12:** Add a focused dual-provider matrix behind the same facade: StoreKit purchase, StoreKit restore, Play Billing purchase, Play Billing restore.
- **D-13:** Restore remains evidence-only. A restore callback proves that provider/backend lookup emitted normalized evidence; entitlement access changes only after backend verification/projection.
- **D-14:** Preserve provider identity fences: StoreKit subject identity should be based on subscription lineage (`original_transaction_id`), while individual purchase/restore events may carry distinct transaction/notification IDs. Play Billing identity should key around `purchase_token`, with new-token/resubscribe cases modeled only as proof fixtures if needed.
- **D-15:** Do not add Stripe, RevenueCat, Paddle, or generic aggregator vocabulary to the provider facade. Those are useful comparables for UX and lifecycle footguns, but they are not Phase 70 adapters.
- **D-16:** If API naming is touched, keep the long-term shape boring and least-surprise: `purchase(intent)` / `restore(intent)` would be better public vocabulary, while `simulate_purchase/1` and `simulate_restore/1` are acceptable as example-host proof names.

### Paywall UI, UX, And DX
- **D-17:** Polish the existing Paywall LiveView states rather than adding a full subscription management product. The four proof states remain `:stale`, `:pending`, `:denied`, and `:granted`.
- **D-18:** Add at most a compact read-only backend entitlement status block showing projection state, freshness, reconciliation posture, effective period/reference, and authority source. Do not build invoice history, payment method editing, cancellation, plan changes, seats, tax, or hosted portal flows.
- **D-19:** Add a secondary proof/DX posture row or compact badges: `Route owner: Phoenix LiveView`, `Purchase/restore: native or companion corridor`, `Authority: backend entitlement projection`, `Provider proof: hermetic mock/provider-shaped evidence`. Keep it visually secondary so the example does not become an in-app tutorial.
- **D-20:** Make state changes accessible: changing entitlement status should use `role="status"` or an equivalent polite live region; purchase/restore controls should be real buttons with loading/disabled behavior during pending operations; headings and focus behavior should stay semantic.
- **D-21:** Use system-aware light/dark styling with CSS variables or existing app styles. Do not add a theme switcher or a broad design-system project.
- **D-22:** Use status-oriented microcopy that tells the truth: examples include "Subscribe to Pro Monthly", "Restore purchase", "Verifying backend entitlement", "Access active from backend projection", and "Unable to verify access". Avoid copy that implies unimplemented cancellation/account-management behavior.

### The Agent's Discretion
- Exact test helper names, fixture file names, and whether the richer fake backend verifier is a new module or an extension of `MockBackend`, as long as it stays example-host/proof-only and does not introduce Ecto or a generic billing framework.
- Exact workflow job names and whether Phase 34/48 regression tests run as separate context steps, as long as the Phase 70 proof file is the named merge-blocking signal.
- Exact UI layout within the locked `70-UI-SPEC.md` constraints, as long as it remains a restrained Phoenix-owned proof surface and not a starter subscription portal.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked contracts
- `.planning/PROJECT.md` — Crosswake thesis, v4.1 milestone posture, backend-owned authority, and non-goals.
- `.planning/REQUIREMENTS.md` — SAAS-01, SAAS-02, and PROOF-01 traceability.
- `.planning/ROADMAP.md` — Phase 70 goal, success criteria, UI hint, and Phase 71 dependency.
- `.planning/STATE.md` — current v4.1 position and pending todo about mock storefront adapters not bleeding into production runtime code.
- `.planning/MILESTONE-ARC.md` — v4.1 archetype-proof goal, hermetic proof requirement, and non-goals for starter apps/new abstractions.
- `.planning/phases/70-subscription-saas-commerce-proof/70-UI-SPEC.md` — locked visual/copy/design constraints for any Phase 70 UI work.

### Existing commerce and provider code
- `lib/crosswake/commerce/contracts.ex` — canonical commerce structs and entitlement lane vocabularies.
- `lib/crosswake/commerce/reconciliation.ex` — authority mutation fence for reconciliation evidence.
- `lib/crosswake/commerce/provider_evidence.ex` — provider vocabulary and normalized event status boundaries.
- `lib/crosswake/companions/store_kit/evidence.ex` — StoreKit provider evidence normalization.
- `lib/crosswake/companions/play_billing/evidence.ex` — Play Billing provider evidence normalization.
- `examples/phoenix_host/lib/crosswake_example/commerce/storefront_adapter.ex` — example-host storefront behaviour.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — default hermetic mock storefront evidence emitter.
- `examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex` — configured StoreKit/Play Billing facade.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — append-only evidence ingestion path.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — provider-aware event/subject identity helpers.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — backend-owned projection gate and derived UI state.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` — current pure-Elixir mock backend verification/projection bridge.
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` — existing Paywall LiveView surface.

### Existing proof and workflow patterns
- `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` — hermetic purchase -> reconciliation -> entitlement proof pattern and authority fence.
- `test/crosswake/proof/phase34_mock_storefront_test.exs` — mock storefront identity and replay proof pattern.
- `test/crosswake/proof/phase35_paywall_live_test.exs` — LiveView state and provider-vocabulary UI fence.
- `test/crosswake/proof/phase48_provider_adapter_proof_test.exs` — provider facade, StoreKit/Play Billing evidence, and advisory proof posture.
- `.github/workflows/phase34-proof.yml` — hermetic vs advisory commerce proof split.
- `.github/workflows/phase48-proof.yml` — targeted provider adapter proof lane shape.
- `test/support/proof_assertions.ex` — fixture and exact-doc assertion helpers.

### Prompt corpus and project vision
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style: proof lanes as product, support truth, deterministic example-host proof, and public-contract honesty.
- `prompts/crosswake-brand-book.md` — boundary-aware messaging and anti-hype/non-magic copy constraints.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — billing/entitlement strategy, server entitlement truth, restore purchase posture, and billing test guidance.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — subscription SaaS/paywalled app fit, native payment boundary, and footgun of treating purchase success as entitlement success.

### External ecosystem references considered during discussion
- Apple StoreKit/App Store Server APIs and notifications — provider transaction evidence, restore, signed server-side lifecycle posture, notification UUID/duplicate handling.
- Google Play Billing backend, subscription lifecycle, and RTDN docs — backend verification, purchase token identity, lifecycle refresh, and notification-as-change-signal posture.
- Stripe webhooks and Customer Portal docs — webhook verification/idempotency and the risk that account management becomes a separate product surface.
- Phoenix contexts and `Ecto.Multi` docs — production guidance for persisted reconciliation/projection, explicitly deferred from this hermetic phase.
- Phoenix LiveView bindings/JS docs and WAI/WCAG status-message guidance — accessible pending/granted state transitions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CrosswakeExample.Commerce.StorefrontAdapter` — already gives a narrow behaviour seam for purchase/restore facade proof.
- `CrosswakeExample.Commerce.ProviderAdapterStorefront` — already emits StoreKit/Play Billing-shaped normalized evidence behind app-env provider selection.
- `CrosswakeExample.Commerce.ReconciliationInbox` — already preserves evidence-only ingestion with replay metadata.
- `CrosswakeExample.Commerce.ReconciliationKeys` — already separates event identity, subject identity, and trace-only correlation metadata.
- `CrosswakeExample.Commerce.EntitlementProjection` — already rejects unverified reconciliation states and enforces monotonic projection.
- `CrosswakeExample.Commerce.MockBackend` — already creates verified snapshots; can be extended into a richer fake verifier if Phase 70 needs refund/revoke/stale scenarios.
- `CrosswakeExample.PaywallEntryLive` — existing state UI and event hooks for subscribe/restore.

### Established Patterns
- Hermetic merge-blocking proof uses pure ExUnit and `Code.require_file`; provider/device/simulator lanes stay advisory.
- Provider vocabularies stay fenced to adapter/evidence modules and never leak into route policy, UI states, or entitlement authority vocabulary.
- Backend authority is promoted only through verified snapshots; client/native/storefront signals are evidence only.
- Example-host proof should be copy-able and useful, but not become a product template or billing framework.
- Support truth and rough-edge language are product surface; do not overclaim real provider/device support from hermetic evidence.

### Integration Points
- New proof file under `test/crosswake/proof/`.
- Optional new or extended example-host fake verifier under `examples/phoenix_host/lib/crosswake_example/commerce/`.
- Optional narrow Paywall LiveView render/copy updates in `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex`.
- New targeted CI workflow `.github/workflows/phase70-proof.yml`.
- Possible docs/support parity updates only where Phase 70 proof posture needs to be visible.

</code_context>

<specifics>
## Specific Ideas

- Preferred proof story: StoreKit-shaped purchase evidence -> `ReconciliationInbox` returns `:awaiting_verification` -> pending UI/projection state -> direct projection rejected -> fake backend verifier emits verified snapshot -> `EntitlementProjection.derived_state/1 == :granted`.
- Preferred restore story: Play Billing-shaped restore evidence -> stable provider subject identity -> pending evidence-only state -> backend projection required before grant.
- Provider matrix should cover StoreKit purchase, StoreKit restore, Play Billing purchase, Play Billing restore.
- Negative cases should include duplicate replay with different `correlation_id`, stale authority, unverified pending restore, revoked/refunded/expired provider result, invalid provider enum/status, and direct grant attempt from evidence.
- UI should include a compact proof posture row and backend entitlement status block, both secondary to the real paywall actions.

</specifics>

<deferred>
## Deferred Ideas

- Ecto-backed reconciliation inbox/projection tables, unique constraints, and `Ecto.Multi` transaction shape — production guidance or future hardening, not Phase 70.
- Generic event/outbox or audit workflow — future audit/reconciliation hardening, likely after v4.1 exposes the event surfaces worth auditing.
- Full subscription/account portal: invoices, payment methods, cancellation, plan changes, seats, tax, hosted portal flows — out of scope for Crosswake archetype proof.
- Real StoreKit/Play Billing sandbox/device merge gate — advisory only until explicit promotion criteria repeatedly pass.
- RevenueCat, Paddle, Stripe, or generic billing aggregator adapters — useful comparables, not Phase 70 scope.

</deferred>

---

*Phase: 70-subscription-saas-commerce-proof*
*Context gathered: 2026-06-04*
