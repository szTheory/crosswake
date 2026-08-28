defmodule CrosswakeExample.AdopterHandoff do
  @moduledoc false

  alias Crosswake.Adoption.{NavigationTopology, RouteInventory}

  @top_level ~w(schema_version rows navigation_entries)

  @spec load(Path.t()) :: {:ok, map()} | {:error, :blocked}
  def load(path) when is_binary(path) and byte_size(path) > 0 do
    with {:ok, bytes} <- File.read(path),
         {:ok, handoff} <- Jason.decode(bytes),
         {:ok, validated} <- validate(handoff) do
      {:ok, validated}
    else
      _ -> {:error, :blocked}
    end
  rescue
    _ -> {:error, :blocked}
  end

  def load(_), do: {:error, :blocked}

  @spec validate(map()) :: {:ok, map()} | {:error, :blocked}
  def validate(input) when is_map(input) do
    with :ok <- exact_top_level?(input),
         {:ok, rows} <- RouteInventory.validate_inventory(normalize_rows(input)),
         {:eligible, _} <- RouteInventory.promotion_status(rows),
         {:ok, topology} <-
           NavigationTopology.compile(%{rows: rows, entries: normalize_entries(input)}),
         {:eligible, topology} <- NavigationTopology.promotion_status(topology) do
      {:ok, %{source: :adopter, inventory: rows, topology: topology}}
    else
      _ -> {:error, :blocked}
    end
  rescue
    _ -> {:error, :blocked}
  end

  def validate(_), do: {:error, :blocked}

  defp exact_top_level?(input) do
    keys = input |> Map.keys() |> Enum.map(&to_string/1) |> MapSet.new()

    if keys == MapSet.new(@top_level) and input["schema_version"] == 1,
      do: :ok,
      else: {:error, :blocked}
  end

  defp normalize_rows(%{"rows" => rows}) when is_list(rows), do: Enum.map(rows, &atomize/1)
  defp normalize_rows(%{rows: rows}) when is_list(rows), do: rows
  defp normalize_rows(_), do: []

  defp normalize_entries(%{"navigation_entries" => entries}) when is_list(entries),
    do: Enum.map(entries, &atomize/1)

  defp normalize_entries(%{navigation_entries: entries}) when is_list(entries), do: entries
  defp normalize_entries(_), do: []

  defp atomize(value) when is_list(value), do: Enum.map(value, &atomize/1)

  defp atomize(value) when is_map(value),
    do: Map.new(value, fn {key, item} -> {known_key(key), atomize(item)} end)

  defp atomize(value), do: known_value(value)

  defp known_key(key) when is_atom(key), do: key

  defp known_key(key) when is_binary(key) do
    Enum.find(
      [
        :route_id,
        :path_pattern,
        :runtime_owner,
        :offline_posture,
        :mutation_categories,
        :staleness_class,
        :auth,
        :recent_auth,
        :scope_posture,
        :media_requirement,
        :fallbacks,
        :disablement,
        :queued_data_retention,
        :status,
        :value,
        :scope,
        :logout,
        :account_switch,
        :requirement,
        :size_band,
        :codec_family,
        :integrity,
        :online,
        :offline,
        :denied,
        :corrupt_pack,
        :disabled,
        :entry,
        :replay,
        :root_tab_id,
        :presentation,
        :parent_route_id,
        :deep_link_posture,
        :restoration_posture
      ],
      key,
      &(Atom.to_string(&1) == key)
    ) || :unknown
  end

  defp known_value(value) when is_binary(value) do
    Enum.find(
      [
        :confirmed_sanitized,
        :known_default,
        :unknown_blocking,
        :not_applicable,
        :offline_island,
        :local_first,
        :answer_submission,
        :not_cacheable,
        :authenticated,
        :not_required,
        :opaque_partitioned,
        :stops_replay,
        :required,
        :small,
        :mp3,
        :verified,
        :serve,
        :queue_local,
        :block,
        :retain_and_block,
        :server_enforced,
        :server_reauthorized,
        :retain_until_resolution,
        :root,
        :push,
        :allow,
        :deny
      ],
      value,
      &(Atom.to_string(&1) == value)
    ) || value
  end

  defp known_value(value), do: value
end
