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

  defp unique_atom(prefix) do
    String.to_atom("phase164_#{prefix}_#{System.unique_integer([:positive])}")
  end
end
