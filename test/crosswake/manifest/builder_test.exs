defmodule Crosswake.Manifest.BuilderTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Registry
  alias Crosswake.Manifest.Builder
  alias Crosswake.Manifest.Serializer
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Offline.ContentPack
  alias Crosswake.Policy.Route

  test "builds a version-bound topology from the paired validated route inventory" do
    route = %Route{id: "route-0123456789abcdef", runtime: :offline_island, offline: :local_first}

    managed_route = %{
      path: "/dashboard/:id",
      metadata: %{
        crosswake_navigation: %{
          rows: [topology_row()],
          entries: [topology_root_entry()]
        }
      },
      helper: "dashboard",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route], generated_at: "2026-08-04T00:00:00Z")

    assert manifest.routes[route.id].runtime == :offline_island
    assert manifest.navigation_topology.status == :ready

    assert manifest.navigation_topology.manifest_schema_version ==
             manifest.manifest_schema_version

    assert [entry] = manifest.navigation_topology.entries
    assert entry.route_id == route.id
    assert entry.presentation == :root
    assert Serializer.render(manifest) == Serializer.render(manifest)
  end

  test "builds an explicit unknown-blocking topology without fabricating roots" do
    manifest = Builder.build([], [], generated_at: "2026-08-04T00:00:00Z")

    assert manifest.navigation_topology.status == :unknown_blocking
    assert manifest.navigation_topology.entries == []
  end

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

  test "notification_open legacy shorthand compiles to the tap-only RouteEntry policy" do
    route =
      Route.new!(
        id: "notifications-page",
        runtime: :live_view,
        entry: :internal_only,
        notification_open: true
      )

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == %{actions: ["tap"]}

    assert Types.to_map(manifest.routes["notifications-page"])["notification_open"] == %{
             "actions" => ["tap"]
           }
  end

  test "notification_open explicit actions are transferred unchanged into RouteEntry" do
    route =
      Route.new!(
        id: "notifications-page",
        runtime: :live_view,
        entry: :internal_only,
        notification_open: [actions: [:tap, :reply]]
      )

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == %{actions: ["tap", "reply"]}

    assert Types.to_map(manifest.routes["notifications-page"])["notification_open"] == %{
             "actions" => ["tap", "reply"]
           }
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

      managed_route = %{
        path: "/approvals-legacy/1",
        metadata: %{},
        helper: "approval_legacy",
        verb: :get
      }

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

      assert %Crosswake.Manifest.Types.Capability{
               id: "some.unknown.capability",
               rebuild: :native_required,
               interaction: :fire_and_forget
             } =
               manifest.capability_registry["some.unknown.capability"]
    end
  end

  describe "Capability rebuild + interaction — structurally unconstructable without both (D-51, D-52, D-54)" do
    test "constructing a Capability without :rebuild raises ArgumentError naming :rebuild" do
      error =
        assert_raise ArgumentError, fn ->
          struct!(Capability, %{id: "x", version: "1.0.0", interaction: :fire_and_forget})
        end

      assert Exception.message(error) =~ ":rebuild"
    end

    test "constructing a Capability without :interaction raises ArgumentError naming :interaction" do
      error =
        assert_raise ArgumentError, fn ->
          struct!(Capability, %{id: "x", version: "1.0.0", rebuild: :none})
        end

      assert Exception.message(error) =~ ":interaction"
    end

    test "all 15 public catalog entries build successfully and each declares an explicit interaction value" do
      registry = Builder.capability_registry([])

      assert map_size(registry) == 15

      assert Enum.all?(Map.values(registry), fn %Capability{interaction: interaction} ->
               interaction in [:fire_and_forget, :device_answer, :user_answer]
             end)
    end

    test "share declares :fire_and_forget — it returns a request acknowledgement, not a completion (D-54)" do
      registry = Builder.capability_registry([])

      assert %Capability{interaction: :fire_and_forget} = registry["share"]
    end

    test "app_info, permissions.status, and notification_token declare :device_answer; file_picker declares :user_answer" do
      registry = Builder.capability_registry([])

      assert %Capability{interaction: :device_answer} = registry["app_info"]
      assert %Capability{interaction: :device_answer} = registry["permissions.status"]
      assert %Capability{interaction: :device_answer} = registry["notification_token"]
      assert %Capability{interaction: :user_answer} = registry["file_picker"]
    end

    test "haptics declares :fire_and_forget" do
      registry = Builder.capability_registry([])

      assert %Capability{interaction: :fire_and_forget} = registry["haptics"]
    end

    test "the compatibility path for a capability id absent from the catalog yields rebuild: :native_required and interaction: :fire_and_forget without raising" do
      route = %Route{
        id: "unmatched-route",
        runtime: :live_view,
        offline: :cached_read_only,
        capabilities: ["totally.unknown.capability"]
      }

      registry = Builder.capability_registry([route])

      assert %Capability{rebuild: :native_required, interaction: :fire_and_forget} =
               registry["totally.unknown.capability"]
    end

    test "the built manifest reports manifest_schema_version 1.1.0" do
      manifest = Builder.build([], [])

      assert manifest.manifest_schema_version == "1.1.0"
      assert Types.new_compatibility().manifest_schema_version == "1.1.0"
    end
  end

  defp topology_root_entry do
    %{
      route_id: "route-0123456789abcdef",
      root_tab_id: "tab-0123456789abcdef",
      presentation: :root,
      parent_route_id: nil,
      deep_link_posture: :deny,
      restoration_posture: :deny
    }
  end

  defp topology_row do
    %{
      route_id: "route-0123456789abcdef",
      path_pattern: "/dashboard/:id",
      runtime_owner: confirmed(:offline_island),
      offline_posture: confirmed(:local_first),
      mutation_categories: confirmed([:answer_submission]),
      staleness_class: confirmed(:not_cacheable),
      auth: confirmed(:authenticated),
      recent_auth: confirmed(:not_required),
      scope_posture:
        confirmed(%{
          scope: :opaque_partitioned,
          logout: :stops_replay,
          account_switch: :stops_replay
        }),
      media_requirement:
        confirmed(%{
          requirement: :required,
          size_band: :small,
          codec_family: :aac,
          integrity: :verified
        }),
      fallbacks:
        confirmed(%{
          online: :serve,
          offline: :queue_local,
          denied: :block,
          corrupt_pack: :block,
          disabled: :retain_and_block
        }),
      disablement: confirmed(%{entry: :server_enforced, replay: :server_reauthorized}),
      queued_data_retention: confirmed(:retain_until_resolution)
    }
  end

  defp confirmed(value), do: %{status: :confirmed_sanitized, value: value}
end
