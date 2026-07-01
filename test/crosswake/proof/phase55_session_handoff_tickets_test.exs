defmodule Crosswake.Proof.Phase55SessionHandoffTicketsTest do
  # D-137-03: All non-host tests moved to packages/crosswake_sigra/test/crosswake/proof/.
  # Only the @requires_example_host integration test remains in core because it runs
  # `mix run` in the examples/phoenix_host directory and needs example-host DB context.
  use ExUnit.Case, async: true

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
end
