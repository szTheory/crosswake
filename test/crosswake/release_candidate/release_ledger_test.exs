defmodule Crosswake.ReleaseCandidate.ReleaseLedgerTest do
  @moduledoc """
  Behavioral proof for the committed release ledger (XPUB-06, Phase 173 plan 03).

  The claim under test is durability: the exact-public proof's verdict survives
  in a place the artifact store cannot take away. A public repository's
  uploaded-artifact retention ceiling sits far below this project's horizon, so
  the copy of record is `docs/release-ledger/RELEASE-LEDGER.jsonl`, written by
  `script/append_release_ledger.sh`.

  These tests invoke the REAL script through `System.cmd/3` and read the REAL
  committed file. They deliberately do not grep the script's source: a
  source-grep cannot tell a script that appends from one that merely contains
  the word "append".

  The read-back test reaches the ledger through `git show` at an explicit
  commit, from a working directory in which the file does not exist — asserted,
  not assumed. A read that could have fallen through to the working-tree copy
  would prove nothing about git.
  """

  use ExUnit.Case, async: true

  @script "script/append_release_ledger.sh"
  @ledger "docs/release-ledger/RELEASE-LEDGER.jsonl"

  # Every key every line must carry. Asserted as a set, so a line with an extra
  # key fails too: a ledger whose shape drifts silently is a ledger whose older
  # lines quietly stop meaning what a reader assumes.
  @required_keys MapSet.new(~w(
    approved_head
    lane
    outcome
    package
    recorded_at
    ref
    run_id
    schema_version
    version
  ))

  # The three backfilled rows seeded when the ledger was created. Pinned as a
  # lower bound on the data-line count: a live release adds rows, so an exact
  # equality here would go red on the first real write, but a ledger that lost
  # rows must still fail — this file is append-only.
  @seeded_entry_count 3

  # The real past release this phase measured durability against: run
  # 31325689640 (2026-08-09, crosswake_sigra 0.1.3). That run's uploaded
  # artifacts report `"expired": true`; this line does not expire.
  @measured_run_id "31325689640"
  @measured_head "70edb8077894fd09d4376591782b511c9d8be664"

  @head String.duplicate("a", 40)
  @other_head String.duplicate("b", 40)

  defp tmp_dir!(name) do
    dir =
      Path.join([
        System.tmp_dir!(),
        "crosswake-release-ledger",
        "#{name}-#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(dir)
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    dir
  end

  defp append(ledger, overrides \\ %{}) do
    fields =
      Map.merge(
        %{
          package: "crosswake",
          version: "0.2.1",
          approved_head: @head,
          ref: "refs/tags/hex-v0.2.1",
          lane: "ordinary",
          run_id: "1234567890",
          outcome: "success"
        },
        overrides
      )

    System.cmd(
      "bash",
      [
        @script,
        "--package",
        fields.package,
        "--version",
        fields.version,
        "--approved-head",
        fields.approved_head,
        "--ref",
        fields.ref,
        "--lane",
        fields.lane,
        "--run-id",
        fields.run_id,
        "--outcome",
        fields.outcome,
        "--ledger",
        ledger
      ],
      stderr_to_stdout: true
    )
  end

  defp data_lines(contents) do
    contents
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(String.trim_leading(&1), "#"))
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  defp entries(contents), do: Enum.map(data_lines(contents), &Jason.decode!/1)

  defp git!(args, opts \\ []) do
    {out, 0} = System.cmd("git", args, [stderr_to_stdout: true] ++ opts)
    String.trim_trailing(out)
  end

  describe "the committed ledger's shape" do
    test "every non-comment line parses as JSON and carries exactly the required key set" do
      lines = data_lines(File.read!(@ledger))

      # Cardinality pinned at the assertion site. Without it, `Enum.all?` over an
      # empty list is vacuously true and a ledger that lost every row would pass.
      assert length(lines) >= @seeded_entry_count,
             "ledger holds #{length(lines)} data lines, fewer than the #{@seeded_entry_count} seeded rows — this file is append-only"

      conforming =
        Enum.count(lines, fn line ->
          case Jason.decode(line) do
            {:ok, entry} when is_map(entry) ->
              MapSet.equal?(MapSet.new(Map.keys(entry)), @required_keys)

            _ ->
              false
          end
        end)

      assert conforming == length(lines),
             "#{length(lines) - conforming} of #{length(lines)} ledger lines are not JSON objects carrying exactly #{inspect(Enum.sort(@required_keys))}"
    end

    test "the backfill boundary is declared and classifies every committed row decidably" do
      contents = File.read!(@ledger)

      boundary =
        case Regex.run(~r/backfill_boundary_run_id=(\d+)/, contents) do
          [_, digits] -> String.to_integer(digits)
          nil -> flunk("the ledger header declares no backfill_boundary_run_id")
        end

      all = entries(contents)

      classified =
        Enum.count(all, fn entry ->
          case Integer.parse(entry["run_id"]) do
            {run_id, ""} -> run_id <= boundary or run_id > boundary
            _ -> false
          end
        end)

      assert classified == length(all),
             "#{length(all) - classified} of #{length(all)} rows carry a run_id that is not an integer, so backfilled-vs-live is undecidable for them"

      backfilled = Enum.count(all, &(String.to_integer(&1["run_id"]) <= boundary))

      assert backfilled >= @seeded_entry_count,
             "expected at least the #{@seeded_entry_count} seeded rows at or below the declared boundary #{boundary}, found #{backfilled}"
    end

    test "the measured run's entry is present and records a real, non-invented coordinate" do
      entry =
        @ledger
        |> File.read!()
        |> entries()
        |> Enum.find(&(&1["run_id"] == @measured_run_id))

      assert entry,
             "no ledger entry for run #{@measured_run_id}, the run durability was measured on"

      assert entry["approved_head"] == @measured_head
      assert entry["package"] == "crosswake_sigra"
      assert entry["version"] == "0.1.3"
      assert entry["outcome"] == "failure"
    end
  end

  describe "durability: the record is readable through git alone" do
    test "a committed entry is readable with git show at an explicit commit, from a directory that does not contain the file" do
      commit = git!(["log", "-n", "1", "--format=%H", "--", @ledger])

      assert Regex.match?(~r/^[0-9a-f]{40}$/, commit),
             "expected a 40-hex commit, got #{inspect(commit)}"

      git_dir = git!(["rev-parse", "--absolute-git-dir"])

      # The read runs from a scratch directory, NOT the repository. Deleting the
      # repository's real copy inside a test would be a destructive act a test
      # must never perform; an empty cwd proves the same thing — there is no
      # working-tree copy here for the read to fall through to, and the assertion
      # below says so rather than assuming it.
      elsewhere = tmp_dir!("git-show")
      refute File.exists?(Path.join(elsewhere, @ledger))

      {contents, 0} =
        System.cmd("git", ["--git-dir", git_dir, "show", "#{commit}:#{@ledger}"],
          cd: elsewhere,
          stderr_to_stdout: true
        )

      committed = entries(contents)

      assert length(committed) >= @seeded_entry_count,
             "the committed blob at #{commit} holds #{length(committed)} data lines"

      entry = Enum.find(committed, &(&1["run_id"] == @measured_run_id))

      assert entry,
             "run #{@measured_run_id} is absent from the ledger blob at #{commit} — the artifact store is not the only thing that forgot it"

      assert entry["approved_head"] == @measured_head
      assert entry["outcome"] == "failure"
      assert entry["package"] == "crosswake_sigra"
      assert entry["version"] == "0.1.3"
    end
  end

  describe "the writer" do
    test "appending the same run twice leaves one line" do
      ledger = Path.join(tmp_dir!("idempotent"), "ledger.jsonl")

      assert {_, 0} = append(ledger)
      assert {second, 0} = append(ledger)
      assert second =~ "not appending a duplicate"

      lines = data_lines(File.read!(ledger))

      assert length(lines) == 1,
             "a re-run of the same run id produced #{length(lines)} lines; a rerun is this pipeline's normal recovery motion and must not inflate the ledger"
    end

    test "a different run for the same coordinate does append a second line" do
      ledger = Path.join(tmp_dir!("distinct-runs"), "ledger.jsonl")

      assert {_, 0} = append(ledger, %{run_id: "1111111111"})
      assert {_, 0} = append(ledger, %{run_id: "2222222222"})

      assert length(data_lines(File.read!(ledger))) == 2
    end

    test "a failing verdict is written as faithfully as a passing one" do
      ledger = Path.join(tmp_dir!("outcomes"), "ledger.jsonl")

      for {outcome, run_id} <- [
            {"success", "3000000001"},
            {"failure", "3000000002"},
            {"cancelled", "3000000003"},
            {"skipped", "3000000004"}
          ] do
        assert {_, 0} = append(ledger, %{outcome: outcome, run_id: run_id})
      end

      written = entries(File.read!(ledger))

      assert length(written) == 4

      assert Enum.map(written, & &1["outcome"]) == ~w(success failure cancelled skipped),
             "a ledger that cannot record failure cannot distinguish a failed proof from one that never ran"

      assert Enum.count(written, &MapSet.equal?(MapSet.new(Map.keys(&1)), @required_keys)) == 4
    end

    test "an earlier line is never rewritten by a later append" do
      ledger = Path.join(tmp_dir!("append-only"), "ledger.jsonl")

      assert {_, 0} = append(ledger, %{run_id: "4000000001", outcome: "failure"})
      first = hd(data_lines(File.read!(ledger)))

      assert {_, 0} =
               append(ledger, %{
                 run_id: "4000000002",
                 outcome: "success",
                 approved_head: @other_head
               })

      lines = data_lines(File.read!(ledger))
      assert length(lines) == 2

      assert hd(lines) == first,
             "the first line changed; this ledger is append-only and its history is the record"
    end

    test "each rejected field exits with its own code, so the log names which field was wrong" do
      ledger = Path.join(tmp_dir!("rejects"), "ledger.jsonl")

      rejections = [
        {%{approved_head: "nope"}, 3},
        {%{version: "1.2"}, 4},
        {%{lane: "sideways"}, 5},
        {%{outcome: "probably"}, 6},
        {%{run_id: "0x10"}, 7}
      ]

      observed =
        for {overrides, expected_code} <- rejections do
          {output, code} = append(ledger, overrides)
          assert output =~ "FAIL", "rejection for #{inspect(overrides)} printed no failure line"
          {code, expected_code}
        end

      assert length(observed) == length(rejections)

      assert Enum.count(observed, fn {code, expected} -> code == expected end) ==
               length(rejections),
             "exit codes #{inspect(observed)} — a shared code cannot tell a caller which field was rejected"

      refute File.exists?(ledger),
             "a rejected entry created the ledger file; validation must happen before anything is written"
    end
  end
end
