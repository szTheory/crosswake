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
    Mix.Task.run("app.config")

    db = Path.join(System.tmp_dir!(), "crosswake_registration_upgrade_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db")
    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    alias CrosswakeExample.Repo

    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(Repo, path, :up, to: 20_260_603_000_000)

    now = "2026-08-24 12:00:00"
    binding = ["binding-valid", "subject", "org", "session", 1, "installation", "apns", "ios", "production", "matched", "token-ref", "fingerprint-valid", "granted", "active", "initial_bind", now, now, "correlation", "{}", now, now]
    missing = ["binding-missing", "subject-missing", "org-missing", "session-missing", 1, "installation-missing", "apns", "ios", "production", "unknown", "token-ref-missing", "fingerprint-missing", "granted", "active", "initial_bind", now, now, "correlation-missing", "{}", now, now]
    Repo.query!("INSERT INTO chimeway_token_bindings (binding_ref, subject_ref, org_ref, session_ref, session_version, installation_ref, provider, platform, environment, app_identity_posture, token_ref, token_fingerprint, notification_status, state, reason, bound_at, last_seen_at, audit_correlation_ref, metadata, inserted_at, updated_at, subject_scope) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'subject_session')", binding)
    Repo.query!("INSERT INTO chimeway_token_bindings (binding_ref, subject_ref, org_ref, session_ref, session_version, installation_ref, provider, platform, environment, app_identity_posture, token_ref, token_fingerprint, notification_status, state, reason, bound_at, last_seen_at, audit_correlation_ref, metadata, inserted_at, updated_at, subject_scope) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'subject_session')", missing)
    Repo.query!("INSERT INTO chimeway_notification_open_intents (id, open_ref, binding_ref, route_id, state, expires_at, inserted_at, updated_at) VALUES ('intent-valid', 'open-valid', 'binding-valid', 'route', 'issued', ?, ?, ?)", [now, now, now])
    Repo.query!("INSERT INTO chimeway_notification_open_intents (id, open_ref, binding_ref, route_id, state, expires_at, inserted_at, updated_at) VALUES ('intent-unmatched', 'open-unmatched', 'missing-binding', 'route', 'issued', ?, ?, ?)", [now, now, now])

    Ecto.Migrator.run(Repo, path, :up, all: true)

    [[tenant, subject, session, version, state]] = Repo.query!("SELECT tenant_ref, subject_ref, session_ref, session_version, state FROM chimeway_notification_open_intents WHERE open_ref = 'open-valid'").rows
    assert [tenant, subject, session, version, state] == ["org", "subject", "session", 1, "issued"]
    [[unmatched_state]] = Repo.query!("SELECT state FROM chimeway_notification_open_intents WHERE open_ref = 'open-unmatched'").rows
    assert unmatched_state == "revoked"
    [[legacy_state, legacy_marker]] = Repo.query!("SELECT state, app_identity_ref FROM chimeway_token_bindings WHERE binding_ref = 'binding-missing'").rows
    assert legacy_state == "invalid"
    assert legacy_marker == "legacy_non_authoritative"

    indexes = Repo.query!("SELECT name, sql FROM sqlite_master WHERE type = 'index' AND tbl_name = 'chimeway_token_bindings'").rows
    for name <- ["chimeway_token_bindings_active_token_identity_index", "chimeway_token_bindings_active_subject_session_scope_index", "chimeway_token_bindings_active_subject_installation_scope_index"] do
      [^name, sql] = Enum.find(indexes, fn [index_name, _] -> index_name == name end)
      assert sql =~ "app_identity_ref"
      refute sql =~ "app_identity_posture"
    end
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: Path.expand("../../..", __DIR__),
               stderr_to_stdout: true
             )

    assert output =~ "Migrated"
  end
end
