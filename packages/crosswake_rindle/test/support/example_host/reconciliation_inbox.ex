defmodule CrosswakeExample.Media.ReconciliationInbox do
  @moduledoc """
  Example-host media evidence inbox.

  This wrapper records replay metadata and forwards only evidence to the Rindle
  reconciliation vocabulary. It does not create available media.
  """

  alias Crosswake.Companions.Rindle.Contracts
  alias Crosswake.Companions.Rindle.Reconciliation
  alias CrosswakeExample.Media.ReconciliationKeys

  @spec ingest_capture_evidence(Contracts.CaptureEvidence.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def ingest_capture_evidence(%Contracts.CaptureEvidence{} = evidence, opts \\ []) do
    event_kind = Keyword.get(opts, :event_kind, "capture_uploaded")
    event_key = ReconciliationKeys.event_key(evidence, event_kind)
    replay? = seen_event_key?(event_key, Keyword.get(opts, :seen_event_keys, []))

    with {:ok, result} <-
           Reconciliation.ingest_capture_evidence(evidence,
             event_kind: event_kind,
             storage_target: "mock",
             backend_scan_started: Keyword.get(opts, :backend_scan_started, false),
             upload_recorded: Keyword.get(opts, :upload_recorded, false),
             seen_idempotency_keys: Keyword.get(opts, :seen_idempotency_keys, [])
           ) do
      result = apply_example_status(result, evidence, opts)

      {:ok,
       %{
         result: result,
         source: result.source,
         status: result.status,
         event_key: event_key,
         subject_key: ReconciliationKeys.subject_key(evidence),
         replay?: replay? or result.replay?,
         trace_metadata:
           ReconciliationKeys.trace_metadata(
             evidence,
             correlation_id: Keyword.get(opts, :correlation_id, evidence.correlation_id)
           )
       }}
    end
  end

  defp apply_example_status(result, evidence, opts) do
    status = example_status(result.status, evidence, opts)
    %{result | status: status, attempt: %{result.attempt | status: status}}
  end

  defp example_status(current_status, evidence, opts) do
    cond do
      Keyword.get(opts, :grant_expired?, false) -> :stale_authority
      Keyword.get(opts, :backend_scan_failed, false) -> :verification_failed
      corrupt_hash?(evidence.content_hash) -> :verification_failed
      unsupported_integrity?(evidence, opts) -> :verification_failed
      partial_multipart?(evidence) -> :upload_recorded
      true -> current_status
    end
  end

  defp partial_multipart?(%Contracts.CaptureEvidence{multipart: multipart}) when is_map(multipart) do
    total = Map.get(multipart, :parts_total) || Map.get(multipart, "parts_total")
    uploaded = Map.get(multipart, :parts_uploaded) || Map.get(multipart, "parts_uploaded")
    completed? = Map.get(multipart, :completed?) || Map.get(multipart, "completed?")

    is_integer(total) and is_integer(uploaded) and (uploaded < total or completed? == false)
  end

  defp partial_multipart?(_evidence), do: false

  defp corrupt_hash?(hash) when is_binary(hash), do: String.contains?(hash, "corrupt")
  defp corrupt_hash?(_hash), do: false

  defp unsupported_integrity?(%Contracts.CaptureEvidence{} = evidence, opts) do
    algorithm =
      Keyword.get(opts, :integrity_algorithm) ||
        get_in(evidence.trace_metadata || %{}, [:integrity_algorithm]) ||
        get_in(evidence.trace_metadata || %{}, ["integrity_algorithm"])

    is_binary(algorithm) and algorithm not in ["sha256", "sha512"]
  end

  defp seen_event_key?(event_key, %MapSet{} = seen), do: MapSet.member?(seen, event_key)
  defp seen_event_key?(event_key, seen) when is_list(seen), do: event_key in seen
  defp seen_event_key?(_event_key, _seen), do: false
end
