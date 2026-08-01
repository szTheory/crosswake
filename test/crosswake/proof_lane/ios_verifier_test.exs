defmodule Crosswake.ProofLane.IosVerifierTest do
  use ExUnit.Case, async: false

  @script Path.expand("../../../script/verify_generated_ios_shell.sh", __DIR__)

  setup do
    root = Path.join(System.tmp_dir!(), "ios-verifier-#{System.unique_integer([:positive])}")
    bin = Path.join(root, "bin")
    project = Path.join(root, "native/ios")
    File.mkdir_p!(bin)
    File.mkdir_p!(project)
    File.write!(Path.join(project, "CrosswakeProofLane.xcodeproj"), "fixture")

    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, bin: bin, project: project}
  end

  test "proof lane reports closed unavailable, blocked, and passed outcomes", %{bin: bin, project: project} do
    for {mode, expected_outcome, expected_status} <- [
          {"list-fail", "unavailable", 3},
          {"missing-target", "blocked", 2},
          {"build-fail", "blocked", 2},
          {"test-fail", "blocked", 2},
          {"success", "passed", 0}
        ] do
      write_xcodebuild(bin)

      {output, status} =
        System.cmd("bash", [@script, "--proof-lane"],
          stderr_to_stdout: true,
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH")},
            {"CROSSWAKE_IOS_PROJECT_ROOT", project},
            {"CROSSWAKE_IOS_SHIM_MODE", mode}
          ]
        )

      assert status == expected_status
      assert {:ok, %{"outcome" => ^expected_outcome, "rule_id" => rule_id, "scope" => scope}} =
               Jason.decode(String.trim(output))
      assert String.starts_with?(rule_id, "PL-IOS-")
      assert scope in ["generated-target-graph", "generated-proof-targets"]
    end
  end

  test "proof-lane missing xcodebuild is unavailable and non-passing", %{project: project} do
    {output, status} =
      System.cmd("bash", [@script, "--proof-lane"],
        stderr_to_stdout: true,
        env: [
          {"PATH", "/usr/bin:/bin"},
          {"CROSSWAKE_IOS_XCODEBUILD_BIN", "crosswake-missing-xcodebuild"},
          {"CROSSWAKE_IOS_PROJECT_ROOT", project}
        ]
      )

    assert status == 3
    assert {:ok, %{"outcome" => "unavailable", "rule_id" => "PL-IOS-XCODEBUILD", "scope" => "generated-proof-targets"}} =
             Jason.decode(String.trim(output))
  end

  defp write_xcodebuild(bin) do
    path = Path.join(bin, "xcodebuild")

    File.write!(path, """
    #!/usr/bin/env bash
    case "${CROSSWAKE_IOS_SHIM_MODE:-success}" in
      list-fail)
        echo "sensitive tool output"
        exit 1
        ;;
      missing-target)
        echo "CrosswakeProofLaneTests"
        exit 0
        ;;
      build-fail)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
          exit 0
        fi
        if [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
          exit 0
        fi
        echo "sensitive build output"
        exit 1
        ;;
      test-fail)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
          exit 0
        fi
        if [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
          exit 0
        fi
        if [[ " $* " == *" test-without-building "* ]]; then
          echo "sensitive test failure"
          exit 1
        fi
        exit 0
        ;;
      success)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
        elif [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
        elif [[ " $* " == *" test-without-building "* ]]; then
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testHostAdapterContract]' passed."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testLifecycleRefresh]' passed."
        fi
        exit 0
        ;;
    esac
    """)

    File.chmod!(path, 0o755)
  end
end
