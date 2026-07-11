defmodule CrosswakeExample.LearnLoop.Entitlement do
  @moduledoc """
  LearnLoop entitlement projection wrapper for the subscription learning lane.

  The visible state is derived from the existing commerce projection helper.
  Storefront evidence stays diagnostic evidence only; access authority remains
  backend projection.
  """

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.Contracts.EntitlementSnapshot
  alias CrosswakeExample.Commerce.EntitlementProjection

  @learner_id "learner-iris"
  @group_id "learnloop_pro"
  @visible_states [:granted, :pending, :stale, :denied]
  @no_live_provider_copy "No live StoreKit, Play Billing, or RevenueCat adapter in this demo"

  @spec visible_states() :: [:granted | :pending | :stale | :denied]
  def visible_states, do: @visible_states

  @spec snapshot_for(atom() | String.t()) :: map()
  def snapshot_for(state) when state in @visible_states do
    snapshot = commerce_snapshot_for(state)
    derived_state = EntitlementProjection.derived_state(snapshot)

    %{
      id: "learnloop-entitlement-#{state}",
      learner_id: @learner_id,
      group_id: @group_id,
      requested_state: state,
      state: derived_state,
      authority: :backend_projection,
      storefront_provider: :mock,
      storefront_evidence: :mocked,
      grants_access_from_storefront_evidence: false,
      access: access_for(derived_state),
      support: Map.fetch!(state_copy(state), :support),
      commerce_snapshot: snapshot
    }
  end

  def snapshot_for(learner_id) when is_binary(learner_id) do
    state = default_state_for(learner_id)

    snapshot_for(state)
    |> Map.put(:learner_id, learner_id)
  end

  @spec state_copy(atom() | String.t()) :: map()
  def state_copy(state) when state in @visible_states do
    Map.fetch!(state_copy_by_state(), state)
  end

  def state_copy(learner_id) when is_binary(learner_id) do
    %{
      learner_id: learner_id,
      authority: :backend_projection,
      storefront_provider: :mock,
      states: Enum.map(@visible_states, &state_copy/1),
      granted: state_copy(:granted),
      pending: state_copy(:pending),
      stale: state_copy(:stale),
      denied: state_copy(:denied)
    }
  end

  @spec support_rows() :: [map()]
  def support_rows do
    [
      %{
        label: "Backend projection required",
        posture: :fail_closed,
        copy: "Backend projection required before gated LearnLoop lessons open."
      },
      %{
        label: "Mock storefront evidence received",
        posture: :evidence_only,
        copy: "Mock storefront evidence received; evidence never grants access by itself."
      },
      %{
        label: "Access stays closed until backend projection refreshes",
        posture: :pending_or_stale,
        copy: "Access stays closed until backend projection refreshes."
      },
      %{
        label: @no_live_provider_copy,
        posture: :unsupported_live_provider,
        copy: @no_live_provider_copy
      }
    ]
  end

  defp state_copy_by_state do
    %{
      granted: %{
        state: :granted,
        title: "Access active from backend projection",
        body: "Gated LearnLoop content is available because backend projection granted access.",
        support:
          "Mock storefront evidence remains labeled as evidence; backend projection grants access.",
        access: :granted,
        grants_access: true,
        storefront_evidence: :mocked,
        authority: :backend_projection
      },
      pending: %{
        state: :pending,
        title: "Mock storefront evidence received",
        body: "Access stays closed until backend projection refreshes.",
        support: "Backend projection required. #{@no_live_provider_copy}.",
        access: :closed,
        grants_access: false,
        storefront_evidence: :mocked,
        authority: :backend_projection
      },
      stale: %{
        state: :stale,
        title: "Backend projection required",
        body: "Access stays closed until backend projection refreshes.",
        support: "Backend projection required. #{@no_live_provider_copy}.",
        access: :closed,
        grants_access: false,
        storefront_evidence: :mocked,
        authority: :backend_projection
      },
      denied: %{
        state: :denied,
        title: @no_live_provider_copy,
        body: "Access stays closed until backend projection refreshes.",
        support: "Backend projection required; mocked storefront evidence does not grant access.",
        access: :closed,
        grants_access: false,
        storefront_evidence: :mocked,
        authority: :backend_projection
      }
    }
  end

  defp commerce_snapshot_for(:granted) do
    entitlement_snapshot(
      state: :granted,
      authority: :active,
      access: :granted,
      reconciliation: :projection_refreshed,
      freshness: :fresh,
      evidence_ref: "learnloop_mock_evt_granted"
    )
  end

  defp commerce_snapshot_for(:pending) do
    entitlement_snapshot(
      state: :pending,
      authority: :none,
      access: :denied,
      reconciliation: :awaiting_verification,
      freshness: :fresh,
      evidence_ref: "learnloop_mock_evt_pending"
    )
  end

  defp commerce_snapshot_for(:stale) do
    entitlement_snapshot(
      state: :stale,
      authority: :none,
      access: :denied,
      reconciliation: :projection_refreshed,
      freshness: :stale,
      evidence_ref: "learnloop_mock_evt_stale"
    )
  end

  defp commerce_snapshot_for(:denied) do
    entitlement_snapshot(
      state: :denied,
      authority: :none,
      access: :denied,
      reconciliation: :projection_refreshed,
      freshness: :fresh,
      evidence_ref: "learnloop_mock_evt_denied"
    )
  end

  defp entitlement_snapshot(opts) do
    now_iso = "2026-07-11T00:00:00Z"
    state = Keyword.fetch!(opts, :state)

    struct!(Contracts.EntitlementSnapshot, %{
      group_id: @group_id,
      authority: %EntitlementSnapshot.AuthorityLane{
        state: Keyword.fetch!(opts, :authority),
        reason: reason_for(state)
      },
      access: %EntitlementSnapshot.AccessLane{
        decision: Keyword.fetch!(opts, :access),
        reason: reason_for(state)
      },
      reconciliation: %EntitlementSnapshot.ReconciliationLane{
        state: Keyword.fetch!(opts, :reconciliation),
        reference: "learnloop_backend_projection_#{state}"
      },
      freshness: %EntitlementSnapshot.FreshnessLane{
        state: Keyword.fetch!(opts, :freshness),
        checked_at: now_iso,
        stale_after: "2026-07-12T00:00:00Z"
      },
      effective: %EntitlementSnapshot.EffectiveLane{
        effective_from: now_iso,
        effective_until: nil
      },
      evidence: %EntitlementSnapshot.EvidenceLane{
        source: :storefront,
        reference: Keyword.fetch!(opts, :evidence_ref),
        observed_at: now_iso
      },
      as_of: as_of_for(state)
    })
  end

  defp access_for(:granted), do: :granted
  defp access_for(_state), do: :closed

  defp default_state_for(@learner_id), do: :pending
  defp default_state_for(_learner_id), do: :denied

  defp reason_for(:granted), do: nil
  defp reason_for(:pending), do: :awaiting_backend_projection
  defp reason_for(:stale), do: :backend_projection_stale
  defp reason_for(:denied), do: :backend_projection_required

  defp as_of_for(:granted), do: 4
  defp as_of_for(:pending), do: 3
  defp as_of_for(:stale), do: 2
  defp as_of_for(:denied), do: 1
end
