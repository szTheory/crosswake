defmodule Crosswake.Proof.Phase56StepUpCeremonyTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.StepUp
  alias Crosswake.Companions.Sigra.StepUpCeremony
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

  test "shared ceremony core allows sufficient auth challenges step-up denials and preserves host denials" do
    route =
      struct!(Crosswake.Manifest.Types.RouteEntry,
        id: "saas-profile-settings",
        path: "/saas/settings/profile",
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard,
        auth_min_level: :mfa,
        requires_recent_auth: 900,
        auth_posture: :strict_recent
      )

    lane = session_authority_lane(:password, 43)
    auth_context = auth_context(lane)

    assert {:allow, %{ok: true}} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result: {:allow, %{facts: %{ok: true}}}
             )

    assert {:challenge, %StepUp.StepUpIntentRecord{}, %StepUp.StepUpChallenge{} = challenge} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result:
                 {:deny,
                  Denial.new(
                    reason: :step_up_required,
                    code: "auth.step_up.insufficient_assurance",
                    message: "Additional authentication is required."
                  )},
               issue_intent: fn _attrs ->
                 {:ok, %{intent: step_up_intent_record(), challenge: step_up_challenge()}}
               end
             )

    assert challenge.return_route_id == "saas-profile-settings"
    assert challenge.required_assurance_level == :mfa

    host_denial =
      Denial.new(
        reason: :step_up_required,
        code: "auth.step_up_intent.route_mismatch",
        message: "Additional authentication is required."
      )

    assert {:deny, ^host_denial} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result:
                 {:deny,
                  Denial.new(
                    reason: :step_up_required,
                    code: "auth.step_up.stale_auth",
                    message: "Additional authentication is required."
                  )},
               issue_intent: fn _attrs -> {:error, host_denial} end
             )

    non_challengeable =
      Denial.new(
        reason: :step_up_required,
        code: "auth.step_up.revoked",
        message: "Additional authentication is required."
      )

    assert {:deny, ^non_challengeable} =
             StepUpCeremony.evaluate_or_issue(route, auth_context,
               evaluator_result: {:deny, non_challengeable},
               issue_intent: fn _attrs -> flunk("non-challengeable denial must not issue") end
             )
  end

  test "ceremony core and evaluator preserve pure transport and persistence boundaries" do
    ceremony_source = File.read!("lib/crosswake/companions/sigra/step_up_ceremony.ex")
    evaluator_source = File.read!("lib/crosswake/companions/sigra/evaluator.ex")

    for forbidden <- [
          "Ecto",
          "Phoenix.Controller",
          "Plug.Conn",
          "Phoenix.LiveView",
          "Phoenix.Token",
          "CrosswakeExample"
        ] do
      refute String.contains?(ceremony_source, forbidden)
    end

    refute evaluator_source =~ "StepUp.issue"
    refute evaluator_source =~ "redirect("
    refute evaluator_source =~ "halt("
    refute evaluator_source =~ "configure_session"
    refute String.contains?(String.downcase(evaluator_source), "csrf")
  end

  test "plug and liveview adapters call shared ceremony and avoid duplicated auth checks" do
    plug_source =
      File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_plug.ex")

    on_mount_source =
      File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_on_mount.ex")

    for source <- [plug_source, on_mount_source] do
      assert source =~ "StepUpCeremony.evaluate_or_issue"

      for forbidden <- [
            "idle_expires_at",
            "absolute_expires_at",
            "assurance_level_meets?",
            "Contracts.auth_age_seconds",
            "remembered",
            "cached"
          ] do
        refute String.contains?(source, forbidden)
      end
    end

    assert plug_source =~ "halt()"
    assert on_mount_source =~ "{:halt, redirected}"
  end

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

  defp auth_context(lane) do
    struct!(Crosswake.Companions.Sigra.Contracts.AuthContext,
      actor_id: lane.subject_ref,
      org_id: lane.org_id,
      mfa_level: lane.assurance_level,
      auth_age: 0,
      session_authority_lane: lane,
      as_of: lane.as_of
    )
  end

  defp step_up_intent_record do
    {:ok, record} =
      StepUp.new_step_up_intent_record(%{
        intent_ref: "sup_record_123",
        locator_digest: "sha256.locator",
        state: :issued,
        subject_ref: "sub_backend_123",
        org_id: "org_backend_123",
        source_session_ref: "sess_source_123",
        expected_session_version: 42,
        source_route_id: "saas-dashboard",
        return_route_id: "saas-profile-settings",
        required_assurance_level: :mfa,
        required_auth_posture: :strict_recent,
        max_auth_age_seconds: 300,
        challenge_kind: :host_confirm_password,
        issued_at: "2026-06-02T12:00:00Z",
        expires_at: "2026-06-02T12:05:00Z",
        audit_correlation_ref: "support:sup.safe",
        projected_session_authority_lane: session_authority_lane(:mfa, 43)
      })

    record
  end

  defp step_up_challenge do
    {:ok, challenge} =
      StepUp.new_step_up_challenge(%{
        challenge_ref: "support:sup.safe",
        intent_ref: "support:sup.safe",
        challenge_kind: :host_confirm_password,
        challenge_route_id: "sigra-step-up",
        return_route_id: "saas-profile-settings",
        required_assurance_level: :mfa,
        max_auth_age_seconds: 300,
        issued_at: "2026-06-02T12:00:00Z",
        expires_at: "2026-06-02T12:05:00Z",
        support_ref: "support:sup.safe"
      })

    challenge
  end

  defp session_authority_lane(assurance, version) do
    {:ok, lane} =
      Crosswake.Companions.Sigra.Contracts.new_session_authority_lane(%{
        session_ref: "sess_projected_123",
        subject_ref: "sub_backend_123",
        org_id: "org_backend_123",
        state: :active,
        assurance_level: assurance,
        authn_methods: [:password, :totp],
        authenticated_at: "2026-06-02T12:00:00Z",
        last_seen_at: "2026-06-02T12:01:00Z",
        idle_expires_at: "2026-06-02T12:31:00Z",
        absolute_expires_at: "2026-06-03T12:00:00Z",
        session_version: version,
        as_of: "2026-06-02T12:01:00Z"
      })

    lane
  end
end
