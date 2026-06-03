defmodule Crosswake.Proof.Phase55SessionHandoffTicketsTest do
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
    source = File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex")

    ticket_source =
      File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex")

    audit_source =
      File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex")

    assert ticket_source =~ ~s(schema "sigra_handoff_tickets")
    assert audit_source =~ ~s(schema "sigra_handoff_audit_events")
    assert source =~ "Phoenix.Token.sign"
    assert source =~ "Phoenix.Token.verify"
    assert source =~ "Manifest.compile(Router)"
    assert source =~ "ticket_digest"
    assert source =~ "audit_correlation_ref"
    assert source =~ "return_to"

    assert File.exists?(
             "examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs"
           )

    assert File.exists?(
             "examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs"
           )
  end

  @tag :requires_example_host
  test "example host proves issue redeem replay expiry revocation mismatch and audit flow" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_handoff_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias Crosswake.Compatibility.RouteGate
    alias Crosswake.Compatibility.Target
    alias Crosswake.Companions.Sigra.Contracts
    alias Crosswake.Manifest
    alias CrosswakeExample.Repo
    alias CrosswakeExample.Router
    alias CrosswakeExample.SaaSPortal.Auth
    alias CrosswakeExample.SaaSPortal.Handoff
    alias CrosswakeExample.SaaSPortal.HandoffAuditEvent
    alias CrosswakeExample.SaaSPortal.HandoffTicket

    base = %{
      subject_ref: "sub_backend",
      org_id: "org_backend",
      source_session_ref: "sess_old",
      expected_session_version: 42,
      target_route_id: "saas-profile-settings",
      request_ref: "req-proof"
    }

    assert {:error, route_denial} = Handoff.issue(Map.put(base, :return_to, "https://evil.example/steal"))
    assert route_denial.code == "auth.handoff.route_mismatch"

    assert {:ok, issued} = Handoff.issue(base)
    assert issued.ticket.state == "issued"
    assert Repo.aggregate(HandoffTicket, :count) == 1
    assert Repo.aggregate(HandoffAuditEvent, :count) == 1

    {:ok, payload} =
      Phoenix.Token.verify(
        Handoff.signing_secret(),
        Handoff.signing_salt(),
        issued.signed_envelope,
        max_age: Handoff.ttl_seconds()
      )

    assert payload["ticket_ref"] == issued.ticket.ticket_ref
    assert payload["route_id"] == "saas-profile-settings"
    refute Map.has_key?(payload, "subject_ref")
    refute Map.has_key?(payload, "org_id")
    refute Map.has_key?(payload, "source_session_ref")
    refute Map.has_key?(payload, "session_version")

    redeem_attrs = %{
      expected_route_id: "saas-profile-settings",
      expected_intent_kind: "session_handoff",
      source_session_ref: "sess_old",
      expected_session_version: 42,
      request_ref: "req-redeem"
    }

    assert {:ok, redemption} = Handoff.redeem(issued.signed_envelope, redeem_attrs)
    assert redemption.session_authority_lane.session_ref == issued.ticket.projected_session_ref
    assert redemption.session_authority_lane.assurance_level == :mfa
    assert redemption.session_renewal_instructions.renew_session? == true
    assert Repo.get!(HandoffTicket, issued.ticket.id).state == "redeemed"

    {:ok, %{manifest: manifest}} = Manifest.compile(Router)
    target = %Target{
      origin: manifest.host.origin,
      manifest_schema_version: manifest.compatibility.manifest_schema_version,
      bridge_protocol_version: manifest.compatibility.bridge_protocol_version,
      native_runtime_version: manifest.compatibility.native_runtime_version
    }

    auth_context =
      struct!(Contracts.AuthContext,
        actor_id: redemption.session_authority_lane.subject_ref,
        org_id: redemption.session_authority_lane.org_id,
        mfa_level: redemption.session_authority_lane.assurance_level,
        auth_age: Contracts.auth_age_seconds(%Contracts.AuthContext{
          actor_id: redemption.session_authority_lane.subject_ref,
          org_id: redemption.session_authority_lane.org_id,
          mfa_level: redemption.session_authority_lane.assurance_level,
          auth_age: 0,
          session_authority_lane: redemption.session_authority_lane,
          as_of: redemption.session_authority_lane.as_of
        }),
        session_authority_lane: redemption.session_authority_lane,
        as_of: redemption.session_authority_lane.as_of
      )

    assert %{status: :allow} =
             RouteGate.evaluate(manifest, "saas-profile-settings", target,
               auth_context: auth_context,
               expected_session_version: redemption.session_authority_lane.session_version
             )

    conn =
      Plug.Test.conn(:get, "/")
      |> Plug.Test.init_test_session(%{"before" => "kept"})
      |> Auth.apply_handoff_renewal(redemption)

    assert Plug.Conn.get_session(conn, "crosswake_session_ref") ==
             redemption.session_authority_lane.session_ref

    assert {:error, replay_denial} = Handoff.redeem(issued.signed_envelope, redeem_attrs)
    assert replay_denial.code == "auth.handoff.replayed_ticket"

    old = DateTime.add(DateTime.utc_now(), -600, :second) |> DateTime.truncate(:second)
    assert {:ok, expired} = Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_expired", issued_at: old, ttl_seconds: 60}))
    assert {:error, expired_denial} = Handoff.redeem(expired.signed_envelope, redeem_attrs)
    assert expired_denial.code == "auth.handoff.expired_ticket"

    assert {:ok, revoked} = Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_revoked"}))
    assert {:ok, _ticket} = Handoff.revoke(revoked.ticket.ticket_ref, %{request_ref: "req-revoke"})
    assert {:error, revoked_denial} = Handoff.redeem(revoked.signed_envelope, redeem_attrs)
    assert revoked_denial.code == "auth.handoff.revoked_ticket"

    assert {:ok, route_mismatch} = Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_route"}))
    assert {:error, route_denial} =
             Handoff.redeem(route_mismatch.signed_envelope, %{redeem_attrs | expected_route_id: "saas-dashboard"})
    assert route_denial.code == "auth.handoff.route_mismatch"

    assert {:ok, intent_mismatch} = Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_intent"}))
    assert {:error, intent_denial} =
             Handoff.redeem(intent_mismatch.signed_envelope, %{redeem_attrs | expected_intent_kind: "other"})
    assert intent_denial.code == "auth.handoff.intent_mismatch"

    assert {:ok, binding_mismatch} = Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_binding"}))
    assert {:error, binding_denial} =
             Handoff.redeem(binding_mismatch.signed_envelope, %{redeem_attrs | expected_session_version: 41})
    assert binding_denial.code == "auth.handoff.binding_mismatch"

    assert {:ok, projection_failure} =
             Handoff.issue(Map.merge(base, %{ticket_ref: "hnd_projection", projected_authority: %{"state" => "active"}}))
    assert {:error, projection_denial} = Handoff.redeem(projection_failure.signed_envelope, redeem_attrs)
    assert projection_denial.code == "auth.handoff.projection_failed"

    audit_types = Repo.all(HandoffAuditEvent) |> Enum.map(& &1.event_type)
    assert "issue" in audit_types
    assert "redeem" in audit_types
    assert "revoke" in audit_types
    assert "deny" in audit_types
    assert Repo.aggregate(HandoffAuditEvent, :count) >= 10

    IO.puts("phase55-host-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase55-host-proof: ok"
  end

  test "phase 55 proof keeps public docs on handoff support and later-phase non-claims" do
    companions = File.read!("guides/companions.md")
    support = File.read!("guides/support_matrix.md")
    native_shell = File.read!("guides/native_shell.md")

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
