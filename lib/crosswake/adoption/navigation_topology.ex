defmodule Crosswake.Adoption.NavigationTopology do
  @moduledoc """
  Closed, version-bound topology compilation from validated first-adopter route rows.

  This compiler carries opaque references only. It does not own paths, labels, browser history,
  or host presentation, and an incomplete inventory remains explicitly `unknown_blocking`.
  """

  alias Crosswake.Adoption.RouteInventory

  defmodule CompileError do
    defexception [:message, :rule_id, :route_ref, :field]
  end

  defmodule Entry do
    @enforce_keys [
      :route_id,
      :root_tab_id,
      :presentation,
      :deep_link_posture,
      :restoration_posture
    ]
    defstruct [
      :route_id,
      :root_tab_id,
      :presentation,
      :parent_route_id,
      :deep_link_posture,
      :restoration_posture
    ]
  end

  @topology_schema_version "1.0.0"
  @manifest_schema_version "1.0.0"
  @opaque_route ~r/^route-[0-9a-f]{16}$/
  @opaque_tab ~r/^tab-[0-9a-f]{16}$/

  @spec compile(list() | map(), String.t()) :: {:ok, map()} | {:error, CompileError.t()}
  def compile(input, manifest_schema_version \\ @manifest_schema_version)

  def compile([], manifest_schema_version), do: {:ok, unknown_blocking(manifest_schema_version)}

  def compile(%{rows: rows, entries: entries}, manifest_schema_version)
      when is_list(rows) and is_list(entries) do
    with {:ok, validated_rows} <- validate_rows(rows),
         {:eligible, _} <- RouteInventory.promotion_status(validated_rows),
         {:ok, compiled_entries} <- validate_entries(entries, validated_rows) do
      {:ok, ready(compiled_entries, manifest_schema_version)}
    else
      {:blocked, _} -> {:ok, unknown_blocking(manifest_schema_version)}
      {:error, %RouteInventory.ValidationError{} = error} -> {:error, from_inventory(error)}
      error -> error
    end
  end

  def compile(rows, manifest_schema_version) when is_list(rows) do
    with {:ok, validated_rows} <- validate_rows(rows) do
      case RouteInventory.promotion_status(validated_rows) do
        {:eligible, _} -> {:ok, unknown_blocking(manifest_schema_version)}
        {:blocked, _} -> {:ok, unknown_blocking(manifest_schema_version)}
      end
    else
      {:error, %RouteInventory.ValidationError{} = error} -> {:error, from_inventory(error)}
    end
  end

  def compile(_, _), do: {:error, error("NT-INVALID", "unresolved", "topology")}

  @spec render(list() | map()) :: {:ok, binary()} | {:error, CompileError.t()}
  def render(input) do
    with {:ok, topology} <- compile(input) do
      {:ok, topology |> ordered() |> Jason.encode!() |> Kernel.<>("\n")}
    end
  end

  @spec promotion_status(list() | map()) :: {:eligible, map()} | {:blocked, map()}
  def promotion_status(input) do
    case compile(input) do
      {:ok, %{status: :ready} = topology} -> {:eligible, topology}
      {:ok, _} -> {:blocked, %{reason: :unknown_blocking, fields: []}}
      {:error, _} -> {:blocked, %{reason: :unknown_blocking, fields: []}}
    end
  end

  defp validate_rows(rows) do
    if Enum.all?(rows, &match?(%RouteInventory{}, &1)) do
      {:ok, rows}
    else
      RouteInventory.validate_inventory(rows)
    end
  end

  defp validate_entries(entries, rows) do
    route_ids = MapSet.new(rows, & &1.route_id)

    with {:ok, parsed} <- parse_entries(entries, route_ids),
         :ok <- validate_graph(parsed) do
      {:ok, parsed}
    end
  end

  defp parse_entries(entries, route_ids) do
    Enum.reduce_while(entries, {:ok, []}, fn input, {:ok, acc} ->
      case parse_entry(input, route_ids) do
        {:ok, entry} -> {:cont, {:ok, [entry | acc]}}
        error -> {:halt, error}
      end
    end)
    |> then(fn
      {:ok, parsed} -> {:ok, Enum.reverse(parsed)}
      error -> error
    end)
  end

  defp parse_entry(input, route_ids) when is_map(input) and map_size(input) in 5..6 do
    expected = [
      :route_id,
      :root_tab_id,
      :presentation,
      :parent_route_id,
      :deep_link_posture,
      :restoration_posture
    ]

    keys = Map.keys(input)

    with :ok <- require_atom_keys(keys),
         :ok <- reject_unknown_keys(keys, expected),
         route_id when is_binary(route_id) <- input[:route_id],
         true <- MapSet.member?(route_ids, route_id) and Regex.match?(@opaque_route, route_id),
         root_tab_id when is_binary(root_tab_id) <- input[:root_tab_id],
         true <- Regex.match?(@opaque_tab, root_tab_id),
         presentation when presentation in [:root, :push] <- input[:presentation],
         posture when posture in [:allow, :deny] <- input[:deep_link_posture],
         restoration when restoration in [:allow, :deny] <- input[:restoration_posture],
         {:ok, parent_route_id} <-
           validate_parent(input[:parent_route_id], presentation, route_ids) do
      {:ok,
       %Entry{
         route_id: route_id,
         root_tab_id: root_tab_id,
         presentation: presentation,
         parent_route_id: parent_route_id,
         deep_link_posture: posture,
         restoration_posture: restoration
       }}
    else
      _ -> {:error, error("NT-INVALID_ENTRY", "unresolved", "entry")}
    end
  end

  defp parse_entry(_, _), do: {:error, error("NT-INVALID_ENTRY", "unresolved", "entry")}

  defp require_atom_keys(keys),
    do:
      if(Enum.all?(keys, &is_atom/1),
        do: :ok,
        else: {:error, error("NT-INVALID_ENTRY", "unresolved", "entry")}
      )

  defp reject_unknown_keys(keys, expected),
    do:
      if(Enum.all?(keys, &(&1 in expected)),
        do: :ok,
        else: {:error, error("NT-UNKNOWN_FIELD", "unresolved", "entry")}
      )

  defp validate_parent(nil, :root, _), do: {:ok, nil}

  defp validate_parent(parent, :push, route_ids) when is_binary(parent) do
    if MapSet.member?(route_ids, parent) and Regex.match?(@opaque_route, parent),
      do: {:ok, parent},
      else: {:error, error("NT-INVALID_PARENT", "unresolved", "parent_route_id")}
  end

  defp validate_parent(_, _, _),
    do: {:error, error("NT-INVALID_PARENT", "unresolved", "parent_route_id")}

  defp validate_graph(entries) do
    roots = Enum.filter(entries, &(&1.presentation == :root))
    duplicate_route? = entries |> Enum.map(& &1.route_id) |> duplicates?()
    duplicate_root? = roots |> Enum.map(& &1.root_tab_id) |> duplicates?()

    valid_parents? =
      Enum.all?(entries, fn entry ->
        entry.presentation == :root or
          Enum.any?(
            entries,
            &(&1.route_id == entry.parent_route_id and &1.root_tab_id == entry.root_tab_id)
          )
      end)

    rooted? = Enum.all?(entries, &reaches_root?(&1, entries, MapSet.new()))

    if roots != [] and not duplicate_route? and not duplicate_root? and valid_parents? and rooted?,
      do: :ok,
      else: {:error, error("NT-INVALID_GRAPH", "unresolved", "entries")}
  end

  defp duplicates?(values), do: length(values) != MapSet.size(MapSet.new(values))

  defp reaches_root?(%Entry{presentation: :root}, _entries, _seen), do: true

  defp reaches_root?(%Entry{} = entry, entries, seen) do
    if MapSet.member?(seen, entry.route_id) do
      false
    else
      case Enum.find(entries, &(&1.route_id == entry.parent_route_id)) do
        nil -> false
        parent -> reaches_root?(parent, entries, MapSet.put(seen, entry.route_id))
      end
    end
  end

  defp ready(entries, manifest_schema_version),
    do: %{
      topology_schema_version: @topology_schema_version,
      manifest_schema_version: manifest_schema_version,
      status: :ready,
      entries: Enum.map(entries, &entry_map/1)
    }

  defp unknown_blocking(manifest_schema_version),
    do: %{
      topology_schema_version: @topology_schema_version,
      manifest_schema_version: manifest_schema_version,
      status: :unknown_blocking,
      entries: []
    }

  defp entry_map(entry),
    do: %{
      route_id: entry.route_id,
      root_tab_id: entry.root_tab_id,
      presentation: entry.presentation,
      parent_route_id: entry.parent_route_id,
      deep_link_posture: entry.deep_link_posture,
      restoration_posture: entry.restoration_posture
    }

  defp ordered(topology),
    do: %{
      topology_schema_version: topology.topology_schema_version,
      manifest_schema_version: topology.manifest_schema_version,
      status: topology.status,
      entries: topology.entries
    }

  defp from_inventory(error),
    do: error("NT-ROUTE_INVENTORY", error.route_ref || "unresolved", error.field || "route_row")

  defp error(rule_id, route_ref, field),
    do: %CompileError{
      rule_id: rule_id,
      route_ref: route_ref,
      field: field,
      message:
        "#{rule_id}: route #{route_ref}, field #{field}; remediation: provide a closed sanitized topology value"
    }
end
