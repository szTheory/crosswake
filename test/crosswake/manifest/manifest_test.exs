Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.ManifestTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  test "manifest compilation from a managed router yields one route-first artifact keyed by route id" do
    assert {:ok, %{manifest: manifest, warnings: []}} = Manifest.compile(ManagedRouter)

    assert Map.keys(manifest.routes) == ["camera", "dashboard", "library", "study-session"]
    assert manifest.routes["dashboard"].path == "/dashboard"
    assert manifest.routes["library"].offline == :cached_read_only
    assert manifest.routes["study-session"].offline == :local_first
    assert manifest.routes["camera"].runtime == :native_screen
  end

  test "cached routes expose explicit cache-contract truth in the manifest" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    route = manifest.routes["library"]

    assert route.offline == :cached_read_only
    assert route.cache_contract.id == "lesson_library_v1"
    assert route.cache_contract.staleness == :best_effort
    assert route.cache_contract.hydration == :sqlite_snapshot
    assert route.cache_contract.storage == :sqlite
    assert route.cache_contract.restrictions == [:read_only, :server_authoritative]
    assert is_nil(route.island_contract)
  end

  test "offline islands expose explicit island-contract truth in the manifest" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    route = manifest.routes["study-session"]

    assert route.runtime == :offline_island
    assert route.offline == :local_first
    assert is_nil(route.cache_contract)
    assert route.island_contract.id == "study_session_v1"
    assert route.island_contract.storage == :sqlite
    assert route.island_contract.draft_surface == :study_session_draft
    assert route.island_contract.journal_mode == :append_only
    assert route.island_contract.reconciliation == :explicit
    assert route.island_contract.checkpoint_requirement == :required
    assert route.island_contract.authoritative_source == :phoenix
    assert route.island_contract.sync_seam == "study_reviews"
  end

  test "top-level manifest includes host, compatibility, support matrix, capability registry, and routes" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    assert manifest.manifest_schema_version == "1.0.0"
    assert manifest.crosswake_version == "0.1.0"
    assert manifest.host.manifest_sources == [:bundled, :cached, :remote]
    assert manifest.compatibility.bridge_protocol_version == "1.0.0"
    assert Map.has_key?(manifest.capability_registry, "camera")
    assert Map.has_key?(manifest.capability_registry, "media_capture")
    assert Map.has_key?(manifest.pack_registry, "camera_capture_assets@1.0.0")
    assert Map.has_key?(manifest.pack_registry, "lesson_library@1.2.0")
    assert manifest.support_matrix.phoenix != []
    assert manifest.support_matrix.capability_families != []
  end

  test "manifest capability registry exposes typed family metadata and compatibility aliases" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    media_capture = manifest.capability_registry["media_capture"]
    camera = manifest.capability_registry["camera"]

    assert media_capture.family == "media_capture"
    assert media_capture.owner == :native_screen
    assert media_capture.package_class == :companion
    assert media_capture.proof_class == :merge_blocking
    assert media_capture.rebuild == :native_required
    assert media_capture.legacy_ids == ["camera", "camera.capture"]

    assert camera.family == "media_capture"
    assert camera.guide == "guides/native_shell.md#native-capture-escape-hatch"
  end

  test "manifest root exposes a canonical typed pack registry keyed by immutable id and version" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    assert Map.keys(manifest.pack_registry) ==
             [
               "camera_capture_assets@1.0.0",
               "lesson_library@1.2.0",
               "study_session_media@3.0.0"
             ]

    assert manifest.pack_registry["lesson_library@1.2.0"] ==
             Types.new_pack_entry(id: "lesson_library", version: "1.2.0", kind: :content)
  end

  test "route entries reference pack registry items instead of duplicating pack metadata payloads" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    assert manifest.routes["library"].packs == ["lesson_library@1.2.0"]
    assert manifest.routes["study-session"].packs == ["study_session_media@3.0.0"]
    assert manifest.routes["camera"].packs == ["camera_capture_assets@1.0.0"]
  end

  test "manifest routes expose typed versioned transfer seam truth per route" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    library_transfers = manifest.routes["library"].transfers
    camera_transfers = manifest.routes["camera"].transfers

    assert Enum.map(library_transfers, & &1.id) == [
             "lesson_import",
             "lesson_export",
             "lesson_download"
           ]

    assert Enum.map(library_transfers, & &1.protocol) == [
             "crosswake.transfer",
             "crosswake.transfer",
             "crosswake.transfer"
           ]

    assert Enum.map(library_transfers, & &1.version) == ["1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(library_transfers, & &1.intent) == [:import, :export, :download]
    assert Enum.map(library_transfers, & &1.states) ==
             List.duplicate(Crosswake.Transfer.Contracts.transfer_states(), 3)

    assert camera_transfers == [
             Types.new_transfer_seam(
               id: "capture_upload",
               intent: :upload,
               direction: :inbound,
               source: :native_capture,
               verification: :required,
               media_types: ["image/*"]
             )
           ]
  end
  test "manifest capability registry includes normalized commerce vocabulary" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    assert %{
             owner: :backend_seam,
             family: "paywall_entry",
             package_class: :example_docs_only
           } = manifest.capability_registry["paywall_entry"]

    assert %{
             owner: :backend_seam,
             family: "purchase_intent",
             package_class: :example_docs_only
           } = manifest.capability_registry["purchase_intent"]

    assert %{
             owner: :backend_seam,
             family: "restore_intent",
             package_class: :example_docs_only
           } = manifest.capability_registry["restore_intent"]

    assert %{
             owner: :backend_seam,
             family: "entitlement_snapshot",
             package_class: :example_docs_only
           } = manifest.capability_registry["entitlement_snapshot"]

    assert %{
             owner: :backend_seam,
             family: "reconciliation_evidence",
             package_class: :example_docs_only
           } = manifest.capability_registry["reconciliation_evidence"]
  end
end
