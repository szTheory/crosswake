defmodule Crosswake.Commerce.ProviderEvidence do
  @moduledoc false

  @provider_vocabulary ["storekit", "play_billing"]

  @event_kind_vocabulary [
    "purchase",
    "restore",
    "renewal",
    "grace_period",
    "billing_retry",
    "refund",
    "revoked"
  ]

  @environment_vocabulary [:sandbox, :production, :license_test]
  @result_status_vocabulary [:submitted, :user_canceled, :pending, :provider_error, :prerequisite_missing, :reconcile_required]
  @lifecycle_hint_vocabulary [:flow_opened, :flow_closed, :pending_external, :reconcile_required, :reconcile_timeout]

  @provider_by_string Map.new(@provider_vocabulary, &{&1, &1})
  @event_kind_by_string Map.new(@event_kind_vocabulary, &{&1, &1})

  @spec provider_vocabulary() :: [String.t()]
  def provider_vocabulary, do: @provider_vocabulary

  @spec event_kind_vocabulary() :: [String.t()]
  def event_kind_vocabulary, do: @event_kind_vocabulary

  @spec environment_vocabulary() :: [atom()]
  def environment_vocabulary, do: @environment_vocabulary

  @spec result_status_vocabulary() :: [atom()]
  def result_status_vocabulary, do: @result_status_vocabulary

  @spec lifecycle_hint_vocabulary() :: [atom()]
  def lifecycle_hint_vocabulary, do: @lifecycle_hint_vocabulary

  @spec authority_mutation_allowed_from_lifecycle_hint?(term()) :: boolean()
  def authority_mutation_allowed_from_lifecycle_hint?(lifecycle_hint)
      when lifecycle_hint in @lifecycle_hint_vocabulary,
      do: false

  def authority_mutation_allowed_from_lifecycle_hint?(_lifecycle_hint), do: false

  @spec canonical_provider(term()) :: {:ok, String.t()} | {:error, {:invalid_provider, keyword()}}
  def canonical_provider(provider) when is_atom(provider), do: canonical_provider(Atom.to_string(provider))

  def canonical_provider(provider) when is_binary(provider) do
    downcased = provider |> String.trim() |> String.downcase()

    case Map.fetch(@provider_by_string, downcased) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:invalid_provider, [provider: provider, allowed: @provider_vocabulary]}}
    end
  end

  def canonical_provider(provider),
    do: {:error, {:invalid_provider, [provider: provider, allowed: @provider_vocabulary]}}

  @spec canonical_event_kind(term()) :: {:ok, String.t()} | {:error, {:invalid_event_kind, keyword()}}
  def canonical_event_kind(event_kind) when is_atom(event_kind) do
    normalized = event_kind |> Atom.to_string() |> String.trim() |> String.downcase()

    case Map.fetch(@event_kind_by_string, normalized) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:invalid_event_kind, [event_kind: event_kind, allowed: @event_kind_vocabulary]}}
    end
  end

  def canonical_event_kind(event_kind) when is_binary(event_kind) do
    normalized = event_kind |> String.trim() |> String.downcase()

    case Map.fetch(@event_kind_by_string, normalized) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> {:error, {:invalid_event_kind, [event_kind: event_kind, allowed: @event_kind_vocabulary]}}
    end
  end

  def canonical_event_kind(event_kind),
    do: {:error, {:invalid_event_kind, [event_kind: event_kind, allowed: @event_kind_vocabulary]}}
end
