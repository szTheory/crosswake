defmodule Crosswake.Companions.Sigra.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts

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

    test "rejects invalid mfa level vocabulary" do
      assert {:error, errors} =
               Contracts.new_auth_context(auth_context_attrs(%{mfa_level: :otp_only}))

      assert {:mfa_level, {:invalid_mfa_level, :otp_only}} in errors
    end
  end

  describe "SessionAuthorityLane" do
    test "constructs backend authority lane with valid mfa vocabulary" do
      assert {:ok, authority_lane} =
               Contracts.new_session_authority_lane(session_authority_lane_attrs())

      assert %Contracts.SessionAuthorityLane{} = authority_lane
      assert authority_lane.authority_state == :active
      assert authority_lane.mfa_level == :phishing_resistant
    end

    test "rejects invalid mfa level vocabulary" do
      assert {:error, errors} =
               Contracts.new_session_authority_lane(
                 session_authority_lane_attrs(%{mfa_level: :hardware_token})
               )

      assert {:mfa_level, {:invalid_mfa_level, :hardware_token}} in errors
    end
  end

  describe "mfa level vocabulary" do
    test "locks closed vocabulary and ordering" do
      assert Contracts.mfa_level_vocabulary() == [:none, :password, :mfa, :phishing_resistant]
      assert Contracts.mfa_level_meets?(:phishing_resistant, :mfa)
      refute Contracts.mfa_level_meets?(:password, :mfa)
    end
  end

  describe "evidence authority boundary" do
    test "rejects evidence carrying authority fields" do
      assert {:error, errors} =
               Contracts.validate_evidence_lane(%{
                 client_trace_id: "trace_1",
                 authority_state: :active,
                 mfa_level: :mfa,
                 auth_level: :mfa,
                 session_authority: :backend,
                 access_granted: true
               })

      assert {:evidence, {:authority_state, :forbidden}} in errors
      assert {:evidence, {:mfa_level, :forbidden}} in errors
      assert {:evidence, {:auth_level, :forbidden}} in errors
      assert {:evidence, {:session_authority, :forbidden}} in errors
      assert {:evidence, {:access_granted, :forbidden}} in errors
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
      authority_state: :active,
      mfa_level: :phishing_resistant,
      auth_age_seconds: 45,
      authenticated_at: "2026-05-31T00:00:00Z"
    }
    |> Map.merge(overrides)
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
