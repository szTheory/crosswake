defmodule CrosswakeExample.Media.MediaProjection do
  @moduledoc """
  Backend-owned media projection for the example host.

  Evidence-only upload records may create uploaded or scanning projections, but
  only the explicit backend verification path can produce available media.
  """

  alias Crosswake.Companions.Rindle.Contracts
  alias Crosswake.Companions.Rindle.Reconciliation

  @spec project_object(Contracts.MediaObject.t() | nil, map()) ::
          {:ok, Contracts.MediaObject.t()} | {:error, term()}
  def project_object(current, %{backend_verified: true} = attrs) do
    base = current || media_object_from_attrs(attrs, :scanning)

    Contracts.verified_media_object(base,
      verification_ref: Map.fetch!(attrs, :verification_ref),
      authoritative_at: Map.fetch!(attrs, :authoritative_at),
      trace_metadata: Map.get(attrs, :trace_metadata, base.trace_metadata)
    )
  end

  def project_object(_current, %Reconciliation.EvidenceResult{} = result) do
    result
    |> evidence_attrs()
    |> media_object_from_attrs(evidence_state(result))
    |> then(&Contracts.new_media_object(Map.from_struct(&1)))
  end

  def project_object(_current, %{result: %Reconciliation.EvidenceResult{} = result} = ingestion) do
    result
    |> evidence_attrs(Map.get(ingestion, :subject_key), Map.get(ingestion, :trace_metadata))
    |> media_object_from_attrs(evidence_state(result))
    |> then(&Contracts.new_media_object(Map.from_struct(&1)))
  end

  @spec derived_state(Contracts.MediaObject.t()) :: Contracts.MediaObject.state()
  def derived_state(%Contracts.MediaObject{state: state}), do: state

  defp evidence_state(%Reconciliation.EvidenceResult{status: :verification_in_progress}), do: :scanning
  defp evidence_state(%Reconciliation.EvidenceResult{}), do: :uploaded

  defp evidence_attrs(result, subject_key \\ nil, trace_metadata \\ nil) do
    %{
      media_object_id: "media_#{result.attempt.grant_id}",
      subject_key: subject_key || "subject::media::unknown",
      storage_key: result.attempt.storage_key,
      as_of: System.system_time(:microsecond),
      trace_metadata: trace_metadata || %{grant_id: result.attempt.grant_id}
    }
  end

  defp media_object_from_attrs(attrs, state) do
    struct!(Contracts.MediaObject, %{
      media_object_id: Map.fetch!(attrs, :media_object_id),
      subject_key: Map.fetch!(attrs, :subject_key),
      storage_key: Map.fetch!(attrs, :storage_key),
      state: state,
      as_of: Map.get(attrs, :as_of, System.system_time(:microsecond)),
      verification_ref: Map.get(attrs, :verification_ref),
      rejection_reason: Map.get(attrs, :rejection_reason),
      authoritative_at: Map.get(attrs, :authoritative_at),
      trace_metadata: Map.get(attrs, :trace_metadata, %{})
    })
  end
end
