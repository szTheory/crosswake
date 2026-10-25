defmodule Crosswake.BearingsReportTest do
  @moduledoc """
  `script/bearings_report.exs` over injected runners and real captured gh/git output
  (`test/fixtures/bearings`, made by the phase 194 capture script). No test calls live
  `gh`, `git` or the network. Each check has a positive case and a negative control that
  asserts the specific line text, so a report that failed for another reason cannot pass.
  """
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @launcher Path.join(@repo_root, "script/bearings-report")

  @fetch {"git", ["fetch", "origin", "main"]}
  @jq "[.[] | {number: .number, merged_at: .merged_at, head_sha: .head.sha}]"
  @run_fields "databaseId,headSha,status,conclusion,event"

  setup_all do
    Process.put(:crosswake_bearings_report_library, true)

    unless Code.ensure_loaded?(Crosswake.BearingsReport) do
      Code.require_file(Path.join(@repo_root, "script/bearings_report.exs"))
    end

    :ok
  end

  defp fixture!(name), do: File.read!(Path.join([@repo_root, "test/fixtures/bearings", name]))

  defp main_sha, do: String.trim(fixture!("git-rev-parse-origin-main.txt"))
  defp head_sha, do: String.trim(fixture!("git-rev-parse-head.txt"))
  defp pr_head, do: hd(JSON.decode!(fixture!("gh-commit-pulls.json")))["head_sha"]

  defp pulls_key,
    do: {"gh", ["api", "repos/szTheory/crosswake/commits/#{main_sha()}/pulls", "--jq", @jq]}

  defp runs_key(sha) do
    {"gh",
     [
       "run",
       "list",
       "--workflow",
       "Crosswake CI",
       "--commit",
       sha,
       "--limit",
       "20",
       "--json",
       @run_fields
     ]}
  end

  # Unmapped keys return an error, so a test that forgets a key turns UNVERIFIED, never OK.
  defp fake_runner(map) do
    fn cmd, args -> Map.get(map, {cmd, args}, {:error, :unmapped}) end
  end

  defp base_map do
    %{
      @fetch => {:ok, ""},
      {"git", ["rev-parse", "origin/main"]} => {:ok, fixture!("git-rev-parse-origin-main.txt")},
      {"git", ["rev-parse", "HEAD"]} => {:ok, fixture!("git-rev-parse-head.txt")},
      {"gh", ["repo", "view", "--json", "nameWithOwner"]} => {:ok, fixture!("gh-repo-view.json")},
      pulls_key() => {:ok, fixture!("gh-commit-pulls.json")},
      runs_key(pr_head()) => {:ok, fixture!("gh-run-list-pr-head.json")},
      runs_key(head_sha()) => {:ok, fixture!("gh-run-list-pr-head.json")}
    }
  end

  defp deps(map) do
    %{
      run: fake_runner(map),
      read: fn _ -> {:error, :enoent} end,
      list: fn _ -> [] end,
      now: ~U[2026-10-25 12:00:00Z]
    }
  end

  # Late-bound: the module is loaded from the script in setup_all, so avoid a compile-time warning.
  defp report(map, opts \\ []), do: apply(module(), :run, [opts, deps(map)])

  defp module, do: Crosswake.BearingsReport

  defp short(sha), do: String.slice(sha, 0, 7)

  describe "CI check over real captured fixtures" do
    test "names the PR head CI ran on and says main is its merge commit" do
      {code, [verdict | _] = lines} = report(base_map())

      expected =
        "ci: success on #{short(pr_head())} (PR #247 head; main #{short(main_sha())} " <>
          "is its merge commit, tested only as a synthetic merge)"

      assert expected in lines
      assert verdict =~ ~r/^BEARINGS: (OK|ATTENTION \(\d+\)|UNVERIFIED \(\d+ reads failed\))$/
      assert code in [0, 1, 2]
    end

    test "the launcher answers --help without any git or gh call" do
      assert {out, 0} = System.cmd(@launcher, ["--help"], stderr_to_stdout: true)
      assert out =~ "usage: script/bearings-report"
    end
  end
end
