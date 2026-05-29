# Phase 35: Reconciliation Wiring And Four-State LiveView — Research

**Researched:** 2026-05-29
**Domain:** Elixir/Phoenix LiveView wiring, PubSub, entitlement state machine
**Confidence:** HIGH — all claims verified from actual source files in this codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** New module `CrosswakeExample.Commerce.MockBackend` owns the verification pipeline
  (build verified `%EntitlementSnapshot{}` → `project_snapshot/2` → `derived_state/1` → broadcast).
- **D-02:** Same code path for example and proof. `PaywallEntryLive.handle_event` delegates to
  `MockBackend`; Phase 36 hermetic proof calls `MockBackend` directly.
- **D-03:** Verified snapshot construction mirrors phase21 test builders (`snapshot/1`,
  `authority_lane/1`, etc.). For `:granted`: `reconciliation: :projection_refreshed`,
  `freshness: :fresh`, `authority: :active`, `access: :granted`.
- **D-04:** On Subscribe: `ingest_evidence/2` runs → immediately broadcast `:pending`; a Task
  (small delay) then runs `MockBackend` and broadcasts the terminal state.
- **D-05:** The async Task wrapper is LiveView-only. Proof calls the synchronous `MockBackend`
  core directly.
- **D-06:** `PaywallEntryLive` owns purchase + restore via `handle_event` ("subscribe" / "restore").
- **D-07:** `CorridorController.purchase/2` and `restore/2` are real thin seams delegating to the
  same `MockStorefront` / `ReconciliationInbox` / `MockBackend` path.
- **D-08:** "PurchaseIntentLive" / "RestoreIntentLive" in the ROADMAP are satisfied by the
  `handle_event` flows on `PaywallEntryLive` plus thin controller actions — not literal modules.
- **D-09:** `render/1` uses `case @derived_state do` dispatching to four named private function
  components: `<.granted/>`, `<.pending/>`, `<.denied/>`, `<.stale/>`.
- **D-10:** `:stale` is structurally distinct from `:denied` — no pricing, no Subscribe action.
- **D-11:** UI consumes only the derived atom; raw `EntitlementSnapshot` lane fields are never
  rendered.
- **D-12:** Start `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` in `application.ex`
  (currently Repo-only).
- **D-13:** Topic is `"entitlement:" <> group_id`. Subscribe only when `connected?(socket)`.
- **D-14:** PubSub message is exactly `{:entitlement_update, derived_state}` (atom only).
- **D-15:** Dev-only (`Mix.env() == :dev`) scenario buttons build real snapshots → `derived_state/1`
  → broadcast.

### Claude's Discretion

- Exact `MockBackend` function names/signatures and precise verified-snapshot field values for
  each state (must pass `derived_state/1` — D-03 anchors the shape).
- The `Task` delay duration for the async `:pending → :granted` transition (D-04).
- Concrete `group_id` constant for the single subscription demo (anchored to
  `MockStorefront.@subscription_entry_id "sub_pro_monthly"`).
- Function-component names, HEEx markup, copy wording, and any CSS/visual treatment.
- Controller action body specifics (response shape) for `CorridorController.purchase/restore`.

### Deferred Ideas (OUT OF SCOPE)

- Merge-blocking hermetic full-lane proof (`phase34_paywall_corridor_proof_test.exs`) — Phase 36.
- `guides/commerce.md` walkthrough + docs-contract lock — Phase 37.
- Detailed visual/UX polish — optionally `/gsd-ui-phase`.
- Multi-product / consumable / non-consumable paywalls (AF-04).
- Real provider adapters — StoreKit / Play Billing — out of scope (AF-01); deferred to v3.6.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WIRE-01 | Adopter can see example submit mock `ReconciliationEvidence` to `ReconciliationInbox.ingest_evidence/2` and handle the returned `EvidenceResult` | `ReconciliationInbox.ingest_evidence/2` verified; returns `{:ok, %{status: :awaiting_verification, ...}}` for "purchase"/"restore" event kinds |
| WIRE-02 | Adopter can see `EntitlementProjection.project_snapshot/2` invoked after simulated backend verification, producing the authoritative entitlement snapshot | `project_snapshot/2` verified; requires `reconciliation.state ∈ [:projection_refreshed, :verification_failed, :conflict, :stale_authority]` — bridged by `MockBackend` |
| STATE-01 | `PaywallLive` reflects entitlement via `derived_state/1` as four distinct UI states without exposing raw lane fields | `derived_state/1` precedence verified: stale→pending→granted→denied. Four-state case dispatch locked by D-09/D-11 |
| PWAL-02 | Adopter can see `PaywallLive` render a single subscription `PaywallEntry` (pricing + Subscribe) with zero provider-SDK code | `PaywallEntry` struct verified (`@enforce_keys [:id, :price_display, :group_id, :features]`); the `:denied` state renders this content; MockStorefront has no provider-SDK code |

</phase_requirements>

---

## Summary

This phase wires the mock paywall corridor end-to-end and renders all four derived entitlement
states in `PaywallEntryLive`. The existing modules (`MockStorefront`, `ReconciliationInbox`,
`EntitlementProjection`) are complete and proven; this phase adds the bridging `MockBackend`
module, the `PaywallEntryLive` LiveView, a thin `CorridorController`, PubSub startup, and the
dev-scenario panel.

The single most important technical insight is the **verification gap bridge**: `ingest_evidence/2`
always returns `status: :awaiting_verification`, but `project_snapshot/2` refuses snapshots with
`reconciliation.state == :awaiting_verification` (it rejects anything not in
`@verified_reconciliation_states`). `MockBackend` bridges this by constructing a fresh
`%EntitlementSnapshot{}` with `reconciliation.state: :projection_refreshed` (or another verified
state for non-granted outcomes), bypassing the ingest result and calling `project_snapshot/2`
directly. This is intentional design: in production, a real backend webhook delivers the verified
snapshot; in the mock, `MockBackend` manufactures it.

The second structural fact: `PaywallEntryLive` initializes to `:stale` (fail-closed) and
transitions *only* via `handle_info({:entitlement_update, derived_state}, socket)` messages from
PubSub. The `:pending` state is made observably distinct by broadcasting it synchronously on
click, before the `Task`-delayed verification completes. All four states are reachable from the
dev scenario panel.

**Primary recommendation:** Implement `MockBackend.verify/1` (or similar) as a pure function
that takes a `ReconciliationEvidence` (or just a `group_id`) and returns `{derived_state, snapshot}`.
`PaywallEntryLive` and `CorridorController` both call it; Phase 36 calls it directly in tests
without a server.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Evidence emission | `MockStorefront` (pure Elixir) | — | Phase 34 delivered; reuse-only |
| Evidence ingestion | `ReconciliationInbox` (pure Elixir) | — | Phase 21 delivered; reuse-only |
| Verification simulation + snapshot build | `MockBackend` (new, pure Elixir) | — | The bridging layer between ingest (`:awaiting_verification`) and projection (needs verified state) |
| Snapshot projection + state derivation | `EntitlementProjection` (pure Elixir) | — | Phase 21 delivered; reuse-only |
| PubSub broadcast | `MockBackend` or `PaywallEntryLive` | — | MockBackend broadcasts; LiveView subscribes |
| UI four-state rendering | `PaywallEntryLive` (LiveView) | — | Receives atom from PubSub, renders via case dispatch |
| POST corridor seam | `CorridorController` (thin controller) | — | Delegates to MockBackend; returns JSON `%{status: evidence_status}` |
| PubSub bus startup | `application.ex` supervision tree | — | `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` added per D-12 |

---

## Standard Stack

No new dependencies. This phase is zero-new-dependency by milestone design (AF-02 / REQUIREMENTS.md).

### Existing Stack (all already in `examples/phoenix_host/mix.exs`)

| Library | Version (lock) | Purpose | Status |
|---------|---------------|---------|--------|
| `phoenix` | 1.8.7 | Router, LiveView, PubSub | Already in deps |
| `phoenix_live_view` | ~1.1 | `use Phoenix.LiveView`, HEEx, connected?/1 | Already in deps |
| `phoenix_pubsub` | 2.2.0 | `Phoenix.PubSub.subscribe/broadcast` | Already in deps (transitive via phoenix) |
| `crosswake` | path: `../..` | `Contracts.*`, routes DSL | Already in deps |

[VERIFIED: mix.lock at `examples/phoenix_host/mix.lock`] — `phoenix_pubsub` 2.2.0 is present as
a transitive dependency of `phoenix` 1.8.7. No separate entry needed in `mix.exs`.

**Installation:** No new packages to install.

---

## Package Legitimacy Audit

No new packages are introduced in this phase. The section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
User click "Subscribe" / "Restore"
         |
         v
PaywallEntryLive.handle_event("subscribe" | "restore", ...)
         |
         +-- build PurchaseIntent / RestoreIntent
         |
         v
MockStorefront.simulate_purchase/2 | simulate_restore/2
         |  returns %ReconciliationEvidence{source: :storefront, provider: "mock"}
         v
ReconciliationInbox.ingest_evidence/2
         |  returns {:ok, %{status: :awaiting_verification, subject_key: ..., ...}}
         v
Phoenix.PubSub.broadcast(CrosswakeExample.PubSub,
  "entitlement:" <> group_id, {:entitlement_update, :pending})
         |
         v
Task.start(fn -> :timer.sleep(delay); MockBackend.verify_and_broadcast(evidence, group_id) end)
         |
         v [async, inside Task]
MockBackend  -- builds %EntitlementSnapshot{reconciliation: :projection_refreshed, ...}
         |
         v
EntitlementProjection.project_snapshot(nil | current, incoming_snapshot)
         |  returns {:ok, projected}
         v
EntitlementProjection.derived_state(projected)
         |  returns :granted | :pending | :denied | :stale
         v
Phoenix.PubSub.broadcast(CrosswakeExample.PubSub,
  "entitlement:" <> group_id, {:entitlement_update, derived_state})
         |
         v [received by LiveView via handle_info]
PaywallEntryLive.handle_info({:entitlement_update, state}, socket)
         |  assign(socket, derived_state: state)
         v
render/1 -- case @derived_state -- four named function components
  :granted -> <.granted />   (green border, "Access granted", manage link)
  :pending -> <.pending />   (amber border, "Processing...", no action)
  :denied  -> <.denied />    (neutral, pricing, Subscribe CTA + Restore link)
  :stale   -> <.stale />     (yellow-50 bg, warning, NO pricing, NO subscribe)

CorridorController.purchase/2 | restore/2
  (POST /commerce/purchase | /commerce/restore)
  -> same MockStorefront -> ReconciliationInbox -> MockBackend path
  -> returns JSON %{status: evidence_status}
```

### Recommended Project Structure

```
examples/phoenix_host/lib/crosswake_example/
├── application.ex              # ADD: {Phoenix.PubSub, name: CrosswakeExample.PubSub}
├── router.ex                   # MODIFY: remove @compile {:no_warn_undefined, PaywallEntryLive/CorridorController}
├── commerce/
│   ├── mock_storefront.ex      # REUSE — no changes
│   ├── reconciliation_inbox.ex # REUSE — no changes
│   ├── entitlement_projection.ex # REUSE — no changes
│   ├── reconciliation_keys.ex  # REUSE — no changes
│   └── mock_backend.ex         # NEW — verification pipeline module
├── paywall_entry_live.ex       # NEW — four-state LiveView
└── corridor_controller.ex      # NEW — thin POST seam
```

Note: `paywall_entry_live.ex` and `corridor_controller.ex` live directly in
`crosswake_example/` (parallel to `router.ex`) because they are in the
`CrosswakeExample` namespace as declared in `router.ex` scope `"/commerce", CrosswakeExample`.

### Pattern 1: Phoenix.PubSub startup and subscribe

[VERIFIED: `examples/phoenix_host/deps/phoenix_pubsub/lib/phoenix/pubsub.ex`]

```elixir
# application.ex — add BEFORE CrosswakeExample.Repo
children = [
  {Phoenix.PubSub, name: CrosswakeExample.PubSub},
  CrosswakeExample.Repo
]
```

```elixir
# PaywallEntryLive.mount/3
def mount(_params, _session, socket) do
  if connected?(socket) do
    group_id = "sub_pro_monthly"  # anchored to @subscription_entry_id
    Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> group_id)
  end
  {:ok, assign(socket, derived_state: :stale)}
end
```

`connected?(socket)` guards the subscription so it only runs for the live (WebSocket-connected)
mount, not the initial static render. [VERIFIED: `claims_live.ex` line 9 uses the same guard.]

### Pattern 2: handle_info for PubSub message

```elixir
def handle_info({:entitlement_update, derived_state}, socket) do
  {:noreply, assign(socket, derived_state: derived_state)}
end
```

The LiveView process receives the message because it subscribed in mount. No other handling needed
— the assign triggers a re-render dispatching the `case`.

### Pattern 3: Four-state case dispatch

[VERIFIED: D-09, D-10 in CONTEXT.md; UI-SPEC component inventory]

```elixir
def render(assigns) do
  ~H"""
  <div class="paywall-corridor">
    <%= case @derived_state do %>
      <% :granted -> %> <.granted />
      <% :pending -> %> <.pending />
      <% :denied  -> %> <.denied />
      <% :stale   -> %> <.stale />
    <% end %>
    <%= if Mix.env() == :dev do %>
      <.dev_scenarios />
    <% end %>
  </div>
  """
end
```

The `case` has NO fallthrough `_ ->` clause — all four atoms are exhaustive branches per D-09.
(Note: In HEEx, `case` in EEx is written with `<% case ... do %>` / `<% end %>`; the `<% :atom -> %>`
form is the per-branch head.)

### Pattern 4: Task spawn for async verification (D-04/D-05)

```elixir
def handle_event("subscribe", _params, socket) do
  group_id = "sub_pro_monthly"
  intent = %Contracts.PurchaseIntent{
    entry_id: "sub_pro_monthly",
    correlation_id: Ecto.UUID.generate()
  }
  evidence = MockStorefront.simulate_purchase(intent)
  {:ok, _attempt} = ReconciliationInbox.ingest_evidence(evidence)
  # Broadcast :pending synchronously (WIRE-01 teachable moment)
  Phoenix.PubSub.broadcast(CrosswakeExample.PubSub,
    "entitlement:" <> group_id,
    {:entitlement_update, :pending})
  # Spawn async verification (D-04 mock backend latency)
  Task.start(fn ->
    :timer.sleep(1_500)  # duration is Claude's discretion
    MockBackend.verify_and_broadcast(evidence, group_id)
  end)
  {:noreply, socket}
end
```

`Task.start/1` (fire-and-forget) is appropriate here because the LiveView process does not need
the Task result directly — the result arrives via PubSub. The Task uses `CrosswakeExample.PubSub`
by name, so it can broadcast without holding a reference to the LiveView pid.

### Pattern 5: MockBackend synchronous core (D-01, D-02, D-03)

```elixir
defmodule CrosswakeExample.Commerce.MockBackend do
  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.EntitlementProjection

  # Called by PaywallEntryLive (via Task) and directly by Phase 36 proof.
  @spec verify_and_broadcast(Contracts.ReconciliationEvidence.t(), String.t()) :: :ok
  def verify_and_broadcast(evidence, group_id) do
    snapshot = build_verified_snapshot(evidence, group_id)
    {:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
    state = EntitlementProjection.derived_state(projected)
    Phoenix.PubSub.broadcast(CrosswakeExample.PubSub,
      "entitlement:" <> group_id,
      {:entitlement_update, state})
    :ok
  end

  # Synchronous core — callable without a server. Phase 36 calls this.
  @spec build_verified_snapshot(Contracts.ReconciliationEvidence.t(), String.t()) ::
          Contracts.EntitlementSnapshot.t()
  def build_verified_snapshot(evidence, group_id) do
    # ... constructs the snapshot per D-03 field values (see below)
  end
end
```

**Phase 36 direct call pattern:**
```elixir
# In proof test (no server, no PubSub):
snapshot = MockBackend.build_verified_snapshot(evidence, group_id)
{:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
state = EntitlementProjection.derived_state(projected)
assert state == :granted
```

### Pattern 6: CorridorController thin seam (D-07)

```elixir
defmodule CrosswakeExample.CorridorController do
  use Phoenix.Controller, formats: [:json]
  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.{MockStorefront, ReconciliationInbox, MockBackend}

  def purchase(conn, _params) do
    group_id = "sub_pro_monthly"
    intent = %Contracts.PurchaseIntent{
      entry_id: "sub_pro_monthly",
      correlation_id: Ecto.UUID.generate()
    }
    evidence = MockStorefront.simulate_purchase(intent)
    {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    Task.start(fn -> MockBackend.verify_and_broadcast(evidence, group_id) end)
    json(conn, %{status: attempt.status})
  end

  def restore(conn, _params) do
    group_id = "sub_pro_monthly"
    intent = %Contracts.RestoreIntent{correlation_id: Ecto.UUID.generate()}
    evidence = MockStorefront.simulate_restore(intent)
    {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    Task.start(fn -> MockBackend.verify_and_broadcast(evidence, group_id) end)
    json(conn, %{status: attempt.status})
  end
end
```

### Anti-Patterns to Avoid

- **Putting verification logic inline in `handle_event`:** D-01/D-02 locked MockBackend as the
  shared module. Inline logic prevents Phase 36 from calling it directly without a server.
- **Broadcasting the raw snapshot or lane fields:** D-11/D-14 — the PubSub message carries only
  the derived atom. Never send `%EntitlementSnapshot{}` over the wire.
- **Subscribing outside `connected?(socket)`:** The static mount renders twice (disconnect + connect);
  subscribing unconditionally creates a duplicate subscription.
- **Passing `:awaiting_verification` snapshot to `project_snapshot/2`:** This returns
  `{:error, :unverified_reconciliation_outcome}`. MockBackend must build a snapshot with
  `reconciliation.state ∈ [:projection_refreshed, :verification_failed, :conflict, :stale_authority]`.
- **Using a `_ ->` fallthrough in the `case @derived_state do`:** D-09 requires all four atoms
  as explicit branches for symbol searchability and exhaustiveness.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PubSub messaging | Custom GenServer registry | `Phoenix.PubSub` (already in deps) | Already available; standard Phoenix idiom |
| Async background work | GenServer/Agent | `Task.start/1` | Fire-and-forget; no state needed; LiveView receives result via PubSub not callback |
| UUID for correlation_id | Custom string generation | `Ecto.UUID.generate()` | `ecto_sql` already in deps; used by `study_session_live.ex` (line 16) |
| Snapshot construction validation | Custom validator | `Contracts.new_entitlement_snapshot/1` | The lib provides a validator; but for MockBackend use `struct!` directly mirroring phase21 test helpers (they use `struct!` not `new_entitlement_snapshot`) |

**Key insight:** All infrastructure (PubSub, Task, struct construction) already exists in the
project. This phase is pure wiring — no new mechanisms.

---

## The Verification Gap: Core Technical Crux

This is the central implementation challenge of the phase.

**The gap:**
```
ingest_evidence/2 result:   %{status: :awaiting_verification, ...}
project_snapshot/2 requires: reconciliation.state ∈ [:projection_refreshed,
                              :verification_failed, :conflict, :stale_authority]
```

`ingest_evidence/2` NEVER returns a snapshot — it returns a plain map with metadata
(lines 22-35 of `reconciliation_inbox.ex`). There is no `%EntitlementSnapshot{}` coming out
of ingest. MockBackend must build the snapshot from scratch.

**How `MockBackend` bridges the gap — field values for each derived state:**

For `derived_state/1` precedence (lines 39-53 of `entitlement_projection.ex`):
1. `:stale` wins if `freshness.state ∈ [:stale, :unknown]`
2. `:pending` wins if `reconciliation.state ∈ [:pending_purchase, :pending_restore, :awaiting_verification]`
3. `:granted` wins if: `freshness.state == :fresh` AND `reconciliation.state == :projection_refreshed` AND `authority.state ∈ [:active, :grace, :billing_retry, :canceled_scheduled_end]` AND `access.decision == :granted`
4. `:denied` is the fallthrough

**Concrete snapshot field requirements per state** (mirrors phase21 test helpers, lines 90-108):

| Target `derived_state` | `reconciliation.state` | `freshness.state` | `authority.state` | `access.decision` | `as_of` |
|------------------------|----------------------|-------------------|-------------------|-------------------|---------|
| `:granted` | `:projection_refreshed` | `:fresh` | `:active` | `:granted` | monotonic int |
| `:pending` | `:awaiting_verification` | `:fresh` | `:none` | `:denied` | monotonic int |
| `:denied` | `:projection_refreshed` | `:fresh` | `:none` (or non-grantable state) | `:denied` | monotonic int |
| `:stale` | `:projection_refreshed` (or any) | `:stale` | `:none` | `:denied` | monotonic int |

**Critical note on `:pending` from MockBackend:** MockBackend produces the terminal states
(`:granted`, `:denied`, `:stale`). The `:pending` state is produced by `PaywallEntryLive`
broadcasting it directly after `ingest_evidence/2` returns — before MockBackend runs. MockBackend
should NOT produce `:pending` (that would break the async flow). However, for the **dev scenario
panel** (D-15), building a `:pending` snapshot is valid — set `reconciliation.state:
:awaiting_verification` and `freshness.state: :fresh`.

**`project_snapshot/2` with `nil` current (first call):**
```elixir
# Line 19-23 of entitlement_projection.ex
def project_snapshot(nil, %EntitlementSnapshot{} = incoming) do
  with :ok <- ensure_verified_reconciliation(incoming.reconciliation.state) do
    {:ok, incoming}
  end
end
```
MockBackend can safely pass `nil` as the current snapshot for the demo (no persistent state).

**Monotonic `as_of`:** The `as_of` field must be a comparable value — integer or ISO8601 string.
For the demo, `System.system_time(:microsecond)` is a simple monotonic integer source.

---

## Exact Signatures and Contracts

### `MockStorefront.simulate_purchase/2`
[VERIFIED: `mock_storefront.ex` lines 52-63]
```elixir
@spec simulate_purchase(Contracts.PurchaseIntent.t(), keyword()) ::
        Contracts.ReconciliationEvidence.t()
```
Returns raw `%ReconciliationEvidence{}` (no `{:ok, _}` wrapper).
Fields set: `source: :storefront, provider: "mock", event_kind: "purchase",
provider_reference: "mock_txn_" <> entry_id, evidence_ref: "mock_evt_" <> entry_id <> "_purchase",
captured_at: ISO8601 string`.

`PurchaseIntent` requires `@enforce_keys [:entry_id, :correlation_id]`.

### `MockStorefront.simulate_restore/2`
[VERIFIED: `mock_storefront.ex` lines 65-76]
```elixir
@spec simulate_restore(Contracts.RestoreIntent.t(), keyword()) ::
        Contracts.ReconciliationEvidence.t()
```
Returns raw `%ReconciliationEvidence{}`. Uses `@subscription_entry_id "sub_pro_monthly"` — NOT
the intent's correlation_id — for both `provider_reference` and `evidence_ref`.

`RestoreIntent` requires `@enforce_keys [:correlation_id]` (NO `entry_id`).

### `ReconciliationInbox.ingest_evidence/2`
[VERIFIED: `reconciliation_inbox.ex` lines 14-37]
```elixir
@spec ingest_evidence(Contracts.ReconciliationEvidence.t(), keyword()) ::
        {:ok, map()} | {:error, term()}
```
Returns `{:ok, %{source, event_key, subject_key, status, replay?, captured_at, trace_metadata}}`.

For `event_kind ∈ ["purchase", "restore", "renewal", "grace_period", "billing_retry"]`:
`status: :awaiting_verification`.
For all others: `status: :verification_failed`.

Optional `opts`: `group_id:`, `correlation_id:`, `seen_event_keys:`.

The `subject_key` computation: `ReconciliationKeys.subject_key(evidence, group_id: group_id)`.
This becomes the PubSub topic suffix if desired, but D-13 anchors the topic to `group_id` directly
(not `subject_key`) for simplicity.

### `EntitlementProjection.project_snapshot/2`
[VERIFIED: `entitlement_projection.ex` lines 15-36]
```elixir
@spec project_snapshot(EntitlementSnapshot.t() | nil, EntitlementSnapshot.t()) ::
        {:ok, EntitlementSnapshot.t()}
        | {:error, :unverified_reconciliation_outcome}
        | {:error, {:stale_authority, EntitlementSnapshot.t()}}
```
**Preconditions (both clauses):**
1. `incoming.reconciliation.state` MUST be in `@verified_reconciliation_states`
   (`[:projection_refreshed, :verification_failed, :conflict, :stale_authority]`).
   If not → `{:error, :unverified_reconciliation_outcome}`.
2. `incoming.as_of >= current.as_of` (monotonic; only applies when `current != nil`).
   If violated → `{:error, {:stale_authority, stale_snapshot}}`.

When `current == nil`: only precondition #1 applies.

### `EntitlementProjection.derived_state/1`
[VERIFIED: `entitlement_projection.ex` lines 38-53]
```elixir
@spec derived_state(EntitlementSnapshot.t()) :: :stale | :pending | :denied | :granted
```
Precedence (strict cond, not case):
1. `freshness.state ∈ [:stale, :unknown]` → `:stale`
2. `reconciliation.state ∈ [:pending_purchase, :pending_restore, :awaiting_verification]` → `:pending`
3. `freshness == :fresh AND reconciliation == :projection_refreshed AND authority ∈ @grantable AND access == :granted` → `:granted`
4. Otherwise → `:denied`

### `EntitlementSnapshot` struct
[VERIFIED: `contracts.ex` lines 135-136]
```elixir
@enforce_keys [:group_id, :authority, :access, :reconciliation, :freshness, :effective, :evidence, :as_of]
```
All eight keys are required. The `FreshnessLane` additionally enforces `[:state, :checked_at]`.
`EffectiveLane` enforces `[:effective_from]`. `EvidenceLane` enforces `[:source, :reference]`.

### `ReconciliationKeys.subject_key/2`
[VERIFIED: `reconciliation_keys.ex` lines 32-42]
```elixir
@spec subject_key(Contracts.ReconciliationEvidence.t(), keyword()) :: String.t()
```
With `group_id`: `"subject::mock::<provider_reference>::group::<group_id>"`.
Without `group_id`: `"subject::mock::<provider_reference>"`.

For the demo the PubSub topic is `"entitlement:sub_pro_monthly"` (using the entry_id directly
per D-13, not the full subject_key).

### Router scope (already declared)
[VERIFIED: `router.ex` lines 221-246]
The three routes are live:
- `live "/paywall", PaywallEntryLive, :index` → `CrosswakeExample.PaywallEntryLive`
- `post "/purchase", CorridorController, :purchase` → `CrosswakeExample.CorridorController`
- `post "/restore", CorridorController, :restore` → `CrosswakeExample.CorridorController`

Both `@compile {:no_warn_undefined, CrosswakeExample.PaywallEntryLive}` and
`@compile {:no_warn_undefined, CrosswakeExample.CorridorController}` exist at lines 29-30 of
`router.ex`. Once the modules are created, these suppressions can be removed (or left — they
become no-ops once the modules exist).

---

## Common Pitfalls

### Pitfall 1: Passing `:awaiting_verification` snapshot to `project_snapshot/2`
**What goes wrong:** `{:error, :unverified_reconciliation_outcome}` — the function returns an
error tuple and no broadcast happens.
**Why it happens:** Misunderstanding that `ingest_evidence/2` status maps to snapshot reconciliation
state. They are different: ingest returns a result *map* (not a snapshot), and the status
`:awaiting_verification` must NOT be directly transferred to the snapshot's `reconciliation.state`
when calling `project_snapshot/2`.
**How to avoid:** MockBackend constructs a fresh snapshot with `reconciliation.state:
:projection_refreshed` for the `:granted` case. The ingest result is used only for its `event_key`
/ `subject_key` metadata, not as a template for the snapshot.
**Warning signs:** Pattern-match failure or `{:error, :unverified_reconciliation_outcome}` in
the Task body.

### Pitfall 2: PubSub not started before subscribe call
**What goes wrong:** `** (ArgumentError) no process: the process is not alive or there's no
process currently associated with the given name` when `Phoenix.PubSub.subscribe/2` is called.
**Why it happens:** `application.ex` currently starts only `CrosswakeExample.Repo` (line 8).
`Phoenix.PubSub` is NOT auto-started by Phoenix 1.8 unless declared in the supervision tree.
**How to avoid:** Add `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` as first child in
`application.ex` (D-12). This is not a mix.exs change — `phoenix_pubsub` 2.2.0 is already in
the lockfile as a transitive dep.
**Warning signs:** Mount raises, or `handle_info` messages are never received.

### Pitfall 3: Subscribing without `connected?(socket)` guard
**What goes wrong:** Duplicate subscription — the LiveView process subscribes once on the static
HTTP render and again on the WebSocket connect. Results in duplicate `handle_info` deliveries.
**Why it happens:** Phoenix LiveView mounts twice: once for the static render (disconnected) and
once for the live connection. `Phoenix.PubSub.subscribe/2` has no idempotency guard.
**How to avoid:** Wrap the subscribe call in `if connected?(socket) do ... end` in `mount/3`.
[VERIFIED: `claims_live.ex` line 9 uses this exact guard pattern.]

### Pitfall 4: Attempting to use ingest result as the snapshot input
**What goes wrong:** Type mismatch — `ReconciliationInbox.ingest_evidence/2` returns `{:ok, map()}`
(a plain map, not a struct). It cannot be passed to `project_snapshot/2` which expects
`%EntitlementSnapshot{}`.
**Why it happens:** The architecture of ingest is deliberately *not* a snapshot builder.
**How to avoid:** After ingest succeeds, discard the result (or use only `event_key`/`subject_key`
for logging), then build the snapshot from scratch in `MockBackend`.

### Pitfall 5: RestoreIntent missing `entry_id` field
**What goes wrong:** Compile error or struct construction failure.
**Why it happens:** `RestoreIntent` has `@enforce_keys [:correlation_id]` — no `entry_id`.
`MockStorefront.simulate_restore/2` hardcodes `@subscription_entry_id` internally.
**How to avoid:** Build `%Contracts.RestoreIntent{correlation_id: uuid}` — never pass `entry_id`.

### Pitfall 6: Monotonic `as_of` violation in demo flow
**What goes wrong:** `{:error, {:stale_authority, stale_snapshot}}` from `project_snapshot/2`
when the demo is re-triggered quickly.
**Why it happens:** `as_of` comparison is strict: `incoming_rank < current_rank → :stale`.
If the same static integer (e.g., `1`) is used for every snapshot construction in MockBackend,
a second subscription click produces a snapshot with the same `as_of` — which passes (`>=` is
acceptable since `incoming_rank < current_rank` is the rejection condition). But if the demo
always passes `nil` as current (stateless demo), the issue never arises.
**How to avoid:** For the stateless demo, always pass `nil` as the current snapshot in
`project_snapshot(nil, incoming)`. Or use `System.system_time(:microsecond)` as `as_of` to
always be monotonically increasing.

### Pitfall 7: `Mix.env() == :dev` evaluated at runtime vs compile time
**What goes wrong:** Dev scenario panel appears in production builds.
**Why it happens:** In HEEx, `if Mix.env() == :dev` is evaluated at *runtime* in a BEAM release
if the function component is a private `def`. D-15 intends a compile-time guard.
**How to avoid:** Use `@dev_mode (Mix.env() == :dev)` as a module attribute evaluated at compile
time, then guard the component as `if @dev_mode` in the render template. Or declare the dev
scenarios component body as empty in non-dev using a conditional `defp`.

---

## Code Examples

### Snapshot builder for `:granted` (mirroring phase21 helpers)
[VERIFIED: `phase21_reconciliation_example_test.exs` lines 90-108]
```elixir
alias Crosswake.Commerce.Contracts

def granted_snapshot(group_id) do
  %Contracts.EntitlementSnapshot{
    group_id: group_id,
    authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :active, reason: nil},
    access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: nil},
    reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
      state: :projection_refreshed,
      reference: "mock_backend_ref"
    },
    freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
      state: :fresh,
      checked_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      stale_after: nil
    },
    effective: %Contracts.EntitlementSnapshot.EffectiveLane{
      effective_from: DateTime.utc_now() |> DateTime.to_iso8601(),
      effective_until: nil
    },
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :storefront,
      reference: "mock_evt_sub_pro_monthly_purchase",
      observed_at: DateTime.utc_now() |> DateTime.to_iso8601()
    },
    as_of: System.system_time(:microsecond)
  }
end
```

For `:denied`: same but `authority.state: :none`, `access.decision: :denied`,
`reconciliation.state: :projection_refreshed`, `freshness.state: :fresh`.

For `:stale`: `freshness.state: :stale` (all other fields can be anything — the stale check
fires first).

For `:pending` (dev scenario only): `reconciliation.state: :awaiting_verification`,
`freshness.state: :fresh`. Note: this snapshot CANNOT be passed to `project_snapshot/2` — it
is only valid for `derived_state/1` in the dev scenario builder.

### LiveView idiom from existing example host
[VERIFIED: `study_session_live.ex`, `dashboard_live.ex`, `claims_live.ex`]

Key idioms to match:
- `use Phoenix.LiveView` (no options)
- `def mount(_params, _session, socket)` — standard 3-arity
- `def handle_event("event_name", _params, socket)` — returns `{:noreply, socket}`
- `def render(assigns)` — single `render/1`, returns `~H"""..."""`
- `@impl true` annotations present in `dashboard_live.ex` but absent in `study_session_live.ex`
  — either is acceptable; use `@impl true` on mount and render for correctness per OTP convention.
- HEEx uses `{}` interpolation (dashboard_live.ex: `{@current_saas_account.name}`) for Phoenix
  1.8, not `<%= %>`. Use `{}` style for new code. (study_session_live.ex uses `<%= %>` — older
  style; dashboard_live.ex uses `{}` — current style for Phoenix 1.8).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `<%= %>` HEEx interpolation | `{}` HEEx interpolation | Phoenix 1.7+ / LiveView 0.20+ | Use `{}` in new `PaywallEntryLive`; `study_session_live.ex` is older; `dashboard_live.ex` shows current style |
| `Phoenix.PubSub.PG2` adapter name | `Phoenix.PubSub` (PG2 is the default unnamed) | PubSub 2.x | Just `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` — no adapter: key needed |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` child spec is valid in Phoenix 1.8 / phoenix_pubsub 2.2.0 without extra options | Pattern 1 | No risk — verified from pubsub docs in deps; the `{Module, opts}` child spec form is standard OTP |
| A2 | `Task.start/1` is the appropriate async primitive (not `Task.async/1`) for fire-and-forget LiveView → PubSub broadcast | Pattern 4 | If wrong, use `Task.Supervisor` — but `Task.start` is documented for fire-and-forget and is used in existing example host code (`sync_controller.ex`) |
| A3 | `Mix.env() == :dev` module attribute approach correctly prevents dev panel in prod builds | Pitfall 7 | Low risk — standard Elixir compile-time flag pattern; if wrong the panel is just visible in prod which is non-critical for an example host |

---

## Open Questions

1. **`group_id` value for PubSub topic**
   - What we know: D-13 anchors to `"entitlement:" <> group_id`; D-13 notes it derives from
     `ReconciliationKeys.subject_key/2` using `@subscription_entry_id "sub_pro_monthly"`.
   - What's unclear: Should `group_id` be `"sub_pro_monthly"` (the entry_id directly) or the
     full `subject_key` output (which depends on evidence fields)?
   - Recommendation: Use `"sub_pro_monthly"` directly — it is the single product constant,
     and D-13 says "group_id" (not subject_key). The full subject_key is for reconciliation
     identity, not for PubSub routing. Planner should confirm in task description.

2. **`PaywallEntry` struct for the `:denied` state render**
   - What we know: `Contracts.PaywallEntry` has `@enforce_keys [:id, :price_display, :group_id, :features]`.
     UI-SPEC shows `"Pro Monthly" / "$9.99 / month"` as mock display values.
   - What's unclear: Should a `%PaywallEntry{}` struct be constructed and passed to the
     component, or should the component hard-code the display values?
   - Recommendation: Construct the struct in `mount/3` and assign it (`assign(socket, paywall_entry: ...)`).
     This makes `PaywallEntryLive` accurately model how an adopter would use the contract,
     satisfying PWAL-02 ("render a single subscription `PaywallEntry`").

3. **PubSub name: `CrosswakeExample.PubSub` vs `:crosswake_example_pubsub`**
   - What we know: D-12 specifies `name: CrosswakeExample.PubSub` (module atom, Phoenix convention).
   - What's unclear: None — D-12 is explicit.
   - Recommendation: Use `CrosswakeExample.PubSub` exactly.

---

## Environment Availability

This phase is code-only in an Elixir project. No external tools beyond the BEAM and Mix are needed.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Compilation | Verified (v3.4 CI runs fine) | 1.19.x | — |
| phoenix_pubsub 2.2.0 | PubSub broadcast/subscribe | Already in lockfile | 2.2.0 | — |
| ecto_sql (UUID) | `Ecto.UUID.generate()` for correlation_id | Already in deps | ~3.10 | Use `:crypto.strong_rand_bytes(16) |> Base.encode16()` |

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` (standard) |
| Quick run command | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs --exclude requires_example_host` |
| Full suite command | `mix test --exclude requires_example_host --warnings-as-errors` |
| Example host compile check | `cd examples/phoenix_host && mix compile --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WIRE-01 | `ingest_evidence/2` called with mock evidence, returns `{:ok, %{status: :awaiting_verification, ...}}` | hermetic unit | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | ❌ Wave 0 (Phase 36 target, but MockBackend path must be testable) |
| WIRE-02 | `project_snapshot/2` called after MockBackend builds verified snapshot, returns `{:ok, projected}` | hermetic unit | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | ❌ Wave 0 (Phase 36) |
| STATE-01 | All four `derived_state/1` outputs reachable and distinct | hermetic unit | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | ❌ Wave 0 (Phase 36) |
| PWAL-02 | `PaywallEntryLive` renders `:denied` state with `PaywallEntry` content, zero provider-SDK | compile + manual | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ❌ compile check only; LiveView rendering is manual |
| D-12 | PubSub starts in supervision tree | compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ❌ Wave 0 |
| D-09/D-10 | `case @derived_state` exhaustive four-branch dispatch | compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ❌ Wave 0 |

### Hermetic Test Strategy for Phase 35's Deliverable

**What is synchronously/deterministically testable (MockBackend core):**

The `MockBackend.build_verified_snapshot/2` + `project_snapshot/2` + `derived_state/1` chain is
pure Elixir, no process, no PubSub, no LiveView. This is exactly what Phase 36's hermetic proof
will assert. Phase 35 only *enables* Phase 36 by providing the module.

The test idiom (from `phase34_mock_storefront_test.exs`):
```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)

defmodule Crosswake.Proof.Phase34PaywallCorridorProofTest do
  use ExUnit.Case, async: false
  # NO @moduletag :requires_example_host  <-- intentionally untagged
  ...
end
```

**What is LiveView-only (NOT hermetically testable in Phase 36):**
- The `Task` + delay async wrapper (D-04/D-05) — involves process timing
- The `connected?(socket)` PubSub subscribe guard — requires a LiveView socket
- The HEEx rendering of the four states — requires Phoenix rendering pipeline

**How all four states are reachable in the synchronous proof:**
```
:granted  → MockBackend.build_verified_snapshot + project_snapshot(nil, snap) + derived_state
:denied   → same path with authority.state: :none, access.decision: :denied
:stale    → same path with freshness.state: :stale
:pending  → build snapshot with reconciliation.state: :awaiting_verification → derived_state
            (CANNOT use project_snapshot/2 for this — it rejects :awaiting_verification)
            Instead: call derived_state/1 directly on a :awaiting_verification snapshot.
```

**The `:pending` state in the hermetic proof:**
`project_snapshot/2` rejects `:awaiting_verification`. For the Phase 36 proof to assert `:pending`,
it must call `derived_state/1` *directly* on a manually built snapshot (bypassing `project_snapshot/2`).
This is the correct model — it mirrors the real topology: ingest produces `:awaiting_verification`
(which `derived_state/1` maps to `:pending`), and the proof asserts that path directly.

**Merge-blocking lane:** The Phase 36 proof file will be `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`, UNtagged, picked up by `mix test --exclude requires_example_host` in `phase34-proof.yml`.

### Sampling Rate

- **Per task commit:** `cd examples/phoenix_host && mix compile --warnings-as-errors`
- **Per wave merge:** `mix test --exclude requires_example_host --warnings-as-errors`
- **Phase gate:** Full suite green (`mix test --exclude requires_example_host --warnings-as-errors`) before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` — Phase 36 target. Phase 35 does not create this file, but must ensure `MockBackend.build_verified_snapshot/2` is callable without a server so Phase 36 can.
- [ ] No existing test infrastructure gaps for Phase 35 itself — it piggybacks on compile verification and the existing proof lane.

---

## Security Domain

`security_enforcement` is not explicitly set in `.planning/config.json` — treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth on paywall route (AF-05 — auth is adopter responsibility) |
| V3 Session Management | No | Stateless demo; no session mutation |
| V4 Access Control | No | No authorization decisions in this phase |
| V5 Input Validation | No | No user-supplied input into business logic (mock data only; correlation_id is generated internally) |
| V6 Cryptography | No | No cryptographic operations |

No ASVS categories apply to this phase. This is a pure wiring phase with mock data only,
no user input reaching security-sensitive paths, no auth/session/access decisions.

The provider-vocabulary fence (no `storekit`, `play_billing`, etc. tokens in MockBackend source)
is the relevant quality gate — it is tested by the Phase 36 proof per PROOF-03.

---

## Sources

### Primary (HIGH confidence)

All findings verified directly from source files read during this session:

- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — simulate_purchase/2, simulate_restore/2 signatures and return shapes
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — ingest_evidence/2 return map keys, evidence_status logic
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — project_snapshot/2 preconditions, @verified_reconciliation_states, derived_state/1 precedence
- `lib/crosswake/commerce/contracts.ex` — EntitlementSnapshot @enforce_keys, all lane structs
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — snapshot builder helpers (lines 180-230)
- `test/crosswake/proof/phase34_mock_storefront_test.exs` — hermetic proof idiom (Code.require_file, async: false, untagged)
- `examples/phoenix_host/lib/crosswake_example/router.ex` — declared routes, @compile no_warn_undefined
- `examples/phoenix_host/lib/crosswake_example/application.ex` — current supervision tree (Repo only)
- `examples/phoenix_host/mix.lock` — phoenix_pubsub 2.2.0 confirmed
- `examples/phoenix_host/mix.exs` — zero new deps confirmed
- `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` — LiveView idiom
- `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` — Phoenix 1.8 `{}` HEEx style
- `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` — connected?(socket) guard
- `.planning/config.json` — nyquist_validation: true confirmed
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-CONTEXT.md` — all 15 decisions
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-UI-SPEC.md` — component inventory, copy, interaction contract

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all deps verified in mix.lock; no new packages needed
- Architecture: HIGH — signatures, return types, and preconditions verified from actual source
- Pitfalls: HIGH — derived from reading actual guard conditions and field names in source
- Verification gap analysis: HIGH — computed directly from `@verified_reconciliation_states` and `derived_state/1` logic in `entitlement_projection.ex`

**Research date:** 2026-05-29
**Valid until:** 2026-06-28 (stable codebase; no external deps changing)
