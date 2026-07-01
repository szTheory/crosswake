defmodule Crosswake.Proof.Phase73AuthSensitiveAdminWorkflowProofTest do
  # async: false because support-truth test calls Application.put_env.
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff
  alias Crosswake.Companions.Sigra.StepUp
  alias Crosswake.Companions.Sigra.StepUpCeremony
  alias Crosswake.Manifest.Types.Compatibility
  alias Crosswake.Manifest.Types.Host
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Manifest.Types.SupportMatrix

  @fixed_now "2026-06-05T12:00:00Z"
  @admin_route_id "saas-admin-member-access"
  @admin_path "/saas/admin/member-access"
  @hostile_values [
    "raw-session-ref-must-not-leak",
    "actor-private",
    "org-private",
    "device-private",
    "person@example.test",
    "203.0.113.73",
    "private-user-agent",
    "raw-oauth-token",
    "raw-provider-payload",
    "raw-pkce-verifier",
    "raw-nonce"
  ]

  # D-137-03: Register sigra so SupportMatrix.auth_contract_truth/0 returns a
  # populated row (denial_codes, posture fields) rather than sentinel [] values.
  setup do
    prior = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, prior)
    end)

    :ok
  end

  defmodule IntentLifecycle do
    defstruct [:ref, :state, :route_id, :session_version, :expires_at]

    def issued(attrs) do
      %__MODULE__{
        ref: Keyword.fetch!(attrs, :ref),
        state: :issued,
        route_id: Keyword.fetch!(attrs, :route_id),
        session_version: Keyword.fetch!(attrs, :session_version),
        expires_at: Keyword.fetch!(attrs, :expires_at)
      }
    end

    def consume(%__MODULE__{state: :issued, expires_at: expires_at} = intent, now)
        when expires_at > now do
      {:ok, %__MODULE__{intent | state: :consumed}}
    end

    def consume(%__MODULE__{state: :consumed}, _now),
      do: {:error, "auth.step_up_intent.consumed_intent"}

    def consume(%__MODULE__{state: :revoked}, _now),
      do: {:error, "auth.step_up_intent.revoked_intent"}

    def consume(%__MODULE__{state: :canceled}, _now),
      do: {:error, "auth.step_up_intent.canceled_intent"}

    def consume(%__MODULE__{}, _now), do: {:error, "auth.step_up_intent.expired_intent"}
  end

  describe "hermetic proof shape" do
    test "phase 73 proof stays focused on admin route authority without provider or native UI claims" do
      source = __ENV__.file |> File.read!() |> String.downcase()

      assert source =~ "phase73authsensitiveadminworkflowprooftest"
      assert source =~ @admin_route_id
      assert source =~ "runtime: :live_view"
      assert source =~ "offline: :unavailable"
      assert source =~ "security: :sensitive"
      assert source =~ "auth_min_level: :mfa"
      assert source =~ "requires_recent_auth: 300"
      assert source =~ "auth_posture: :strict_recent"
      assert source =~ "stepupceremony.evaluate_or_issue"
      assert source =~ "persistent shell session does not grant admin authority"
      assert source =~ "persistent_native_context"
      assert source =~ "intentlifecycle"
      assert source =~ "denialcodes.sanitize_details"
    end
  end

  describe "admin route posture and RouteGate authority" do
    test "persistent native session evidence is denied until backend step-up projects fresh authority" do
      route = admin_route()
      target = target()

      persistent_native_context = auth_context(lane: [cached: true, assurance_level: :mfa])
      decision = RouteGate.evaluate(manifest(), @admin_route_id, target, auth_context: persistent_native_context)

      assert route.runtime == :live_view
      assert route.entry == :internal_only
      assert route.offline == :unavailable
      assert route.security == :sensitive
      assert route.auth_min_level == :mfa
      assert route.requires_recent_auth == 300
      assert route.auth_posture == :strict_recent
      assert decision.status == :deny
      assert decision.denial.reason == :step_up_required
      assert decision.denial.code == "auth.step_up.cached_not_allowed"
      assert decision.transition == :halt

      fresh_context = auth_context(lane: [assurance_level: :mfa, authenticated_at: @fixed_now])
      allowed = RouteGate.evaluate(manifest(), @admin_route_id, target, auth_context: fresh_context)

      assert allowed.status == :allow
      assert allowed.transition == :activate
    end

    test "weak stale remembered revoked expired and version-mismatched authority fail closed" do
      cases = [
        {auth_context(lane: [assurance_level: :password]), [], "auth.step_up.insufficient_assurance"},
        {stale_auth_context(), [], "auth.step_up.stale_auth"},
        {auth_context(lane: [remembered: true, assurance_level: :mfa]), [],
         "auth.step_up.remembered_not_allowed"},
        {auth_context(lane: [state: :revoked]), [], "auth.step_up.revoked"},
        {auth_context(lane: [idle_expires_at: "2026-06-05T11:59:00Z"]), [],
         "auth.step_up.idle_expired"},
        {auth_context(lane: [session_version: 72]), [expected_session_version: 73],
         "auth.step_up.version_mismatch"}
      ]

      for {context, opts, code} <- cases do
        decision =
          RouteGate.evaluate(
            manifest(),
            @admin_route_id,
            target(),
            Keyword.put(opts, :auth_context, context)
          )

        assert decision.status == :deny
        assert decision.denial.reason == :step_up_required
        assert decision.denial.code == code
      end
    end

    test "phishing-resistant fixture stays backend-projection-only and does not become provider proof" do
      route = %RouteEntry{admin_route() | auth_min_level: :phishing_resistant}
      manifest = manifest(%{@admin_route_id => route})

      denied =
        RouteGate.evaluate(manifest, @admin_route_id, target(),
          auth_context: auth_context(lane: [assurance_level: :mfa])
        )

      assert denied.status == :deny
      assert denied.denial.code == "auth.step_up.insufficient_assurance"

      allowed =
        RouteGate.evaluate(manifest, @admin_route_id, target(),
          auth_context: auth_context(lane: [assurance_level: :phishing_resistant])
        )

      assert allowed.status == :allow
    end
  end

  describe "handoff and step-up lifecycle" do
    test "handoff ticket is route-bound evidence and does not authorize admin access by itself" do
      weak_lane = session_authority_lane(assurance_level: :password)

      assert {:ok, ticket} =
               Handoff.new_handoff_ticket_record(%{
                 ticket_ref: "hnd_admin_73",
                 ticket_digest: "sha256.hnd_admin_73",
                 state: :issued,
                 subject_ref: "sub_backend",
                 org_id: "org_backend",
                 source_session_ref: "sess_persistent_native",
                 expected_session_version: 72,
                 binding_kind: :session_route_intent,
                 intent_kind: :admin_member_access,
                 target_route_id: @admin_route_id,
                 required_assurance_level: :mfa,
                 required_auth_posture: :strict_recent,
                 issued_at: @fixed_now,
                 expires_at: "2026-06-05T12:05:00Z",
                 audit_correlation_ref: "support:hnd.admin.73",
                 projected_session_authority_lane: weak_lane
               })

      assert ticket.target_route_id == @admin_route_id
      assert ticket.projected_session_authority_lane == weak_lane

      decision =
        RouteGate.evaluate(manifest(), @admin_route_id, target(),
          auth_context: auth_context(weak_lane)
        )

      assert decision.status == :deny
      assert decision.denial.code == "auth.step_up.insufficient_assurance"

      assert {:ok, audit} =
               Handoff.new_handoff_audit_event(%{
                 event_id: "evt_hnd_admin_73",
                 event_type: :deny,
                 handoff_ref: "support:hnd.admin.73",
                 state_before: :issued,
                 state_after: :issued,
                 outcome: :denied,
                denial_code: "auth.handoff.projection_failed",
                 occurred_at: @fixed_now,
                 route_id: @admin_route_id,
                 intent_kind: :admin_member_access,
                 request_ref: "req_admin_73",
                 actor_kind: :backend,
                 binding_result: "matched",
                 metadata: %{proof_class: "phase73_admin"}
               })

      assert audit.outcome == :denied
      assert audit.route_id == @admin_route_id
      assert audit.denial_code == "auth.handoff.projection_failed"
    end

    test "step-up challenge and completion produce the only successful admin unlock path" do
      weak_context =
        auth_context(
          lane: [
            assurance_level: :password,
            authenticated_at: "2026-06-05T11:40:00Z",
            session_version: 72
          ]
        )

      assert {:challenge, %StepUp.StepUpIntentRecord{} = intent, %StepUp.StepUpChallenge{} = challenge} =
               StepUpCeremony.evaluate_or_issue(admin_route(), weak_context,
                 expected_session_version: 72,
                 request_ref: "req_admin_step_up_73",
                 issue_intent: &issue_step_up_intent/1
               )

      assert intent.return_route_id == @admin_route_id
      assert intent.required_assurance_level == :mfa
      assert intent.required_auth_posture == :strict_recent
      assert challenge.return_route_id == @admin_route_id
      assert challenge.required_assurance_level == :mfa

      fresh_lane = session_authority_lane(assurance_level: :mfa, session_version: 73)

      assert {:ok, renewal} =
               StepUp.new_session_renewal_instructions(%{
                 renew_session?: true,
                 rotate_csrf?: true,
                 put_session: %{
                   "crosswake_session_ref" => fresh_lane.session_ref,
                   "crosswake_session_version" => fresh_lane.session_version
                 },
                 delete_session: ["crosswake_step_up_intent_ref", "crosswake_step_up_challenge"],
                 projected_session_ref: fresh_lane.session_ref,
                 projected_session_version: fresh_lane.session_version,
                 live_socket_invalidation: %{reason: :step_up_completed}
               })

      assert {:ok, audit} =
               StepUp.new_step_up_audit_event(%{
                 event_id: "evt_sup_admin_73",
                 event_type: :consume,
                 step_up_intent_ref: intent.audit_correlation_ref,
                 intent_ref: intent.intent_ref,
                 state_before: :challenged,
                 state_after: :consumed,
                 outcome: :allowed,
                 occurred_at: @fixed_now,
                 route_id: @admin_route_id,
                 challenge_kind: :host_confirm_password,
                 source_session_ref: "sess_persistent_native",
                 projected_session_ref: fresh_lane.session_ref,
                 session_version_before: 72,
                 session_version_after: 73,
                 assurance_after: :mfa,
                 authn_methods_after: [:password, :totp],
                 binding_result: "matched",
                 request_ref: "req_admin_step_up_73",
                 actor_kind: :backend,
                 metadata: %{proof_class: "phase73_admin"}
               })

      assert {:ok, completion} =
               StepUp.new_step_up_completion(%{
                 step_up_intent_ref: intent.audit_correlation_ref,
                 consumed_at: @fixed_now,
                 session_authority_lane: fresh_lane,
                 session_renewal_instructions: renewal,
                 route_target: %{route_id: @admin_route_id},
                 audit_event: audit
               })

      assert completion.session_renewal_instructions.renew_session? == true
      assert completion.session_renewal_instructions.rotate_csrf? == true
      assert completion.session_renewal_instructions.live_socket_invalidation == %{reason: :step_up_completed}
      assert completion.route_target == %{route_id: @admin_route_id}

      allowed =
        RouteGate.evaluate(manifest(), @admin_route_id, target(),
          auth_context: auth_context(completion.session_authority_lane),
          expected_session_version: 73
        )

      assert allowed.status == :allow
      assert allowed.transition == :activate
    end

    test "in-memory lifecycle fixture proves replay expired canceled and revoked states fail closed" do
      issued =
        IntentLifecycle.issued(
          ref: "sup_admin_73",
          route_id: @admin_route_id,
          session_version: 72,
          expires_at: "2026-06-05T12:05:00Z"
        )

      assert {:ok, consumed} = IntentLifecycle.consume(issued, @fixed_now)
      assert {:error, "auth.step_up_intent.consumed_intent"} =
               IntentLifecycle.consume(consumed, @fixed_now)

      assert {:error, "auth.step_up_intent.expired_intent"} =
               issued
               |> Map.put(:expires_at, "2026-06-05T11:59:00Z")
               |> IntentLifecycle.consume(@fixed_now)

      assert {:error, "auth.step_up_intent.canceled_intent"} =
               issued
               |> Map.put(:state, :canceled)
               |> IntentLifecycle.consume(@fixed_now)

      assert {:error, "auth.step_up_intent.revoked_intent"} =
               issued
               |> Map.put(:state, :revoked)
               |> IntentLifecycle.consume(@fixed_now)
    end
  end

  describe "safe output and example-host posture" do
    test "handoff and step-up locators reject authority and identity smuggling" do
      assert {:error, handoff_errors} =
               Handoff.new_handoff_envelope(%{
                 typ: "crosswake.sigra.handoff.v1",
                 ticket_ref: "hnd_admin_73",
                 version: "1",
                 issuer: "crosswake_example",
                 audience: "crosswake.sigra.handoff",
                 issued_at: @fixed_now,
                 expires_at: "2026-06-05T12:05:00Z",
                 intent_kind: :admin_member_access,
                 route_id: @admin_route_id,
                 binding_kind: :session_route_intent,
                 session_ref: "raw-session-ref-must-not-leak",
                 subject_ref: "actor-private",
                 org_id: "org-private",
                 session_authority_lane: %{state: :active},
                 access_granted: true
               })

      assert {:handoff_envelope, {:session_ref, :forbidden}} in handoff_errors
      assert {:handoff_envelope, {:subject_ref, :forbidden}} in handoff_errors
      assert {:handoff_envelope, {:org_id, :forbidden}} in handoff_errors
      assert {:handoff_envelope, {:session_authority_lane, :forbidden}} in handoff_errors
      assert {:handoff_envelope, {:access_granted, :forbidden}} in handoff_errors

      assert {:error, step_up_errors} =
               StepUp.new_step_up_intent_locator(%{
                 typ: "crosswake.sigra.step_up.v1",
                 intent_ref: "sup_admin_73",
                 version: "1",
                 issuer: "crosswake_example",
                 audience: "crosswake.sigra.step_up",
                 issued_at: @fixed_now,
                 expires_at: "2026-06-05T12:05:00Z",
                 source_route_id: "saas-dashboard",
                 return_route_id: @admin_route_id,
                 challenge_kind: :host_confirm_password,
                 session_ref: "raw-session-ref-must-not-leak",
                 actor_id: "actor-private",
                 org_id: "org-private",
                 provider_payload: "raw-provider-payload",
                 csrf_token: "secret-csrf",
                 session_authority_lane: %{state: :active}
               })

      assert {:step_up_intent_locator, {:session_ref, :forbidden}} in step_up_errors
      assert {:step_up_intent_locator, {:actor_id, :forbidden}} in step_up_errors
      assert {:step_up_intent_locator, {:org_id, :forbidden}} in step_up_errors
      assert {:step_up_intent_locator, {:provider_payload, :forbidden}} in step_up_errors
      assert {:step_up_intent_locator, {:csrf_token, :forbidden}} in step_up_errors
      assert {:step_up_intent_locator, {:session_authority_lane, :forbidden}} in step_up_errors
    end

    test "public denial details and support truth stay low-cardinality" do
      sanitized =
        DenialCodes.sanitize_details(%{
          step_up_intent_ref: "support:sup.admin.73",
          handoff_ref: "support:hnd.admin.73",
          auth_posture: :strict_recent,
          max_auth_age_seconds: 300,
          auth_age_seconds: 900,
          session_ref: "raw-session-ref-must-not-leak",
          actor_id: "actor-private",
          org_id: "org-private",
          device_ref: "device-private",
          email: "person@example.test",
          ip: "203.0.113.73",
          user_agent: "private-user-agent",
          oauth_access_token: "raw-oauth-token",
          provider_payload: "raw-provider-payload",
          pkce_verifier: "raw-pkce-verifier",
          nonce: "raw-nonce"
        })

      inspected = inspect(sanitized)

      assert sanitized["step_up_intent_ref"] == "support:sup.admin.73"
      assert sanitized["handoff_ref"] == "support:hnd.admin.73"
      assert sanitized["auth_posture"] == "strict_recent"

      for value <- @hostile_values do
        refute inspected =~ value
      end

      assert [%{} = row] = Crosswake.SupportMatrix.auth_contract_truth()
      assert row.posture =~ "auth-sensitive admin workflow proof"
      assert row.posture =~ "persistent shell session state"
      assert row.posture =~ "native auth UI"
      assert row.posture =~ "generic audit system"
      assert :native_auth_ui in row.deferred
      assert :provider_device_proof in row.deferred
    end

    test "example host exposes compact admin proof surface and no broad admin console" do
      route_source =
        File.read!("../../examples/phoenix_host/lib/crosswake_example/router.ex")

      live_source =
        File.read!(
          "../../examples/phoenix_host/lib/crosswake_example/saas_portal/admin_access_live.ex"
        )

      plug_source =
        File.read!(
          "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex"
        )

      mount_source =
        File.read!(
          "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex"
        )

      auth_source =
        File.read!("../../examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex")

      step_up_source =
        File.read!("../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex")

      assert route_source =~ @admin_route_id
      assert route_source =~ "offline: :unavailable"
      assert route_source =~ "security: :sensitive"
      assert live_source =~ "Persistent shell session does not grant admin authority"
      assert live_source =~ ~s(role="status")
      assert live_source =~ "Safe audit ref"
      assert plug_source =~ "StepUpCeremony.evaluate_or_issue"
      assert mount_source =~ "StepUpCeremony.evaluate_or_issue"
      assert auth_source =~ "Plug.CSRFProtection.delete_csrf_token"
      assert auth_source =~ "configure_session(conn, renew: true)"
      assert step_up_source =~ ~s("crosswake_step_up_intent_ref")
      assert step_up_source =~ ~s("crosswake_step_up_challenge")

      for forbidden <- ["delete user", "impersonate", "audit browser", "role editor"] do
        refute String.downcase(live_source) =~ forbidden
      end
    end
  end

  defp issue_step_up_intent(attrs) do
    lane =
      session_authority_lane(
        assurance_level: attrs.required_assurance_level,
        session_version: (attrs.expected_session_version || 72) + 1
      )

    with {:ok, intent} <-
           StepUp.new_step_up_intent_record(%{
             intent_ref: "sup_admin_73",
             locator_digest: "sha256.sup_admin_73",
             state: :issued,
             subject_ref: attrs.subject_ref,
             org_id: attrs.org_id,
             source_session_ref: attrs.source_session_ref,
             expected_session_version: attrs.expected_session_version,
             source_route_id: attrs.source_route_id,
             return_route_id: attrs.return_route_id,
             required_assurance_level: attrs.required_assurance_level,
             required_auth_posture: attrs.required_auth_posture,
             max_auth_age_seconds: attrs.max_auth_age_seconds,
             challenge_kind: attrs.challenge_kind,
             issued_at: @fixed_now,
             expires_at: "2026-06-05T12:05:00Z",
             audit_correlation_ref: "support:sup.admin.73",
             projected_session_authority_lane: lane
           }),
         {:ok, challenge} <-
           StepUp.new_step_up_challenge(%{
             challenge_ref: "challenge_admin_73",
             intent_ref: intent.audit_correlation_ref,
             challenge_kind: attrs.challenge_kind,
             challenge_route_id: attrs.source_route_id,
             return_route_id: attrs.return_route_id,
             required_assurance_level: attrs.required_assurance_level,
             max_auth_age_seconds: attrs.max_auth_age_seconds,
             issued_at: @fixed_now,
             expires_at: "2026-06-05T12:05:00Z",
             message: "Additional authentication is required.",
             support_ref: intent.audit_correlation_ref
           }) do
      {:ok, %{intent: intent, challenge: challenge}}
    end
  end

  defp manifest(routes \\ %{@admin_route_id => admin_route()}) do
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
      routes: routes
    }
  end

  defp admin_route do
    %RouteEntry{
      id: @admin_route_id,
      path: @admin_path,
      runtime: :live_view,
      entry: :internal_only,
      offline: :unavailable,
      security: :sensitive,
      auth_min_level: :mfa,
      requires_recent_auth: 300,
      auth_posture: :strict_recent
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

  defp stale_auth_context do
    auth_context(
      lane: [
        assurance_level: :mfa,
        authenticated_at: "2026-06-05T11:50:00Z",
        as_of: @fixed_now
      ]
    )
  end

  defp auth_context(%Contracts.SessionAuthorityLane{} = lane) do
    %Contracts.AuthContext{
      actor_id: lane.subject_ref,
      org_id: lane.org_id,
      mfa_level: lane.assurance_level,
      auth_age: Contracts.lane_auth_age_seconds(lane, lane.as_of),
      session_authority_lane: lane,
      as_of: lane.as_of
    }
  end

  defp auth_context(opts) do
    opts
    |> Keyword.get(:lane, [])
    |> session_authority_lane()
    |> auth_context()
  end

  defp session_authority_lane(overrides) do
    attrs =
      Keyword.merge(
        [
          session_ref: "sess_backend_73",
          subject_ref: "sub_backend",
          org_id: "org_backend",
          state: :active,
          assurance_level: :mfa,
          authn_methods: [:password, :totp],
          authenticated_at: @fixed_now,
          last_seen_at: @fixed_now,
          idle_expires_at: "2026-06-05T12:30:00Z",
          absolute_expires_at: "2026-06-06T12:00:00Z",
          session_version: 73,
          as_of: @fixed_now,
          remembered: false,
          cached: false
        ],
        overrides
      )

    struct!(Contracts.SessionAuthorityLane, attrs)
  end
end
