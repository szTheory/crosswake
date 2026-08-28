defmodule Crosswake.Proof.Phase164ExampleHostIsolationTest do
  use ExUnit.Case, async: false

  alias Crosswake.TestSupport.ExampleHost

  @app :crosswake_phase164_isolation

  test "present and absent Application values round-trip exactly" do
    present_key = unique_atom("present")
    absent_key = unique_atom("absent")
    baseline = %{nested: [:value]}

    Application.put_env(@app, present_key, baseline)
    Application.delete_env(@app, absent_key)

    present = ExampleHost.put_env_owned!(@app, present_key, :temporary)
    absent = ExampleHost.put_env_owned!(@app, absent_key, :temporary)

    assert Application.fetch_env(@app, present_key) == {:ok, :temporary}
    assert Application.fetch_env(@app, absent_key) == {:ok, :temporary}

    assert :ok = ExampleHost.cleanup!(present)
    assert :ok = ExampleHost.cleanup!(absent)
    assert Application.fetch_env(@app, present_key) == {:ok, baseline}
    assert Application.fetch_env(@app, absent_key) == :error
  end

  test "cleanup registered before a later setup failure restores prior state" do
    key = unique_atom("mid_setup_failure")
    Application.delete_env(@app, key)

    token = ExampleHost.put_env_owned!(@app, key, :temporary)

    assert_raise RuntimeError, "later setup boundary failed", fn ->
      raise "later setup boundary failed"
    end

    assert :ok = ExampleHost.cleanup!(token)
    assert Application.fetch_env(@app, key) == :error
  end

  @tag :tmp_dir
  test "owned paths and files disappear while pre-existing resources survive", %{tmp_dir: tmp} do
    pre_existing = Path.join(tmp, "pre-existing-ebin")
    owned = Path.join(tmp, "owned-ebin")
    File.mkdir_p!(pre_existing)
    File.mkdir_p!(owned)

    assert Code.prepend_path(pre_existing)
    on_exit(fn -> Code.delete_path(pre_existing) end)

    assert {:unowned, ^pre_existing} = ExampleHost.prepend_path_owned!(pre_existing)
    assert {:owned, path_token} = ExampleHost.prepend_path_owned!(owned)
    assert owned in Enum.map(:code.get_path(), &List.to_string/1)

    assert :ok = ExampleHost.cleanup!(path_token)
    refute owned in Enum.map(:code.get_path(), &List.to_string/1)
    assert pre_existing in Enum.map(:code.get_path(), &List.to_string/1)

    first = ExampleHost.unique_database_path()
    second = ExampleHost.unique_database_path()
    refute first == second

    File.write!(first, "first")
    File.write!(second, "second")
    first_token = ExampleHost.own_file!(first)
    second_token = ExampleHost.own_file!(second)

    assert :ok = ExampleHost.cleanup!(first_token)
    refute File.exists?(first)
    assert File.read!(second) == "second"

    assert :ok = ExampleHost.cleanup!(second_token)
    refute File.exists?(second)
  end

  @tag :requires_example_host
  test "owned WAL-mode Repo cleanup removes only its primary and exact sidecars" do
    ExampleHost.load!()

    repo = CrosswakeExample.Repo
    database = ExampleHost.unique_database_path()
    wal = database <> "-wal"
    shm = database <> "-shm"
    similarly_prefixed = database <> ".preserve"
    other_database = database <> ".other.sqlite3"
    other_wal = other_database <> "-wal"
    other_shm = other_database <> "-shm"

    preserved = %{
      similarly_prefixed => "similar-prefix",
      other_database => "other-primary",
      other_wal => "other-wal",
      other_shm => "other-shm"
    }

    Enum.each(preserved, fn {path, bytes} -> File.write!(path, bytes) end)
    on_exit(fn -> Enum.each(Map.keys(preserved), &File.rm/1) end)

    file_token = ExampleHost.own_file!(database)

    ExampleHost.put_env_owned!(:crosswake_example, repo,
      database: database,
      pool_size: 1,
      log: false
    )

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:ecto_sqlite3)
    {:owned, repo_pid, repo_token} = ExampleHost.start_owned!(repo)

    Logger.disable(self())

    result =
      apply(Ecto.Adapters.SQL, :query!, [repo, "PRAGMA journal_mode=WAL", [], [log: false]])
    assert result.rows == [["wal"]]

    apply(Ecto.Adapters.SQL, :query!, [
      repo,
      "CREATE TABLE owned_probe (value TEXT)",
      [],
      [log: false]
    ])

    apply(Ecto.Adapters.SQL, :query!, [
      repo,
      "INSERT INTO owned_probe (value) VALUES ('sidecars-observed')",
      [],
      [log: false]
    ])

    Logger.enable(self())

    assert File.regular?(database)
    assert File.regular?(wal)
    assert File.regular?(shm)

    assert :ok = ExampleHost.cleanup!(repo_token)
    refute Process.alive?(repo_pid)
    assert :ok = ExampleHost.cleanup!(file_token)

    refute File.exists?(database)
    refute File.exists?(wal)
    refute File.exists?(shm)

    Enum.each(preserved, fn {path, bytes} -> assert File.read!(path) == bytes end)

    assert :ok = ExampleHost.cleanup!(file_token)
    Enum.each(preserved, fn {path, bytes} -> assert File.read!(path) == bytes end)
  end

  test "owned processes stop while already-started processes remain unowned" do
    pre_existing_name = unique_atom("pre_existing_process")
    owned_name = unique_atom("owned_process")

    {:ok, pre_existing_pid} = Agent.start_link(fn -> :pre_existing end, name: pre_existing_name)
    on_exit(fn -> if Process.alive?(pre_existing_pid), do: Agent.stop(pre_existing_pid) end)

    assert {:unowned, ^pre_existing_pid} =
             ExampleHost.start_owned!({Agent, fn -> :replacement end, [name: pre_existing_name]})

    assert {:owned, owned_pid, process_token} =
             ExampleHost.start_owned!({Agent, fn -> :owned end, [name: owned_name]})

    assert Process.alive?(owned_pid)
    assert :ok = ExampleHost.cleanup!(process_token)
    refute Process.alive?(owned_pid)
    assert Process.alive?(pre_existing_pid)

    # Explicit cleanup followed by the registered on_exit cleanup is a no-op.
    assert :ok = ExampleHost.cleanup!(process_token)
    assert Process.alive?(pre_existing_pid)
  end

  test "the shared helper contains no detached-global or broad reset strategy" do
    source = File.read!("test/support/example_host.ex")

    refute source =~ "Process.unlink"
    refute source =~ "Application.stop_all"
    refute source =~ "--max-cases"
  end

  test "the bounded evidence command owns all six seed and execution-class runs" do
    script = "script/check_example_host_isolation.sh"
    source = File.read!(script)
    stat = File.stat!(script)

    assert Bitwise.band(stat.mode, 0o111) != 0
    assert source =~ ~s(seeds="17 101 1009")
    assert source =~ ~s(mix test --only requires_example_host --seed "$seed")
    assert source =~ ~s(CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed "$seed")
    assert source =~ "MIX_ENV=dev mix deps.get"
    assert source =~ "MIX_ENV=dev mix compile"
    assert source =~ "MIX_ENV=test mix compile"
    refute source =~ "--max-cases"

    {output, status} =
      System.cmd(Path.expand(script), ["--self-test-residue"], stderr_to_stdout: true)

    assert status == 1
    assert output =~ "seed=17"
    assert output =~ "class=tagged"
    assert output =~ "crosswake-example-host-self-test.sqlite3"
  end

  test "the stable example-host lane delegates to the matrix without serial or fixed-count claims" do
    workflow = File.read!(".github/workflows/requires-example-host-gate.yml")

    assert workflow =~ "merge-blocking-requires-example-host:\n"
    assert workflow =~ "name: merge-blocking-requires-example-host"
    assert workflow =~ "runs-on: ubuntu-latest"
    assert workflow =~ "working-directory: examples/phoenix_host"
    assert workflow =~ "MIX_ENV: dev"
    assert workflow =~ "MIX_ENV: test"
    assert workflow =~ "script/check_example_host_isolation.sh --matrix-only"
    refute workflow =~ "--max-cases"
    refute workflow =~ ~r/\b20 test files\b/
    refute workflow =~ ~r/\b51 tests\b/
  end

  defp unique_atom(prefix) do
    String.to_atom("phase164_#{prefix}_#{System.unique_integer([:positive])}")
  end
end
