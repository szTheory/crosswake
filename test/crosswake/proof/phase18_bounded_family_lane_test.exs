Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.Proof.Phase18BoundedFamilyLaneTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest
  alias Crosswake.TestSupport.RouterFixtures

  test "bounded bridge families stay family-first and file_picker stays transfer-backed" do
    {:ok, %{manifest: manifest}} = Manifest.compile(RouterFixtures.ManagedRouter)

    assert {:ok, app_info} = Registry.lookup(manifest, "dashboard", "app.info.get")
    assert {:ok, haptics} = Registry.lookup(manifest, "dashboard", "haptics.impact")
    assert {:ok, permission} = Registry.lookup(manifest, "dashboard", "permissions.status")
    assert {:ok, token} = Registry.lookup(manifest, "dashboard", "notifications.token.get")

    assert {:ok, picker} =
             Registry.lookup(manifest, "library", "files.pick", %{"transfer_id" => "lesson_import"})

    assert app_info.capability == "app_info"
    assert haptics.capability == "haptics"
    assert permission.capability == "permissions.status"
    assert token.capability == "notification_token"
    assert picker.capability == "file_picker"

    assert {:error, :undeclared_capability} =
             Registry.lookup(manifest, "library", "files.pick", %{"transfer_id" => "lesson_export"})

    assert {:error, :unsupported_command} =
             Registry.lookup(manifest, "dashboard", "deep_link")
  end
end
