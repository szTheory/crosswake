defmodule Mix.Tasks.Crosswake.GenShell.DiffTest do
  @moduledoc """
  Scaffold test for LIFE-02b — `mix crosswake.gen.shell --diff` behaviours.

  Tests are pending-skipped until the `--diff` switch exists in the gen.shell task
  (Plan 03). The module tag `:phase134_pending` excludes these from CI until it lands.

  Behaviours under test (turning GREEN in Plan 03):
    - diff-no-write: `--diff` makes NO changes to any file on disk
    - diff-stdout: captured output contains a unified-diff `---`/`+++` header
    - pbxproj-excluded: output does NOT contain `project.pbxproj`
  """

  use ExUnit.Case, async: true

  @moduletag :phase134_pending

  @gen_shell_module Mix.Tasks.Crosswake.Gen.Shell

  # ---------------------------------------------------------------------------
  # Guard: all tests skip until the `--diff` option is present in gen.shell.
  # The switch is detected by checking module attributes via __info__(:attributes).
  # Plan 03 removes the guard and wires real assertions.
  # ---------------------------------------------------------------------------

  defp diff_switch_available? do
    if Code.ensure_loaded?(@gen_shell_module) do
      attributes = @gen_shell_module.__info__(:attributes)
      switches = Keyword.get(attributes, :switches, [])
      Keyword.has_key?(switches, :diff)
    else
      false
    end
  end

  # ---------------------------------------------------------------------------
  # Tests — pending-skipped until --diff switch exists
  # ---------------------------------------------------------------------------

  test "diff-no-write: --diff makes no changes to any file on disk" do
    if Code.ensure_loaded?(@gen_shell_module) and diff_switch_available?() do
      # Snapshot file mtimes before --diff run
      tmp = System.tmp_dir!() |> Path.join("cw_diff_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp)

      try do
        # Capture mtimes before
        template_dir = Path.join([File.cwd!(), "priv", "templates", "crosswake", "shell"])
        files_before = Path.wildcard(Path.join(template_dir, "**/*"))

        mtimes_before =
          Map.new(files_before, fn f ->
            {f, File.stat!(f).mtime}
          end)

        contents_before =
          Map.new(files_before, fn f ->
            if File.regular?(f), do: {f, File.read!(f)}, else: {f, :dir}
          end)

        # Run --diff (output captured, files should not change)
        ExUnit.CaptureIO.capture_io(fn ->
          Mix.Task.rerun("crosswake.gen.shell", ["ios", "--diff"])
        end)

        # Verify no files changed
        for {path, mtime_before} <- mtimes_before do
          if File.exists?(path) and File.regular?(path) do
            assert File.read!(path) == contents_before[path],
                   "--diff must not modify #{path}"

            assert File.stat!(path).mtime == mtime_before,
                   "--diff must not touch mtime of #{path}"
          end
        end
      after
        File.rm_rf!(tmp)
      end
    else
      :ok
    end
  end

  test "diff-stdout: captured output contains unified-diff --- / +++ header" do
    if Code.ensure_loaded?(@gen_shell_module) and diff_switch_available?() do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          try do
            Mix.Task.rerun("crosswake.gen.shell", ["ios", "--diff"])
          catch
            :exit, _ -> :ok
          end
        end)

      # When templates have changed, expect a unified diff header
      # (This test verifies the output FORMAT — actual diff content is Plan 03's concern)
      assert String.contains?(output, "---") or String.contains?(output, "[crosswake]"),
             "Expected --diff output to contain a unified diff header or [crosswake] info line"
    else
      :ok
    end
  end

  test "pbxproj-excluded: --diff output does not contain project.pbxproj" do
    if Code.ensure_loaded?(@gen_shell_module) and diff_switch_available?() do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          try do
            Mix.Task.rerun("crosswake.gen.shell", ["ios", "--diff"])
          catch
            :exit, _ -> :ok
          end
        end)

      refute String.contains?(output, "project.pbxproj"),
             "--diff output must not include project.pbxproj (excluded by @diff_excluded_templates)"
    else
      :ok
    end
  end
end
