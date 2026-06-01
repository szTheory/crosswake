defmodule CrosswakeExample.Commerce.MockStorefront do
  @moduledoc """
  Pure-Elixir, provider-neutral mock storefront evidence emitter for the
  example host.

  This module manufactures `ReconciliationEvidence` structs that feed the
  existing `ReconciliationInbox` / `ReconciliationKeys` / `EntitlementProjection`
  machinery (all provider-neutral and unchanged by swapping this module out).

  ## The two swap-target functions

  A real provider adapter (for example, one wrapping a native payment SDK)
  would replace exactly two functions:

  - `simulate_purchase/2` — call after a payment SDK confirms a new transaction.
    Replace with a function that reads the vendor transaction record and returns
    an equivalent `ReconciliationEvidence` struct.
  - `simulate_restore/2` — call after a payment SDK delivers a restore receipt.
    Replace with a function that reads the vendor restore record and returns an
    equivalent `ReconciliationEvidence` struct.

  Everything downstream (`ReconciliationInbox.ingest_evidence/2`,
  `ReconciliationKeys.event_key/1`, `EntitlementProjection.project_snapshot/2`)
  is provider-neutral and requires no changes when you swap this module for a
  real adapter.

  ## Identity derivation

  Provider references and evidence refs derive from stable product identifiers
  (`entry_id` / `@subscription_entry_id`), never from transient device
  correlation IDs. This ensures that network retries carrying the same
  storefront transaction produce identical evidence keys and are correctly
  deduplicated as replays by `ReconciliationInbox`.

  ## Module constants

  `@subscription_entry_id` is the single canonical subscription product
  identifier for the example host (one product per AF-04). All restore
  evidence is anchored on this constant so that restore shares the same
  `subject_key` as a purchase of the same product.

  ## No provider-SDK code

  This module contains no provider-SDK code. `provider: "mock"` is the only
  value ever emitted. See `AF-01` / `AF-07` in the phase constraints.
  """

  alias Crosswake.Commerce.Contracts

  @behaviour CrosswakeExample.Commerce.StorefrontAdapter

  @subscription_entry_id "sub_pro_monthly"

  @impl true
  @spec simulate_purchase(Contracts.PurchaseIntent.t()) ::
          {:ok, Contracts.ReconciliationEvidence.t()}
  def simulate_purchase(%Contracts.PurchaseIntent{} = intent), do: {:ok, simulate_purchase(intent, [])}

  @spec simulate_purchase(Contracts.PurchaseIntent.t(), keyword()) ::
          Contracts.ReconciliationEvidence.t()
  def simulate_purchase(%Contracts.PurchaseIntent{} = intent, opts) do
    %Contracts.ReconciliationEvidence{
      source: :storefront,
      provider: "mock",
      event_kind: "purchase",
      provider_reference: provider_reference(intent.entry_id),
      evidence_ref: evidence_ref(intent.entry_id, "purchase"),
      captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601())
    }
  end

  @impl true
  @spec simulate_restore(Contracts.RestoreIntent.t()) ::
          {:ok, Contracts.ReconciliationEvidence.t()}
  def simulate_restore(%Contracts.RestoreIntent{} = intent), do: {:ok, simulate_restore(intent, [])}

  @spec simulate_restore(Contracts.RestoreIntent.t(), keyword()) ::
          Contracts.ReconciliationEvidence.t()
  def simulate_restore(%Contracts.RestoreIntent{} = _intent, opts) do
    %Contracts.ReconciliationEvidence{
      source: :storefront,
      provider: "mock",
      event_kind: "restore",
      provider_reference: provider_reference(@subscription_entry_id),
      evidence_ref: evidence_ref(@subscription_entry_id, "restore"),
      captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601())
    }
  end

  defp provider_reference(entry_id), do: "mock_txn_" <> entry_id

  defp evidence_ref(entry_id, event_kind), do: "mock_evt_" <> entry_id <> "_" <> event_kind
end
