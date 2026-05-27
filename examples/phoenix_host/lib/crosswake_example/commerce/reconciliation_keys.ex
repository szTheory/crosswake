defmodule CrosswakeExample.Commerce.ReconciliationKeys do
  @moduledoc """
  Example-host helpers for provider-aware reconciliation identity.

  `event_key` is for dedupe/replay safety.
  `subject_key` is for serializing authoritative projection updates.

  Transient `correlation_id` values are trace-only metadata and are never part of
  idempotency authority identity.
  """

  alias Crosswake.Commerce.Contracts

  @spec event_key(Contracts.ReconciliationEvidence.t()) :: String.t()
  def event_key(%Contracts.ReconciliationEvidence{} = evidence) do
    [
      canonical_component("event"),
      canonical_component(evidence.provider),
      opaque_component(evidence.provider_reference),
      canonical_component(evidence.event_kind),
      opaque_component(evidence.evidence_ref)
    ]
    |> join_components()
  end

  @spec subject_key(Contracts.ReconciliationEvidence.t()) :: String.t()
  def subject_key(%Contracts.ReconciliationEvidence{} = evidence) do
    subject_key(evidence, [])
  end

  @spec subject_key(Contracts.ReconciliationEvidence.t(), keyword()) :: String.t()
  def subject_key(%Contracts.ReconciliationEvidence{} = evidence, opts) when is_list(opts) do
    components =
      [
        canonical_component("subject"),
        canonical_component(evidence.provider),
        opaque_component(evidence.provider_reference)
      ]
      |> maybe_append_group_id(Keyword.get(opts, :group_id))

    join_components(components)
  end

  @spec trace_metadata(Contracts.ReconciliationEvidence.t()) :: map()
  def trace_metadata(%Contracts.ReconciliationEvidence{} = evidence) do
    trace_metadata(evidence, [])
  end

  @spec trace_metadata(Contracts.ReconciliationEvidence.t(), keyword()) :: map()
  def trace_metadata(%Contracts.ReconciliationEvidence{} = evidence, opts) when is_list(opts) do
    [
      evidence_ref: evidence.evidence_ref,
      captured_at: evidence.captured_at,
      integrity_digest: evidence.integrity_digest,
      idempotency_ref: evidence.idempotency_ref,
      correlation_id: Keyword.get(opts, :correlation_id)
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_append_group_id(components, group_id) do
    case present_string(group_id) do
      nil -> components
      normalized_group_id -> components ++ [canonical_component("group"), opaque_component(normalized_group_id)]
    end
  end

  defp canonical_component(component) do
    component
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp opaque_component(component) do
    component
    |> to_string()
    |> String.trim()
  end

  defp join_components(components), do: Enum.join(components, "::")

  defp present_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp present_string(_value), do: nil
end
