defmodule Mix.Tasks.Crosswake.Shell.StatusTest do
  @moduledoc """
  Scaffold test for LIFE-02b — `mix crosswake.shell.status` exit-code behaviours.

  Tests are pending-skipped until Mix.Tasks.Crosswake.Shell.Status exists (Plan 02).
  The module tag `:phase134_pending` excludes these from CI until the task lands.

  Behaviours under test (turning GREEN in Plan 02):
    - exit 0 when shells are up-to-date
    - exit 0 when no .crosswake/shell.json found (not-a-shell path — non-adopter CI safe)
    - exit 2 when at least one platform is behind
    - exit 1 (Mix.raise) on bad / unreadable manifest
  """

  use ExUnit.Case, async: true

  @moduletag :phase134_pending

  @status_task_module Mix.Tasks.Crosswake.Shell.Status

  # ---------------------------------------------------------------------------
  # Guard: all tests in this file are skipped until the status task module loads.
  # Plan 02 removes the guard and wires real assertions.
  # ---------------------------------------------------------------------------

  defp task_loaded? do
    Code.ensure_loaded?(@status_task_module)
  end

  # ---------------------------------------------------------------------------
  # Helpers — write a minimal .crosswake/shell.json into a tmp dir and run the
  # task there, catching the exit({:shutdown, N}) tuple.
  # ---------------------------------------------------------------------------

  defp run_status(tmp_dir, manifest_content, args \\ []) do
    manifest_path = Path.join([tmp_dir, ".crosswake", "shell.json"])
    File.mkdir_p!(Path.dirname(manifest_path))
    if manifest_content != :no_file, do: File.write!(manifest_path, manifest_content)

    original_cwd = File.cwd!()
    File.cd!(tmp_dir)

    result =
      try do
        Mix.Task.rerun("crosswake.shell.status", args)
        {:exit_code, 0}
      catch
        :exit, {:shutdown, code} -> {:exit_code, code}
      after
        File.cd!(original_cwd)
      end

    result
  end

  defp up_to_date_manifest do
    Jason.encode!(%{
      "template_version" => 1,
      "platforms" => %{
        "ios" => %{"template_version" => 1},
        "android" => %{"template_version" => 1}
      }
    })
  end

  defp behind_manifest do
    Jason.encode!(%{
      "template_version" => 5,
      "platforms" => %{
        "ios" => %{"template_version" => 3},
        "android" => %{"template_version" => 5}
      }
    })
  end

  # ---------------------------------------------------------------------------
  # Tests — pending-skipped until @status_task_module is loaded
  # ---------------------------------------------------------------------------

  test "exit 0 when shells are up to date" do
    if task_loaded?() do
      tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)

      try do
        assert {:exit_code, 0} = run_status(tmp, up_to_date_manifest())
      after
        File.rm_rf!(tmp)
      end
    else
      :ok
    end
  end

  test "exit 0 when no .crosswake/shell.json found (not-a-shell path)" do
    if task_loaded?() do
      tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)

      try do
        assert {:exit_code, 0} = run_status(tmp, :no_file)
      after
        File.rm_rf!(tmp)
      end
    else
      :ok
    end
  end

  test "exit 2 when at least one platform is behind" do
    if task_loaded?() do
      tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)

      try do
        assert {:exit_code, 2} = run_status(tmp, behind_manifest())
      after
        File.rm_rf!(tmp)
      end
    else
      :ok
    end
  end

  test "exit 1 (Mix.raise) on bad / unreadable manifest" do
    if task_loaded?() do
      tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)

      try do
        # Write invalid JSON so the manifest parse fails
        assert_raise Mix.Error, fn ->
          run_status(tmp, "{not valid json}")
        end
      after
        File.rm_rf!(tmp)
      end
    else
      :ok
    end
  end
end
