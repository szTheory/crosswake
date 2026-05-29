# Project Research Summary

**Project:** Crosswake v3.4 Commerce Archetype Proof
**Domain:** Mocked-storefront paywall corridor example for a Phoenix-native OSS library
**Researched:** 2026-05-29
**Confidence:** HIGH

## Executive Summary

Crosswake v3.4 closes the gap between the v3.2 commerce contract vocabulary and a copy-able adopter example. The v3.2 contracts already define everything needed (`PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence`, `EntitlementSnapshot`), and the example host already ships three proven reconciliation modules (`ReconciliationInbox`, `EntitlementProjection`, `ReconciliationKeys`). What does not yet exist is a wired paywall route, a `MockStorefront` adapter, a `PaywallEntryLive` LiveView with all four entitlement states, a merge-blocking hermetic proof test, and an updated guide walkthrough. The milestone delivers exactly those six artifacts — nothing more.

Zero new dependencies are required. Every new file is pure Elixir wired through already-shipped contracts. The recommended build order is: route corridor declarations and the phase34-proof.yml two-job CI split first, then `MockStorefront`, then `PaywallEntryLive` scaffold with reconciliation wiring, then the four-state LiveView with PubSub, then the hermetic merge-blocking proof test, then the guides walkthrough and docs-contract lock. Two natural sub-phases emerge: (1) data and contract layer provable in isolation, then (2) runtime and docs. The proof test is intentionally structured before the LiveView PubSub wiring so the data layer can be validated independently.

The primary risks are boundary violations, not technical difficulty. The three non-negotiable guardrails are: `MockStorefront` must return `ReconciliationEvidence` and route through `ingest_evidence/2` — it can never grant authority directly; the idempotency key must derive from the stable `provider_reference`, not the transient `correlation_id`; and all four `derived_state/1` outputs (`:stale`, `:pending`, `:denied`, `:granted`) are contractually required in both the LiveView and the proof test. A fourth systemic risk is test isolation — any test using `Code.require_file` or `File.cd!/2` must use `async: false` and must not collide on inline fixture module names with the existing phase23 test.

## Key Findings

### Recommended Stack

No new dependencies are introduced. The existing `examples/phoenix_host/mix.exs` already contains every technology needed: Phoenix 1.8.x for routing and LiveView, `phoenix_live_view ~> 1.1` for four-state reactive UI, `ecto_sql`/`ecto_sqlite3` for optional persistence, and `jason` for evidence payload encoding. The crosswake library itself (loaded via `path: "../.."`) provides all contract struct definitions.

**Core technologies (all existing):**
- `crosswake` (local path): Commerce contracts, reconciliation primitives, Router DSL with `commerce:` keyword — foundation for all new artifacts
- `phoenix ~> 1.8`: Router scope/live/post macros, controller pipeline for intent routes — no new config needed
- `phoenix_live_view ~> 1.1`: `assign/3`, `handle_event/3`, `handle_info/2` for four-state paywall rendering — proven by existing SaaS approvals and study session lanes
- `ecto_sql` + `ecto_sqlite3` (already wired): Optional persistence for entitlement snapshots — same pattern as `selective_native/claim.ex`
- `ExUnit` (stdlib): Hermetic proof test with no additional test framework

**What not to add:** No StoreKit/Play Billing SDK, no `mox`, no `Phoenix.PubSub` supervisor additions beyond what is needed, no HEEx component libraries, no Ecto migrations as a proof requirement.

### Expected Features

All twelve table-stakes features are in scope for v3.4. They group into six clusters: route declaration, MockStorefront adapter, reconciliation wiring, LiveView state reflection, hermetic proof lane, and docs walkthrough.

**Must have (table stakes):**
- TS-01/TS-02: `paywall_entry` route in example host router + `PaywallEntryLive` with pricing display — makes the pattern copy-able; without a real route declaration it is only a test fixture
- TS-03/TS-04: `MockStorefront` consuming `PurchaseIntent` and `RestoreIntent`, emitting `ReconciliationEvidence{source: :storefront, provider: "mock"}` — the central teaching artifact showing how a real StoreKit/Play Billing adapter would be swapped in
- TS-05/TS-06: Backend evidence submission path through `ReconciliationInbox.ingest_evidence/2` and `EntitlementProjection.project_snapshot/2` — makes the authority update step visible to adopters
- TS-07/TS-08/TS-09/TS-10: LiveView rendering all four `derived_state/1` outputs (`:granted`, `:pending`, `:denied`, `:stale`) — four-state coverage is contractually required, not just UX polish
- TS-11: Merge-blocking hermetic proof test driving the full mock lane — CI-gated proof is what separates a proven example from aspirational documentation
- TS-12: `guides/commerce.md` end-to-end paywall corridor walkthrough section — adopters use the guide before copying the example

**Should have (differentiators, include in v3.4):**
- DIF-01: `MockStorefront` designed as a clear drop-in swap target (well-commented module shape documenting what a real adapter replaces)
- DIF-02: All four `derived_state/1` outputs explicitly asserted in the proof test with distinct assertions, not just `:granted`
- DIF-05: Docs-contract test locking the commerce.md walkthrough against actual example module names — keeps the guide honest if code changes
- DIF-06: `source: :storefront` semantic explicitly shown (not `:device`) — teaches the evidence-source vocabulary

**Defer to later milestones:**
- Real StoreKit / Play Billing adapter code — v3.6 (provider adapters milestone)
- PubSub / real-time entitlement push — adopter responsibility; document as extension pattern in guide
- Multi-product paywall (consumable, non-consumable, subscription) — single `PaywallEntry` is sufficient to teach the corridor shape
- Persistent entitlement storage in the mock lane — optional UX polish; not required for hermetic proof

**Anti-features (do not include regardless of pressure):**
- Any provider SDK imports in `MockStorefront` or any example file (AF-01, AF-07)
- LiveView exposing raw `EntitlementSnapshot` lane fields — `derived_state/1` is the only UI decision function (AF-08)
- Auth/session gating on paywall route — adds auth library setup that obscures the commerce lane (AF-05)

### Architecture Approach

The architecture is a four-layer stack: Crosswake core library (do not modify), the existing example-host reconciliation layer (reuse as-is), a new mock adapter layer (`MockStorefront`), and a new example-host UI layer (`PaywallEntryLive`, router additions). Data flows strictly downward: `MockStorefront` emits `ReconciliationEvidence` → `ReconciliationInbox.ingest_evidence/2` produces an attempt with `status: :awaiting_verification` → the host backend simulates verification and builds a verified `EntitlementSnapshot` → `EntitlementProjection.project_snapshot/2` validates and promotes it → `derived_state/1` returns the four-state atom → PubSub broadcasts to `PaywallEntryLive` which updates `@entitlement_state`. The LiveView is a read model only; it never holds authoritative entitlement state.

**Major components:**
1. `CrosswakeExample.Commerce.MockStorefront` (NEW) — pure function module; `simulate_purchase/1` and `simulate_restore/1`; returns `ReconciliationEvidence{source: :storefront, provider: "mock"}`; lives in `examples/phoenix_host/`, never in `lib/`
2. `CrosswakeExample.Router` (MODIFY) — add `/paywall` scope with three corridor routes using `commerce: [corridor: :subscription_default, role: :paywall_entry|:purchase_intent|:restore_intent]`
3. `CrosswakeExample.Paywall.PaywallEntryLive` (NEW) — subscribes to PubSub `"entitlement"` topic; pattern-matches on all four `derived_state/1` values; initializes to `:stale` (fail-closed)
4. `CrosswakeExample.Paywall.PurchaseIntentLive` + `RestoreIntentLive` (NEW) — call MockStorefront then ReconciliationInbox then simulate verification then EntitlementProjection then PubSub broadcast
5. `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` (NEW) — merge-blocking hermetic proof; inline router fixtures (phase-prefixed to avoid collision); no `Code.require_file` on example-host files; drives all four `derived_state/1` state assertions
6. `.github/workflows/phase34-proof.yml` (NEW) — two-job split mirroring `phase23-proof.yml`; hermetic job gates merge; advisory job has `continue-on-error: true`
7. `guides/commerce.md` (MODIFY) — add "Paywall Corridor Walkthrough" section; extended `commerce_test.exs` docs-contract assertions lock it

**Key patterns:**
- Hermetic proof uses inline struct construction, never `Code.require_file` on example-host paths (mirrors phase23 exactly)
- `:requires_example_host` tagged test handles full corridor with `Code.require_file` at module scope, `async: false` (mirrors phase21 exactly)
- Advisory vs. merge-blocking separation enforced at CI `if:`/`continue-on-error:` level, not ExUnit tags alone

### Critical Pitfalls

1. **MockStorefront granting authority directly** — return `ReconciliationEvidence` only; route all evidence through `ingest_evidence/2`; proof test must assert `authority_mutation_allowed_from_evidence?/1` returns `false` and that `project_snapshot/2` rejects any snapshot with non-`:projection_refreshed` reconciliation state
2. **Idempotency key derived from `correlation_id`** — `MockStorefront` must use a stable `provider_reference` UUID seeded from `entry_id`, not `correlation_id` (which is transient and device-generated); replay proof test must use `provider_reference` as the stable identity
3. **Four-state LiveView collapsed to binary** — `PaywallEntryLive` must have explicit `case` branches for all four `derived_state/1` values; `:stale` must render distinctly from `:denied`; `:pending` must render a "processing" state; proof test must assert all four render outcomes
4. **Hermetic proof test with hidden example-host dependency** — no `Code.require_file` on example-host paths inside the merge-blocking proof file; `phase34-proof.yml` must run `--exclude requires_example_host`; hermeticity guard must be in the same file as the proof assertions
5. **Test isolation failures** — any test using `Code.require_file` or `File.cd!/2` must use `async: false`; inline fixture modules must use `Phase34`-prefixed names to avoid collision with phase23's `PaywallCorridorRouter`/`PurchaseCorridorRouter`; `Code.require_file` calls at module scope only, not inside test callbacks
6. **Docs-contract drift** — write example code first, then write the guide from running code; the docs-contract test must be in the same phase as the walkthrough; assert exact module names and canonical field names (`provider_reference`, `evidence_ref`, not invented aliases)

## Implications for Roadmap

Based on research, suggested phase structure (five phases, roughly two logical layers):

### Phase 1: Contract Anchor and CI Infrastructure

**Rationale:** Route corridor declarations and the CI workflow two-job split are the dependency anchors for everything else. The manifest, doctor output, and proof test fixtures all derive from the router's `commerce:` declarations. Establishing the CI split first ensures the hermetic/advisory separation is never retrofitted. This phase has zero runtime risk — pure compile-time wiring and YAML.

**Delivers:** `paywall_entry`, `purchase_intent`, `restore_intent` routes in `examples/phoenix_host/router.ex` with correct `commerce: [corridor: :subscription_default, role: ...]` DSL; `.github/workflows/phase34-proof.yml` with hermetic job (merge-blocking) and advisory job (`continue-on-error: true`) and 4-condition `promotion_path` comment.

**Addresses:** TS-01, CI infrastructure for TS-11

**Avoids:** Advisory/merge-blocking confusion (Pitfall 4b); retroactive CI restructuring

### Phase 2: MockStorefront and Idempotency Proof

**Rationale:** `MockStorefront` is the only net-new module in the data layer and the seam all downstream LiveViews and the proof test depend on. Building it second (after routes establish the corridor vocabulary) locks the exact `provider_reference` shape, `event_kind` values, and `source: :storefront` semantic before LiveView or proof test construction begins. Idempotency invariants must be proved in this phase, not deferred.

**Delivers:** `CrosswakeExample.Commerce.MockStorefront` with `simulate_purchase/1` and `simulate_restore/1`; stable `provider_reference` construction (not derived from `correlation_id`); provider-vocabulary fence test scanning mock source for forbidden tokens; replay proof sub-test establishing idempotency baseline.

**Addresses:** TS-03, TS-04, DIF-01, DIF-06

**Avoids:** Evidence-grants-authority violation (Pitfall 1); idempotency key from `correlation_id` (Pitfall 6); example drifting into billing engine (Pitfall 2)

### Phase 3: PaywallEntryLive Scaffold and Reconciliation Wiring

**Rationale:** Once `MockStorefront` exists and the corridor routes are declared, the LiveView scaffold and its reconciliation wiring can be built together. PubSub wiring belongs in this phase (not deferred) because the `:pending` → `:granted` transition is a first-class proof requirement — it cannot be bolted on after the hermetic proof test is written.

**Delivers:** `PaywallEntryLive` (four-state render with explicit `case` on `derived_state/1`); `PurchaseIntentLive` and `RestoreIntentLive` wired to MockStorefront → `ReconciliationInbox.ingest_evidence/2` → simulated verification → `EntitlementProjection.project_snapshot/2` → `Phoenix.PubSub.broadcast`; LiveView PubSub subscription with `handle_info/2` for `{:entitlement_update, state}`.

**Addresses:** TS-02, TS-05, TS-06, TS-07, TS-08, TS-09, TS-10

**Avoids:** Four-state LiveView collapsed to binary (Pitfall 5); LiveView holding authoritative entitlement state (Architecture Anti-Pattern 3)

### Phase 4: Hermetic Proof Lane

**Rationale:** The hermetic proof test is written after the data layer and LiveViews exist so it asserts against final code, not planning-draft signatures. It must be in its own file with phase-scoped fixture module names. All isolation rules are applied at first write — not retrofitted.

**Delivers:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` with all nine hermetic assertions; hermeticity self-scan guard; provider-vocabulary fence; all four `derived_state/1` state assertions; `:pending` → `:granted` transition assertion. Separate `:requires_example_host` tagged test loading MockStorefront via `Code.require_file` (module scope, `async: false`) and driving the full corridor.

**Addresses:** TS-11, DIF-02, DIF-03 (idempotency visible), DIF-04 (replay detection)

**Avoids:** Hidden environment dependency in hermetic lane (Pitfall 4a); parallel `Code.require_file` race (Pitfall 7a); module name collision (Pitfall 7c)

### Phase 5: Guides Walkthrough and Docs-Contract Lock

**Rationale:** Guide is written last — from running, final code — so module names, function arities, and struct field names in the walkthrough match the implementation exactly. The docs-contract test extension is in the same phase as the walkthrough. Non-claims section must be verified intact after the new walkthrough is added.

**Delivers:** `guides/commerce.md` "Paywall Corridor Walkthrough" section with explicit mock-vs-real callout; extended `commerce_test.exs` assertions locking walkthrough heading, exact module name (`CrosswakeExample.Commerce.MockStorefront`), canonical field names (`provider_reference`, `evidence_ref`), and all five non-claims (`StoreKit`, `Play Billing`, `Device-local authority`, `Offline purchase replay`, `Storefront purchase UI`).

**Addresses:** TS-12, DIF-05

**Avoids:** Docs-contract drift (Pitfall 3); non-claims section silently broken by guide update (Pitfall 2)

### Phase Ordering Rationale

- Routes before MockStorefront: The corridor vocabulary (`paywall_entry`, `purchase_intent`, `restore_intent` role atoms, `subscription_default` corridor) must be declared before MockStorefront or the LiveViews reference a concrete DSL shape.
- CI split before proof test: Writing `phase34-proof.yml` before the proof test file prevents assigning a test to the wrong CI job after the fact.
- Data layer before LiveView: MockStorefront is the evidence factory; ReconciliationInbox and EntitlementProjection are already proven in phase21. Wiring them before building the LiveView ensures the LiveView is built against a stable data surface.
- Proof test before guide: Writing the hermetic proof against final code catches any function rename or field alias before the guide walkthrough references them.
- Guide last, with docs-contract in same phase: The docs-contract lock is only meaningful when written against final code. Deferring it creates the exact drift it is meant to prevent.

### Research Flags

All five phases use well-documented, already-proven patterns. No phase requires `--research-phase` during planning.

- **Phase 1:** Corridor DSL shape proven in phase23 fixture routers; `phase23-proof.yml` is the exact template — no research needed
- **Phase 2:** `ReconciliationEvidence` fields verified from `contracts.ex`; idempotency pattern verified from `reconciliation_inbox.ex` and `reconciliation_keys.ex` — no research needed
- **Phase 3:** `derived_state/1` and `project_snapshot/2` verified from `entitlement_projection.ex`; PubSub subscription is standard Phoenix LiveView — no research needed
- **Phase 4:** `phase23_commerce_support_proof_test.exs` is the exact hermetic template; Phase 30 post-mortem documents all isolation rules — no research needed
- **Phase 5:** `commerce_test.exs` existing assertion patterns are the template — no research needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified from `examples/phoenix_host/mix.exs` and hex.pm API on 2026-05-29; all dep ranges accommodate current stable releases with zero changes |
| Features | HIGH | All contract surfaces are live code; grounded in `contracts.ex`, `reconciliation.ex`, example-host commerce modules, and `phase23_commerce_support_proof_test.exs` |
| Architecture | HIGH | Component boundaries derived from committed source; `derived_state/1` four-state logic and `project_snapshot/2` verification gate verified from `entitlement_projection.ex` |
| Pitfalls | HIGH | Grounded in Phase 30 post-mortem (STATE.md), `phase23-proof.yml` two-job split, `reconciliation.ex` guardrails, and `commerce_test.exs` non-claims lock |

**Overall confidence:** HIGH

### Gaps to Address

- **PubSub supervision:** The example host does not currently start `Phoenix.PubSub`. If `PaywallEntryLive` subscribes to a PubSub topic, `CrosswakeExample.PubSub` must be added to `application.ex`. This is a known one-line addition but should be confirmed before Phase 3. If it proves invasive, the `:pending` → `:granted` transition can be driven by direct socket assigns in the hermetic lane, with PubSub wiring limited to the `:requires_example_host` integration test.
- **Verified snapshot construction shape:** The data flow requires the host backend to build a verified `EntitlementSnapshot` (reconciliation `:projection_refreshed`, authority `:active`, access `:granted`, freshness `:fresh`) after `ingest_evidence/2` returns `:awaiting_verification`. The exact shape of this simulation step (inline in the LiveView handler vs. a separate context function) should be decided during Phase 3 planning so the proof test and the example code use the same construction path.

## Sources

### Primary (HIGH confidence)

- `lib/crosswake/commerce/contracts.ex` — `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence`, `EntitlementSnapshot` typed struct definitions; `authority_mutation_allowed_from_evidence?/1`
- `lib/crosswake/commerce/reconciliation.ex` — `ingest_evidence/2`, `IdempotencyKey`, `reject_direct_authority_override/1`, `outcome_implies_authority_grant?/1`
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — `derived_state/1` four-state function, `project_snapshot/2` monotonic guard and verification gate
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — `ingest_evidence/2` with event_key/subject_key/replay detection
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — provider-aware `event_key/1`, `subject_key/2`
- `examples/phoenix_host/lib/crosswake_example/router.ex` — confirmed no `paywall_entry` route exists; existing corridor DSL patterns
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermetic proof template, hermeticity guard, `@forbidden_provider_tokens` fence, inline fixture module naming conventions
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — `Code.require_file` at module scope, `async: false`, `:requires_example_host` tag, replay test shape
- `test/crosswake/guides/commerce_test.exs` — non-claims lock, corridor role parity test, docs-contract patterns
- `.github/workflows/phase23-proof.yml` — two-job split, `continue-on-error: true`, 4-condition `promotion_path`, hermetic job `if:` guard
- `.planning/STATE.md` — Phase 30 post-mortem: parallel-compile `require_file` race, global-cwd `File.cd` race
- `.planning/MILESTONE-ARC.md` — locked guardrails: "Entitlement truth remains backend- and Phoenix-owned"
- `.planning/PROJECT.md` — ENTL-03, RECN-02, Key Decisions on hermetic/advisory split, docs-contract as merge-blocking
- `.planning/threads/commerce-archetype-proof.md` — v3.4 goal, MockStorefront design constraints, advisory-to-hermetic promotion criteria
- `guides/commerce.md` — three-layer guide structure, reviewer playbooks, non-claims section
- `examples/phoenix_host/mix.exs` — complete existing dep tree (confirmed no new deps needed)
- hex.pm API (2026-05-29) — phoenix 1.8.7, phoenix_live_view 1.1.31 / 1.2.0-rc.3, ecto_sqlite3 0.24.0

### Secondary (MEDIUM confidence)

- Context7 `/phoenixframework/phoenix_live_view` — `assign/3`, `handle_event/3`, `handle_info/2` patterns confirmed; PubSub subscription mount pattern

---
*Research completed: 2026-05-29*
*Ready for roadmap: yes*
