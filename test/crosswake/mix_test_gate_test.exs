defmodule Crosswake.MixTestGateTest do
  @moduledoc """
  `script/mix_test_gate.sh` over a PATH-first `mix` stub. Each verdict has a case that asserts
  the exact `verdict=` and `reason=` tokens and that the `--out` file ends with the same gate
  line, so a gate that failed for another reason cannot pass. The summary line in the first
  case is copied from real ExUnit output (the Task 1 run of `docs_report_test.exs`).
  """
  use ExUnit.Case, async: true

  @script Path.expand("../../script/mix_test_gate.sh", __DIR__)
  @usage "mix-test-gate: usage script/mix_test_gate.sh --out FILE [--min N] [--min-total N] [--] [mix test args...]"

  # Writes a `mix` stub that prints `body` and exits `code`, and drops a marker when invoked.
  defp stub!(tmp, body, code) do
    bin = Path.join(tmp, "bin")
    File.mkdir_p!(bin)
    File.write!(Path.join(tmp, "body.txt"), body)
    marker = Path.join(tmp, "mix-was-run")

    File.write!(Path.join(bin, "mix"), """
    #!/bin/sh
    touch "#{marker}"
    cat "#{Path.join(tmp, "body.txt")}"
    exit #{code}
    """)

    File.chmod!(Path.join(bin, "mix"), 0o755)
    {bin, marker}
  end

  defp gate(tmp, body, code, args \\ []) do
    {bin, marker} = stub!(tmp, body, code)
    out = Path.join(tmp, "gate-out.txt")

    {stdout, status} =
      System.cmd("bash", [@script, "--out", out] ++ args ++ ["--", "test/some_test.exs"],
        env: [{"PATH", bin <> ":" <> System.get_env("PATH")}],
        stderr_to_stdout: true
      )

    %{stdout: String.trim(stdout), status: status, out: out, marker: marker}
  end

  defp last_line(path),
    do: path |> File.read!() |> String.trim_trailing() |> String.split("\n") |> List.last()

  defp assert_verdict(result, status, tokens) do
    assert result.status == status, result.stdout

    for token <- tokens do
      assert result.stdout =~ token, result.stdout
    end

    assert last_line(result.out) == result.stdout
    assert File.exists?(result.marker)
  end

  @tag :tmp_dir
  test "PASS on a real ExUnit summary with the run counted", %{tmp_dir: tmp} do
    body = "Finished in 0.8 seconds (0.8s async, 0.00s sync)\n19 tests, 0 failures\n"
    result = gate(tmp, body, 0)
    assert_verdict(result, 0, ["rc=0", "ran=19", "failures=0", "verdict=PASS"])
    refute result.stdout =~ "reason="
  end

  @tag :tmp_dir
  test "zero tests that ran is below_min", %{tmp_dir: tmp} do
    result = gate(tmp, "0 tests, 0 failures\n", 0)
    assert_verdict(result, 1, ["ran=0", "verdict=FAIL", "reason=below_min"])
  end

  @tag :tmp_dir
  test "failing tests with a failing exit status is mix_rc", %{tmp_dir: tmp} do
    result = gate(tmp, "14 tests, 1 failure\n", 2)
    assert_verdict(result, 1, ["rc=2", "failures=1", "verdict=FAIL", "reason=mix_rc"])
  end

  @tag :tmp_dir
  test "failures in the summary fail even when mix exited 0", %{tmp_dir: tmp} do
    result = gate(tmp, "14 tests, 1 failure\n", 0)
    assert_verdict(result, 1, ["rc=0", "failures=1", "verdict=FAIL", "reason=failures"])
  end

  @tag :tmp_dir
  test "a clean summary with a nonzero exit status is mix_rc", %{tmp_dir: tmp} do
    result = gate(tmp, "14 tests, 0 failures\n", 1)
    assert_verdict(result, 1, ["rc=1", "failures=0", "verdict=FAIL", "reason=mix_rc"])
  end

  @tag :tmp_dir
  test "a compile error with no summary is no_summary", %{tmp_dir: tmp} do
    body = "** (CompileError) test/some_test.exs:1: undefined function foo/0\n"
    result = gate(tmp, body, 0)
    assert_verdict(result, 1, ["total=-", "ran=-", "verdict=FAIL", "reason=no_summary"])
  end

  @tag :tmp_dir
  test "an invalid test is reason=invalid", %{tmp_dir: tmp} do
    result = gate(tmp, "1 test, 0 failures, 1 invalid\n", 0)
    assert_verdict(result, 1, ["invalid=1", "verdict=FAIL", "reason=invalid"])
  end

  @tag :tmp_dir
  test "doctests count toward the ran floor", %{tmp_dir: tmp} do
    body = "3 doctests, 14 tests, 0 failures\n"

    result = gate(tmp, body, 0, ["--min", "17"])
    assert_verdict(result, 0, ["total=17", "ran=17", "min=17", "verdict=PASS"])

    result = gate(tmp, body, 0, ["--min", "18"])
    assert_verdict(result, 1, ["ran=17", "min=18", "verdict=FAIL", "reason=below_min"])
  end

  @tag :tmp_dir
  test "excluded tests do not count as run", %{tmp_dir: tmp} do
    result = gate(tmp, "14 tests, 0 failures (14 excluded)\n", 0)
    assert_verdict(result, 1, ["total=14", "excluded=14", "ran=0", "reason=below_min"])
  end

  @tag :tmp_dir
  test "--min-total grades the total including excluded tests", %{tmp_dir: tmp} do
    body = "2923 tests, 0 failures (79 excluded)\n"

    result = gate(tmp, body, 0, ["--min-total", "2923"])
    assert_verdict(result, 0, ["total=2923", "excluded=79", "ran=2844", "verdict=PASS"])

    result = gate(tmp, body, 0, ["--min-total", "2924"])
    assert_verdict(result, 1, ["min_total=2924", "verdict=FAIL", "reason=below_min_total"])
  end

  @tag :tmp_dir
  test "a stale PASS line in the out file is removed before the run", %{tmp_dir: tmp} do
    out = Path.join(tmp, "gate-out.txt")
    stale = "mix-test-gate: rc=0 total=9 verdict=PASS\n"
    File.write!(out, stale)
    assert File.read!(out) =~ "verdict=PASS"

    result = gate(tmp, "", 0)
    assert_verdict(result, 1, ["verdict=FAIL", "reason=no_summary"])
    refute File.read!(out) =~ "verdict=PASS"
  end

  @tag :tmp_dir
  test "usage errors exit 2 with the usage line and run no mix", %{tmp_dir: tmp} do
    {bin, marker} = stub!(tmp, "19 tests, 0 failures\n", 0)
    env = [{"PATH", bin <> ":" <> System.get_env("PATH")}]
    out = Path.join(tmp, "gate-out.txt")

    cases = [
      ["--", "test/some_test.exs"],
      ["--out", out, "--min", "abc", "--", "test/some_test.exs"],
      ["--out", out, "--min", "0", "--", "test/some_test.exs"],
      ["--out", out, "--min-total", "-1", "--", "test/some_test.exs"]
    ]

    results =
      for args <- cases do
        System.cmd("bash", [@script | args], env: env, stderr_to_stdout: true)
      end

    assert length(results) == 4

    for {stdout, status} <- results do
      assert status == 2
      assert String.trim(stdout) == @usage
    end

    refute File.exists?(marker)
  end

  # The no-pipe rule: the line that runs `mix test` must not carry a pipe.
  defp piped_mix_test_lines(source) do
    source
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^\s*mix test\b/, &1))
    |> Enum.filter(&String.contains?(&1, "|"))
  end

  test "the line that runs mix test has no pipe, and the check would catch one" do
    source = File.read!(@script)
    invocations = Regex.scan(~r/^\s*mix test\b.*$/m, source)
    assert length(invocations) == 1
    assert piped_mix_test_lines(source) == []

    piped = String.replace(source, ~s(mix test "$@" >"$OUT"), ~s(mix test "$@" | tee "$OUT"))
    assert piped != source
    assert length(piped_mix_test_lines(piped)) == 1
  end
end
