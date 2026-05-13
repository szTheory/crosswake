Code.require_file("../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.RouterTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.RouterMetadata
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  test "managed routes expose normalized crosswake policy on compiled route metadata" do
    route = route_by_path!(ManagedRouter, "/dashboard")

    assert route.metadata.crosswake == [runtime: :live_view, offline: :cached_read_only, security: :standard, id: "dashboard"]
    assert %Route{id: "dashboard", runtime: :live_view, offline: :cached_read_only, security: :standard} =
             RouterMetadata.fetch!(route.metadata)
  end

  test "routes without crosswake metadata remain untouched" do
    route = route_by_path!(ManagedRouter, "/settings")

    refute Map.has_key?(route.metadata, :crosswake)
    refute Map.has_key?(route.metadata, :crosswake_policy)
    assert :error == RouterMetadata.fetch(route.metadata)
  end

  test "all public runtimes round-trip through Phoenix router introspection" do
    assert_route_info("/dashboard", "dashboard", :live_view)
    assert_route_info("/library", "library", :offline_island)
    assert_route_info("/camera", "camera", :native_screen)
  end

  defp assert_route_info(path, id, runtime) do
    info = Phoenix.Router.route_info(ManagedRouter, "GET", path, "example.test")

    assert %Route{id: ^id, runtime: ^runtime} = RouterMetadata.fetch!(info)
    assert info.crosswake_policy.id == id
    assert info.crosswake[:id] == id
  end

  defp route_by_path!(router, path) do
    Enum.find(router.__routes__(), &(&1.path == path)) ||
      flunk("expected route #{path} to exist")
  end
end
