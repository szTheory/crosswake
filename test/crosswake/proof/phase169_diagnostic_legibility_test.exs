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

  # The five pre-existing scoped scanner_check/7 call sites (D-07) — unaffected by
  # the always-emitted release.workflow_integrity owner check.
  @scoped_scanner_codes ~w(
    release.workflow_path_gates
    release.cleanroom_dependency_floor
    release.governance_queue_max
    release.governance_behavioral_identity_gates
    release.governance_cleanup_after_proof
  )

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

  describe "Task 2: scope the five call sites to their own gates and compose every non-empty bucket" do
    test "a foreign check failing leaves the five scoped checks green and surfaces once via the owner check" do
      baseline = Crosswake.ReleaseStatus.build()

      all_scanner_ids =
        baseline.checks
        |> Enum.filter(&(&1.source == "script/check_release_workflow_integrity.exs"))
        |> Enum.flat_map(& &1.evidence)
        |> Enum.uniq()

      checks =
        all_scanner_ids
        |> Map.new(&{&1, %{status: :ok, detail: "fixture ok", order: 0}})
        |> Map.put("release.foreign.regression", %{
          status: :error,
          detail: "fixture foreign failure",
          order: 999
        })

      status =
        Crosswake.ReleaseStatus.build(
          workflow_integrity: %{
            status: :failed,
            checks: checks,
            message: "scanner reported release workflow drift"
          }
        )

      for code <- @scoped_scanner_codes do
        assert %{status: :ok} = check!(status, code)
      end

      assert %{status: :error, message: message, evidence: evidence} =
               check!(status, "release.workflow_integrity")

      assert "release.foreign.regression" in evidence
      assert message =~ "release.foreign.regression"
      assert message =~ "fixture foreign failure"
    end

    test "one of a caller's own required IDs failing surfaces that caller's check with the verbatim detail" do
      baseline = Crosswake.ReleaseStatus.build()
      required_ids = check!(baseline, "release.workflow_path_gates").evidence
      [own_id | _] = required_ids

      checks =
        required_ids
        |> Map.new(&{&1, %{status: :ok, detail: "fixture ok", order: 0}})
        |> Map.put(own_id, %{status: :error, detail: "fixture own failure detail", order: 0})

      status =
        Crosswake.ReleaseStatus.build(
          workflow_integrity: %{
            status: :failed,
            checks: checks,
            message: "scanner reported release workflow drift"
          }
        )

      assert %{status: :error, message: message} = check!(status, "release.workflow_path_gates")
      assert message =~ own_id
      assert message =~ "fixture own failure detail"
    end

    test "a simultaneous own-failing and required-missing state names failing first and never shadows missing" do
      baseline = Crosswake.ReleaseStatus.build()
      required_ids = check!(baseline, "release.workflow_path_gates").evidence
      [failing_id, missing_id | _] = required_ids

      checks =
        required_ids
        |> Enum.reject(&(&1 == missing_id))
        |> Map.new(&{&1, %{status: :ok, detail: "fixture ok", order: 0}})
        |> Map.put(failing_id, %{status: :error, detail: "fixture failing detail", order: 0})

      status =
        Crosswake.ReleaseStatus.build(
          workflow_integrity: %{
            status: :failed,
            checks: checks,
            message: "scanner reported release workflow drift",
            roster_size: 69
          }
        )

      assert %{status: :error, message: message} = check!(status, "release.workflow_path_gates")

      assert [failing_part, missing_part] = String.split(message, "; ", parts: 2)
      assert failing_part =~ "failing"
      assert failing_part =~ failing_id
      assert missing_part =~ "never defined"
      assert missing_part =~ missing_id
      assert missing_part =~ "not in the scanner's "
      assert missing_part =~ "script/check_release_workflow_integrity.exs"
    end

    test "a missing required ID explains the absence rather than presenting it as an unexplained new problem" do
      baseline = Crosswake.ReleaseStatus.build()
      required_ids = check!(baseline, "release.workflow_path_gates").evidence
      [missing_id | rest_ids] = required_ids

      checks = Map.new(rest_ids, &{&1, %{status: :ok, detail: "fixture ok", order: 0}})

      status =
        Crosswake.ReleaseStatus.build(
          workflow_integrity: %{
            status: :failed,
            checks: checks,
            message: "scanner reported release workflow drift",
            roster_size: 69
          }
        )

      assert %{status: :error, message: message} = check!(status, "release.workflow_path_gates")
      assert message =~ "never defined by scanner: #{missing_id}"
      assert message =~ "not in the scanner's 69-check roster"
      assert message =~ "script/check_release_workflow_integrity.exs"
    end

    test "two of a caller's own required IDs failing are both named, ordered by scanner emission order, stably" do
      baseline = Crosswake.ReleaseStatus.build()
      required_ids = check!(baseline, "release.workflow_path_gates").evidence
      [id_a, id_b | rest_ids] = required_ids

      checks =
        rest_ids
        |> Map.new(&{&1, %{status: :ok, detail: "fixture ok", order: 0}})
        |> Map.put(id_a, %{status: :error, detail: "detail A", order: 5})
        |> Map.put(id_b, %{status: :error, detail: "detail B", order: 2})

      build_fn = fn ->
        Crosswake.ReleaseStatus.build(
          workflow_integrity: %{
            status: :failed,
            checks: checks,
            message: "scanner reported release workflow drift"
          }
        )
      end

      status = build_fn.()

      assert %{status: :error, message: message} = check!(status, "release.workflow_path_gates")
      assert message =~ "#{id_b}: detail B"
      assert message =~ "#{id_a}: detail A"

      {b_index, _} = :binary.match(message, id_b)
      {a_index, _} = :binary.match(message, id_a)
      assert b_index < a_index, "expected order:2 (#{id_b}) before order:5 (#{id_a})"

      status2 = build_fn.()
      assert check!(status2, "release.workflow_path_gates").message == message
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
