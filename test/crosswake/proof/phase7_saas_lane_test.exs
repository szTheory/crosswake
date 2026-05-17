defmodule Crosswake.Proof.Phase7SaaSLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest

  @saas_routes %{
    "saas-dashboard" => "/saas/dashboard",
    "saas-account" => "/saas/accounts/:id",
    "saas-approvals" => "/saas/approvals",
    "saas-approval" => "/saas/approvals/:id",
    "saas-profile-settings" => "/saas/settings/profile"
  }

  test "shared example host exposes exactly the locked SaaS route set under /saas" do
    Code.require_file(Path.expand("examples/phoenix_host/lib/crosswake_example/router.ex", File.cwd!()))

    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    saas_routes =
      manifest.routes
      |> Enum.filter(fn {_id, route} -> String.starts_with?(route.path, "/saas") end)
      |> Enum.into(%{})

    assert Map.keys(saas_routes) |> Enum.sort() == Map.keys(@saas_routes) |> Enum.sort()

    for {route_id, path} <- @saas_routes do
      assert saas_routes[route_id].path == path
    end
  end

  test "all SaaS routes stay live_view-owned inside one shared defaults posture" do
    Code.require_file(Path.expand("examples/phoenix_host/lib/crosswake_example/router.ex", File.cwd!()))

    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    for route_id <- Map.keys(@saas_routes) do
      route = manifest.routes[route_id]

      assert route.runtime == :live_view
      assert route.offline == :cached_read_only
      assert route.security == :standard
    end
  end

  test "the SaaS lane does not drift into packs, transfers, offline islands, or native screens" do
    Code.require_file(Path.expand("examples/phoenix_host/lib/crosswake_example/router.ex", File.cwd!()))

    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    for route_id <- Map.keys(@saas_routes) do
      route = manifest.routes[route_id]

      assert route.runtime != :native_screen
      assert route.runtime != :offline_island
      assert route.packs == []
      assert route.transfers == []
    end
  end
end
