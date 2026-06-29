defmodule Mix.Tasks.Crosswake.GenShell.DiffTest do
  @moduledoc """
  Tests for LIFE-02b — `mix crosswake.gen.shell --diff` behaviours.

  Three behaviours under test:
    - diff-no-write: `--diff` makes NO changes to any file on disk (byte-identical before/after)
    - diff-stdout: captured output contains a unified-diff `---` header when a generated file differs
    - pbxproj-excluded: output does NOT contain `project.pbxproj`
  """

  # Mix.Task.rerun modifies global Mix task state; async: false prevents races
  # with other mix-task tests running concurrently.
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @gen_shell_task "crosswake.gen.shell"

  # ---------------------------------------------------------------------------
  # Helper: recursively snapshot all files and their contents in a directory.
  # Returns a map of path => binary content (or :dir for directories).
  # ---------------------------------------------------------------------------

  defp snapshot_files(dir) do
    dir
    |> Path.join("**")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      if File.dir?(path) do
        {path, :dir}
      else
        {path, File.read!(path)}
      end
    end)
    |> Map.new()
  end

  # ---------------------------------------------------------------------------
  # Test 1: diff-no-write
  # Generate a shell into a tmp dir, snapshot all files + contents, run --diff,
  # re-snapshot, assert byte-identical. No file should be created, modified, or deleted.
  # ---------------------------------------------------------------------------

  test "diff-no-write: --diff makes no changes to any file on disk" do
    tmp =
      System.tmp_dir!()
      |> Path.join("cw_diff_no_write_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    try do
      # Generate a real android shell
      capture_io(fn ->
        Mix.Task.rerun(@gen_shell_task, ["android", "--target", tmp])
      end)

      # Snapshot full file set with content
      snapshot_before = snapshot_files(tmp)

      # Run --diff — must write nothing
      capture_io(fn ->
        Mix.Task.rerun(@gen_shell_task, ["android", "--target", tmp, "--diff"])
      end)

      snapshot_after = snapshot_files(tmp)

      # Assert byte-identical: no files added, removed, or changed
      assert Map.keys(snapshot_before) |> Enum.sort() ==
               Map.keys(snapshot_after) |> Enum.sort(),
             "--diff must not create or delete any files"

      Enum.each(snapshot_before, fn {path, content_before} ->
        content_after = Map.fetch!(snapshot_after, path)

        assert content_before == content_after,
               "--diff must not modify #{path}"
      end)
    after
      File.rm_rf!(tmp)
    end
  end

  # ---------------------------------------------------------------------------
  # Test 2: diff-stdout
  # Generate a shell, modify one generated file on disk (to force a diff),
  # run --diff, assert the output contains a unified-diff `---` header.
  # We edit the ON-DISK generated file (not the template) so the diff triggers.
  # ---------------------------------------------------------------------------

  test "diff-stdout: output contains unified-diff --- header when a generated file differs" do
    tmp =
      System.tmp_dir!()
      |> Path.join("cw_diff_stdout_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    try do
      # Generate android shell
      capture_io(fn ->
        Mix.Task.rerun(@gen_shell_task, ["android", "--target", tmp])
      end)

      # Modify a generated file to force a diff (edit the on-disk copy, not the template)
      gradle_props = Path.join([tmp, "native", "android", "crosswake_shell", "gradle.properties"])
      original = File.read!(gradle_props)
      File.write!(gradle_props, original <> "\n# diff-test-sentinel-line\n")

      # Run --diff and capture output
      output =
        capture_io(fn ->
          Mix.Task.rerun(@gen_shell_task, ["android", "--target", tmp, "--diff"])
        end)

      assert String.contains?(output, "---"),
             "Expected --diff output to contain a unified diff '---' header when a file differs; got:\n#{output}"
    after
      File.rm_rf!(tmp)
    end
  end

  # ---------------------------------------------------------------------------
  # Test 3: pbxproj-excluded
  # Generate an iOS shell, run --diff on it, assert "project.pbxproj" does not
  # appear anywhere in the output.
  # ---------------------------------------------------------------------------

  test "pbxproj-excluded: --diff output does not contain project.pbxproj" do
    tmp =
      System.tmp_dir!()
      |> Path.join("cw_diff_pbxproj_#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    try do
      # Generate iOS shell (pbxproj is an iOS template)
      capture_io(fn ->
        Mix.Task.rerun(@gen_shell_task, ["ios", "--target", tmp])
      end)

      output =
        capture_io(fn ->
          Mix.Task.rerun(@gen_shell_task, ["ios", "--target", tmp, "--diff"])
        end)

      refute String.contains?(output, "project.pbxproj"),
             "--diff output must not include project.pbxproj (excluded by @diff_excluded_templates);\ngot:\n#{output}"
    after
      File.rm_rf!(tmp)
    end
  end
end
