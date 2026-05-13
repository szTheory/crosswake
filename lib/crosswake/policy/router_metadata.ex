defmodule Crosswake.Policy.RouterMetadata do
  @moduledoc """
  Attaches and extracts compiled Crosswake route policy from Phoenix route metadata.
  """

  alias Crosswake.Policy.Route

  @raw_key :crosswake
  @compiled_key :crosswake_policy

  @spec attach(map(), keyword()) :: map()
  def attach(metadata, crosswake_options) when is_map(metadata) and is_list(crosswake_options) do
    compiled = Route.new!(crosswake_options)

    metadata
    |> Map.put(@raw_key, crosswake_options)
    |> Map.put(@compiled_key, compiled)
  end

  @spec fetch(map()) :: {:ok, Route.t()} | :error
  def fetch(metadata) when is_map(metadata) do
    case Map.fetch(metadata, @compiled_key) do
      {:ok, %Route{} = route} -> {:ok, route}
      _other -> :error
    end
  end

  @spec fetch!(map()) :: Route.t()
  def fetch!(metadata) when is_map(metadata) do
    case fetch(metadata) do
      {:ok, route} -> route
      :error -> raise KeyError, key: @compiled_key, term: metadata
    end
  end

  @spec raw_key() :: atom()
  def raw_key, do: @raw_key

  @spec compiled_key() :: atom()
  def compiled_key, do: @compiled_key
end
