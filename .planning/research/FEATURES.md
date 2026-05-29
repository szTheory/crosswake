# Feature Research: v3.4 Commerce Archetype Proof (Mocked Storefront Paywall Corridor)

**Milestone:** v3.4 Commerce Archetype Proof
**Domain:** Mocked-storefront paywall corridor example for a Phoenix-native OSS library
**Researched:** 2026-05-29
**Confidence:** HIGH — sourced from checked-in contracts, reconciliation module, example-host commerce modules, guides/commerce.md, phase23 proof test, and commerce-archetype-proof thread. All contract surfaces are real code, not aspirational design.

---

## Grounding Facts

What already exists in the repo that v3.4 builds on (do NOT re-research or re-implement):

- `Crosswake.Commerce.Contracts` defines all five typed vocabulary surfaces: `PaywallEntry`, `PurchaseIntent`, `RestoreIntent`, `EntitlementSnapshot` (6 lanes), `ReconciliationEvidence`, `CommerceEvent`.
- `Crosswake.Commerce.Reconciliation` defines `ingest_evidence/2`, `EvidenceResult`, `Attempt`, `IdempotencyKey`, and the full outcome vocabulary. `authority_mutation_allowed_from_evidence?/1` returns `false` unconditionally — authority mutation is backend-owned by contract.
- `CrosswakeExample.Commerce.EntitlementProjection` implements `project_snapshot/2` (monotonic `as_of` guard, verified reconciliation check) and `derived_state/1` (4-output projection: `:stale`, `:pending`, `:denied`, `:granted`).
- `CrosswakeExample.Commerce.ReconciliationInbox` implements `ingest_evidence/2` with `event_key`, `subject_key`, replay detection, and `trace_metadata`.
- `CrosswakeExample.Commerce.ReconciliationKeys` defines provider-aware key construction (`event_key`, `subject_key`, `trace_metadata`).
- No `paywall_entry` route exists in `examples/phoenix_host/lib/crosswake_example/router.ex` — the corridor is declared in test fixtures only.
- No `MockStorefront` module exists anywhere in the repo.
- No `PaywallLive` or equivalent LiveView exists in the example host.
- The phase23 proof test uses inline `PaywallCorridorRouter` / `PurchaseCorridorRouter` fixtures, not the example host router.

What v3.4 must add: a runnable adopter lane wiring all of the above into a copy-able `examples/phoenix_host` paywall corridor, proved end-to-end by a merge-blocking hermetic test.

---

## Feature Landscape

### Table Stakes — Adopter Expects These (Missing = Example Is Not Copy-able)

Features a Phoenix dev trying to ship subscriptions requires to trust the corridor as a real pattern. Missing any of these means the example does not teach what it is supposed to teach.

| Feature | Why Expected | User-Centric Statement | Complexity | v3.2 Contract Dependency |
|---------|--------------|------------------------|------------|--------------------------|
| TS-01: `paywall_entry` route in example host router | Without a real declared route the pattern is only a test fixture, not copy-able | Adopter can copy a `live "/paywall"` route with `commerce: [corridor: :subscription_default, role: :paywall_entry]` policy from `examples/phoenix_host/router.ex` and see a working route declaration | LOW | `Crosswake.Router` `crosswake:` option with commerce key (v3.2) |
| TS-02: `PaywallLive` LiveView showing pricing and a mock purchase action | Adopter needs to see the UI ownership — Phoenix owns the paywall display, not native | Adopter can see a LiveView that renders a pricing plan and a "Subscribe" action without any provider SDK code | LOW | `PaywallEntry` struct (`:id`, `:price_display`, `:group_id`, `:features`) from `Contracts` |
| TS-03: `MockStorefront` adapter that consumes `PurchaseIntent` and returns `ReconciliationEvidence` | The whole point of the mock lane is to stand in for a real StoreKit/Play Billing adapter | Adopter can see how a real storefront adapter would ingest a `PurchaseIntent`, produce a `ReconciliationEvidence` struct, and return it to the backend — all in pure Elixir with no native code | MEDIUM | `PurchaseIntent` (`:entry_id`, `:correlation_id`), `ReconciliationEvidence` (`:source`, `:provider`, `:provider_reference`, `:event_kind`, `:evidence_ref`, `:captured_at`) from `Contracts` |
| TS-04: `MockStorefront` handling `RestoreIntent` | Restore is the second required corridor; omitting it leaves a gap in the copy-able pattern | Adopter can see how a restore trigger produces `ReconciliationEvidence` with `event_kind: "restore"` | LOW | `RestoreIntent` (`:correlation_id`) from `Contracts` |
| TS-05: Backend route or handler that submits `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` | Adopter must see the evidence handoff from the mock storefront call back to the Phoenix backend | Adopter can see a Phoenix controller or LiveView handle event that calls `ReconciliationInbox.ingest_evidence/2` with mock evidence and receives an `EvidenceResult` | LOW | `ReconciliationInbox.ingest_evidence/2` and `ReconciliationEvidence` (already in example host) |
| TS-06: `EntitlementProjection.project_snapshot/2` called to refresh the authoritative snapshot | This is the authority update step — missing it means the projection half of the pattern is invisible | Adopter can see `EntitlementProjection.project_snapshot/2` called after successful evidence ingestion and the resulting snapshot stored as the new authority source | LOW | `EntitlementProjection.project_snapshot/2` and `EntitlementSnapshot` (already in example host) |
| TS-07: LiveView reflecting `:granted` state after mock purchase completes reconciliation | Without a real UI state change, the "end-to-end" claim is hollow | Adopter can observe their `PaywallLive` (or a sibling `EntitledLive`) display a "granted" access state after a mock purchase flows through reconciliation | MEDIUM | `EntitlementProjection.derived_state/1` returning `:granted` |
| TS-08: LiveView reflecting `:pending` state during reconciliation in-progress | Reconciliation takes time; the pending state is a first-class corridor moment the adopter must be able to handle | Adopter can see how to render a "pending" UI state while `reconciliation.state` is `:pending_purchase` or `:awaiting_verification` | LOW | `derived_state/1` returning `:pending`, reconciliation vocabulary in `Reconciliation` |
| TS-09: LiveView reflecting `:denied` state (no active entitlement) | Denied is the default cold-start state — showing how the paywall gates access is the primary teaching goal | Adopter can see how a LiveView gates access with `:denied` returned by `derived_state/1` and redirects or renders a paywall prompt | LOW | `derived_state/1` returning `:denied` |
| TS-10: LiveView reflecting `:stale` state (freshness degraded) | Stale is the fail-closed state — it must be shown as distinct from denied so adopters do not conflate "stale snapshot" with "no entitlement" | Adopter can see how a stale snapshot (freshness `:stale` or `:unknown`) surfaces as a distinct "checking..." or "refresh needed" state, not a silent access denial | LOW | `derived_state/1` returning `:stale`, `FreshnessLane` states |
| TS-11: Merge-blocking hermetic proof test driving the full mock lane | Without a CI-gated proof the example is aspirational, not proven | Adopter can see a passing ExUnit test that drives mock purchase → ingestion → projection → derived state transitions without hitting a network or native SDK | MEDIUM | All v3.2 contract surfaces; existing hermetic proof pattern from phase23-proof.yml |
| TS-12: `guides/commerce.md` updated with end-to-end mock walkthrough section | Adopters use the guide to understand the corridor before copying the example | Adopter can read a step-by-step walkthrough in `guides/commerce.md` that anchors each step to a named module and function in the example host | LOW | Existing three-layer guide structure (docs-contract tests must not break) |

### Differentiators — What Makes the Example Genuinely Useful

Not strictly required to make the example "work," but these are what separate a copy-able pattern from a toy stub.

| Feature | Value Proposition | User-Centric Statement | Complexity | Dependency |
|---------|-------------------|------------------------|------------|------------|
| DIF-01: `MockStorefront` designed as a drop-in swap target | Shows adopters exactly what a real StoreKit or Play Billing adapter must implement at the seam | Adopter can see a clear `@behaviour` or well-commented module shape for `MockStorefront` that documents which functions a real provider adapter would replace | MEDIUM | `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence` from `Contracts` |
| DIF-02: All four `derived_state/1` outputs exercised by the proof test with explicit assertions | Proves that every UI state the LiveView must handle is covered by contract, not just the happy path | Adopter can read the proof test and see `:granted`, `:pending`, `:denied`, and `:stale` all explicitly asserted — not just `:granted` | MEDIUM | `EntitlementProjection.derived_state/1` |
| DIF-03: Idempotency key construction demonstrated via `ReconciliationKeys` | One of the trickiest real-world pitfalls (duplicate webhook retries) is invisible without a working example | Adopter can see `ReconciliationKeys.event_key/1` and `subject_key/1` called with mock evidence and understand why `correlation_id` is trace-only | LOW | `ReconciliationKeys` (already in example host) |
| DIF-04: Replay detection shown explicitly in the mock purchase path | Duplicate evidence submission is a real-world concern; the mock lane is the place to make it visible | Adopter can submit the same mock `ReconciliationEvidence` twice and see `replay?: true` in the second `EvidenceResult` | LOW | `ReconciliationInbox.ingest_evidence/2` with `seen_event_keys:` opt |
| DIF-05: Docs-contract test locking the commerce.md walkthrough against the example modules | Keeps the guide honest — if the example modules change, the test breaks | Adopter can trust that the `guides/commerce.md` walkthrough references real module and function names that exist in the example host | LOW | Existing docs-contract test pattern from phase23 proof |
| DIF-06: `MockStorefront` uses `source: :storefront` not `source: :device` | Shows adopters the semantic distinction between a simulated native storefront callback (`:storefront`) and a hypothetical device-side assertion (`:device`) | Adopter can see why the mock uses `source: :storefront` and what that means for `EvidenceLane.source` in the resulting snapshot | LOW | `ReconciliationEvidence.source` vocabulary: `:device`, `:storefront`, `:webhook`, `:support` |

### Anti-Features — Do Not Include

Features that seem helpful for a paywall example but undermine the v3.4 teaching goal or the mock-vs-real boundary.

| Anti-Feature | Why Requested | Why It's Wrong for v3.4 | What to Do Instead |
|--------------|---------------|--------------------------|-------------------|
| AF-01: Any StoreKit or Play Billing adapter code in MockStorefront | "Make it realistic by using the real SDK shape" | Shipping provider SDK imports or callbacks would imply provider adapters have shipped (they have not; v3.6 is the provider adapter milestone). Breaks the mock-vs-real boundary and the non-claims documented in guides/commerce.md | Keep MockStorefront pure Elixir, no native SDK references. Document the swap point clearly in comments. |
| AF-02: Persistent storage (Ecto, ETS) in the mock purchase flow | "A real adopter would use a database" | A persistence layer adds setup complexity (migrations, repos, test DB) that obscures the corridor shape being taught. The example must be hermetically runnable. | Use in-memory `Agent` or process state for the mock lane. A real adopter adds persistence to their own host; the example shows the contract shape, not the persistence layer. |
| AF-03: Live WebSocket push of entitlement state changes | "Make it feel real with PubSub/Presence" | Real-time push is a valid adopter concern but adds PubSub setup and channel complexity that obscures the reconciliation flow. The example's job is to teach the flow boundary, not Phoenix Channels. | Show a synchronous handle_event → assign → re-render loop. Document that real adopters can add PubSub push on top of the same `derived_state/1` result. |
| AF-04: Multi-product paywall (consumable, non-consumable, subscription) | "Show all purchase types" | Product-type complexity is not what v3.4 teaches. Multiple `PaywallEntry` rows would multiply the fixture surface without adding corridor insight. | Use a single subscription-style `PaywallEntry` with a single `group_id`. Adopters can extend to multiple entries; the corridor shape is the same. |
| AF-05: Auth/session gating on the paywall route | "A real paywall needs authentication" | Auth setup (Pow, phx_gen_auth, etc.) would require the example host to ship session fixtures, adding setup that obscures the commerce lane. v3.4 is about the corridor, not auth. | Leave the paywall route unauthenticated in the example. Document that real adopters add their own auth pipeline. The `commerce: [corridor: :subscription_default, role: :paywall_entry]` declaration is the teaching artifact. |
| AF-06: Graceful degradation / offline paywall fallback | "Show what happens if the native corridor is unavailable" | The mock lane deliberately bypasses native availability checks — simulating availability failures would require mocking the capability/native shell layer, which is a separate proof surface. | The mock lane proves the happy path. Document `commerce.corridor.prerequisite_missing` as the canonical fallback code (already in guides/commerce.md). Offline fallback stays in the non-claims layer. |
| AF-07: Revenue Cat or third-party billing SDK references in mock or example code | "RevenueCat simplifies the provider layer" | Importing RevenueCat normalizes a third-party billing SDK dependency in the Crosswake example, contradicting the provider-neutral posture. The canonical v3.2 proof tests already assert that forbidden provider tokens do not appear in merge-blocking surfaces. | Keep `provider: "mock"` in all `ReconciliationEvidence` structs. Provider-specific adapters are v3.6 work. |
| AF-08: Displaying raw `EntitlementSnapshot` fields in the LiveView | "Show the full snapshot for transparency" | Exposing `authority.state`, `reconciliation.state`, `freshness.state` directly in the UI couples the LiveView to internal lane vocabulary. The teaching point is `derived_state/1` as the single UI decision function. | LiveView renders only the four `derived_state/1` outputs: `:granted`, `:pending`, `:denied`, `:stale`. Internal snapshot lanes are a projection implementation detail. |

---

## Feature Dependencies

```
TS-01 (paywall_entry route)
    └──required by──> TS-02 (PaywallLive LiveView)
    └──required by──> TS-11 (proof test exercises real route declaration)

TS-03 (MockStorefront / PurchaseIntent → ReconciliationEvidence)
    └──required by──> TS-04 (MockStorefront / RestoreIntent)
    └──required by──> TS-05 (evidence submission to ReconciliationInbox)
    └──enables──> DIF-01 (MockStorefront as swap target)
    └──enables──> DIF-06 (source: :storefront semantic)

TS-05 (ReconciliationInbox.ingest_evidence/2 called)
    └──required by──> TS-06 (EntitlementProjection.project_snapshot/2 called)
    └──enables──> DIF-03 (idempotency key construction visible)
    └──enables──> DIF-04 (replay detection)

TS-06 (project_snapshot/2 called)
    └──required by──> TS-07 (granted state in LiveView)
    └──required by──> TS-08 (pending state in LiveView)
    └──required by──> TS-09 (denied state in LiveView)
    └──required by──> TS-10 (stale state in LiveView)
    └──enables──> DIF-02 (all four derived_state outputs asserted in proof)

TS-11 (merge-blocking proof test)
    └──requires──> TS-01, TS-03, TS-04, TS-05, TS-06, TS-07, TS-08, TS-09, TS-10
    └──enables──> DIF-02 (all four states proved)
    └──enables──> DIF-04 (replay path proved)
    └──enables──> DIF-05 (docs-contract lock) [separate test]

TS-12 (guides/commerce.md walkthrough)
    └──requires──> TS-03, TS-05, TS-06 (must reference real module names)
    └──requires──> DIF-05 (docs-contract test locks walkthrough against example)
    └──must not break──> existing phase23 guide structure tests (three H2 layers, non-claims section)
```

### Dependency Notes

- **TS-03 before TS-05**: `ReconciliationEvidence` must be constructible from mock data before `ReconciliationInbox.ingest_evidence/2` can be called. `MockStorefront` is the factory.
- **TS-06 before UI states (TS-07–TS-10)**: `project_snapshot/2` must be called before any `derived_state/1` output can be tested. The projection is the single path from evidence to UI state.
- **TS-11 hermetic constraint**: The proof test must not import `CrosswakeExample.Router` directly (following the phase23 pattern). It must use isolated module fixtures or call example-host modules directly in a unit-test style. The example host router itself is not on the library's `mix test` compile path.
- **DIF-05 docs-contract test**: Must only check that walkthrough section headings and module/function names in `guides/commerce.md` match what exists in the example host — it must not weaken or replace the existing phase23 guide structure assertions.

---

## MVP Definition

### What v3.4 Must Deliver (Milestone Scope)

All table-stakes features are required to close the "adopter can copy this" gap.

- [x] TS-01: `paywall_entry` route in `examples/phoenix_host/router.ex`
- [x] TS-02: `PaywallLive` LiveView with pricing display and mock purchase action
- [x] TS-03: `MockStorefront` consuming `PurchaseIntent` → `ReconciliationEvidence`
- [x] TS-04: `MockStorefront` consuming `RestoreIntent` → `ReconciliationEvidence`
- [x] TS-05: Backend evidence submission path (`ReconciliationInbox.ingest_evidence/2`)
- [x] TS-06: Backend projection path (`EntitlementProjection.project_snapshot/2`)
- [x] TS-07: LiveView rendering `:granted`
- [x] TS-08: LiveView rendering `:pending`
- [x] TS-09: LiveView rendering `:denied`
- [x] TS-10: LiveView rendering `:stale`
- [x] TS-11: Merge-blocking hermetic proof test
- [x] TS-12: `guides/commerce.md` walkthrough section updated

Differentiators DIF-01, DIF-02, DIF-05, DIF-06 should be included in v3.4 — they are low-complexity and directly reinforce what makes the example credible. DIF-03 and DIF-04 are medium-confidence additions: include if the proof test naturally exercises them; do not add separate example-host UI for them.

### Defer to Later Milestones

- Real StoreKit / Play Billing adapter code → v3.6 (provider adapters milestone)
- PubSub / real-time entitlement push → adopter responsibility; documented as extension pattern
- Multi-product paywall → adopter responsibility; single `PaywallEntry` is sufficient to teach the corridor

---

## Feature Prioritization Matrix

| Feature | Adopter Value | Implementation Cost | Priority | Phase Cluster |
|---------|--------------|---------------------|----------|---------------|
| TS-01: paywall_entry route | HIGH | LOW | P1 | Route declaration |
| TS-02: PaywallLive w/ pricing + action | HIGH | LOW | P1 | Route declaration |
| TS-03: MockStorefront / PurchaseIntent | HIGH | MEDIUM | P1 | MockStorefront |
| TS-04: MockStorefront / RestoreIntent | HIGH | LOW | P1 | MockStorefront |
| TS-05: Evidence submission to inbox | HIGH | LOW | P1 | Reconciliation wiring |
| TS-06: project_snapshot/2 call | HIGH | LOW | P1 | Reconciliation wiring |
| TS-07: granted state in LiveView | HIGH | LOW | P1 | LiveView states |
| TS-08: pending state in LiveView | HIGH | LOW | P1 | LiveView states |
| TS-09: denied state in LiveView | HIGH | LOW | P1 | LiveView states |
| TS-10: stale state in LiveView | MEDIUM | LOW | P1 | LiveView states |
| TS-11: hermetic proof test | HIGH | MEDIUM | P1 | Proof lane |
| TS-12: commerce.md walkthrough | HIGH | LOW | P1 | Docs |
| DIF-01: MockStorefront as swap target | HIGH | LOW | P1 | MockStorefront |
| DIF-02: all four states asserted in proof | HIGH | LOW | P1 | Proof lane |
| DIF-05: docs-contract test | MEDIUM | LOW | P2 | Proof lane |
| DIF-06: source: :storefront semantic | MEDIUM | LOW | P2 | MockStorefront |
| DIF-03: idempotency key demonstration | LOW | LOW | P3 | Reconciliation wiring |
| DIF-04: replay detection demonstrated | LOW | LOW | P3 | Reconciliation wiring |

---

## Mock-vs-Real Boundary Reference

This table is the canonical authority for what v3.4 ships vs. what stays deferred. Any phase or PR that blurs this line is out of scope.

| Surface | v3.4 Status | Deferred To |
|---------|-------------|-------------|
| `MockStorefront` (pure Elixir, `source: :storefront`) | SHIP | — |
| `PaywallEntry`, `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence` | ALREADY EXIST (v3.2 contracts) | — |
| `ReconciliationInbox`, `EntitlementProjection`, `ReconciliationKeys` | ALREADY EXIST (example host) | — |
| StoreKit adapter code | DO NOT SHIP | v3.6 |
| Play Billing adapter code | DO NOT SHIP | v3.6 |
| Real provider SDK imports in any example or library module | DO NOT SHIP | v3.6 |
| Advisory → merge-blocking promotion for purchase_intent / restore_intent | DO NOT SHIP | v3.6 (4-condition promotion_path from phase23-proof.yml) |
| Persistent entitlement storage (Ecto/ETS) in mock lane | DO NOT SHIP | Adopter responsibility |
| PubSub / real-time entitlement push in example | DO NOT SHIP | Adopter responsibility |

---

## Category Reference Summary

| Category | Label | Count | Phase Cluster |
|----------|-------|-------|---------------|
| Route declaration (`paywall_entry` route + `PaywallLive`) | Table Stakes | TS-01, TS-02 | Route |
| MockStorefront adapter (`PurchaseIntent`, `RestoreIntent`) | Table Stakes + Differentiator | TS-03, TS-04, DIF-01, DIF-06 | MockStorefront |
| Reconciliation wiring (inbox ingestion + projection) | Table Stakes + Differentiator | TS-05, TS-06, DIF-03, DIF-04 | Reconciliation |
| LiveView state reflection (granted/pending/denied/stale) | Table Stakes | TS-07, TS-08, TS-09, TS-10 | LiveView states |
| Hermetic proof lane | Table Stakes + Differentiator | TS-11, DIF-02, DIF-05 | Proof |
| Docs walkthrough | Table Stakes | TS-12 | Docs |
| Provider adapter code (StoreKit, Play Billing) | Anti-Feature | AF-01, AF-07 | Out of scope |
| Persistence, PubSub, auth, multi-product | Anti-Feature | AF-02, AF-03, AF-04, AF-05 | Out of scope |
| Raw snapshot field exposure in UI | Anti-Feature | AF-08 | Architecture concern |

---

## Sources

- `/Users/jon/projects/crosswake/lib/crosswake/commerce/contracts.ex` — typed contract vocabulary (HIGH confidence)
- `/Users/jon/projects/crosswake/lib/crosswake/commerce/reconciliation.ex` — `ingest_evidence/2`, `authority_mutation_allowed_from_evidence?/1` (HIGH confidence)
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — `project_snapshot/2`, `derived_state/1` (HIGH confidence)
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — `ingest_evidence/2` with event_key/subject_key (HIGH confidence)
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — provider-aware key construction (HIGH confidence)
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex` — confirmed no paywall_entry route exists (HIGH confidence)
- `/Users/jon/projects/crosswake/guides/commerce.md` — three-layer guide structure, reviewer playbooks, non-claims (HIGH confidence)
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermetic proof pattern and hermeticity constraints (HIGH confidence)
- `/Users/jon/projects/crosswake/.planning/threads/commerce-archetype-proof.md` — v3.4 design intent and next-step list (HIGH confidence)
- `/Users/jon/projects/crosswake/.planning/PROJECT.md` — validated requirements COMM-04–COMM-06, ENTL-01–03, RECN-01–03, non-claims, key decisions (HIGH confidence)
- SEED-002 — Masilotti Bridge Components and PurchaseKit noted as category comparison only, not implementation targets (HIGH confidence)

---

*Feature research for: v3.4 Commerce Archetype Proof — mocked-storefront paywall corridor example*
*Researched: 2026-05-29*
