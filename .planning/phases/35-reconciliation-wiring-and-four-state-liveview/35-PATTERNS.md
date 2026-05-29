# Phase 35: Reconciliation Wiring And Four-State LiveView — Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 5 (3 new, 2 modified)
**Analogs found:** 5 / 5

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` | service | request-response (synchronous pure pipeline) | `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` | exact (same namespace, same plain-module shape, same `@moduledoc` teaching structure) |
| `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` | LiveView | event-driven + pub-sub | `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` + `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` + `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` | role-match (same `use Phoenix.LiveView` idiom; claims_live supplies the `connected?(socket)` guard; study_session_live supplies multi-event `handle_event`; dashboard_live supplies Phoenix 1.8 `{}` HEEx style) |
| `examples/phoenix_host/lib/crosswake_example/corridor_controller.ex` | controller | request-response (JSON POST) | `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` | exact (`use Phoenix.Controller, formats: [:json]`, `json(conn, ...)` response, single-responsibility delegation to a context module) |
| `examples/phoenix_host/lib/crosswake_example/application.ex` | config | — | self (existing file, adding one child) | n/a — targeted line edit |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | config | — | self (existing file, removing suppression directives) | n/a — targeted line edit |

---

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` (service, synchronous pure pipeline)

**Analog:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`

**Module header + @moduledoc pattern** (mock_storefront.ex lines 1-47):
```elixir
defmodule CrosswakeExample.Commerce.MockBackend do
  @moduledoc """
  Pure-Elixir, provider-neutral mock verification pipeline for the example host.

  Bridges the verification gap: `ReconciliationInbox.ingest_evidence/2` always
  returns `status: :awaiting_verification`, but `EntitlementProjection.project_snapshot/2`
  requires a verified `reconciliation.state`. This module manufactures the verified
  `%EntitlementSnapshot{}` for each terminal outcome and broadcasts the derived state
  via PubSub.

  ## Same code path for example and proof

  `PaywallEntryLive` delegates here (via a fire-and-forget Task); the Phase 36 hermetic
  proof calls `build_verified_snapshot/2` and `verify_and_broadcast/2` directly without
  a running server (D-02).

  ## No provider-SDK code

  `provider: "mock"` is the only value ever produced. See `AF-01` / `AF-07` in the
  phase constraints.
  """

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.EntitlementProjection
```

**Snapshot builder helpers — mirror of `test/crosswake/proof/phase21_reconciliation_example_test.exs` lines 180-229:**
```elixir
# snapshot/1 base (phase21 test lines 180-200):
defp snapshot(overrides \\ %{}) do
  base = %{
    group_id: "group_123",
    authority: authority_lane(:none),
    access: access_lane(:denied),
    reconciliation: reconciliation_lane(:projection_refreshed),
    freshness: freshness_lane(:fresh),
    effective: %Contracts.EntitlementSnapshot.EffectiveLane{
      effective_from: "2026-05-01T00:00:00Z",
      effective_until: nil
    },
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :webhook,
      reference: "evidence_123",
      observed_at: "2026-05-27T10:00:00Z"
    },
    as_of: 100
  }
  struct!(Contracts.EntitlementSnapshot, Map.merge(base, overrides))
end

# Lane helpers (phase21 test lines 202-229):
defp authority_lane(state), do: %Contracts.EntitlementSnapshot.AuthorityLane{state: state, reason: nil}
defp access_lane(decision),  do: %Contracts.EntitlementSnapshot.AccessLane{decision: decision, reason: nil}
defp reconciliation_lane(state, reference \\ "attempt_123"),
     do: %Contracts.EntitlementSnapshot.ReconciliationLane{state: state, reference: reference}
defp freshness_lane(state),
     do: %Contracts.EntitlementSnapshot.FreshnessLane{state: state, checked_at: "...", stale_after: nil}
```

**`MockBackend` applies the same pattern for its `build_verified_snapshot/2`.** Use `struct!` (not `new_entitlement_snapshot/1`) exactly as phase21 test helpers do.

**Concrete field values per target derived state** (from RESEARCH.md verification-gap section):

| `derived_state` target | `reconciliation.state` | `freshness.state` | `authority.state` | `access.decision` |
|------------------------|------------------------|-------------------|-------------------|-------------------|
| `:granted` | `:projection_refreshed` | `:fresh` | `:active` | `:granted` |
| `:denied` | `:projection_refreshed` | `:fresh` | `:none` | `:denied` |
| `:stale` | `:projection_refreshed` | `:stale` | `:none` | `:denied` |
| `:pending` (dev scenario only) | `:awaiting_verification` | `:fresh` | `:none` | `:denied` |

**`as_of`:** Use `System.system_time(:microsecond)` — monotonically increasing integer, avoids stale_authority error on repeated clicks.

**Core public functions:**
```elixir
# Called by PaywallEntryLive via Task (async) and potentially by Phase 36 proof.
@spec verify_and_broadcast(Contracts.ReconciliationEvidence.t(), String.t()) :: :ok
def verify_and_broadcast(evidence, group_id) do
  snapshot = build_verified_snapshot(evidence, group_id)
  {:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
  state = EntitlementProjection.derived_state(projected)
  Phoenix.PubSub.broadcast(
    CrosswakeExample.PubSub,
    "entitlement:" <> group_id,
    {:entitlement_update, state}
  )
  :ok
end

# Synchronous core — callable without a server. Phase 36 calls this directly.
@spec build_verified_snapshot(Contracts.ReconciliationEvidence.t(), String.t()) ::
        Contracts.EntitlementSnapshot.t()
def build_verified_snapshot(_evidence, group_id) do
  # Build struct! for the :granted terminal state (mock always succeeds for purchase/restore)
end
```

**Module constant anchor** (mirrors mock_storefront.ex line 50):
```elixir
@subscription_entry_id "sub_pro_monthly"
```

**Provider-vocabulary fence** (mirrors phase21 test lines 141-163): The Phase 36 proof will assert no forbidden tokens (`"storekit"`, `"play_billing"`, `"revenuecat"`) appear in `mock_backend.ex`. Never write provider names inline.

---

### `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` (LiveView, event-driven + pub-sub)

**Primary analog:** `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` (lines 1-31) for `connected?(socket)` guard; `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` (lines 1-78) for multi-handler `handle_event` structure; `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` (lines 1-54) for Phoenix 1.8 `{}` HEEx interpolation style.

**Module header + use pattern:**
```elixir
# claims_live.ex line 1 / study_session_live.ex line 1 / dashboard_live.ex line 1:
defmodule CrosswakeExample.PaywallEntryLive do
  use Phoenix.LiveView
  # dashboard_live.ex uses @impl true on mount/render — use this style for OTP correctness
```

**Import aliases** (following mock_storefront.ex conventions):
```elixir
alias Crosswake.Commerce.Contracts
alias CrosswakeExample.Commerce.{MockStorefront, ReconciliationInbox, MockBackend}
```

**`connected?(socket)` guard in mount** (claims_live.ex lines 6-11):
```elixir
@impl true
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> @group_id)
  end
  {:ok, assign(socket,
    derived_state: :stale,
    paywall_entry: paywall_entry()
  )}
end
```

**Multi-event handle_event pattern** (study_session_live.ex lines 12-47):
```elixir
def handle_event("subscribe", _params, socket) do
  # ... build intent, simulate, ingest, broadcast :pending, Task.start verify
  {:noreply, socket}
end

def handle_event("restore", _params, socket) do
  # ... same shape with RestoreIntent + simulate_restore
  {:noreply, socket}
end
```

**handle_info for PubSub** (new pattern — no existing analog; add alongside handle_event):
```elixir
def handle_info({:entitlement_update, derived_state}, socket) do
  {:noreply, assign(socket, derived_state: derived_state)}
end
```

**Async Task.start for fire-and-forget** (RESEARCH.md Pattern 4; `Task.start` is used by sync_controller.ex per RESEARCH.md assumption A2):
```elixir
Task.start(fn ->
  :timer.sleep(1_500)
  MockBackend.verify_and_broadcast(evidence, @group_id)
end)
```

**Four-state case dispatch in render** (dashboard_live.ex lines 18-53 for `{}` HEEx; D-09 for case structure):
```elixir
@impl true
def render(assigns) do
  ~H"""
  <div class="paywall-corridor">
    <%= case @derived_state do %>
      <% :granted -> %> <.granted />
      <% :pending -> %> <.pending />
      <% :denied  -> %> <.denied paywall_entry={@paywall_entry} />
      <% :stale   -> %> <.stale />
    <% end %>
    <%= if @dev_mode do %>
      <.dev_scenarios />
    <% end %>
  </div>
  """
end
```

**HEEx interpolation style** — use `{}` for attribute and text bindings (dashboard_live.ex lines 25-49):
```elixir
# Current Phoenix 1.8 style (dashboard_live.ex):
<strong>{@current_saas_account.name}</strong>
<p>Account health: {@current_saas_account.health}</p>

# Legacy style (study_session_live.ex) — do NOT use for new code:
<h2>Card #<%= @current_card_id %></h2>
```

**BEM-style class names** (study_session_live.ex line 51, claims_live.ex line 15):
```elixir
# Existing pattern:
<div class="study-session">
<div class="claims-list">

# UI-SPEC CSS classes for PaywallEntryLive:
<div class="paywall-corridor">
<div class="paywall-state paywall-state--granted">
<div class="paywall-state paywall-state--pending">
<div class="paywall-state paywall-state--denied">
<div class="paywall-state paywall-state--stale">
<div class="dev-scenarios">
```

**Private function component definition pattern** (new for this file — no existing component-in-LiveView analog in the example host; use standard Phoenix function component form):
```elixir
defp granted(assigns) do
  ~H"""
  <div class="paywall-state paywall-state--granted">
    <h2>Access granted</h2>
    <p>Your subscription is active. You have full access.</p>
    <a href="#">Manage subscription</a>
  </div>
  """
end
```

**Dev mode compile-time guard** (RESEARCH.md Pitfall 7):
```elixir
# Module attribute — evaluated at compile time, not runtime:
@dev_mode Mix.env() == :dev
```

**`phx-click` button pattern** (study_session_live.ex lines 60-62):
```elixir
<button phx-click="subscribe" class="button primary">Subscribe</button>
<button phx-click="restore" class="button">Already subscribed? Restore purchase</button>
```

**Error handling pattern** — put_flash for ingest failure (study_session_live.ex lines 41-45 — error branch style):
```elixir
case ReconciliationInbox.ingest_evidence(evidence) do
  {:ok, _attempt} ->
    # ... broadcast :pending, start Task
    {:noreply, socket}
  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Something went wrong submitting your purchase. Please try again.")}
end
```

---

### `examples/phoenix_host/lib/crosswake_example/corridor_controller.ex` (controller, request-response JSON POST)

**Analog:** `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` (lines 1-21) — exact role match: `use Phoenix.Controller, formats: [:json]`, delegates to a context module, returns `json(conn, ...)`.

**Module header + use pattern** (sync_controller.ex lines 1-4):
```elixir
defmodule CrosswakeExample.CorridorController do
  use Phoenix.Controller, formats: [:json]
  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.{MockStorefront, ReconciliationInbox, MockBackend}
```

**Action body pattern** (sync_controller.ex lines 5-14 — delegate to context, return json):
```elixir
# sync_controller.ex exact pattern:
def sync(conn, %{"events" => events}) when is_list(events) do
  case Study.sync_events(events) do
    {:ok, result} ->
      json(conn, %{data: result})
    {:error, reason} ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: to_string(reason)})
  end
end

# CorridorController adapts to thin seam (D-07):
def purchase(conn, _params) do
  group_id = @group_id
  intent = %Contracts.PurchaseIntent{
    entry_id: @group_id,
    correlation_id: Ecto.UUID.generate()
  }
  evidence = MockStorefront.simulate_purchase(intent)
  {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
  Task.start(fn -> MockBackend.verify_and_broadcast(evidence, group_id) end)
  json(conn, %{status: attempt.status})
end
```

**`RestoreIntent` has no `entry_id`** (RESEARCH.md Pitfall 5 — mock_storefront.ex line 67):
```elixir
def restore(conn, _params) do
  intent = %Contracts.RestoreIntent{correlation_id: Ecto.UUID.generate()}
  # NOT: %Contracts.RestoreIntent{entry_id: ..., correlation_id: ...}  ← compile error
  evidence = MockStorefront.simulate_restore(intent)
  ...
end
```

---

### `examples/phoenix_host/lib/crosswake_example/application.ex` (config — supervision tree, targeted edit)

**Analog:** self (existing file lines 1-14)

**Current state** (application.ex lines 1-14):
```elixir
defmodule CrosswakeExample.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CrosswakeExample.Repo
    ]

    opts = [strategy: :one_for_one, name: CrosswakeExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Required change** (RESEARCH.md Pattern 1 / D-12 — add PubSub BEFORE Repo):
```elixir
children = [
  {Phoenix.PubSub, name: CrosswakeExample.PubSub},
  CrosswakeExample.Repo
]
```

**Only edit:** replace the `children = [CrosswakeExample.Repo]` list. No other lines change. PubSub must be first so it is available when Repo and LiveView processes start subscribing.

---

### `examples/phoenix_host/lib/crosswake_example/router.ex` (config — suppress-directive removal, targeted edit)

**Analog:** self (existing file lines 29-30)

**Current state to remove** (router.ex lines 29-30):
```elixir
@compile {:no_warn_undefined, CrosswakeExample.PaywallEntryLive}
@compile {:no_warn_undefined, CrosswakeExample.CorridorController}
```

**Required change:** delete lines 29-30 once both modules exist. The three `/commerce` routes themselves (lines 221-246) are already correct and require no changes.

---

## Shared Patterns

### `use Phoenix.LiveView` with `@impl true`
**Source:** `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex` lines 1-2, 7, 18
**Apply to:** `paywall_entry_live.ex`
```elixir
use Phoenix.LiveView

@impl true
def mount(_params, _session, socket) do ... end

@impl true
def render(assigns) do ... end
```
`@impl true` is present in `dashboard_live.ex` (current style) and absent in `study_session_live.ex` and `claims_live.ex` (older style). Use `@impl true` on `mount`, `render`, and `handle_event` / `handle_info` for new code.

### `connected?(socket)` PubSub subscription guard
**Source:** `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` lines 7-9
**Apply to:** `paywall_entry_live.ex` mount
```elixir
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> group_id)
  end
  ...
end
```
Without this guard: duplicate subscriptions (static render + live connection both subscribe).

### `Ecto.UUID.generate()` for correlation IDs
**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex` line 15
**Apply to:** `paywall_entry_live.ex` handle_event, `corridor_controller.ex` purchase/restore
```elixir
client_mutation_id: Ecto.UUID.generate()
# In phase 35 context:
correlation_id: Ecto.UUID.generate()
```

### `struct!` for snapshot construction (not `new_entitlement_snapshot/1`)
**Source:** `test/crosswake/proof/phase21_reconciliation_example_test.exs` lines 181-200
**Apply to:** `mock_backend.ex` `build_verified_snapshot/2` and any dev-scenario snapshot builders in `paywall_entry_live.ex`
```elixir
struct!(Contracts.EntitlementSnapshot, Map.merge(base, overrides))
```
The phase21 test helpers use `struct!` throughout — consistent with the decision in RESEARCH.md "Don't Hand-Roll" table.

### `use Phoenix.Controller, formats: [:json]` with `json(conn, ...)` response
**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` lines 1-2, 7-8
**Apply to:** `corridor_controller.ex`
```elixir
use Phoenix.Controller, formats: [:json]
...
json(conn, %{status: attempt.status})
```

### `Code.require_file` hermetic proof idiom
**Source:** `test/crosswake/proof/phase34_mock_storefront_test.exs` lines 1-3
**Apply to:** Phase 36 proof test (not created in this phase, but `mock_backend.ex` must be reachable this way)
```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
```
`mock_backend.ex` must be a plain module with no PubSub or LiveView startup dependency in its public synchronous functions to satisfy this requirement (D-02).

### Provider-vocabulary fence (source fence pattern)
**Source:** `test/crosswake/proof/phase21_reconciliation_example_test.exs` lines 141-163 and `test/crosswake/proof/phase34_mock_storefront_test.exs` lines 34-40
**Apply to:** `mock_backend.ex` (and by convention `paywall_entry_live.ex`, `corridor_controller.ex`)

Forbidden tokens (split to avoid triggering the fence in this file itself):
- `"store" <> "kit"`
- `"play" <> "_billing"`
- `"revenue" <> "cat"`

Never write these tokens inline in any new commerce module source.

---

## No Analog Found

All five files have analogs. No entries.

---

## Metadata

**Analog search scope:**
- `examples/phoenix_host/lib/crosswake_example/` (all subdirectories)
- `examples/phoenix_host/lib/crosswake_example/commerce/` (all modules)
- `test/crosswake/proof/` (phase21 + phase34 hermetic tests)

**Files read for analog extraction:**
1. `examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex`
2. `examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex`
3. `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex`
4. `examples/phoenix_host/lib/crosswake_example/application.ex`
5. `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`
6. `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
7. `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
8. `examples/phoenix_host/lib/crosswake_example/router.ex`
9. `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex`
10. `test/crosswake/proof/phase21_reconciliation_example_test.exs` (lines 85-230)
11. `test/crosswake/proof/phase34_mock_storefront_test.exs` (lines 1-40)

**Pattern extraction date:** 2026-05-29
