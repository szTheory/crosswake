defmodule Crosswake.Proof.Phase56StepUpCeremonyTest do
  use ExUnit.Case, async: true

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
end
