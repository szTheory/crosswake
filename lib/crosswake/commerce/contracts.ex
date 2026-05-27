defmodule Crosswake.Commerce.Contracts do
  @moduledoc """
  Typed commerce contract surfaces shared by core, route policy, and manifest truth.
  """

  defmodule PaywallEntry do
    @moduledoc false
    @enforce_keys [:id, :price_display, :group_id, :features]
    defstruct [:id, :price_display, :group_id, features: []]

    @type t :: %__MODULE__{
            id: String.t(),
            price_display: String.t(),
            group_id: String.t(),
            features: [String.t()]
          }
  end

  defmodule PurchaseIntent do
    @moduledoc false
    @enforce_keys [:entry_id, :correlation_id]
    defstruct [:entry_id, :correlation_id]

    @type t :: %__MODULE__{
            entry_id: String.t(),
            correlation_id: String.t()
          }
  end

  defmodule RestoreIntent do
    @moduledoc false
    @enforce_keys [:correlation_id]
    defstruct [:correlation_id]

    @type t :: %__MODULE__{
            correlation_id: String.t()
          }
  end

  defmodule EntitlementSnapshot do
    @moduledoc false
    defmodule AuthorityLane do
      @moduledoc false
      @enforce_keys [:state]
      defstruct [:state, :reason]

      @type state ::
              :none
              | :active
              | :grace
              | :billing_retry
              | :canceled_scheduled_end
              | :revoked
              | :refunded
              | :expired

      @type t :: %__MODULE__{
              state: state(),
              reason: atom() | nil
            }
    end

    defmodule AccessLane do
      @moduledoc false
      @enforce_keys [:decision]
      defstruct [:decision, :reason]

      @type decision :: :granted | :denied

      @type t :: %__MODULE__{
              decision: decision(),
              reason: atom() | nil
            }
    end

    defmodule ReconciliationLane do
      @moduledoc false
      @enforce_keys [:state]
      defstruct [:state, :reference]

      @type state ::
              :pending_purchase
              | :pending_restore
              | :awaiting_verification
              | :projection_refreshed
              | :conflict
              | :verification_failed
              | :stale_authority

      @type t :: %__MODULE__{
              state: state(),
              reference: String.t() | nil
            }
    end

    defmodule FreshnessLane do
      @moduledoc false
      @enforce_keys [:state, :checked_at]
      defstruct [:state, :checked_at, :stale_after]

      @type state :: :fresh | :stale | :unknown

      @type t :: %__MODULE__{
              state: state(),
              checked_at: String.t(),
              stale_after: String.t() | nil
            }
    end

    defmodule EffectiveLane do
      @moduledoc false
      @enforce_keys [:effective_from]
      defstruct [:effective_from, :effective_until]

      @type t :: %__MODULE__{
              effective_from: String.t(),
              effective_until: String.t() | nil
            }
    end

    defmodule EvidenceLane do
      @moduledoc false
      @enforce_keys [:source, :reference]
      defstruct [:source, :reference, :observed_at]

      @type source :: :device | :storefront | :webhook | :support

      @type t :: %__MODULE__{
              source: source(),
              reference: String.t(),
              observed_at: String.t() | nil
            }
    end

    @enforce_keys [:group_id, :authority, :access, :reconciliation, :freshness, :effective, :evidence, :as_of]
    defstruct [:group_id, :authority, :access, :reconciliation, :freshness, :effective, :evidence, :as_of]

    @type t :: %__MODULE__{
            group_id: String.t(),
            authority: AuthorityLane.t(),
            access: AccessLane.t(),
            reconciliation: ReconciliationLane.t(),
            freshness: FreshnessLane.t(),
            effective: EffectiveLane.t(),
            evidence: EvidenceLane.t(),
            as_of: non_neg_integer() | String.t()
          }
  end

  defmodule ReconciliationEvidence do
    @moduledoc false
    @enforce_keys [
      :source,
      :provider,
      :provider_reference,
      :event_kind,
      :evidence_ref,
      :captured_at
    ]
    defstruct [
      :source,
      :provider,
      :provider_reference,
      :event_kind,
      :evidence_ref,
      :captured_at,
      :integrity_digest,
      :idempotency_ref
    ]

    @type source :: :device | :storefront | :webhook | :support

    @type t :: %__MODULE__{
            source: source(),
            provider: String.t(),
            provider_reference: String.t(),
            event_kind: String.t(),
            evidence_ref: String.t(),
            captured_at: String.t(),
            integrity_digest: String.t() | nil,
            idempotency_ref: String.t() | nil
          }
  end

  @authority_vocabulary [
    :none,
    :active,
    :grace,
    :billing_retry,
    :canceled_scheduled_end,
    :revoked,
    :refunded,
    :expired
  ]
  @access_vocabulary [:granted, :denied]

  @reconciliation_vocabulary [
    :pending_purchase,
    :pending_restore,
    :awaiting_verification,
    :projection_refreshed,
    :conflict,
    :verification_failed,
    :stale_authority
  ]

  @freshness_vocabulary [:fresh, :stale, :unknown]
  @reconciliation_evidence_source_vocabulary [:device, :storefront, :webhook, :support]

  @spec authority_vocabulary() :: [EntitlementSnapshot.AuthorityLane.state()]
  def authority_vocabulary, do: @authority_vocabulary

  @spec access_vocabulary() :: [EntitlementSnapshot.AccessLane.decision()]
  def access_vocabulary, do: @access_vocabulary

  @spec reconciliation_vocabulary() :: [EntitlementSnapshot.ReconciliationLane.state()]
  def reconciliation_vocabulary, do: @reconciliation_vocabulary

  @spec freshness_vocabulary() :: [EntitlementSnapshot.FreshnessLane.state()]
  def freshness_vocabulary, do: @freshness_vocabulary

  @spec reconciliation_evidence_source_vocabulary() :: [ReconciliationEvidence.source()]
  def reconciliation_evidence_source_vocabulary, do: @reconciliation_evidence_source_vocabulary

  @spec new_entitlement_snapshot(map() | keyword()) ::
          {:ok, EntitlementSnapshot.t()} | {:error, keyword()}
  def new_entitlement_snapshot(attrs) when is_list(attrs) do
    attrs
    |> Map.new()
    |> new_entitlement_snapshot()
  end

  def new_entitlement_snapshot(attrs) when is_map(attrs) do
    with {:ok, snapshot} <- build_entitlement_snapshot(attrs),
         :ok <- validate_entitlement_snapshot(snapshot) do
      {:ok, snapshot}
    end
  end

  @spec validate_entitlement_snapshot(EntitlementSnapshot.t()) :: :ok | {:error, keyword()}
  def validate_entitlement_snapshot(%EntitlementSnapshot{} = snapshot) do
    []
    |> validate_authority_lane(snapshot.authority)
    |> validate_access_lane(snapshot.access)
    |> validate_reconciliation_lane(snapshot.reconciliation)
    |> validate_freshness_lane(snapshot.freshness)
    |> validate_effective_lane(snapshot.effective)
    |> validate_evidence_lane(snapshot.evidence)
    |> to_validation_result()
  end

  defp build_entitlement_snapshot(attrs) do
    try do
      {:ok, struct!(EntitlementSnapshot, attrs)}
    rescue
      error in KeyError -> {:error, [snapshot: Exception.message(error)]}
    end
  end

  defp validate_authority_lane(errors, %EntitlementSnapshot.AuthorityLane{state: state}) do
    if state in @authority_vocabulary do
      errors
    else
      [{:authority, {:invalid_state, state}} | errors]
    end
  end

  defp validate_authority_lane(errors, _), do: [{:authority, :invalid_lane} | errors]

  defp validate_access_lane(errors, %EntitlementSnapshot.AccessLane{decision: decision}) do
    if decision in @access_vocabulary do
      errors
    else
      [{:access, {:invalid_decision, decision}} | errors]
    end
  end

  defp validate_access_lane(errors, _), do: [{:access, :invalid_lane} | errors]

  defp validate_reconciliation_lane(errors, %EntitlementSnapshot.ReconciliationLane{state: state}) do
    if state in @reconciliation_vocabulary do
      errors
    else
      [{:reconciliation, {:invalid_state, state}} | errors]
    end
  end

  defp validate_reconciliation_lane(errors, _), do: [{:reconciliation, :invalid_lane} | errors]

  defp validate_freshness_lane(errors, %EntitlementSnapshot.FreshnessLane{state: state}) do
    if state in @freshness_vocabulary do
      errors
    else
      [{:freshness, {:invalid_state, state}} | errors]
    end
  end

  defp validate_freshness_lane(errors, _), do: [{:freshness, :invalid_lane} | errors]

  defp validate_effective_lane(errors, %EntitlementSnapshot.EffectiveLane{}), do: errors
  defp validate_effective_lane(errors, _), do: [{:effective, :invalid_lane} | errors]

  defp validate_evidence_lane(errors, %EntitlementSnapshot.EvidenceLane{}), do: errors
  defp validate_evidence_lane(errors, _), do: [{:evidence, :invalid_lane} | errors]

  defp to_validation_result([]), do: :ok
  defp to_validation_result(errors), do: {:error, Enum.reverse(errors)}
end
