defmodule Crosswake.Planning.PathsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Planning.Paths

  setup do
    previous = System.get_env("GSD_WORKSTREAM")
    System.delete_env("GSD_WORKSTREAM")

    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-planning-paths-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)

    on_exit(fn ->
      File.rm_rf!(root)

      if previous do
        System.put_env("GSD_WORKSTREAM", previous)
      else
        System.delete_env("GSD_WORKSTREAM")
      end
    end)

    %{root: root}
  end

  test "prefers the backwards-compatible flat planning root", %{root: root} do
    write_state(root, ".planning", "planning")
    write_state(root, ".planning/workstreams/quality", "ready_to_plan")

    assert Paths.resolve!(root) == Path.join(root, ".planning")
  end

  test "selects the sole active workstream while another is parked", %{root: root} do
    write_state(root, ".planning/workstreams/adopter", "parked_external_dependency")
    write_state(root, ".planning/workstreams/quality", "ready_to_plan")

    assert Paths.resolve!(root) == Path.join(root, ".planning/workstreams/quality")
  end

  test "fails closed when more than one active workstream is available", %{root: root} do
    write_state(root, ".planning/workstreams/one", "ready_to_plan")
    write_state(root, ".planning/workstreams/two", "in_progress")

    assert_raise RuntimeError, ~r/pass :planning_root explicitly/, fn ->
      Paths.resolve!(root)
    end
  end

  test "accepts an explicit relative planning root", %{root: root} do
    assert Paths.resolve!(root, planning_root: "custom/planning") ==
             Path.join(root, "custom/planning")
  end

  defp write_state(root, relative_root, status) do
    directory = Path.join(root, relative_root)
    File.mkdir_p!(directory)
    File.write!(Path.join(directory, "STATE.md"), "---\nstatus: #{status}\n---\n")
  end
end
