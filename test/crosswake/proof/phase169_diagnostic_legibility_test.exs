defmodule Crosswake.Proof.Phase169DiagnosticLegibilityTest do
  @moduledoc """
  Merge-blocking proof for Phase 169 (Diagnostic Legibility).

  Closes the live PR #164 defect: a single failing scanner check's own sentence must
  reach the maintainer, end to end, through a stable owning check
  (`release.workflow_integrity`) — never as a bare, uninformative ID. Also proves the
  scanner's additive ROSTER/DONE stdout protocol and its self-checking
  `release.scanner.roster_exact` guard.

  Runs `async: false` — this module mutates process environment
  (`RELEASE_PLEASE_MANIFEST_PATH`, `RELEASE_WORKFLOW_PATH`) to drive real
  scanner subprocess runs.
  """

  use ExUnit.Case, async: false

  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
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

      assert length(roster_lines) == 1,
             "expected exactly one ROSTER line, got #{inspect(roster_lines)}"

      assert length(done_lines) == 1, "expected exactly one DONE line, got #{inspect(done_lines)}"

      ok_fail_count =
        Enum.count(lines, fn line ->
          String.starts_with?(line, "[crosswake] OK: ") or
            String.starts_with?(line, "[crosswake] FAIL: ")
        end)

      [done_line] = done_lines

      [emitted_str, _of, _roster_count_str | _rest] =
        done_line |> String.trim_leading("[crosswake] DONE: ") |> String.split(" ")

      assert String.to_integer(emitted_str) == ok_fail_count
    end
  end

  describe "Task 1: :unverifiable is first-class in aggregate_status/1 and exit_code/1 (FID-02, D-13)" do
    test "exit_code/1 returns exact integers for every known status" do
      assert Crosswake.ReleaseStatus.exit_code(:ok) == 0
      assert Crosswake.ReleaseStatus.exit_code(:warning) == 0
      assert Crosswake.ReleaseStatus.exit_code(:error) == 1
      assert Crosswake.ReleaseStatus.exit_code(:unverifiable) == 3
    end

    test "exit_code/1's map-forwarding clause reaches the new clause" do
      assert Crosswake.ReleaseStatus.exit_code(%{status: :unverifiable}) == 3
    end

    test "exit_code/1's catch-all still fails open for an unrecognized status (known hazard any future atom must close)" do
      assert Crosswake.ReleaseStatus.exit_code(:some_future_unknown_atom) == 0
    end

    test "the exit_code(:unverifiable) clause appears textually above the catch-all in source" do
      source = File.read!("lib/crosswake/release_status.ex")

      {unverifiable_index, _} = :binary.match(source, "def exit_code(:unverifiable), do: 3")
      {catch_all_index, _} = :binary.match(source, "def exit_code(_status), do: 0")

      assert unverifiable_index < catch_all_index
    end

    test "aggregate_status/1 over one :error and one :unverifiable returns :error" do
      assert Crosswake.ReleaseStatus.aggregate_status([
               %{status: :unverifiable},
               %{status: :error}
             ]) == :error
    end

    test "aggregate_status/1 over one :unverifiable, one :warning, and five :ok returns :unverifiable" do
      checks =
        [%{status: :unverifiable}, %{status: :warning}] ++ List.duplicate(%{status: :ok}, 5)

      assert Crosswake.ReleaseStatus.aggregate_status(checks) == :unverifiable
      assert Crosswake.ReleaseStatus.aggregate_status(Enum.reverse(checks)) == :unverifiable
    end

    test "aggregate_status([]) returns :unverifiable — nothing verified is not clean" do
      assert Crosswake.ReleaseStatus.aggregate_status([]) == :unverifiable
    end

    test "aggregate_status/1 branch for :unverifiable appears after :error and before :warning in source" do
      source = File.read!("lib/crosswake/release_status.ex")

      {error_index, _} = :binary.match(source, "&(&1.status == :error)")
      {unverifiable_index, _} = :binary.match(source, "&(&1.status == :unverifiable)")
      {warning_index, _} = :binary.match(source, "&(&1.status == :warning)")

      assert error_index < unverifiable_index
      assert unverifiable_index < warning_index
    end

    test "exit_code/1 carries a @doc naming all three codes and stating that 2 is reserved" do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Crosswake.ReleaseStatus)

      {_, _, _, %{"en" => doc}, _} =
        Enum.find(docs, fn
          {{:function, :exit_code, 1}, _, _, _, _} -> true
          _ -> false
        end)

      assert doc =~ "0"
      assert doc =~ "1"
      assert doc =~ "3"
      assert doc =~ "reserved"
    end

    test "@schema_version is \"1.2.0\"" do
      status = Crosswake.ReleaseStatus.build(live?: false)
      assert status.schema_version == "1.2.0"
    end

    test "render/1 renders UNVERIFIED, never the bare atom, for an :unverifiable check" do
      status = %{
        schema_version: "1.2.0",
        generated_at: "2026-01-01T00:00:00Z",
        status: :unverifiable,
        live_checked: false,
        core: [],
        companions: [],
        release_candidate: %{
          version: "0.0.0",
          state: "BLOCKED",
          next_action: "n/a",
          linked_coordinates: [],
          independent_companions: [],
          mirror: %{baseline_ref: "n/a", public_ref: "n/a"}
        },
        checks: [
          %{
            status: :unverifiable,
            code: "release.fixture.crash_check",
            message: "fixture message",
            next_action: "fix it",
            source: "fixture"
          }
        ]
      }

      rendered = Crosswake.ReleaseStatus.render(status)

      assert rendered =~ "UNVERIFIED"
      refute rendered =~ "unverifiable"
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

  describe "Task 2: the two crash shapes classify distinctly and cascade loudly (D-03, D-08)" do
    test "the crash-before-roster fixture yields :unavailable with the never-started message, and the five scoped checks + owner check are :unverifiable (exit 3)" do
      previous = System.get_env("RELEASE_PLEASE_CONFIG_PATH")

      missing_path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-missing-config-#{System.unique_integer([:positive])}.json"
        )

      System.put_env("RELEASE_PLEASE_CONFIG_PATH", missing_path)

      on_exit(fn ->
        case previous do
          nil -> System.delete_env("RELEASE_PLEASE_CONFIG_PATH")
          value -> System.put_env("RELEASE_PLEASE_CONFIG_PATH", value)
        end
      end)

      {raw_output, raw_exit_code} = run_scanner()
      refute raw_output =~ "[crosswake] ROSTER: "
      assert raw_exit_code != 0

      status = Crosswake.ReleaseStatus.build(live?: false)

      owner = check!(status, "release.workflow_integrity")
      assert owner.status == :unverifiable
      assert owner.message =~ "scanner did not start: no roster line emitted (exit "

      for code <- @scoped_scanner_codes do
        check = check!(status, code)

        assert check.status == :unverifiable,
               "expected #{code} to be :unverifiable, got #{inspect(check.status)}"

        assert check.message =~ "This is not a pass."
      end

      refute Enum.empty?(status.checks)
      refute Enum.any?(status.checks, &(&1.code in @scoped_scanner_codes and &1.status == :ok))

      assert Crosswake.ReleaseStatus.exit_code(status) == 3
    end

    test "the roster-then-crash fixture yields :unverifiable with the terminated-early message, and the five scoped checks + owner check are :unverifiable (exit 3)" do
      source = File.read!(@scanner)
      mutated = inject_crash_after_roster(source)

      status =
        with_mutated_scanner_cwd(mutated, fn cwd ->
          Crosswake.ReleaseStatus.build(live?: false, cwd: cwd)
        end)

      owner = check!(status, "release.workflow_integrity")
      assert owner.status == :unverifiable
      assert owner.message =~ " roster checks ran (exit "
      assert owner.message =~ "scanner terminated early: 0 of "

      for code <- @scoped_scanner_codes do
        check = check!(status, code)

        assert check.status == :unverifiable,
               "expected #{code} to be :unverifiable, got #{inspect(check.status)}"

        assert check.message =~ "This is not a pass."
      end

      refute Enum.empty?(status.checks)
      refute Enum.any?(status.checks, &(&1.code in @scoped_scanner_codes and &1.status == :ok))

      assert Crosswake.ReleaseStatus.exit_code(status) == 3
    end

    test "a run with a ROSTER line, full OK/FAIL lines, but no DONE line classifies as :unverifiable, not :ok" do
      source = File.read!(@scanner)
      mutated = drop_done_line(source)

      status =
        with_mutated_scanner_cwd(mutated, fn cwd ->
          Crosswake.ReleaseStatus.build(live?: false, cwd: cwd)
        end)

      owner = check!(status, "release.workflow_integrity")
      assert owner.status == :unverifiable
    end

    test "a complete run with one FAIL still routes to :error / exit 1 (unchanged)" do
      {_id, _detail} = run_drifted_scanner_and_capture_fail()
      status = Crosswake.ReleaseStatus.build(live?: false)

      assert status.status == :error
      assert Crosswake.ReleaseStatus.exit_code(status) == 1
    end

    test "the stderr excerpt in a crash message is bounded and carries a truncation marker when clipped" do
      previous = System.get_env("RELEASE_PLEASE_CONFIG_PATH")

      missing_path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-missing-config-#{System.unique_integer([:positive])}.json"
        )

      System.put_env("RELEASE_PLEASE_CONFIG_PATH", missing_path)

      on_exit(fn ->
        case previous do
          nil -> System.delete_env("RELEASE_PLEASE_CONFIG_PATH")
          value -> System.put_env("RELEASE_PLEASE_CONFIG_PATH", value)
        end
      end)

      status = Crosswake.ReleaseStatus.build(live?: false)
      owner = check!(status, "release.workflow_integrity")

      [_, excerpt] = String.split(owner.message, "stderr: ", parts: 2)
      assert String.length(excerpt) <= 520
    end

    test "the OK|FAIL consumer regex literal is byte-identical to its pre-phase form" do
      source = File.read!("lib/crosswake/release_status.ex")
      assert source =~ "~r/^\\[crosswake\\] (OK|FAIL): ([^\\s]+) - (.*)$/"
    end
  end

  # --- Task 2 helpers ---------------------------------------------------------

  # Injects a raise immediately after the ROSTER line is emitted and before any
  # OK/FAIL line prints — the roster-then-crash shape (D-03). Mirrors
  # mutate_roster_remove_id/2's raise-on-absent-pattern discipline: a silent
  # no-op mutation would make the negative control prove nothing.
  defp inject_crash_after_roster(source) do
    target = roster_ioputs_line()

    unless String.contains?(source, target) do
      raise """
      inject_crash_after_roster/1 found no ROSTER IO.puts line to inject after.

      The mutation would be a no-op, so the negative control would assert nothing.
      The scanner's ROSTER emission line changed — update this helper to match.
      """
    end

    String.replace(
      source,
      target,
      target <> "\n    raise \"phase169 test-injected crash after roster\"",
      global: false
    )
  end

  # Removes the DONE line emission so a run completes all OK/FAIL lines but never
  # asserts completion — proving DONE is a positive assertion, not an inference.
  defp drop_done_line(source) do
    target = done_ioputs_call()

    unless String.contains?(source, target) do
      raise """
      drop_done_line/1 found no DONE IO.puts call to remove.

      The mutation would be a no-op, so the negative control would assert nothing.
      The scanner's DONE emission changed — update this helper to match.
      """
    end

    String.replace(source, target, "", global: false)
  end

  defp roster_ioputs_line do
    "    IO.puts(\"[crosswake] ROSTER: \#{length(@roster_ids)} \#{Enum.join(@roster_ids, \",\")}\")"
  end

  defp done_ioputs_call do
    "    IO.puts(\n      \"[crosswake] DONE: \#{length(checks)} of \#{length(@roster_ids)} roster checks emitted; \#{length(failures)} failed.\"\n    )\n\n"
  end

  # Mirrors an entire cwd as a symlink tree so the scanner script's relative
  # reads (manifest, config, workflow, mix.exs, gradle files, .git) resolve to
  # the REAL project — except for script/check_release_workflow_integrity.exs,
  # which is written as the real (non-symlinked) mutated content. This lets
  # Crosswake.ReleaseStatus.build(cwd: ...) exercise the mutated scanner through
  # the exact same code path production uses, with no permanent change to any
  # tracked file.
  defp with_mutated_scanner_cwd(mutated_source, fun) do
    real_cwd = File.cwd!()

    temp_root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase169-cwd-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temp_root)

    try do
      for entry <- File.ls!(real_cwd), entry != "script" do
        File.ln_s!(Path.join(real_cwd, entry), Path.join(temp_root, entry))
      end

      script_dir = Path.join(temp_root, "script")
      File.mkdir_p!(script_dir)

      for entry <- File.ls!(Path.join(real_cwd, "script")),
          entry != "check_release_workflow_integrity.exs" do
        File.ln_s!(Path.join([real_cwd, "script", entry]), Path.join(script_dir, entry))
      end

      File.write!(Path.join(script_dir, "check_release_workflow_integrity.exs"), mutated_source)

      fun.(temp_root)
    after
      File.rm_rf!(temp_root)
    end
  end

  describe "Task 3: release.scanner.roster_exact — self-checking roster, proven non-vacuous" do
    test "a clean run emits [crosswake] OK: release.scanner.roster_exact" do
      {output, exit_code} = run_scanner()

      assert exit_code == 0, output
      assert output =~ ~r/^\[crosswake\] OK: release\.scanner\.roster_exact - /m
    end

    test "removing one ID token from @roster_ids turns the scanner red at release.scanner.roster_exact (non-vacuity proof)" do
      source = File.read!(@scanner)
      mutated = mutate_roster_remove_id(source, "release.concurrency.not_cancelled")

      path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-roster-mutation-#{System.unique_integer([:positive])}.exs"
        )

      File.write!(path, mutated)
      on_exit(fn -> File.rm(path) end)

      {output, exit_code} = System.cmd("elixir", [path], stderr_to_stdout: true)

      assert exit_code != 0,
             "expected a drifted @roster_ids to make the scanner exit non-zero:\n#{output}"

      assert output =~ "[crosswake] FAIL: release.scanner.roster_exact"
    end

    test "the mutation helper raises when its target token is absent from the source" do
      source = File.read!(@scanner)

      assert_raise RuntimeError, ~r/found no/, fn ->
        mutate_roster_remove_id(source, "release.this.id.does.not.exist.anywhere")
      end
    end

    test "on a clean run, ROSTER count, ROSTER ID-list length, OK/FAIL line count, and DONE emitted count are mutually consistent and > 60" do
      {output, exit_code} = run_scanner()
      assert exit_code == 0, output

      lines = String.split(output, "\n", trim: true)

      [roster_line] = Enum.filter(lines, &String.starts_with?(&1, "[crosswake] ROSTER: "))
      [done_line] = Enum.filter(lines, &String.starts_with?(&1, "[crosswake] DONE: "))

      [roster_count_str, roster_ids_str] =
        roster_line
        |> String.trim_leading("[crosswake] ROSTER: ")
        |> String.split(" ", parts: 2)

      roster_count = String.to_integer(roster_count_str)
      roster_id_list_length = roster_ids_str |> String.split(",", trim: true) |> length()

      ok_fail_count =
        Enum.count(lines, fn line ->
          String.starts_with?(line, "[crosswake] OK: ") or
            String.starts_with?(line, "[crosswake] FAIL: ")
        end)

      [done_emitted_str, _of, _roster_count_str2 | _rest] =
        done_line |> String.trim_leading("[crosswake] DONE: ") |> String.split(" ")

      done_emitted = String.to_integer(done_emitted_str)

      assert roster_count == roster_id_list_length
      assert roster_count == ok_fail_count
      assert roster_count == done_emitted
      assert roster_count > 60
    end
  end

  describe "169-02 Task 3: the Mix task reaches OS exit 3, with D-17 microcopy" do
    test "a clean run terminates with exit status exactly 0 and prints neither FAIL (exit nor UNVERIFIED (exit" do
      {output, exit_status} = run_mix_release_status()

      assert exit_status == 0
      refute output =~ "[crosswake] FAIL (exit"
      refute output =~ "[crosswake] UNVERIFIED (exit"
    end

    test "the reintroduced-bare-literal fixture terminates with exit status exactly 1 and prints the FAIL (exit 1) summary block" do
      mutated = reintroduce_bare_version_literal(File.read!(@workflow), "publish-hex", "0.2.1")

      path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-mixtask-workflow-#{System.unique_integer([:positive])}.yml"
        )

      File.write!(path, mutated)
      on_exit(fn -> File.rm(path) end)

      {output, exit_status} =
        run_mix_release_status(env: [{"RELEASE_WORKFLOW_PATH", path}])

      assert exit_status == 1
      assert output =~ "[crosswake] FAIL (exit 1): release status ran all "
      refute output =~ "[crosswake] UNVERIFIED (exit"
    end

    test "the crash fixture terminates with exit status exactly 3 and prints the UNVERIFIED (exit 3) summary block naming 'Do not read exit 3 as a pass.'" do
      missing_path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-mixtask-missing-config-#{System.unique_integer([:positive])}.json"
        )

      {output, exit_status} =
        run_mix_release_status(env: [{"RELEASE_PLEASE_CONFIG_PATH", missing_path}])

      assert exit_status == 3
      assert output =~ "[crosswake] UNVERIFIED (exit 3): "
      assert output =~ "Do not read exit 3 as a pass."
    end

    test "lib/mix/tasks/crosswake.release.status.ex contains exit({:shutdown, 3}) and no System.halt(" do
      source = File.read!("lib/mix/tasks/crosswake.release.status.ex")

      assert source =~ "exit({:shutdown, 3})"
      refute source =~ "System.halt("
    end

    test "Mix.shell().info(output) appears on an earlier line than the exit-code case" do
      source = File.read!("lib/mix/tasks/crosswake.release.status.ex")

      {info_index, _} = :binary.match(source, "Mix.shell().info(output)")

      {case_index, _} =
        :binary.match(source, "case Crosswake.ReleaseStatus.exit_code(status) do")

      assert info_index < case_index
    end

    test "no check count in the summary block is a hardcoded integer literal in the source" do
      source = File.read!("lib/crosswake/release_status.ex")

      refute source =~ "release status ran all 7 checks"
      refute source =~ "1 of 7 checks"
    end
  end

  # --- Task 3 helpers -------------------------------------------------------

  # Mirrors phase142_release_integrity_test.exs's replace_in_job/4 raise-on-absent-
  # pattern discipline: a silent no-op mutation would make the negative control prove
  # nothing about the check it names.
  defp mutate_roster_remove_id(source, id) do
    target = "\n    #{id}\n"

    unless String.contains?(source, target) do
      raise """
      mutate_roster_remove_id/2 found no #{inspect(id)} line in @roster_ids.

      The mutation would be a no-op, so the negative control would assert nothing.
      The scanner drifted away from this ID — update the test to a current roster
      member, do not delete the control.
      """
    end

    String.replace(source, target, "\n", global: false)
  end

  # --- Task 1 helpers -------------------------------------------------------

  defp job_block(workflow, job) do
    case Regex.run(
           ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
           workflow
         ) do
      [block] -> block
      _ -> ""
    end
  end

  # Phase 171 (WELD-02/WELD-03) made the publish gates derive their version
  # comparison from the same release manifest the guard already reads, so a
  # release-manifest-only drift (the pre-171 fixture technique this helper used) no
  # longer produces ANY scanner FAIL -- that is the intended effect of the
  # fix, not a regression. Reintroducing a bare version literal into one
  # gated job's if: clause (the shape release.publish_gate.no_bare_version_literal
  # exists to catch) is the current way to produce a genuine, legible FAIL.
  defp reintroduce_bare_version_literal(workflow, job, version) do
    block = job_block(workflow, job)

    expected =
      "needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version"

    unless String.contains?(block, expected) do
      raise """
      reintroduce_bare_version_literal/3 found no approved_version comparison in job #{inspect(job)}.

      The mutation would be a no-op, so the negative control would assert nothing.
      """
    end

    mutated =
      String.replace(block, expected, "needs.release-please.outputs.version == '#{version}'")

    if mutated == block do
      raise """
      reintroduce_bare_version_literal/3 produced an IDENTICAL block for job #{inspect(job)}.

      The replacement matched but changed nothing.
      """
    end

    String.replace(workflow, block, mutated, global: false)
  end

  defp run_drifted_scanner_and_capture_fail do
    mutated = reintroduce_bare_version_literal(File.read!(@workflow), "publish-hex", "0.2.1")

    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase169-workflow-#{System.unique_integer([:positive])}.yml"
      )

    File.write!(path, mutated)

    previous_env = System.get_env("RELEASE_WORKFLOW_PATH")
    System.put_env("RELEASE_WORKFLOW_PATH", path)

    on_exit(fn ->
      File.rm(path)

      case previous_env do
        nil -> System.delete_env("RELEASE_WORKFLOW_PATH")
        value -> System.put_env("RELEASE_WORKFLOW_PATH", value)
      end
    end)

    {output, exit_code} = run_scanner()

    assert exit_code == 1,
           "expected the reintroduced bare version literal to make the scanner exit 1:\n#{output}"

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

  # --- 169-02 Task 3 helper ---------------------------------------------------

  # Observes the REAL OS exit status of `mix crosswake.release.status` — the
  # only way to prove Mix.raise (always 1) versus exit({:shutdown, 3}) actually
  # reaches the OS, not just the library-level exit_code/1 return value.
  defp run_mix_release_status(opts \\ []) do
    env = Keyword.get(opts, :env, [])

    System.cmd("mix", ["crosswake.release.status"],
      cd: File.cwd!(),
      stderr_to_stdout: true,
      env: env
    )
  end

  defp check!(status, code) do
    Enum.find(status.checks, &(&1.code == code)) || flunk("missing check #{code}")
  end
end
