defmodule Crosswake.Companions.Chimeway.ResolverTest do
  use ExUnit.Case

  alias Crosswake.Companions.Chimeway.Resolver
  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Compatibility.RouteGate.Decision
  alias Crosswake.Shell.Denial

  alias Crosswake.Manifest.Types.Compatibility

  alias Crosswake.Manifest.Types.Host

  defmodule MockIntentConsumer do
    @behaviour Crosswake.Companions.Chimeway.IntentConsumer

    def consume_intent(%NotificationOpenEvidence{open_ref: "valid_ref"}) do
      {:ok, %OpenResolution{open_ref: "valid_ref", state: :valid, resolved_at: DateTime.utc_now()}}
    end

    def consume_intent(%NotificationOpenEvidence{open_ref: open_ref}) do
      state = String.to_atom(open_ref)
      {:ok, %OpenResolution{open_ref: open_ref, state: state, resolved_at: DateTime.utc_now()}}
    end
  end

  setup do
    manifest = struct(Root,
      compatibility: struct(Compatibility, manifest_schema_version: "2.0.0", bridge_protocol_version: "1.0.0", native_runtime_version: "1.0.0"),
      capability_registry: %{},
      host: struct(Host, origin: "https://test.com"),
      routes: %{
        "dashboard" => %RouteEntry{
          id: "dashboard",
          path: "/dashboard",
          runtime: :liveview,
          notification_open: true,
          entry: :external
        },
        "no_notif" => %RouteEntry{
          id: "no_notif",
          path: "/no_notif",
          runtime: :liveview,
          notification_open: false,
          entry: :external
        },
        "restricted_actions" => %RouteEntry{
          id: "restricted_actions",
          path: "/restricted",
          runtime: :liveview,
          notification_open: [actions: ["tap", "reply"]],
          entry: :external
        },
        "auth_route" => %RouteEntry{
          id: "auth_route",
          path: "/auth",
          runtime: :liveview,
          notification_open: true,
          auth_posture: :remembered_ok,
          auth_min_level: 2,
          entry: :external
        }
      }
    )

    %{manifest: manifest}
  end

  test "returns route_mismatch when route is not in manifest", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "unknown")
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.route_mismatch"
  end

  test "returns policy_denied when notification_open is false", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "no_notif")
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.policy_denied"
  end

  test "returns unsupported_action when action is not in allowed list", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "restricted_actions", action_ref: "delete")
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.unsupported_action"
  end

  test "allows valid action in restricted list", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "restricted_actions", action_ref: "tap")
    assert {:allow, %Decision{}} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
  end

  test "maps intent consumer errors to denial codes", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "expired", route_id: "dashboard")
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.expired"

    evidence = struct(NotificationOpenEvidence, open_ref: "replayed", route_id: "dashboard")
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.replayed"
  end

  test "delegates to RouteGate when valid", %{manifest: manifest} do
    # RouteGate will return {:allow, %Decision{}} because it's a basic route unless we test auth
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "dashboard", auth_context: %{})
    assert {:allow, %Decision{}} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
  end

  test "passes through RouteGate step_up_required denial", %{manifest: manifest} do
    # auth_route requires auth, but evidence provides none
    evidence = struct(NotificationOpenEvidence, open_ref: "valid_ref", route_id: "auth_route", auth_context: %{})
    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :step_up_required
  end
end
