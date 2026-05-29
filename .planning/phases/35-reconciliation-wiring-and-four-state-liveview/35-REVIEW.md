---
phase: 35-reconciliation-wiring-and-four-state-liveview
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example/application.ex
  - examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex
  - examples/phoenix_host/lib/crosswake_example/corridor_controller.ex
  - examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex
  - examples/phoenix_host/lib/crosswake_example/router.ex
findings:
  critical: 2
  warning: 5
  info: 3
  total: 10
status: issues_found
---

# Phase 35: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

This phase wires the four-state LiveView paywall corridor (`PaywallEntryLive`) to the mock commerce
pipeline (`MockStorefront` → `ReconciliationInbox` → `MockBackend`) and exposes `CorridorController`
for native-screen POST seams. The reconciliation data model and state derivation logic are sound.
The PubSub-driven state propagation pattern is architecturally correct.

Two blockers exist: an unguarded bare pattern match in the Task path silently swallows failures
(stuck `:pending` UI state), and the POST routes for native-screen commerce intents are wired
to a pipeline that refuses JSON — making them dead on arrival for any non-browser client.
Five warnings cover the application missing an HTTP server, misleading initial UI state,
cross-user PubSub broadcast leakage, a silently-ignored PubSub error return, and an unguarded
crash path in the controller. Three info items cover minor quality issues.

---

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Bare match in fire-and-forget Task silently swallows failure — LiveView stuck in `:pending`

**File:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex:56`

**Issue:** `verify_and_broadcast/2` runs inside a `Task.start/1` fire-and-forget. Line 56 is a
bare pattern match:

```elixir
{:ok, projected} = EntitlementProjection.project_snapshot(nil, snapshot)
```

`project_snapshot/2` can return `{:error, :unverified_reconciliation_outcome}` or
`{:error, {:stale_authority, _}}`. If either error tuple is returned, the bare match raises
`MatchError` inside the Task. The Task process crashes silently (no monitor, no supervisor),
`Phoenix.PubSub.broadcast/3` is never called, and every connected LiveView remains in the
`:pending` state indefinitely with no error surface to the user or operator.

In practice `build_verified_snapshot/2` always constructs a `:projection_refreshed` snapshot,
so the current mock cannot trigger this path. But the guard disappears the moment anyone modifies
`build_verified_snapshot/2` or calls `verify_and_broadcast/2` with a different snapshot producer
(e.g., the Phase 36 proof that calls both functions directly).

**Fix:** Replace the bare match with explicit error handling:

```elixir
def verify_and_broadcast(evidence, group_id) do
  snapshot = build_verified_snapshot(evidence, group_id)

  case EntitlementProjection.project_snapshot(nil, snapshot) do
    {:ok, projected} ->
      state = EntitlementProjection.derived_state(projected)

      Phoenix.PubSub.broadcast(
        CrosswakeExample.PubSub,
        "entitlement:" <> group_id,
        {:entitlement_update, state}
      )

    {:error, reason} ->
      # Broadcast :stale so the UI does not hang in :pending
      Phoenix.PubSub.broadcast(
        CrosswakeExample.PubSub,
        "entitlement:" <> group_id,
        {:entitlement_update, :stale}
      )

      require Logger
      Logger.error("[MockBackend] project_snapshot failed: #{inspect(reason)}")
  end

  :ok
end
```

---

### CR-02: Commerce POST routes wired to `:browser` pipeline — JSON requests refused with 406

**File:** `examples/phoenix_host/lib/crosswake_example/router.ex:220`

**Issue:** The `/commerce` scope uses `pipe_through [:browser]`. The browser pipeline contains
`plug :accepts, ["html"]` (line 34). `CorridorController` declares `use Phoenix.Controller, formats: [:json]` and responds exclusively with `json/2`. Any native-screen client that POSTs to
`/commerce/purchase` or `/commerce/restore` with `Accept: application/json` (or without an
explicit HTML accept header) will receive HTTP 406 Not Acceptable from the `:accepts` plug — the
controller body is never reached. This makes both routes dead on arrival for their stated purpose
(D-07: "native-screen purchase POST / restore POST").

**Fix:** Add an `:api` sub-scope for the two POST routes, or add a dedicated `:commerce_api`
pipeline:

```elixir
# In the pipeline section:
pipeline :commerce_api do
  plug :accepts, ["json"]
end

# In the scope:
scope "/commerce", CrosswakeExample do
  pipe_through [:browser]

  crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
    live "/paywall", PaywallEntryLive, :index,
      crosswake: [id: "commerce-paywall-entry", runtime: :live_view,
                  commerce: [corridor: :subscription_default, role: :paywall_entry]]
  end
end

scope "/commerce", CrosswakeExample do
  pipe_through [:commerce_api]

  post "/purchase", CorridorController, :purchase,
    crosswake: [id: "commerce-purchase-intent", runtime: :native_screen,
                commerce: [corridor: :subscription_default, role: :purchase_intent]]

  post "/restore", CorridorController, :restore,
    crosswake: [id: "commerce-restore-intent", runtime: :native_screen,
                commerce: [corridor: :subscription_default, role: :restore_intent]]
end
```

---

## Warnings

### WR-01: `CorridorController` bare-matches `ingest_evidence` — unhandled error returns 500

**File:** `examples/phoenix_host/lib/crosswake_example/corridor_controller.ex:52` and `:72`

**Issue:** Both `purchase/2` and `restore/2` bare-match the result:

```elixir
{:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
```

`ReconciliationInbox.ingest_evidence/2` returns `{:error, keyword()}` when
`normalize_source/1` fails (e.g., if evidence carries an unrecognised source atom). A bare match
that crashes the controller process produces a 500 HTML error page instead of a structured JSON
error response, and breaks the JSON contract the controller advertises.

**Fix:**

```elixir
case ReconciliationInbox.ingest_evidence(evidence) do
  {:ok, attempt} ->
    json(conn, %{status: attempt.status})

  {:error, reason} ->
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "ingestion_failed", detail: inspect(reason)})
end
```

---

### WR-02: No `Endpoint` in `Application` supervisor — HTTP server never starts

**File:** `examples/phoenix_host/lib/crosswake_example/application.ex:7-10`

**Issue:** The supervisor children are only `Phoenix.PubSub` and `CrosswakeExample.Repo`. No
`CrosswakeExample.Endpoint` (or equivalent) is listed. As written, starting this application
does not bind any HTTP port — the router, LiveView, and controller code are all unreachable via
HTTP. If this application is intended to be runnable (to demonstrate the paywall corridor
interactively), the endpoint must be added to the tree.

If the application is only ever used as a manifest-generation host (via `gen_manifest.exs`) and is
never started as an HTTP server, this is acceptable but should be documented to prevent confusion.

**Fix (if HTTP serving is intended):**

```elixir
children = [
  CrosswakeExample.Endpoint,         # <-- add this
  {Phoenix.PubSub, name: CrosswakeExample.PubSub},
  CrosswakeExample.Repo
]
```

---

### WR-03: All connected users share a single PubSub topic — cross-user state contamination

**File:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex:13` and `corridor_controller.ex:53,73`

**Issue:** Every `PaywallEntryLive` process subscribes to `"entitlement:sub_pro_monthly"` — a
single global topic. `CorridorController.purchase/2` and `restore/2` call
`MockBackend.verify_and_broadcast/2` with `group_id = @subscription_entry_id`, which broadcasts
to the same global topic. A purchase or restore by any one user causes every connected LiveView
(all sessions, all users) to transition to `:granted`. The dev-force events in `PaywallEntryLive`
also broadcast globally.

In a real deployment this means User B's session instantly reflects User A's payment outcome —
an incorrect entitlement grant across sessions.

**Fix:** Derive the PubSub topic from a per-user or per-session identifier (e.g., from session,
assigns, or a token parameter) rather than from the product constant:

```elixir
# In mount/3:
user_id = get_session(session, :user_id)
Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:#{user_id}:#{@group_id}")
```

Pass the same scoped topic key through to `verify_and_broadcast/2`.

---

### WR-04: `verify_and_broadcast/2` ignores `PubSub.broadcast/3` error return

**File:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex:59-63`

**Issue:** `Phoenix.PubSub.broadcast/3` returns `:ok | {:error, term()}`. The return value is
silently discarded. If broadcast fails (e.g., PubSub process not started, topic dispatch error),
`verify_and_broadcast/2` still returns `:ok`, and the LiveView is never updated. There is no
log, no error surface, and the user's UI stays in whatever state it was in before.

**Fix:**

```elixir
case Phoenix.PubSub.broadcast(
       CrosswakeExample.PubSub,
       "entitlement:" <> group_id,
       {:entitlement_update, state}
     ) do
  :ok ->
    :ok

  {:error, reason} ->
    require Logger
    Logger.error("[MockBackend] PubSub.broadcast failed: #{inspect(reason)}")
    :ok
end
```

---

### WR-05: Initial `derived_state: :stale` in `mount/3` is semantically incorrect

**File:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex:18`

**Issue:** On first mount (before any purchase or restore has occurred), the socket is assigned
`derived_state: :stale`. The `:stale` UI renders "Access unavailable — We can't verify your
access right now. Access is closed until verification succeeds." This copy implies a
*verification failure* to a first-time visitor who has never attempted to purchase, which is
confusing and potentially alarming. The semantically correct initial state is `:denied` ("Subscribe
to continue"), since no entitlement exists yet.

`:stale` is reserved by `EntitlementProjection.derived_state/1` for snapshots where
`freshness.state in [:stale, :unknown]` — a check-freshness failure, not a "no subscription" case.
Using it as the initial UI state conflates two distinct concepts.

**Fix:**

```elixir
assign(socket,
  derived_state: :denied,    # <-- was :stale
  paywall_entry: paywall_entry(),
  dev_mode: @dev_mode
)
```

---

## Info

### IN-01: `build_verified_snapshot/2` silently discards its `evidence` argument

**File:** `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex:86`

**Issue:** The function signature accepts `_evidence` (underscore-prefixed, intentionally unused).
The generated `EvidenceLane.reference` field is hardcoded as
`"mock_evt_" <> @subscription_entry_id <> "_purchase"` regardless of whether the incoming evidence
represents a purchase or a restore. A restore will produce an evidence lane that claims to be a
purchase event. This makes proof assertions (`PROOF-03`) and log correlation misleading.

**Fix:** Thread the `evidence_ref` from the incoming evidence struct:

```elixir
def build_verified_snapshot(evidence, group_id) do
  now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

  struct!(Contracts.EntitlementSnapshot, %{
    ...
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :storefront,
      reference: evidence.evidence_ref,   # use actual ref, not hardcoded string
      observed_at: now_iso
    },
    ...
  })
end
```

---

### IN-02: `handle_info/2` has no catchall clause — unhandled messages log noisily

**File:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex:258`

**Issue:** Only one `handle_info` clause is defined. Any stray message delivered to this LiveView
process (system messages, PubSub broadcasts from other topics if the topic were ever broadened,
monitoring signals) produces a `no function clause matching` warning in the LiveView internals
or a `FunctionClauseError` crash depending on Phoenix version. For a module intended as an
example, a catchall prevents confusion.

**Fix:**

```elixir
@impl true
def handle_info({:entitlement_update, derived_state}, socket) do
  {:noreply, assign(socket, derived_state: derived_state)}
end

def handle_info(_msg, socket) do
  {:noreply, socket}
end
```

---

### IN-03: Five near-identical dev-force event handlers contain duplicated snapshot construction

**File:** `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex:92-255`

**Issue:** `handle_event/3` clauses for `dev_force_granted`, `dev_force_pending`,
`dev_force_denied`, and `dev_force_stale` each independently construct a full
`%Contracts.EntitlementSnapshot{}` struct (30+ lines per handler) differing only in a handful of
field values. Any change to the struct shape (e.g., a new required lane) must be replicated in
four places. This is a maintenance hazard in an example that is also the teaching artifact for
adopters.

**Fix:** Extract a shared dev-snapshot builder:

```elixir
defp dev_snapshot(opts) do
  now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

  struct!(Contracts.EntitlementSnapshot, %{
    group_id: @group_id,
    authority: %Contracts.EntitlementSnapshot.AuthorityLane{
      state: Keyword.get(opts, :authority_state, :none),
      reason: nil
    },
    access: %Contracts.EntitlementSnapshot.AccessLane{
      decision: Keyword.get(opts, :access_decision, :denied),
      reason: nil
    },
    reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
      state: Keyword.get(opts, :reconciliation_state, :projection_refreshed),
      reference: Keyword.fetch!(opts, :reference)
    },
    freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
      state: Keyword.get(opts, :freshness_state, :fresh),
      checked_at: now_iso,
      stale_after: nil
    },
    effective: %Contracts.EntitlementSnapshot.EffectiveLane{
      effective_from: now_iso,
      effective_until: nil
    },
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :storefront,
      reference: Keyword.fetch!(opts, :evidence_ref),
      observed_at: now_iso
    },
    as_of: System.system_time(:microsecond)
  })
end
```

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
