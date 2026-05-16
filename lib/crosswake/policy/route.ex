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
    capabilities: [],
    packs: [],
    sync: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          runtime: Schema.runtime(),
          offline: Schema.offline(),
          cache_contract: String.t() | nil,
          island_contract: String.t() | nil,
          capabilities: [String.t()],
          packs: [Schema.pack_requirement()],
          sync: [String.t()],
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
             {:ok, validated} <- validate_pack_requirements(validated) do
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
    |> validate_pack_requirements!()
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

  defp validation_error(key, value, message) do
    %NimbleOptions.ValidationError{
      key: key,
      value: value,
      message: message
    }
  end
end
