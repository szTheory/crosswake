defmodule Crosswake.Commerce do
  @moduledoc """
  Thin behaviour/orchestration seam for Phoenix-owned commerce intent and snapshot hooks.
  """

  alias Crosswake.Commerce.Contracts

  @doc """
  Submit a purchase intent initiated by the Phoenix user.
  """
  @callback submit_purchase_intent(Contracts.PurchaseIntent.t()) :: :ok | {:error, term()}

  @doc """
  Submit a restore intent initiated by the Phoenix user.
  """
  @callback submit_restore_intent(Contracts.RestoreIntent.t()) :: :ok | {:error, term()}

  @doc """
  Ingest evidence from device callbacks or webhooks.
  """
  @callback ingest_reconciliation_evidence(Contracts.ReconciliationEvidence.t()) :: :ok | {:error, term()}

  @doc """
  Fetch the current entitlement snapshot for a given group.
  """
  @callback fetch_entitlement_snapshot(String.t()) :: {:ok, Contracts.EntitlementSnapshot.t()} | {:error, term()}
end
