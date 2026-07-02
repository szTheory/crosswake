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

  test "generated ledger contains try/rescue crash-isolation (never reraises — keeps handler attached)" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "audit", "ledger.ex"])
    schema_content = File.read!(schema_path)

    # Handler must wrap write in try/rescue
    assert schema_content =~ "rescue",
           "Generated ledger must contain rescue to catch write failures and keep the telemetry handler attached"

    # Handler MUST NOT reraise (reraising causes telemetry auto-detach → silent audit blackout)
    # The generated file should have Logger.error and return :ok on rescue, never reraise
    refute schema_content =~ "reraise",
           "Generated ledger must NEVER use reraise — reraising auto-detaches the telemetry handler (silent audit blackout)"
  end

  test "generated ledger contains on_conflict: :nothing for idempotent replays" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "audit", "ledger.ex"])
    schema_content = File.read!(schema_path)

    assert schema_content =~ "on_conflict",
           "Generated ledger must use on_conflict: :nothing so replay events are idempotent"
  end

  test "generated ledger moduledoc marks row_hash/prev_hash as advisory (not tamper-evidence)" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "audit", "ledger.ex"])
    schema_content = File.read!(schema_path)

    assert schema_content =~ "advisory",
           "Generated ledger @moduledoc must mark row_hash/prev_hash as ADVISORY, not tamper-evidence"
  end

  test "generated ledger identifies idempotency_key as the real integrity guarantee" do
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "audit", "ledger.ex"])
    schema_content = File.read!(schema_path)

    assert schema_content =~ "idempotency_key",
           "Generated ledger must name idempotency_key as the real integrity guarantee"
  end

  test "Next steps output contains mix crosswake.threadline CTA (brand-voice inspect guidance)" do
    import ExUnit.CaptureIO

    output =
      capture_io(fn ->
        run(["--dir", @tmp_dir, "--app", "TestApp"])
      end)

    assert output =~ "mix crosswake.threadline",
           "Next steps must include 'mix crosswake.threadline' CTA so operators know how to inspect recorded events"
  end

  test "Next steps output contains mix ecto.create note (brand-voice database-first guidance)" do
    import ExUnit.CaptureIO

    output =
      capture_io(fn ->
        run(["--dir", @tmp_dir, "--app", "TestApp"])
      end)

    assert output =~ "mix ecto.create",
           "Next steps must include 'mix ecto.create' note so operators know to create the database first"
  end

  test "skipping message used (not 'reused') when file already exists — clear verb" do
    import ExUnit.CaptureIO

    # First run creates the files
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    # Second run should say "skipping", not "reused"
    output =
      capture_io(fn ->
        run(["--dir", @tmp_dir, "--app", "TestApp"])
      end)

    assert output =~ "skipping",
           "Idempotent re-run must print 'skipping' (not 'reused') to clearly communicate the file was not re-written"

    refute output =~ "reused",
           "Must not print 'reused' — use 'skipping' to match brandbook voice (verb-first, concrete)"
  end
end
