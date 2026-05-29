# Requirements: Crosswake — v3.4 Commerce Archetype Proof

**Defined:** 2026-05-29
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

**Milestone goal:** Turn v3.2's commerce vocabulary into a copy-able adopter lane — a runnable paywall corridor in `examples/phoenix_host` driven by a mocked storefront, proving purchase → reconciliation → entitlement → UI end-to-end (ARCH-02) without any provider adapter code.

**Grounding (already shipped — reuse, do not rebuild):** `Crosswake.Commerce.Contracts` (`PaywallEntry`, `PurchaseIntent`, `RestoreIntent`, `EntitlementSnapshot`, `ReconciliationEvidence`, `CommerceEvent`); `Crosswake.Commerce.Reconciliation` (`ingest_evidence/2`, `authority_mutation_allowed_from_evidence?/1` → `false`); and the Phase 21 example-host modules `CrosswakeExample.Commerce.{ReconciliationInbox, EntitlementProjection, ReconciliationKeys}` (incl. `project_snapshot/2` and `derived_state/1` → `:stale | :pending | :denied | :granted`). Zero new dependencies. See `.planning/research/SUMMARY.md`.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Paywall Corridor

- [x] **PWAL-01**: Adopter can copy a `paywall_entry` route declaring `commerce: [corridor: :subscription_default, role: :paywall_entry]` from `examples/phoenix_host`
- [x] **PWAL-02**: Adopter can see a `PaywallLive` LiveView render a single subscription `PaywallEntry` (pricing display + "Subscribe" action) with zero provider-SDK code

### Mock Storefront

- [x] **MOCK-01**: Adopter can see `MockStorefront` consume a `PurchaseIntent` and return `ReconciliationEvidence{source: :storefront, provider: "mock"}` in pure Elixir
- [x] **MOCK-02**: Adopter can see `MockStorefront` consume a `RestoreIntent` and return restore evidence (`event_kind: "restore"`)
- [x] **MOCK-03**: `MockStorefront` is shaped and documented as a drop-in swap target that makes explicit which functions a real StoreKit/Play Billing adapter would replace

### Reconciliation Wiring

- [x] **WIRE-01**: Adopter can see the example submit mock `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` and handle the returned `EvidenceResult`
- [x] **WIRE-02**: Adopter can see `EntitlementProjection.project_snapshot/2` produce the authoritative entitlement snapshot after successful ingestion
- [x] **WIRE-03**: Adopter can observe provider-aware idempotency-key construction (via `ReconciliationKeys`, not transient `correlation_id`) and replay detection (`replay?: true` on duplicate evidence submission)

### Entitlement State Reflection

- [x] **STATE-01**: `PaywallLive` reflects entitlement access via `EntitlementProjection.derived_state/1`, surfacing `:granted`, `:pending`, `:denied`, and `:stale` as four distinct UI states (stale is never conflated with denied), without exposing raw `EntitlementSnapshot` lane fields

### Proof Lane

- [x] **PROOF-01**: A merge-blocking hermetic ExUnit proof drives the full lane (mock purchase → `ingest_evidence/2` → `project_snapshot/2` → `derived_state/1`) with no network or native SDK, asserting all four states and the `:pending` → `:granted` transition
- [x] **PROOF-02**: A `phase34-proof.yml` two-job CI split keeps the hermetic lane merge-blocking (`--exclude requires_example_host` honored) while any provider/storefront/device checks stay advisory-only, with the documented 4-condition `promotion_path` (mirroring `phase23-proof.yml`)
- [x] **PROOF-03**: The proof asserts that mock evidence routed through `ingest_evidence/2` can never grant entitlement authority directly — the mock-boundary fence, anchored on `authority_mutation_allowed_from_evidence?/1` returning `false`

### Adopter Docs

- [ ] **DOCS-01**: `guides/commerce.md` gains an end-to-end mock-corridor walkthrough section that anchors each step to a named example-host module and function
- [ ] **DOCS-02**: A docs-contract test locks the walkthrough's module/function references against the example host without weakening the existing phase23 three-layer guide-structure assertions

## v2 Requirements

Deferred to future milestones. Tracked but not in this roadmap.

### Provider Adapters (→ v3.6)

- **ADPT-01**: First-party StoreKit adapter consuming the v3.2 commerce contracts as canonical input
- **ADPT-02**: First-party Play Billing adapter consuming the v3.2 commerce contracts as canonical input
- **ADPT-03**: Graduate the `purchase_intent` / `restore_intent` advisory proof to merge-blocking by satisfying the 4-condition `promotion_path` from `phase23-proof.yml`

## Out of Scope

Explicitly excluded for v3.4. Documented to prevent scope creep. (Anti-features sourced from `.planning/research/FEATURES.md`.)

| Feature | Reason |
|---------|--------|
| StoreKit / Play Billing / any provider-SDK code in `MockStorefront` or example | Would imply provider adapters shipped; breaks the mock-vs-real boundary and the guides/commerce.md non-claims. Deferred to v3.6 (AF-01). |
| RevenueCat or other third-party billing SDK references | Contradicts provider-neutral posture; phase23 proof already fences forbidden provider tokens. `provider: "mock"` only (AF-07). |
| Persistent entitlement storage (Ecto/ETS) in the mock lane | Migrations/test-DB setup obscures the corridor shape and breaks hermetic runnability. Use in-memory process state; persistence is adopter responsibility (AF-02). |
| Real-time PubSub/Presence push as a v3.4 deliverable | Channel setup obscures the reconciliation flow. The synchronous handle_event → assign → re-render loop teaches the boundary; PubSub is an adopter extension on the same `derived_state/1` result (AF-03). |
| Auth/session gating on the paywall route | Auth fixtures obscure the commerce lane; the corridor declaration is the teaching artifact. Adopters add their own auth pipeline (AF-05). |
| Multi-product paywall (consumable / non-consumable / subscription) | Product-type breadth multiplies fixtures without adding corridor insight. A single subscription `PaywallEntry` teaches the same shape (AF-04). |
| Offline / native-unavailable paywall fallback | Requires mocking the capability/native-shell layer — a separate proof surface. `commerce.corridor.prerequisite_missing` stays the documented canonical fallback (AF-06). |
| Exposing raw `EntitlementSnapshot` lane fields in the LiveView | Couples the UI to internal lane vocabulary; `derived_state/1` is the single UI decision function (AF-08). |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PWAL-01 | Phase 33 | Complete |
| PWAL-02 | Phase 35 | Complete |
| MOCK-01 | Phase 34 | Complete |
| MOCK-02 | Phase 34 | Complete |
| MOCK-03 | Phase 34 | Complete |
| WIRE-01 | Phase 35 | Complete |
| WIRE-02 | Phase 35 | Complete |
| WIRE-03 | Phase 34 | Complete |
| STATE-01 | Phase 35 | Complete |
| PROOF-01 | Phase 36 | Complete |
| PROOF-02 | Phase 33 | Complete |
| PROOF-03 | Phase 36 | Complete |
| DOCS-01 | Phase 37 | Pending |
| DOCS-02 | Phase 37 | Pending |

**Coverage:**
- v1 requirements: 14 total
- Mapped to phases: 14 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-29*
*Last updated: 2026-05-29 — traceability populated after roadmap creation (Phases 33-37)*
