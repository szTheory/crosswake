defmodule Crosswake.Manifest.Builder do
  @moduledoc """
  Builds the route-first manifest root from compiled Crosswake route policy.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Offline.Contracts
  alias Crosswake.Policy.Route

  @spec build([Route.t()], [map()], keyword()) :: Types.Root.t()
  def build(routes, managed_routes, opts \\ [])
      when is_list(routes) and is_list(managed_routes) do
    host =
      Keyword.get_lazy(opts, :host, fn ->
        case Keyword.fetch(opts, :origin) do
          {:ok, origin} -> Types.new_host(origin: origin)
          :error -> Types.new_host()
        end
      end)

    compatibility = Keyword.get(opts, :compatibility, Types.new_compatibility())
    support_matrix = Keyword.get(opts, :support_matrix, Crosswake.SupportMatrix.canonical())

    Types.new_root(
      crosswake_version:
        Keyword.get(opts, :crosswake_version, Mix.Project.config()[:version] || "dev"),
      generated_at:
        Keyword.get(
          opts,
          :generated_at,
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
        ),
      host: host,
      compatibility: compatibility,
      support_matrix: support_matrix,
      capability_registry: capability_registry(routes),
      routes: route_entries(routes, managed_routes, host.origin)
    )
  end

  defp capability_registry(routes) do
    routes
    |> Enum.flat_map(& &1.capabilities)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn capability ->
      {capability, Types.new_capability(id: capability, version: capability_version(capability))}
    end)
  end

  defp route_entries(routes, managed_routes, origin) do
    routes
    |> Enum.zip(managed_routes)
    |> Map.new(fn {%Route{} = route, managed_route} ->
      path = Map.fetch!(managed_route, :path)

      entry =
        Types.new_route_entry(
          id: route.id,
          path: path,
          runtime: route.runtime,
          offline: route.offline,
          cache_contract: cache_contract(route),
          island_contract: island_contract(route),
          capabilities: route.capabilities,
          packs: route.packs,
          sync: route.sync,
          security: route.security,
          allowlisted_origins: [origin]
        )

      {route.id, entry}
    end)
  end

  defp capability_version(_capability), do: "1.0.0"

  defp cache_contract(%Route{cache_contract: nil}), do: nil

  defp cache_contract(%Route{id: route_id, cache_contract: contract_id}) do
    contract_id
    |> Contracts.new_cache_route(route_id: route_id)
    |> Contracts.cache_contract()
  end

  defp island_contract(%Route{island_contract: nil}), do: nil

  defp island_contract(%Route{id: route_id, island_contract: contract_id, sync: [sync_seam | _rest]}) do
    contract_id
    |> Contracts.new_study_session_island(route_id: route_id, sync_seam: sync_seam)
    |> Contracts.island_contract()
  end

  defp island_contract(%Route{id: route_id, island_contract: contract_id}) do
    contract_id
    |> Contracts.new_study_session_island(route_id: route_id, sync_seam: contract_id)
    |> Contracts.island_contract()
  end
end
