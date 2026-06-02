defmodule Crosswake.Companions.Sigra.HandoffTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff
  alias Crosswake.Shell.Denial

  describe "HandoffEnvelope" do
    test "accepts only bounded locator and correlation claims" do
      assert {:ok, envelope} = Handoff.new_handoff_envelope(envelope_attrs())

      assert %Handoff.HandoffEnvelope{} = envelope
      assert envelope.typ == "crosswake.sigra.handoff.v1"
      assert envelope.ticket_ref == "hnd_locator_123"
      assert envelope.version == "1"
      assert envelope.intent_kind == :session_handoff
      assert envelope.route_id == "saas-profile-settings"
      assert envelope.binding_kind == :session_route_intent
      assert envelope.record_digest == "sha256.record"
    end

    test "rejects authority, identity, credential, and token-bearing envelope claims" do
      forbidden_keys = [
        :subject_ref,
        :org_id,
        :session_ref,
        :device_ref,
        :credential_id,
        :oauth_artifact,
        :provider_payload,
        :csrf_token,
        :nonce,
        :pkce_verifier,
        :state,
        :assurance_level,
        :authn_methods,
        :session_authority_lane,
        :session_version
      ]

      attrs =
        forbidden_keys
        |> Map.new(&{&1, "client supplied"})
        |> Map.merge(envelope_attrs())

      assert {:error, errors} = Handoff.new_handoff_envelope(attrs)

      for key <- forbidden_keys do
        assert {:handoff_envelope, {key, :forbidden}} in errors
      end
    end

    test "rejects unsupported envelope claims instead of silently widening" do
      assert {:error, errors} =
               Handoff.new_handoff_envelope(Map.put(envelope_attrs(), :return_to, "/admin"))

      assert {:handoff_envelope, {:return_to, :unsupported_claim}} in errors
    end
  end

  describe "HandoffTicketRecord" do
    test "requires authoritative lifecycle binding and projection fields" do
      assert {:ok, record} = Handoff.new_handoff_ticket_record(ticket_record_attrs())

      assert %Handoff.HandoffTicketRecord{} = record
      assert record.state == :issued
      assert record.subject_ref == "sub_backend_123"
      assert record.org_id == "org_backend_123"
      assert record.source_session_ref == "sess_source_123"
      assert record.target_route_id == "saas-profile-settings"
      assert %Contracts.SessionAuthorityLane{} = record.projected_session_authority_lane
    end

    test "limits lifecycle states to issued redeemed expired and revoked" do
      assert Handoff.lifecycle_states() == [:issued, :redeemed, :expired, :revoked]

      for state <- Handoff.lifecycle_states() do
        assert {:ok, _record} =
                 Handoff.new_handoff_ticket_record(ticket_record_attrs(%{state: state}))
      end

      assert {:error, errors} =
               Handoff.new_handoff_ticket_record(ticket_record_attrs(%{state: :pending}))

      assert {:state, {:invalid_value, :pending}} in errors
    end

    test "requires a projected SessionAuthorityLane instead of parallel authority data" do
      assert {:error, errors} =
               Handoff.new_handoff_ticket_record(
                 ticket_record_attrs(%{projected_session_authority_lane: %{state: :active}})
               )

      assert {:session_authority_lane, :invalid_contract} in errors
    end
  end

  describe "redemption audit and renewal contracts" do
    test "require projected authority and host-owned session renewal instructions" do
      assert {:ok, lane} = Contracts.new_session_authority_lane(session_authority_lane_attrs())

      assert {:ok, renewal} =
               Handoff.new_session_renewal_instructions(%{
                 renew_session?: true,
                 put_session: %{
                   "crosswake_session_ref" => "sess_projected_123",
                   "crosswake_session_version" => 43
                 },
                 delete_session: ["crosswake_step_up_challenge"],
                 projected_session_ref: "sess_projected_123",
                 projected_session_version: 43
               })

      assert {:ok, audit_event} = Handoff.new_handoff_audit_event(audit_event_attrs())

      assert {:ok, redemption} =
               Handoff.new_handoff_redemption(%{
                 handoff_ref: "support_handoff_123",
                 consumed_at: "2026-06-02T12:01:00Z",
                 session_authority_lane: lane,
                 session_projection: %{session_ref: "sess_projected_123", session_version: 43},
                 session_renewal_instructions: renewal,
                 route_target: %{route_id: "saas-profile-settings", path: "/saas/profile"},
                 audit_event: audit_event
               })

      assert %Handoff.HandoffRedemption{} = redemption
      assert redemption.session_authority_lane == lane
      assert redemption.session_renewal_instructions.renew_session? == true
      refute Map.has_key?(redemption, :conn)
      refute Map.has_key?(renewal, :plug_conn)
    end

    test "stays pure Elixir without Phoenix Ecto Repo or Plug coupling" do
      source = File.read!("lib/crosswake/companions/sigra/handoff.ex")

      refute String.contains?(source, "Phoenix" <> ".Token")
      refute String.contains?(source, "Ecto" <> ".Schema")
      refute String.contains?(source, "Repo.")
      refute String.contains?(source, "Plug" <> ".Conn")
      refute String.contains?(source, "configure_" <> "session")
    end
  end

  describe "DenialCodes handoff registry" do
    test "includes exact handoff subcodes under the existing public step-up reason" do
      handoff_codes = [
        "auth.handoff.missing_ticket",
        "auth.handoff.invalid_ticket",
        "auth.handoff.expired_ticket",
        "auth.handoff.replayed_ticket",
        "auth.handoff.revoked_ticket",
        "auth.handoff.binding_mismatch",
        "auth.handoff.intent_mismatch",
        "auth.handoff.route_mismatch",
        "auth.handoff.projection_failed"
      ]

      assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.handoff.")) ==
               handoff_codes

      for code <- handoff_codes do
        denial =
          Denial.new(
            reason: :step_up_required,
            code: code,
            message: "Additional authentication is required.",
            details: DenialCodes.sanitize_details(%{handoff_state: :issued})
          )

        assert denial.reason == :step_up_required
        assert denial.code == code
      end
    end

    test "sanitizes handoff denial details and drops ticket session identity and secret fields" do
      sanitized =
        DenialCodes.sanitize_details(%{
          handoff_ref: "support:hnd.safe_123",
          handoff_state: :issued,
          handoff_kind: :session_handoff,
          handoff_version: "1",
          handoff_transport: :signed_envelope,
          binding_kind: :session_route_intent,
          intent_kind: :session_handoff,
          route_binding: "saas-profile-settings",
          ticket_expires_at: "2026-06-02T12:03:00Z",
          ticket_age_seconds: 60,
          evaluated_at: "2026-06-02T12:01:00Z",
          ticket_ref: "hnd_raw_ticket",
          ticket_digest: "sha256.secret",
          session_ref: "sess_secret",
          subject_ref: "sub_secret",
          org_id: "org_secret",
          device_ref: "device_secret",
          provider_payload: %{secret: true},
          credential_id: "credential_secret",
          ip: "203.0.113.1",
          user_agent: "Browser",
          nonce: "nonce_secret",
          csrf_token: "csrf_secret",
          pkce_verifier: "pkce_secret"
        })

      assert sanitized == %{
               "handoff_ref" => "support:hnd.safe_123",
               "handoff_state" => "issued",
               "handoff_kind" => "session_handoff",
               "handoff_version" => "1",
               "handoff_transport" => "signed_envelope",
               "binding_kind" => "session_route_intent",
               "intent_kind" => "session_handoff",
               "route_binding" => "saas-profile-settings",
               "ticket_expires_at" => "2026-06-02T12:03:00Z",
               "ticket_age_seconds" => 60,
               "evaluated_at" => "2026-06-02T12:01:00Z"
             }
    end

    test "collapses public invalid handoff cases to invalid_ticket" do
      public_invalid_cases = [
        :malformed_envelope,
        :bad_signature,
        :unsupported_version,
        :unknown_record,
        :tamper
      ]

      for cause <- public_invalid_cases do
        denial =
          Denial.new(
            reason: :step_up_required,
            code: "auth.handoff.invalid_ticket",
            message: "Additional authentication is required.",
            details: DenialCodes.sanitize_details(%{handoff_kind: cause})
          )

        assert denial.reason == :step_up_required
        assert denial.code == "auth.handoff.invalid_ticket"
        refute Map.has_key?(denial.details, "ticket_ref")
      end
    end
  end

  defp envelope_attrs(overrides \\ %{}) do
    %{
      typ: "crosswake.sigra.handoff.v1",
      ticket_ref: "hnd_locator_123",
      version: "1",
      issuer: "crosswake_example",
      audience: "crosswake.sigra.handoff",
      issued_at: "2026-06-02T12:00:00Z",
      expires_at: "2026-06-02T12:03:00Z",
      intent_kind: :session_handoff,
      route_id: "saas-profile-settings",
      binding_kind: :session_route_intent,
      record_digest: "sha256.record",
      correlation_digest: "sha256.correlation",
      handoff_transport: "signed_envelope"
    }
    |> Map.merge(overrides)
  end

  defp ticket_record_attrs(overrides \\ %{}) do
    {:ok, lane} = Contracts.new_session_authority_lane(session_authority_lane_attrs())

    %{
      ticket_ref: "hnd_record_123",
      ticket_digest: "sha256.ticket",
      state: :issued,
      subject_ref: "sub_backend_123",
      org_id: "org_backend_123",
      source_session_ref: "sess_source_123",
      expected_session_version: 42,
      binding_kind: :session_route_intent,
      intent_kind: :session_handoff,
      intent_ref: "intent_backend_123",
      source_route_id: "login-return",
      target_route_id: "saas-profile-settings",
      required_assurance_level: :mfa,
      required_auth_posture: :strict_recent,
      issued_at: "2026-06-02T12:00:00Z",
      expires_at: "2026-06-02T12:03:00Z",
      audit_correlation_ref: "audit_safe_123",
      projected_session_authority_lane: lane
    }
    |> Map.merge(overrides)
  end

  defp audit_event_attrs(overrides \\ %{}) do
    %{
      event_id: "evt_handoff_123",
      event_type: :redeem,
      handoff_ref: "support_handoff_123",
      ticket_ref: "hnd_record_123",
      state_before: :issued,
      state_after: :redeemed,
      outcome: :allowed,
      occurred_at: "2026-06-02T12:01:00Z",
      route_id: "saas-profile-settings",
      intent_kind: :session_handoff,
      intent_ref: "intent_backend_123",
      source_session_ref: "sess_source_123",
      projected_session_ref: "sess_projected_123",
      session_version_before: 42,
      session_version_after: 43,
      assurance_after: :mfa,
      authn_methods_after: [:password, :totp],
      binding_result: "matched",
      request_ref: "req_safe_123",
      actor_kind: :subject,
      metadata: %{audit_class: "handoff"}
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
