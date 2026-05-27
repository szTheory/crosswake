defmodule Crosswake.CompatibilityTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Bridge.Contract
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types
  alias Crosswake.Packs.Inventory
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  test "compatibility findings cover runtime, capability, and declared pack mismatches separately" do
    manifest = manifest_fixture()

    findings =
      Compatibility.route_findings(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "0.9.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "0.8.0"},
          packs: %{"camera.assets" => "0.9.0"},
          origin: Types.default_origin()
        }
      )

    assert Enum.map(findings, & &1.axis) |> Enum.sort() == [
             :capability_version,
             :native_runtime_version,
             :pack_version
           ]
  end

  test "route gate returns typed denial codes instead of free form strings" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{"camera.assets" => "2.0.0"},
          origin: "https://untrusted.example"
        }
      )

    assert decision.status == :deny
    assert %Denial{reason: :origin_denied, route_id: "camera"} = decision.denial
    assert Enum.map(decision.denials, & &1.reason) == [:origin_denied]
  end

  test "deep link denial happens before runtime boot and exposes only safe recovery metadata" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{},
          origin: Types.default_origin()
        },
        activation_source: :deep_link,
        fallback_route_id: "dashboard"
      )

    assert decision.status == :deny
    assert %Denial{reason: :pack_incompatible} = decision.denial

    assert decision.denial.recovery == %{
             actions: [:retry, :open_safe_fallback, :update_app],
             fallback_route_id: "dashboard",
             mode: :safe_fallback
           }
  end

  test "in app navigation denial keeps the current route stable and reports an interrupting pack denial" do
    manifest = manifest_fixture()

    decision =
      RouteGate.evaluate(
        manifest,
        "camera",
        %Target{
          manifest_schema_version: "1.0.0",
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          manifest_source: :bundled,
          capabilities: %{"camera" => "1.0.0"},
          packs: %{},
          origin: Types.default_origin()
        },
        activation_source: :in_app_navigation,
        current_route_id: "dashboard"
      )

    assert decision.status == :deny
    assert decision.transition == :stay_put
    assert %Denial{reason: :pack_incompatible} = decision.denial
    assert decision.denial.details == %{current_route_id: "dashboard"}
  end

  test "bridge findings fail closed on active route origin capability and pack mismatches" do
    manifest = bridge_manifest_fixture()

    findings =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "files.pick",
          capability: "file_picker",
          route_id: "library",
          active_route_id: "dashboard",
          origin: "https://untrusted.example",
          native_runtime_version: "0.9.0",
          correlation_id: "bridge-1",
          capabilities: %{"file_picker" => "0.9.0"},
          installed_packs: %{}
        )
      )

    assert Enum.map(findings, & &1.axis) |> Enum.sort() == [
             :active_route,
             :capability_version,
             :native_runtime_version,
             :origin,
             :pack_version
           ]
  end

  test "bridge findings reject commands outside the bounded command set" do
    manifest = bridge_manifest_fixture()

    findings =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "share.sheet.present",
          capability: "share.sheet.present",
          route_id: "dashboard",
          active_route_id: "dashboard",
          origin: Types.default_origin(),
          native_runtime_version: "1.0.0",
          correlation_id: "bridge-2"
        )
      )

    assert [%Compatibility.Finding{axis: :bridge_command} = finding] = findings
    assert finding.message =~ "outside the bounded Phase 3 command set"
  end

  test "bridge denials reuse the shared denial vocabulary and report pack_incompatible" do
    manifest = bridge_manifest_fixture()

    [finding] =
      Compatibility.bridge_findings(
        manifest,
        Contract.new_request(
          command: "files.pick",
          capability: "file_picker",
          route_id: "library",
          active_route_id: "library",
          origin: Types.default_origin(),
          native_runtime_version: "1.0.0",
          correlation_id: "bridge-3",
          capabilities: %{"file_picker" => "1.0.0"},
          installed_packs: %{}
        )
      )
      |> Enum.filter(&(&1.axis == :pack_version))

    denial = Compatibility.finding_to_denial(finding, route_id: "library")

    assert %Denial{reason: :pack_incompatible, route_id: "library"} = denial
  end

  test "route findings deny missing stale invalidated and unverified pack inventory through pack_incompatible posture" do
    manifest = manifest_fixture()

    states = [
      %{},
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "0.9.0",
            bytes: 2048,
            integrity_status: :verified,
            verified_at: ~U[2026-05-17 10:00:00Z]
          )
      },
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "1.0.0",
            bytes: 2048,
            integrity_status: :verified,
            verified_at: ~U[2026-05-17 10:00:00Z],
            status: :invalidating,
            invalidation_reason: :manifest_replaced,
            invalidated_at: ~U[2026-05-17 10:05:00Z],
            last_known_state: %{state: :available, version: "1.0.0"}
          )
      },
      %{
        "camera.assets" =>
          Inventory.record(
            pack_id: "camera.assets",
            required_version: "1.0.0",
            installed_version: "1.0.0",
            bytes: 2048,
            integrity_status: :pending,
            verified_at: nil
          )
      }
    ]

    for installed_packs <- states do
      findings =
        Compatibility.route_findings(
          manifest,
          "camera",
          %Target{
            manifest_schema_version: "1.0.0",
            bridge_protocol_version: "1.0.0",
            native_runtime_version: "1.0.0",
            manifest_source: :bundled,
            capabilities: %{"camera" => "1.0.0"},
            packs: installed_packs,
            origin: Types.default_origin()
          }
        )

      assert Enum.any?(findings, &(&1.axis == :pack_version))
    end
  end

  test "compatibility guide keeps package versions separate from runtime axes" do
    guide = File.read!("guides/compatibility.md")

    assert guide =~ "Package Versions Versus Compatibility Axes"
    assert guide =~ "Companion Compatibility Contract"
    assert guide =~ "Release Choreography"
    assert guide =~ "Runtime Line Rules"
    assert guide =~ "package versions alone"
    assert guide =~ "manifest_schema_version"
    assert guide =~ "bridge_protocol_version"
    assert guide =~ "native_runtime_version"
    assert guide =~ "minimum compatible ranges"
  end

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-15T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "camera" => Types.new_capability(id: "camera", version: "1.0.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            allowlisted_origins: [Types.default_origin()]
          ),
        "camera" =>
          Types.new_route_entry(
            id: "camera",
            path: "/camera",
            runtime: :native_screen,
            offline: :unavailable,
            capabilities: ["camera"],
            packs: ["camera.assets@1.0.0"],
            security: :sensitive,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end

  defp bridge_manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-16T00:00:00Z",
      host: Types.new_host(),
      compatibility:
        Types.new_compatibility(
          native_runtime_version: "1.0.0",
          bridge_protocol_version: "1.0.0"
        ),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0"),
        "file_picker" => Types.new_capability(id: "file_picker", version: "1.0.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app.info.get"],
            allowlisted_origins: [Types.default_origin()]
          ),
        "library" =>
          Types.new_route_entry(
            id: "library",
            path: "/library",
            runtime: :live_view,
            offline: :cached_read_only,
            capabilities: ["file_picker"],
            packs: ["library.bundle@1.0.0"],
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end
end
