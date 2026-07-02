defmodule Crosswake.Proof.Phase57AuthReturnBoundariesTest do
  # async: false because setup calls Application.put_env for SupportMatrix non-vacuity.
  # D-137-03: Moved from core test suite (sigra modules not available post-extraction).
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Sigra.AuthReturn
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff
  alias Crosswake.Manifest
  alias Crosswake.Policy.Route
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  @auth_return_codes [
    "auth.return.oauth.missing_return",
    "auth.return.oauth.invalid_return",
    "auth.return.oauth.expired_return",
    "auth.return.oauth.replayed_return",
    "auth.return.oauth.state_mismatch",
    "auth.return.oauth.nonce_mismatch",
    "auth.return.oauth.pkce_missing",
    "auth.return.oauth.redirect_mismatch",
    "auth.return.passkey.missing_return",
    "auth.return.passkey.invalid_return",
    "auth.return.passkey.expired_return",
    "auth.return.passkey.replayed_return",
    "auth.return.passkey.challenge_mismatch",
    "auth.return.passkey.origin_mismatch",
    "auth.return.passkey.rp_id_mismatch",
    "auth.return.passkey.user_verification_missing",
    "auth.return.native_auth.missing_return",
    "auth.return.native_auth.invalid_return",
    "auth.return.native_auth.expired_return",
    "auth.return.native_auth.replayed_return",
    "auth.return.native_auth.link_unverified",
    "auth.return.native_auth.callback_mismatch",
    "auth.return.native_auth.projection_failed"
  ]

  # D-137-03: Register sigra so SupportMatrix.auth_contract_truth/0 returns a
  # populated row (denial_codes, shipped_contracts) rather than sentinel [] values.
  setup do
    prior = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, prior)
    end)

    :ok
  end

  test "phase 57 locks canonical auth-return denial vocabulary under step_up_required" do
    assert Enum.filter(DenialCodes.codes(), &String.starts_with?(&1, "auth.return.")) ==
             @auth_return_codes

    for code <- @auth_return_codes do
      assert DenialCodes.valid_code?(code)

      denial =
        Denial.new(
          reason: :step_up_required,
          code: code,
          message: "Additional authentication is required.",
          details:
            DenialCodes.sanitize_details(%{
              auth_return_ref: "support:ret.safe",
              auth_return_kind: :oauth,
              auth_return_transport: :verified_https_link,
              link_verification: :verified
            })
        )

      assert denial.reason == :step_up_required
      assert denial.code == code
      refute :auth_return_denied in Denial.reasons()
    end
  end

  test "safe auth-return detail allowlist excludes tokens credentials nonces and provider payloads" do
    allowed = DenialCodes.allowed_detail_keys()

    for key <- [
          "auth_return_ref",
          "auth_return_kind",
          "auth_return_transport",
          "auth_return_state",
          "return_route_id",
          "link_verification",
          "validation_posture",
          "return_expires_at",
          "return_age_seconds"
        ] do
      assert key in allowed
    end

    for key <- [
          "authorization_code",
          "access_token",
          "refresh_token",
          "id_token",
          "credential_id",
          "passkey_credential_id",
          "client_data_json",
          "authenticator_data",
          "nonce",
          "pkce_verifier",
          "provider_payload",
          "session_ref",
          "actor_id",
          "org_id",
          "ip",
          "user_agent"
        ] do
      refute key in allowed
    end
  end

  test "route policy exposes one route-local auth_return seam and rejects weaker sensitive custom schemes" do
    assert {:ok, route} =
             Route.new(
               id: "oauth-return",
               runtime: :live_view,
               auth_return: [
                 kind: :oauth,
                 transport: :verified_https_link,
                 return_route_id: "billing-settings",
                 validates: [
                   :state,
                   :nonce,
                   :pkce,
                   :redirect_uri,
                   :link_verification,
                   :expiry,
                   :replay
                 ]
               ]
             )

    assert route.auth_return.kind == :oauth
    assert route.security == :sensitive
    assert route.auth_posture == :strict_recent

    assert {:error, error} =
             Route.new(
               id: "oauth-return",
               runtime: :live_view,
               security: :sensitive,
               auth_return: [
                 kind: :oauth,
                 transport: :custom_scheme,
                 return_route_id: "billing-settings",
                 validates: [:state, :pkce, :redirect_uri, :expiry, :replay]
               ]
             )

    assert Exception.message(error) =~ "custom_scheme is advisory only"

    assert {:error, error} =
             Route.new(
               id: "oauth-return",
               runtime: :live_view,
               auth_return: [
                 kind: :oauth,
                 transport: :verified_https_link,
                 return_route_id: "billing-settings",
                 validates: [:state, :pkce]
               ]
             )

    assert Exception.message(error) =~ "requires validations"
  end

  test "auth_return serializes into manifest route entries" do
    route =
      Route.new!(
        id: "passkey-return",
        runtime: :live_view,
        auth_return: [
          kind: :passkey,
          transport: :verified_https_link,
          return_route_id: "account-security",
          validates: [
            :challenge,
            :origin,
            :rp_id,
            :user_verification,
            :link_verification,
            :expiry,
            :replay
          ]
        ]
      )

    manifest =
      Manifest.Builder.build(
        [route],
        [%{id: "passkey-return", path: "/auth/passkey/return"}],
        origin: "https://app.example",
        generated_at: "2026-06-02T12:00:00Z"
      )

    entry = manifest.routes["passkey-return"]
    assert entry.auth_return.kind == :passkey
    assert entry.auth_return.transport == :verified_https_link
    assert entry.auth_return.return_route_id == "account-security"
  end

  test "auth-return envelopes are evidence only and reject authority smuggling" do
    assert {:ok, envelope} = AuthReturn.new_envelope(oauth_envelope_attrs())
    assert %AuthReturn.OAuthEvidence{} = envelope.evidence
    assert envelope.kind == :oauth

    assert {:error, errors} =
             AuthReturn.new_envelope(
               oauth_envelope_attrs(%{
                 access_token: "tok_secret",
                 passkey_credential_id: "cred_secret",
                 nonce: "raw_nonce",
                 pkce_verifier: "raw_verifier",
                 session_authority_lane: %{state: :active},
                 return_to: "/admin"
               })
             )

    assert {:auth_return_envelope, {:access_token, :forbidden}} in errors
    assert {:auth_return_envelope, {:passkey_credential_id, :forbidden}} in errors
    assert {:auth_return_envelope, {:nonce, :forbidden}} in errors
    assert {:auth_return_envelope, {:pkce_verifier, :forbidden}} in errors
    assert {:auth_return_envelope, {:session_authority_lane, :forbidden}} in errors
    assert {:auth_return_envelope, {:return_to, :forbidden}} in errors
  end

  test "backend promotion requires host-owned attempt record SessionAuthorityLane and renewal instructions" do
    assert {:ok, record} =
             AuthReturn.new_attempt_record(%{
               attempt_ref: "ret_123",
               attempt_digest: "sha256:ret",
               kind: :oauth,
               state: :issued,
               subject_ref: "sub_backend",
               org_id: "org_backend",
               source_session_ref: "sess_old",
               expected_session_version: 42,
               route_id: "oauth-return",
               return_route_id: "billing-settings",
               transport: :verified_https_link,
               link_verification: :verified,
               state_digest: "sha256:state",
               nonce_digest: "sha256:nonce",
               pkce_challenge_digest: "sha256:pkce",
               pkce_method: :S256,
               issued_at: "2026-06-02T12:00:00Z",
               expires_at: "2026-06-02T12:05:00Z",
               audit_correlation_ref: "support:ret.safe",
               projected_session_authority_lane: session_authority_lane()
             })

    assert %Contracts.SessionAuthorityLane{} = record.projected_session_authority_lane

    assert {:ok, completion} =
             AuthReturn.new_completion(%{
               auth_return_ref: "support:ret.safe",
               consumed_at: "2026-06-02T12:01:00Z",
               session_authority_lane: session_authority_lane(),
               session_renewal_instructions: renewal_instructions(),
               route_target: %{route_id: "billing-settings"}
             })

    assert completion.session_authority_lane.state == :active

    assert {:error, errors} =
             AuthReturn.new_completion(%{
               auth_return_ref: "support:ret.safe",
               consumed_at: "2026-06-02T12:01:00Z",
               session_authority_lane: %{state: :active},
               session_renewal_instructions: renewal_instructions(),
               route_target: %{route_id: "billing-settings"}
             })

    assert {:session_authority_lane, :invalid_contract} in errors
  end

  test "support truth promotes auth-return boundaries without provider or device overclaims" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert :auth_return_boundary in row.shipped_contracts
    assert :auth_return_attempt in row.shipped_contracts
    assert row.auth_return.status == :shipped
    assert row.auth_return.authority_source == :server_record
    assert row.auth_return.envelope_authority == false
    assert row.auth_return.route_policy_seam == :auth_return
    assert row.auth_return.sensitive_transport == :verified_https_link_required
    assert row.auth_return.custom_scheme_posture == :advisory_only
    assert :oauth not in row.deferred
    assert :passkey not in row.deferred
    assert :auth_return_boundaries not in row.deferred
    assert :provider_device_proof in row.deferred
    assert :native_auth_ui in row.deferred
    assert "auth.return.oauth.invalid_return" in row.denial_codes
    assert "auth_return_ref" in row.safe_detail_keys
  end

  test "example host exposes Ecto-owned auth-return replay and audit records" do
    attempt_source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_attempt.ex"
      )

    audit_source =
      File.read!(
        "../../examples/phoenix_host/lib/crosswake_example/saas_portal/auth_return_audit_event.ex"
      )

    assert attempt_source =~ ~s(schema "sigra_auth_return_attempts")
    assert audit_source =~ ~s(schema "sigra_auth_return_audit_events")
    assert attempt_source =~ "attempt_digest"
    assert attempt_source =~ "projected_session_authority"
    assert attempt_source =~ "link_verification"
    assert audit_source =~ "denial_code"
    assert audit_source =~ "binding_result"

    assert File.exists?(
             "../../examples/phoenix_host/priv/repo/migrations/20260602080000_create_sigra_auth_return_attempts.exs"
           )

    assert File.exists?(
             "../../examples/phoenix_host/priv/repo/migrations/20260602080100_create_sigra_auth_return_audit_events.exs"
           )
  end

  defp oauth_envelope_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        typ: "crosswake.sigra.auth_return.v1",
        return_ref: "ret_123",
        version: "1",
        issuer: "crosswake_example",
        audience: "crosswake.sigra.auth_return",
        kind: :oauth,
        route_id: "oauth-return",
        return_route_id: "billing-settings",
        transport: :verified_https_link,
        expected_callback: "https://app.example/auth/oauth/return",
        received_callback: "https://app.example/auth/oauth/return",
        issued_at: "2026-06-02T12:00:00Z",
        expires_at: "2026-06-02T12:05:00Z",
        replay_posture: :server_record_required,
        link_verification: :verified,
        validation_posture: %{
          state: :matched,
          nonce: :matched,
          pkce: :present,
          redirect: :matched,
          expiry: :fresh,
          replay: :not_seen
        },
        evidence: %{
          provider_kind: :oidc,
          issuer: "https://issuer.example",
          state: :matched,
          nonce: :matched,
          pkce: :present,
          redirect: :matched,
          replay: :not_seen,
          authorization_code_ref: "code_digest:abc",
          id_token_ref: "id_token_digest:def"
        }
      },
      overrides
    )
  end

  defp session_authority_lane do
    {:ok, lane} =
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

    lane
  end

  defp renewal_instructions do
    {:ok, renewal} =
      Handoff.new_session_renewal_instructions(%{
        renew_session?: true,
        put_session: %{"crosswake_session_ref" => "sess_projected"},
        delete_session: ["crosswake_auth_return_ref"],
        projected_session_ref: "sess_projected",
        projected_session_version: 43
      })

    renewal
  end
end
