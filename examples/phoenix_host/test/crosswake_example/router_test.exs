defmodule CrosswakeExample.RouterTest do
  use ExUnit.Case, async: true

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
end
