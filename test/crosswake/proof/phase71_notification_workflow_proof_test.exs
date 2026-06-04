defmodule Crosswake.Proof.Phase71NotificationWorkflowProofTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution
  alias Crosswake.Companions.Chimeway.Resolver
  alias Crosswake.Companions.Sigra.Contracts, as: SigraContracts
  alias Crosswake.Manifest.Types.Compatibility
  alias Crosswake.Manifest.Types.Host
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.SupportMatrix

  @fixed_now "2026-06-04T12:00:00Z"
  @target_route_id "saas_approval"
  @target_path "/saas/approvals/:approval_id"
  @allowed_actions ["tap", "approve"]
  @hostile_values [
    "raw-token-must-not-leak",
    "apns-token-must-not-leak",
    "fcm-token-must-not-leak",
    "provider-payload-must-not-leak",
    "Private title",
    "Private body",
    "approval-secret",
    "actor-private",
    "session-private",
    "device-private",
    "203.0.113.10",
    "private-agent",
    "person@example.test"
  ]

  defmodule StatefulIntentConsumer do
    @behaviour Crosswake.Companions.Chimeway.IntentConsumer

    alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
    alias Crosswake.Companions.Chimeway.Contracts.OpenResolution

    @fixed_now "2026-06-04T12:00:00Z"

    @impl true
    def consume_intent(%NotificationOpenEvidence{} = evidence) do
      state =
        case {evidence.open_ref, evidence.binding_ref, evidence.route_id, evidence.action_ref} do
          {"open_valid", "binding_active", route_id, "approve"}
          when route_id in ["saas_approval", "saas_approval_with_fallback"] ->
            :valid
          {"open_expired", _, _, _} -> :expired
          {"open_replayed", _, _, _} -> :replayed
          {"open_revoked", _, _, _} -> :revoked
          {"open_binding_mismatch", _, _, _} -> :binding_mismatch
          {"open_route_mismatch", _, _, _} -> :route_mismatch
          {"open_action_mismatch", _, _, _} -> :action_mismatch
          {_, "binding_revoked", _, _} -> :binding_revoked
          {_, _binding_ref, "wrong_route", _} -> :route_mismatch
          {_, _, _, "wrong_action"} -> :action_mismatch
          _other -> :policy_denied
        end

      {:ok, %OpenResolution{open_ref: evidence.open_ref, state: state, resolved_at: @fixed_now}}
    end
  end

  describe "hermetic proof shape" do
    test "proof uses inline manifest and intent consumer without provider/device runtime dependencies" do
      source = __ENV__.file |> File.read!() |> String.downcase()
      scanned_source = Regex.replace(~r/defp forbidden_runtime_phrases do.*?^  end/ms, source, "")

      assert source =~ "defmodule crosswake.proof.phase71notificationworkflowprooftest"
      assert source =~ "use exunit.case, async: false"
      assert source =~ @target_route_id
      assert source =~ "tap"
      assert source =~ "approve"
      assert source =~ "auth_min_level: :mfa"
      assert source =~ "requires_recent_auth: 300"
      assert source =~ "statefulintentconsumer"
      assert source =~ "crosswake.companions.chimeway.intentconsumer"

      for phrase <- forbidden_runtime_phrases() do
        refute scanned_source =~ phrase
      end
    end
  end

  describe "notification re-entry over Chimeway RouteGate and Sigra" do
    test "valid one-time intent and fresh backend MFA auth activate the route" do
      assert {:allow, decision} =
               Resolver.resolve(manifest(), evidence(auth_context: auth_context()), StatefulIntentConsumer)

      assert decision.status == :allow
      assert decision.transition == :activate
      assert decision.route_id == @target_route_id
    end

    test "missing invalid weak stale revoked remembered and cached auth halt notification activation" do
      cases = [
        {nil, "auth.step_up.missing_context"},
        {invalid_auth_context(), "auth.step_up.invalid_context"},
        {auth_context(lane: [assurance_level: :password]), "auth.step_up.insufficient_assurance"},
        {stale_auth_context(), "auth.step_up.stale_auth"},
        {auth_context(lane: [state: :revoked]), "auth.step_up.revoked"},
        {auth_context(lane: [remembered: true]), "auth.step_up.remembered_not_allowed"},
        {auth_context(lane: [cached: true]), "auth.step_up.cached_not_allowed"}
      ]

      for {auth_context, code} <- cases do
        assert {:deny, denial} =
                 Resolver.resolve(
                   manifest(),
                   evidence(auth_context: auth_context),
                   StatefulIntentConsumer
                 )

        assert denial.reason == :step_up_required
        assert denial.code == code
      end
    end

    test "notification-source stale auth on fallback route halts instead of redirecting" do
      assert {:deny, denial} =
               Resolver.resolve(
                 manifest(:with_fallback),
                 evidence(
                   route_id: "saas_approval_with_fallback",
                   auth_context: stale_auth_context()
                 ),
                 StatefulIntentConsumer
               )

      assert denial.reason == :step_up_required
      assert denial.code == "auth.step_up.stale_auth"

      decision =
        Crosswake.Compatibility.RouteGate.evaluate(
          manifest(:with_fallback),
          "saas_approval_with_fallback",
          target(),
          activation_source: :notification,
          auth_context: stale_auth_context()
        )

      assert decision.status == :deny
      assert decision.denial.reason == :step_up_required
      assert decision.transition == :halt
    end
  end

  describe "Chimeway denial matrix and support-safe output" do
    test "route policy and intent failures use canonical Chimeway denial vocabulary" do
      cases = [
        {evidence(route_id: "unknown_route"), "notification.open.route_mismatch"},
        {evidence(route_id: "notification_disabled"), "notification.open.policy_denied"},
        {evidence(action_ref: "delete"), "notification.open.unsupported_action"},
        {evidence(open_ref: "open_expired"), "notification.open.expired"},
        {evidence(open_ref: "open_replayed"), "notification.open.replayed"},
        {evidence(open_ref: "open_revoked"), "notification.open.binding_revoked"},
        {evidence(open_ref: "open_binding_mismatch"), "notification.open.binding_mismatch"},
        {evidence(open_ref: "open_route_mismatch"), "notification.open.route_mismatch"},
        {evidence(open_ref: "open_action_mismatch"), "notification.open.action_mismatch"}
      ]

      for {evidence, code} <- cases do
        assert {:deny, denial} = Resolver.resolve(manifest(), evidence, StatefulIntentConsumer)
        assert denial.reason == :notification_open_denied
        assert denial.code == code
      end
    end

    test "hostile notification metadata is absent from denial details and inspect output" do
      assert {:deny, denial} =
               Resolver.resolve(
                 manifest(),
                 evidence(open_ref: "open_expired", metadata: hostile_metadata()),
                 StatefulIntentConsumer
               )

      inspected = inspect(denial)
      details = inspect(denial.details)

      for value <- @hostile_values do
        refute details =~ value
        refute inspected =~ value
      end
    end
  end

  defp manifest(mode \\ :default) do
    %Root{
      manifest_schema_version: "2.0.0",
      crosswake_version: "0.1.0",
      generated_at: @fixed_now,
      host: %Host{
        phoenix_version: "1.7.0",
        live_view_version: "0.20.0",
        origin: "https://example.test",
        manifest_sources: [:bundled]
      },
      compatibility: %Compatibility{
        manifest_schema_version: "2.0.0",
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        supported_manifest_sources: [:bundled],
        remote_updates: []
      },
      support_matrix: %SupportMatrix{
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
      routes: routes(mode)
    }
  end

  defp routes(:default) do
    Map.merge(base_routes(), %{
      "notification_disabled" => %RouteEntry{
        id: "notification_disabled",
        path: "/saas/disabled/:approval_id",
        runtime: :live_view,
        entry: :external,
        notification_open: nil
      }
    })
  end

  defp routes(:with_fallback) do
    Map.put(base_routes(), "saas_approval_with_fallback", %RouteEntry{
      id: "saas_approval_with_fallback",
      path: @target_path,
      runtime: :live_view,
      entry: :external,
      notification_open: [actions: @allowed_actions],
      auth_min_level: :mfa,
      requires_recent_auth: 300,
      auth_posture: :strict_recent,
      on_unavailable: {:fallback_phoenix, :dashboard}
    })
  end

  defp base_routes do
    %{
      @target_route_id => %RouteEntry{
        id: @target_route_id,
        path: @target_path,
        runtime: :live_view,
        entry: :external,
        notification_open: [actions: @allowed_actions],
        auth_min_level: :mfa,
        requires_recent_auth: 300,
        auth_posture: :strict_recent
      }
    }
  end

  defp target do
    %Crosswake.Compatibility.Target{
      manifest_schema_version: "2.0.0",
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      origin: "https://example.test"
    }
  end

  defp evidence(overrides) do
    attrs =
      Keyword.merge(
        [
          route_id: @target_route_id,
          open_ref: "open_valid",
          binding_ref: "binding_active",
          provider: :apns,
          action_ref: "approve",
          action_kind: :tap,
          evaluated_at: @fixed_now,
          auth_context: auth_context(),
          metadata: %{}
        ],
        overrides
      )

    struct!(NotificationOpenEvidence, attrs)
  end

  defp auth_context(overrides \\ []) do
    lane_overrides = Keyword.get(overrides, :lane, [])
    auth_age = Keyword.get(overrides, :auth_age, 60)

    assert {:ok, lane} = SigraContracts.new_session_authority_lane(lane_attrs(lane_overrides))

    assert {:ok, context} =
             SigraContracts.new_auth_context(%{
               actor_id: "actor_123",
               org_id: "org_123",
               mfa_level: :mfa,
               auth_age: auth_age,
               session_authority_lane: lane,
               as_of: @fixed_now
             })

    context
  end

  defp invalid_auth_context do
    %SigraContracts.AuthContext{
      actor_id: "",
      org_id: "org_123",
      mfa_level: :mfa,
      auth_age: 60
    }
  end

  defp stale_auth_context do
    auth_context(
      lane: [
        authenticated_at: "2026-06-04T11:50:00Z",
        as_of: @fixed_now
      ]
    )
  end

  defp lane_attrs(overrides) do
    %{
      session_ref: "session_ref_123",
      subject_ref: "actor_123",
      org_id: "org_123",
      state: :active,
      assurance_level: :mfa,
      authn_methods: [:password, :totp],
      authenticated_at: "2026-06-04T11:59:00Z",
      last_seen_at: @fixed_now,
      idle_expires_at: "2026-06-04T12:30:00Z",
      absolute_expires_at: "2026-06-05T12:00:00Z",
      renew_after: "2026-06-04T12:20:00Z",
      remembered: false,
      cached: false,
      session_version: 7,
      revoked_at: nil,
      as_of: @fixed_now
    }
    |> Map.merge(Map.new(overrides))
  end

  defp hostile_metadata do
    %{
      raw_token: "raw-token-must-not-leak",
      apns_token: "apns-token-must-not-leak",
      fcm_token: "fcm-token-must-not-leak",
      provider_payload: "provider-payload-must-not-leak",
      notification_title: "Private title",
      notification_body: "Private body",
      route_params: %{"approval_id" => "approval-secret"},
      actor_id: "actor-private",
      session_ref: "session-private",
      device_id: "device-private",
      ip: "203.0.113.10",
      user_agent: "private-agent",
      email: "person@example.test"
    }
  end

  defp forbidden_runtime_phrases do
    [
      "endpoint.",
      "repo.",
      "pubsub.",
      "liveview server",
      "system.cmd(",
      "provider credential setup",
      "native device proof",
      "simulator runtime"
    ]
  end
end
