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

    def consume_intent(%NotificationOpenEvidence{open_ref: "server_bound_ref"}) do
      {:ok,
       %OpenResolution{
         open_ref: "server_bound_ref",
         state: :valid,
         route_id: "dashboard",
         action_ref: "tap",
         resolved_at: DateTime.utc_now()
       }}
    end

    def consume_intent(%NotificationOpenEvidence{} = evidence)
        when evidence.open_ref == "valid_ref" do
      {:ok,
       %OpenResolution{
         open_ref: evidence.open_ref,
         state: :valid,
         route_id: evidence.route_id,
         action_ref: evidence.action_ref || "tap",
         resolved_at: DateTime.utc_now()
       }}
    end

    def consume_intent(%NotificationOpenEvidence{open_ref: open_ref}) do
      state = String.to_atom(open_ref)
      {:ok, %OpenResolution{open_ref: open_ref, state: state, resolved_at: DateTime.utc_now()}}
    end
  end

  setup do
    manifest =
      struct(Root,
        compatibility:
          struct(Compatibility,
            manifest_schema_version: "2.0.0",
            bridge_protocol_version: "1.0.0",
            native_runtime_version: "1.0.0"
          ),
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
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "valid_ref",
        route_id: "restricted_actions",
        action_ref: "delete"
      )

    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.unsupported_action"
  end

  test "allows valid action in restricted list", %{manifest: manifest} do
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "valid_ref",
        route_id: "restricted_actions",
        action_ref: "tap"
      )

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

  test "normalizes revoked binding and action mismatch states to canonical codes", %{
    manifest: manifest
  } do
    for {state, code} <- [
          {"revoked", "notification.open.binding_revoked"},
          {"binding_revoked", "notification.open.binding_revoked"},
          {"action_mismatch", "notification.open.action_mismatch"}
        ] do
      evidence = struct(NotificationOpenEvidence, open_ref: state, route_id: "dashboard")

      assert {:deny, %Denial{} = denial} =
               Resolver.resolve(manifest, evidence, MockIntentConsumer)

      assert denial.reason == :notification_open_denied
      assert denial.code == code
    end
  end

  test "unknown intent state fails closed without raw-state public code", %{manifest: manifest} do
    evidence = struct(NotificationOpenEvidence, open_ref: "internal_state", route_id: "dashboard")

    assert {:deny, %Denial{} = denial} =
             Resolver.resolve(manifest, evidence, MockIntentConsumer)

    assert denial.reason == :notification_open_denied
    assert denial.code == "notification.open.policy_denied"
    refute denial.code == "notification.open.internal_state"
    refute inspect(denial.details) =~ "internal_state"
  end

  test "sanitizes hostile details from intent-state denials", %{manifest: manifest} do
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "expired",
        route_id: "dashboard",
        metadata: %{
          raw_token: "raw-token-must-not-leak",
          provider_payload: "provider-payload-must-not-leak",
          email: "person@example.test"
        }
      )

    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)

    refute inspect(denial.details) =~ "raw-token-must-not-leak"
    refute inspect(denial.details) =~ "provider-payload-must-not-leak"
    refute inspect(denial.details) =~ "person@example.test"
  end

  test "delegates to RouteGate when valid", %{manifest: manifest} do
    # RouteGate will return {:allow, %Decision{}} because it's a basic route unless we test auth
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "valid_ref",
        route_id: "dashboard",
        auth_context: %{}
      )

    assert {:allow, %Decision{}} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
  end

  test "uses only server-bound route and action after consumption", %{manifest: manifest} do
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "server_bound_ref",
        route_id: "client_supplied_route",
        action_ref: "client_supplied_action",
        auth_context: %{}
      )

    assert {:allow, %Decision{} = decision} =
             Resolver.resolve(manifest, evidence, MockIntentConsumer)

    assert decision.route_id == "dashboard"
  end

  test "passes through RouteGate denial for auth-predicated route", %{manifest: manifest} do
    # D-137-03: Sigra extracted to crosswake_sigra package. Without Sigra registered
    # in :companions, RouteGate returns :dependency_missing (fail-closed sentinel).
    # The integration test for :step_up_required lives in
    # packages/crosswake_chimeway/test/crosswake/proof/phase71_notification_workflow_proof_test.exs.
    evidence =
      struct(NotificationOpenEvidence,
        open_ref: "valid_ref",
        route_id: "auth_route",
        auth_context: %{}
      )

    assert {:deny, %Denial{} = denial} = Resolver.resolve(manifest, evidence, MockIntentConsumer)
    # fail-closed: no auth-authority companion registered
    assert denial.reason == :dependency_missing
  end
end
