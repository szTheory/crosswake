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

    test "cached routes can declare an explicit cache contract without implying local mutation support" do
      assert {:ok, route} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 cache_contract: :lesson_library_v1,
                 security: :standard
               )

      assert route.offline == :cached_read_only
      assert Map.get(route, :cache_contract) == "lesson_library_v1"
      assert Map.get(route, :island_contract) == nil
    end

    test "offline-island routes can declare an explicit island contract without changing the runtime taxonomy" do
      assert {:ok, route} =
               Route.new(
                 id: "study-session",
                 runtime: :offline_island,
                 offline: :local_first,
                 island_contract: "study_session_v1",
                 sync: ["study_reviews"],
                 security: :standard
               )

      assert route.runtime == :offline_island
      assert route.offline == :local_first
      assert Map.get(route, :cache_contract) == nil
      assert Map.get(route, :island_contract) == "study_session_v1"
    end

    test "rejects cache-only and island-only contract metadata on the wrong offline posture" do
      assert {:error, error} =
               Route.new(
                 id: "study-session",
                 runtime: :offline_island,
                 offline: :local_first,
                 cache_contract: "lesson_library_v1",
                 security: :standard
               )

      assert Exception.message(error) =~
               "cache_contract requires offline :cached_read_only and does not belong on local-first routes"

      assert {:error, error} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 island_contract: "study_session_v1",
                 security: :standard
               )

      assert Exception.message(error) =~
               "island_contract requires runtime :offline_island with offline :local_first"
    end
  end
end
