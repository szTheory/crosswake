
defmodule Crosswake.ManifestTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types
  alias Crosswake.Policy.CorridorProfiles
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

  test "manifest keeps schema 1.0.0 while commerce corridor fields remain additive" do
    assert {:ok, %{manifest: baseline_manifest}} = Manifest.compile(ManagedRouter)

    assert baseline_manifest.manifest_schema_version == "1.0.0"
    assert baseline_manifest.commerce_corridors == %{}
    assert Enum.all?(baseline_manifest.routes, fn {_id, route} -> is_nil(route.commerce) end)

    assert {:ok, %{manifest: commerce_manifest}} =
             Manifest.compile([
               route("/paywall",
                 helper: "paywall",
                 crosswake: [
                   id: "paywall",
                   runtime: :live_view,
                   security: :standard,
                   commerce: [corridor: :subscription_default, role: :paywall_entry]
                 ]
               )
             ])

    assert commerce_manifest.manifest_schema_version == "1.0.0"
    assert Map.has_key?(commerce_manifest.commerce_corridors, "subscription_default")
    assert commerce_manifest.routes["paywall"].commerce.corridor_ref == "subscription_default"
    assert commerce_manifest.routes["paywall"].commerce.role == :paywall_entry
  end

  test "manifest capability registry exposes typed family metadata and compatibility aliases" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    file_picker = manifest.capability_registry["file_picker"]
    media_capture = manifest.capability_registry["media_capture"]
    camera = manifest.capability_registry["camera"]
    notification_token = manifest.capability_registry["notification_token"]

    assert file_picker.family == "file_picker"
    assert file_picker.owner == :bounded_bridge
    assert file_picker.package_class == :core
    assert file_picker.proof_class == :merge_blocking
    assert file_picker.rebuild == :native_required
    assert file_picker.prerequisites == [
             "declared transfer_id",
             "bounded bridge support",
             "inbound native_picker transfer seam",
             "copy-first staged handle plus transfer verification"
           ]
    assert file_picker.denial == "undeclared_capability"
    assert file_picker.fallback ==
             "keep the route on Phoenix-owned import guidance until a copy-first native_picker seam is declared and verified"
    assert file_picker.legacy_ids == ["files.pick"]

    assert media_capture.family == "media_capture"
    assert media_capture.owner == :native_screen
    assert media_capture.package_class == :companion
    assert media_capture.proof_class == :merge_blocking
    assert media_capture.rebuild == :native_required
    assert media_capture.legacy_ids == ["camera", "camera.capture"]

    assert camera.family == "media_capture"
    assert camera.guide == "guides/native_shell.md#native-capture-escape-hatch"

    assert notification_token.family == "notification_token"
    assert notification_token.owner == :bounded_bridge
    assert notification_token.package_class == :companion
    assert notification_token.rebuild == :companion_required
    assert notification_token.prerequisites == [
             "declared route capability",
             "bounded bridge support",
             "notification authorization already resolved",
             "provider token snapshot available"
           ]
    assert notification_token.denial == "unavailable_capability"
    assert notification_token.fallback ==
             "treat notification token replies as provider-tagged evidence instead of backend registration truth"
    assert notification_token.legacy_ids == ["push.notifications"]
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
             "lesson_upload_prepare",
             "lesson_export",
             "lesson_download"
           ]

    assert Enum.map(library_transfers, & &1.protocol) ==
             List.duplicate("crosswake.transfer", 4)

    assert Enum.map(library_transfers, & &1.version) == ["1.0.0", "1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(library_transfers, & &1.intent) == [:import, :upload, :export, :download]
    assert Enum.map(Enum.take(library_transfers, 2), & &1.source) == [:native_picker, :native_picker]
    assert Enum.map(Enum.take(library_transfers, 2), & &1.verification) == [:required, :required]
    assert Enum.map(library_transfers, & &1.states) ==
             List.duplicate(Crosswake.Transfer.Contracts.transfer_states(), 4)

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
             package_class: :core
           } = manifest.capability_registry["paywall_entry"]

    assert %{
             owner: :backend_seam,
             family: "purchase_intent",
             package_class: :core
           } = manifest.capability_registry["purchase_intent"]

    assert %{
             owner: :backend_seam,
             family: "restore_intent",
             package_class: :core
           } = manifest.capability_registry["restore_intent"]

    assert %{
             owner: :backend_seam,
             family: "entitlement_snapshot",
             package_class: :core
           } = manifest.capability_registry["entitlement_snapshot"]

    assert %{
             owner: :backend_seam,
             family: "reconciliation_evidence",
             package_class: :core
           } = manifest.capability_registry["reconciliation_evidence"]
  end

  test "manifest links canonical profile definitions through root commerce_corridors and route corridor_ref entries" do
    canonical = CorridorProfiles.commerce_corridors()["subscription_default"]

    assert {:ok, %{manifest: manifest}} =
             Manifest.compile([
               route("/paywall",
                 helper: "paywall",
                 crosswake: [
                   id: "paywall",
                   runtime: :live_view,
                   security: :standard,
                   commerce: [corridor: :subscription_default, role: :paywall_entry]
                 ]
               )
             ])

    assert manifest.commerce_corridors["subscription_default"].id == canonical.id
    assert manifest.commerce_corridors["subscription_default"].denial == canonical.denial
    assert manifest.commerce_corridors["subscription_default"].fallback == canonical.fallback
    assert manifest.routes["paywall"].commerce.corridor_ref == "subscription_default"
    assert manifest.routes["paywall"].commerce.role == :paywall_entry
    assert Types.to_map(manifest)["commerce_corridors"]["subscription_default"]["id"] == "subscription_default"
    assert Types.to_map(manifest)["routes"]["paywall"]["commerce"]["corridor_ref"] == "subscription_default"
  end

  defp route(path, opts) do
    metadata =
      case Keyword.fetch(opts, :crosswake) do
        {:ok, crosswake} -> %{crosswake: crosswake}
        :error -> %{}
      end

    %{
      path: path,
      metadata: metadata,
      helper: Keyword.get(opts, :helper, "route"),
      verb: Keyword.get(opts, :verb, :get)
    }
  end
end
