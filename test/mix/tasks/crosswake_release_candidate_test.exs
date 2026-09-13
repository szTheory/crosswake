unless Code.ensure_loaded?(Mix.Tasks.Crosswake.Release.Candidate) do
  defmodule Mix.Tasks.Crosswake.Release.Candidate do
    def run(_args, _opts \\ []), do: :not_implemented
  end
end

defmodule Mix.Tasks.Crosswake.Release.CandidateTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Crosswake.Release.Candidate

  @sha_a String.duplicate("a", 40)
  @sha_b String.duplicate("b", 40)
  @sha_c String.duplicate("c", 40)
  @digest_a String.duplicate("1", 64)
  @digest_b String.duplicate("2", 64)
  @digest_c String.duplicate("3", 64)
  @privacy_canary "candidate-private-input-must-not-echo"

  @tag :tmp_dir
  test "the exact command writes one authoritative receipt and matching projections", %{
    tmp_dir: tmp_dir
  } do
    output_dir = Path.join(tmp_dir, "candidate")

    terminal =
      capture_io(fn ->
        Candidate.run(
          ["--version", "0.2.1", "--ref", @sha_a, "--output-dir", output_dir],
          candidate_opts: [input: input()]
        )
      end)

    receipt_path = Path.join(output_dir, "candidate-receipt.json")
    markdown_path = Path.join(output_dir, "candidate-receipt.md")
    summary_path = Path.join(output_dir, "candidate-github-summary.md")
    terminal_path = Path.join(output_dir, "candidate-terminal.txt")

    assert File.regular?(receipt_path)
    assert File.regular?(markdown_path)
    assert File.regular?(summary_path)
    assert File.regular?(terminal_path)

    receipt = receipt_path |> File.read!() |> Jason.decode!()
    assert receipt["state"] == "READY FOR APPROVAL"
    assert receipt["identity"]["bound"]["ref"] == @sha_a

    for projection <- [
          terminal,
          File.read!(markdown_path),
          File.read!(summary_path),
          File.read!(terminal_path)
        ] do
      assert String.starts_with?(projection, "READY FOR APPROVAL")
      assert projection =~ receipt["next_action"]
    end
  end

  @tag :tmp_dir
  test "unknown, missing, duplicate, and malformed options fail before evaluation or output", %{
    tmp_dir: tmp_dir
  } do
    calls = :counters.new(1, [])

    input_adapter = fn ->
      :counters.add(calls, 1, 1)
      input()
    end

    invalid_argv = [
      [],
      ["--version", "0.2.1", "--ref", @sha_a],
      ["--version", "0.2.0", "--ref", @sha_a, "--output-dir", tmp_dir],
      ["--version", "0.2.1", "--ref", "abc1234", "--output-dir", tmp_dir],
      ["--version", "0.2.1", "--ref", @sha_a, "--output-dir", tmp_dir, "--bogus"],
      [
        "--version",
        "0.2.1",
        "--version",
        "0.2.1",
        "--ref",
        @sha_a,
        "--output-dir",
        tmp_dir
      ],
      ["--version", "0.2.1", "--ref", @sha_a, "--output-dir", tmp_dir, @privacy_canary]
    ]

    for argv <- invalid_argv do
      error =
        assert_raise Mix.Error, fn ->
          Candidate.run(argv, candidate_opts: [input_adapter: input_adapter])
        end

      assert Exception.message(error) == "invalid release candidate command"
      refute Exception.message(error) =~ @privacy_canary
    end

    assert :counters.get(calls, 1) == 0
    refute File.exists?(Path.join(tmp_dir, "candidate-receipt.json"))
  end

  @tag :tmp_dir
  test "blocked and stale receipts are written before the task exits non-zero", %{
    tmp_dir: tmp_dir
  } do
    blocked_dir = Path.join(tmp_dir, "blocked")

    assert_raise Mix.Error, "release candidate is BLOCKED", fn ->
      capture_io(fn ->
        Candidate.run(
          ["--version", "0.2.1", "--ref", @sha_a, "--output-dir", blocked_dir],
          candidate_opts: [
            input:
              put_in(input(), [:credentials], %{
                mirror_write_authority: "NOT CHECKED",
                exercised: false
              })
          ]
        )
      end)
    end

    assert Jason.decode!(File.read!(Path.join(blocked_dir, "candidate-receipt.json")))["state"] ==
             "BLOCKED"

    stale_dir = Path.join(tmp_dir, "stale")

    assert_raise Mix.Error, "release candidate is STALE", fn ->
      capture_io(fn ->
        Candidate.run(
          ["--version", "0.2.1", "--ref", @sha_a, "--output-dir", stale_dir],
          candidate_opts: [input: put_in(input(), [:observed_identity, :tree], @sha_c)]
        )
      end)
    end

    assert Jason.decode!(File.read!(Path.join(stale_dir, "candidate-receipt.json")))["state"] ==
             "STALE"
  end

  @tag :tmp_dir
  test "the CLI identity must match the bound fixture before filesystem activity", %{
    tmp_dir: tmp_dir
  } do
    output_dir = Path.join(tmp_dir, "mismatch")

    assert_raise ArgumentError, "candidate command identity is invalid", fn ->
      Candidate.run(
        ["--version", "0.2.1", "--ref", @sha_b, "--output-dir", output_dir],
        candidate_opts: [input: input()]
      )
    end

    refute File.exists?(output_dir)
  end

  test "the thin task delegates without remote or database mutation authority" do
    source =
      case File.read("lib/mix/tasks/crosswake.release.candidate.ex") do
        {:ok, bytes} -> bytes
        {:error, :enoent} -> ""
      end

    assert source =~ "Crosswake.ReleaseCandidate.run!"

    for forbidden <- ["git push", "hex.publish", "gh pr", "Ecto.Repo", "System.cmd"] do
      refute source =~ forbidden
    end
  end

  defp input do
    %{
      identity: identity(),
      observed_identity: identity(),
      checks: [%{id: "candidate.package", status: "PASS"}],
      external_state: %{
        publication: "NONE",
        successful_coordinates: [],
        failed_step: nil,
        changed: false,
        all_linked_proven: false
      },
      credentials: %{mirror_write_authority: "PROVEN", exercised: true}
    }
  end

  defp identity do
    %{
      version: "0.2.1",
      ref: @sha_a,
      head: @sha_a,
      tree: @sha_b,
      base: @sha_c,
      coordinates: [%{id: "hex-core", coordinate: "crosswake@0.2.1"}],
      config_digests: [%{id: "release-please-config", sha256: @digest_a}],
      workflow_digests: [%{id: "release-please", sha256: @digest_b}],
      package_digests: [
        %{
          id: "crosswake",
          outer_sha256: @digest_a,
          payload_sha256: @digest_b,
          metadata_sha256: @digest_c
        }
      ],
      proofs: [%{id: "package-audit", status: "PASS", sha256: @digest_a}],
      mirror: %{
        split: @sha_a,
        main: @sha_b,
        tag: "v0.2.1",
        plan_sha256: @digest_c
      },
      run: %{id: 1234, head: @sha_a, status: "COMPLETED", conclusion: "SUCCESS"}
    }
  end
end
