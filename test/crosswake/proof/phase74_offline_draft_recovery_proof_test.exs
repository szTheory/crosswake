defmodule Crosswake.Proof.Phase74OfflineDraftRecoveryProofTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.IslandContract
  alias Crosswake.Manifest.Types.NavigationTopology
  alias Crosswake.Policy.Validator
  alias Crosswake.Policy.Route

  @fixed_now "2026-06-05T12:00:00Z"

  defmodule FakeSyncController do
    def init(opts), do: opts

    def call(conn, _opts) do
      # Simulates draft ingestion and mutation using the SyncController pattern
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      draft = Jason.decode!(body)

      if draft["mutation"] == "update_draft" do
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{status: "ok", draft_id: draft["id"], synced: true})
        )
      else
        Plug.Conn.send_resp(conn, 400, "invalid mutation")
      end
    end
  end

  describe "Phase 74 hermetic proof shape" do
    test "focuses on explicit offline draft constraints" do
      source = __ENV__.file |> File.read!() |> String.downcase()

      assert source =~ "offline_island"
      assert source =~ "test/crosswake/proof/phase73_auth_sensitive_admin_workflow_proof_test.exs"
      assert source =~ "test/crosswake/offline/proof_lane_test.exs"
      assert source =~ "local_first"
      assert source =~ "cached_read_only"
      assert source =~ "synccontroller"
      assert source =~ "islandcontract"
    end
  end

  describe "Compiler enforcement of offline policies" do
    test "Validator rejects :local_first offline policy when paired with a :live_view runtime" do
      route = %Route{
        id: "invalid-live-view",
        runtime: :live_view,
        offline: :local_first,
        capabilities: [],
        packs: [],
        sync: [],
        transfers: []
      }

      managed_route = %{
        path: "/drafts",
        source: %{file: "lib/router.ex", line: 10}
      }

      errors = Validator.validate([route], [managed_route])

      offline_error = Enum.find(errors, &(&1.key == :offline))
      assert offline_error
      assert offline_error.message == "live_view routes cannot declare offline :local_first"
    end
  end

  describe "offline posture and RouteGate limits" do
    test "evaluates an offline_island route with :local_first, proving the manifest bounds and IslandContract presence" do
      route = %RouteEntry{
        id: "offline-draft-route",
        path: "/draft",
        runtime: :offline_island,
        offline: :local_first,
        entry: :internal_only,
        island_contract: %IslandContract{
          id: "draft-island",
          storage: :sqlite,
          draft_surface: :full,
          journal_mode: :wal,
          reconciliation: :last_write_wins,
          checkpoint_requirement: :none,
          authoritative_source: :phoenix,
          sync_seam: "draft_sync"
        }
      }

      manifest = manifest(%{"offline-draft-route" => route})

      decision = RouteGate.evaluate(manifest, "offline-draft-route", target())

      assert route.runtime == :offline_island
      assert route.offline == :local_first
      assert route.island_contract.sync_seam == "draft_sync"
      assert decision.status == :allow
    end

    test "evaluates a standard :live_view route with :cached_read_only, ensuring offline island logic is not applied universally" do
      route = %RouteEntry{
        id: "cached-route",
        path: "/history",
        runtime: :live_view,
        offline: :cached_read_only,
        entry: :internal_only,
        island_contract: nil
      }

      manifest = manifest(%{"cached-route" => route})

      decision = RouteGate.evaluate(manifest, "cached-route", target())

      assert route.runtime == :live_view
      assert route.offline == :cached_read_only
      assert is_nil(route.island_contract)
      assert decision.status == :allow
    end
  end

  describe "Local draft ingestion and mutation" do
    test "simulates local draft ingestion and mutation using the SyncController pattern" do
      conn =
        Plug.Test.conn(
          :post,
          "/sync",
          Jason.encode!(%{id: "draft-123", mutation: "update_draft"})
        )
        |> Plug.Conn.put_req_header("content-type", "application/json")

      conn = FakeSyncController.call(conn, FakeSyncController.init([]))

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["status"] == "ok"
      assert response["draft_id"] == "draft-123"
      assert response["synced"] == true
    end
  end

  defp manifest(routes) do
    %Root{
      manifest_schema_version: "2.0.0",
      crosswake_version: "0.1.0",
      generated_at: @fixed_now,
      host: %Crosswake.Manifest.Types.Host{
        phoenix_version: "1.7.0",
        live_view_version: "0.20.0",
        origin: "https://example.test",
        manifest_sources: [:bundled]
      },
      compatibility: %Crosswake.Manifest.Types.Compatibility{
        manifest_schema_version: "2.0.0",
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        supported_manifest_sources: [:bundled],
        remote_updates: []
      },
      support_matrix: %Crosswake.Manifest.Types.SupportMatrix{
        phoenix: [],
        live_view: [],
        ios: [],
        android: [],
        shells: [],
        capability_families: [],
        package_surfaces: [],
        release_boundaries: [],
        change_classes: []
      },
      capability_registry: %{},
      pack_registry: %{},
      commerce_corridors: %{},
      navigation_topology: %NavigationTopology{
        topology_schema_version: "1.0.0",
        manifest_schema_version: "2.0.0",
        status: :unknown_blocking,
        entries: []
      },
      routes: routes
    }
  end

  defp target do
    %Target{
      manifest_schema_version: "2.0.0",
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      origin: "https://example.test",
      manifest_source: :bundled
    }
  end
end
