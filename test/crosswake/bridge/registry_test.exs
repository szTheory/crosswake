defmodule Crosswake.Bridge.RegistryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix

  test "registry allows exactly the bounded Phase 3 command set" do
    assert Registry.allowed_commands() == [
             "app.info.get",
             "files.pick",
             "haptics.impact"
           ]

    assert Registry.command_supported?("app.info.get")
    assert Registry.command_supported?("haptics.impact")
    assert Registry.command_supported?("files.pick")
    refute Registry.command_supported?("camera.capture")
    refute Registry.command_supported?("clipboard.read")
    refute Registry.command_supported?("share.sheet.present")
  end

  test "registry resolves versions and allowlists from manifest truth" do
    manifest = manifest_fixture()

    assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "haptics.impact")
    assert entry.command == "haptics.impact"
    assert entry.capability == "haptics.impact"
    assert entry.version == "2.3.0"
    assert entry.allowlisted_origins == ["https://shell.crosswake.example"]
  end

  test "registry rejects unsupported commands and undeclared route capabilities" do
    manifest = manifest_fixture()

    assert {:error, :unsupported_command} =
             Registry.lookup(manifest, "dashboard", "notifications.push")

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
        "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0"),
        "haptics.impact" => Types.new_capability(id: "haptics.impact", version: "2.3.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app.info.get", "haptics.impact"],
            allowlisted_origins: ["https://shell.crosswake.example"]
          )
      }
    )
  end
end
