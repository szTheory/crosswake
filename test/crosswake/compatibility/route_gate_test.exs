defmodule Crosswake.Compatibility.RouteGateTest do
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Evaluator
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types.RouteEntry

  defmodule AuthRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
        )

        live("/remembered", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "remembered",
            runtime: :live_view,
            auth_min_level: :password,
            auth_posture: :remembered_ok
          ]
        )
      end
    end
  end

  defmodule KillSwitchCompanion do
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :phase54_kill_switch

    @impl true
    def enabled?(_config), do: true

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: true

    @impl true
    def validate_dependency, do: :ok

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :phase54_kill_switch,
        enabled: true,
        dependency_status: :present,
        gate_status: :unconfigured,
        kill_switch_status: :active,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  defmodule GatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/gated-auth", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated-auth",
            runtime: :live_view,
            gated_by: :test_flag,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
        )
      end
    end
  end

  setup do
    # Post-inversion fix: register the real Sigra facade so auth-predicated routes
    # get :step_up_required instead of :dependency_missing. Pre-inversion, Sigra.Evaluator
    # was called directly regardless of the registry — delete_env was valid then but is
    # contradictory now that auth evaluation is registry-dispatched. The test intent
    # (auth-predicated route denies with :step_up_required) is preserved by registering Sigra.
    original_companions = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
    end)

    :ok
  end

  test "evaluator denies missing and invalid auth context with canonical codes" do
    route = route_entry(auth_min_level: :mfa, auth_posture: :strict_recent)

    # D-137-A: Evaluator now emits %Finding{axis: :auth} directly (Plan 02).
    assert {:deny, %Finding{axis: :auth} = missing} = Evaluator.evaluate_route_auth(route, nil, [])
    assert missing.code == "auth.step_up.missing_context"
    assert Map.keys(missing.details) == ["evaluated_at"]

    invalid_context = %Contracts.AuthContext{
      actor_id: "",
      org_id: "org",
      mfa_level: :mfa,
      auth_age: 0
    }

    assert {:deny, invalid} = Evaluator.evaluate_route_auth(route, invalid_context, [])
    assert invalid.code == "auth.step_up.invalid_context"
  end

  test "evaluator denies lifecycle, version, assurance, freshness, remembered, and cached failures" do
    route =
      route_entry(auth_min_level: :mfa, requires_recent_auth: 300, auth_posture: :strict_recent)

    cases = [
      {auth_context(lane: [state: :suspended]), [], "auth.step_up.non_active"},
      {auth_context(lane: [idle_expires_at: "2026-06-01T00:04:00Z"]), [],
       "auth.step_up.idle_expired"},
      {auth_context(lane: [absolute_expires_at: "2026-06-01T00:04:00Z"]), [],
       "auth.step_up.absolute_expired"},
      {auth_context(lane: [state: :revoked]), [], "auth.step_up.revoked"},
      {auth_context(lane: [session_version: 6]), [expected_session_version: 7],
       "auth.step_up.version_mismatch"},
      {auth_context(lane: [assurance_level: :password]), [],
       "auth.step_up.insufficient_assurance"},
      {auth_context(
         lane: [authenticated_at: "2026-06-01T00:00:00Z", as_of: "2026-06-01T00:10:00Z"]
       ), [], "auth.step_up.stale_auth"},
      {auth_context(lane: [remembered: true]), [], "auth.step_up.remembered_not_allowed"},
      {auth_context(lane: [cached: true]), [], "auth.step_up.cached_not_allowed"}
    ]

    for {context, opts, code} <- cases do
      # D-137-A: Evaluator now emits %Finding{axis: :auth} (Plan 02).
      assert {:deny, %Finding{axis: :auth} = finding} = Evaluator.evaluate_route_auth(route, context, opts)
      assert finding.code == code
    end
  end

  test "remembered authority passes only when route posture explicitly permits it" do
    remembered_route = route_entry(auth_min_level: :password, auth_posture: :remembered_ok)
    strict_route = route_entry(auth_min_level: :password, auth_posture: :strict_recent)
    context = auth_context(lane: [remembered: true, assurance_level: :password])

    assert {:allow, _result} = Evaluator.evaluate_route_auth(remembered_route, context, [])
    assert {:deny, denial} = Evaluator.evaluate_route_auth(strict_route, context, [])
    assert denial.code == "auth.step_up.remembered_not_allowed"
  end

  test "RouteGate delegates auth after kill-switch and before compatibility" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthRouter)
    target = %Target{origin: manifest.host.origin}

    decision = RouteGate.evaluate(manifest, "secure", target, [])
    assert decision.denial.reason == :step_up_required
    assert decision.denial.code == "auth.step_up.missing_context"

    auth_context = auth_context(lane: [assurance_level: :password])
    decision = RouteGate.evaluate(manifest, "secure", target, auth_context: auth_context)
    assert decision.denial.reason == :step_up_required
    assert decision.denial.code == "auth.step_up.insufficient_assurance"
  end

  test "notification-source auth denial halts before fallback redirect" do
    route =
      route_entry(
        id: "secure_notification_with_fallback",
        path: "/secure-notification",
        entry: :external,
        auth_min_level: :mfa,
        requires_recent_auth: 300,
        on_unavailable: {:fallback_phoenix, :dashboard}
      )

    manifest = manifest_for(route)
    target = %Target{origin: "https://example.test"}
    stale_context = auth_context(lane: [authenticated_at: "2026-05-31T23:54:00Z"])

    decision =
      RouteGate.evaluate(manifest, route.id, target,
        activation_source: :notification,
        auth_context: stale_context
      )

    assert decision.status == :deny
    assert decision.denial.reason == :step_up_required
    assert decision.denial.code == "auth.step_up.stale_auth"
    assert decision.transition == :halt
  end

  test "non-notification auth denial still uses configured fallback redirect" do
    route =
      route_entry(
        id: "secure_with_fallback",
        path: "/secure-fallback",
        entry: :external,
        auth_min_level: :mfa,
        requires_recent_auth: 300,
        on_unavailable: {:fallback_phoenix, :dashboard}
      )

    manifest = manifest_for(route)
    target = %Target{origin: "https://example.test"}
    stale_context = auth_context(lane: [authenticated_at: "2026-05-31T23:54:00Z"])

    decision = RouteGate.evaluate(manifest, route.id, target, auth_context: stale_context)

    assert decision.status == :deny
    assert decision.denial.reason == :step_up_required
    assert decision.transition == {:redirect, :dashboard}
  end

  test "RouteGate keeps kill-switch precedence over Sigra auth checks" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouter)
    target = %Target{origin: manifest.host.origin}
    Application.put_env(:crosswake, :companions, [KillSwitchCompanion])

    decision = RouteGate.evaluate(manifest, "gated-auth", target, [])

    assert decision.denial.reason == :kill_switch_active
    refute decision.denial.reason == :step_up_required
  end

  defp route_entry(attrs) do
    attrs =
      Keyword.merge(
        [
          id: "secure",
          path: "/secure",
          runtime: :live_view,
          offline: :unavailable,
          entry: :internal_only
        ],
        attrs
      )

    RouteEntry |> struct!(attrs)
  end

  defp manifest_for(%RouteEntry{} = route) do
    %Crosswake.Manifest.Types.Root{
      manifest_schema_version: "2.0.0",
      crosswake_version: "0.1.0",
      generated_at: "2026-06-04T12:00:00Z",
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
      routes: %{route.id => route}
    }
  end

  defp auth_context(opts) do
    lane_opts = Keyword.get(opts, :lane, [])
    assert {:ok, lane} = Contracts.new_session_authority_lane(lane_attrs(lane_opts))
    assert {:ok, context} = Contracts.new_auth_context(session_authority_lane: lane)
    context
  end

  defp lane_attrs(overrides) do
    %{
      session_ref: "session_ref_123",
      subject_ref: "actor_123",
      org_id: "org_123",
      state: :active,
      assurance_level: :mfa,
      authn_methods: [:password, :totp],
      authenticated_at: "2026-06-01T00:04:00Z",
      last_seen_at: "2026-06-01T00:05:00Z",
      idle_expires_at: "2026-06-01T00:30:00Z",
      absolute_expires_at: "2026-06-02T00:00:00Z",
      renew_after: "2026-06-01T00:20:00Z",
      remembered: false,
      cached: false,
      session_version: 7,
      revoked_at: nil,
      as_of: "2026-06-01T00:05:00Z"
    }
    |> Map.merge(Map.new(overrides))
  end
end
