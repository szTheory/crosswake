defmodule Mix.Tasks.Crosswake.Gen.AuditTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Crosswake.Gen.Audit, only: [run: 1]

  @tmp_dir "tmp_audit_test"

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  test "generates audit schema and migration templates idempotently" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "audit", "ledger.ex"])
    assert File.exists?(schema_path)

    schema_content = File.read!(schema_path)
    assert schema_content =~ "defmodule TestApp.Audit.Ledger do"
    assert schema_content =~ "schema \"crosswake_audit_events\" do"

    migrations_dir = Path.join([@tmp_dir, "priv", "repo", "migrations"])
    assert File.exists?(migrations_dir)

    migration_files = File.ls!(migrations_dir)
    assert length(migration_files) == 1
    migration_file = hd(migration_files)
    assert migration_file =~ "_create_crosswake_audit_events.exs"

    migration_path = Path.join(migrations_dir, migration_file)
    migration_content = File.read!(migration_path)
    assert migration_content =~ "defmodule TestApp.Repo.Migrations.CreateCrosswakeAuditEvents do"

    # Test idempotency
    run(["--dir", @tmp_dir, "--app", "TestApp"])
    migration_files_after = File.ls!(migrations_dir)
    assert length(migration_files_after) == 1
  end
end
