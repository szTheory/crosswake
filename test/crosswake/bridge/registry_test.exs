defmodule Crosswake.Bridge.RegistryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Bridge.Commands.PermissionsStatus
  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix

  test "registry allows exactly the bounded bridge command set including explicit transfer seams" do
    assert Registry.allowed_commands() == [
             "app.info.get",
             "files.pick",
             "haptics.impact",
             "notifications.token.get",
             "permissions.status",
             "share.invoke",
             "transfer.download",
             "transfer.export",
             "transfer.import",
             "transfer.upload.prepare"
           ]

    assert Registry.command_supported?("app.info.get")
    assert Registry.command_supported?("haptics.impact")
    assert Registry.command_supported?("files.pick")
    assert Registry.command_supported?("notifications.token.get")
    assert Registry.command_supported?("permissions.status")
    assert Registry.command_supported?("transfer.download")
    assert Registry.command_supported?("transfer.export")
    assert Registry.command_supported?("transfer.import")
    assert Registry.command_supported?("transfer.upload.prepare")
    refute Registry.command_supported?("camera.capture")
    refute Registry.command_supported?("clipboard.read")
    refute Registry.command_supported?("share.sheet.present")
  end

  test "registry resolves versions and allowlists from manifest truth" do
    manifest = manifest_fixture()

    assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "haptics.impact")
    assert entry.command == "haptics.impact"
    assert entry.capability == "haptics"
    assert entry.version == "2.3.0"
    assert entry.allowlisted_origins == ["https://shell.crosswake.example"]
  end

  test "registry resolves permissions.status through the bounded capability path" do
    manifest = manifest_fixture()

    assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "permissions.status")
    assert entry.command == "permissions.status"
    assert entry.capability == "permissions.status"
    assert entry.version == "1.0.0"
  end

  test "registry resolves notification_token through manifest-backed capability declarations" do
    manifest = manifest_fixture()

    assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "notifications.token.get")
    assert entry.command == "notifications.token.get"
    assert entry.capability == "notification_token"
    assert entry.version == "1.2.0"
    assert entry.route_id == "dashboard"
  end

  test "registry allowlists transfer commands from route transfer declarations only" do
    manifest = manifest_fixture()

    assert {:ok, entry} = Registry.lookup(manifest, "camera", "transfer.upload.prepare")
    assert entry.command == "transfer.upload.prepare"
    assert entry.capability == "transfer.upload.prepare"
    assert entry.version == "1.0.0"
    assert entry.route_id == "camera"
    assert entry.allowlisted_origins == ["https://shell.crosswake.example"]
  end

  test "registry rejects unsupported commands and undeclared route transfer seams fail closed" do
    manifest = manifest_fixture()

    assert {:error, :unsupported_command} =
             Registry.lookup(manifest, "dashboard", "notifications.push")

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "dashboard", "files.pick")

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "camera", "notifications.token.get")

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "dashboard", "transfer.upload.prepare")

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "camera", "transfer.download")
  end

  test "permissions.status stays narrowed to the notifications alias" do
    assert {:ok, %PermissionsStatus.Request{alias: "notifications"}} =
             PermissionsStatus.new_request(alias: :notifications)

    assert {:error, :unsupported_alias} =
             PermissionsStatus.new_request(alias: "camera")

    response =
      PermissionsStatus.new_response(
        alias: "notifications",
        status: :denied,
        detail: %{"platform_status" => "not_determined"}
      )

    assert response.alias == "notifications"
    assert response.status == :denied
    assert response.detail == %{"platform_status" => "not_determined"}
  end

  test "notification_token request stays prompt-free and response stays provider explicit" do
    assert {:ok, %NotificationToken.Request{}} = NotificationToken.new_request([])

    response =
      NotificationToken.new_response(
        provider: "fcm",
        token: "fcm-token",
        notification_status: :restricted,
        detail: %{"reason" => "companion_unavailable"}
      )

    assert response.provider == "fcm"
    assert response.token == "fcm-token"
    assert response.notification_status == :restricted
    assert response.detail == %{"reason" => "companion_unavailable"}
  end

  test "files.pick stays a compatibility command instead of becoming the public share family" do
    manifest =
      manifest_fixture()
      |> put_in([Access.key!(:capability_registry), "share"], Types.new_capability(id: "share", family: "share"))
      |> put_in([Access.key!(:routes), "dashboard", Access.key!(:capabilities)], ["share"])

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "dashboard", "files.pick")
  end

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-16T00:00:00Z",
      host: Types.new_host(origin: "https://shell.crosswake.example"),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "app_info" =>
          Types.new_capability(
            id: "app_info",
            family: "app_info",
            version: "1.0.0",
            owner: :bounded_bridge,
            package_class: :core,
            proof_class: :merge_blocking,
            rebuild: :none,
            prerequisites: ["declared route capability"],
            denial: "undeclared_capability",
            fallback: "Phoenix route continues without native app metadata",
            guide: "guides/bridge.md#bounded-bridge",
            legacy_ids: ["app.info.get"]
          ),
        "app.info.get" =>
          Types.new_capability(
            id: "app.info.get",
            family: "app_info",
            version: "1.0.0",
            owner: :bounded_bridge,
            package_class: :core,
            proof_class: :merge_blocking,
            rebuild: :none,
            prerequisites: ["declared route capability"],
            denial: "undeclared_capability",
            fallback: "Phoenix route continues without native app metadata",
            guide: "guides/bridge.md#bounded-bridge"
          ),
        "haptics" =>
          Types.new_capability(
            id: "haptics",
            family: "haptics",
            version: "2.3.0",
            owner: :bounded_bridge,
            package_class: :core,
            proof_class: :merge_blocking,
            rebuild: :none,
            prerequisites: ["declared route capability"],
            denial: "undeclared_capability",
            fallback: "Phoenix route continues without native confirmation feedback",
            guide: "guides/bridge.md#bounded-bridge",
            legacy_ids: ["haptics.impact"]
          ),
        "haptics.impact" =>
          Types.new_capability(
            id: "haptics.impact",
            family: "haptics",
            version: "2.3.0",
            owner: :bounded_bridge,
            package_class: :core,
            proof_class: :merge_blocking,
            rebuild: :none,
            prerequisites: ["declared route capability"],
            denial: "undeclared_capability",
            fallback: "Phoenix route continues without native confirmation feedback",
            guide: "guides/bridge.md#bounded-bridge"
          ),
        "permissions.status" =>
          Types.new_capability(
            id: "permissions.status",
            family: "permissions.status",
            version: "1.0.0",
            owner: :bounded_bridge,
            package_class: :core,
            proof_class: :merge_blocking,
            rebuild: :none,
            prerequisites: [
              "declared route capability",
              "bounded bridge support",
              "notifications alias only"
            ],
            denial: "undeclared_capability",
            fallback: "route continues without native notification permission snapshot authority",
            guide: "guides/capabilities.md#bounded-bridge"
          ),
        "notification_token" =>
          Types.new_capability(
            id: "notification_token",
            family: "notification_token",
            version: "1.2.0",
            owner: :bounded_bridge,
            package_class: :companion,
            proof_class: :advisory,
            rebuild: :companion_required,
            prerequisites: [
              "declared route capability",
              "bounded bridge support",
              "notification authorization already resolved",
              "provider token snapshot available"
            ],
            denial: "unavailable_capability",
            fallback: "treat notification token replies as provider-tagged evidence instead of backend registration truth",
            guide: "guides/capabilities.md#bounded-bridge",
            legacy_ids: ["push.notifications", "notifications.token.get"]
          )
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app.info.get", "haptics.impact", "permissions.status", "push.notifications"],
            allowlisted_origins: ["https://shell.crosswake.example"]
          ),
        "camera" =>
          Types.new_route_entry(
            id: "camera",
            path: "/camera",
            runtime: :native_screen,
            offline: :unavailable,
            allowlisted_origins: ["https://shell.crosswake.example"],
            transfers: [
              Types.new_transfer_seam(
                id: "capture_upload",
                intent: :upload,
                direction: :inbound,
                source: :native_capture,
                verification: :required
              )
            ]
          )
      }
    )
  end
end
