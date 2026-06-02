defmodule Crosswake.Proof.Phase55SessionHandoffTicketsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff
  alias Crosswake.Shell.Denial

  @handoff_codes [
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

  test "phase 55 locks the exact auth handoff denial vocabulary" do
    assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.handoff.")) ==
             @handoff_codes

    assert Enum.all?(@handoff_codes, &DenialCodes.valid_code?/1)
  end

  test "handoff denials keep the existing public step-up shell reason" do
    for code <- @handoff_codes do
      denial =
        Denial.new(
          reason: :step_up_required,
          code: code,
          message: "Additional authentication is required.",
          details: DenialCodes.sanitize_details(%{handoff_ref: "support:hnd.safe"})
        )

      assert denial.reason == :step_up_required
      assert denial.code == code
      refute :handoff_denied in Denial.reasons()
    end
  end

  test "safe handoff detail allowlist excludes raw ticket session identity and credential material" do
    allowed = DenialCodes.allowed_detail_keys()

    for key <- [
          "handoff_ref",
          "handoff_state",
          "handoff_kind",
          "handoff_version",
          "handoff_transport",
          "binding_kind",
          "intent_kind",
          "route_binding",
          "ticket_expires_at",
          "ticket_age_seconds",
          "evaluated_at"
        ] do
      assert key in allowed
    end

    for key <- [
          "ticket_ref",
          "ticket_digest",
          "session_ref",
          "subject_ref",
          "org_id",
          "device_ref",
          "provider_payload",
          "credential_id",
          "ip",
          "user_agent",
          "nonce",
          "csrf_token",
          "pkce_verifier"
        ] do
      refute key in allowed
    end
  end

  test "handoff envelope cannot become self-contained authority" do
    assert {:error, errors} =
             Handoff.new_handoff_envelope(%{
               typ: "crosswake.sigra.handoff.v1",
               ticket_ref: "hnd_locator",
               version: "1",
               issuer: "crosswake_example",
               audience: "crosswake.sigra.handoff",
               issued_at: "2026-06-02T12:00:00Z",
               expires_at: "2026-06-02T12:03:00Z",
               intent_kind: :session_handoff,
               route_id: "saas-profile-settings",
               binding_kind: :session_route_intent,
               session_ref: "sess_secret",
               subject_ref: "sub_secret",
               org_id: "org_secret",
               assurance_level: :mfa,
               authn_methods: [:password, :totp],
               session_version: 43
             })

    assert {:handoff_envelope, {:session_ref, :forbidden}} in errors
    assert {:handoff_envelope, {:subject_ref, :forbidden}} in errors
    assert {:handoff_envelope, {:org_id, :forbidden}} in errors
    assert {:handoff_envelope, {:assurance_level, :forbidden}} in errors
    assert {:handoff_envelope, {:authn_methods, :forbidden}} in errors
    assert {:handoff_envelope, {:session_version, :forbidden}} in errors
  end

  test "redemption success requires SessionAuthorityLane projection and renewal instructions" do
    assert {:ok, lane} =
             Contracts.new_session_authority_lane(%{
               session_ref: "sess_projected",
               subject_ref: "sub_backend",
               org_id: "org_backend",
               state: :active,
               assurance_level: :mfa,
               authn_methods: [:password, :totp],
               authenticated_at: "2026-06-02T12:00:00Z",
               last_seen_at: "2026-06-02T12:01:00Z",
               idle_expires_at: "2026-06-02T12:31:00Z",
               absolute_expires_at: "2026-06-03T12:00:00Z",
               session_version: 43,
               as_of: "2026-06-02T12:01:00Z"
             })

    assert {:ok, renewal} =
             Handoff.new_session_renewal_instructions(%{
               renew_session?: true,
               put_session: %{"crosswake_session_ref" => "sess_projected"},
               delete_session: [],
               projected_session_ref: "sess_projected",
               projected_session_version: 43
             })

    assert {:ok, redemption} =
             Handoff.new_handoff_redemption(%{
               handoff_ref: "support:hnd.safe",
               consumed_at: "2026-06-02T12:01:00Z",
               session_authority_lane: lane,
               session_renewal_instructions: renewal,
               route_target: %{route_id: "saas-profile-settings"}
             })

    assert redemption.session_authority_lane == lane
    assert redemption.session_renewal_instructions.renew_session? == true

    assert {:error, errors} =
             Handoff.new_handoff_redemption(%{
               handoff_ref: "support:hnd.safe",
               consumed_at: "2026-06-02T12:01:00Z",
               session_authority_lane: %{state: :active},
               session_renewal_instructions: renewal,
               route_target: %{route_id: "saas-profile-settings"}
             })

    assert {:session_authority_lane, :invalid_contract} in errors
  end

  test "phase 55-01 proof does not claim host persistence ceremony or provider return flows" do
    source = File.read!(__ENV__.file)

    refute String.contains?(source, "Ecto" <> ".Multi")
    refute String.contains?(source, "configure_" <> "session")
    refute String.contains?(source, "LiveView " <> "on_mount")
    refute String.contains?(source, "OAuth " <> "callback")
    refute String.contains?(source, "passkey " <> "assertion")
    refute String.contains?(source, "refresh-token " <> "rotation")
  end
end
