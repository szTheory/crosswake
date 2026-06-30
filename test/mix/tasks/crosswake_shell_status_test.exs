defmodule Mix.Tasks.Crosswake.Shell.StatusTest do
  @moduledoc """
  Tests for LIFE-02b — `mix crosswake.shell.status` exit-code behaviours.

  Behaviours under test:
    - exit 0 when shells are up-to-date (stamped == live template_version)
    - exit 0 when no .crosswake/shell.json found (not-a-shell path — non-adopter CI safe)
    - exit 2 when at least one platform is behind (stamped < live)
    - exit 1 (Mix.raise) on bad / unreadable manifest
    - --format json emits a decodable per-platform status payload
  """

  # async: false — run_status/3 changes the global process working directory via
  # File.cd!/2 while exercising the mix task. Under async: true it raced with the
  # concurrent crosswake_gen_shell_test.exs, whose template render resolves a
  # CWD-relative _build path (Application.app_dir) and then failed with File.Error
  # when CWD pointed at this test's tmp dir. async: false serializes it (matching
  # crosswake_doctor_test.exs and crosswake_gen_shell_diff_test.exs), eliminating
  # the race. (deferred-items.md item 1 — confirmed as the cause of red broad-suite
  # CI lanes on PR #40.)
  use ExUnit.Case, async: false

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

  # Live template version — the single source of truth (Plan 01 ships this as 2).
  defp live_version, do: Mix.Tasks.Crosswake.Gen.Shell.template_version()

  defp up_to_date_manifest do
    Jason.encode!(%{
      "template_version" => live_version(),
      "platform" => "ios"
    })
  end

  defp behind_manifest do
    Jason.encode!(%{
      "template_version" => live_version() - 1,
      "platform" => "ios"
    })
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  test "exit 0 when shells are up to date" do
    tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    try do
      assert {:exit_code, 0} = run_status(tmp, up_to_date_manifest())
    after
      File.rm_rf!(tmp)
    end
  end

  test "exit 0 when no .crosswake/shell.json found (not-a-shell path)" do
    tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    try do
      assert {:exit_code, 0} = run_status(tmp, :no_file)
    after
      File.rm_rf!(tmp)
    end
  end

  test "exit 2 when manifest is behind (stamped < live)" do
    tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    try do
      assert {:exit_code, 2} = run_status(tmp, behind_manifest())
    after
      File.rm_rf!(tmp)
    end
  end

  test "exit 1 (Mix.raise) on malformed JSON manifest" do
    tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    try do
      assert_raise Mix.Error, fn ->
        run_status(tmp, "{not valid json}")
      end
    after
      File.rm_rf!(tmp)
    end
  end

  test "--format json emits decodable per-platform payload" do
    tmp = System.tmp_dir!() |> Path.join("cw_status_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp)

    try do
      # Capture output by using Mix.shell() mock
      output_lines =
        ExUnit.CaptureIO.capture_io(fn ->
          run_status(tmp, up_to_date_manifest(), ["--format", "json"])
        end)

      # The JSON payload should decode to a map with status and platforms keys
      decoded = Jason.decode!(output_lines)
      assert decoded["status"] == "up_to_date"
      assert is_map(decoded["platforms"])
      assert decoded["current_version"] == live_version()

      # Each present platform entry has the required keys
      for {_platform, entry} <- decoded["platforms"] do
        assert Map.has_key?(entry, "status")
        assert Map.has_key?(entry, "stamped_version")
        assert Map.has_key?(entry, "current_version")
        assert Map.has_key?(entry, "versions_behind")
        assert Map.has_key?(entry, "highest_severity")
      end
    after
      File.rm_rf!(tmp)
    end
  end
end
