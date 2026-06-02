defmodule Crosswake.Proof.Phase54SigraSessionAuthorityTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Evaluator
  alias Crosswake.Manifest.Types.RouteEntry

  test "phase 54 authority contract is backend owned and lifecycle explicit" do
    assert {:ok, lane} =
             Contracts.new_session_authority_lane(%{
               session_ref: "session_ref_123",
               subject_ref: "actor_123",
               org_id: "org_123",
               state: :active,
               assurance_level: :mfa,
               authn_methods: [:password, :totp],
               authenticated_at: "2026-06-01T00:00:00Z",
               last_seen_at: "2026-06-01T00:05:00Z",
               idle_expires_at: "2026-06-01T00:30:00Z",
               absolute_expires_at: "2026-06-02T00:00:00Z",
               renew_after: "2026-06-01T00:20:00Z",
               remembered: false,
               cached: false,
               session_version: 7,
               revoked_at: nil,
               as_of: "2026-06-01T00:05:00Z"
             })

    assert lane.state == :active
    assert lane.assurance_level == :mfa
    assert Contracts.lane_auth_age_seconds(lane, nil) == 300
    assert Contracts.assurance_level_meets?(:mfa, :password)
    refute Contracts.assurance_level_meets?(:password, :mfa)
  end

  test "evidence lanes cannot smuggle session authority fields" do
    authority_keys = [
      :state,
      :assurance_level,
      :mfa_level,
      :authn_methods,
      :authenticated_at,
      :last_seen_at,
      :idle_expires_at,
      :absolute_expires_at,
      :renew_after,
      :session_version,
      :revoked_at,
      :session_authority,
      :access_granted
    ]

    assert {:error, errors} =
             authority_keys
             |> Map.new(&{&1, "client supplied"})
             |> Contracts.validate_evidence_lane()

    for key <- authority_keys do
      assert {:evidence, {key, :forbidden}} in errors
    end
  end

  test "canonical auth denial taxonomy remains under the public step-up shell reason" do
    assert DenialCodes.codes() == [
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

    assert Enum.all?(DenialCodes.codes(), &String.starts_with?(&1, "auth.step_up."))
  end

  test "shell-safe auth denial details are allowlisted" do
    sanitized =
      DenialCodes.sanitize_details(%{
        required_assurance_level: :phishing_resistant,
        current_assurance_level: :password,
        required_mfa_level: :phishing_resistant,
        current_mfa_level: :password,
        max_auth_age_seconds: 300,
        auth_age_seconds: 900,
        auth_posture: :strict_recent,
        authority_state: :active,
        expected_session_version: 7,
        current_session_version: 6,
        evaluated_at: "2026-06-01T00:15:00Z",
        challenge_ref: "challenge:phase54.safe",
        step_up_token_ref: "stepup.phase54.safe",
        session_id: "secret_session",
        subject_id: "actor_123",
        org_id: "org_123",
        oauth_access_token: "token",
        provider_payload: "raw provider data",
        passkey_credential_id: "credential",
        pii_email: "person@example.com"
      })

    assert Map.keys(sanitized) |> Enum.sort() == DenialCodes.allowed_detail_keys() |> Enum.sort()
    refute Map.has_key?(sanitized, "session_id")
    refute Map.has_key?(sanitized, "subject_id")
    refute Map.has_key?(sanitized, "provider_payload")
    refute Map.has_key?(sanitized, "passkey_credential_id")
  end

  test "evaluator keeps auth failures under stable step-up reason with canonical subcodes" do
    route = %RouteEntry{
      id: "secure",
      path: "/secure",
      runtime: :live_view,
      offline: :unavailable,
      entry: :internal_only,
      auth_min_level: :mfa,
      requires_recent_auth: 300,
      auth_posture: :strict_recent
    }

    assert {:deny, denial} = Evaluator.evaluate_route_auth(route, nil, [])

    assert denial.reason == :step_up_required
    assert denial.code == "auth.step_up.missing_context"
    assert Map.keys(denial.details) == ["evaluated_at"]
  end

  test "phase 54 proof does not claim later auth machinery" do
    source = File.read!(__ENV__.file)

    refute String.contains?(source, "handoff" <> " ticket")
    refute String.contains?(source, "session" <> " renewal")
    refute String.contains?(source, "OAuth" <> " callback")
    refute String.contains?(source, "passkey" <> " assertion")
    refute String.contains?(source, "refresh-token" <> " rotation")
  end
end
