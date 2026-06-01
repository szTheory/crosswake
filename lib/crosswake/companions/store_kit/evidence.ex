defmodule Crosswake.Companions.StoreKit.Evidence do
  @moduledoc false

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Commerce.ProviderEvidence

  @enforce_keys [:original_transaction_id, :event_kind, :environment, :source, :captured_at]
  defstruct [
    :original_transaction_id,
    :transaction_id,
    :notification_uuid,
    :signed_transaction_info_digest,
    :event_kind,
    :environment,
    :source,
    :captured_at,
    :idempotency_ref,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          original_transaction_id: String.t(),
          transaction_id: String.t() | nil,
          notification_uuid: String.t() | nil,
          signed_transaction_info_digest: String.t() | nil,
          event_kind: String.t(),
          environment: :sandbox | :production,
          source: Contracts.ReconciliationEvidence.source(),
          captured_at: String.t(),
          idempotency_ref: String.t() | nil,
          metadata: map()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    with :ok <- require_present(attrs, :original_transaction_id),
         :ok <- require_evidence_identity(attrs),
         {:ok, event_kind} <- ProviderEvidence.canonical_event_kind(Map.get(attrs, :event_kind)),
         {:ok, source} <- Contracts.canonical_reconciliation_evidence_source(Map.get(attrs, :source)),
         {:ok, environment} <- normalize_environment(Map.get(attrs, :environment)),
         {:ok, evidence} <- build(attrs, event_kind, source, environment) do
      {:ok, evidence}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}

  @spec to_reconciliation_evidence(t()) :: {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def to_reconciliation_evidence(%__MODULE__{} = evidence) do
    with {:ok, evidence_ref} <- evidence_ref(evidence) do
      {:ok,
       %Contracts.ReconciliationEvidence{
         source: evidence.source,
         provider: "storekit",
         provider_reference: evidence.original_transaction_id,
         event_kind: evidence.event_kind,
         evidence_ref: evidence_ref,
         captured_at: evidence.captured_at,
         integrity_digest: evidence.signed_transaction_info_digest,
         idempotency_ref: evidence.idempotency_ref
       }}
    end
  end

  def to_reconciliation_evidence(_evidence), do: {:error, :invalid_evidence}

  defp build(attrs, event_kind, source, environment) do
    try do
      {:ok,
       struct!(__MODULE__, %{
         original_transaction_id: Map.get(attrs, :original_transaction_id),
         transaction_id: Map.get(attrs, :transaction_id),
         notification_uuid: Map.get(attrs, :notification_uuid),
         signed_transaction_info_digest: Map.get(attrs, :signed_transaction_info_digest),
         event_kind: event_kind,
         environment: environment,
         source: source,
         captured_at: Map.get(attrs, :captured_at),
         idempotency_ref: Map.get(attrs, :idempotency_ref),
         metadata: Map.merge(%{storekit_environment: environment}, Map.get(attrs, :metadata, %{}))
       })}
    rescue
      error in [ArgumentError, KeyError] -> {:error, Exception.message(error)}
    end
  end

  defp require_present(attrs, key) do
    case Map.get(attrs, key) do
      value when is_binary(value) ->
        if byte_size(String.trim(value)) > 0, do: :ok, else: {:error, {:missing_field, key}}

      _ -> {:error, {:missing_field, key}}
    end
  end

  defp require_evidence_identity(attrs) do
    if present?(Map.get(attrs, :transaction_id)) or present?(Map.get(attrs, :notification_uuid)) or
         present?(Map.get(attrs, :signed_transaction_info_digest)) do
      :ok
    else
      {:error, {:missing_field, :event_identity}}
    end
  end

  defp normalize_environment(environment) when environment in [:sandbox, :production], do: {:ok, environment}

  defp normalize_environment(environment),
    do: {:error, {:invalid_environment, [environment: environment, allowed: [:sandbox, :production]]}}

  defp evidence_ref(%__MODULE__{transaction_id: value}) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
  defp evidence_ref(%__MODULE__{notification_uuid: value}) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}

  defp evidence_ref(%__MODULE__{signed_transaction_info_digest: value})
       when is_binary(value) and byte_size(value) > 0,
       do: {:ok, value}

  defp evidence_ref(_evidence), do: {:error, {:missing_field, :event_identity}}

  defp present?(value) when is_binary(value), do: byte_size(String.trim(value)) > 0
  defp present?(_value), do: false
end
