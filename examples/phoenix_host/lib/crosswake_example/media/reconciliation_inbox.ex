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
             seen_idempotency_keys: Keyword.get(opts, :seen_idempotency_keys, [])
           ) do
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

  defp seen_event_key?(event_key, %MapSet{} = seen), do: MapSet.member?(seen, event_key)
  defp seen_event_key?(event_key, seen) when is_list(seen), do: event_key in seen
  defp seen_event_key?(_event_key, _seen), do: false
end
