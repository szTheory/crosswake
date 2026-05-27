defmodule Crosswake.Policy.Route do
  @moduledoc """
  Normalized Phase 1 route policy contract.
  """

  alias Crosswake.Policy.Defaults
  alias Crosswake.Policy.Schema

  @enforce_keys [:id, :runtime]
  defstruct [
    :id,
    :runtime,
    :security,
    :cache_contract,
    :island_contract,
    offline: :unavailable,
    entry: :internal_only,
    capabilities: [],
    packs: [],
    sync: [],
    transfers: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          runtime: Schema.runtime(),
          offline: Schema.offline(),
          entry: Schema.entry(),
          cache_contract: String.t() | nil,
          island_contract: String.t() | nil,
          capabilities: [String.t()],
          packs: [Schema.pack_requirement()],
          sync: [String.t()],
          transfers: [Crosswake.Transfer.Contracts.declaration()],
          security: Schema.security() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate()
    |> case do
      {:ok, validated} ->
        with {:ok, validated} <- validate_offline_contracts(validated),
             {:ok, validated} <- validate_entry_policy(validated),
             {:ok, validated} <- validate_pack_requirements(validated),
             {:ok, validated} <- validate_transfer_declarations(validated) do
          {:ok, struct!(__MODULE__, validated)}
        end

      {:error, error} -> {:error, error}
    end
  end

  @spec new!(keyword()) :: t()
  def new!(options) when is_list(options) do
    options
    |> merged_options()
    |> Schema.validate!()
    |> validate_offline_contracts!()
    |> validate_entry_policy!()
    |> validate_pack_requirements!()
    |> validate_transfer_declarations!()
    |> then(&struct!(__MODULE__, &1))
  end

  defp merged_options(options) do
    Defaults.route()
    |> Keyword.merge(options)
  end

  defp validate_offline_contracts(validated) do
    cond do
      validated[:cache_contract] && validated[:offline] != :cached_read_only ->
        {:error,
         validation_error(
           :cache_contract,
           validated[:cache_contract],
           "cache_contract requires offline :cached_read_only and does not belong on local-first routes"
         )}

      validated[:island_contract] &&
          (validated[:runtime] != :offline_island or validated[:offline] != :local_first) ->
        {:error,
         validation_error(
           :island_contract,
           validated[:island_contract],
           "island_contract requires runtime :offline_island with offline :local_first"
         )}

      true ->
        {:ok, validated}
    end
  end

  defp validate_offline_contracts!(validated) do
    case validate_offline_contracts(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_pack_requirements(validated) do
    pack_ids = Enum.map(validated[:packs], & &1.id)

    if Enum.uniq(pack_ids) == pack_ids do
      {:ok, validated}
    else
      {:error,
       validation_error(
         :packs,
         validated[:packs],
         "pack ids must be unique within a route declaration"
       )}
    end
  end

  defp validate_pack_requirements!(validated) do
    case validate_pack_requirements(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_transfer_declarations(validated) do
    transfer_ids = Enum.map(validated[:transfers], & &1.id)

    cond do
      Enum.uniq(transfer_ids) != transfer_ids ->
        {:error,
         validation_error(
           :transfers,
           validated[:transfers],
           "transfer ids must be unique within a route declaration"
         )}

      true ->
        validate_transfer_runtime(validated)
    end
  end

  defp validate_transfer_runtime(validated) do
    case Enum.find(validated[:transfers], &invalid_transfer_for_runtime?(&1, validated[:runtime])) do
      nil ->
        {:ok, validated}

      transfer ->
        {:error,
         validation_error(
           :transfers,
           validated[:transfers],
           transfer_runtime_message(transfer)
         )}
    end
  end

  defp validate_transfer_declarations!(validated) do
    case validate_transfer_declarations(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp validate_entry_policy(validated) do
    case {validated[:entry], validated[:runtime]} do
      {:external, :offline_island} ->
        {:error,
         validation_error(
           :entry,
           validated[:entry],
           "entry :external is not supported on offline_island routes"
         )}

      _other ->
        {:ok, validated}
    end
  end

  defp validate_entry_policy!(validated) do
    case validate_entry_policy(validated) do
      {:ok, validated} -> validated
      {:error, error} -> raise error
    end
  end

  defp invalid_transfer_for_runtime?(transfer, runtime) do
    transfer.source == :native_capture and runtime != :native_screen
  end

  defp transfer_runtime_message(%{source: :native_capture, id: id}) do
    "transfer #{inspect(id)} native_capture source requires runtime :native_screen"
  end

  defp validation_error(key, value, message) do
    %NimbleOptions.ValidationError{
      key: key,
      value: value,
      message: message
    }
  end
end
