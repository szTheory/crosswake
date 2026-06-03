defmodule Crosswake.Companions.Rindle.Reconciliation do
  @moduledoc """
  Backend-owned reconciliation vocabulary for Rindle media capture evidence.

  Device upload success produces evidence results. It does not directly mutate
  media availability; only explicit backend verification may produce an
  available `MediaObject`.
  """

  alias Crosswake.Companions.Rindle.Contracts

  @type outcome ::
          :queued_capture
          | :upload_recorded
          | :awaiting_verification
          | :verification_in_progress
          | :projection_refreshed
          | :verification_failed
          | :rejected
          | :conflict
          | :stale_authority

  @outcome_vocabulary [
    :queued_capture,
    :upload_recorded,
    :awaiting_verification,
    :verification_in_progress,
    :projection_refreshed,
    :verification_failed,
    :rejected,
    :conflict,
    :stale_authority
  ]

  @unresolved_outcomes [
    :queued_capture,
    :upload_recorded,
    :awaiting_verification,
    :verification_in_progress
  ]
  @workflow_reporting_outcomes [
    :projection_refreshed,
    :verification_failed,
    :rejected,
    :conflict,
    :stale_authority
  ]

  @spec outcome_vocabulary() :: [outcome()]
  def outcome_vocabulary, do: @outcome_vocabulary

  @spec reconciliation_outcome?(term()) :: boolean()
  def reconciliation_outcome?(outcome), do: outcome in @outcome_vocabulary

  @spec unresolved_outcome?(term()) :: boolean()
  def unresolved_outcome?(outcome), do: outcome in @unresolved_outcomes

  @spec workflow_reporting_outcome?(term()) :: boolean()
  def workflow_reporting_outcome?(outcome), do: outcome in @workflow_reporting_outcomes

  @spec outcome_implies_availability?(term()) :: false
  def outcome_implies_availability?(_outcome), do: false

  defmodule Attempt do
    @moduledoc """
    A backend-owned media reconciliation attempt.
    """
    @enforce_keys [:storage_target, :grant_id, :event_kind, :status]
    defstruct [:storage_target, :grant_id, :event_kind, :status, :storage_key, :evidence_ref, :idempotency_ref]

    @type t :: %__MODULE__{
            storage_target: String.t(),
            grant_id: String.t(),
            event_kind: String.t(),
            status: Crosswake.Companions.Rindle.Reconciliation.outcome(),
            storage_key: String.t() | nil,
            evidence_ref: String.t() | nil,
            idempotency_ref: String.t() | nil
          }
  end

  defmodule IdempotencyKey do
    @moduledoc """
    Stable media evidence idempotency fields.

    Device correlation ids are trace-only and are intentionally excluded.
    """
    @enforce_keys [:storage_target, :grant_id, :idempotency_key, :event_kind]
    defstruct [:storage_target, :grant_id, :idempotency_key, :event_kind]

    @type t :: %__MODULE__{
            storage_target: String.t(),
            grant_id: String.t(),
            idempotency_key: String.t(),
            event_kind: String.t()
          }
  end

  defmodule EvidenceResult do
    @moduledoc """
    Evidence-only result of media capture ingestion.
    """
    @enforce_keys [:source, :status, :attempt, :idempotency_key, :replay?]
    defstruct [:source, :status, :attempt, :idempotency_key, :replay?]

    @type t :: %__MODULE__{
            source: Contracts.CaptureEvidence.source(),
            status: Crosswake.Companions.Rindle.Reconciliation.outcome(),
            attempt: Crosswake.Companions.Rindle.Reconciliation.Attempt.t(),
            idempotency_key: Crosswake.Companions.Rindle.Reconciliation.IdempotencyKey.t(),
            replay?: boolean()
          }
  end

  @success_like_event_kinds MapSet.new(["capture_uploaded", "upload", "uploaded", "multipart_complete"])

  @spec ingest_capture_evidence(Contracts.CaptureEvidence.t(), keyword()) ::
          {:ok, EvidenceResult.t()} | {:error, term()}
  def ingest_capture_evidence(%Contracts.CaptureEvidence{} = evidence, opts \\ []) do
    with :ok <- reject_direct_mutation_override(opts),
         :ok <- Contracts.validate_capture_evidence(evidence),
         {:ok, source} <- normalize_evidence_source(evidence.source) do
      event_kind = Keyword.get(opts, :event_kind, "capture_uploaded")
      storage_target = Keyword.get(opts, :storage_target, "mock")
      idempotency_key = to_idempotency_key(evidence, storage_target, event_kind)
      replay? = seen_idempotency_key?(idempotency_key, Keyword.get(opts, :seen_idempotency_keys, []))
      status = evidence_status(event_kind, opts)

      attempt = %Attempt{
        storage_target: storage_target,
        grant_id: evidence.grant_id,
        event_kind: event_kind,
        status: status,
        storage_key: evidence.storage_key,
        evidence_ref: evidence.client_upload_ref,
        idempotency_ref: evidence.idempotency_key
      }

      {:ok,
       %EvidenceResult{
         source: source,
         status: status,
         attempt: attempt,
         idempotency_key: idempotency_key,
         replay?: replay?
       }}
    end
  end

  @spec availability_mutation_allowed_from_evidence?(Contracts.CaptureEvidence.t()) :: false
  def availability_mutation_allowed_from_evidence?(%Contracts.CaptureEvidence{}), do: false

  defp reject_direct_mutation_override(opts) do
    cond do
      Keyword.has_key?(opts, :authority_state) -> {:error, :authority_lane_mutation_forbidden}
      Keyword.has_key?(opts, :availability_state) -> {:error, :availability_lane_mutation_forbidden}
      true -> :ok
    end
  end

  defp normalize_evidence_source(source) do
    case Contracts.canonical_capture_evidence_source(source) do
      {:ok, canonical_source} -> {:ok, canonical_source}
      {:error, {:invalid_source, details}} -> {:error, [source: {:invalid_source, details}]}
    end
  end

  defp to_idempotency_key(%Contracts.CaptureEvidence{} = evidence, storage_target, event_kind) do
    %IdempotencyKey{
      storage_target: storage_target,
      grant_id: evidence.grant_id,
      idempotency_key: evidence.idempotency_key,
      event_kind: event_kind
    }
  end

  defp seen_idempotency_key?(idempotency_key, %MapSet{} = seen), do: MapSet.member?(seen, idempotency_key)
  defp seen_idempotency_key?(idempotency_key, seen) when is_list(seen), do: Enum.member?(seen, idempotency_key)
  defp seen_idempotency_key?(_idempotency_key, _seen), do: false

  defp evidence_status(_event_kind, opts) do
    cond do
      Keyword.get(opts, :backend_scan_started, false) -> :verification_in_progress
      Keyword.get(opts, :upload_recorded, false) -> :upload_recorded
      success_like_evidence?(Keyword.get(opts, :event_kind, "capture_uploaded")) -> :awaiting_verification
      true -> :verification_failed
    end
  end

  defp success_like_evidence?(event_kind), do: MapSet.member?(@success_like_event_kinds, to_string(event_kind))
end
