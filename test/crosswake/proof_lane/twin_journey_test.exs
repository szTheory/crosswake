defmodule Crosswake.ProofLane.TwinJourneyTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.TwinJourney

  defp ctx(root),
    do: %{
      run_root: root,
      project: "/x/CrosswakeShell.xcodeproj",
      udid: "UDID-1",
      control_port: 5123
    }

  setup do
    root =
      Path.join(System.tmp_dir!(), "twin-journey-" <> Base.encode16(:crypto.strong_rand_bytes(4)))

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf(root) end)
    {:ok, root: root}
  end

  describe "xcodebuild_args/2" do
    test "always carries the test plan, run-root paths and the control port", %{root: root} do
      for mode <- [
            :build,
            {:test, "CrosswakeShellUITests/TwinJourneyUITests/test_01_uninterrupted_journey"}
          ] do
        args = TwinJourney.xcodebuild_args(mode, Map.put(ctx(root), :result_bundle, "rb-c1"))
        joined = Enum.join(args, " ")

        assert ["-testPlan", "TwinJourney"] ==
                 args
                 |> Enum.chunk_every(2, 1, :discard)
                 |> Enum.find(&(&1 == ["-testPlan", "TwinJourney"]))

        assert Enum.at(args, Enum.find_index(args, &(&1 == "-derivedDataPath")) + 1) ==
                 Path.join(root, "dd")

        assert Enum.at(args, Enum.find_index(args, &(&1 == "-resultBundlePath")) + 1) ==
                 Path.join(root, "rb-c1.xcresult")

        assert "TEST_RUNNER_CROSSWAKE_TWIN_CONTROL_PORT=5123" in args
        assert "ONLY_ACTIVE_ARCH=YES" in args
        refute joined =~ ~r/screenshot|attachment|keepAlways|recording/i
      end
    end

    test "test mode selects exactly one method and the env carries the control port", %{
      root: root
    } do
      args = TwinJourney.xcodebuild_args({:test, "A/B/test_x"}, ctx(root))
      assert "-only-testing:A/B/test_x" in args
      assert hd(args) == "test-without-building"

      assert TwinJourney.xcodebuild_env(ctx(root)) == [
               {"TEST_RUNNER_CROSSWAKE_TWIN_CONTROL_PORT", "5123"}
             ]
    end
  end

  describe "classify_output/2" do
    test "reduces raw output to a closed class and method names" do
      text = """
      Test Case '-[CrosswakeShellUITests.TwinJourneyUITests test_01_uninterrupted_journey]' passed (4.0 seconds).
      secret-looking line that must not survive
      ** TEST EXECUTE SUCCEEDED **
      """

      assert %{class: :succeeded, tests: ["test_01_uninterrupted_journey"]} =
               TwinJourney.classify_output(text, 0)

      assert %{class: :failed} = TwinJourney.classify_output("** TEST EXECUTE FAILED **", 65)
      assert %{class: :build_failed} = TwinJourney.classify_output("** TEST BUILD FAILED **", 65)
      assert %{class: :timeout} = TwinJourney.classify_output("", :timeout)
      assert %{class: :cause_not_retained} = TwinJourney.classify_output("unrecognised", 1)
      refute Map.has_key?(TwinJourney.classify_output(text, 0), :text)
    end
  end

  describe "cleanup/1" do
    test "removes result bundles, derived data, databases and media copies", %{root: root} do
      File.mkdir_p!(Path.join(root, "rb-c1.xcresult/Data"))
      File.mkdir_p!(Path.join(root, "dd/Build"))
      File.mkdir_p!(Path.join(root, "att-canary"))
      File.write!(Path.join(root, "twin.sqlite3"), "x")
      File.write!(Path.join(root, "twin.sqlite3-wal"), "x")
      File.mkdir_p!(Path.join(root, "obs/c1"))
      File.write!(Path.join(root, "obs/c1/pronunciation.aiff"), "x")
      File.write!(Path.join(root, "obs/c1/twin-webview.jsonl"), "{}\n")

      assert :ok = TwinJourney.cleanup(root)
      assert Path.wildcard(Path.join(root, "**/*.xcresult")) == []
      refute File.exists?(Path.join(root, "dd"))
      refute File.exists?(Path.join(root, "att-canary"))
      refute File.exists?(Path.join(root, "twin.sqlite3"))
      refute File.exists?(Path.join(root, "twin.sqlite3-wal"))
      refute File.exists?(Path.join(root, "obs/c1/pronunciation.aiff"))
      assert File.exists?(Path.join(root, "obs/c1/twin-webview.jsonl"))
    end

    test "refuses to treat a protected directory as a run root and reports residue", %{
      root: _root
    } do
      assert {:error, :residue} = TwinJourney.cleanup(System.tmp_dir!())
    end
  end

  describe "write_stages/2" do
    test "writes a closed private per-stage record once and names the cases never reached", %{
      root: root
    } do
      runtime = %Crosswake.ProofLane.TwinRuntime{
        run_root: root,
        run_id: "twin-test-run",
        database_path: nil,
        origin: nil,
        origin_port: nil,
        registry: nil
      }

      stages = [
        %{stage: :canary, xcodebuild: :failed, attachments: :counted_zero},
        %{stage: :c1, xcodebuild: :succeeded, attachments: :counted_zero},
        %{stage: :c3, xcodebuild: :timeout, attachments: :no_result_bundle}
      ]

      assert :ok = TwinJourney.write_stages(runtime, stages)
      path = Path.join(root, "run-stages.json")
      assert File.stat!(path).mode |> Bitwise.band(0o777) == 0o600

      assert %{
               "schema" => "crosswake.twin_run_stages/1",
               "run_id" => "twin-test-run",
               "stages" => [
                 %{"stage" => "canary", "xcodebuild" => "failed"},
                 %{"stage" => "c1", "attachments" => "counted_zero"},
                 %{
                   "stage" => "c3",
                   "xcodebuild" => "timeout",
                   "attachments" => "no_result_bundle"
                 }
               ],
               "not_reached" => ["c2", "c4", "c5"]
             } = Jason.decode!(File.read!(path))

      # A first record is never overwritten.
      assert {:error, :eexist} = TwinJourney.write_stages(runtime, [])
    end
  end

  test "the module and the UI sources never request a screenshot or attachment option" do
    source = File.read!("lib/crosswake/proof_lane/twin_journey.ex")
    refute source =~ ~r/keepAlways|--screenshot|attachmentLifetime/i
  end

  test "the journey observes identities only through the checked source gate" do
    source = File.read!("lib/crosswake/proof_lane/twin_journey.ex")
    assert source =~ "TwinProducers.checked_identities("
    refute source =~ "TwinProducers.observe_identities("
  end

  # The source pin keeps the statement bare, the next test proves the dead-registry path
  # neither raises nor changes the verdict. Changing either is the deferred item "a stop
  # failure changes the run verdict"; reopen it on the next twin change that already alters
  # the cause list or receipt (Phase 188 or later), or after any run that leaves a process
  # behind.
  test "the journey discards the stop_children result by design until a stop failure feeds the verdict" do
    source = File.read!("lib/crosswake/proof_lane/twin_journey.ex")
    assert source =~ ~r/^\s+TwinRuntime\.stop_children\(runtime\)\s*$/m
    refute source =~ "= TwinRuntime.stop_children("
    refute source =~ "case TwinRuntime.stop_children("
  end

  test "a journey whose registry is gone before finish keeps its verdict and does not raise", %{
    root: root
  } do
    build = fn name ->
      run_root = Path.join([root, name, "run"])
      File.mkdir_p!(run_root)
      {:ok, registry} = Agent.start(fn -> %{children: %{}, first_failure: nil} end)

      %Crosswake.ProofLane.TwinRuntime{
        run_id: "twin-test-" <> name,
        run_root: run_root,
        database_path: Path.join(root, "outside.db"),
        origin: nil,
        origin_port: nil,
        origin_listener: nil,
        candidate_path: root,
        registry: registry
      }
    end

    dead = build.("dead")
    live = build.("live")
    on_exit(fn -> if Process.alive?(live.registry), do: Agent.stop(live.registry) end)

    # The database path is outside the run root, so start_backend refuses before it can run
    # ecto.migrate or phx.server; on a host missing a tool, the tool lookup blocks first.
    refute String.starts_with?(dead.database_path, dead.run_root <> "/")
    refute String.starts_with?(live.database_path, live.run_root <> "/")

    :ok = Agent.stop(dead.registry)

    dead_result = TwinJourney.run(dead, %{}, [])
    live_result = TwinJourney.run(live, %{}, [])

    assert dead_result == {:blocked, :prerequisite_missing}
    assert live_result == {:blocked, :prerequisite_missing}
    assert dead_result == live_result
    assert {:error, :registry_gone} = Crosswake.ProofLane.TwinRuntime.stop_children(dead)
  end
end
