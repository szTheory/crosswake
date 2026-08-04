defmodule Crosswake.Proof.Phase161_1NavigationGateIntegrityTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.NavigationShellAdvisory

  @script "scripts/verify_phase_161_1.sh"
  @host_tests ~w(
    testOrderedProductionNavigationProofEmitsClosedMarkers
    testProductionContainerAuthorizesRootsAndMirrorsOneNavigateWithoutDuplicate
    testPatchAndCancelledThenCompletedPopPreserveProductionStackAndFocus
    testDocumentStartShellContractUsesOnlyFixedMarkerAndFiveDefaults
    testLayoutDeliveryKeepsFourSafeAreaFactsSeparateFromKeyboard
    testSyntheticProductionNavigationFlow
  )

  @tag :tmp_dir
  test "a zero-exit host run with passed names cannot promote without every ordered marker", %{tmp_dir: tmp} do
    assert_marker_failure(tmp, Enum.drop(NavigationShellAdvisory.assertion_ids(), -1))
    assert_marker_failure(tmp, NavigationShellAdvisory.assertion_ids() ++ [List.last(NavigationShellAdvisory.assertion_ids())])
    assert_marker_failure(tmp, Enum.reverse(NavigationShellAdvisory.assertion_ids()))
  end

  @tag :tmp_dir
  test "the exact marker fixture advances past transcript reduction", %{tmp_dir: tmp} do
    {output, status} = run_gate(tmp, NavigationShellAdvisory.assertion_ids())

    assert status == 0, "expected exact markers to advance, got #{status}: #{output}"
    refute output =~ "PL-IOS-NAV-HOST-MARKER"
  end

  defp assert_marker_failure(tmp, markers) do
    {output, status} = run_gate(tmp, markers)

    assert status != 0
    assert output =~ "PL-IOS-NAV-HOST-MARKER: host-markers"
    refute output =~ "fixture-transcript-canary"
  end

  defp run_gate(tmp, markers) do
    bin = Path.join(tmp, "bin-#{System.unique_integer([:positive])}")
    destination = Path.join(tmp, "retained-#{System.unique_integer([:positive])}")
    File.mkdir_p!(bin)
    write_shims(bin)

    System.cmd("bash", [@script, destination],
      cd: File.cwd!(),
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH", "")},
        {"CROSSWAKE_FIXTURE_MARKERS", Enum.map_join(markers, "\n", &"#{&1}: passed")}
      ],
      stderr_to_stdout: true
    )
  end

  defp write_shims(bin) do
    File.write!(
      Path.join(bin, "mix"),
      "#!/usr/bin/env bash\nif [ \"${1:-}\" = run ]; then exec /opt/homebrew/bin/mix \"$@\"; fi\nexit 0\n"
    )
    File.write!(Path.join(bin, "node"), "#!/usr/bin/env bash\nexit 0\n")
    File.write!(Path.join(bin, "swift"), "#!/usr/bin/env bash\nexit 0\n")

    File.write!(Path.join(bin, "xcrun"), "#!/usr/bin/env bash\necho 'iPhone fixture (fixture-id) (Booted)'\n")

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
end
