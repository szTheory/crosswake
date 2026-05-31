defmodule Crosswake.OperatorInspection.Formatter do
  @moduledoc """
  Human-readable formatter for route-authoritative operator inspection documents.
  """

  alias Crosswake.OperatorInspection.Types

  @spec render(Types.Document.t()) :: String.t()
  def render(%Types.Document{} = document) do
    [
      "Crosswake operator inspection",
      "schema_version: #{document.schema_version}",
      "crosswake_version: #{document.crosswake_version}",
      "generated_at: #{document.generated_at}",
      "summary: routes=#{document.summary.route_count} verification_required=#{document.summary.verification_required_count} rebuild_required=#{document.summary.rebuild_required_count} blocking=#{document.summary.blocking_count}",
      format_source(document.source),
      format_routes(document.routes),
      format_findings(document.findings)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_source(source) do
    "source: manifest_schema_version=#{source.manifest_schema_version} bridge_protocol_version=#{source.bridge_protocol_version} native_runtime_version=#{source.native_runtime_version}"
  end

  defp format_routes(routes) do
    lines =
      routes
      |> Enum.sort_by(fn {route_id, _route} -> route_id end)
      |> Enum.map(fn {_route_id, route} ->
        [
          "  #{route.id} #{route.path} runtime=#{route.runtime} owner=#{route.ownership.owner_plane} support=#{route.support.status} proof=#{route.support.proof_class}",
          "    offline=#{route.offline.mode} cache_contract=#{yes_no(route.offline.cache_contract)} island_contract=#{yes_no(route.offline.island_contract)}",
          format_route_capabilities(route),
          format_route_commerce(route),
          format_route_companion(route),
          format_route_auth(route),
          format_route_notifications(route),
          format_route_rebuild(route),
          format_route_denials(route)
        ]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join("\n")
      end)

    ["routes:" | lines] |> Enum.join("\n")
  end

  defp format_route_capabilities(%{capabilities: []}), do: nil

  defp format_route_capabilities(route) do
    capabilities =
      route.capabilities
      |> Enum.map_join(", ", fn capability ->
        "#{capability["id"]}(owner=#{capability["owner"]}, proof=#{capability["proof_class"]}, rebuild=#{capability["rebuild"]})"
      end)

    "    capabilities: #{capabilities}"
  end

  defp format_route_commerce(%{commerce: nil}), do: nil

  defp format_route_commerce(route) do
    commerce = route.commerce

    "    commerce: corridor=#{commerce.corridor_ref} role=#{commerce.role} owner=#{commerce.owner_posture} advisory_provider_proof=#{yes_no(commerce.advisory_provider_proof)}"
  end

  defp format_route_companion(%{companion: %{gated_by: nil}}), do: nil

  defp format_route_companion(route) do
    companion = route.companion

    "    companion: gated_by=#{companion.gated_by} gate_state=#{companion.gate_state || "none"} dependency=#{companion.dependency_status}"
  end

  defp format_route_auth(%{auth: %{fallback: nil}}), do: nil

  defp format_route_auth(route) do
    auth = route.auth

    "    auth: min_level=#{auth.auth_min_level || "none"} recent=#{auth.requires_recent_auth || "none"} readiness=#{auth.readiness} fallback=#{auth.fallback}"
  end

  defp format_route_notifications(%{notifications: %{token_capability_declared: false}}), do: nil

  defp format_route_notifications(route) do
    notifications = route.notifications

    "    notifications: token=#{yes_no(notifications.token_capability_declared)} provider_readiness=#{notifications.provider_readiness} delivery_supported=#{yes_no(notifications.delivery_supported)}"
  end

  defp format_route_rebuild(%{rebuild: %{native_required: false, companion_required: false}}),
    do: nil

  defp format_route_rebuild(route) do
    rebuild = route.rebuild
    reasons = if rebuild.reasons == [], do: "none", else: Enum.join(rebuild.reasons, "; ")

    "    rebuild: native=#{yes_no(rebuild.native_required)} companion=#{yes_no(rebuild.companion_required)} reasons=#{reasons}"
  end

  defp format_route_denials(%{denials: []}), do: nil
  defp format_route_denials(route), do: "    denials: #{Enum.join(route.denials, ", ")}"

  defp format_findings([]), do: nil

  defp format_findings(findings) do
    lines =
      findings
      |> Enum.sort_by(&{&1.severity, &1.code})
      |> Enum.map(fn finding ->
        "  #{finding.severity} #{finding.code}: #{finding.message}"
      end)

    ["findings:" | lines] |> Enum.join("\n")
  end

  defp yes_no(true), do: "yes"
  defp yes_no(false), do: "no"
  defp yes_no(nil), do: "no"
  defp yes_no(value), do: value
end
