defmodule Crosswake.Proof.Phase165CiIntegrityTest do
  @moduledoc """
  Structural CI trust-boundary proof for Phase 165.
  """
  use ExUnit.Case, async: true

  @controller ".github/workflows/cancel-obsolete-crosswake-ci.yml"
  @crosswake_ci ".github/workflows/crosswake-ci.yml"
  @native_workflow ".github/workflows/native-behavioral-proof-gate.yml"
  @android_script "script/verify_generated_android_shell.sh"
  @android_setup ".github/actions/setup-android-jvm/action.yml"
  @elixir_setup ".github/actions/setup-elixir-cache/action.yml"

  @tag :cancellation_controller
  test "controller is requested-run-only and grants no permission beyond Actions mutation" do
    workflow = File.read!(@controller)

    assert workflow =~
             ~r/^on:\n  workflow_run:\n    workflows: \[Crosswake CI\]\n    types: \[requested\]$/m

    assert workflow =~ ~r/^permissions:\n  actions: write$/m
    refute workflow =~ "pull_request_target"
    refute workflow =~ ~r/^\s+(contents|issues|pull-requests|checks|packages): write$/m
    refute workflow =~ "write-all"
    refute workflow =~ "secrets."
  end

  @tag :cancellation_controller
  test "controller consumes immutable default-branch policy and never checks out PR code" do
    workflow = File.read!(@controller)

    refute workflow =~ "actions/checkout"
    refute workflow =~ "github.event.workflow_run.head_sha"
    refute workflow =~ "github.event.workflow_run.head_repository"
    assert workflow =~ "${GITHUB_REPOSITORY}/${GITHUB_SHA}/script/select_obsolete_ci_runs.py"
    assert workflow =~ "--repository \"$GITHUB_REPOSITORY\""
    assert workflow =~ "--workflow-name 'Crosswake CI'"
    assert workflow =~ "pagination_complete"
  end

  @tag :cancellation_controller
  test "strict-lower selection is a hard gate before bounded cancel and force-cancel" do
    workflow = File.read!(@controller)

    select_at = byte_offset(workflow, "id: select")
    gate_at = byte_offset(workflow, "steps.select.outputs.disposition == 'cancel_lower'")
    cancel_at = byte_offset(workflow, ~s(actions/runs/$run_id/cancel"))
    poll_at = byte_offset(workflow, "poll_attempt")
    force_at = byte_offset(workflow, ~s(actions/runs/$run_id/force-cancel"))

    assert select_at < gate_at
    assert gate_at < cancel_at
    assert cancel_at < poll_at
    assert poll_at < force_at
    assert workflow =~ "timeout-minutes: 10"
    assert workflow =~ "steps.select.outputs.run_ids != '[]'"
    assert workflow =~ "closed disposition"
    refute workflow =~ ~r/\b(retry|rerun|re-run)\b.*\b(test|proof|assert)/i
  end

  @tag :cancellation_controller
  test "ordinary PR concurrency remains repository-and-PR scoped and non-cancelling" do
    workflow = File.read!(@crosswake_ci)

    assert workflow =~
             "group: crosswake-ci-${{ github.repository }}-pr-${{ github.event.pull_request.number }}"

    assert workflow =~ "cancel-in-progress: false"
    refute workflow =~ "cancel-in-progress: true"
  end

  @tag :runner_placement
  test "generated Android JVM proof has a portable branch before connected provisioning" do
    script = File.read!(@android_script)
    main = between(script, "main() {", ~s(main "$@"))

    portable_at = byte_offset(main, ~s([[ "${RUN_CONNECTED_TESTS}" == "0" ]]))
    connected_at = byte_offset(main, "install_connected_android_toolchain")

    assert portable_at < connected_at
    assert script =~ "run_generated_shell_jvm_proof"

    portable = function_body(script, "run_generated_shell_jvm_proof")

    for forbidden <- [
          "commandlinetools-mac",
          "brew",
          "/Applications",
          "Contents/Home",
          "DEVELOPER_DIR",
          "simulator",
          "emulator",
          "adb",
          "sdkmanager",
          "avdmanager"
        ] do
      refute portable =~ forbidden
    end
  end

  @tag :runner_placement
  test "Android JVM jobs use Ubuntu and the shared JDK 17 Gradle wrapper setup" do
    workflow = File.read!(@native_workflow)
    setup = File.read!(@android_setup)

    for job <- ["android-package-unit", "android-generated-shell-unit"] do
      body = job_body(workflow, job)
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "timeout-minutes:"
      assert body =~ "uses: ./.github/actions/setup-android-jvm"
    end

    assert setup =~ "working-directory:"
    assert setup =~ "java-version:"
    assert setup =~ ~r/java-version:\n(?:    .*\n)*?    default: "17"/
    assert setup =~ "gradle-version:"
    assert setup =~ "actions/setup-java@v5"
    assert setup =~ "gradle/actions/setup-gradle@v6"
    assert setup =~ "gradle-wrapper.properties"
    refute setup =~ "actions/cache"
  end

  @tag :cache_identity
  test "compiled cache identity misses when any compatibility dimension changes" do
    fixtures = %{
      beam: %{
        dependency_scope: "root",
        os: "Linux",
        architecture: "X64",
        otp: "27.3",
        elixir: "1.19.5",
        mix_env: "test",
        topology: "Native-android-package-unit",
        dependency_topology: "mix-exs-a",
        lock: "mix-lock-a"
      },
      gradle: %{
        jdk: "17",
        gradle: "8.12.1",
        os: "Linux",
        architecture: "X64",
        wrapper: "wrapper-a",
        config: "gradle-config-a",
        lock: "gradle-lock-a"
      },
      swift: %{
        platform: "macOS",
        architecture: "ARM64",
        swift_xcode: "toolchain-a",
        manifest: "package-a",
        resolved_state: "absent"
      }
    }

    for {_cache, fixture} <- fixtures, {dimension, value} <- fixture do
      changed = Map.put(fixture, dimension, value <> "-changed")
      refute cache_identity(fixture) == cache_identity(changed), "#{dimension} must miss"
    end
  end

  @tag :cache_identity
  test "Elixir cache keeps topology and inert Hex boundaries with closed outcomes" do
    action = File.read!(@elixir_setup)

    for dimension <- [
          "steps.scope.outputs.value",
          "steps.topology.outputs.value",
          "runner.os",
          "runner.arch",
          "steps.beam.outputs.otp-version",
          "steps.beam.outputs.elixir-version",
          "inputs.mix-env",
          "mix.exs",
          "mix.lock"
        ] do
      assert action =~ dimension
    end

    assert action =~ "path: ~/.hex/packages"
    refute action =~ ~r/path:\s*~\/\.hex\s*$/m
    refute action =~ ~r/^\s*path:.*cache\.ets/m
    assert action =~ "cache-outcome"
    assert action =~ ~r/outcome=(exact|partial|miss)/
  end

  @tag :cache_identity
  test "Swift cache separates toolchains and present versus absent resolution" do
    workflow = File.read!(@native_workflow)
    body = job_body(workflow, "ios-package-unit")

    for dimension <- [
          "runner.os",
          "runner.arch",
          "swift --version",
          "xcodebuild -version",
          "Package.swift",
          "Package.resolved",
          "resolved-state"
        ] do
      assert body =~ dimension
    end

    assert body =~ ~r/resolved_state="absent"/
    assert body =~ ~r/resolved_state="present-/
  end

  defp byte_offset(value, needle) do
    case :binary.match(value, needle) do
      {offset, _length} -> offset
      :nomatch -> flunk("expected workflow marker #{inspect(needle)}")
    end
  end

  defp between(value, first, last) do
    [_prefix, rest] = String.split(value, first, parts: 2)
    [body, _suffix] = String.split(rest, last, parts: 2)
    body
  end

  defp job_body(workflow, job) do
    [_prefix, rest] = String.split(workflow, "  #{job}:", parts: 2)
    [body | _] = String.split(rest, ~r/^  [a-z0-9_-]+:/m, parts: 2)
    body
  end

  defp function_body(script, name) do
    case Regex.run(~r/^#{name}\(\) \{\n(?<body>.*?)^\}/ms, script, capture: :all_names) do
      [body] -> body
      nil -> flunk("expected shell function #{name}")
    end
  end

  defp cache_identity(fixture) do
    encoded = fixture |> Enum.sort() |> :erlang.term_to_binary()
    :crypto.hash(:sha256, encoded)
  end
end
