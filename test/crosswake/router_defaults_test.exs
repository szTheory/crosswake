
defmodule Crosswake.RouterDefaultsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.RouterMetadata
  alias Crosswake.TestSupport.RouterFixtures.DefaultsRouter

  test "scope defaults fill secondary policy axes without replacing route ownership" do
    policy = route_policy!(DefaultsRouter, "/reader")

    assert %Route{
             id: "reader",
             runtime: :live_view,
             offline: :cached_read_only,
             capabilities: ["notification_token"],
             packs: [%{id: "core_content", version: "1.0.0", kind: :content, integrity: nil}],
             sync: ["catalog"],
             security: :standard
           } = policy
  end

  test "route-local values override nested scope defaults deterministically" do
    policy = route_policy!(DefaultsRouter, "/capture")

    assert %Route{
             id: "capture",
             runtime: :native_screen,
             offline: :local_first,
             capabilities: ["media_capture"],
             packs: [%{id: "capture_pack", version: "1.0.0", kind: :media, integrity: nil}],
             sync: ["uploads"],
             security: :sensitive
           } = policy
  end

  test "unmanaged routes stay structurally untouched while incremental adoption remains allowed" do
    route = route_by_path!(DefaultsRouter, "/public")

    refute Map.has_key?(route.metadata, :crosswake)
    refute Map.has_key?(route.metadata, :crosswake_policy)
    assert :error == RouterMetadata.fetch(route.metadata)
  end

  defp route_policy!(router, path) do
    router
    |> route_by_path!(path)
    |> Map.fetch!(:metadata)
    |> RouterMetadata.fetch!()
  end

  defp route_by_path!(router, path) do
    Enum.find(router.__routes__(), &(&1.path == path)) ||
      flunk("expected route #{path} to exist")
  end
end
