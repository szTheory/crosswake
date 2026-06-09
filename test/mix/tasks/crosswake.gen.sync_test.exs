defmodule Mix.Tasks.Crosswake.Gen.SyncTest do
  use ExUnit.Case, async: false

  import Mix.Tasks.Crosswake.Gen.Sync, only: [run: 1]

  @tmp_dir "tmp_sync_test"

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end

  test "generates sync schema and controller templates" do
    # Temporarily override Mix's path knowledge or just pass a target context if possible.
    # We will pass the root dir as an option to the generator.
    run(["--dir", @tmp_dir, "--app", "TestApp"])

    schema_path = Path.join([@tmp_dir, "lib", "test_app", "sync", "event_log.ex"])
    controller_path = Path.join([@tmp_dir, "lib", "test_app_web", "controllers", "sync_controller.ex"])

    assert File.exists?(schema_path)
    assert File.exists?(controller_path)

    schema_content = File.read!(schema_path)
    assert schema_content =~ "defmodule TestApp.Sync.EventLog do"
    assert schema_content =~ "schema \"crosswake_sync_event_logs\" do"

    controller_content = File.read!(controller_path)
    assert controller_content =~ "defmodule TestAppWeb.SyncController do"
    assert controller_content =~ "def replay(conn, %{\"events\" => events}) do"
  end
end
