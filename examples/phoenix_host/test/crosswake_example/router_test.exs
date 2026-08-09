defmodule CrosswakeExample.RouterTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.RouterMetadata

  @path "/_e2e/sync-state/:client_mutation_id"

  test "E2E sync-state route present in :test, wired to scoping controller" do
    route =
      CrosswakeExample.Router
      |> Phoenix.Router.routes()
      |> Enum.find(&(&1.path == @path))

    assert route, "expected #{@path} compiled in :test"
    assert route.verb == :get
    assert route.plug == CrosswakeExample.E2E.SyncStateController
    assert route.plug_opts == :show
  end

  test "E2E showcase reset route is present in :test and wired to fixed reset controller" do
    route = route_by_path("/_e2e/showcase-reset")

    assert route, "expected /_e2e/showcase-reset compiled in :test"
    assert route.verb == :post
    assert route.plug == CrosswakeExample.E2E.ShowcaseResetController
    assert route.plug_opts == :create
  end

  test "E2E showcase reset route remains inside the compile-time test/e2e guard" do
    source =
      Path.expand("../../lib/crosswake_example/router.ex", __DIR__)
      |> File.read!()

    assert source =~
             ~r/if Mix\.env\(\) in \[:test, :e2e\] do.*post\("\/showcase-reset", ShowcaseResetController, :create\)/s
  end

  test "E2E undeclared-control route (PROOF-01 A2) is present in :test, wired to the LiveView" do
    route = route_by_path("/_e2e/undeclared-control")

    assert route, "expected /_e2e/undeclared-control compiled in :test"
    assert route.verb == :get
    assert route.plug == Phoenix.LiveView.Plug
    assert route.plug_opts == CrosswakeExample.E2E.UndeclaredControlLive

    {:ok, policy} = RouterMetadata.fetch(route.metadata)
    assert policy.id == "e2e-a2-shell-denial"
    assert policy.capabilities == ["haptics"]
  end

  test "E2E undeclared-control route remains inside the compile-time test/e2e guard" do
    source =
      Path.expand("../../lib/crosswake_example/router.ex", __DIR__)
      |> File.read!()

    assert source =~
             ~r/if Mix\.env\(\) in \[:test, :e2e\] do.*live\("\/undeclared-control", UndeclaredControlLive/s
  end

  test "root route is the Crosswake showcase hub LiveView with cached read-only metadata" do
    route = route_by_path("/")
    {:ok, policy} = RouterMetadata.fetch(route.metadata)

    assert route.verb == :get
    assert route.plug == Phoenix.LiveView.Plug
    assert route.plug_opts == CrosswakeExample.Showcase.HubLive
    assert policy.id == "showcase-hub"
    assert policy.runtime == :live_view
    assert policy.offline == :cached_read_only
    assert policy.security == :standard
  end

  test "legacy proof routes remain reachable after the root showcase replacement" do
    paths =
      CrosswakeExample.Router
      |> Phoenix.Router.routes()
      |> Enum.map(& &1.path)
      |> MapSet.new()

    assert MapSet.member?(paths, "/offline")
    assert MapSet.member?(paths, "/bridge-proof")
    assert MapSet.member?(paths, "/native/claims")
  end

  defp route_by_path(path) do
    CrosswakeExample.Router
    |> Phoenix.Router.routes()
    |> Enum.find(&(&1.path == path))
  end
end
