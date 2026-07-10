defmodule CrosswakeExample.Showcase.CatalogTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Showcase.Branding
  alias CrosswakeExample.Showcase.Catalog

  @lane_ids [:saas_admin, :field_service, :learning_training]
  @allowed_support_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]

  @allowed_runtime_labels [
    "LiveView route",
    "Cached read-only",
    "Offline island",
    "Local-first outbox",
    "Native screen",
    "Requires native runtime",
    "Demo pressure",
    "Future native-control candidate",
    "Sensitive route"
  ]

  test "lanes are the three v19 showcase domains in stable order" do
    assert Enum.map(Catalog.lanes(), & &1.id) == @lane_ids
  end

  test "each lane carries its fixed demo app brand metadata" do
    for lane <- Catalog.lanes() do
      assert lane.brand == Branding.brand_for!(lane.id)
      assert lane.brand.id == lane.id
      assert lane.brand.name in ["AdminPilot", "Fieldserv", "LearnLoop"]
      refute lane.brand.name =~ "Crosswake"
    end
  end

  test "every card route id and path exists in compiled Crosswake route metadata" do
    compiled = compiled_route_map()

    for card <- Catalog.cards() do
      route_id = Map.fetch!(card, :primary_route_id)
      path = Map.fetch!(card, :primary_path)

      assert Map.has_key?(compiled, route_id),
             "D-13/D-15: catalog card #{inspect(card.id)} references missing route id #{inspect(route_id)}"

      %{route: route} = Map.fetch!(compiled, route_id)

      assert route.path == path,
             "D-14/D-15: catalog card #{inspect(card.id)} route #{route_id} path drifted; expected #{inspect(route.path)}, got #{inspect(path)}"
    end
  end

  test "learning lane targets the browser-owned offline proof surface" do
    learning_lane = Enum.find(Catalog.lanes(), &(&1.id == :learning_training))

    assert learning_lane.primary_path == "/offline"
    assert learning_lane.primary_route_id == "offline-study"
    assert learning_lane.primary_cta == "Open Offline Study Proof"
  end

  test "card posture matches compiled runtime, offline, security, and capability metadata" do
    compiled = compiled_route_map()

    for card <- Catalog.cards() do
      route_id = Map.fetch!(card, :primary_route_id)
      posture = Map.fetch!(card, :route_posture)
      %{policy: policy} = Map.fetch!(compiled, route_id)

      assert posture.runtime == policy.runtime,
             "D-13/D-15: #{route_id} runtime posture drifted from compiled route metadata"

      assert posture.offline == policy.offline,
             "D-13/D-15: #{route_id} offline posture drifted from compiled route metadata"

      assert posture.security == policy.security,
             "D-13/D-15: #{route_id} security posture drifted from compiled route metadata"

      assert normalized_capabilities(posture.capabilities) ==
               normalized_capabilities(policy.capabilities),
             "D-13/D-15: #{route_id} capability posture drifted from compiled route metadata"
    end
  end

  test "support and runtime labels stay visible, allowlisted, and honest" do
    assert Catalog.allowed_support_labels() == @allowed_support_labels

    for card <- Catalog.cards(), label <- Map.fetch!(card, :support_labels) do
      assert label in @allowed_support_labels,
             "D-16/D-17: #{inspect(card.id)} uses unsupported support-label category #{inspect(label)}"

      refute label =~ ~r/\bsupported\b/i,
             "D-17: #{inspect(card.id)} uses broad support wording #{inspect(label)} instead of the allowed support labels"
    end

    for card <- Catalog.cards(), label <- Map.fetch!(card, :runtime_labels) do
      assert is_binary(label) and label != "",
             "D-16: #{inspect(card.id)} runtime/offline label must be visible text"

      assert label in @allowed_runtime_labels,
             "D-16: #{inspect(card.id)} uses unsupported runtime/offline label #{inspect(label)}"
    end
  end

  defp compiled_route_map do
    CrosswakeExample.Router
    |> Phoenix.Router.routes()
    |> Enum.reduce(%{}, fn route, acc ->
      case RouterMetadata.fetch(route.metadata) do
        {:ok, policy} -> Map.put(acc, policy.id, %{route: route, policy: policy})
        :error -> acc
      end
    end)
  end

  defp normalized_capabilities(capabilities) do
    capabilities
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end
end
