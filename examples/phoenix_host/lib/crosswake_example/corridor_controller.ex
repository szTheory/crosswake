defmodule CrosswakeExample.CorridorController do
  @moduledoc """
  Thin JSON POST seam for the mock paywall corridor (D-07).

  Implements the `purchase` and `restore` actions declared in the Phase 33 router:

      post "/purchase", CorridorController, :purchase
      post "/restore",  CorridorController, :restore

  These routes represent the backend seam that a native screen or companion app POSTs
  mock storefront evidence to. Both actions delegate to the same
  `MockStorefront → ReconciliationInbox → MockBackend` path that `PaywallEntryLive`
  uses, so the declared POST routes are live and read honestly as production-shaped
  thin seams.

  ## Request body

  Both actions ignore the request body entirely and construct all intents from internal
  constants and a freshly generated `correlation_id`. No client-supplied data reaches
  business logic (T-35-03 — accept disposition; auth gating is adopter responsibility, AF-05).

  ## No provider-SDK code

  `provider: "mock"` is the only value ever produced (via `MockStorefront`). No provider-SDK
  code may appear here — see `AF-01` / `AF-07` in the phase constraints.
  """

  use Phoenix.Controller, formats: [:json]

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.{MockStorefront, ReconciliationInbox, MockBackend}

  @subscription_entry_id "sub_pro_monthly"

  @doc """
  Simulates a native-screen purchase POST (WIRE-01, D-07).

  Builds a `PurchaseIntent`, calls `MockStorefront.simulate_purchase/2` to emit
  `ReconciliationEvidence`, ingests it via `ReconciliationInbox.ingest_evidence/2`
  (returning `status: :awaiting_verification`), then spawns `MockBackend.verify_and_broadcast/2`
  asynchronously. Responds with `%{status: evidence_status}` so the seam surface is honest.
  """
  def purchase(conn, _params) do
    group_id = @subscription_entry_id

    intent = %Contracts.PurchaseIntent{
      entry_id: @subscription_entry_id,
      correlation_id: Ecto.UUID.generate()
    }

    evidence = MockStorefront.simulate_purchase(intent)
    {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    Task.start(fn -> MockBackend.verify_and_broadcast(evidence, group_id) end)
    json(conn, %{status: attempt.status})
  end

  @doc """
  Simulates a native-screen restore POST (WIRE-01, D-07).

  Builds a `RestoreIntent` (no `entry_id` — `RestoreIntent` enforces only `:correlation_id`,
  Pitfall 5), calls `MockStorefront.simulate_restore/2`, ingests the evidence, spawns
  async verification, and responds with `%{status: evidence_status}`.
  """
  def restore(conn, _params) do
    group_id = @subscription_entry_id

    intent = %Contracts.RestoreIntent{
      correlation_id: Ecto.UUID.generate()
    }

    evidence = MockStorefront.simulate_restore(intent)
    {:ok, attempt} = ReconciliationInbox.ingest_evidence(evidence)
    Task.start(fn -> MockBackend.verify_and_broadcast(evidence, group_id) end)
    json(conn, %{status: attempt.status})
  end
end
