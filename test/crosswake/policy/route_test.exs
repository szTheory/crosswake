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

    test "normalizes representative security and list-valued fields" do
      assert {:ok, route} =
               Route.new(
                 id: :capture,
                 runtime: :native_screen,
                 capabilities: [:camera, "photos"],
                 packs: [:media_core],
                 sync: [:uploads],
                 security: :sensitive
               )

      assert route.id == "capture"
      assert route.capabilities == ["camera", "photos"]
      assert route.packs == ["media_core"]
      assert route.sync == ["uploads"]
      assert route.security == :sensitive
    end
  end
end
