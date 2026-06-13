defmodule CrosswakeExample.Commerce.MockBackendVerifier do
  @moduledoc """
  Deterministic proof-only backend verifier for provider-shaped commerce evidence.

  The example inbox records normalized provider evidence, but it never grants
  entitlement authority. This helper models the backend verification step by
  converting normalized evidence into verified entitlement snapshots with fixed
  timestamps and monotonic ranks supplied by the caller or defaults.
  """

  alias Crosswake.Commerce.Contracts

  @default_checked_at "2026-06-04T00:00:00Z"
  @default_effective_from "2026-06-04T00:00:00Z"
  @default_observed_at "2026-06-04T00:00:00Z"
  @default_as_of 1_000

  @denied_lifecycles %{
    refunded: %{
      authority: :refunded,
      access_reason: :refunded,
      reconciliation: :projection_refreshed
    },
    revoked: %{
      authority: :revoked,
      access_reason: :revoked,
      reconciliation: :projection_refreshed
    },
    expired: %{
      authority: :expired,
      access_reason: :expired,
      reconciliation: :projection_refreshed
    },
    verification_failed: %{
      authority: :none,
      access_reason: :verification_failed,
      reconciliation: :verification_failed
    },
    stale_authority: %{
      authority: :none,
      access_reason: :stale_authority,
      reconciliation: :stale_authority
    }
  }

  @spec verify_evidence(Contracts.ReconciliationEvidence.t(), String.t(), keyword()) ::
          {:ok, Contracts.EntitlementSnapshot.t()}
  def verify_evidence(%Contracts.ReconciliationEvidence{} = evidence, group_id, opts \\ [])
      when is_binary(group_id) do
    lifecycle = Keyword.get(opts, :lifecycle, :active)
    lane = lane_for_lifecycle(lifecycle)
    reference = Keyword.get(opts, :reference, default_reference(evidence, group_id))

    snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{
          state: lane.authority,
          reason: lane.authority_reason
        },
        access: %Contracts.EntitlementSnapshot.AccessLane{
          decision: lane.access,
          reason: lane.access_reason
        },
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: lane.reconciliation,
          reference: reference
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: lane.freshness,
          checked_at: Keyword.get(opts, :checked_at, @default_checked_at),
          stale_after: Keyword.get(opts, :stale_after)
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: Keyword.get(opts, :effective_from, @default_effective_from),
          effective_until: Keyword.get(opts, :effective_until)
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: evidence.source,
          reference: reference,
          observed_at: Keyword.get(opts, :observed_at, @default_observed_at)
        },
        as_of: Keyword.get(opts, :as_of, @default_as_of)
      })

    {:ok, snapshot}
  end

  defp lane_for_lifecycle(:active) do
    %{
      authority: :active,
      authority_reason: nil,
      access: :granted,
      access_reason: nil,
      reconciliation: :projection_refreshed,
      freshness: :fresh
    }
  end

  defp lane_for_lifecycle(:stale) do
    %{
      authority: :active,
      authority_reason: nil,
      access: :granted,
      access_reason: nil,
      reconciliation: :projection_refreshed,
      freshness: :stale
    }
  end

  defp lane_for_lifecycle(lifecycle) when is_atom(lifecycle) do
    case Map.fetch(@denied_lifecycles, lifecycle) do
      {:ok, denied} ->
        %{
          authority: denied.authority,
          authority_reason: denied.access_reason,
          access: :denied,
          access_reason: denied.access_reason,
          reconciliation: denied.reconciliation,
          freshness: :fresh
        }

      :error ->
        lane_for_lifecycle(:verification_failed)
    end
  end

  defp lane_for_lifecycle(_lifecycle), do: lane_for_lifecycle(:verification_failed)

  defp default_reference(%Contracts.ReconciliationEvidence{} = evidence, group_id) do
    [
      "phase70",
      "verified",
      group_id,
      evidence.provider,
      evidence.event_kind,
      evidence.evidence_ref
    ]
    |> Enum.map(&to_string/1)
    |> Enum.join(":")
  end
end
