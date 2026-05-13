defmodule Crosswake.Policy.RouteTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route

  describe "new/1" do
    test "normalizes omitted defaults" do
      assert {:ok, route} = Route.new(id: "inbox", runtime: :live_view)

      assert route.id == "inbox"
      assert route.runtime == :live_view
      assert route.offline == :unavailable
      assert route.capabilities == []
      assert route.packs == []
      assert route.sync == []
    end

    test "accepts the phase 1 public runtime taxonomy" do
      for runtime <- [:live_view, :offline_island, :native_screen] do
        assert {:ok, route} = Route.new(id: Atom.to_string(runtime), runtime: runtime)
        assert route.runtime == runtime
      end
    end
  end
end
