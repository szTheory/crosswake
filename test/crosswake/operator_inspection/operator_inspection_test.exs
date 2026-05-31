defmodule Crosswake.OperatorInspectionTest do
  use ExUnit.Case, async: false

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Types
  alias Crosswake.TestSupport.StubCompanion

  defmodule PageController do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule InspectionRouter do
    use Crosswake.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      get("/dashboard", Elixir.Crosswake.OperatorInspectionTest.PageController, :dashboard,
        crosswake: [
          id: "dashboard",
          runtime: :live_view,
          security: :standard,
          capabilities: ["app_info"]
        ]
      )

      get("/checkout", Elixir.Crosswake.OperatorInspectionTest.PageController, :checkout,
        crosswake: [
          id: "checkout",
          runtime: :live_view,
          security: :sensitive,
          commerce: [corridor: :subscription_default, role: :purchase_intent]
        ]
      )

      get("/secure", Elixir.Crosswake.OperatorInspectionTest.PageController, :secure,
        crosswake: [
          id: "secure",
          runtime: :live_view,
          security: :sensitive,
          auth_min_level: :mfa,
          requires_recent_auth: 600
        ]
      )

      get(
        "/notifications",
        Elixir.Crosswake.OperatorInspectionTest.PageController,
        :notifications,
        crosswake: [
          id: "notifications",
          runtime: :live_view,
          security: :standard,
          capabilities: ["notification_token"]
        ]
      )

      get("/gated", Elixir.Crosswake.OperatorInspectionTest.PageController, :gated,
        crosswake: [
          id: "gated",
          runtime: :live_view,
          security: :standard,
          gated_by: :stub_companion
        ]
      )
    end
  end

  setup do
    previous = Application.get_env(:crosswake, :companions)
    Application.put_env(:crosswake, :companions, [StubCompanion])

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:crosswake, :companions)
      else
        Application.put_env(:crosswake, :companions, previous)
      end
    end)
  end

  test "builds a route-authoritative operator inspection document from a router" do
    document =
      OperatorInspection.inspect(
        route_source: InspectionRouter,
        generated_at: "2026-05-31T00:00:00Z",
        git_sha: "abc123"
      )

    assert %Types.Document{} = document
    assert document.schema_version == "1.0.0"
    assert document.generated_at == "2026-05-31T00:00:00Z"
    assert document.provenance.generator == "Crosswake.OperatorInspection"
    assert document.provenance.git_sha == "abc123"

    assert Map.keys(document.routes) == [
             "checkout",
             "dashboard",
             "gated",
             "notifications",
             "secure"
           ]

    assert document.routes["dashboard"].ownership.owner_plane == :phoenix
    assert document.routes["dashboard"].support.status == :supported

    checkout = document.routes["checkout"]
    assert checkout.commerce.role == :purchase_intent
    assert checkout.commerce.owner_posture == :native_or_companion_required
    assert checkout.commerce.advisory_provider_proof == true
    assert checkout.rebuild.native_required == true
    assert checkout.rebuild.companion_required == false
    assert checkout.support.proof_class == :advisory
    assert "commerce.corridor.unsupported" in checkout.denials

    secure = document.routes["secure"]
    assert secure.auth.auth_min_level == :mfa
    assert secure.auth.requires_recent_auth == 600
    assert secure.auth.readiness == :verification_required
    assert secure.support.proof_class == :advisory
    assert "step_up_required" in secure.denials

    notifications = document.routes["notifications"]
    assert notifications.notifications.token_capability_declared == true
    assert notifications.notifications.provider_readiness == :verification_required
    assert notifications.notifications.delivery_supported == false

    gated = document.routes["gated"]
    assert gated.companion.gated_by == :stub_companion
    assert gated.companion.posture == :first_party_typed_companion
    assert gated.support.proof_class == :advisory
    assert "gate_denied" in gated.denials
  end

  test "keeps support status, proof class, condition status, and findings as separate axes" do
    document =
      OperatorInspection.inspect(
        route_source: InspectionRouter,
        generated_at: "2026-05-31T00:00:00Z"
      )

    notification_route = document.routes["notifications"]

    assert notification_route.support.status == :verification_required
    assert notification_route.support.proof_class == :advisory

    notification_condition =
      Enum.find(notification_route.conditions, &(&1.type == :notification_token))

    assert notification_condition.status == :unknown
    assert notification_condition.severity == :advisory
    assert notification_condition.reason == :provider_snapshot

    assert Enum.any?(document.findings, fn finding ->
             finding.code == "operator.notification_token.provider_snapshot" and
               finding.severity == :advisory and
               finding.details.route_id == "notifications"
           end)
  end

  test "derives indexes and summary from routes without replacing route truth" do
    document =
      OperatorInspection.inspect(
        route_source: InspectionRouter,
        generated_at: "2026-05-31T00:00:00Z"
      )

    assert document.summary.route_count == map_size(document.routes)
    assert document.summary.verification_required_count >= 4

    assert document.indexes.by_runtime["live_view"] == [
             "checkout",
             "dashboard",
             "gated",
             "notifications",
             "secure"
           ]

    assert document.indexes.by_capability["notification_token"] == ["notifications"]
    assert document.indexes.by_companion["stub_companion"] == ["gated"]
    assert document.indexes.by_auth_predicate["step_up_required"] == ["secure"]
    assert "checkout" in document.indexes.by_rebuild_requirement["native_required"]
    assert "notifications" in document.indexes.by_rebuild_requirement["companion_required"]
  end
end
