defmodule Crosswake.Manifest.BuilderTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Builder
  alias Crosswake.Offline.ContentPack
  alias Crosswake.Policy.Route

  test "ContentPack references populate pack_registry and route packs list" do
    route = %Route{
      id: "offline-data",
      runtime: :offline_island,
      offline: :local_first,
      packs: [%ContentPack{id: "data_core", version: "1.0.0", kind: :content}]
    }

    managed_route = %{
      path: "/data",
      metadata: %{},
      helper: "data",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert Map.has_key?(manifest.pack_registry, "data_core@1.0.0")
    
    pack_entry = manifest.pack_registry["data_core@1.0.0"]
    assert pack_entry.id == "data_core"
    assert pack_entry.version == "1.0.0"
    assert pack_entry.kind == :content

    assert "data_core@1.0.0" in manifest.routes["offline-data"].packs
  end

  test "notification_open policy is transferred into RouteEntry" do
    route = %Route{
      id: "notifications-page",
      runtime: :live_view,
      entry: :internal_only,
      notification_open: true
    }

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == true
  end

  test "notification_open policy with actions is transferred into RouteEntry" do
    route = %Route{
      id: "notifications-page",
      runtime: :live_view,
      entry: :internal_only,
      notification_open: %{actions: [:view, :reply]}
    }

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == %{actions: [:view, :reply]}
  end
end
