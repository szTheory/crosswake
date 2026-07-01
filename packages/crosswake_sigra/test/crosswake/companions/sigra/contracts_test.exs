defmodule Crosswake.Companions.Sigra.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes

  describe "AuthContext" do
    test "constructs typed auth context with normalized auth age for route comparison" do
      assert {:ok, auth_context} = Contracts.new_auth_context(auth_context_attrs())

      assert %Contracts.AuthContext{} = auth_context
      assert auth_context.actor_id == "actor_123"
      assert auth_context.org_id == "org_123"
      assert auth_context.mfa_level == :mfa
      assert auth_context.auth_age == 120
      assert Contracts.auth_age_seconds(auth_context) == 120
    end

    test "derives route auth aliases from backend-owned session authority lane" do
      assert {:ok, lane} = Contracts.new_session_authority_lane(session_authority_lane_attrs())

      assert {:ok, auth_context} =
               Contracts.new_auth_context(
                 session_authority_lane: lane,
                 as_of: "2026-06-01T00:05:00Z"
               )

      assert auth_context.actor_id == "actor_123"
      assert auth_context.org_id == "org_123"
      assert auth_context.mfa_level == :phishing_resistant
      assert Contracts.auth_age_seconds(auth_context) == 300
    end

    test "rejects invalid mfa level vocabulary" do
      assert {:error, errors} =
               Contracts.new_auth_context(auth_context_attrs(%{mfa_level: :otp_only}))

      assert {:mfa_level, {:invalid_mfa_level, :otp_only}} in errors
    end
  end

  describe "SessionAuthorityLane" do
    test "constructs backend authority lane with explicit lifecycle and assurance fields" do
      assert {:ok, authority_lane} =
               Contracts.new_session_authority_lane(session_authority_lane_attrs())

      assert %Contracts.SessionAuthorityLane{} = authority_lane
      assert authority_lane.session_ref == "session_ref_123"
      assert authority_lane.subject_ref == "actor_123"
      assert authority_lane.state == :active
      assert authority_lane.assurance_level == :phishing_resistant
      assert authority_lane.authn_methods == [:password, :totp]
      assert authority_lane.authenticated_at == "2026-06-01T00:00:00Z"
      assert authority_lane.last_seen_at == "2026-06-01T00:04:00Z"
      assert authority_lane.idle_expires_at == "2026-06-01T00:30:00Z"
      assert authority_lane.absolute_expires_at == "2026-06-02T00:00:00Z"
      assert authority_lane.renew_after == "2026-06-01T00:20:00Z"
      assert authority_lane.remembered == false
      assert authority_lane.cached == false
      assert authority_lane.session_version == 42
      assert authority_lane.revoked_at == nil
      assert authority_lane.as_of == "2026-06-01T00:05:00Z"
    end

    test "rejects invalid assurance level vocabulary" do
      assert {:error, errors} =
               Contracts.new_session_authority_lane(
                 session_authority_lane_attrs(%{assurance_level: :hardware_token})
               )

      assert {:assurance_level, {:invalid_mfa_level, :hardware_token}} in errors
    end

    test "preserves phase 46 aliases without making them authority source of truth" do
      assert {:ok, lane} =
               Contracts.new_session_authority_lane(
                 session_authority_lane_attrs(%{
                   session_ref: nil,
                   subject_ref: nil,
                   state: nil,
                   assurance_level: nil,
                   session_id: "legacy_session_ref",
                   actor_id: "legacy_actor",
                   authority_state: :active,
                   mfa_level: :mfa
                 })
               )

      assert lane.session_ref == "legacy_session_ref"
      assert lane.subject_ref == "legacy_actor"
      assert lane.state == :active
      assert lane.assurance_level == :mfa
    end
  end

  describe "mfa level vocabulary" do
    test "locks closed vocabulary and ordering" do
      assert Contracts.mfa_level_vocabulary() == [:none, :password, :mfa, :phishing_resistant]

      assert Contracts.assurance_level_vocabulary() == [
               :none,
               :password,
               :mfa,
               :phishing_resistant
             ]

      assert Contracts.authority_state_vocabulary() == [
               :active,
               :step_up_required,
               :suspended,
               :expired,
               :revoked
             ]

      assert Contracts.mfa_level_meets?(:phishing_resistant, :mfa)
      assert Contracts.assurance_level_meets?(:mfa, :password)
      refute Contracts.mfa_level_meets?(:password, :mfa)
    end
  end

  describe "evidence authority boundary" do
    test "rejects evidence carrying authority fields" do
      assert {:error, errors} =
               Contracts.validate_evidence_lane(%{
                 client_trace_id: "trace_1",
                 authority_state: :active,
                 state: :active,
                 mfa_level: :mfa,
                 assurance_level: :mfa,
                 auth_level: :mfa,
                 authn_methods: [:password],
                 authenticated_at: "2026-06-01T00:00:00Z",
                 idle_expires_at: "2026-06-01T00:30:00Z",
                 absolute_expires_at: "2026-06-02T00:00:00Z",
                 session_version: 42,
                 revoked_at: nil,
                 session_authority: :backend,
                 access_granted: true
               })

      assert {:evidence, {:authority_state, :forbidden}} in errors
      assert {:evidence, {:state, :forbidden}} in errors
      assert {:evidence, {:mfa_level, :forbidden}} in errors
      assert {:evidence, {:assurance_level, :forbidden}} in errors
      assert {:evidence, {:auth_level, :forbidden}} in errors
      assert {:evidence, {:authn_methods, :forbidden}} in errors
      assert {:evidence, {:authenticated_at, :forbidden}} in errors
      assert {:evidence, {:idle_expires_at, :forbidden}} in errors
      assert {:evidence, {:absolute_expires_at, :forbidden}} in errors
      assert {:evidence, {:session_version, :forbidden}} in errors
      assert {:evidence, {:revoked_at, :forbidden}} in errors
      assert {:evidence, {:session_authority, :forbidden}} in errors
      assert {:evidence, {:access_granted, :forbidden}} in errors
    end
  end

  describe "DenialCodes" do
    test "locks canonical auth step-up subcodes and shell-safe detail allowlist" do
      assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.step_up.")) == [
               "auth.step_up.missing_context",
               "auth.step_up.invalid_context",
               "auth.step_up.non_active",
               "auth.step_up.idle_expired",
               "auth.step_up.absolute_expired",
               "auth.step_up.revoked",
               "auth.step_up.version_mismatch",
               "auth.step_up.insufficient_assurance",
               "auth.step_up.stale_auth",
               "auth.step_up.remembered_not_allowed",
               "auth.step_up.cached_not_allowed"
             ]

      assert "required_assurance_level" in DenialCodes.allowed_detail_keys()
      assert "auth_posture" in DenialCodes.allowed_detail_keys()
      assert "evaluated_at" in DenialCodes.allowed_detail_keys()
    end

    test "sanitizes secret and identity-bearing denial details" do
      sanitized =
        DenialCodes.sanitize_details(%{
          required_assurance_level: :mfa,
          current_assurance_level: :password,
          auth_posture: :strict_recent,
          authority_state: :active,
          evaluated_at: "2026-06-01T00:05:00Z",
          challenge_ref: "challenge:safe-1",
          step_up_token_ref: "stepup.safe_1",
          session_id: "session_secret",
          subject_id: "actor_123",
          org_id: "org_123",
          token: "bearer secret",
          provider_payload: %{secret: true},
          passkey_credential_id: "credential_secret",
          email: "person@example.com"
        })

      assert sanitized == %{
               "required_assurance_level" => "mfa",
               "current_assurance_level" => "password",
               "auth_posture" => "strict_recent",
               "authority_state" => "active",
               "evaluated_at" => "2026-06-01T00:05:00Z",
               "challenge_ref" => "challenge:safe-1",
               "step_up_token_ref" => "stepup.safe_1"
             }
    end
  end

  describe "StepUpChallenge" do
    test "models reference state only without ceremony or token machinery" do
      assert {:ok, challenge} = Contracts.new_step_up_challenge(step_up_challenge_attrs())

      assert %Contracts.StepUpChallenge{} = challenge
      assert challenge.challenge_id == "challenge_123"
      assert challenge.required_mfa_level == :phishing_resistant
      assert challenge.max_auth_age_seconds == 300
      assert challenge.reason == :high_risk_route

      refute Map.has_key?(challenge, :passkey_assertion)
      refute Map.has_key?(challenge, :oauth_code_verifier)
      refute Map.has_key?(challenge, :oauth_access_token)
      refute Map.has_key?(challenge, :refresh_token)
      refute Map.has_key?(challenge, :token_exchange)
    end
  end

  defp auth_context_attrs(overrides \\ %{}) do
    %{
      actor_id: "actor_123",
      org_id: "org_123",
      mfa_level: :mfa,
      auth_age: 120
    }
    |> Map.merge(overrides)
  end

  defp session_authority_lane_attrs(overrides \\ %{}) do
    %{
      session_ref: "session_ref_123",
      subject_ref: "actor_123",
      org_id: "org_123",
      state: :active,
      assurance_level: :phishing_resistant,
      authn_methods: [:password, :totp],
      authenticated_at: "2026-06-01T00:00:00Z",
      last_seen_at: "2026-06-01T00:04:00Z",
      idle_expires_at: "2026-06-01T00:30:00Z",
      absolute_expires_at: "2026-06-02T00:00:00Z",
      renew_after: "2026-06-01T00:20:00Z",
      remembered: false,
      cached: false,
      session_version: 42,
      revoked_at: nil,
      as_of: "2026-06-01T00:05:00Z"
    }
    |> Map.merge(overrides)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp step_up_challenge_attrs(overrides \\ %{}) do
    %{
      challenge_id: "challenge_123",
      required_mfa_level: :phishing_resistant,
      max_auth_age_seconds: 300,
      reason: :high_risk_route,
      issued_at: "2026-05-31T00:00:00Z",
      expires_at: "2026-05-31T00:05:00Z"
    }
    |> Map.merge(overrides)
  end
end
