defmodule Crosswake.Proof.Phase55SessionHandoffTicketsTest do
  # async: false because setup calls Application.put_env for SupportMatrix non-vacuity.
  # D-137-03: Moved from core test suite (sigra modules not available post-extraction).
  # The @requires_example_host host-DB integration test remains in core (phase55 core file).
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

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

  # D-137-03: Register sigra so SupportMatrix.auth_contract_truth/0 returns populated
  # denial_codes and safe_detail_keys (not sentinel []).
  setup do
    prior = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, prior)
    end)

    :ok
  end

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

  test "support truth promotes shipped handoff contracts without later-phase claims" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert [
             :session_authority,
             :handoff_ticket,
             :server_record_redemption
             | _
           ] = row.shipped_contracts

    assert row.handoff.status == :shipped
    assert row.handoff.authority_source == :server_record
    assert row.handoff.envelope_authority == false
    assert row.handoff.proof_class == :merge_blocking
    assert :denial_code in row.handoff.audit_fields
    assert :binding_result in row.handoff.audit_fields
    assert row.denial_codes == DenialCodes.codes()
    assert "auth.handoff.route_mismatch" in row.denial_codes
    assert "handoff_ref" in row.safe_detail_keys
    assert "ticket_ref" not in row.safe_detail_keys
    assert row.fallback == :step_up_required
    refute :handoff in row.deferred
    refute :ceremony in row.deferred
    refute :auth_return_boundaries in row.deferred
    assert :refresh_tokens in row.deferred
    assert :provider_device_proof in row.deferred
    assert :native_auth_ui in row.deferred
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

  test "example host issues signed low-sensitivity envelopes backed by one-time records" do
    source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex"
      )

    ticket_source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex"
      )

    audit_source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex"
      )

    assert ticket_source =~ ~s(schema "sigra_handoff_tickets")
    assert audit_source =~ ~s(schema "sigra_handoff_audit_events")
    assert source =~ "Phoenix.Token.sign"
    assert source =~ "Phoenix.Token.verify"
    assert source =~ "Manifest.compile(Router)"
    assert source =~ "ticket_digest"
    assert source =~ "audit_correlation_ref"
    assert source =~ "return_to"

    assert File.exists?(
             "../../examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs"
           )

    assert File.exists?(
             "../../examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs"
           )
  end

  test "phase 55 proof keeps public docs on handoff support and later-phase non-claims" do
    companions = File.read!("../../guides/companions.md")
    support = File.read!("../../guides/support_matrix.md")
    native_shell = File.read!("../../guides/native_shell.md")

    for doc <- [companions, support, native_shell] do
      assert doc =~ "handoff"
      assert doc =~ "server-record"
      assert doc =~ "refresh-token"
      assert doc =~ "native auth UI"
    end

    assert companions =~ "Handoff envelopes, step-up locators, auth-return envelopes"
    assert companions =~ "Phase 55 handoff ticket contracts"
    assert support =~ "auth.handoff.*"
    assert native_shell =~ "the bridge is not an auth authority"
  end

  test "phase 55-03 proof does not claim ceremony diagnostics or provider return flows" do
    source = File.read!(__ENV__.file)

    refute String.contains?(source, "LiveView " <> "on_mount")
    refute String.contains?(source, "OAuth " <> "callback")
    refute String.contains?(source, "passkey " <> "assertion")
    refute String.contains?(source, "refresh-token " <> "rotation")
  end
end
