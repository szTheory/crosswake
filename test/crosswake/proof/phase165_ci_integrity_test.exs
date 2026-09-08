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
  @phase5 ".github/workflows/phase5-proof.yml"
  @phase18 ".github/workflows/phase18-proof.yml"
  @phase79 ".github/workflows/phase79-proof.yml"
  @release_please ".github/workflows/release-please.yml"

  @task1_retired_workflows [
    ".github/workflows/aggregator-negative-control.yml",
    ".github/workflows/contract-drift-gate.yml",
    ".github/workflows/dependency-security.yml",
    ".github/workflows/requires-example-host-gate.yml"
  ]

  @tag :triggers
  test "core integrity proof has one pull-request producer in Crosswake CI" do
    workflow = File.read!(@crosswake_ci)

    for path <- @task1_retired_workflows do
      refute File.exists?(path), "#{path} must be retired after its PR proof moves"
    end

    for {job, display_name, command} <- [
          {"proof-aggregator-negative-control", "proof-aggregator-negative-control",
           "python3 script/check_aggregator_result_semantics.py --assert-outcomes"},
          {"guard-01-contract-drift-test", "guard-01-contract-drift-test",
           "mix test test/crosswake/contract/contract_drift_test.exs"},
          {"guard-02-generate-and-diff", "guard-02-generate-and-diff",
           "mix crosswake.contract.gen"},
          {"proof-dependency-security", "proof-dependency-security",
           "script/check_dependency_security.sh"},
          {"proof-requires-example-host", "proof-requires-example-host",
           "script/check_example_host_isolation.sh --matrix-only"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    for {job, display_name, need} <- [
          {"compat-aggregator-negative-control", "merge-blocking-aggregator-negative-control",
           "proof-aggregator-negative-control"},
          {"compat-contract-drift", "merge-blocking-contract-drift",
           "guard-01-contract-drift-test"},
          {"compat-dependency-security", "merge-blocking-dependency-security",
           "proof-dependency-security"},
          {"compat-requires-example-host", "merge-blocking-requires-example-host",
           "proof-requires-example-host"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "needs:"
      assert body =~ need
      refute body =~ "actions/checkout"
    end

    contract = job_body(workflow, "compat-contract-drift")
    assert contract =~ "guard-02-generate-and-diff"
    assert contract =~ "if: always()"
    assert contract =~ "python3"
  end

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
    assert setup =~ "runner.arch"
    assert setup =~ "inputs.java-version"
    assert setup =~ "steps.wrapper.outputs.version"
    assert setup =~ "steps.compatibility.outputs.digest"
    assert setup =~ "gradle.lockfile"
    assert setup =~ "*.gradle"
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
    build_cache = between(action, "    - id: build-cache", "    # Hex TARBALL cache")
    refute build_cache =~ "restore-keys"
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

  @tag :runner_placement
  test "mixed legacy proof keeps only Apple invocations on macOS" do
    phase5 = File.read!(@phase5)
    phase18 = File.read!(@phase18)
    phase79 = File.read!(@phase79)

    assert job_body(phase5, "phase5-proof") =~ "runs-on: ubuntu-latest"
    refute phase5 =~ "DEVELOPER_DIR"

    assert job_body(phase18, "phase18-portable-proof") =~ "runs-on: ubuntu-latest"
    assert job_body(phase18, "phase18-portable-proof") =~ "verify_generated_android_shell.sh"
    assert job_body(phase18, "phase18-proof") =~ "runs-on: macos-15"
    assert job_body(phase18, "phase18-proof") =~ "verify_generated_ios_shell.sh"
    refute job_body(phase18, "phase18-portable-proof") =~ "DEVELOPER_DIR"

    assert job_body(phase79, "v5-android-jvm-proof") =~ "runs-on: ubuntu-latest"
    assert job_body(phase79, "merge-blocking-v5-proof") =~ "runs-on: macos-15"
    assert job_body(phase79, "merge-blocking-v5-proof") =~ "verify_generated_ios_shell.sh"
    refute job_body(phase79, "merge-blocking-v5-proof") =~ "verify_generated_android_shell.sh"
  end

  @tag :runner_placement
  @tag timeout: 60_000
  test "every workflow job is bounded and every macOS job invokes native tooling" do
    for path <- Path.wildcard(".github/workflows/*.{yml,yaml}"),
        {job, body} <- workflow_jobs(File.read!(path)) do
      assert body =~ ~r/^    timeout-minutes:\s*[1-9][0-9]*\s*$/m,
             "#{path}:#{job} must have a positive job timeout"

      if body =~ ~r/^    runs-on:\s*macos/m do
        assert body =~
                 ~r/(?:\bswift\b|\bxcodebuild\b|\bxcrun\b|\bcodesign\b|simulator|emulator|verify_generated_ios_shell)/i,
               "#{path}:#{job} uses macOS without a native tool invocation"
      end
    end
  end

  @tag timeout: 60_000
  test "ordinary CI never retries an assertion command" do
    assertion =
      ~r/(?:mix test|swift (?:test|build)|gradlew .*?(?:test|build)|xcodebuild|script\/[^\s]*(?:proof|verify))/

    for path <- Path.wildcard(".github/workflows/*.{yml,yaml}"),
        path != @release_please,
        {job, body} <- workflow_jobs(File.read!(path)),
        script <- run_scripts(body) do
      retry_loop = script =~ ~r/(?:for\s+[^\n]+;\s*do|while\s+)/

      refute retry_loop and script =~ assertion,
             "#{path}:#{job} retries a proof/test/assertion command"
    end
  end

  @tag :release_trust
  test "Release Please retains non-cancelling queue and approval-aware publish authority" do
    workflow = File.read!(@release_please)

    assert workflow =~
             ~r/concurrency:\n  group: release-please-.*\n  cancel-in-progress: false\n  queue: max/

    refute workflow =~ ~r/concurrency:\n(?:  .*\n)*?  cancel-in-progress: true/
    assert workflow =~ "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
    assert workflow =~ "MAVEN_USERNAME: ${{ secrets.ORG_GRADLE_PROJECT_mavenCentralUsername }}"
    assert workflow =~ "MIRROR_DEPLOY_KEY: ${{ secrets.MIRROR_DEPLOY_KEY }}"
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

  defp workflow_jobs(workflow) do
    [_prefix, jobs] = String.split(workflow, ~r/^jobs:\s*$/m, parts: 2)

    Regex.scan(~r/^  ([a-zA-Z0-9_-]+):\s*\n(.*?)(?=^  [a-zA-Z0-9_-]+:\s*$|\z)/ms, jobs,
      capture: :all_but_first
    )
    |> Enum.map(fn [job, body] -> {job, body} end)
  end

  defp run_scripts(job_body) do
    Regex.scan(
      ~r/^      run:\s*(?:\|\s*\n(?<block>(?:        .*\n?)*)|(?<inline>.+))$/m,
      job_body,
      capture: :all_names
    )
    |> Enum.map(fn [block, inline] -> if block == "", do: inline, else: block end)
  end

  defp cache_identity(fixture) do
    encoded = fixture |> Enum.sort() |> :erlang.term_to_binary()
    :crypto.hash(:sha256, encoded)
  end
end
