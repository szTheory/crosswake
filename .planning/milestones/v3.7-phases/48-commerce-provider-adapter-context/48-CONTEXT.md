# Phase 48: Commerce Provider Adapter Context - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Plan first-party StoreKit and Play Billing adapter seams that feed existing
backend-owned commerce reconciliation contracts.

**Delivers:**
- First-party provider adapter seams for StoreKit and Play Billing that emit
  normalized `Crosswake.Commerce.Contracts.ReconciliationEvidence`.
- Provider-specific evidence normalization rules that preserve stable
  idempotency, environment visibility, signed evidence provenance, and
  backend-owned entitlement authority.
- Purchase and restore choreography that uses bounded semantic bridge events,
  not high-frequency provider event streams or client-owned access decisions.
- Advisory-to-merge-blocking promotion criteria for provider proof.
- Reviewer/storefront guidance and support truth that distinguishes shipped
  adapter seams from provider/device proof posture.

**Satisfies:** ADPT-01, ADPT-02, and ADPT-03.

**In scope:**
- StoreKit and Play Billing companion-owned adapter seams.
- Typed provider evidence structs that map into existing commerce contracts.
- Purchase and restore intent/result lifecycle hints that remain low-frequency.
- Hermetic adapter contract proof plus advisory provider/device/storefront lanes.
- Support matrix, doctor/readiness, changelog, and reviewer guide truth for
  v3.7 provider adapters.

**Out of scope:**
- Device-local entitlement grants.
- Universal billing engine semantics in core.
- Raw provider enum leakage into public Crosswake contracts.
- Raw transaction event streams over the bridge.
- RevenueCat or additional provider adapters.
- Offline purchase replay or local-first entitlement mutation.

</domain>

<decisions>
## Implementation Decisions

### 1. Adapter Surface Shape - LOCKED
- **D-01:** Ship StoreKit and Play Billing as first-party companion seams, not
  as generic core abstractions and not as native-shell-only examples.
- **D-02:** Core `crosswake` keeps the provider-neutral commerce contracts,
  reconciliation vocabulary, support truth, doctor hooks, and typed validation
  helpers. Provider SDK churn and platform-specific coordination live in
  companion/provider surfaces.
- **D-03:** The companion seam may call host-owned native coordinators on iOS
  and Android, but Crosswake owns the typed evidence contract, failure posture,
  support/readiness rows, and proof classification.
- **D-04:** Do not introduce a generic provider plugin bus. StoreKit and Play
  Billing establish two explicit first-party seams with closed provider names,
  compatibility/rebuild truth, and docs-contract parity.
- **D-05:** Companion support must fail closed when optional native/provider
  dependencies or route prerequisites are missing, using existing
  `commerce.corridor.*` denial/fallback posture.

### 2. Provider Evidence Normalization - LOCKED
- **D-06:** Add provider-specific normalized structs that map into the existing
  `Crosswake.Commerce.Contracts.ReconciliationEvidence` envelope.
- **D-07:** Use a small closed Crosswake event-kind vocabulary for the states
  Crosswake already models: `purchase`, `restore`, `renewal`, `grace_period`,
  `billing_retry`, `refund`, and `revoked`. Raw provider enums stay adapter
  metadata, not core event kinds.
- **D-08:** `provider_reference` is provider-subject identity. For StoreKit,
  use original transaction lineage (`original_transaction_id` /
  StoreKit 2 `originalID`). For Play Billing, use the purchase token lineage.
  Do not use order id, product id, or transient device correlation id as the
  subject authority key.
- **D-09:** `evidence_ref` is event-instance identity for replay/dedupe. For
  StoreKit, use transaction id, notification UUID, or signed payload digest as
  appropriate to the evidence source. For Play Billing, use RTDN message id,
  order context, or signed/raw payload digest as appropriate.
- **D-10:** Require an environment marker (`sandbox` / `production`, with
  provider-native variants captured as metadata) in normalized provider structs
  and surface it through support/doctor/operator output where useful.
- **D-11:** Preserve signed proof artifacts as evidence provenance: Apple JWS
  or digest, Play purchase token/RTDN payload digest, verification source, and
  captured time. These artifacts can feed backend verification but never grant
  authority directly.
- **D-12:** Keep backend idempotency dual-keyed: `event_key` for
  provider+provider_reference+event_kind+evidence_ref replay safety, and
  `subject_key` for provider+provider_reference projection ordering.

### 3. Purchase And Restore Choreography - LOCKED
- **D-13:** Use one-shot purchase/restore intent/result handoff as the primary
  bridge contract. The route asks for a provider workflow; native returns a
  typed result and/or normalized evidence; Phoenix reconciliation owns the rest.
- **D-14:** Allow only a small fixed lifecycle-hint taxonomy for UX and recovery:
  `flow_opened`, `flow_closed`, `pending_external`, `reconcile_required`, and
  `reconcile_timeout`. These hints are non-authoritative and cannot update
  entitlement authority or access directly.
- **D-15:** Do not bridge raw StoreKit `Transaction.updates`, Play Billing
  callbacks, or provider lifecycle streams into Phoenix/LiveView as public
  Crosswake events.
- **D-16:** Required result taxonomy should distinguish at least:
  `submitted`, `user_canceled`, `pending`, `provider_error`,
  `prerequisite_missing`, and `reconcile_required`.
- **D-17:** Restore is a reviewer-visible first-class flow. It requests
  reconciliation for prior provider purchases; it does not grant access until
  backend projection refreshes an authoritative entitlement snapshot.
- **D-18:** Adapter-internal provider duties such as StoreKit transaction finish
  handling and Play Billing acknowledgement/consumption are implementation
  responsibilities that result in evidence and backend verification, not direct
  access grants.

### 4. Proof And Promotion Criteria - LOCKED
- **D-19:** Use a two-tier proof model. Merge-blocking proof covers hermetic
  contract fixtures, provider evidence mapping, backend authority invariants,
  docs/support/doctor parity, and simulator/provider-SDK correctness where it
  is deterministic. Sandbox/device/storefront evidence remains advisory unless
  explicit promotion criteria pass.
- **D-20:** Promotion target for v3.7 is not "all provider evidence is
  merge-blocking." It is "core adapter correctness is merge-blocking;
  environment-sensitive provider proof is advisory unless separately promoted."
- **D-21:** Add criteria-as-code promotion rules for these claims:
  `purchase_intent.provider.storekit`, `restore_intent.provider.storekit`,
  `purchase_intent.provider.play_billing`, and
  `restore_intent.provider.play_billing`.
- **D-22:** Each promotion rule must include required evidence set, platforms,
  minimum consecutive passes or equivalent repeatability threshold, freshness
  window, failure budget, docs anchors, check ids, rebuild/action class, and
  demotion trigger.
- **D-23:** Backend-authority invariants are mandatory in merge-blocking proof:
  device/storefront evidence never mutates entitlement authority directly,
  pending/awaiting verification never grants access, replay keys are stable,
  and raw provider enums do not leak into core contracts.
- **D-24:** Manual app-review evidence, sandbox accounts, and physical-device
  runs are archival advisory artifacts until Crosswake has a stable funded
  release-only gate or a future phase explicitly promotes them.

### 5. Reviewer And Support Truth - LOCKED
- **D-25:** Keep `Crosswake.SupportMatrix` as the only claim-authoritative
  support source. Authored reviewer guides cannot define new support states.
- **D-26:** Use a layered guide model: generated canonical support truth,
  authored advisory StoreKit/Play reviewer templates bound to canonical columns,
  and explicit rough-edge/non-claim language.
- **D-27:** Add provider setup/readiness checklist metadata with stable doctor
  check ids. Treat checklist completion as support/readiness evidence, not as
  provider certification or entitlement authority.
- **D-28:** Provider-facing docs must restate backend-owned entitlement
  authority, fail-closed corridor denial vocabulary, proof class, and rebuild
  requirement at the point of use.
- **D-29:** Changelog and release guidance must distinguish "v3.7 adapter seams
  shipped" from provider proof class, promotion state, and published Hex truth.
- **D-30:** Green advisory storefront/provider runs must not implicitly promote
  support class, remove warnings, or widen public claims without the ADPT-03
  promotion rule passing.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-31:** Import the Phoenix/Plug/Ecto lesson: explicit structs, closed
  vocabularies, behaviours only where they clarify ownership, and boring
  validation beat hidden adapter inference.
- **D-32:** Import the companion/native ecosystem lesson from Capacitor,
  Hotwire Native, Expo, and React Native IAP: platform-specific provider code
  needs compatibility and rebuild truth; treating it as stable core too early
  creates support drift.
- **D-33:** Import the billing ecosystem lesson from StoreKit, Play Billing,
  Stripe, and RevenueCat: stable idempotency, signed evidence provenance,
  backend verification, and reviewer guidance matter more than client-side
  success callbacks.
- **D-34:** Import the CI ecosystem lesson from Expo/Firebase/Kubernetes:
  environment-sensitive proof is valuable but must be classified, repeatable,
  and demotable before it blocks merges.
- **D-35:** Import the Django/Terraform lesson: stable check ids,
  machine-readable readiness, compatibility requirements, and human docs serve
  different readers but must derive from the same canonical truth.

### the agent's Discretion
- Exact module names are planner discretion. Strong defaults:
  `Crosswake.Companions.StoreKit`, `Crosswake.Companions.PlayBilling`, and
  provider evidence structs under those namespaces.
- Exact native coordinator names and Swift/Kotlin file layout are planner
  discretion if host-owned native responsibilities and rebuild truth remain
  explicit.
- Exact event-kind atom names are planner discretion if the vocabulary remains
  closed, provider-neutral, and mapped from raw provider enums.
- Exact promotion thresholds are planner discretion, but weak promotion should
  fail closed to advisory.
- Exact guide layout is planner discretion. Preserve generated canonical tables,
  advisory reviewer templates, and source-map/docs-contract tests.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/ROADMAP.md` section "Phase 48: Commerce Provider Adapter Context"
  - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "v3.7 Requirements" - ADPT-01, ADPT-02,
  and ADPT-03.
- `.planning/PROJECT.md` - Crosswake thesis, v3.7 current milestone, core
  guardrails, and provider-adapter non-goals.
- `.planning/STATE.md` - current position, blockers, and deferred provider
  proof posture.
- `.planning/MILESTONE-ARC.md` - strategic rationale for v3.7 and required
  proof/support outputs.

### Prior Phase Decisions
- `.planning/phases/53-release-continuity-and-closeout-hardening/53-CONTEXT.md`
  - release/changelog truth, closeout routing, and unreleased-vs-published
  support language.
- `.planning/phases/52-operator-proof-and-docs/52-CONTEXT.md` - proof topology,
  docs-contract lock shape, stable drift ids, and advisory provider proof
  posture.
- `.planning/phases/51-support-matrix-and-native-rebuild-truth/51-CONTEXT.md`
  - support/proof/rebuild/action axes, promotion rules, public non-claims, and
  provider adapter support rows.
- `.planning/phases/50-doctor-publish-and-readiness-checks/50-CONTEXT.md` -
  doctor readiness categories, stable ids, severity semantics, and deferred
  claim guardrails.
- `.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` -
  route-authoritative inspection, JSON/human boundary, and support condition
  derivation.
- `.planning/milestones/v3.2-phases/23-commerce-support-and-proof-closure/23-CONTEXT.md`
  - commerce support/proof/rebuild posture and hermetic/advisory provider proof
  split.
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md`
  - mocked storefront swap-target boundary and idempotency decisions.
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-CONTEXT.md`
  - backend projection, four-state LiveView, and reconciliation authority flow.

### Existing Code Surfaces
- `lib/crosswake/commerce/contracts.ex` - canonical commerce structs,
  `ReconciliationEvidence`, entitlement lanes, and source vocabulary.
- `lib/crosswake/commerce/reconciliation.ex` - backend-owned ingestion,
  idempotency key shape, and authority-mutation fence.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` -
  pure mock storefront adapter and the two swap-target functions for real
  provider adapters.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`
  - event/subject key precedent and trace-only correlation id handling.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
  - append-only evidence ingestion example.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
  - authoritative projection and derived-state precedent.
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` -
  current mocked purchase/restore LiveView UX precedent.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support,
  commerce corridor, promotion, action/rebuild, companion, notification, and
  provider adapter truth.
- `lib/crosswake/doctor/publish_readiness.ex` - publish/readiness diagnostics
  and provider-adapter non-claim precedent.
- `lib/crosswake/operator_inspection.ex` - operator inspection assembly and
  support/readiness propagation.
- `lib/crosswake/manifest/types.ex` - manifest support/action/promotion
  serialization precedent.

### Existing Tests And Workflows
- `test/crosswake/commerce/contracts_test.exs` - commerce contract validation
  precedent.
- `test/crosswake/commerce/reconciliation_test.exs` - reconciliation authority
  and idempotency tests.
- `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` - hermetic
  mocked paywall proof and anti-grant fence.
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` - commerce
  support and advisory proof split precedent.
- `test/crosswake/proof/phase52_operator_truth_test.exs` - operator/support/
  docs-contract proof precedent.
- `test/crosswake/guides/commerce_test.exs` - commerce guide docs-contract
  precedent.
- `test/support/proof_assertions.ex` - stable proof assertion helpers.
- `.github/workflows/phase23-proof.yml` - original commerce hermetic/advisory
  split.
- `.github/workflows/phase34-proof.yml` - mocked paywall proof lane.
- `.github/workflows/phase52-proof.yml` - operator proof and advisory lane
  naming precedent.

### Public Guides And Release Truth
- `guides/commerce.md` - provider-neutral commerce contract, advisory reviewer
  templates, backend authority, and v3.6 non-claims.
- `guides/support_matrix.md` - rendered support, proof, action, rebuild, and
  promotion truth.
- `guides/native_shell.md` - native rebuild, shell boundary, and rough-edge
  language.
- `guides/compatibility.md` - compatibility axes and runtime-line language.
- `guides/companions.md` - companion seam pattern, optional dependency
  diagnostics, and in-tree first-party companion posture.
- `CHANGELOG.md` - public release history and published-vs-unreleased support
  boundary.

### Prompt Corpus
- `prompts/crosswake-brand-book.md` - boundary-aware positioning and no-magic
  language.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, support matrices,
  proof lanes, release truth, and optional surface honesty.
- `prompts/crosswake-gsd-project-brief.md` - route policy, adapter ladder, and
  Phoenix-first mobile substrate thesis.
- `prompts/crosswake-integrations-and-companions.md` - companion classification
  model and provider/companion sequencing.
- `prompts/crosswake-research-synthesis.md` - canonical architecture thesis and
  runtime ownership ladder.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` -
  native SDK adapter level and route/runtime policy lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - Hotwire-style shell,
  optional billing hooks, and ecosystem comparison.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - three-plane route,
  component/capability, and server event/command model.

### External Platform References
- `https://developer.apple.com/documentation/storekit/in-app-purchase` -
  StoreKit purchase, transaction, entitlement, and signed transaction context.
- `https://developer.apple.com/documentation/appstoreserverapi` - App Store
  Server API, JWS-signed transaction/renewal data, sandbox behavior, and
  server-side transaction history.
- `https://developer.android.com/google/play/billing/integrate` - Play Billing
  purchase flow, query/acknowledgement guidance, and backend verification
  cautions.
- `https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products`
  - Play Developer API purchase token, order id, purchase state, consumption,
  acknowledgement, and test/promo metadata.
- `https://developer.android.com/google/play/billing/lifecycle/subscriptions`
  - Play subscription lifecycle, purchase-token validity, subscription state,
  and acknowledgement expectations.
- `https://developer.apple.com/app-store/review/guidelines/` - reviewer
  expectations and restore/app-review context.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce.Contracts.ReconciliationEvidence` already has the right
  canonical envelope for evidence-only provider output. v3.7 should extend
  validation/mapping around it rather than replacing it.
- `Crosswake.Commerce.Reconciliation.ingest_evidence/2` already rejects direct
  authority overrides and computes provider-aware idempotency. Provider adapters
  should feed this path.
- `CrosswakeExample.Commerce.MockStorefront` is the exact provider swap target:
  replace `simulate_purchase/2` and `simulate_restore/2` with StoreKit/Play
  adapter evidence emitters while leaving reconciliation/projection unchanged.
- `CrosswakeExample.Commerce.ReconciliationKeys` already models `event_key`,
  `subject_key`, and correlation-id trace metadata; provider adapters should
  preserve that separation.
- `Crosswake.SupportMatrix` already contains commerce corridor prerequisite
  classes, provider-adapter action classes, and promotion-rule vocabulary that
  v3.7 can extend rather than redesign.
- `Crosswake.Doctor.PublishReadiness` already reports provider-adapter
  non-shipped/readiness findings; v3.7 should transform those into shipped seam
  plus proof-class/promotion-state findings.

### Established Patterns
- Crosswake keeps public support truth split across support status, proof class,
  diagnostic severity, rebuild/action class, and promotion rule. Provider
  adapters must not collapse those axes into one "ready" flag.
- Example-host proof is hermetic and pure by default, with provider/device
  checks advisory until repeatability is proven.
- Guides are partly generated/canonical and partly authored advisory prose;
  docs-contract tests lock the boundary.
- Companion seams are typed, fail closed on optional dependency gaps, emit
  telemetry/diagnostics, and remain route-local rather than generic plugins.

### Integration Points
- Route policy and manifest support for `purchase_intent` and `restore_intent`
  corridors.
- Native shells / host-native coordinators for StoreKit and Play Billing
  purchase/restore flows.
- Phoenix reconciliation inbox and entitlement projection examples.
- Support matrix promotion rows for StoreKit/Play purchase and restore claims.
- Doctor/readiness checks and operator inspection provider readiness output.
- Commerce guide reviewer templates, support matrix rendering, changelog, and
  proof workflows.

</code_context>

<specifics>
## Specific Ideas

- Strong default architecture: first-party companion seams wrapping
  provider-specific native coordinators and emitting typed evidence to Phoenix.
- Preferred evidence shape: provider-specific normalized structs mapped into
  existing `ReconciliationEvidence`; do not widen core into a billing engine.
- Preferred flow: one-shot purchase/restore handoff plus a fixed, non-
  authoritative lifecycle-hint taxonomy.
- Preferred proof: two-tier promotion where deterministic adapter correctness is
  merge-blocking and environment-sensitive storefront/device proof remains
  advisory until criteria-as-code passes.
- Preferred docs: canonical generated support truth plus authored advisory
  reviewer templates and stable doctor checklist ids.

</specifics>

<deferred>
## Deferred Ideas

- RevenueCat adapter remains deferred until StoreKit and Play Billing establish
  the first-party provider adapter shape.
- Full provider certification or physical-device conformance gating remains
  deferred until there is stable funded infrastructure and a future phase
  explicitly promotes it.
- Offline purchase replay and local-first entitlement mutation remain out of
  scope.

</deferred>

---

*Phase: 48-Commerce Provider Adapter Context*
*Context gathered: 2026-06-01*
