defmodule Crosswake.Manifest.BuilderTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Registry
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

  describe "haptics vocabulary flip (D-57, D-58, D-60, D-61)" do
    test "a route declaring the family id \"haptics\" authorizes the haptics.impact command" do
      route = %Route{
        id: "saas-approval",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["haptics"]
      }

      managed_route = %{path: "/approvals/1", metadata: %{}, helper: "approval", verb: :get}

      manifest = Builder.build([route], [managed_route])

      assert {:ok, entry} = Registry.lookup(manifest, "saas-approval", "haptics.impact")
      assert entry.capability == "haptics"
    end

    test "a route declaring the legacy id \"haptics.impact\" still authorizes the haptics.impact command (D-63)" do
      route = %Route{
        id: "saas-approval-legacy",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["haptics.impact"]
      }

      managed_route = %{path: "/approvals-legacy/1", metadata: %{}, helper: "approval_legacy", verb: :get}

      manifest = Builder.build([route], [managed_route])

      assert {:ok, entry} = Registry.lookup(manifest, "saas-approval-legacy", "haptics.impact")
      assert entry.capability == "haptics"
    end

    test "the built manifest carries exactly one haptics capability-registry entry when only the family id is declared (D-60)" do
      route = %Route{
        id: "saas-approval",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["haptics"]
      }

      managed_route = %{path: "/approvals/1", metadata: %{}, helper: "approval", verb: :get}

      manifest = Builder.build([route], [managed_route])

      haptics_family_entries =
        manifest.capability_registry
        |> Map.values()
        |> Enum.filter(&(&1.family == "haptics"))

      assert length(haptics_family_entries) == 1
    end

    test "no capability in the built manifest lists its own id inside its own legacy_ids (D-60, universal invariant)" do
      # Exercise the compatibility path (a legacy declaration not already in the
      # public catalog) so compatibility_capability_attrs/2 actually runs, in
      # addition to every public catalog entry.
      route = %Route{
        id: "legacy-route",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["app.info.get", "push.notifications"]
      }

      managed_route = %{path: "/legacy", metadata: %{}, helper: "legacy", verb: :get}

      manifest = Builder.build([route], [managed_route])

      offenders =
        manifest.capability_registry
        |> Enum.filter(fn {_id, capability} -> capability.id in capability.legacy_ids end)

      assert offenders == [],
             "capability entries must never list their own id in their own legacy_ids, found: #{inspect(offenders)}"
    end

    test "the compatibility path builds without raising for an id not present in the public catalog" do
      route = %Route{
        id: "unknown-route",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["some.unknown.capability"]
      }

      managed_route = %{path: "/unknown", metadata: %{}, helper: "unknown", verb: :get}

      manifest = Builder.build([route], [managed_route])

      assert %Crosswake.Manifest.Types.Capability{id: "some.unknown.capability"} =
               manifest.capability_registry["some.unknown.capability"]
    end
  end
end
