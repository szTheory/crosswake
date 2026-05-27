defmodule CrosswakeExample.Commerce.EntitlementProjection do
  @moduledoc """
  Example-host projection of one authoritative entitlement snapshot.

  Ingestion attempts remain evidence-only. Snapshot authority updates happen here
  and require verified reconciliation outcomes plus monotonic `as_of` ordering.
  """

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.Contracts.EntitlementSnapshot

  @pending_reconciliation_states [:pending_purchase, :pending_restore, :awaiting_verification]
  @grantable_authority_states [:active, :grace, :billing_retry, :canceled_scheduled_end]
  @verified_reconciliation_states [:projection_refreshed, :verification_failed, :conflict, :stale_authority]

  @spec project_snapshot(EntitlementSnapshot.t() | nil, EntitlementSnapshot.t()) ::
          {:ok, EntitlementSnapshot.t()}
          | {:error, :unverified_reconciliation_outcome}
          | {:error, {:stale_authority, EntitlementSnapshot.t()}}
  def project_snapshot(nil, %EntitlementSnapshot{} = incoming) do
    with :ok <- ensure_verified_reconciliation(incoming.reconciliation.state) do
      {:ok, incoming}
    end
  end

  def project_snapshot(%EntitlementSnapshot{} = current, %EntitlementSnapshot{} = incoming) do
    with :ok <- ensure_verified_reconciliation(incoming.reconciliation.state),
         :ok <- ensure_monotonic_as_of(current.as_of, incoming.as_of) do
      {:ok, incoming}
    else
      {:error, :stale_authority} ->
        {:error, {:stale_authority, stale_authority_snapshot(current, incoming)}}

      error ->
        error
    end
  end

  @spec derived_state(EntitlementSnapshot.t()) :: :stale | :pending | :denied | :granted
  def derived_state(%EntitlementSnapshot{} = snapshot) do
    cond do
      snapshot.freshness.state in [:stale, :unknown] ->
        :stale

      snapshot.reconciliation.state in @pending_reconciliation_states ->
        :pending

      granted_snapshot?(snapshot) ->
        :granted

      true ->
        :denied
    end
  end

  defp granted_snapshot?(%EntitlementSnapshot{} = snapshot) do
    snapshot.freshness.state == :fresh and
      resolved_reconciliation?(snapshot.reconciliation.state) and
      snapshot.authority.state in @grantable_authority_states and
      snapshot.access.decision == :granted
  end

  defp resolved_reconciliation?(:projection_refreshed), do: true
  defp resolved_reconciliation?(_state), do: false

  defp ensure_verified_reconciliation(state) do
    if state in @verified_reconciliation_states do
      :ok
    else
      {:error, :unverified_reconciliation_outcome}
    end
  end

  defp ensure_monotonic_as_of(current_as_of, incoming_as_of) do
    with {:ok, current_rank} <- as_of_rank(current_as_of),
         {:ok, incoming_rank} <- as_of_rank(incoming_as_of) do
      if incoming_rank < current_rank do
        {:error, :stale_authority}
      else
        :ok
      end
    else
      _error -> {:error, :stale_authority}
    end
  end

  defp as_of_rank(value) when is_integer(value), do: {:ok, value}

  defp as_of_rank(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} ->
        {:ok, int}

      _ ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> {:ok, DateTime.to_unix(datetime, :microsecond)}
          _error -> :error
        end
    end
  end

  defp as_of_rank(_value), do: :error

  defp stale_authority_snapshot(%EntitlementSnapshot{} = current, %EntitlementSnapshot{} = incoming) do
    %EntitlementSnapshot{
      current
      | reconciliation: %EntitlementSnapshot.ReconciliationLane{
          current.reconciliation
          | state: :stale_authority,
            reference: incoming.reconciliation.reference || current.reconciliation.reference
        }
    }
  end
end
