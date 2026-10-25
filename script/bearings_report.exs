#!/usr/bin/env elixir

# One-screen orientation report: is CI green where it counts, and what needs attention.
#
# Absence is never success: a read that failed, returned nothing where data is required,
# or could not be parsed is UNVERIFIED, never OK. This is not a required check and is not
# referenced by any workflow; the fixture-based ExUnit file is its only CI exposure.
#
# The CI line reports the PR head because Crosswake CI runs only on pull_request: the
# origin/main tip is never tested directly, only its PR head and a synthetic merge commit.
#
# Exit codes: 0 OK, 1 ATTENTION, 2 UNVERIFIED (which wins).
# Output carries fixed reason strings only; stderr text and env values are never printed.
defmodule Crosswake.BearingsReport do
  @default_ws "quality-ratchet-release"
  @sha ~r/\A[0-9a-f]{40}\z/

  def main(argv) do
    {opts, _rest, invalid} =
      OptionParser.parse(argv, strict: [ws: :string, root: :string, help: :boolean])

    cond do
      opts[:help] ->
        IO.puts("usage: script/bearings-report [--ws NAME] [--root DIR]")
        0

      invalid != [] or not valid_ws?(Keyword.get(opts, :ws, @default_ws)) ->
        emit(render([unverified("args", "invalid --ws")]))

      true ->
        deps = %{
          run: &system_run/2,
          read: &File.read/1,
          list: &Path.wildcard/1,
          now: DateTime.utc_now()
        }

        case change_root(opts[:root]) do
          :ok -> emit(run(opts, deps))
          :error -> emit(render([unverified("args", "invalid --root")]))
        end
    end
  end

  defp emit({code, lines}) do
    Enum.each(lines, &IO.puts/1)
    code
  end

  defp valid_ws?(ws), do: Regex.match?(~r/^[a-z0-9][a-z0-9-]*$/, ws)

  defp change_root(nil), do: :ok
  defp change_root(root), do: if(File.cd(root) == :ok, do: :ok, else: :error)

  @doc "The single external-read seam: `{:ok, out}` or `{:error, reason_atom}`, never stderr text."
  def system_run(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {out, 0} -> {:ok, out}
      {_discarded, _status} -> {:error, :exit_status}
    end
  rescue
    ErlangError -> {:error, :missing_binary}
    _ -> {:error, :exception}
  end

  def run(opts, deps) do
    {fetch_ok, sync_lines} = check_sync(deps)
    ctx = %{fetch_ok: fetch_ok, ws: Keyword.get(opts, :ws, @default_ws), root: opts[:root]}

    render([sync_lines, check_ci(ctx, deps), check_prs(ctx, deps), check_local(ctx, deps)])
  end

  @stale_seconds 14 * 24 * 60 * 60
  @pr_limit 100

  @doc "Fetches origin/main, then reports ahead/behind. Returns `{fetch_ok, lines}`."
  def check_sync(deps) do
    case deps.run.("git", ["fetch", "origin", "main"]) do
      {:ok, _} ->
        {true, [sync_counts(deps)]}

      {:error, _} ->
        {false, [unverified("sync", "fetch origin main failed")]}
    end
  end

  defp sync_counts(deps) do
    with {:ok, out} <-
           deps.run.("git", ["rev-list", "--left-right", "--count", "HEAD...origin/main"]),
         [a, b] <- String.split(out),
         {ahead, ""} <- Integer.parse(a),
         {behind, ""} <- Integer.parse(b) do
      kind = if ahead > 0 or behind > 0, do: :attention, else: :info
      {kind, "sync: ahead #{ahead} behind #{behind}"}
    else
      _ -> unverified("sync", "unparseable rev-list count")
    end
  end

  @doc "Open PR classes and stale PRs from `gh pr list`."
  def check_prs(_ctx, deps) do
    args = [
      "pr",
      "list",
      "--state",
      "open",
      "--limit",
      Integer.to_string(@pr_limit),
      "--json",
      "number,headRefName,createdAt,isDraft"
    ]

    with {:ok, out} <- gh_read(deps, args, "could not read open PRs"),
         {:ok, list} when is_list(list) <- decode(out),
         true <- Enum.all?(list, &pr_shape?/1) do
      if length(list) >= @pr_limit,
        do: [unverified("prs", "list truncated at #{@pr_limit}")],
        else: pr_lines(list, deps.now)
    else
      {:error, reason} -> [unverified("prs", reason)]
      _ -> [unverified("prs", "unparseable gh output")]
    end
  end

  defp pr_shape?(%{"number" => n, "headRefName" => h, "createdAt" => c})
       when is_integer(n) and is_binary(h) and is_binary(c),
       do: match?({:ok, _, _}, DateTime.from_iso8601(c))

  defp pr_shape?(_), do: false

  defp pr_lines(list, now) do
    count = fn prefix ->
      Enum.count(list, &String.starts_with?(&1["headRefName"], prefix))
    end

    rp = count.("release-please--")
    dep = count.("dependabot/")
    feature = length(list) - rp - dep

    stale =
      list
      |> Enum.filter(fn pr ->
        {:ok, created, _} = DateTime.from_iso8601(pr["createdAt"])
        DateTime.diff(now, created, :second) > @stale_seconds
      end)
      |> Enum.map(& &1["number"])
      |> Enum.sort()

    head =
      {:info,
       "prs: open #{length(list)} (release-please #{rp}, dependabot #{dep}, feature #{feature})"}

    if stale == [],
      do: [head],
      else: [
        head,
        {:attention, "prs: stale #{length(stale)}: " <> Enum.map_join(stale, " ", &"##{&1}")}
      ]
  end

  @doc "Worktrees, stashes and branches not merged into origin/main, as one line."
  def check_local(_ctx, deps) do
    with {:ok, wt} <- local_read(deps, "git", ["worktree", "list", "--porcelain"]),
         {:ok, stash} <- local_read(deps, "git", ["stash", "list"]),
         {:ok, unlanded} <-
           local_read(deps, "git", [
             "branch",
             "--no-merged",
             "origin/main",
             "--format=%(refname:short)"
           ]) do
      worktrees = wt |> String.split("\n") |> Enum.count(&String.starts_with?(&1, "worktree "))
      stashes = count_lines(stash)
      branches = count_lines(unlanded)

      if worktrees == 0 do
        [unverified("local", "no worktree parsed")]
      else
        kind = if worktrees > 1 or stashes > 0 or branches > 0, do: :attention, else: :info

        [
          {kind,
           "local: worktrees #{worktrees}, stashes #{stashes}, unlanded branches #{branches}"}
        ]
      end
    else
      {:error, reason} -> [unverified("local", reason)]
    end
  end

  defp local_read(deps, cmd, args) do
    case deps.run.(cmd, args) do
      {:ok, out} -> {:ok, out}
      {:error, _} -> {:error, "could not read #{Enum.join(Enum.take(args, 2), " ")}"}
    end
  end

  defp count_lines(out), do: out |> String.split("\n") |> Enum.count(&(String.trim(&1) != ""))

  @doc "Takes check results (each a list of `{kind, text}`) and returns `{exit_code, lines}`."
  def render(results) do
    lines = List.flatten(results)
    lines = if lines == [], do: [unverified("report", "no checks produced output")], else: lines

    bad = for {:unverified, t} <- lines, do: "UNVERIFIED " <> t
    attention = for {:attention, t} <- lines, do: t
    info = for {:info, t} <- lines, do: t

    {code, verdict} =
      cond do
        bad != [] -> {2, "BEARINGS: UNVERIFIED (#{length(bad)} reads failed)"}
        attention != [] -> {1, "BEARINGS: ATTENTION (#{length(attention)})"}
        true -> {0, "BEARINGS: OK"}
      end

    {code, [verdict | bad ++ attention ++ info]}
  end

  defp unverified(check, reason), do: {:unverified, "#{check}: #{reason}"}

  def check_ci(%{fetch_ok: false}, _deps), do: [unverified("ci", "origin/main not refreshed")]

  def check_ci(_ctx, deps) do
    with {:ok, main_sha} <- rev_parse(deps, "origin/main", "could not read origin/main"),
         {:ok, slug} <- repo_slug(deps),
         {:ok, pr} <- merged_pr(deps, slug, main_sha),
         {:ok, run} <- latest_run(deps, pr.head_sha, "no Crosswake CI run on the PR head"),
         {:ok, head_sha} <- rev_parse(deps, "HEAD", "could not read HEAD") do
      [ci_line(run, pr, main_sha) | head_lines(deps, head_sha, main_sha, pr.head_sha)]
    else
      {:error, reason} -> [unverified("ci", reason)]
    end
  end

  defp rev_parse(deps, ref, reason) do
    with {:ok, out} <- deps.run.("git", ["rev-parse", ref]),
         sha = String.trim(out),
         true <- Regex.match?(@sha, sha) do
      {:ok, sha}
    else
      _ -> {:error, reason}
    end
  end

  defp repo_slug(deps) do
    with {:ok, out} <-
           gh_read(
             deps,
             ["repo", "view", "--json", "nameWithOwner"],
             "could not read repository name"
           ),
         {:ok, %{"nameWithOwner" => slug}} when is_binary(slug) and slug != "" <- decode(out) do
      {:ok, slug}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "unparseable gh output"}
    end
  end

  defp merged_pr(deps, slug, main_sha) do
    jq = "[.[] | {number: .number, merged_at: .merged_at, head_sha: .head.sha}]"
    args = ["api", "repos/#{slug}/commits/#{main_sha}/pulls", "--jq", jq]

    with {:ok, out} <- gh_read(deps, args, "could not read merged PR for main tip"),
         {:ok, list} when is_list(list) <- decode(out) do
      case Enum.filter(list, &(is_map(&1) and not is_nil(&1["merged_at"]))) do
        [%{"number" => n, "head_sha" => h}] when is_integer(n) ->
          if Regex.match?(@sha, h || ""),
            do: {:ok, %{number: n, head_sha: h}},
            else: {:error, "unparseable gh output"}

        _ ->
          {:error, "main tip has no single merged PR"}
      end
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "unparseable gh output"}
    end
  end

  # Newest Crosswake CI run for exactly `sha`. `empty_reason` is the UNVERIFIED reason for `[]`.
  defp latest_run(deps, sha, empty_reason) do
    args = [
      "run",
      "list",
      "--workflow",
      "Crosswake CI",
      "--commit",
      sha,
      "--limit",
      "20",
      "--json",
      "databaseId,headSha,status,conclusion,event"
    ]

    with {:ok, out} <- gh_read(deps, args, "could not read CI runs"),
         {:ok, runs} when is_list(runs) <- decode(out) do
      matching = Enum.filter(runs, &(is_map(&1) and &1["headSha"] == sha))

      cond do
        runs == [] -> {:error, empty_reason}
        matching == [] -> {:error, "run list did not return the requested commit"}
        true -> {:ok, Enum.max_by(matching, &(&1["databaseId"] || 0))}
      end
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "unparseable gh output"}
    end
  end

  defp gh_read(deps, args, reason) do
    case deps.run.("gh", args) do
      {:ok, out} -> {:ok, out}
      {:error, _} -> {:error, reason}
    end
  end

  defp decode(out) do
    case JSON.decode(out) do
      {:ok, term} -> {:ok, term}
      {:error, _} -> {:error, "unparseable gh output"}
    end
  end

  defp verdict_of(%{"status" => "completed", "conclusion" => c}) when is_binary(c), do: c
  defp verdict_of(_), do: "PENDING"

  defp kind_of("success"), do: :info
  defp kind_of(_), do: :attention

  defp ci_line(run, pr, main_sha) do
    v = verdict_of(run)

    {kind_of(v),
     "ci: #{v} on #{short(pr.head_sha)} (PR ##{pr.number} head; main #{short(main_sha)} " <>
       "is its merge commit, tested only as a synthetic merge)"}
  end

  # Local HEAD that is neither the main tip nor the PR head needs its own CI run.
  defp head_lines(_deps, head, main, pr_head) when head in [main, pr_head], do: []

  defp head_lines(deps, head, _main, _pr_head) do
    case latest_run(deps, head, :none) do
      {:error, :none} ->
        [{:attention, "ci: CI has not run on HEAD #{short(head)}"}]

      {:error, reason} ->
        [unverified("ci", reason)]

      {:ok, run} ->
        v = verdict_of(run)
        [{kind_of(v), "ci: #{v} on HEAD #{short(head)}"}]
    end
  end

  defp short(sha), do: String.slice(sha, 0, 7)
end

unless Process.get(:crosswake_bearings_report_library),
  do: System.halt(Crosswake.BearingsReport.main(System.argv()))
