defmodule Mix.Tasks.Crosswake.Release.CandidateTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Crosswake.Release.Candidate

  @sha_a String.duplicate("a", 40)
  @sha_b String.duplicate("b", 40)
  @sha_c String.duplicate("c", 40)
  @sha_d String.duplicate("d", 40)
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

  # WELD-06, end to end: a well-formed version two minor releases ahead of the
  # declared candidate reaches the full evaluation graph and produces a real
  # receipt -- proving the CLI entrypoint (parse!/1,
  # validate_command_identity!/3) AND the identity self-consistency layer
  # (Identity.normalize!/2) both accept it, not just format-check it.
  @tag :tmp_dir
  test "a well-formed version two minor releases ahead reaches evaluation and produces a real receipt",
       %{tmp_dir: tmp_dir} do
    output_dir = Path.join(tmp_dir, "non-candidate")
    version = "1.4.0"

    terminal =
      capture_io(fn ->
        Candidate.run(
          ["--version", version, "--ref", @sha_a, "--output-dir", output_dir],
          candidate_opts: [input: input(version)]
        )
      end)

    receipt =
      Path.join(output_dir, "candidate-receipt.json") |> File.read!() |> Jason.decode!()

    assert receipt["state"] == "READY FOR APPROVAL"
    assert receipt["identity"]["bound"]["version"] == version
    assert String.starts_with?(terminal, "READY FOR APPROVAL")
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
      ["--version", "1.2", "--ref", @sha_a, "--output-dir", tmp_dir],
      ["--version", "v1.2.3", "--ref", @sha_a, "--output-dir", tmp_dir],
      ["--version", "1.2.3-rc1", "--ref", @sha_a, "--output-dir", tmp_dir],
      ["--version", "", "--ref", @sha_a, "--output-dir", tmp_dir],
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

  @tag :tmp_dir
  test "the public evidence-directory command builds a deterministic receipt from exact artifacts",
       %{
         tmp_dir: tmp_dir
       } do
    fixture = Crosswake.ReleaseCandidateReceiptFixtures.build!(Path.join(tmp_dir, "evidence"))
    output_dir = Path.join(tmp_dir, "receipt")

    args = evidence_args(fixture, output_dir)
    terminal = capture_io(fn -> Candidate.run(args) end)
    receipt = Path.join(output_dir, "candidate-receipt.json") |> File.read!() |> Jason.decode!()
    receipt_bytes = File.read!(Path.join(output_dir, "candidate-receipt.json"))
    second_output_dir = Path.join(tmp_dir, "receipt-second")

    second_terminal =
      capture_io(fn -> Candidate.run(evidence_args(fixture, second_output_dir)) end)

    assert receipt["state"] == "READY FOR APPROVAL"
    assert Enum.any?(receipt["identity"]["bound"]["proofs"], &(&1["id"] == "maven.rehearsal"))
    assert receipt["external_state"]["publication"] == "NONE"
    assert receipt["external_state"]["changed"] == false
    assert terminal =~ "READY FOR APPROVAL"
    assert second_terminal == terminal
    assert File.read!(Path.join(second_output_dir, "candidate-receipt.json")) == receipt_bytes
  end

  @tag :tmp_dir
  test "missing, stale identity/run bindings and unexpected sensitive fields fail closed", %{
    tmp_dir: tmp_dir
  } do
    mutations = [
      {:missing_ci_receipt,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.ci)) end},
      {:missing_ci_manifest,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.ci_packages)) end},
      {:missing_hex_rehearsal,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.hex)) end},
      {:missing_hex_manifest,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.hex_packages)) end},
      {:missing_ios_rehearsal,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.ios)) end},
      {:missing_mirror_observation,
       fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.mirror)) end},
      {:missing_maven, fn fixture -> File.rm!(Path.join(fixture.root, fixture.files.maven)) end},
      {:stale_candidate_head,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :ci,
           &Map.put(&1, "head", @sha_b)
         )
       end},
      {:stale_candidate_tree,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :ci,
           &Map.put(&1, "tree", @sha_d)
         )
       end},
      {:stale_candidate_base,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :ci,
           &Map.put(&1, "base", @sha_d)
         )
       end},
      {:maven_not_dropped,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :maven,
           &Map.put(&1, "deployment_result", "VALIDATED")
         )
       end},
      {:stale_ci_run,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :ci,
           &Map.put(&1, "run_id", "9999")
         )
       end},
      {:stale_hex_run,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :hex,
           &Map.put(&1, "run_id", "9999")
         )
       end},
      {:stale_ios_run,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :ios,
           &Map.put(&1, "run_id", "9999")
         )
       end},
      {:stale_maven_run,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :maven,
           &Map.put(&1, "run_id", "9999")
         )
       end},
      {:sensitive_unknown_key,
       fn fixture ->
         Crosswake.ReleaseCandidateReceiptFixtures.mutate_json!(
           fixture,
           :maven,
           &Map.put(&1, @privacy_canary, "private")
         )
       end}
    ]

    for {name, mutate} <- mutations do
      fixture =
        Crosswake.ReleaseCandidateReceiptFixtures.build!(Path.join(tmp_dir, Atom.to_string(name)))

      mutate.(fixture)
      output_dir = Path.join(tmp_dir, "out-#{name}")

      error =
        assert_raise ArgumentError, "candidate evidence is invalid", fn ->
          capture_io(fn -> Candidate.run(evidence_args(fixture, output_dir)) end)
        end

      refute Exception.message(error) =~ @privacy_canary
      refute File.exists?(output_dir)
    end
  end

  @tag :tmp_dir
  test "public evidence command rejects duplicate selectors and caller-supplied receipt payload",
       %{
         tmp_dir: tmp_dir
       } do
    fixture = Crosswake.ReleaseCandidateReceiptFixtures.build!(Path.join(tmp_dir, "evidence"))
    args = evidence_args(fixture, Path.join(tmp_dir, "output"))

    for invalid <- [args ++ ["--ci-run-id", "1001"], args ++ ["--receipt", "{}"]] do
      error = assert_raise Mix.Error, fn -> Candidate.run(invalid) end
      assert Exception.message(error) == "invalid release candidate command"
    end

    stale_version_args =
      args
      |> Enum.chunk_every(2)
      |> Enum.flat_map(fn
        ["--version", _value] -> ["--version", "0.2.5"]
        pair -> pair
      end)

    assert_raise ArgumentError, "candidate evidence is invalid", fn ->
      capture_io(fn -> Candidate.run(stale_version_args) end)
    end
  end

  defp input(version \\ "0.2.1") do
    %{
      identity: identity(version),
      observed_identity: identity(version),
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

  defp evidence_args(fixture, output_dir) do
    [
      "--version",
      fixture.version,
      "--ref",
      fixture.ref,
      "--evidence-dir",
      fixture.root,
      "--output-dir",
      output_dir,
      "--ci-run-id",
      Integer.to_string(fixture.runs.ci),
      "--hex-run-id",
      Integer.to_string(fixture.runs.hex),
      "--ios-run-id",
      Integer.to_string(fixture.runs.ios),
      "--maven-run-id",
      Integer.to_string(fixture.runs.maven)
    ]
  end

  defp identity(version) do
    %{
      version: version,
      ref: @sha_a,
      head: @sha_a,
      tree: @sha_b,
      base: @sha_c,
      coordinates: [%{id: "hex-core", coordinate: "crosswake@#{version}"}],
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
        tag: "v#{version}",
        plan_sha256: @digest_c
      },
      run: %{id: 1234, head: @sha_a, status: "COMPLETED", conclusion: "SUCCESS"}
    }
  end
end
