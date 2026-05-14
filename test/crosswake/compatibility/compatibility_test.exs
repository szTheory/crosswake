defmodule Crosswake.CompatibilityTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types
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
end
