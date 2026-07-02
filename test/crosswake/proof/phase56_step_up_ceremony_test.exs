defmodule Crosswake.Proof.Phase56StepUpCeremonyTest do
  # D-137-03: All non-host tests moved to packages/crosswake_sigra/test/crosswake/proof/
  # Only the @requires_example_host integration test remains in core because it runs
  # `mix run` in the examples/phoenix_host directory and needs example-host DB context.
  use ExUnit.Case, async: true

  @tag :requires_example_host
  test "example host proves issue challenge consume replay expiry cancel revoke binding and renewal" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")

    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_step_up_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias Crosswake.Companions.Sigra.Contracts
    alias Crosswake.Manifest
    alias CrosswakeExample.Repo
    alias CrosswakeExample.Router
    alias CrosswakeExample.SaaSPortal.Auth
    alias CrosswakeExample.SaaSPortal.StepUp
    alias CrosswakeExample.SaaSPortal.StepUpAuditEvent
    alias CrosswakeExample.SaaSPortal.StepUpIntent
    alias CrosswakeExample.SaaSPortal.StepUpOnMount
    alias CrosswakeExample.SaaSPortal.StepUpPlug

    base = %{
      subject_ref: "sub_backend",
      org_id: "org_backend",
      source_session_ref: "sess_old",
      expected_session_version: 42,
      source_route_id: "saas-dashboard",
      return_route_id: "saas-profile-settings",
      request_ref: "req-issue"
    }

    assert {:error, raw_return_denial} = StepUp.issue(Map.put(base, :return_to, "https://evil.example/steal"))
    assert raw_return_denial.code == "auth.step_up_intent.invalid_intent"

    assert {:error, route_denial} = StepUp.issue(%{base | return_route_id: "unknown-route"})
    assert route_denial.code == "auth.step_up_intent.route_mismatch"

    {:ok, %{manifest: manifest}} = Manifest.compile(Router)
    route = manifest.routes["saas-profile-settings"]

    weak_lane =
      struct!(Contracts.SessionAuthorityLane,
        session_ref: "sess_old",
        subject_ref: "sub_backend",
        org_id: "org_backend",
        state: :active,
        assurance_level: :password,
        authn_methods: [:password],
        authenticated_at: "2026-06-02T11:00:00Z",
        last_seen_at: "2026-06-02T12:00:00Z",
        idle_expires_at: "2026-06-02T12:30:00Z",
        absolute_expires_at: "2026-06-03T12:00:00Z",
        session_version: 42,
        as_of: "2026-06-02T12:00:00Z"
      )

    weak_context =
      struct!(Contracts.AuthContext,
        actor_id: "sub_backend",
        org_id: "org_backend",
        mfa_level: :password,
        auth_age: 3600,
        session_authority_lane: weak_lane,
        as_of: weak_lane.as_of
      )

    assert {:challenge, _plug_intent, plug_challenge} =
             StepUpPlug.decision(route, weak_context, expected_session_version: 42)

    assert {:challenge, _mount_intent, mount_challenge} =
             StepUpOnMount.decision(route, weak_context, expected_session_version: 42)

    assert plug_challenge.challenge_kind == mount_challenge.challenge_kind
    assert plug_challenge.return_route_id == mount_challenge.return_route_id
    assert plug_challenge.required_assurance_level == mount_challenge.required_assurance_level
    assert plug_challenge.max_auth_age_seconds == mount_challenge.max_auth_age_seconds
    assert plug_challenge.return_route_id == "saas-profile-settings"
    refute plug_challenge.support_ref =~ "return_to"

    intent_count_before_direct_issue = Repo.aggregate(StepUpIntent, :count)

    assert {:ok, issued} = StepUp.issue(base)
    assert issued.intent.state == "issued"
    assert Repo.aggregate(StepUpIntent, :count) == intent_count_before_direct_issue + 1
    assert Repo.aggregate(StepUpAuditEvent, :count) >= 1

    {:ok, payload} =
      Phoenix.Token.verify(
        StepUp.signing_secret(),
        StepUp.signing_salt(),
        issued.signed_locator,
        max_age: StepUp.ttl_seconds()
      )

    assert payload["intent_ref"] == issued.intent.intent_ref
    assert payload["source_route_id"] == "saas-dashboard"
    assert payload["return_route_id"] == "saas-profile-settings"
    refute Map.has_key?(payload, "subject_ref")
    refute Map.has_key?(payload, "org_id")
    refute Map.has_key?(payload, "source_session_ref")
    refute Map.has_key?(payload, "projected_authority")
    refute Map.has_key?(payload, "csrf_token")
    refute Map.has_key?(payload, "nonce")
    refute Map.has_key?(payload, "provider_payload")
    refute Map.has_key?(payload, "passkey_credential_id")
    refute Map.has_key?(payload, "oauth_access_token")

    assert {:ok, challenge} = StepUp.challenge(issued.signed_locator, %{request_ref: "req-challenge"})
    assert challenge.return_route_id == "saas-profile-settings"
    assert Repo.get!(StepUpIntent, issued.intent.id).state == "challenged"

    consume_attrs = %{
      expected_return_route_id: "saas-profile-settings",
      expected_challenge_kind: "host_confirm_password",
      source_session_ref: "sess_old",
      expected_session_version: 42,
      request_ref: "req-consume"
    }

    assert {:ok, completion} = StepUp.consume(issued.signed_locator, consume_attrs)
    assert %Contracts.SessionAuthorityLane{state: :active} = completion.session_authority_lane
    assert completion.session_renewal_instructions.renew_session? == true
    assert completion.session_renewal_instructions.rotate_csrf? == true
    assert completion.session_renewal_instructions.live_socket_invalidation == %{reason: :step_up_completed}
    assert Repo.get!(StepUpIntent, issued.intent.id).state == "consumed"
    assert Repo.get!(StepUpIntent, issued.intent.id).consumed_at

    conn =
      Plug.Test.conn(:get, "/")
      |> Plug.Test.init_test_session(%{
        "before" => "kept",
        "crosswake_step_up_intent_ref" => "transient",
        "crosswake_step_up_challenge" => "transient"
      })
      |> Auth.apply_step_up_completion(completion)

    assert Plug.Conn.get_session(conn, "crosswake_session_ref") ==
             completion.session_authority_lane.session_ref

    assert Plug.Conn.get_session(conn, "crosswake_session_version") ==
             completion.session_authority_lane.session_version

    refute Plug.Conn.get_session(conn, "crosswake_step_up_intent_ref")
    refute Plug.Conn.get_session(conn, "crosswake_step_up_challenge")

    assert {:error, replay_denial} = StepUp.consume(issued.signed_locator, consume_attrs)
    assert replay_denial.code == "auth.step_up_intent.consumed_intent"

    old = DateTime.add(DateTime.utc_now(), -600, :second) |> DateTime.truncate(:second)
    assert {:ok, expired} =
             StepUp.issue(Map.merge(base, %{intent_ref: "sup_expired", issued_at: old, ttl_seconds: 60}))

    assert {:error, expired_denial} = StepUp.consume(expired.signed_locator, consume_attrs)
    assert expired_denial.code == "auth.step_up_intent.expired_intent"

    assert {:ok, canceled} = StepUp.issue(Map.merge(base, %{intent_ref: "sup_canceled"}))
    assert {:ok, _intent} = StepUp.cancel(canceled.intent.intent_ref, %{request_ref: "req-cancel"})
    assert {:error, canceled_denial} = StepUp.consume(canceled.signed_locator, consume_attrs)
    assert canceled_denial.code == "auth.step_up_intent.canceled_intent"

    assert {:ok, revoked} = StepUp.issue(Map.merge(base, %{intent_ref: "sup_revoked"}))
    assert {:ok, _intent} = StepUp.revoke(revoked.intent.intent_ref, %{request_ref: "req-revoke"})
    assert {:error, revoked_denial} = StepUp.consume(revoked.signed_locator, consume_attrs)
    assert revoked_denial.code == "auth.step_up_intent.revoked_intent"

    assert {:ok, binding} = StepUp.issue(Map.merge(base, %{intent_ref: "sup_binding"}))
    assert {:error, binding_denial} =
             StepUp.consume(binding.signed_locator, %{consume_attrs | expected_session_version: 41})
    assert binding_denial.code == "auth.step_up_intent.binding_mismatch"

    assert {:ok, return_route} = StepUp.issue(Map.merge(base, %{intent_ref: "sup_route"}))
    assert {:error, return_denial} =
             StepUp.consume(return_route.signed_locator, %{consume_attrs | expected_return_route_id: "saas-dashboard"})
    assert return_denial.code == "auth.step_up_intent.route_mismatch"

    assert {:ok, projection_failure} =
             StepUp.issue(
               Map.merge(base, %{
                 intent_ref: "sup_projection",
                 projected_authority: %{"state" => "active"}
               })
             )

    assert {:error, projection_denial} = StepUp.consume(projection_failure.signed_locator, consume_attrs)
    assert projection_denial.code == "auth.step_up_intent.projection_failed"
    assert Repo.get!(StepUpIntent, projection_failure.intent.id).state == "issued"

    audit_types = Repo.all(StepUpAuditEvent) |> Enum.map(& &1.event_type)
    assert "issue" in audit_types
    assert "challenge" in audit_types
    assert "consume" in audit_types
    assert "cancel" in audit_types
    assert "revoke" in audit_types
    assert "deny" in audit_types
    assert Repo.aggregate(StepUpAuditEvent, :count) >= 12

    IO.puts("phase56-step-up-host-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase56-step-up-host-proof: ok"
  end
end
