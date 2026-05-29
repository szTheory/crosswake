defmodule CrosswakeExample.Commerce.ReconciliationInbox do
  @moduledoc """
  Example-host, append-only reconciliation ingestion.

  This module records normalized evidence attempts and replay metadata only. It
  does not mutate authority or grant route access.
  """

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.ReconciliationKeys

  @success_like_event_kinds MapSet.new(["purchase", "restore", "renewal", "grace_period", "billing_retry"])

  @spec ingest_evidence(Contracts.ReconciliationEvidence.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def ingest_evidence(%Contracts.ReconciliationEvidence{} = evidence, opts \\ []) do
    with {:ok, source} <- normalize_source(evidence.source) do
      event_key = ReconciliationKeys.event_key(evidence)
      subject_key = ReconciliationKeys.subject_key(evidence, group_id: Keyword.get(opts, :group_id))
      replay? = seen_event_key?(event_key, Keyword.get(opts, :seen_event_keys, []))

      {:ok,
       %{
         source: source,
         event_key: event_key,
         subject_key: subject_key,
         status: evidence_status(evidence.event_kind),
         replay?: replay?,
         captured_at: evidence.captured_at,
         trace_metadata:
           ReconciliationKeys.trace_metadata(
             evidence,
             correlation_id: Keyword.get(opts, :correlation_id)
           )
       }}
    end
  end

  defp evidence_status(event_kind) do
    if MapSet.member?(@success_like_event_kinds, to_string(event_kind)) do
      :awaiting_verification
    else
      :verification_failed
    end
  end

  defp normalize_source(source) do
    case Contracts.canonical_reconciliation_evidence_source(source) do
      {:ok, canonical_source} -> normalize_canonical_source(canonical_source)
      {:error, {:invalid_source, details}} -> {:error, [source: {:invalid_source, details}]}
    end
  end

  defp normalize_canonical_source(:device), do: {:ok, :device}
  defp normalize_canonical_source(:storefront), do: {:ok, :storefront}
  defp normalize_canonical_source(:webhook), do: {:ok, :webhook}
  defp normalize_canonical_source(:support), do: {:ok, :support}

  defp seen_event_key?(event_key, %MapSet{} = seen_event_keys), do: MapSet.member?(seen_event_keys, event_key)
  defp seen_event_key?(event_key, seen_event_keys) when is_list(seen_event_keys), do: event_key in seen_event_keys
  defp seen_event_key?(_event_key, _seen_event_keys), do: false
end
