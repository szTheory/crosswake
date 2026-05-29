# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [.planning/milestones/v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.1-ROADMAP.md](milestones/v3.1-ROADMAP.md)
- ✅ **v3.2 Commerce And Entitlement Seams** — Phases 19-25 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.2-ROADMAP.md](milestones/v3.2-ROADMAP.md)
- ✅ **v3.3 Release Readiness** — Phases 26-32 shipped on 2026-05-29 (`crosswake 0.1.0` live on hex.pm). Full archive: [.planning/milestones/v3.3-ROADMAP.md](milestones/v3.3-ROADMAP.md)
- 🚧 **v3.4 Commerce Archetype Proof** — Phases 33-37 (in progress, started 2026-05-29)

## Phases

<details>
<summary>✅ v3.2 Commerce And Entitlement Seams (Phases 19-25) — SHIPPED 2026-05-27</summary>

- [x] Phase 19: Commerce Route Corridors (3/3 plans) — completed 2026-05-27
- [x] Phase 20: Entitlement Lifecycle Semantics (4/4 plans) — completed 2026-05-27
- [x] Phase 21: Reconciliation Example (2/2 plans) — completed 2026-05-27
- ⊘ Phase 22: Commerce Support, Review, And Proof — decomposed by audit into Phases 23+24 before execution
- [x] Phase 23: Commerce Support And Proof Closure (4/4 plans) — completed 2026-05-27
- [x] Phase 24: Reconciliation Traceability Hardening (3/3 plans) — completed 2026-05-27
- [x] Phase 25: Tech-debt closure (Phase 20 verification text + Phase 24 parity test WR-01/02) (2/2 plans) — completed 2026-05-27

</details>

<details>
<summary>✅ v3.3 Release Readiness (Phases 26-32) — SHIPPED 2026-05-29</summary>

- [x] Phase 26: Package Metadata Audit (4/4 plans) — completed 2026-05-28
- [x] Phase 27: Versioning Decision And CHANGELOG Synthesis (2/2 plans) — completed 2026-05-28
- [x] Phase 28: release-please Configuration Files (1/1 plan) — completed 2026-05-28
- [x] Phase 29: Release Workflows And Supply-Chain Hardening (1/1 plan) — completed 2026-05-28
- [x] Phase 30: Hex Page Polish And Tarball Dry-Run (2/2 plans) — completed 2026-05-29
- [x] Phase 31: First Hex Publish (Human-Gated) — completed 2026-05-29 (`crosswake 0.1.0` live)
- [x] Phase 32: Post-Publish Cleanup — completed 2026-05-29

</details>

### 🚧 v3.4 Commerce Archetype Proof (In Progress)

**Milestone Goal:** Turn v3.2's commerce vocabulary into a copy-able adopter lane — a runnable paywall corridor in `examples/phoenix_host` driven by a mocked storefront, proving purchase → reconciliation → entitlement → UI end-to-end without any provider adapter code.

- [x] **Phase 33: Corridor Routes And CI Infrastructure** (2 plans) - Declare paywall corridor routes in the example host router and establish the two-job `phase34-proof.yml` CI split that gates all subsequent proof work (completed 2026-05-29)
- [x] **Phase 34: MockStorefront And Idempotency Invariants** - Implement `MockStorefront` as a pure Elixir evidence-emitting adapter and prove its idempotency and provider-vocabulary boundary in the same phase (completed 2026-05-29)
- [x] **Phase 35: Reconciliation Wiring And Four-State LiveView** - Wire purchase/restore evidence through the reconciliation inbox and projection, and build `PaywallEntryLive` with explicit branches for all four `derived_state/1` outputs (completed 2026-05-29)
- [x] **Phase 36: Hermetic Proof Lane** - Write the merge-blocking `phase34_paywall_corridor_proof_test.exs` against final data-layer code, asserting all states, the `:pending` → `:granted` transition, and the mock-boundary fence (completed 2026-05-29)
- [ ] **Phase 37: Guides Walkthrough And Docs-Contract Lock** - Add the end-to-end paywall corridor walkthrough to `guides/commerce.md` and extend `commerce_test.exs` to lock all module/function references and non-claims against the shipped example

## Phase Details

### Phase 33: Corridor Routes And CI Infrastructure

**Goal**: The `examples/phoenix_host` router declares the three paywall corridor routes with correct `commerce:` DSL, and `phase34-proof.yml` establishes the hermetic-merge-blocking / advisory-only two-job CI split that will gate every subsequent PR in this milestone
**Depends on**: Phase 32 (v3.3 complete)
**Requirements**: PWAL-01, PROOF-02
**Success Criteria** (what must be TRUE):

  1. An adopter can copy the `paywall_entry` route declaration (with `commerce: [corridor: :subscription_default, role: :paywall_entry]`) from `examples/phoenix_host/router.ex` and see the canonical DSL shape
  2. The example host router compiles with all three corridor routes (`paywall_entry`, `purchase_intent`, `restore_intent`) and they appear in the manifest with correct corridor metadata
  3. `.github/workflows/phase34-proof.yml` exists with a hermetic merge-blocking job and an advisory job (`continue-on-error: true`) including the 4-condition `promotion_path` comment mirroring `phase23-proof.yml`
  4. The hermetic CI job runs `mix test --exclude requires_example_host` cleanly and the advisory job never gates a merge**Plans**: 2 plans
- [x] 33-01-PLAN.md — Declare /commerce corridor routes (paywall_entry live + purchase/restore post) in the example host router; forward-reference Phase 35 modules; manifest-introspection proof test
- [x] 33-02-PLAN.md — Create phase34-proof.yml two-job hermetic+advisory CI split (merge-blocking `mix test --exclude requires_example_host` + advisory continue-on-error lane)

### Phase 34: MockStorefront And Idempotency Invariants

**Goal**: `CrosswakeExample.Commerce.MockStorefront` exists as a pure-Elixir evidence emitter with `simulate_purchase/1` and `simulate_restore/1`, its idempotency invariants are provable against the existing `ReconciliationInbox` and `ReconciliationKeys`, and a provider-vocabulary fence confirms no forbidden tokens appear in the mock source
**Depends on**: Phase 33
**Requirements**: MOCK-01, MOCK-02, MOCK-03, WIRE-03
**Success Criteria** (what must be TRUE):

  1. An adopter can inspect `MockStorefront.simulate_purchase/1` and see it consume a `PurchaseIntent` and return `ReconciliationEvidence{source: :storefront, provider: "mock", event_kind: "purchase"}` with no provider SDK code
  2. An adopter can inspect `MockStorefront.simulate_restore/1` and see it consume a `RestoreIntent` and return restore evidence (`event_kind: "restore"`)
  3. `MockStorefront`'s `@moduledoc` explicitly names the two functions a real StoreKit/Play Billing adapter would replace, making the drop-in swap target pattern obvious
  4. A replay test demonstrates that submitting evidence with the same `provider_reference` (but a different `correlation_id`) returns `replay?: true` from `ReconciliationInbox.ingest_evidence/2`, proving idempotency is keyed on stable provider identity via `ReconciliationKeys`, not transient device IDs
  5. A provider-vocabulary fence test confirms `MockStorefront` source contains no `storekit`, `play_billing`, `play billing`, or `revenuecat` tokens

**Plans**: 2 plans
**Wave 1**

- [x] 34-01-PLAN.md — Create CrosswakeExample.Commerce.MockStorefront (pure-Elixir evidence emitter: simulate_purchase/2, simulate_restore/2, swap-target @moduledoc)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 34-02-PLAN.md — Hermetic untagged proof test: replay/idempotency invariant, restore-shares-subject-key, provider-vocabulary fence

### Phase 35: Reconciliation Wiring And Four-State LiveView

**Goal**: `PaywallEntryLive`, `PurchaseIntentLive`, and `RestoreIntentLive` are wired end-to-end — mock evidence flows through `ReconciliationInbox.ingest_evidence/2` and `EntitlementProjection.project_snapshot/2`, and `PaywallEntryLive` renders all four `derived_state/1` outputs as distinct UI states
**Depends on**: Phase 34
**Requirements**: WIRE-01, WIRE-02, STATE-01, PWAL-02
**Success Criteria** (what must be TRUE):

  1. An adopter can see `PurchaseIntentLive` submit mock `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` and handle the returned `EvidenceResult` (status `:awaiting_verification`) *(per D-08, satisfied by the purchase-intent flow on `PaywallEntryLive.handle_event("subscribe")` + the `CorridorController.purchase` seam, not a literal `PurchaseIntentLive` module)*
  2. An adopter can see `EntitlementProjection.project_snapshot/2` invoked after simulated backend verification, producing the authoritative entitlement snapshot used to derive UI state
  3. `PaywallEntryLive` renders a single subscription `PaywallEntry` (pricing display + "Subscribe" action) with zero provider-SDK code visible
  4. `PaywallEntryLive` has explicit `case` branches for all four `derived_state/1` values — `:granted`, `:pending`, `:denied`, and `:stale` — where `:stale` is visually distinct from `:denied` and `:pending` shows a "processing" state
  5. `PaywallEntryLive` initializes to `:stale` on mount (fail-closed) and transitions to other states only via the PubSub `{:entitlement_update, derived_state}` message path

**Plans**: 2 plans
**UI hint**: yes

**Wave 1**

- [x] 35-01-PLAN.md — Data-layer + transport spine: MockBackend verification-gap bridge (WIRE-02), Phoenix.PubSub supervision bootstrap (D-12), thin CorridorController POST seam (WIRE-01)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 35-02-PLAN.md — PaywallEntryLive four-state LiveView (STATE-01, PWAL-02): fail-closed :stale mount + connected? subscribe, purchase/restore intent flows, exhaustive case dispatch to four named components, dev scenario drivers, router suppression cleanup

### Phase 36: Hermetic Proof Lane

**Goal**: `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` is the merge-blocking proof for the full mock corridor — it drives all four `derived_state/1` states, asserts the `:pending` → `:granted` transition, and fences `authority_mutation_allowed_from_evidence?/1` returning `false`, all without any network call, process start, or example-host runtime dependency
**Depends on**: Phase 35
**Requirements**: PROOF-01, PROOF-03
**Success Criteria** (what must be TRUE):

  1. The hermetic proof test drives the full lane — inline `ReconciliationEvidence` → `ingest_evidence/2` → `project_snapshot/2` → `derived_state/1` — and all four states (`:stale`, `:pending`, `:denied`, `:granted`) are explicitly asserted with distinct assertions
  2. The proof test asserts the `:pending` → `:granted` transition: ingestion produces `:awaiting_verification`, then a verified snapshot produces `:granted` via `project_snapshot/2`
  3. The mock-boundary fence assertion confirms `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` returns `false` for mock-produced evidence, and that `project_snapshot/2` rejects any snapshot with non-`:projection_refreshed` reconciliation state
  4. The proof test file uses `async: false`, phase-prefixed inline fixture module names (e.g. `Phase34PaywallCorridorRouter`) to avoid collision with phase23 fixtures, and contains a hermeticity self-scan guard confirming no `Code.require_file` on example-host paths
  5. The hermetic CI job in `phase34-proof.yml` runs this test file and passes cleanly under `--exclude requires_example_host --warnings-as-errors`

**Plans**: 1 plan
Plans:

- [x] 36-01-PLAN.md — Hermetic merge-blocking proof of the mock paywall corridor (four states, :pending->:granted transition, mock-boundary fence, self-scan guard)

### Phase 37: Guides Walkthrough And Docs-Contract Lock

**Goal**: `guides/commerce.md` gains an end-to-end paywall corridor walkthrough section written against the final shipped code, and `commerce_test.exs` is extended to lock all module/function references, canonical field names, and the four non-claims against the working example — making the guide a merge-blocking artifact
**Depends on**: Phase 36
**Requirements**: DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):

  1. `guides/commerce.md` contains a "Paywall Corridor Walkthrough" section that anchors each step (route declaration, MockStorefront call, evidence ingestion, snapshot projection, derived state, LiveView rendering) to a named example-host module and function
  2. The walkthrough opens with an explicit mock-vs-real callout stating that `MockStorefront` uses `provider: "mock"` and that no StoreKit or Play Billing code is shipped
  3. A docs-contract test in `commerce_test.exs` asserts the walkthrough heading exists, that `CrosswakeExample.Commerce.MockStorefront` is named exactly, and that canonical field names (`provider_reference`, `evidence_ref`) are used rather than invented aliases
  4. The docs-contract test confirms the existing phase23 three-layer guide-structure assertions still pass after the new walkthrough section is added
  5. The docs-contract test asserts all four non-claims (`StoreKit`, `Play Billing`, `Device-local authority`, `Offline purchase replay`) remain present in `guides/commerce.md` after the walkthrough update

**Plans**: TBD

## Progress

**Execution Order:** 33 → 34 → 35 → 36 → 37

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 33. Corridor Routes And CI Infrastructure | 2/2 | Complete    | 2026-05-29 |
| 34. MockStorefront And Idempotency Invariants | 2/2 | Complete    | 2026-05-29 |
| 35. Reconciliation Wiring And Four-State LiveView | 2/2 | Complete   | 2026-05-29 |
| 36. Hermetic Proof Lane | 1/1 | Complete    | 2026-05-29 |
| 37. Guides Walkthrough And Docs-Contract Lock | 0/TBD | Not started | - |
