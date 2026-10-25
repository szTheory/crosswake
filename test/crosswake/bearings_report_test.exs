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

  @rev_list_key {"git", ["rev-list", "--left-right", "--count", "HEAD...origin/main"]}
  @pr_key {"gh",
           [
             "pr",
             "list",
             "--state",
             "open",
             "--limit",
             "100",
             "--json",
             "number,headRefName,createdAt,isDraft"
           ]}
  @wt_key {"git", ["worktree", "list", "--porcelain"]}
  @stash_key {"git", ["stash", "list"]}
  @unlanded_key {"git", ["branch", "--no-merged", "origin/main", "--format=%(refname:short)"]}

  # Real captured fixtures for every read (the checkout's real unlanded branches and old PRs
  # make this map ATTENTION; exact-output tests use it as is).
  defp fixture_map do
    Map.merge(ci_map(), %{
      @rev_list_key => {:ok, fixture!("git-rev-list-count.txt")},
      @pr_key => {:ok, fixture!("gh-pr-list.json")},
      @wt_key => {:ok, fixture!("git-worktree-porcelain.txt")},
      @stash_key => {:ok, fixture!("git-stash-list.txt")},
      @unlanded_key => {:ok, fixture!("git-branch-no-merged.txt")}
    })
  end

  # Clean state for the sync, PR and local reads so CI tests keep a single cause.
  defp base_map do
    Map.merge(fixture_map(), %{
      @rev_list_key => {:ok, "0\t0\n"},
      @pr_key => {:ok, "[]"},
      @stash_key => {:ok, ""},
      @unlanded_key => {:ok, ""}
    })
  end

  defp ci_map do
    %{
      @fetch => {:ok, ""},
      {"git", ["rev-parse", "origin/main"]} => {:ok, fixture!("git-rev-parse-origin-main.txt")},
      {"git", ["rev-parse", "HEAD"]} => {:ok, fixture!("git-rev-parse-head.txt")},
      {"gh", ["repo", "view", "--json", "nameWithOwner"]} => {:ok, fixture!("gh-repo-view.json")},
      pulls_key() => {:ok, fixture!("gh-commit-pulls.json")},
      runs_key(pr_head()) => {:ok, fixture!("gh-run-list-pr-head.json")},
      runs_key(head_sha()) => {:ok, JSON.encode!([run_of(head_sha())])}
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
      assert code == 0
      assert verdict == "BEARINGS: OK"
    end

    test "the launcher answers --help without any git or gh call" do
      assert {out, 0} = System.cmd(@launcher, ["--help"], stderr_to_stdout: true)
      assert out =~ "usage: script/bearings-report"
    end
  end

  defp put_runs(map, sha, runs), do: Map.put(map, runs_key(sha), {:ok, JSON.encode!(runs)})

  defp run_of(sha, overrides \\ %{}) do
    Map.merge(
      %{
        "databaseId" => 1,
        "headSha" => sha,
        "status" => "completed",
        "conclusion" => "success",
        "event" => "pull_request"
      },
      overrides
    )
  end

  describe "CI negative controls" do
    test "a gh error on the commit-pulls read is UNVERIFIED with a fixed reason" do
      map = Map.put(base_map(), pulls_key(), {:error, :exit_status})
      {code, [verdict | rest] = lines} = report(map)

      assert code == 2
      assert verdict == "BEARINGS: UNVERIFIED (1 reads failed)"
      assert "UNVERIFIED ci: could not read merged PR for main tip" in rest
      refute Enum.any?(lines, &(&1 =~ "exit_status"))
    end

    for {label, pulls} <- [
          zero: "[]",
          unmerged:
            ~s([{"number":9,"merged_at":null,"head_sha":"6fea7251f9d997e2db86608d37da933b1a805af7"}]),
          two:
            ~s([{"number":9,"merged_at":"2026-10-01T00:00:00Z","head_sha":"6fea7251f9d997e2db86608d37da933b1a805af7"},{"number":10,"merged_at":"2026-10-02T00:00:00Z","head_sha":"6fea7251f9d997e2db86608d37da933b1a805af7"}])
        ] do
      test "main tip with #{label} merged PRs is UNVERIFIED" do
        map = Map.put(base_map(), pulls_key(), {:ok, unquote(pulls)})
        {code, lines} = report(map)

        assert code == 2
        assert "UNVERIFIED ci: main tip has no single merged PR" in lines
      end
    end

    test "an empty run list for the PR head is UNVERIFIED, never a pass" do
      {code, lines} = report(put_runs(base_map(), pr_head(), []))

      assert code == 2
      assert "UNVERIFIED ci: no Crosswake CI run on the PR head" in lines
    end

    test "runs for a different commit than requested are UNVERIFIED" do
      other = String.duplicate("a", 40)
      {code, lines} = report(put_runs(base_map(), pr_head(), [run_of(other)]))

      assert code == 2
      assert "UNVERIFIED ci: run list did not return the requested commit" in lines
    end

    test "the newest run decides, and an in-progress run is PENDING attention" do
      runs = [
        run_of(pr_head(), %{"databaseId" => 5, "status" => "in_progress", "conclusion" => ""}),
        run_of(pr_head(), %{"databaseId" => 2})
      ]

      {code, [verdict | _] = lines} = report(put_runs(base_map(), pr_head(), runs))

      assert code == 1
      assert verdict =~ ~r/^BEARINGS: ATTENTION/
      assert Enum.any?(lines, &(&1 =~ "ci: PENDING on #{short(pr_head())}"))
    end

    test "a failed conclusion is attention, not OK" do
      runs = [run_of(pr_head(), %{"conclusion" => "failure"})]
      {code, lines} = report(put_runs(base_map(), pr_head(), runs))

      assert code == 1
      assert Enum.any?(lines, &(&1 =~ "ci: failure on #{short(pr_head())}"))
    end

    test "HEAD that is neither main nor the PR head with no run is caught" do
      {code, lines} = report(put_runs(base_map(), head_sha(), []))

      assert code == 1
      assert "ci: CI has not run on HEAD #{short(head_sha())}" in lines
    end

    test "HEAD equal to the main tip needs no separate run" do
      map = Map.put(base_map(), {"git", ["rev-parse", "HEAD"]}, {:ok, main_sha() <> "\n"})
      {_code, lines} = report(map)

      refute Enum.any?(lines, &(&1 =~ "HEAD"))
    end

    test "a failed fetch is UNVERIFIED and reads nothing else" do
      {code, lines} = report(%{@fetch => {:error, :exit_status}})

      assert code == 2
      assert "UNVERIFIED ci: origin/main not refreshed" in lines
    end

    test "unparseable gh output is UNVERIFIED" do
      map =
        Map.put(
          base_map(),
          {"gh", ["repo", "view", "--json", "nameWithOwner"]},
          {:ok, "not json"}
        )

      {code, lines} = report(map)

      assert code == 2
      assert "UNVERIFIED ci: unparseable gh output" in lines
    end

    test "a runner that always returns empty success never yields OK" do
      deps = %{deps(%{}) | run: fn _, _ -> {:ok, ""} end}
      {code, [verdict | _]} = apply(module(), :run, [[], deps])

      refute verdict == "BEARINGS: OK"
      assert code == 2
    end

    test "render with no lines is UNVERIFIED, never OK" do
      assert {2,
              [
                "BEARINGS: UNVERIFIED (1 reads failed)",
                "UNVERIFIED report: no checks produced output"
              ]} =
               apply(module(), :render, [[]])
    end
  end

  defp pr_json(entries) do
    JSON.encode!(
      for {n, branch, created} <- entries do
        %{"number" => n, "headRefName" => branch, "createdAt" => created, "isDraft" => false}
      end
    )
  end

  defp ago(seconds), do: DateTime.to_iso8601(DateTime.add(~U[2026-10-25 12:00:00Z], -seconds))

  describe "sync check" do
    test "0 and 0 is info" do
      {_code, lines} = report(base_map())
      assert "sync: ahead 0 behind 0" in lines
    end

    test "ahead is attention" do
      {code, lines} = report(Map.put(base_map(), @rev_list_key, {:ok, "2\t0\n"}))
      assert code == 1
      assert "sync: ahead 2 behind 0" in lines
    end

    test "behind is attention" do
      {code, lines} = report(Map.put(base_map(), @rev_list_key, {:ok, "0\t3\n"}))
      assert code == 1
      assert "sync: ahead 0 behind 3" in lines
    end

    test "garbage rev-list output is UNVERIFIED" do
      {code, lines} = report(Map.put(base_map(), @rev_list_key, {:ok, "garbage"}))
      assert code == 2
      assert "UNVERIFIED sync: unparseable rev-list count" in lines
    end

    test "a failed fetch is caught on both the sync and CI lines" do
      {code, lines} = report(Map.put(base_map(), @fetch, {:error, :exit_status}))
      assert code == 2
      assert "UNVERIFIED sync: fetch origin main failed" in lines
      assert "UNVERIFIED ci: origin/main not refreshed" in lines
    end
  end

  describe "open PR classes" do
    test "classifies the real fixture and lists stale PRs ascending" do
      {_code, lines} = report(Map.put(base_map(), @pr_key, {:ok, fixture!("gh-pr-list.json")}))
      assert "prs: open 7 (release-please 1, dependabot 5, feature 1)" in lines
      assert "prs: stale 2: #210 #211" in lines
    end

    test "exactly 14 days is not stale and 14 days plus one second is" do
      edge = pr_json([{1, "feat/a", ago(1_209_600)}, {2, "feat/b", ago(1_209_601)}])
      {_code, lines} = report(Map.put(base_map(), @pr_key, {:ok, edge}))
      assert "prs: stale 1: #2" in lines
      refute Enum.any?(lines, &(&1 =~ "#1"))
    end

    test "a 15-day-old PR is stale" do
      old = pr_json([{7, "feat/old", ago(15 * 86_400)}])
      {code, lines} = report(Map.put(base_map(), @pr_key, {:ok, old}))
      assert code == 1
      assert "prs: stale 1: #7" in lines
    end

    test "100 PRs is UNVERIFIED and 99 is verified" do
      many = fn n -> pr_json(for i <- 1..n, do: {i, "feat/#{i}", ago(60)}) end
      {code, lines} = report(Map.put(base_map(), @pr_key, {:ok, many.(100)}))
      assert code == 2
      assert "UNVERIFIED prs: list truncated at 100" in lines

      {code, lines} = report(Map.put(base_map(), @pr_key, {:ok, many.(99)}))
      assert code == 0
      assert "prs: open 99 (release-please 0, dependabot 0, feature 99)" in lines
    end

    test "an empty list is a verified zero" do
      {code, lines} = report(base_map())
      assert code == 0
      assert "prs: open 0 (release-please 0, dependabot 0, feature 0)" in lines
    end

    test "a gh error is UNVERIFIED" do
      {code, lines} = report(Map.put(base_map(), @pr_key, {:error, :exit_status}))
      assert code == 2
      assert "UNVERIFIED prs: could not read open PRs" in lines
    end
  end

  describe "local work" do
    test "one worktree, no stash, no unlanded branch is info" do
      {code, lines} = report(base_map())
      assert code == 0
      assert "local: worktrees 1, stashes 0, unlanded branches 0" in lines
    end

    test "zero worktrees parsed is UNVERIFIED" do
      {code, lines} = report(Map.put(base_map(), @wt_key, {:ok, ""}))
      assert code == 2
      assert "UNVERIFIED local: no worktree parsed" in lines
    end

    test "two worktrees is attention" do
      wt = "worktree /repo\nHEAD aaa\n\nworktree /repo-other\nHEAD bbb\n"
      {code, lines} = report(Map.put(base_map(), @wt_key, {:ok, wt}))
      assert code == 1
      assert "local: worktrees 2, stashes 0, unlanded branches 0" in lines
    end

    test "a stash is attention" do
      map = Map.put(base_map(), @stash_key, {:ok, "stash@{0}: WIP on x: abc msg\n"})
      {code, lines} = report(map)
      assert code == 1
      assert "local: worktrees 1, stashes 1, unlanded branches 0" in lines
    end

    test "an unlanded branch is attention" do
      {code, lines} = report(Map.put(base_map(), @unlanded_key, {:ok, "feat/x\n"}))
      assert code == 1
      assert "local: worktrees 1, stashes 0, unlanded branches 1" in lines
    end

    test "a failed read is UNVERIFIED" do
      {code, lines} = report(Map.put(base_map(), @stash_key, {:error, :exit_status}))
      assert code == 2
      assert "UNVERIFIED local: could not read stash list" in lines
    end
  end

  describe "fixed fixture set" do
    test "renders byte-identical lines in a fixed order" do
      {code, lines} = report(fixture_map())

      expected = [
        "BEARINGS: ATTENTION (3)",
        "sync: ahead 12 behind 0",
        "prs: stale 2: #210 #211",
        "local: worktrees 1, stashes 0, unlanded branches 2",
        "ci: success on #{short(pr_head())} (PR #247 head; main #{short(main_sha())} " <>
          "is its merge commit, tested only as a synthetic merge)",
        "ci: success on HEAD #{short(head_sha())}",
        "prs: open 7 (release-please 1, dependabot 5, feature 1)"
      ]

      assert code == 1
      assert lines == expected
      assert report(fixture_map()) == {code, lines}
    end

    test "new fixtures keep the shape the report reads" do
      for pr <- JSON.decode!(fixture!("gh-pr-list.json")) do
        assert %{"number" => _, "headRefName" => _, "createdAt" => _, "isDraft" => _} = pr
      end

      assert fixture!("git-worktree-porcelain.txt") =~ "worktree /repo"
      assert fixture!("git-rev-list-count.txt") =~ ~r/^\d+\s+\d+$/
    end
  end

  describe "argument guard" do
    test "an invalid --ws exits 2 with the specific line and reads nothing" do
      {out, code} = System.cmd(@launcher, ["--ws", "../x"], stderr_to_stdout: true)

      assert code == 2
      assert out =~ "UNVERIFIED args: invalid --ws"
    end
  end

  describe "fixtures and source" do
    test "captured fixtures keep the shape the report reads" do
      pulls = JSON.decode!(fixture!("gh-commit-pulls.json"))
      assert [%{"number" => _, "merged_at" => _, "head_sha" => _} | _] = pulls

      runs = JSON.decode!(fixture!("gh-run-list-pr-head.json"))
      assert [%{"databaseId" => _, "headSha" => _, "status" => _, "conclusion" => _} | _] = runs

      assert %{"nameWithOwner" => slug} = JSON.decode!(fixture!("gh-repo-view.json"))
      assert is_binary(slug)
    end

    test "MANIFEST lists a command for every fixture file and each exists" do
      lines = fixture!("MANIFEST.txt") |> String.split("\n", trim: true)
      assert length(lines) >= 5

      for line <- lines, not String.starts_with?(line, "#") do
        [file, cmd] = String.split(line, " ", parts: 2)
        assert cmd =~ ~r/^(git|gh) /
        assert File.exists?(Path.join([@repo_root, "test/fixtures/bearings", file]))
      end

      assert length(lines) >= 10
    end

    test "the report writes no file" do
      source = File.read!(Path.join(@repo_root, "script/bearings_report.exs"))
      refute source =~ ~r/File\.(write|rm|mkdir|cp|rename)/
    end

    test "no workflow references the report" do
      for wf <- Path.wildcard(Path.join(@repo_root, ".github/workflows/*.yml")) do
        refute File.read!(wf) =~ "bearings"
      end
    end
  end
end
