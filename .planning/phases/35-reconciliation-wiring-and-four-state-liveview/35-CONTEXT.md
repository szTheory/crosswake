# Phase 35: Reconciliation Wiring And Four-State LiveView - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the mock paywall corridor end-to-end in `examples/phoenix_host` and render all four
entitlement states. The runtime flow:

1. A **Subscribe** (or **Restore**) `handle_event` on `PaywallEntryLive` builds a mock
   `PurchaseIntent`/`RestoreIntent`, calls `MockStorefront.simulate_purchase/2`
   (Phase 34) → `ReconciliationEvidence`.
2. Evidence → `ReconciliationInbox.ingest_evidence/2` → `EvidenceResult` map with
   `status: :awaiting_verification` (WIRE-01). This **is** the `:pending` UI state.
3. A **simulated backend verification** (new `MockBackend`) builds a *verified*
   `EntitlementSnapshot` and runs `EntitlementProjection.project_snapshot/2` (WIRE-02) →
   `derived_state/1` → one of `:granted | :pending | :denied | :stale`.
4. The result is broadcast via `Phoenix.PubSub` as `{:entitlement_update, derived_state}`.
5. `PaywallEntryLive` subscribes on mount, **initializes to `:stale` (fail-closed)**, and
   transitions only via that PubSub message (STATE-01, PWAL-02), rendering each of the four
   states as a distinct branch.

**In scope:** `PaywallEntryLive` (mount/subscribe/render/handle_event/handle_info), a new
`CrosswakeExample.Commerce.MockBackend` verification module, thin `CorridorController.purchase`/
`restore` POST actions (the routes declared in Phase 33), starting `Phoenix.PubSub` in
`application.ex`, the four-state UI with dev-only scenario drivers, and the
`{:entitlement_update, derived_state}` PubSub contract. **Requirements:** WIRE-01, WIRE-02,
STATE-01, PWAL-02.

**Out of scope:** the merge-blocking hermetic full-lane proof test (Phase 36 — this phase only
*enables* it by providing the shared `MockBackend` path), the `guides/commerce.md` walkthrough +
docs-contract lock (Phase 37). No StoreKit/Play Billing/RevenueCat/provider-SDK code
(`provider: "mock"` only); no persistence; single subscription product; no multi-product paywalls.

</domain>

<decisions>
## Implementation Decisions

### A. Verification pipeline shape (WIRE-02, STATE pending todo resolved)
- **D-01:** Introduce a new plain-Elixir module
  `CrosswakeExample.Commerce.MockBackend` that owns the verification pipeline:
  build the verified `%EntitlementSnapshot{}` → `EntitlementProjection.project_snapshot/2`
  → `derived_state/1` → broadcast. This resolves the open STATE todo ("inline LiveView
  handler vs separate context function") in favor of a **separate context module**.
- **D-02:** **Same code path for example and proof.** `PaywallEntryLive.handle_event`
  delegates to `MockBackend`; the Phase 36 hermetic proof calls `MockBackend` **directly**
  (it cannot reach `handle_event` without a running server/channel stack). The module-scope
  `Code.require_file` test idiom only works with plain modules. This completes the existing
  layering: `MockStorefront → ReconciliationInbox → MockBackend → EntitlementProjection`.
- **D-03:** The verified snapshot construction mirrors the existing phase21 test builders
  (`snapshot/1`, `authority_lane/1`, `access_lane/1`, `reconciliation_lane/1`,
  `freshness_lane/1`). For `:granted` the verified snapshot is
  `reconciliation: :projection_refreshed`, `freshness: :fresh`, `authority: :active`,
  `access: :granted`. The pure verify→project→derive core is **synchronous and
  deterministic** so the proof can assert it without timing.

### B. Verification timing (async latency)
- **D-04:** The demo models backend latency so `:pending` is observably distinct before
  `:granted`. On Subscribe: `ingest_evidence/2` runs, then **immediately broadcast
  `{:entitlement_update, :pending}`**; a `Task` (small delay) then runs the `MockBackend`
  verification core and broadcasts the terminal state. Both arrive via `handle_info` —
  mirroring real backend webhook topology (the teachable moment) and making the `:pending`
  branch genuinely reachable at runtime.
- **D-05:** The async wrapper (`Task` + delay) is a **LiveView-only** concern. The proof
  test calls the synchronous `MockBackend` core directly (D-02/D-03), so async timing never
  leaks into the hermetic lane.

### C. Corridor component topology (reconciles ROADMAP vs Phase 33 D-03)
- **D-06:** **`PaywallEntryLive` owns purchase + restore via `handle_event`**
  ("Subscribe" / "Restore" buttons), each delegating to the `MockStorefront` →
  `ReconciliationInbox` → `MockBackend` path. Phase 33 (D-02/D-03, locked) declared
  `paywall_entry` as the only `live` route; `purchase_intent`/`restore_intent` are POST
  `CorridorController` routes because those roles are `:native_or_companion_required` (NOT
  Phoenix-owned). Building them as Phoenix `live` screens would misrepresent native-owned
  corridors and contradict the runtime-ownership thesis.
- **D-07:** `CorridorController.purchase/2` and `restore/2` (forward-referenced in Phase 33)
  are implemented as **real thin seams** delegating to the **same** `MockStorefront`/
  `ReconciliationInbox`/`MockBackend` path — so the declared POST routes are live, not dead,
  and read honestly as "the backend seam a native screen/companion POSTs evidence to."
- **D-08 (ROADMAP reconciliation — confirmed with user):** The ROADMAP goal and Success
  Criterion #1 name `PurchaseIntentLive`/`RestoreIntentLive`. These are satisfied by the
  purchase-intent / restore-intent **flows** (the `handle_event` path on `PaywallEntryLive`
  + the thin controller actions), **not** by literal separate LiveView modules. The verifier
  should evaluate Criterion #1 against this reinterpretation; ROADMAP/Criterion #1 wording
  may be reworded to "the purchase-intent flow" rather than "`PurchaseIntentLive`".

### D. Four-state UI rendering (STATE-01, PWAL-02)
- **D-09:** `render/1` uses a single `case @derived_state do` dispatching to **four named
  private function components** (one per state). The `case` is the exhaustive branch map;
  the component names document the four states and make them findable by symbol search.
- **D-10:** `:stale` is **structurally** distinct from `:denied` (not just color): `:stale`
  = a fail-closed warning ("We can't verify your access right now; access is closed until
  verification succeeds") with **no** pricing and **no** Subscribe action; `:denied` = the
  paywall itself (single subscription `PaywallEntry`: pricing display + "Subscribe" button).
  `:pending` = a "processing" state. `:granted` = entitled content / "manage subscription".
- **D-11:** The UI consumes **only the derived atom** — raw `EntitlementSnapshot` lane fields
  are never rendered (STATE-01 "without exposing raw lane fields").

### E. PubSub topic & message contract (STATE-01)
- **D-12:** Start `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` in
  `examples/phoenix_host/lib/crosswake_example/application.ex` (currently Repo-only — confirms
  and resolves the Phase 33 STATE prerequisite todo).
- **D-13:** Topic is `"entitlement:" <> group_id` (mirrors Phoenix `"user:" <> id` convention
  and the existing `ReconciliationKeys.subject_key/2` notion). `PaywallEntryLive` subscribes in
  `mount` only when `connected?(socket)`.
- **D-14:** The PubSub message is exactly `{:entitlement_update, derived_state}` carrying the
  **atom only** — no snapshot/lane fields cross the wire (reinforces D-11 / STATE-01).

### F. Demo state drivers
- **D-15:** Dev-only (`Mix.env() == :dev`) scenario buttons let an adopter drive
  `PaywallEntryLive` into all four states. Each button builds a real `%EntitlementSnapshot{}`,
  runs it through `derived_state/1`, and broadcasts `{:entitlement_update, state}` — so every
  branch is demonstrably reachable **honestly** (the derivation is real, not a fabricated
  atom). The dev guard is the explicit delimiter between demo scaffolding and real data flow.

### Claude's Discretion
- Exact `MockBackend` function names/signatures and the precise verified-snapshot field
  values for each state (must pass `derived_state/1` — D-03 anchors the shape).
- The `Task` delay duration for the async `:pending → :granted` transition (D-04).
- Concrete `group_id` constant for the single subscription demo (anchored to
  `MockStorefront.@subscription_entry_id "sub_pro_monthly"`).
- Function-component names, HEEx markup, copy wording, and any CSS/visual treatment
  (detailed visual design can optionally be deferred to `/gsd-ui-phase`).
- Controller action body specifics (response shape) for `CorridorController.purchase/restore`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements
- `.planning/REQUIREMENTS.md` — v3.4 requirements (WIRE-01, WIRE-02, STATE-01, PWAL-02 for
  this phase) + Out of Scope table (AF-01..AF-08: AF-01 provider-SDK ban, AF-02 no
  persistence, AF-04 single subscription, AF-07 `provider: "mock"` only).
- `.planning/ROADMAP.md` §"Phase 35: Reconciliation Wiring And Four-State LiveView" — goal +
  5 success criteria. **Note D-08:** Criterion #1's `PurchaseIntentLive` is satisfied by the
  `handle_event` flow on `PaywallEntryLive` + thin controller, not a literal module.
- `.planning/threads/commerce-archetype-proof.md` — milestone thread / strategic intent.
- `.planning/research/SUMMARY.md` — reuse-don't-rebuild module inventory.
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md` — MockStorefront
  identity model (D-01..D-11): `simulate_purchase/2`, `simulate_restore/2`,
  `@subscription_entry_id "sub_pro_monthly"`, evidence shape consumed here.
- `.planning/phases/33-corridor-routes-and-ci-infrastructure/33-CONTEXT.md` — corridor route
  decisions (D-02 live paywall, D-03 POST purchase/restore, D-04 forward-referenced
  `PaywallEntryLive`/`CorridorController`); `phase34-proof.yml` CI lane these tests run under.

### Commerce Contracts (reuse, do not modify — SHIPPED lib code in `crosswake 0.1.0`)
- `lib/crosswake/commerce/contracts.ex` §19-38 — `PurchaseIntent` (`{entry_id, correlation_id}`),
  `RestoreIntent` (`{correlation_id}`). §40-148 — `EntitlementSnapshot` + its lanes
  (`AuthorityLane` states, `AccessLane` `:granted|:denied`, `ReconciliationLane` states incl.
  `:awaiting_verification`/`:projection_refreshed`/`:stale_authority`, `FreshnessLane`
  `:fresh|:stale|:unknown`, `EffectiveLane`, `EvidenceLane`); `@enforce_keys`
  `[:group_id, :authority, :access, :reconciliation, :freshness, :effective, :evidence, :as_of]`.
  §150-183 — `ReconciliationEvidence` enforced/optional keys.

### Phase 21 / Phase 34 Example-Host Modules (the wiring targets — reuse, do not modify)
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` —
  `simulate_purchase/2`, `simulate_restore/2` (Phase 34). Entry point of the corridor flow.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` —
  `ingest_evidence/2` returns `%{status: evidence_status(event_kind), replay?, event_key,
  subject_key, ...}`; `"purchase"`/`"restore"` → `status: :awaiting_verification` (the
  `:pending` state). WIRE-01 target.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` —
  `project_snapshot/2` (requires `reconciliation.state` ∈ verified states
  `[:projection_refreshed, :verification_failed, :conflict, :stale_authority]`; monotonic
  `as_of`) and `derived_state/1` (precedence: stale→pending→granted→denied). WIRE-02/STATE-01
  target. **Key gap MockBackend bridges:** ingest yields `:awaiting_verification`, but
  `project_snapshot/2` needs an *already-verified* snapshot.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` —
  `event_key/1`, `subject_key/2` (informs the `group_id` / topic in D-13).
- `examples/phoenix_host/lib/crosswake_example/router.ex` — declared `/commerce` routes:
  `live "/paywall", PaywallEntryLive` + `post "/purchase"|"/restore", CorridorController`
  (Phase 33); `@compile {:no_warn_undefined, ...}` list to clear once modules exist.
- `examples/phoenix_host/lib/crosswake_example/application.ex` — supervision tree (Repo only;
  add `Phoenix.PubSub` per D-12).

### Test / UI Patterns (mirror)
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` §90-200 — snapshot builder
  helpers (`snapshot/1`, `authority_lane/1`, `access_lane/1`, `reconciliation_lane/1`,
  `freshness_lane/1`) producing all four derived states; `sample_evidence/1`; provider-token
  fence pattern. `MockBackend`'s verified-snapshot construction mirrors these (D-03).
- `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` (and other
  `*_live.ex`) — existing example LiveView idiom (`use Phoenix.LiveView`, plain `mount`/
  `handle_event`); the new `PaywallEntryLive` follows the same conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MockStorefront.simulate_purchase/2` & `simulate_restore/2` — Phase 34; the corridor's
  evidence source. No changes.
- `ReconciliationInbox.ingest_evidence/2`, `EntitlementProjection.project_snapshot/2` &
  `derived_state/1` — Phase 21; wired here, not modified.
- phase21 test snapshot builders — the construction pattern `MockBackend` reuses to build
  verified/denied/stale snapshots.
- Existing `examples/phoenix_host/.../commerce/` directory — home for the new `MockBackend`
  module alongside the other commerce modules.

### Established Patterns
- Plain `use Phoenix.LiveView` modules with `mount`/`handle_event` (existing example LiveViews);
  PaywallEntryLive adds `handle_info` for the PubSub message.
- Hermetic example-host tests reach example modules via `Code.require_file` at module scope and
  stay UNtagged → they run in the `phase34-proof.yml` merge-blocking lane. This is precisely why
  the verification pipeline must be a plain module (`MockBackend`), callable without a server (D-02).
- `provider:` is the string `"mock"`; `source:` is the atom `:storefront`. No provider tokens.
- `@compile {:no_warn_undefined, ...}` in the router lists the forward-referenced modules
  (Phase 33 D-05); entries can be removed as `PaywallEntryLive`/`CorridorController` land.

### Integration Points
- Subscribe click → `MockStorefront` → `ReconciliationInbox.ingest_evidence/2` →
  broadcast `:pending` → (Task) `MockBackend` verify → `project_snapshot/2` → `derived_state/1`
  → broadcast terminal state → `PaywallEntryLive.handle_info` → assign → render branch.
- `Phoenix.PubSub` (new in `application.ex`) is the transport; topic `"entitlement:" <> group_id`.
- `CorridorController.purchase/restore` POST actions delegate into the same path (D-07).
- Phase 36's hermetic proof calls `MockBackend` directly — this phase's deliverable enables it.

</code_context>

<specifics>
## Specific Ideas

- Layering one-liner: `MockStorefront → ReconciliationInbox → MockBackend → EntitlementProjection`,
  with `PaywallEntryLive` and `CorridorController` both delegating to `MockBackend` and the
  Phase 36 proof calling `MockBackend` directly (single shared verification path).
- Async transition: emit `:pending` synchronously on click, then `Task` → verify → broadcast
  terminal state; both delivered via `handle_info({:entitlement_update, state}, socket)`.
- Fail-closed mount: `assign(socket, derived_state: :stale)` before any PubSub message.
- Four named function components: `<.granted/>`, `<.pending/>`, `<.denied/>` (the paywall),
  `<.stale/>` — dispatched by `case @derived_state`.
- Dev scenario buttons (`Mix.env() == :dev`) build real snapshots → `derived_state/1` → broadcast,
  so all four branches are reachable honestly in the running example.

</specifics>

<deferred>
## Deferred Ideas

- **Merge-blocking hermetic full-lane proof** (`phase34_paywall_corridor_proof_test.exs`,
  asserting all four states, the `:pending → :granted` transition, and the mock-boundary fence)
  — Phase 36 (PROOF-01, PROOF-03). This phase only provides the shared `MockBackend` path it
  asserts against.
- **`guides/commerce.md` end-to-end walkthrough + docs-contract lock** — Phase 37 (DOCS-01,
  DOCS-02). The wiring built here is what that walkthrough narrates.
- **Detailed visual/UX polish of the four states** — optionally `/gsd-ui-phase` (UI hint: yes).
  This phase locks *functional* UI intent (four named branches, structural stale≠denied, dev
  drivers); pixel-level design is non-blocking.
- **Multi-product / consumable / non-consumable paywalls** — out of scope (AF-04); single
  subscription product only.
- **Real provider adapters (StoreKit / Play Billing)** — out of scope (AF-01); deferred to v3.6
  (ADPT-01/02/03), advisory CI only.

### Reviewed Todos (not folded)
None — the `todo.match-phase` query returned no matches. The two relevant STATE pending todos
(verification-simulation shape; PubSub-not-started prerequisite) were resolved as decisions
D-01/D-02 and D-12 respectively.

</deferred>

---

*Phase: 35-Reconciliation Wiring And Four-State LiveView*
*Context gathered: 2026-05-29*
