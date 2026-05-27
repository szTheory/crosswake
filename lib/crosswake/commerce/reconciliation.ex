defmodule Crosswake.Commerce.Reconciliation do
  @moduledoc """
  Typed backend-owned reconciliation vocabulary for commerce.
  
  This module encodes the canonical flow:
  1. Device/native evidence enters Phoenix.
  2. Phoenix records a reconciliation attempt.
  3. Host-owned workers verify it.
  4. Backend publishes a refreshed authoritative entitlement snapshot.
  
  These states represent reconciliation or freshness outcomes, not automatic access grants
  or silent denials. Device success is evidence, not entitlement.
  """

  alias Crosswake.Commerce.Contracts

  @type outcome ::
          :pending_purchase
          | :pending_restore
          | :awaiting_verification
          | :projection_refreshed
          | :conflict
          | :verification_failed
          | :stale_authority

  @outcome_vocabulary [
    :pending_purchase,
    :pending_restore,
    :awaiting_verification,
    :projection_refreshed,
    :conflict,
    :verification_failed,
    :stale_authority
  ]

  @unresolved_outcomes [:pending_purchase, :pending_restore, :awaiting_verification]
  @workflow_reporting_outcomes [:projection_refreshed, :verification_failed, :conflict, :stale_authority]

  @spec outcome_vocabulary() :: [outcome()]
  def outcome_vocabulary do
    @outcome_vocabulary
  end

  @spec reconciliation_outcome?(term()) :: boolean()
  def reconciliation_outcome?(state), do: state in @outcome_vocabulary

  @spec unresolved_outcome?(term()) :: boolean()
  def unresolved_outcome?(state), do: state in @unresolved_outcomes

  @spec workflow_reporting_outcome?(term()) :: boolean()
  def workflow_reporting_outcome?(state), do: state in @workflow_reporting_outcomes

  @spec outcome_implies_authority_grant?(term()) :: boolean()
  def outcome_implies_authority_grant?(state) when state in @outcome_vocabulary, do: false
  def outcome_implies_authority_grant?(_state), do: false

  @spec outcome_implies_access_granted?(term()) :: boolean()
  def outcome_implies_access_granted?(state) when state in @outcome_vocabulary, do: false
  def outcome_implies_access_granted?(_state), do: false

  defmodule Attempt do
    @moduledoc """
    A typed record of a backend-owned reconciliation attempt.
    """
    @enforce_keys [:provider, :provider_reference, :event_kind, :status]
    defstruct [:provider, :provider_reference, :event_kind, :status, :evidence_ref, :idempotency_ref]

    @type t :: %__MODULE__{
            provider: String.t(),
            provider_reference: String.t(),
            event_kind: String.t(),
            status: Crosswake.Commerce.Reconciliation.outcome(),
            evidence_ref: String.t() | nil,
            idempotency_ref: String.t() | nil
          }
  end

  defmodule IdempotencyKey do
    @moduledoc """
    Provider-aware and backend-owned idempotency fields.
    Transient device correlation ids are not part of this key.
    """
    @enforce_keys [:provider, :provider_reference, :event_kind]
    defstruct [:provider, :provider_reference, :event_kind]

    @type t :: %__MODULE__{
            provider: String.t(),
            provider_reference: String.t(),
            event_kind: String.t()
          }
  end

  defmodule EvidenceResult do
    @moduledoc """
    Represents an evidence-only result state for device purchase, restore, or native callback success.
    These states do not directly mutate entitlement authority.
    """
    @enforce_keys [:source, :status, :attempt, :idempotency_key, :replay?]
    defstruct [:source, :status, :attempt, :idempotency_key, :replay?]

    @type t :: %__MODULE__{
            source: Contracts.ReconciliationEvidence.source(),
            status: Crosswake.Commerce.Reconciliation.outcome(),
            attempt: Crosswake.Commerce.Reconciliation.Attempt.t(),
            idempotency_key: Crosswake.Commerce.Reconciliation.IdempotencyKey.t(),
            replay?: boolean()
          }
  end

  @success_like_event_kinds MapSet.new(["purchase", "restore", "renewal", "grace_period", "billing_retry"])

  @spec ingest_evidence(Contracts.ReconciliationEvidence.t(), keyword()) ::
          {:ok, EvidenceResult.t()} | {:error, term()}
  def ingest_evidence(%Contracts.ReconciliationEvidence{} = evidence, opts \\ []) do
    with :ok <- reject_direct_authority_override(opts) do
      idempotency_key = to_idempotency_key(evidence)
      replay? = seen_idempotency_key?(idempotency_key, Keyword.get(opts, :seen_idempotency_keys, []))
      status = evidence_status(evidence, opts)

      attempt = %Attempt{
        provider: evidence.provider,
        provider_reference: evidence.provider_reference,
        event_kind: evidence.event_kind,
        status: status,
        evidence_ref: evidence.evidence_ref,
        idempotency_ref: evidence.idempotency_ref
      }

      {:ok,
       %EvidenceResult{
         source: evidence.source,
         status: status,
         attempt: attempt,
         idempotency_key: idempotency_key,
         replay?: replay?
       }}
    end
  end

  @spec authority_mutation_allowed_from_evidence?(Contracts.ReconciliationEvidence.t()) :: false
  def authority_mutation_allowed_from_evidence?(%Contracts.ReconciliationEvidence{}), do: false

  defp to_idempotency_key(%Contracts.ReconciliationEvidence{} = evidence) do
    %IdempotencyKey{
      provider: evidence.provider,
      provider_reference: evidence.provider_reference,
      event_kind: evidence.event_kind
    }
  end

  defp seen_idempotency_key?(idempotency_key, %MapSet{} = seen), do: MapSet.member?(seen, idempotency_key)
  defp seen_idempotency_key?(idempotency_key, seen) when is_list(seen), do: Enum.member?(seen, idempotency_key)
  defp seen_idempotency_key?(_idempotency_key, _seen), do: false

  defp evidence_status(evidence, opts) do
    cond do
      Keyword.get(opts, :verified_projection, false) -> :projection_refreshed
      success_like_evidence?(evidence.event_kind) -> :awaiting_verification
      true -> :verification_failed
    end
  end

  defp success_like_evidence?(event_kind),
    do: MapSet.member?(@success_like_event_kinds, to_string(event_kind))

  defp reject_direct_authority_override(opts) do
    case Keyword.fetch(opts, :authority_state) do
      {:ok, _state} -> {:error, :authority_lane_mutation_forbidden}
      :error -> :ok
    end
  end
end
