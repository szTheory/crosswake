# Phase 70: Subscription SaaS Commerce Proof - Research

**Researched:** 2026-06-04
**Domain:** Commerce proof lanes, provider-shaped evidence, backend entitlement projection, restrained Paywall LiveView status UI
**Confidence:** HIGH - based on Phase 70 context, project requirements/state/roadmap, UI contract, existing proof lanes, workflows, commerce modules, and prompt corpus.

## Summary

Phase 70 should be planned as a single integrated SaaS commerce proof lane, not as a broad billing feature. The core deliverable is a deterministic ExUnit proof that runs in CI and proves:

- mock/provider-shaped StoreKit and Play Billing purchase/restore evidence can enter the existing storefront facade and reconciliation inbox;
- ingested purchase/restore evidence remains evidence-only and yields pending/awaiting verification state;
- entitlement projection changes only after backend-owned verification emits a verified `%EntitlementSnapshot{}`;
- restore pulls provider-shaped state through the same facade without trusting client evidence;
- negative cases fail closed: client success, direct override, pending restore, replay, stale authority, invalid provider vocabulary, refund/revoke/expire outcomes.

Primary implementation recommendation: create `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` as the merge-blocking artifact, backed by deterministic inline fixtures and a small richer fake backend verifier in `examples/phoenix_host/lib/crosswake_example/commerce/` if `MockBackend.build_verified_snapshot/2` is too grant-only and wall-clock-dependent for Phase 70's adversarial matrix.

No project-local skills were present under `.codex/skills/` or `.agents/skills/`.

## Requirement Coverage

| Requirement | Planning Implication |
|-------------|----------------------|
| SAAS-01 | Prove an E2E subscription SaaS corridor using mock storefront/provider adapters for StoreKit and Play Billing purchase/restore. |
| SAAS-02 | Assert the only grant path is backend promotion to a verified entitlement snapshot; client/device/storefront evidence alone must never mutate authority. |
| PROOF-01 context | Keep the Phase 70 merge-blocking lane hermetic, deterministic, and runnable without devices, provider SDKs, Endpoint, Repo, PubSub, network, or simulators. |

## Implementation Approach

### 1. Build One Integrated Hermetic Proof

Add `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`.

Use the existing `Code.require_file` pattern from Phase 34/48 to load only pure commerce modules:

- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/storefront_adapter.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex`
- optional new pure verifier module if added

Keep `use ExUnit.Case, async: false` if manipulating `Application` env for provider selection. Restore `:crosswake_example` env in `on_exit/1`, as Phase 48 does.

The proof should tell one product-shaped story:

1. StoreKit purchase evidence is emitted by `ProviderAdapterStorefront`.
2. `ReconciliationInbox.ingest_evidence/2` returns `status: :awaiting_verification`.
3. A pending snapshot derives `:pending` but `EntitlementProjection.project_snapshot/2` rejects it as `:unverified_reconciliation_outcome`.
4. Backend verifier emits a verified snapshot.
5. `EntitlementProjection.project_snapshot/2` accepts the verified snapshot.
6. `EntitlementProjection.derived_state/1` becomes `:granted`.
7. Repeat restore coverage using Play Billing to prove restore is facade/provider-backed and evidence-only until backend projection.

### 2. Add or Extend a Deterministic Fake Backend Verifier

Current `MockBackend.build_verified_snapshot/2` is useful but Phase 70 needs more than "always grant":

- it uses `DateTime.utc_now()` and `System.system_time/1`, which are less ideal for deterministic proof assertions;
- it only emits a granted terminal snapshot;
- Phase 70 needs stale, refund, revoke, expire, failed verification, and stale-authority scenarios.

Plan for one of these shapes:

- Extend `MockBackend` with a deterministic `build_snapshot(evidence, group_id, opts)` or `verify_evidence(evidence, opts)` function.
- Add a new pure example-host module such as `CrosswakeExample.Commerce.MockBackendVerifier` if avoiding churn in `MockBackend` is cleaner.

Recommended verifier behavior:

- consumes normalized `%Crosswake.Commerce.Contracts.ReconciliationEvidence{}`;
- accepts fixed `checked_at`, `effective_from`, `effective_until`, `as_of`, `authority_state`, `access_decision`, and `reconciliation_state` options;
- defaults to `:projection_refreshed`, `:active`, `:granted`, fixed ISO timestamps, and fixed integer `as_of`;
- maps provider lifecycle outcomes:
  - `purchase`, `restore`, `renewal`, `grace_period`, `billing_retry` can be verified, but only backend verification may grant;
  - `refund`, `revoked`, and expired fixtures should produce denied derived state;
  - unknown/invalid event kinds should fail before authority projection.

Do not add Ecto schemas, migrations, persistent inbox tables, outbox machinery, generic event sourcing, Stripe/RevenueCat/Paddle vocabulary, or provider SDK calls.

### 3. Keep Existing Ownership Boundaries

Use these current modules as the implementation spine:

- `CrosswakeExample.Commerce.StorefrontAdapter` is the facade contract.
- `MockStorefront` remains the default hermetic mock adapter.
- `ProviderAdapterStorefront` already supports configured StoreKit/Play Billing purchase and restore.
- `ReconciliationInbox` records evidence and replay metadata only.
- `ReconciliationKeys` keeps event identity, subject identity, and trace-only correlation metadata separate.
- `EntitlementProjection.project_snapshot/2` is the authority gate and monotonic `as_of` guard.
- `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` returns false and should be asserted directly.

### 4. Add Phase 70 Workflow

Add `.github/workflows/phase70-proof.yml` following `.github/workflows/phase48-proof.yml`:

- `permissions: contents: read`;
- pinned `actions/checkout@...` and `erlef/setup-beam@...`;
- PR, push to main, workflow_dispatch with `lane` input, weekly schedule;
- merge-blocking macOS job that runs:
  - `mix deps.get`
  - `mix compile --warnings-as-errors`
  - `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`
- advisory provider/device job with `continue-on-error: true`, credential-gated StoreKit/Play Billing notices, and no merge gate authority.

Phase 34's broad proof lane is useful commentary, but Phase 48 is the closer workflow template because it already has pinned actions, permissions, a targeted proof file, and advisory provider/device split.

### 5. UI Polish Should Stay Narrow

`70-UI-SPEC.md` is a locked visual contract but contains draft billing-portal copy that conflicts with Phase 70 scope. Planning should honor the Phase 70 context correction over the draft UI copy:

- Phoenix LiveView defaults only;
- no shadcn or external component library;
- system font, restrained light/system styling, accent only for subscribe/restore/active entitlement;
- accessible pending/granted/denied/stale status presentation;
- no cancellation, invoices, payment method editing, plan changes, seats, tax, hosted portal, or account management.

Existing `PaywallEntryLive` has a few plan-worthy targets:

- remove or replace the "Manage subscription" link because subscription management is out of scope;
- use copy such as "Subscribe to Pro Monthly", "Restore purchase", "Verifying backend entitlement", "Access active from backend projection", and "Unable to verify access";
- add a compact read-only status block only if needed: projection state, freshness, reconciliation posture, effective period/reference, authority source;
- add `role="status"` or equivalent polite live region around changing entitlement state;
- keep buttons as real `<button>` controls and model loading/disabled behavior only if the implementation touches UI callbacks;
- avoid provider vocabulary in user-facing states, preserving the Phase 35 fence.

Do not move purchase/restore authority into LiveView. The LiveView can initiate evidence submission and render state; backend projection remains authoritative.

## Existing Files And Patterns To Reuse

### Proof Files

| File | Reuse Pattern |
|------|---------------|
| `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | Hermetic pure ExUnit, `Code.require_file`, pending-to-granted proof, authority fence, self-scan guard, exact rejection of unverified reconciliation. |
| `test/crosswake/proof/phase34_mock_storefront_test.exs` | Mock storefront fixture shape, identity/replay assertions, correlation ID as trace-only, restore subject identity parity. |
| `test/crosswake/proof/phase35_paywall_live_test.exs` | LiveView render/callback proof style if UI needs test coverage, provider-vocabulary fence, direct callback testing. Keep it out of merge-blocking Phase 70 unless deliberately adding a separate example-host lane. |
| `test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | Provider facade selection, StoreKit/Play Billing evidence normalization, Application env cleanup, provider identity assertions, advisory proof posture. |

### Workflow Files

| File | Reuse Pattern |
|------|---------------|
| `.github/workflows/phase34-proof.yml` | Explains hermetic merge gate vs advisory provider/device posture and promotion discipline. |
| `.github/workflows/phase48-proof.yml` | Best template for Phase 70: pinned actions, `permissions: contents: read`, targeted ExUnit proof, advisory provider sandbox/device job. |

### Commerce Modules

| File | Key Finding |
|------|-------------|
| `lib/crosswake/commerce/contracts.ex` | Canonical structs for `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence`, and `EntitlementSnapshot` lanes. |
| `lib/crosswake/commerce/reconciliation.ex` | Core evidence ingestion rejects direct `authority_state` override and never allows authority mutation from evidence. Useful direct negative assertion. |
| `lib/crosswake/commerce/provider_evidence.ex` | Canonical provider/event vocabularies; provider lifecycle hints never allow authority mutation. |
| `lib/crosswake/companions/store_kit/evidence.ex` | StoreKit normalization: original transaction ID as provider reference, transaction/notification/digest as event identity. |
| `lib/crosswake/companions/play_billing/evidence.ex` | Play Billing normalization: purchase token as provider reference, RTDN/order/digest as event identity. |
| `examples/phoenix_host/lib/crosswake_example/commerce/provider_adapter_storefront.ex` | Existing dual provider facade; supports StoreKit/Play purchase/restore and Play restore fixtures with fixed opts. |
| `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` | Evidence-only example-host inbox; success-like events become `:awaiting_verification`, not authority. |
| `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | Authority gate: rejects unverified reconciliation, derives `:pending` before grant, enforces monotonic `as_of`. |
| `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` | Current projection bridge; reuse for happy path or extend for deterministic negative lifecycle outcomes. |
| `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` | UI surface for narrow copy/status polish; avoid treating dev force handlers or rendered copy as authority proof. |

### Prompt Corpus

Relevant prompt findings:

- Subscription SaaS/paywalled apps are a first-class Crosswake target, but policy-sensitive.
- Billing/purchase flow often belongs to native StoreKit/Play Billing, while entitlement truth belongs to backend verification and projection.
- The key footgun is treating purchase success or receipt presence as entitlement success.
- Restore purchases must be supported.
- Avoid mapping provider-specific complexity into a magic generic adapter.
- Avoid broad support claims before proof lanes and docs exist.

## Risks And Footguns

- **Authority laundering:** A test that asserts provider evidence exists but not that `project_snapshot/2` rejects pending evidence will miss SAAS-02.
- **Grant-only mock backend:** Reusing `MockBackend.build_verified_snapshot/2` without richer negative fixtures can under-test refunds, revocations, expiry, stale authority, and failed verification.
- **Nondeterminism:** Wall-clock timestamps and `System.system_time/1` make exact proof assertions brittle. Use fixed timestamps and integer `as_of` values.
- **Application env leakage:** Provider facade tests mutate `:crosswake_example` config. Use `setup`/`on_exit` restoration.
- **Correlation ID misuse:** Correlation IDs are trace metadata, not event/subject identity. Replay tests should vary `correlation_id` while preserving provider identity.
- **Provider vocabulary leakage:** StoreKit/Play Billing names belong in adapter evidence/tests, not user-facing UI states or provider-neutral route/support truth.
- **UI scope creep:** The UI spec's cancellation/payment wording is draft copy, not Phase 70 permission. Do not build subscription management.
- **Hermeticity regression:** Merge-blocking Phase 70 must not start Endpoint, Repo, PubSub, LiveView server infrastructure, provider SDKs, simulators, network, or devices.
- **Mock code bleed:** Keep new verifier/proof helpers in example-host/proof-only modules; do not turn them into production runtime abstractions.
- **Restore overclaim:** Restore callback only proves provider/backend lookup emitted normalized evidence; access changes only after backend verification.

## Recommended Test Matrix

| Scenario | Expected Result |
|----------|-----------------|
| Mock storefront purchase through facade | Evidence ingested as `:awaiting_verification`; no authority grant before backend projection. |
| StoreKit purchase through provider facade | Provider-shaped evidence enters provider-neutral inbox; pending snapshot rejected by projection; verified backend snapshot grants. |
| StoreKit restore through provider facade | Restore evidence uses subscription lineage subject identity; pending until backend verification. |
| Play Billing purchase through provider facade | Purchase token identity is stable; pending until backend verification. |
| Play Billing restore through provider facade | Restore pulls provider state through facade; pending until backend projection. |
| Client success/device evidence only | `authority_mutation_allowed_from_evidence?/1 == false`; projection does not grant. |
| Direct authority override attempt | Core reconciliation rejects with `:authority_lane_mutation_forbidden`. |
| Duplicate replay, different correlation ID | Same event key/subject key; replay detected; no duplicate authority update. |
| Stale incoming authority snapshot | `project_snapshot/2` returns `{:error, {:stale_authority, snapshot}}` and preserves current fresher state. |
| Refund/revoked/expired provider outcome | Verified backend snapshot projects but derives `:denied`, not `:granted`. |
| Invalid provider/event vocabulary | Evidence constructor/facade returns error; no projection attempt. |
| Pending purchase/restore snapshot | `derived_state/1 == :pending`; `project_snapshot/2` rejects as unverified. |

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`, so the plan should create Wave-0 automated proof before implementation.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Merge-blocking command | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` |
| Workflow | `.github/workflows/phase70-proof.yml` |
| Hermeticity | Pure ExUnit + `Code.require_file`; no Endpoint/Repo/PubSub/network/device/provider SDK |

### Phase Requirements To Test Map

| Requirement | Behavior | Test Type | File Exists Now |
|-------------|----------|-----------|-----------------|
| SAAS-01 | End-to-end mock/provider-shaped purchase and restore corridor | hermetic proof | No - create in first plan |
| SAAS-02 | Entitlement projection changes only after backend verification | hermetic proof | No - create in first plan |
| Phase 70 SC1 | CI runs simulated purchase using mock storefront adapters | workflow + proof | No - create workflow |
| Phase 70 SC2 | Client-side success ignored until backend verification | hermetic negative tests | No - create proof |
| Phase 70 SC3 | Restore pulls state from provider facade without trusting client evidence | hermetic proof | No - create proof |

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` with RED assertions for SAAS-01/SAAS-02 and all success criteria.
- [ ] Deterministic backend verifier extension/helper if current `MockBackend` cannot satisfy negative lifecycle assertions.
- [ ] `.github/workflows/phase70-proof.yml` targeted merge-blocking lane and advisory provider/device lane.
- [ ] Optional focused Paywall LiveView proof updates only if UI copy/status behavior is changed.

## Planning Slices

Recommended plan split:

1. **Wave 0 proof scaffold:** Add Phase 70 proof file with fixed fixtures and failing assertions for purchase/restore/backend-authority matrix.
2. **Verifier and projection support:** Add deterministic verifier helper or extend `MockBackend` to emit grant/deny/stale/refund/revoke/expire snapshots without wall-clock dependence.
3. **Provider facade matrix:** Fill StoreKit/Play Billing purchase/restore fixture coverage and identity/replay assertions.
4. **CI workflow:** Add Phase 70 workflow based on Phase 48.
5. **UI/DX polish:** Narrow Paywall LiveView status/copy/accessibility updates, removing out-of-scope subscription-management affordances.
6. **Verification close:** Run targeted Phase 70 proof, relevant Phase 34/35/48 regression tests, and compile with warnings as errors.

## Open Questions

None blocking. The phase context already resolves scope, backend authority, facade/provider semantics, UI posture, and workflow shape.

## RESEARCH COMPLETE
