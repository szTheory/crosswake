defmodule Crosswake.Policy.RouteTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route

  describe "new/1" do
    test "normalizes omitted defaults" do
      assert {:ok, route} = Route.new(id: "inbox", runtime: :live_view)

      assert route.id == "inbox"
      assert route.runtime == :live_view
      assert route.offline == :unavailable
      assert route.entry == :internal_only
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
                 packs: [[id: :media_core, version: "1.0.0", kind: :content]],
                 sync: [:uploads],
                 security: :sensitive
               )

      assert route.id == "capture"
      assert route.capabilities == ["camera", "photos"]
      assert route.packs == [
               %{id: "media_core", version: "1.0.0", kind: :content, integrity: nil}
             ]
      assert route.sync == ["uploads"]
      assert route.security == :sensitive
    end

    test "accepts one or more semantic pack requirements with immutable ids and versions" do
      assert {:ok, route} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 cache_contract: :lesson_library_v1,
                 packs: [
                   [
                     id: "lesson_library",
                     version: "1.2.0",
                     kind: :content,
                     integrity: [algorithm: :sha256, digest: "sha256-abc123"]
                   ],
                   [id: :pronunciation_audio, version: "2.0.0", kind: :media]
                 ],
                 security: :standard
               )

      assert route.packs == [
               %{
                 id: "lesson_library",
                 version: "1.2.0",
                 kind: :content,
                 integrity: %{algorithm: "sha256", digest: "sha256-abc123"}
               },
               %{id: "pronunciation_audio", version: "2.0.0", kind: :media, integrity: nil}
             ]
    end

    test "cached routes can declare an explicit cache contract without implying local mutation support" do
      assert {:ok, route} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 entry: :external,
                 cache_contract: :lesson_library_v1,
                 security: :standard
               )

      assert route.offline == :cached_read_only
      assert route.entry == :external
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

    test "rejects duplicate pack ids so route-local pack truth stays unambiguous" do
      assert {:error, error} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 cache_contract: :lesson_library_v1,
                 packs: [
                   [id: "lesson_library", version: "1.2.0", kind: :content],
                   [id: "lesson_library", version: "2.0.0", kind: :content]
                 ],
                 security: :standard
               )

      assert Exception.message(error) =~ "pack ids must be unique"
    end

    test "rejects external entry on offline-island routes" do
      assert {:error, error} =
               Route.new(
                 id: "study-session",
                 runtime: :offline_island,
                 offline: :local_first,
                 entry: :external,
                 island_contract: "study_session_v1",
                 sync: ["study_reviews"],
                 security: :standard
               )

      assert Exception.message(error) =~ "entry :external is not supported on offline_island routes"
    end

    test "normalizes explicit route-local transfer seams for upload, download, import, and export" do
      assert {:ok, route} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 cache_contract: :lesson_library_v1,
                 security: :standard,
                 transfers: [
                   [
                     id: :asset_upload,
                     intent: :upload,
                     source: :native_picker,
                     verification: :required,
                     media_types: ["image/*"]
                   ],
                   [
                     id: :asset_download,
                     intent: :download,
                     destination: :app_sandbox,
                     verification: :required,
                     media_types: ["application/pdf"]
                   ],
                   [
                     id: :asset_import,
                     intent: :import,
                     source: :native_picker,
                     verification: :required,
                     media_types: ["application/zip"]
                   ],
                   [
                     id: :asset_export,
                     intent: :export,
                     destination: :user_visible_files,
                     verification: :required,
                     media_types: ["text/csv"]
                   ]
                 ]
               )

      assert Enum.map(route.transfers, & &1.intent) == [:upload, :download, :import, :export]
      assert Enum.map(route.transfers, & &1.direction) == [:inbound, :outbound, :inbound, :outbound]
    end

    test "rejects ambiguous or runtime-inconsistent transfer declarations" do
      assert {:error, error} =
               Route.new(
                 id: "capture",
                 runtime: :native_screen,
                 security: :sensitive,
                 transfers: [
                   [
                     id: :capture_upload,
                     intent: :upload,
                     source: :native_capture,
                     destination: :user_visible_files,
                     verification: :required,
                     media_types: ["image/*"]
                   ]
                 ]
               )

      assert Exception.message(error) =~ "must not declare destination"

      assert {:error, error} =
               Route.new(
                 id: "library",
                 runtime: :live_view,
                 security: :standard,
                 transfers: [
                   [
                     id: :capture_only_upload,
                     intent: :upload,
                     source: :native_capture,
                     verification: :required,
                     media_types: ["image/*"]
                   ]
                 ]
               )

      assert Exception.message(error) =~ "native_capture source requires runtime :native_screen"
    end
  end
end
