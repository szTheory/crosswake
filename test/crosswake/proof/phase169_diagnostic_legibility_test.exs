defmodule Crosswake.Proof.Phase169DiagnosticLegibilityTest do
  @moduledoc """
  Merge-blocking proof for Phase 169 (Diagnostic Legibility).

  Closes the live PR #164 defect: a single failing scanner check's own sentence must
  reach the maintainer, end to end, through a stable owning check
  (`release.workflow_integrity`) — never as a bare, uninformative ID. Also proves the
  scanner's additive ROSTER/DONE stdout protocol and its self-checking
  `release.scanner.roster_exact` guard.

  Runs `async: false` — this module mutates process environment
  (`RELEASE_PLEASE_MANIFEST_PATH`) to drive real scanner subprocess runs.
  """

  use ExUnit.Case, async: false

  @scanner "script/check_release_workflow_integrity.exs"
  @manifest_path ".release-please-manifest.json"
  @line_regex ~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/

  describe "Task 1: one failing scanner check's own sentence reaches mix crosswake.release.status" do
    test "a drifted manifest surfaces the failing check's verbatim detail through build/1 and render/1" do
      {fail_id, detail} = run_drifted_scanner_and_capture_fail()

      assert detail != "", "expected the FAIL line to carry a non-empty detail"

      assert String.length(detail) > String.length(fail_id),
             "expected the detail to be more than the bare ID (got #{inspect(detail)})"

      status = Crosswake.ReleaseStatus.build(live?: false)

      owner_checks =
        Enum.filter(status.checks, &(&1.code == "release.workflow_integrity"))

      assert [check] = owner_checks,
             "expected exactly one release.workflow_integrity check, got #{length(owner_checks)}"

      assert check.status == :error
      assert check.message =~ fail_id
      assert check.message =~ detail

      rendered = Crosswake.ReleaseStatus.render(status)
      assert rendered =~ detail
    end

    test "a clean run reports release.workflow_integrity as :ok with no indented continuation" do
      status = Crosswake.ReleaseStatus.build(live?: false)

      assert %{status: :ok} = check = check!(status, "release.workflow_integrity")
      assert Map.get(check, :entries, []) == []

      rendered = Crosswake.ReleaseStatus.render(status)
      assert rendered =~ "- OK release.workflow_integrity:"
      refute rendered =~ ~r/^ {4}release\.\S+: /m
    end
  end

  describe "Task 1: scanner ROSTER/DONE stdout protocol" do
    test "a clean run emits exactly one ROSTER line and one DONE line with consistent counts" do
      {output, exit_code} = run_scanner()

      assert exit_code == 0, output

      lines = String.split(output, "\n", trim: true)

      roster_lines = Enum.filter(lines, &String.starts_with?(&1, "[crosswake] ROSTER: "))
      done_lines = Enum.filter(lines, &String.starts_with?(&1, "[crosswake] DONE: "))

      assert length(roster_lines) == 1, "expected exactly one ROSTER line, got #{inspect(roster_lines)}"
      assert length(done_lines) == 1, "expected exactly one DONE line, got #{inspect(done_lines)}"

      ok_fail_count =
        Enum.count(lines, fn line ->
          String.starts_with?(line, "[crosswake] OK: ") or
            String.starts_with?(line, "[crosswake] FAIL: ")
        end)

      [done_line] = done_lines
      [emitted_str, _of, _roster_count_str | _rest] = done_line |> String.trim_leading("[crosswake] DONE: ") |> String.split(" ")

      assert String.to_integer(emitted_str) == ok_fail_count
    end
  end

  # --- Task 1 helpers -------------------------------------------------------

  defp run_drifted_scanner_and_capture_fail do
    manifest = @manifest_path |> File.read!() |> JSON.decode!()
    drifted = Map.put(manifest, ".", "0.2.2")

    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase169-manifest-#{System.unique_integer([:positive])}.json"
      )

    File.write!(path, JSON.encode!(drifted))

    previous_env = System.get_env("RELEASE_PLEASE_MANIFEST_PATH")
    System.put_env("RELEASE_PLEASE_MANIFEST_PATH", path)

    on_exit(fn ->
      File.rm(path)

      case previous_env do
        nil -> System.delete_env("RELEASE_PLEASE_MANIFEST_PATH")
        value -> System.put_env("RELEASE_PLEASE_MANIFEST_PATH", value)
      end
    end)

    {output, exit_code} = run_scanner()
    assert exit_code == 1, "expected the drifted manifest to make the scanner exit 1:\n#{output}"

    fail_line =
      output
      |> String.split("\n", trim: true)
      |> Enum.find(&String.starts_with?(&1, "[crosswake] FAIL: "))

    refute is_nil(fail_line), "expected exactly one [crosswake] FAIL: line. Output:\n#{output}"

    [_full, "FAIL", id, detail] = Regex.run(@line_regex, fail_line)

    {id, detail}
  end

  defp run_scanner do
    System.cmd("elixir", [@scanner], stderr_to_stdout: true)
  end

  defp check!(status, code) do
    Enum.find(status.checks, &(&1.code == code)) || flunk("missing check #{code}")
  end
end
