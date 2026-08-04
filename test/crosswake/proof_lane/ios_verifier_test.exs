defmodule Crosswake.ProofLane.IosVerifierTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator}

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

  test "proof lane requires exact adapter-backed test evidence before passing", %{
    bin: bin,
    project: project
  } do
    for {mode, expected_outcome, expected_status} <- [
          {"list-fail", "unavailable", 3},
          {"missing-target", "blocked", 2},
          {"build-fail", "blocked", 2},
          {"test-fail", "blocked", 2},
          {"generic-success", "blocked", 2},
          {"adapter-evidence", "blocked", 2}
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
      assert scope in ["generated-target-graph", "generated-proof-targets", "pack_audio_prerequisite"]
    end
  end

  test "reference-pack mode passes only with exact structured operation evidence and remains advisory", %{
    bin: bin,
    project: project
  } do
    write_xcodebuild(bin)

    {output, status} =
      System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
        stderr_to_stdout: true,
        env: [
          {"PATH", bin <> ":" <> System.get_env("PATH")},
          {"CROSSWAKE_IOS_PROJECT_ROOT", project},
          {"CROSSWAKE_IOS_SHIM_MODE", "structured-evidence"}
        ]
      )

    assert status == 0

    assert {:ok,
            %{
              "outcome" => "passed",
              "scope" => "pack_audio_prerequisite",
              "rule_id" => "PL-IOS-PACK-AUDIO-ADVISORY"
            }} = Jason.decode(String.trim(output))
  end

  test "reference-pack mode rejects incomplete or reordered current-run provenance", %{
    bin: bin,
    project: project
  } do
    for mode <- [
          "legacy-evidence",
          "missing-denial",
          "extra-evidence",
          "duplicate-evidence",
          "reordered-evidence",
          "missing-reset",
          "marker-only",
          "duplicate-current-run",
          "reordered-current-run"
        ] do
      write_xcodebuild(bin)

      {output, status} =
        System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
          stderr_to_stdout: true,
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH")},
            {"CROSSWAKE_IOS_PROJECT_ROOT", project},
            {"CROSSWAKE_IOS_SHIM_MODE", mode}
          ]
        )

      assert status == 2
      assert {:ok, %{"outcome" => "blocked", "rule_id" => "PL-IOS-TEST-EVIDENCE"}} =
               Jason.decode(String.trim(output))
    end
  end

  test "proof-lane missing xcodebuild is unavailable and non-passing", %{project: project} do
    {output, status} =
      System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
        stderr_to_stdout: true,
        env: [
          {"PATH", "/usr/bin:/bin"},
          {"CROSSWAKE_IOS_XCODEBUILD_BIN", "crosswake-missing-xcodebuild"},
          {"CROSSWAKE_IOS_PROJECT_ROOT", project}
        ]
      )

    assert status == 3

    assert {:ok,
            %{
              "outcome" => "unavailable",
              "rule_id" => "PL-IOS-XCODEBUILD",
              "scope" => "generated-proof-targets"
            }} =
             Jason.decode(String.trim(output))
  end

  test "untouched generated lane with a nil host factory is blocked rather than passed", %{
    bin: bin,
    root: root
  } do
    target = Path.join(root, "generated")
    File.mkdir_p!(target)

    config = %Config{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: Path.join(target, "native/ios")
    }

    assert {:ok, _} = Generator.generate(config)

    assert File.read!(
             Path.join(config.ios_shell_root, "CrosswakeProofLane/ProofLaneDriver.swift")
           ) =~
             "nil"

    write_xcodebuild(bin)

    {output, status} =
      System.cmd("bash", [@script, "--proof-lane"],
        stderr_to_stdout: true,
        env: [
          {"PATH", bin <> ":" <> System.get_env("PATH")},
          {"CROSSWAKE_IOS_PROJECT_ROOT", config.ios_shell_root},
          {"CROSSWAKE_IOS_SHIM_MODE", "generic-success"}
        ]
      )

    assert status == 2

    assert {:ok,
            %{
              "outcome" => "blocked",
              "rule_id" => "PL-IOS-TEST-EVIDENCE",
              "scope" => "generated-proof-targets"
            }} = Jason.decode(String.trim(output))
  end

  test "proof lane leaves configured global git and swiftpm files byte-identical", %{
    bin: bin,
    project: project,
    root: root
  } do
    write_xcodebuild(bin)
    home = Path.join(root, "home")
    git_config = Path.join(home, ".gitconfig")
    swiftpm_config = Path.join(home, ".swiftpm/configuration/mirrors.json")
    File.mkdir_p!(Path.dirname(swiftpm_config))
    File.write!(git_config, "[user]\n\tname = untouched\n")
    File.write!(swiftpm_config, "{\"object\": []}\n")
    before_git = File.read!(git_config)
    before_swiftpm = File.read!(swiftpm_config)

    {output, status} =
      System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
        stderr_to_stdout: true,
        env: [
          {"HOME", home},
          {"PATH", bin <> ":" <> System.get_env("PATH")},
          {"CROSSWAKE_IOS_PROJECT_ROOT", project},
          {"CROSSWAKE_IOS_SHIM_MODE", "structured-evidence"},
          {"CROSSWAKE_IOS_USE_LOCAL_CORE", "1"}
        ]
      )

    assert status == 0, output
    assert {:ok, %{"outcome" => "passed"}} = Jason.decode(String.trim(output))
    assert File.read!(git_config) == before_git
    assert File.read!(swiftpm_config) == before_swiftpm
  end

  test "verifier uses private DerivedData for every xcodebuild invocation", %{bin: bin, project: project, root: root} do
    trace = Path.join(root, "xcodebuild-trace")
    run_root = Path.join(root, "caller-run-root")
    write_xcodebuild(bin)

    {output, status} =
      System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
        stderr_to_stdout: true,
        env: [
          {"PATH", bin <> ":" <> System.get_env("PATH")},
          {"TMPDIR", root},
          {"CROSSWAKE_IOS_PROJECT_ROOT", project},
          {"CROSSWAKE_IOS_RUN_ROOT", run_root},
          {"CROSSWAKE_IOS_XCODEBUILD_TRACE", trace},
          {"CROSSWAKE_IOS_SHIM_MODE", "structured-evidence"}
        ]
      )

    assert status == 0, output
    assert {:ok, %{"outcome" => "passed"}} = Jason.decode(String.trim(output))
    assert File.read!(trace) =~ "-list"
    assert File.read!(trace) =~ "-showdestinations"
    assert File.read!(trace) =~ "build-for-testing"
    assert File.read!(trace) =~ "test-without-building"
    assert File.read!(trace) =~ "-derivedDataPath #{run_root}/DerivedData"
    refute File.exists?(run_root)
  end

  test "verifier cleans caller run root after structured success and failures", %{bin: bin, project: project, root: root} do
    for mode <- ["structured-evidence", "list-fail", "build-fail", "test-fail"] do
      run_root = Path.join(root, "caller-run-root-#{mode}")
      write_xcodebuild(bin)

      {_output, _status} =
        System.cmd("bash", [@script, "--proof-lane", "--reference-pack-adapter"],
          stderr_to_stdout: true,
          env: [
            {"PATH", bin <> ":" <> System.get_env("PATH")},
            {"TMPDIR", root},
            {"CROSSWAKE_IOS_PROJECT_ROOT", project},
            {"CROSSWAKE_IOS_RUN_ROOT", run_root},
            {"CROSSWAKE_IOS_SHIM_MODE", mode}
          ]
        )

      refute File.exists?(run_root), "expected cleanup after #{mode}"
    end
  end

  defp write_xcodebuild(bin) do
    path = Path.join(bin, "xcodebuild")

    File.write!(path, """
    #!/usr/bin/env bash
    if [[ -n "${CROSSWAKE_IOS_XCODEBUILD_TRACE:-}" ]]; then
      printf '%q ' "$@" >> "$CROSSWAKE_IOS_XCODEBUILD_TRACE"
      printf '\n' >> "$CROSSWAKE_IOS_XCODEBUILD_TRACE"
    fi
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
      generic-success)
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
      adapter-evidence)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
        elif [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
        elif [[ " $* " == *" test-without-building "* ]]; then
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testMissingAdapterRemainsUnavailable]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testFixtureInstallReconcilesAfterRelaunch]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testWrongRequirementAndFailedAudioRemainNonPassing]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testUnexpectedNetworkObservationBlocksAudioAndEmitsNoEvidence]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testMissingProviderInstallRelaunchAndOfflineAudio]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testAccessibilityReflowContract]' passed (0.001 seconds)."
        fi
        exit 0
        ;;
      structured-evidence)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
        elif [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
        elif [[ " $* " == *" test-without-building "* ]]; then
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testMissingAdapterRemainsUnavailable]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testFixtureInstallReconcilesAfterRelaunch]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testWrongRequirementAndFailedAudioRemainNonPassing]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testUnexpectedNetworkObservationBlocksAudioAndEmitsNoEvidence]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testMissingProviderInstallRelaunchAndOfflineAudio]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testAccessibilityReflowContract]' passed (0.001 seconds)."
          echo "PACK-RESET-BLOCKED"
          echo "PACK-INSTALL-READY"
          echo "PACK-RELAUNCH-READY"
          echo "PACK-AUDIO-OFFLINE"
          echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","installed_audio_read"],"outcome":"passed","schema_version":2}'
        fi
        exit 0
        ;;
      legacy-evidence|missing-denial|extra-evidence|duplicate-evidence|reordered-evidence|missing-reset|marker-only|duplicate-current-run|reordered-current-run)
        if [[ " $* " == *" -list "* ]]; then
          echo "CrosswakeProofLaneTests"
          echo "CrosswakeProofLaneUITests"
        elif [[ " $* " == *" -showdestinations "* ]]; then
          echo "{ platform:iOS Simulator, id:FAKE-IPHONE-ID, OS:18.0, name:iPhone 16 }"
        elif [[ " $* " == *" test-without-building "* ]]; then
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testMissingAdapterRemainsUnavailable]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testFixtureInstallReconcilesAfterRelaunch]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneTests.ProofLaneContractTests testWrongRequirementAndFailedAudioRemainNonPassing]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testMissingProviderInstallRelaunchAndOfflineAudio]' passed (0.001 seconds)."
          echo "Test Case '-[CrosswakeProofLaneUITests.ProofLaneUITests testAccessibilityReflowContract]' passed (0.001 seconds)."
          case "${CROSSWAKE_IOS_SHIM_MODE}" in
            legacy-evidence) echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","networking_disabled","installed_audio_read"],"outcome":"passed","schema_version":1}' ;;
            missing-denial) echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","installed_audio_read"],"outcome":"passed","schema_version":2}' ;;
            extra-evidence) echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","installed_audio_read","extra"],"outcome":"passed","schema_version":2}' ;;
            duplicate-evidence) echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","network_operation_denied","installed_audio_read"],"outcome":"passed","schema_version":2}' ;;
            reordered-evidence) echo '{"assertion_ids":["fixture_acquired","network_operation_denied","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","installed_audio_read"],"outcome":"passed","schema_version":2}' ;;
            missing-reset)
              echo "PACK-INSTALL-READY"
              echo "PACK-RELAUNCH-READY"
              echo "PACK-AUDIO-OFFLINE"
              echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","installed_audio_read"],"outcome":"passed","schema_version":2}'
              ;;
            marker-only)
              echo "PACK-RESET-BLOCKED"
              echo "PACK-INSTALL-READY"
              echo "PACK-RELAUNCH-READY"
              echo "PACK-AUDIO-OFFLINE"
              ;;
            duplicate-current-run)
              echo "PACK-RESET-BLOCKED"
              echo "PACK-INSTALL-READY"
              echo "PACK-INSTALL-READY"
              echo "PACK-RELAUNCH-READY"
              echo "PACK-AUDIO-OFFLINE"
              echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","installed_audio_read"],"outcome":"passed","schema_version":2}'
              ;;
            reordered-current-run)
              echo "PACK-INSTALL-READY"
              echo "PACK-RESET-BLOCKED"
              echo "PACK-RELAUNCH-READY"
              echo "PACK-AUDIO-OFFLINE"
              echo '{"assertion_ids":["fixture_acquired","exact_integrity_verified","atomic_promotion_completed","relaunch_artifact_readback","network_operation_denied","installed_audio_read"],"outcome":"passed","schema_version":2}'
              ;;
          esac
        fi
        exit 0
        ;;
    esac
    """)

    File.chmod!(path, 0o755)
  end
end
