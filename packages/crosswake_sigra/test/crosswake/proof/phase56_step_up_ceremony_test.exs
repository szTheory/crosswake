defmodule Crosswake.Proof.Phase56StepUpCeremonyTest do
  # async: false because the support-truth test calls Application.put_env.
  # Pure sigra-logic tests would be async-safe but they share this module.
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.Finding
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.StepUp
  alias Crosswake.Companions.Sigra.StepUpCeremony
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  @step_up_intent_codes [
    "auth.step_up_intent.missing_intent",
    "auth.step_up_intent.invalid_intent",
    "auth.step_up_intent.expired_intent",
    "auth.step_up_intent.consumed_intent",
    "auth.step_up_intent.canceled_intent",
    "auth.step_up_intent.revoked_intent",
    "auth.step_up_intent.route_mismatch",
    "auth.step_up_intent.binding_mismatch",
    "auth.step_up_intent.challenge_failed",
    "auth.step_up_intent.projection_failed"
  ]

  # D-137-03: Register sigra in test setup so SupportMatrix.auth_contract_truth/0
  # returns a populated row (denial_codes, safe_detail_keys) rather than sentinels.
  setup do
    prior = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, prior)
    end)

    :ok
  end

  test "phase 56 locks the exact step-up intent denial vocabulary" do
    assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.step_up_intent.")) ==
             @step_up_intent_codes

    assert Enum.all?(@step_up_intent_codes, &DenialCodes.valid_code?/1)
  end

  test "step-up intent denials keep the existing public step-up shell reason" do
    for code <- @step_up_intent_codes do
      denial =
        Denial.new(
          reason: :step_up_required,
          code: code,
          message: "Additional authentication is required.",
          details:
            DenialCodes.sanitize_details(%{
              step_up_intent_ref: "support:sup.safe",
              intent_state: :issued
            })
        )

      assert denial.reason == :step_up_required
      assert denial.code == code
      refute :step_up_intent_denied in Denial.reasons()
    end
  end

  test "safe step-up intent detail allowlist excludes raw locator session identity and secret fields" do
    allowed = DenialCodes.allowed_detail_keys()

    for key <- [
          "step_up_intent_ref",
          "intent_state",
          "challenge_kind",
          "route_binding",
          "intent_expires_at",
          "intent_age_seconds"
        ] do
      assert key in allowed
    end

    for key <- [
          "intent_ref",
          "locator_token",
          "session_ref",
          "actor_id",
          "org_id",
          "device_ref",
          "provider_payload",
          "passkey_credential_id",
          "oauth_access_token",
          "csrf_token",
          "nonce",
          "pkce_verifier",
          "ip",
          "user_agent"
        ] do
      refute key in allowed
    end
  end

  test "malformed tampered unknown and unsupported locators collapse publicly to invalid_intent" do
    for cause <- [:malformed_locator, :tampered_locator, :unknown_intent, :unsupported_version] do
      denial =
        Denial.new(
          reason: :step_up_required,
          code: "auth.step_up_intent.invalid_intent",
          message: "Additional authentication is required.",
          details:
            DenialCodes.sanitize_details(%{
              challenge_kind: cause,
              locator_token: "raw.secret",
              session_ref: "sess_secret",
              actor_id: "actor_secret"
            })
        )

      assert denial.reason == :step_up_required
      assert denial.code == "auth.step_up_intent.invalid_intent"
      assert denial.details == %{"challenge_kind" => Atom.to_string(cause)}
    end
  end

  test "step-up locator cannot become self-contained authority" do
    assert {:error, errors} =
             StepUp.new_step_up_intent_locator(%{
               typ: "crosswake.sigra.step_up.v1",
               intent_ref: "sup_locator_123",
               version: "1",
               issuer: "crosswake_example",
               audience: "crosswake.sigra.step_up",
               issued_at: "2026-06-02T12:00:00Z",
               expires_at: "2026-06-02T12:05:00Z",
               source_route_id: "saas-admin",
               return_route_id: "saas-billing",
               challenge_kind: :host_confirm_password,
               session_ref: "sess_secret",
               subject_ref: "sub_secret",
               org_id: "org_secret",
               assurance_level: :mfa,
               session_authority_lane: %{state: :active}
             })

    assert {:step_up_intent_locator, {:session_ref, :forbidden}} in errors
    assert {:step_up_intent_locator, {:subject_ref, :forbidden}} in errors
    assert {:step_up_intent_locator, {:org_id, :forbidden}} in errors
    assert {:step_up_intent_locator, {:assurance_level, :forbidden}} in errors
    assert {:step_up_intent_locator, {:session_authority_lane, :forbidden}} in errors
  end

  test "shared ceremony core allows sufficient auth challenges step-up denials and preserves host denials" do
    route =
      struct!(Crosswake.Manifest.Types.RouteEntry,
        id: "saas-profile-settings",
        path: "/saas/settings/profile",
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard,
        auth_min_level: :mfa,
        requires_recent_auth: 900,
        auth_posture: :strict_recent
      )

    lane = session_authority_lane(:password, 43)
    auth_context = auth_context(lane)

    assert {:allow, %{ok: true}} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result: {:allow, %{facts: %{ok: true}}}
             )

    # D-137-A: evaluator_result fixtures now use %Finding{axis: :auth} shape (Plan 02).
    assert {:challenge, %StepUp.StepUpIntentRecord{}, %StepUp.StepUpChallenge{} = challenge} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result:
                 {:deny,
                  %Finding{
                    axis: :auth,
                    code: "auth.step_up.insufficient_assurance",
                    message: "Additional authentication is required.",
                    details: %{}
                  }},
               issue_intent: fn _attrs ->
                 {:ok, %{intent: step_up_intent_record(), challenge: step_up_challenge()}}
               end
             )

    assert challenge.return_route_id == "saas-profile-settings"
    assert challenge.required_assurance_level == :mfa

    # host_denial is now a Finding — issue_intent returns {:error, %Finding{axis: :auth}}.
    # StepUpCeremony.normalize_issue_result passes it through as {:deny, finding}.
    host_denial = %Finding{
      axis: :auth,
      code: "auth.step_up_intent.route_mismatch",
      message: "Additional authentication is required.",
      details: %{}
    }

    assert {:deny, ^host_denial} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result:
                 {:deny,
                  %Finding{
                    axis: :auth,
                    code: "auth.step_up.stale_auth",
                    message: "Additional authentication is required.",
                    details: %{}
                  }},
               issue_intent: fn _attrs -> {:error, host_denial} end
             )

    non_challengeable = %Finding{
      axis: :auth,
      code: "auth.step_up.revoked",
      message: "Additional authentication is required.",
      details: %{}
    }

    assert {:deny, ^non_challengeable} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result: {:deny, non_challengeable},
               issue_intent: fn _attrs -> flunk("non-challengeable denial must not issue") end
             )
  end

  test "ceremony core and evaluator preserve pure transport and persistence boundaries" do
    ceremony_source = File.read!("lib/crosswake/companions/sigra/step_up_ceremony.ex")
    evaluator_source = File.read!("lib/crosswake/companions/sigra/evaluator.ex")

    for forbidden <- [
          "Ecto",
          "Phoenix.Controller",
          "Plug.Conn",
          "Phoenix.LiveView",
          "Phoenix.Token",
          "CrosswakeExample"
        ] do
      refute String.contains?(ceremony_source, forbidden)
    end

    refute evaluator_source =~ "StepUp.issue"
    refute evaluator_source =~ "redirect("
    refute evaluator_source =~ "halt("
    refute evaluator_source =~ "configure_session"
    refute String.contains?(String.downcase(evaluator_source), "csrf")
  end

  test "plug and liveview adapters call shared ceremony and avoid duplicated auth checks" do
    plug_source =
      File.read!("../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex")

    on_mount_source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex"
      )

    for source <- [plug_source, on_mount_source] do
      assert source =~ "StepUpCeremony.evaluate_or_issue"

      for forbidden <- [
            "idle_expires_at",
            "absolute_expires_at",
            "assurance_level_meets?",
            "Contracts.auth_age_seconds",
            "remembered",
            "cached"
          ] do
        refute String.contains?(source, forbidden)
      end
    end

    assert plug_source =~ "halt()"
    assert on_mount_source =~ "{:halt, redirected}"
  end

  test "support truth diagnostics and docs promote phase 56 without auth-return overclaims" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert :step_up_intent in row.shipped_contracts
    assert :plug_liveview_ceremony in row.shipped_contracts
    refute :ceremony in row.deferred
    refute :auth_return_boundaries in row.deferred
    assert :refresh_tokens in row.deferred
    assert :provider_device_proof in row.deferred
    assert :native_auth_ui in row.deferred
    assert "auth.step_up_intent.invalid_intent" in row.denial_codes
    assert "step_up_intent_ref" in row.safe_detail_keys
    assert row.step_up.lifecycle_states == StepUp.lifecycle_states()
    assert row.step_up.route_target_validation == :manifest_route_id
    assert row.step_up.csrf_rotation == :host_instruction
    assert row.step_up.liveview_invalidation == :required

    companions = File.read!("../../guides/companions.md")
    support = File.read!("../../guides/support_matrix.md")
    native_shell = File.read!("../../guides/native_shell.md")

    for doc <- [companions, support, native_shell] do
      assert doc =~ "step-up intent"
      assert doc =~ "Plug/LiveView ceremony"
      assert doc =~ "OAuth"
      assert doc =~ "passkey"
      assert doc =~ "native auth"
      assert doc =~ "refresh-token"
      assert doc =~ "provider/device"
      refute doc =~ "ceremony remains deferred"
    end

    assert companions =~ "direct shell/WebView token authority"
    assert native_shell =~ "the bridge is not an auth authority"
  end

  test "phase 56 roadmap success criteria are represented by code host proof diagnostics and docs" do
    assert File.exists?("lib/crosswake/companions/sigra/step_up.ex")
    assert File.exists?("lib/crosswake/companions/sigra/step_up_ceremony.ex")

    assert File.exists?(
             "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up.ex"
           )

    assert File.exists?(
             "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex"
           )

    assert File.exists?(
             "../../examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex"
           )

    proof_source = File.read!(__ENV__.file)

    for required <- [
          "sigra_step_up_intents",
          "auth.step_up_intent.consumed_intent",
          "auth.step_up_intent.expired_intent",
          "auth.step_up_intent.canceled_intent",
          "auth.step_up_intent.revoked_intent",
          "auth.step_up_intent.route_mismatch",
          "auth.step_up_intent.binding_mismatch",
          "auth.step_up_intent.projection_failed",
          "renew_session?",
          "rotate_csrf?",
          "live_socket_invalidation",
          "StepUpCeremony.evaluate_or_issue"
        ] do
      assert proof_source =~ required
    end
  end

  defp auth_context(lane) do
    struct!(Crosswake.Companions.Sigra.Contracts.AuthContext,
      actor_id: lane.subject_ref,
      org_id: lane.org_id,
      mfa_level: lane.assurance_level,
      auth_age: 0,
      session_authority_lane: lane,
      as_of: lane.as_of
    )
  end

  defp step_up_intent_record do
    {:ok, record} =
      StepUp.new_step_up_intent_record(%{
        intent_ref: "sup_record_123",
        locator_digest: "sha256.locator",
        state: :issued,
        subject_ref: "sub_backend_123",
        org_id: "org_backend_123",
        source_session_ref: "sess_source_123",
        expected_session_version: 42,
        source_route_id: "saas-dashboard",
        return_route_id: "saas-profile-settings",
        required_assurance_level: :mfa,
        required_auth_posture: :strict_recent,
        max_auth_age_seconds: 300,
        challenge_kind: :host_confirm_password,
        issued_at: "2026-06-02T12:00:00Z",
        expires_at: "2026-06-02T12:05:00Z",
        audit_correlation_ref: "support:sup.safe",
        projected_session_authority_lane: session_authority_lane(:mfa, 43)
      })

    record
  end

  defp step_up_challenge do
    {:ok, challenge} =
      StepUp.new_step_up_challenge(%{
        challenge_ref: "support:sup.safe",
        intent_ref: "support:sup.safe",
        challenge_kind: :host_confirm_password,
        challenge_route_id: "sigra-step-up",
        return_route_id: "saas-profile-settings",
        required_assurance_level: :mfa,
        max_auth_age_seconds: 300,
        issued_at: "2026-06-02T12:00:00Z",
        expires_at: "2026-06-02T12:05:00Z",
        support_ref: "support:sup.safe"
      })

    challenge
  end

  defp session_authority_lane(assurance, version) do
    {:ok, lane} =
      Crosswake.Companions.Sigra.Contracts.new_session_authority_lane(%{
        session_ref: "sess_projected_123",
        subject_ref: "sub_backend_123",
        org_id: "org_backend_123",
        state: :active,
        assurance_level: assurance,
        authn_methods: [:password, :totp],
        authenticated_at: "2026-06-02T12:00:00Z",
        last_seen_at: "2026-06-02T12:01:00Z",
        idle_expires_at: "2026-06-02T12:31:00Z",
        absolute_expires_at: "2026-06-03T12:00:00Z",
        session_version: version,
        as_of: "2026-06-02T12:01:00Z"
      })

    lane
  end
end
