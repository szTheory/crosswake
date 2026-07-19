defmodule CrosswakeExample.LearnLoop.Diagnostics do
  @moduledoc """
  Lane-local LearnLoop route policy diagnostics.

  Compiled router metadata is the source of truth for route ownership. LearnLoop
  fixture data layers support copy and capability pressure without creating a
  URL-addressable diagnostics surface.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.LearnLoop.Fixtures
  alias CrosswakeExample.Router
  alias CrosswakeExample.Showcase.Catalog

  @route_ids [
    "learnloop-dashboard",
    "learnloop-course",
    "learnloop-pack",
    "learnloop-study-session",
    "learnloop-history",
    "learnloop-subscription"
  ]

  @guide_links [
    %{label: "Route policy guide", path: "guides/route_policy.md"},
    %{label: "Offline guide", path: "guides/offline.md"},
    %{label: "Commerce guide", path: "guides/commerce.md"},
    %{label: "Support matrix", path: "guides/support_matrix.md"},
    %{label: "Capability families", path: "guides/capabilities.md"}
  ]

  @row_guide_links %{
    live_view: ["guides/route_policy.md", "guides/support_matrix.md", "guides/offline.md"],
    offline_island: [
      "guides/route_policy.md",
      "guides/offline.md",
      "guides/support_matrix.md",
      "guides/capabilities.md"
    ],
    entitlement: [
      "guides/route_policy.md",
      "guides/commerce.md",
      "guides/support_matrix.md",
      "guides/capabilities.md"
    ]
  }

  @support_categories %{
    "learnloop-dashboard" => "Demo pressure",
    "learnloop-course" => "Demo pressure",
    "learnloop-pack" => "Demo pressure",
    "learnloop-study-session" => "Proof-backed example",
    "learnloop-history" => "Demo pressure",
    "learnloop-subscription" => "Demo pressure"
  }

  @lane_visible_labels [
    "LiveView route",
    "Cached read-only",
    "Offline island",
    "Local-first outbox",
    "Backend projection",
    "Mocked storefront evidence"
  ]

  @spec route_ids() :: [String.t()]
  def route_ids, do: @route_ids

  @spec allowed_support_labels() :: [String.t()]
  def allowed_support_labels, do: Catalog.allowed_support_labels()

  @spec guide_links() :: [map()]
  def guide_links, do: @guide_links

  @spec route_policy_rows(module()) :: [map()]
  def route_policy_rows(router \\ Router) do
    router
    |> compiled_learnloop_routes()
    |> Enum.sort_by(fn %{policy: policy} ->
      Enum.find_index(@route_ids, &(&1 == policy.id)) || length(@route_ids)
    end)
    |> Enum.map(&route_row/1)
  end

  @spec capability_pressure_rows() :: [map()]
  def capability_pressure_rows do
    fixture_pressure = Map.new(Fixtures.capability_pressure(), &{&1.id, &1})

    [
      pressure_row(
        :content_pack,
        "learnloop-pack",
        "Demo pressure",
        "example/docs-only",
        "demo pressure",
        pressure_summary(fixture_pressure, "pressure-content-pack")
      ),
      pressure_row(
        :offline_study,
        "learnloop-study-session",
        "Proof-backed example",
        "example/docs-only",
        "shipped proof-backed example",
        pressure_summary(fixture_pressure, "pressure-local-first-study")
      ),
      pressure_row(
        :sync_reconciliation,
        "learnloop-study-session",
        "Proof-backed example",
        "example/docs-only",
        "shipped proof-backed example",
        "Review-event outbox replays through the existing append-only sync seam."
      ),
      pressure_row(
        :entitlement_projection,
        "learnloop-subscription",
        "Demo pressure",
        "example/docs-only",
        "backend projection evidence",
        "Backend entitlement projection remains the access authority for gated lessons."
      ),
      pressure_row(
        :native_storage_pressure,
        "learnloop-study-session",
        "Future gap",
        "deferred",
        "next-pack candidate",
        pressure_summary(fixture_pressure, "pressure-native-storage")
      ),
      pressure_row(
        :commerce_paywall_pressure,
        "learnloop-subscription",
        "Future gap",
        "deferred",
        "deferred productionization",
        pressure_summary(fixture_pressure, "pressure-commerce-paywall")
      )
    ]
  end

  defp compiled_learnloop_routes(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.flat_map(fn route ->
      with true <- String.starts_with?(route.path, "/learnloop"),
           {:ok, policy} <- RouterMetadata.fetch(route.metadata),
           true <- policy.id in @route_ids do
        [%{route: route, policy: policy}]
      else
        _other -> []
      end
    end)
  end

  defp route_row(%{route: route, policy: policy}) do
    posture = route_posture!(policy.id)
    findings = support_findings_for(policy.id)

    %{
      route_id: policy.id,
      path: route.path,
      runtime_owner: policy.runtime,
      runtime_owner_label: runtime_owner_label(policy.runtime),
      offline_posture: policy.offline,
      offline_posture_label: offline_posture_label(policy.offline),
      security_posture: policy.security,
      security_posture_label: security_posture_label(policy.security),
      capabilities: policy.capabilities,
      capability_labels: capability_labels(policy.capabilities),
      packs: policy.packs,
      pack_labels: pack_labels(policy.packs),
      transfers: policy.transfers,
      transfer_labels: transfer_labels(policy.transfers),
      support_label: Map.fetch!(@support_categories, policy.id),
      support_findings: findings,
      lane_visible_labels: @lane_visible_labels,
      visible_labels: visible_labels(policy, posture, findings),
      badge_label: posture.badge_label,
      rough_edge: posture.rough_edge,
      guide_links: guide_links_for(policy.id)
    }
  end

  defp pressure_row(capability, route_id, support_label, package_owner, proof_posture, rough_edge) do
    %{
      capability: capability,
      route_id: route_id,
      runtime_owner: route_posture!(route_id).runtime_owner,
      support_label: support_label,
      package_owner: package_owner,
      proof_posture: proof_posture,
      rough_edge: rough_edge,
      guide_links: guide_links_for(route_id)
    }
  end

  defp pressure_summary(fixture_pressure, id) do
    fixture_pressure
    |> Map.fetch!(id)
    |> Map.fetch!(:summary)
  end

  defp route_posture!(route_id) do
    Fixtures.route_postures()
    |> Enum.find(&(&1.route_id == route_id))
    |> case do
      nil -> raise ArgumentError, "unknown LearnLoop route posture: #{inspect(route_id)}"
      posture -> posture
    end
  end

  defp support_findings_for(route_id) do
    Fixtures.support_findings()
    |> Enum.filter(&(&1.route_id == route_id))
  end

  defp guide_links_for("learnloop-study-session"), do: @row_guide_links.offline_island
  defp guide_links_for("learnloop-subscription"), do: @row_guide_links.entitlement
  defp guide_links_for(_route_id), do: @row_guide_links.live_view

  defp runtime_owner_label(:live_view), do: "LiveView route"
  defp runtime_owner_label(:offline_island), do: "Offline island"
  defp runtime_owner_label(runtime), do: humanize_atom(runtime)

  defp offline_posture_label(:cached_read_only), do: "Cached read-only"
  defp offline_posture_label(:local_first), do: "Local-first outbox"
  defp offline_posture_label(offline), do: humanize_atom(offline)

  defp security_posture_label(:sensitive), do: "Sensitive route"
  defp security_posture_label(:standard), do: "Standard route"
  defp security_posture_label(security), do: humanize_atom(security)

  defp capability_labels([]), do: ["No native capability required"]
  defp capability_labels(capabilities), do: Enum.map(capabilities, &to_string/1)

  defp pack_labels([]), do: ["No content pack declared"]

  defp pack_labels(packs) do
    Enum.map(packs, fn pack ->
      [
        declaration_field(pack, :id),
        declaration_field(pack, :version),
        declaration_field(pack, :kind)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join(" / ")
    end)
  end

  defp transfer_labels([]), do: ["No transfer seam declared"]

  defp transfer_labels(transfers) do
    Enum.map(transfers, fn transfer ->
      [
        declaration_field(transfer, :id),
        declaration_field(transfer, :intent),
        declaration_field(transfer, :source),
        declaration_field(transfer, :verification)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join(" / ")
    end)
  end

  defp visible_labels(policy, posture, findings) do
    [
      runtime_owner_label(policy.runtime),
      offline_posture_label(policy.offline),
      posture.badge_label,
      Enum.map(findings, & &1.label)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp declaration_field(declaration, field) when is_map(declaration),
    do: Map.get(declaration, field)

  defp declaration_field(declaration, field) when is_list(declaration),
    do: Keyword.get(declaration, field)

  defp humanize_atom(nil), do: "Not declared"

  defp humanize_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
