defmodule Crosswake.Shell.ActivationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Types
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.Activation.Decision
  alias Crosswake.Shell.Activation.Request
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  test "cold start, deep link, notification, and in-app navigation normalize into one activation request shape" do
    requests = [
      Activation.new_request(
        route_id: "dashboard",
        source: :cold_start,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "cold-start-1",
        declared_pack_requirements: %{"shell.chrome" => "1.0.0"},
        installed_packs: %{"shell.chrome" => "1.0.0"},
        capabilities: %{"app.info.get" => "1.0.0"}
      ),
      Activation.new_request(
        url: "#{Types.default_origin()}/dashboard",
        source: :deep_link,
        manifest_source: :cached,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "deep-link-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{}
      ),
      Activation.new_request(
        route_id: "dashboard",
        url: "#{Types.default_origin()}/dashboard",
        source: :notification,
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "notification-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{"haptics.impact" => "1.0.0"}
      ),
      Activation.new_request(
        route_id: "dashboard",
        source: :in_app_navigation,
        origin: Types.default_origin(),
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "in-app-1",
        declared_pack_requirements: %{},
        installed_packs: %{},
        capabilities: %{"files.pick" => "1.0.0"}
      )
    ]

    assert Enum.all?(requests, &match?(%Request{}, &1))
    assert Enum.map(requests, & &1.source) == [:cold_start, :deep_link, :notification, :in_app_navigation]
    assert Enum.map(requests, & &1.manifest_source) == [:bundled, :cached, :bundled, :bundled]
    assert Enum.map(requests, & &1.bridge_protocol_version) == ["1.0.0", "1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(requests, & &1.native_runtime_version) == ["1.0.0", "1.0.0", "1.0.0", "1.0.0"]
    assert Enum.map(requests, & &1.correlation_id) == ["cold-start-1", "deep-link-1", "notification-1", "in-app-1"]
    assert Enum.at(requests, 1).origin == Types.default_origin()
  end

  test "activation resolves to explicit allow or deny before any runtime mount" do
    manifest = manifest_fixture()

    allow_decision =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "dashboard",
          source: :cold_start,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "allow-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    deny_decision =
      manifest
      |> Activation.resolve(
        Activation.new_request(
          route_id: "missing",
          source: :deep_link,
          origin: Types.default_origin(),
          manifest_source: :bundled,
          bridge_protocol_version: "1.0.0",
          native_runtime_version: "1.0.0",
          correlation_id: "deny-1",
          declared_pack_requirements: %{},
          installed_packs: %{},
          capabilities: %{}
        )
      )

    assert %Decision{status: :allow, route_id: "dashboard", denial: nil} = allow_decision
    assert %Decision{status: :deny, route_id: "missing", denial: %Denial{reason: :inactive_route}} =
             deny_decision
  end

  test "denials expose stable product reasons and machine readable details" do
    reasons = [
      :compatibility_mismatch,
      :undeclared_capability,
      :unavailable_capability,
      :origin_denied,
      :inactive_route,
      :pack_incompatible
    ]

    denials =
      Enum.map(reasons, fn reason ->
        Denial.new(
          reason: reason,
          route_id: "dashboard",
          message: "denied",
          details: %{axis: Atom.to_string(reason)}
        )
      end)

    assert Enum.map(denials, & &1.reason) == reasons

    assert Enum.map(denials, &Denial.to_map/1) == [
             %{
               "code" => "compatibility_mismatch",
               "details" => %{"axis" => "compatibility_mismatch"},
               "message" => "denied",
               "reason" => "compatibility_mismatch",
               "route_id" => "dashboard"
             },
             %{
               "code" => "undeclared_capability",
               "details" => %{"axis" => "undeclared_capability"},
               "message" => "denied",
               "reason" => "undeclared_capability",
               "route_id" => "dashboard"
             },
             %{
               "code" => "unavailable_capability",
               "details" => %{"axis" => "unavailable_capability"},
               "message" => "denied",
               "reason" => "unavailable_capability",
               "route_id" => "dashboard"
             },
             %{
               "code" => "origin_denied",
               "details" => %{"axis" => "origin_denied"},
               "message" => "denied",
               "reason" => "origin_denied",
               "route_id" => "dashboard"
             },
             %{
               "code" => "inactive_route",
               "details" => %{"axis" => "inactive_route"},
               "message" => "denied",
               "reason" => "inactive_route",
               "route_id" => "dashboard"
             },
             %{
               "code" => "pack_incompatible",
               "details" => %{"axis" => "pack_incompatible"},
               "message" => "denied",
               "reason" => "pack_incompatible",
               "route_id" => "dashboard"
             }
           ]
  end

  defp manifest_fixture do
    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-05-15T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{},
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end
end
