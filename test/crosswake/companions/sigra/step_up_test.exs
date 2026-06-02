defmodule Crosswake.Companions.Sigra.StepUpTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.StepUp
  alias Crosswake.Shell.Denial

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

  describe "StepUpIntentLocator" do
    test "accepts only low-sensitivity locator and correlation claims" do
      assert {:ok, locator} = StepUp.new_step_up_intent_locator(locator_attrs())

      assert %StepUp.StepUpIntentLocator{} = locator
      assert locator.typ == "crosswake.sigra.step_up.v1"
      assert locator.intent_ref == "sup_locator_123"
      assert locator.source_route_id == "saas-admin"
      assert locator.return_route_id == "saas-billing"
      assert locator.challenge_kind == :host_confirm_password
      assert locator.record_digest == "sha256.record"
      assert locator.step_up_transport == "signed_locator"
    end

    test "rejects authority, identity, credential, session, and token-bearing claims" do
      forbidden_keys = [
        :session_ref,
        :subject_ref,
        :org_id,
        :oauth_access_token,
        :passkey_credential_id,
        :csrf_token,
        :nonce,
        :pkce_verifier,
        :assurance_level,
        :session_authority_lane
      ]

      attrs =
        forbidden_keys
        |> Map.new(&{&1, "client supplied"})
        |> Map.merge(locator_attrs())

      assert {:error, errors} = StepUp.new_step_up_intent_locator(attrs)

      for key <- forbidden_keys do
        assert {:step_up_intent_locator, {key, :forbidden}} in errors
      end
    end

    test "rejects unsupported locator claims instead of silently widening" do
      assert {:error, errors} =
               StepUp.new_step_up_intent_locator(Map.put(locator_attrs(), :return_to, "/admin"))

      assert {:step_up_intent_locator, {:return_to, :unsupported_claim}} in errors
    end
  end

  describe "StepUpIntentRecord" do
    test "limits lifecycle states to issued challenged consumed expired canceled and revoked" do
      assert StepUp.lifecycle_states() == [
               :issued,
               :challenged,
               :consumed,
               :expired,
               :canceled,
               :revoked
             ]

      for state <- StepUp.lifecycle_states() do
        assert {:ok, _record} =
                 StepUp.new_step_up_intent_record(intent_record_attrs(%{state: state}))
      end

      assert {:error, errors} =
               StepUp.new_step_up_intent_record(intent_record_attrs(%{state: :pending}))

      assert {:state, {:invalid_value, :pending}} in errors
    end

    test "requires backend projection instead of parallel authority data" do
      assert {:ok, record} = StepUp.new_step_up_intent_record(intent_record_attrs())

      assert %StepUp.StepUpIntentRecord{} = record
      assert record.return_route_id == "saas-billing"
      assert record.required_assurance_level == :mfa
      assert %Contracts.SessionAuthorityLane{} = record.projected_session_authority_lane

      assert {:error, errors} =
               StepUp.new_step_up_intent_record(
                 intent_record_attrs(%{projected_session_authority_lane: %{state: :active}})
               )

      assert {:session_authority_lane, :invalid_contract} in errors
    end
  end

  describe "challenge consume completion audit and renewal contracts" do
    test "constructs bounded challenge and consume request contracts" do
      assert {:ok, locator} = StepUp.new_step_up_intent_locator(locator_attrs())

      assert {:ok, challenge} =
               StepUp.new_step_up_challenge(%{
                 challenge_ref: "support:sup.challenge",
                 intent_ref: "support:sup.safe",
                 challenge_kind: :host_confirm_password,
                 challenge_route_id: "sigra-step-up",
                 return_route_id: "saas-billing",
                 required_assurance_level: :mfa,
                 max_auth_age_seconds: 300,
                 issued_at: "2026-06-02T12:00:00Z",
                 expires_at: "2026-06-02T12:05:00Z",
                 message: "Additional authentication is required.",
                 support_ref: "support:sup.safe"
               })

      assert challenge.challenge_kind == :host_confirm_password

      assert {:ok, request} =
               StepUp.new_step_up_consume_request(%{
                 locator: locator,
                 expected_source_route_id: "saas-admin",
                 expected_return_route_id: "saas-billing",
                 expected_challenge_kind: :host_confirm_password,
                 source_session_ref: "sess_source_123",
                 expected_session_version: 42,
                 challenge_evidence: %{host_verified_at: "2026-06-02T12:01:00Z"},
                 request_ref: "req_safe_123",
                 evaluated_at: "2026-06-02T12:01:00Z"
               })

      assert request.locator == locator
    end

    test "completion requires SessionAuthorityLane and host-owned renewal instructions" do
      assert {:ok, lane} = Contracts.new_session_authority_lane(session_authority_lane_attrs())

      assert {:ok, renewal} =
               StepUp.new_session_renewal_instructions(%{
                 renew_session?: true,
                 rotate_csrf?: true,
                 put_session: %{
                   "crosswake_session_ref" => "sess_projected_123",
                   "crosswake_session_version" => 43
                 },
                 delete_session: ["crosswake_step_up_intent_ref", "crosswake_step_up_challenge"],
                 projected_session_ref: "sess_projected_123",
                 projected_session_version: 43,
                 live_socket_invalidation: %{reason: :step_up_completed}
               })

      assert {:ok, audit_event} = StepUp.new_step_up_audit_event(audit_event_attrs())

      assert {:ok, completion} =
               StepUp.new_step_up_completion(%{
                 step_up_intent_ref: "support:sup.safe",
                 consumed_at: "2026-06-02T12:01:00Z",
                 session_authority_lane: lane,
                 session_projection: %{session_ref: "sess_projected_123", session_version: 43},
                 session_renewal_instructions: renewal,
                 route_target: %{route_id: "saas-billing", path: "/saas/billing"},
                 audit_event: audit_event
               })

      assert completion.session_authority_lane == lane
      assert completion.session_renewal_instructions.renew_session? == true
      assert completion.session_renewal_instructions.rotate_csrf? == true

      assert {:error, errors} =
               StepUp.new_step_up_completion(%{
                 step_up_intent_ref: "support:sup.safe",
                 consumed_at: "2026-06-02T12:01:00Z",
                 session_authority_lane: %{state: :active},
                 session_renewal_instructions: renewal,
                 route_target: %{route_id: "saas-billing"}
               })

      assert {:session_authority_lane, :invalid_contract} in errors
    end

    test "stays pure Elixir without host transport or persistence coupling" do
      source = File.read!("lib/crosswake/companions/sigra/step_up.ex")

      refute String.contains?(source, "Ecto")
      refute String.contains?(source, "Phoenix" <> ".Token")
      refute String.contains?(source, "Plug" <> ".Conn")
      refute String.contains?(source, "Phoenix.LiveView")
      refute String.contains?(source, "CrosswakeExample")
    end
  end

  describe "DenialCodes step-up intent registry" do
    test "includes exact step-up intent subcodes under the existing public shell reason" do
      assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.step_up_intent.")) ==
               @step_up_intent_codes

      for code <- @step_up_intent_codes do
        denial =
          Denial.new(
            reason: :step_up_required,
            code: code,
            message: "Additional authentication is required.",
            details: DenialCodes.sanitize_details(%{intent_state: :issued})
          )

        assert denial.reason == :step_up_required
        assert denial.code == code
      end
    end

    test "sanitizes step-up intent denial details and drops raw sensitive fields" do
      sanitized =
        DenialCodes.sanitize_details(%{
          step_up_intent_ref: "support:sup.safe_123",
          intent_state: :issued,
          challenge_kind: :host_confirm_password,
          route_binding: "saas-admin->saas-billing",
          intent_expires_at: "2026-06-02T12:05:00Z",
          intent_age_seconds: 60,
          intent_ref: "sup_raw",
          locator_token: "secret.locator",
          session_ref: "sess_secret",
          actor_id: "actor_secret",
          org_id: "org_secret",
          device_ref: "device_secret",
          provider_payload: %{secret: true},
          passkey_credential_id: "credential_secret",
          oauth_access_token: "oauth_secret",
          csrf_token: "csrf_secret",
          nonce: "nonce_secret",
          pkce_verifier: "pkce_secret",
          ip: "203.0.113.1",
          user_agent: "Browser"
        })

      assert sanitized == %{
               "step_up_intent_ref" => "support:sup.safe_123",
               "intent_state" => "issued",
               "challenge_kind" => "host_confirm_password",
               "route_binding" => "saas-admin->saas-billing",
               "intent_expires_at" => "2026-06-02T12:05:00Z",
               "intent_age_seconds" => 60
             }
    end

    test "collapses public invalid locator cases to invalid_intent" do
      for cause <- [:malformed_locator, :tamper, :unknown_record, :unsupported_version] do
        denial =
          Denial.new(
            reason: :step_up_required,
            code: "auth.step_up_intent.invalid_intent",
            message: "Additional authentication is required.",
            details: DenialCodes.sanitize_details(%{challenge_kind: cause, locator_token: "raw"})
          )

        assert denial.reason == :step_up_required
        assert denial.code == "auth.step_up_intent.invalid_intent"
        refute Map.has_key?(denial.details, "locator_token")
      end
    end
  end

  defp locator_attrs(overrides \\ %{}) do
    %{
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
      record_digest: "sha256.record",
      correlation_digest: "sha256.correlation",
      step_up_transport: "signed_locator"
    }
    |> Map.merge(overrides)
  end

  defp intent_record_attrs(overrides \\ %{}) do
    {:ok, lane} = Contracts.new_session_authority_lane(session_authority_lane_attrs())

    %{
      intent_ref: "sup_record_123",
      locator_digest: "sha256.locator",
      state: :issued,
      subject_ref: "sub_backend_123",
      org_id: "org_backend_123",
      source_session_ref: "sess_source_123",
      expected_session_version: 42,
      source_route_id: "saas-admin",
      return_route_id: "saas-billing",
      return_params: %{"tab" => "payment_methods"},
      required_assurance_level: :mfa,
      required_auth_posture: :strict_recent,
      max_auth_age_seconds: 300,
      challenge_kind: :host_confirm_password,
      issued_at: "2026-06-02T12:00:00Z",
      expires_at: "2026-06-02T12:05:00Z",
      audit_correlation_ref: "audit_safe_123",
      projected_session_authority_lane: lane
    }
    |> Map.merge(overrides)
  end

  defp audit_event_attrs(overrides \\ %{}) do
    %{
      event_id: "evt_step_up_123",
      event_type: :consume,
      step_up_intent_ref: "support:sup.safe",
      intent_ref: "sup_record_123",
      state_before: :challenged,
      state_after: :consumed,
      outcome: :allowed,
      occurred_at: "2026-06-02T12:01:00Z",
      route_id: "saas-billing",
      challenge_kind: :host_confirm_password,
      source_session_ref: "sess_source_123",
      projected_session_ref: "sess_projected_123",
      session_version_before: 42,
      session_version_after: 43,
      assurance_after: :mfa,
      authn_methods_after: [:password, :totp],
      binding_result: "matched",
      request_ref: "req_safe_123",
      actor_kind: :subject,
      metadata: %{audit_class: "step_up"}
    }
    |> Map.merge(overrides)
  end

  defp session_authority_lane_attrs(overrides \\ %{}) do
    %{
      session_ref: "sess_projected_123",
      subject_ref: "sub_backend_123",
      org_id: "org_backend_123",
      state: :active,
      assurance_level: :mfa,
      authn_methods: [:password, :totp],
      authenticated_at: "2026-06-02T12:00:00Z",
      last_seen_at: "2026-06-02T12:01:00Z",
      idle_expires_at: "2026-06-02T12:31:00Z",
      absolute_expires_at: "2026-06-03T12:00:00Z",
      renew_after: "2026-06-02T12:20:00Z",
      remembered: false,
      cached: false,
      session_version: 43,
      revoked_at: nil,
      as_of: "2026-06-02T12:01:00Z"
    }
    |> Map.merge(overrides)
  end
end
