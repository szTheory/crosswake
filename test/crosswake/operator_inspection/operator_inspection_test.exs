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
          capabilities: ["notification_token"],
          notification_open: true
        ]
      )

      get(
        "/saas/approvals/:id",
        Elixir.Crosswake.OperatorInspectionTest.PageController,
        :approval,
        crosswake: [
          id: "saas_approval",
          runtime: :live_view,
          security: :sensitive,
          notification_open: [actions: [:tap, :approve]],
          auth_min_level: :mfa,
          requires_recent_auth: 300
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
    # Post-DECOUPLE-03: the auth contract surface (denial_codes, telemetry event
    # names, safe_detail_keys) is sourced at runtime from the registered
    # auth-authority companion, not from static core data. Register the real
    # Sigra facade ahead of the stub so auth_contract_truth/0 has an authority to
    # aggregate — the stub remains for the route-gating assertions. (See 136-06.)
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra, StubCompanion])

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
             "saas_approval",
             "secure"
           ]

    assert document.routes["dashboard"].ownership.owner_plane == :phoenix
    assert document.routes["dashboard"].support.status == :supported

    checkout = document.routes["checkout"]
    assert checkout.notifications.open_routing_active == false
    assert checkout.commerce.role == :purchase_intent
    assert checkout.commerce.owner_posture == :native_or_companion_required
    assert checkout.commerce.advisory_provider_proof == true
    assert checkout.rebuild.native_required == true
    assert checkout.rebuild.companion_required == false
    assert checkout.rebuild.change_class == "native or companion rebuild required"
    assert "native_shell" in checkout.rebuild.action_classes
    assert checkout.support.proof_class == :advisory
    assert "commerce.corridor.unsupported" in checkout.denials

    secure = document.routes["secure"]
    assert secure.auth.auth_min_level == :mfa
    assert secure.auth.requires_recent_auth == 600
    assert secure.auth.auth_posture == :strict_recent
    assert secure.auth.readiness == :verification_required
    assert secure.auth.posture == :session_authority

    assert secure.auth.shipped_contracts == [
             :session_authority,
             :handoff_ticket,
             :server_record_redemption,
             :step_up_intent,
             :plug_liveview_ceremony,
             :auth_return_boundary,
             :auth_return_attempt
           ]

    assert secure.auth.handoff.authority_source == :server_record
    assert secure.auth.handoff.envelope_authority == false
    assert secure.auth.step_up.status == :shipped
    assert secure.auth.step_up.route_target_validation == :manifest_route_id
    assert "auth.step_up.missing_context" in secure.auth.denial_codes
    assert "auth.handoff.invalid_ticket" in secure.auth.denial_codes
    assert "auth.step_up_intent.invalid_intent" in secure.auth.denial_codes
    assert "handoff_ref" in secure.auth.safe_detail_keys
    assert "step_up_intent_ref" in secure.auth.safe_detail_keys
    refute :handoff in secure.auth.non_goals
    refute :ceremony in secure.auth.non_goals
    assert secure.support.proof_class == :advisory
    assert "step_up_required" in secure.denials

    notifications = document.routes["notifications"]
    assert notifications.notifications.token_capability_declared == true
    assert notifications.notifications.provider_readiness == :verification_required
    assert notifications.notifications.delivery_supported == false
    assert notifications.notifications.open_routing_active == true
    assert notifications.notifications.route_activation_proof == :hermetic
    assert notifications.notifications.activation_authority == :route_gate_sigra
    assert notifications.notifications.evidence_authority == false
    assert "notification_token.provider_snapshot" in notifications.support.promotion_rule_ids

    approval = document.routes["saas_approval"]
    assert approval.notifications.open_routing_active == true
    assert approval.notifications.route_activation_proof == :hermetic
    assert approval.notifications.activation_authority == :route_gate_sigra
    assert approval.notifications.action_allowlist == [:tap, :approve]
    assert approval.notifications.delivery_supported == false
    assert approval.auth.auth_min_level == :mfa
    assert approval.auth.requires_recent_auth == 300

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
      "saas_approval",
      "secure"
    ]

    assert document.indexes.by_capability["notification_token"] == ["notifications"]
    assert document.indexes.by_companion["stub_companion"] == ["gated"]
    assert document.indexes.by_auth_predicate["step_up_required"] == [
             "checkout",
             "saas_approval",
             "secure"
           ]
    assert "checkout" in document.indexes.by_rebuild_requirement["native_required"]
    assert "notifications" in document.indexes.by_rebuild_requirement["companion_required"]
  end

  test "routes expose canonical rebuild action classes and promotion rule ids" do
    document =
      OperatorInspection.inspect(
        route_source: InspectionRouter,
        generated_at: "2026-05-31T00:00:00Z"
      )

    checkout = document.routes["checkout"]
    notifications = document.routes["notifications"]
    secure = document.routes["secure"]
    gated = document.routes["gated"]

    assert checkout.rebuild.change_class == "native or companion rebuild required"
    assert checkout.rebuild.action_classes == ["native_shell", "provider_adapter"]
    assert checkout.rebuild.compatibility_signal == "native_runtime_version"
    assert "purchase_intent.provider.storekit" in checkout.support.promotion_rule_ids
    assert "purchase_intent.provider.play_billing" in checkout.support.promotion_rule_ids

    assert notifications.rebuild.change_class == "native or companion rebuild required"
    assert notifications.rebuild.action_classes == ["companion_native"]
    assert "notification_token.provider_snapshot" in notifications.support.promotion_rule_ids

    assert secure.support.status == :verification_required
    assert secure.support.proof_class == :advisory
    assert "auth.sigra.session_authority" in secure.support.promotion_rule_ids
    assert secure.auth.contract_surface == :full_sigra_machinery
    assert secure.auth.contract_proof_class == :merge_blocking
    assert secure.auth.route_authority_source == :session_authority_lane
    assert secure.auth.evidence_authority.handoff_envelope == false
    assert secure.auth.host_readiness == :verification_required
    assert secure.auth.provider_device_proof == :advisory
    assert secure.auth.telemetry.status == :shipped
    assert [:crosswake, :auth, :denial] in secure.auth.telemetry.event_names
    assert secure.auth.security_closeout.status == :shipped

    assert gated.rebuild.action_classes == ["companion_native"]
  end

  test "operator media recovery proof truth preserves proof-only and backend-authority posture" do
    assert [media_truth] = OperatorInspection.media_recovery_proof_truth()

    assert media_truth.recovery_proof == :hermetic
    assert media_truth.simulated_network_degradation == :proof_only
    assert media_truth.local_capture_authority == false
    assert media_truth.backend_verification_required == true
    assert media_truth.real_storage_supported == false
    assert media_truth.native_capture_supported == false
    assert media_truth.background_transfer_supported == false
    assert media_truth.posture =~ "local capture evidence is not availability authority"
  end
end
