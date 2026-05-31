defmodule CrosswakeExample.Media.ReconciliationKeys do
  @moduledoc """
  Stable media reconciliation identity helpers for the example host.

  `correlation_id` stays in trace metadata only; it never participates in replay
  identity.
  """

  alias Crosswake.Companions.Rindle.Contracts

  @spec event_key(Contracts.CaptureEvidence.t(), String.t() | atom()) :: String.t()
  def event_key(%Contracts.CaptureEvidence{} = evidence, event_kind) do
    [
      "event",
      "media",
      "mock",
      evidence.grant_id,
      evidence.idempotency_key,
      canonical(event_kind),
      evidence.storage_key
    ]
    |> Enum.map(&component/1)
    |> Enum.join("::")
  end

  @spec subject_key(Contracts.CaptureEvidence.t() | Contracts.UploadGrant.t()) :: String.t()
  def subject_key(%Contracts.CaptureEvidence{} = evidence), do: subject_from_storage_key(evidence.storage_key)
  def subject_key(%Contracts.UploadGrant{} = grant), do: subject_from_storage_key(grant.key_prefix)

  @spec trace_metadata(Contracts.CaptureEvidence.t(), keyword()) :: map()
  def trace_metadata(%Contracts.CaptureEvidence{} = evidence, opts \\ []) do
    [
      storage_key: evidence.storage_key,
      captured_at: evidence.captured_at,
      client_upload_ref: evidence.client_upload_ref,
      content_hash: evidence.content_hash,
      correlation_id: Keyword.get(opts, :correlation_id, evidence.correlation_id)
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp subject_from_storage_key(value) do
    value
    |> to_string()
    |> String.split("/", trim: true)
    |> case do
      ["media", subject | _rest] -> "subject::media::" <> subject
      _other -> "subject::media::unknown"
    end
  end

  defp canonical(value), do: value |> to_string() |> String.trim() |> String.downcase()
  defp component(value), do: value |> to_string() |> String.trim()
end
