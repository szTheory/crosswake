defmodule CrosswakeExample.Chimeway.RegistrationAuthorityMigrationUpgradeTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Exercises the Chimeway authority upgrade from the released migration boundary.

  The proof owns its SQLite database: it never resets the example-host test
  database and never prints seeded row values.
  """

  test "released host schema upgrades forward to fail-closed authority indexes" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    import Ecto.Query
    Mix.Task.run("app.config")

    db = Path.join(System.tmp_dir!(), "crosswake_registration_upgrade_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db")
    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    alias CrosswakeExample.Repo

    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(Repo, path, :up, to: 20_260_603_000_000)

    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    expires_at = DateTime.add(DateTime.utc_now(), 3600, :second) |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    binding = ["binding-valid", "subject", "org", "session", 1, "installation", "apns", "ios", "production", "matched", "token-ref", "fingerprint-valid", "granted", "active", "initial_bind", now, now, "correlation", "{}", now, now]
    missing = ["binding-missing", "subject-missing", "org-missing", "session-missing", 1, "installation-missing", "apns", "ios", "production", "unknown", "token-ref-missing", "fingerprint-missing", "granted", "active", "initial_bind", now, now, "correlation-missing", "{}", now, now]
    Repo.query!("INSERT INTO chimeway_token_bindings (binding_ref, subject_ref, org_ref, session_ref, session_version, installation_ref, provider, platform, environment, app_identity_posture, token_ref, token_fingerprint, notification_status, state, reason, bound_at, last_seen_at, audit_correlation_ref, metadata, inserted_at, updated_at, subject_scope) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'subject_session')", binding)
    Repo.query!("INSERT INTO chimeway_token_bindings (binding_ref, subject_ref, org_ref, session_ref, session_version, installation_ref, provider, platform, environment, app_identity_posture, token_ref, token_fingerprint, notification_status, state, reason, bound_at, last_seen_at, audit_correlation_ref, metadata, inserted_at, updated_at, subject_scope) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'subject_session')", missing)
    Repo.query!("UPDATE chimeway_token_bindings SET state = 'revoked' WHERE binding_ref = 'binding-missing'")
    Repo.query!("INSERT INTO chimeway_notification_open_intents (id, open_ref, binding_ref, route_id, state, expires_at, inserted_at, updated_at) VALUES ('intent-valid', 'open-valid', 'binding-valid', 'route', 'issued', ?, ?, ?)", [expires_at, now, now])
    Repo.query!("INSERT INTO chimeway_notification_open_intents (id, open_ref, binding_ref, route_id, state, expires_at, inserted_at, updated_at) VALUES ('intent-unmatched', 'open-unmatched', 'missing-binding', 'route', 'issued', ?, ?, ?)", [now, now, now])
    Repo.query!("INSERT INTO chimeway_notification_open_intents (id, open_ref, binding_ref, route_id, state, expires_at, inserted_at, updated_at) VALUES ('intent-inactive', 'open-inactive', 'binding-missing', 'route', 'issued', ?, ?, ?)", [now, now, now])

    # This column represents a host which ran the briefly released rewritten
    # migration. The forward migration must support it as well as the pristine
    # released boundary above, without replaying either historical migration.
    Repo.query!("UPDATE chimeway_token_bindings SET app_identity_ref = 'com.example.host' WHERE binding_ref = 'binding-valid'")
    collision_old = ["collision-old", "subject-collision", "org-collision", "session-collision", 1, "installation-collision", "apns", "ios", "production", "matched", "com.example.host", "token-old", "fingerprint-old", "granted", "active", "initial_bind", "2026-08-24 11:00:00", "2026-08-24 11:00:00", "correlation-old", "{}", now, now]
    collision_new = ["collision-new", "subject-collision", "org-collision", "session-collision", 1, "installation-collision", "apns", "ios", "production", "unknown", "com.example.host", "token-new", "fingerprint-new", "granted", "active", "initial_bind", now, now, "correlation-new", "{}", now, now]
    collision_sql = "INSERT INTO chimeway_token_bindings (binding_ref, subject_ref, org_ref, session_ref, session_version, installation_ref, provider, platform, environment, app_identity_posture, app_identity_ref, token_ref, token_fingerprint, notification_status, state, reason, bound_at, last_seen_at, audit_correlation_ref, metadata, inserted_at, updated_at, subject_scope) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'subject_session')"
    Repo.query!(collision_sql, collision_old)
    Repo.query!(collision_sql, collision_new)

    # These rows were valid under the released posture-keyed indexes because
    # their authority scopes and posture differ. The forward migration's new
    # posture-independent token identity index must reconcile them first.
    token_identity_old = ["token-identity-old", "subject-token-old", "org-token-old", "session-token-old", 1, "installation-token-old", "apns", "ios", "production", "matched", "com.example.host", "token-token-old", "fingerprint-token-identity", "granted", "active", "initial_bind", "2026-08-24 10:00:00", "2026-08-24 10:00:00", "correlation-token-old", "{}", now, now]
    token_identity_new = ["token-identity-new", "subject-token-new", "org-token-new", "session-token-new", 2, "installation-token-new", "apns", "ios", "production", "unknown", "com.example.host", "token-token-new", "fingerprint-token-identity", "granted", "active", "initial_bind", now, now, "correlation-token-new", "{}", now, now]
    Repo.query!(collision_sql, token_identity_old)
    Repo.query!(collision_sql, token_identity_new)

    Ecto.Migrator.run(Repo, path, :up, to: 20_260_824_210_000)

    [[scope_before_upgrade]] = Repo.query!("SELECT scope FROM chimeway_notification_open_intents WHERE open_ref = 'open-valid'").rows
    assert is_nil(scope_before_upgrade)

    malformed = ["binding-malformed-installation", "subject-malformed", "org-malformed", "session-malformed", 1, "installation-malformed", "apns", "ios", "production", "unknown", "com.example.host", "token-malformed", "fingerprint-malformed", "granted", "active", "initial_bind", now, now, "correlation-malformed", "{}", now, now]
    installation_control = ["binding-installation-control", "subject-installation-control", "org-installation-control", nil, nil, "installation-control", "apns", "ios", "production", "unknown", "com.example.host", "token-installation-control", "fingerprint-installation-control", "granted", "active", "initial_bind", now, now, "correlation-installation-control", "{}", now, now]

    Repo.query!(collision_sql |> String.replace("'subject_session'", "'subject_installation'"), malformed)
    Repo.query!(collision_sql |> String.replace("'subject_session'", "'subject_installation'"), installation_control)

    Ecto.Migrator.run(Repo, path, :up, all: true)

    [[tenant, subject, session, version, scope, state]] = Repo.query!("SELECT tenant_ref, subject_ref, session_ref, session_version, scope, state FROM chimeway_notification_open_intents WHERE open_ref = 'open-valid'").rows
    assert [tenant, subject, session, version, scope, state] == ["org", "subject", "session", 1, "subject_session", "issued"]
    [[unmatched_state]] = Repo.query!("SELECT state FROM chimeway_notification_open_intents WHERE open_ref = 'open-unmatched'").rows
    assert unmatched_state == "revoked"
    [[inactive_state]] = Repo.query!("SELECT state FROM chimeway_notification_open_intents WHERE open_ref = 'open-inactive'").rows
    assert inactive_state == "revoked"

    reconciliation_events = fn open_ref ->
      Repo.query!(
        "SELECT event.id, event.event_type, event.occurred_at, event.details, intent.updated_at " <>
          "FROM chimeway_notification_open_intent_events AS event " <>
          "INNER JOIN chimeway_notification_open_intents AS intent ON intent.id = event.open_intent_id " <>
          "WHERE intent.open_ref = ? AND event.event_type = 'reconciliation_revoked'",
        [open_ref]
      ).rows
    end

    for open_ref <- ["open-unmatched", "open-inactive"] do
      assert [[event_id, "reconciliation_revoked", occurred_at, details, updated_at]] =
               reconciliation_events.(open_ref)

      assert is_binary(event_id)
      assert Jason.decode!(details) == %{}
      assert occurred_at == updated_at
    end

    assert reconciliation_events.("open-valid") == []
    reconciliation_counts = Map.new(["open-valid", "open-unmatched", "open-inactive"], fn open_ref ->
      {open_ref, length(reconciliation_events.(open_ref))}
    end)

    Ecto.Migrator.run(Repo, path, :up, all: true)

    assert reconciliation_counts ==
             Map.new(["open-valid", "open-unmatched", "open-inactive"], fn open_ref ->
               {open_ref, length(reconciliation_events.(open_ref))}
             end)

    [[legacy_state, legacy_marker]] = Repo.query!("SELECT state, app_identity_ref FROM chimeway_token_bindings WHERE binding_ref = 'binding-missing'").rows
    assert legacy_state == "invalid"
    assert legacy_marker == "legacy_non_authoritative"
    assert 1 == Repo.aggregate(from(binding in "chimeway_token_bindings", where: binding.subject_ref == "subject-collision" and binding.state == "active"), :count)
    [[winner]] = Repo.query!("SELECT binding_ref FROM chimeway_token_bindings WHERE subject_ref = 'subject-collision' AND state = 'active'").rows
    assert winner == "collision-new"
    [[token_identity_winner]] = Repo.query!("SELECT binding_ref FROM chimeway_token_bindings WHERE token_fingerprint = 'fingerprint-token-identity' AND state = 'active'").rows
    assert token_identity_winner == "token-identity-new"
    [[token_identity_loser_state, token_identity_loser_reason]] = Repo.query!("SELECT state, reason FROM chimeway_token_bindings WHERE binding_ref = 'token-identity-old'").rows
    assert [token_identity_loser_state, token_identity_loser_reason] == ["superseded", "token_rotated"]

    indexes = Repo.query!("SELECT name, sql FROM sqlite_master WHERE type = 'index' AND tbl_name = 'chimeway_token_bindings'").rows
    for name <- ["chimeway_token_bindings_active_token_identity_index", "chimeway_token_bindings_active_subject_session_scope_index", "chimeway_token_bindings_active_subject_installation_scope_index"] do
      [^name, sql] = Enum.find(indexes, fn [index_name, _] -> index_name == name end)
      assert sql =~ "app_identity_ref"
      refute sql =~ "app_identity_posture"
    end

    [[malformed_state, malformed_reason]] = Repo.query!("SELECT state, reason FROM chimeway_token_bindings WHERE binding_ref = 'binding-malformed-installation'").rows
    assert [malformed_state, malformed_reason] == ["revoked", "session_revoked"]
    [[valid_session_state]] = Repo.query!("SELECT state FROM chimeway_token_bindings WHERE binding_ref = 'binding-valid'").rows
    assert valid_session_state == "active"
    [[installation_control_state]] = Repo.query!("SELECT state FROM chimeway_token_bindings WHERE binding_ref = 'binding-installation-control'").rows
    assert installation_control_state == "active"

    triggers = Repo.query!("SELECT name FROM sqlite_master WHERE type = 'trigger' AND tbl_name = 'chimeway_token_bindings'").rows
    assert ["chimeway_token_bindings_subject_scope_consistency_insert_guard"] in triggers
    assert ["chimeway_token_bindings_subject_scope_consistency_update_guard"] in triggers

    invalid_active = ["binding-direct-invalid", "subject-direct", "org-direct", "session-direct", 1, "installation-direct", "apns", "ios", "production", "unknown", "com.example.host", "token-direct", "fingerprint-direct", "granted", "active", "initial_bind", now, now, "correlation-direct", "{}", now, now]

    assert_raise Exqlite.Error, fn ->
      Repo.query!(collision_sql |> String.replace("'subject_session'", "'subject_installation'"), invalid_active)
    end

    valid_installation = ["binding-direct-valid", "subject-direct-valid", "org-direct-valid", nil, nil, "installation-direct-valid", "apns", "ios", "production", "unknown", "com.example.host", "token-direct-valid", "fingerprint-direct-valid", "granted", "active", "initial_bind", now, now, "correlation-direct-valid", "{}", now, now]
    Repo.query!(collision_sql |> String.replace("'subject_session'", "'subject_installation'"), valid_installation)

    assert_raise Exqlite.Error, fn ->
      Repo.query!("UPDATE chimeway_token_bindings SET session_ref = 'unexpected', session_version = 1 WHERE binding_ref = 'binding-direct-valid'")
    end

    alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
    alias CrosswakeExample.Chimeway.{NotificationOpenIntent, NotificationOpenIntentEvent, Registry}

    evidence = %NotificationOpenEvidence{
      route_id: "untrusted-route",
      action_ref: "untrusted-action",
      open_ref: "open-valid",
      binding_ref: "binding-valid",
      provider: :apns,
      auth_context: %{
        tenant_ref: "org",
        subject_ref: "subject",
        installation_ref: "installation",
        subject_scope: :subject_session,
        session_ref: "session",
        session_version: 1
      }
    }

    assert {:ok, %{state: :valid}} = Registry.consume_intent(evidence)
    assert {:ok, %{state: :replayed}} = Registry.consume_intent(evidence)

    intent = Repo.get_by!(NotificationOpenIntent, open_ref: "open-valid")
    assert intent.state == "consumed"
    assert intent.consumed_at
    assert Repo.exists?(from(event in NotificationOpenIntentEvent, where: event.open_intent_id == ^intent.id and event.event_type == "consumed"))
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: Path.expand("../../..", __DIR__),
               stderr_to_stdout: true
             )

    refute output =~ "raw-apns-token"
  end
end
