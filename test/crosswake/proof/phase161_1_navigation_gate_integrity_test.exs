defmodule Crosswake.Proof.Phase161_1NavigationGateIntegrityTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.NavigationShellAdvisory

  @script "scripts/verify_phase_161_1.sh"
  @workflow ".github/workflows/crosswake-ci.yml"
  @mix_project "mix.exs"
  @phase41_dedicated_command "test --only phase41_nested_process --seed 748644 --max-cases 1"
  @phase41_hosted_broad_command "test --exclude phase41_nested_process --exclude requires_example_host --seed 748644 --max-cases 8"
  @phase41_alias_broad_command "test --exclude phase41_nested_process --exclude requires_example_host --exclude advisory_only --seed 748644 --max-cases 8"
  @companion_commands [
    "cmd --cd packages/crosswake_rulestead mix deps.get --check-locked",
    "cmd --cd packages/crosswake_rulestead mix test",
    "cmd --cd packages/crosswake_rindle mix deps.get --check-locked",
    "cmd --cd packages/crosswake_rindle mix test",
    "cmd --cd packages/crosswake_sigra mix deps.get --check-locked",
    "cmd --cd packages/crosswake_sigra mix test",
    "cmd --cd packages/crosswake_chimeway mix deps.get --check-locked",
    "cmd --cd packages/crosswake_chimeway mix test",
    "cmd --cd packages/crosswake_threadline mix deps.get --check-locked",
    "cmd --cd packages/crosswake_threadline mix test"
  ]
  @phase41_tagged_tests [
    "successful physical-class promotion survives the producing subprocess exit",
    "a zero-exit host run with passed names cannot promote without every ordered marker",
    "the exact marker fixture advances past transcript reduction"
  ]
  @phase41_non_host_tests 1_625
  @phase41_host_tests 74
  @phase41_broad_tests @phase41_non_host_tests - length(@phase41_tagged_tests)
  @host_tests ~w(
    testOrderedProductionNavigationProofEmitsClosedMarkers
    testProductionContainerAuthorizesRootsAndMirrorsOneNavigateWithoutDuplicate
    testPatchAndCancelledThenCompletedPopPreserveProductionStackAndFocus
    testDocumentStartShellContractUsesOnlyFixedMarkerAndFiveDefaults
    testLayoutDeliveryKeepsFourSafeAreaFactsSeparateFromKeyboard
    testSyntheticProductionNavigationFlow
  )

  @tag :tmp_dir
  @tag :phase41_nested_process
  test "a zero-exit host run with passed names cannot promote without every ordered marker", %{
    tmp_dir: tmp
  } do
    assert_phase41_partition_contract!()

    assert_marker_failure(tmp, Enum.drop(NavigationShellAdvisory.assertion_ids(), -1))

    assert_marker_failure(
      tmp,
      NavigationShellAdvisory.assertion_ids() ++
        [List.last(NavigationShellAdvisory.assertion_ids())]
    )

    assert_marker_failure(tmp, Enum.reverse(NavigationShellAdvisory.assertion_ids()))
  end

  @tag :tmp_dir
  @tag :phase41_nested_process
  test "the exact marker fixture advances past transcript reduction", %{tmp_dir: tmp} do
    with_phase41_nested_process_tracer("ordered-markers", fn ->
      {output, status} = run_gate(tmp, NavigationShellAdvisory.assertion_ids())

      assert status == 0, "expected exact markers to advance, got #{status}: #{output}"
      refute output =~ "PL-IOS-NAV-HOST-MARKER"
    end)
  end

  defp assert_marker_failure(tmp, markers) do
    {output, status} = run_gate(tmp, markers)

    assert status != 0
    assert output =~ "PL-IOS-NAV-HOST-MARKER: host-markers"
    refute output =~ "fixture-transcript-canary"
  end

  defp assert_phase41_partition_contract! do
    tagged_tests =
      "test/**/*_test.exs"
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> then(
          &Regex.scan(~r/@tag\s+:phase41_nested_process\s+test\s+"([^"]+)"/, &1,
            capture: :all_but_first
          )
        )
        |> List.flatten()
      end)
      |> Enum.sort()

    assert tagged_tests == Enum.sort(@phase41_tagged_tests)
    assert length(tagged_tests) == 3
    assert @phase41_broad_tests == 1_622
    assert @phase41_broad_tests + length(tagged_tests) == @phase41_non_host_tests
    assert @phase41_non_host_tests + @phase41_host_tests == 1_699

    assert_verify_alias_partition_contract!()

    phase41_commands =
      @workflow
      |> File.read!()
      |> String.split("      - name: Run Phase 41 gating doctor and support matrix proof\n",
        parts: 2
      )
      |> List.last()
      |> String.split("      - name: Summarize Phase 41 gating proof\n", parts: 2)
      |> List.first()

    dedicated = "mix " <> @phase41_dedicated_command
    broad = "mix " <> @phase41_hosted_broad_command

    assert length(:binary.matches(phase41_commands, dedicated)) == 1
    assert length(:binary.matches(phase41_commands, broad)) == 1
    assert :binary.match(phase41_commands, dedicated) < :binary.match(phase41_commands, broad)
    assert phase41_commands =~ "mix test test/crosswake/proof/phase41_gating_doctor_test.exs"
  end

  defp assert_verify_alias_partition_contract! do
    aliases = aliases_from_mix_project!()
    companion_commands = Keyword.fetch!(aliases, :"companions.test")
    verify_commands = Keyword.fetch!(aliases, :verify)

    assert companion_commands == @companion_commands

    assert_verify_commands!(
      [
        "companions.test",
        @phase41_dedicated_command,
        @phase41_alias_broad_command
      ],
      verify_commands
    )

    for mutation <- [
          ["companions.test", @phase41_alias_broad_command],
          [
            "companions.test",
            @phase41_dedicated_command,
            @phase41_dedicated_command,
            @phase41_alias_broad_command
          ],
          [
            "companions.test",
            @phase41_alias_broad_command,
            @phase41_dedicated_command
          ],
          [
            "companions.test",
            @phase41_dedicated_command,
            String.replace(@phase41_alias_broad_command, "--exclude phase41_nested_process ", "")
          ]
        ] do
      assert_raise ExUnit.AssertionError, fn ->
        assert_verify_commands!(
          [
            "companions.test",
            @phase41_dedicated_command,
            @phase41_alias_broad_command
          ],
          mutation
        )
      end
    end
  end

  defp aliases_from_mix_project! do
    @mix_project
    |> File.read!()
    |> Code.string_to_quoted!()
    |> Macro.prewalk(nil, fn
      {:defp, _, [{:aliases, _, _}, [do: aliases]]} = node, nil when is_list(aliases) ->
        {node, aliases}

      node, acc ->
        {node, acc}
    end)
    |> elem(1)
    |> case do
      aliases when is_list(aliases) -> aliases
      nil -> flunk("mix.exs must define a literal aliases/0 keyword list")
    end
  end

  defp assert_verify_commands!(expected, actual) do
    assert actual == expected,
           "mix verify must serialize the exact Phase41 three-test selection before the broad 1,622-test selection"
  end

  defp run_gate(tmp, markers) do
    bin = Path.join(tmp, "bin-#{System.unique_integer([:positive])}")
    destination = Path.join(tmp, "retained-#{System.unique_integer([:positive])}")
    real_mix = System.find_executable("mix")

    assert is_binary(real_mix)

    File.mkdir_p!(bin)
    write_shims(bin)

    System.cmd("bash", [@script, destination],
      cd: File.cwd!(),
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"CROSSWAKE_REAL_MIX", real_mix},
        {"CROSSWAKE_FIXTURE_MARKERS", Enum.map_join(markers, "\n", &"#{&1}: passed")}
      ],
      stderr_to_stdout: true
    )
  end

  defp write_shims(bin) do
    File.write!(
      Path.join(bin, "mix"),
      "#!/usr/bin/env bash\nif [ \"${1:-}\" = run ]; then exec \"$CROSSWAKE_REAL_MIX\" \"$@\"; fi\nexit 0\n"
    )

    File.write!(Path.join(bin, "node"), "#!/usr/bin/env bash\nexit 0\n")
    File.write!(Path.join(bin, "swift"), "#!/usr/bin/env bash\nexit 0\n")

    File.write!(
      Path.join(bin, "xcrun"),
      "#!/usr/bin/env bash\necho 'iPhone fixture (fixture-id) (Booted)'\n"
    )

    File.write!(
      Path.join(bin, "xcodebuild"),
      """
      #!/usr/bin/env bash
      set -eu
      for test_name in #{@host_tests |> Enum.map(&"'#{&1}'") |> Enum.join(" ")}; do
        echo "Test Case '$test_name' passed"
      done
      printf '%s\\n' "$CROSSWAKE_FIXTURE_MARKERS"
      echo 'fixture-transcript-canary' >&2
      exit 0
      """
    )

    for executable <- ["mix", "node", "swift", "xcrun", "xcodebuild"] do
      File.chmod!(Path.join(bin, executable), 0o700)
    end
  end

  defp with_phase41_nested_process_tracer(owner, fun) do
    case System.get_env("CROSSWAKE_PHASE41_ADVERSARIAL_ROOT") do
      nil ->
        with_phase41_nested_process_lease(fun)

      root ->
        with_phase41_nested_process_lease(fn ->
          File.mkdir_p!(root)
          File.write!(Path.join(root, "ready-#{owner}"), "ready")
          await_phase41_peer(root, 100)

          case File.open(Path.join(root, "nested-process.lease"), [:write, :exclusive]) do
            {:ok, lease} ->
              try do
                fun.()
              after
                File.close(lease)
                File.rm(Path.join(root, "nested-process.lease"))
              end

            {:error, :eexist} ->
              flunk("PHASE41-NESTED-PROCESS-CONTENTION: phase41_resource_contention")
          end
        end)
    end
  end

  defp with_phase41_nested_process_lease(fun) do
    :global.trans({Crosswake.Proof.Phase41NestedProcessLease, self()}, fun)
  end

  defp await_phase41_peer(_root, 0), do: :ok

  defp await_phase41_peer(root, attempts) do
    if length(Path.wildcard(Path.join(root, "ready-*"))) >= 2 do
      :ok
    else
      Process.sleep(10)
      await_phase41_peer(root, attempts - 1)
    end
  end
end
