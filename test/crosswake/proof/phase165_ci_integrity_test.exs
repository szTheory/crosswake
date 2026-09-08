defmodule Crosswake.Proof.Phase165CiIntegrityTest do
  @moduledoc """
  Structural CI trust-boundary proof for Phase 165.
  """
  use ExUnit.Case, async: true

  @controller ".github/workflows/cancel-obsolete-crosswake-ci.yml"
  @crosswake_ci ".github/workflows/crosswake-ci.yml"
  @native_workflow @crosswake_ci
  @android_script "script/verify_generated_android_shell.sh"
  @android_setup ".github/actions/setup-android-jvm/action.yml"
  @elixir_setup ".github/actions/setup-elixir-cache/action.yml"
  @release_please ".github/workflows/release-please.yml"
  @leaf_manifest "script/ci_leaf_manifest.json"

  @plan06_task1_sources [
    ".github/workflows/phase41-proof.yml",
    ".github/workflows/phase43-proof.yml",
    ".github/workflows/phase45-proof.yml",
    ".github/workflows/phase48-proof.yml"
  ]

  @plan06_task2_sources [
    ".github/workflows/phase52-proof.yml",
    ".github/workflows/phase58-proof.yml",
    ".github/workflows/phase69-proof.yml",
    ".github/workflows/phase70-proof.yml"
  ]

  @plan07_sources [
    ".github/workflows/phase71-proof.yml",
    ".github/workflows/phase73-proof.yml",
    ".github/workflows/phase74-proof.yml",
    ".github/workflows/phase75-closeout-gate.yml"
  ]

  @plan08_task1_sources [
    ".github/workflows/native-behavioral-proof-gate.yml",
    ".github/workflows/phase5-proof.yml",
    ".github/workflows/phase18-proof.yml",
    ".github/workflows/phase79-proof.yml"
  ]

  @plan08_task2_retired_sources [
    ".github/workflows/offline-sync-e2e-gate.yml",
    ".github/workflows/phase67-proof.yml"
  ]

  @phase68_advisory ".github/workflows/phase68-proof.yml"

  @plan08_task3_sources [
    ".github/workflows/merge-blocking-ios-mirror-parity.yml",
    ".github/workflows/phase10-proof.yml",
    ".github/workflows/phase96-proof.yml"
  ]

  @plan09_retired_sources [
    ".github/workflows/brandbook-verify.yml",
    ".github/workflows/collateral-guard.yml",
    ".github/workflows/hex-page-proof.yml",
    ".github/workflows/release-as-staleness-gate.yml"
  ]

  @task1_retired_workflows [
    ".github/workflows/aggregator-negative-control.yml",
    ".github/workflows/contract-drift-gate.yml",
    ".github/workflows/dependency-security.yml",
    ".github/workflows/requires-example-host-gate.yml"
  ]

  @tag :triggers
  @tag :release_trust
  test "brand, collateral, Hex-page, and staleness PR proof have one explicit owner" do
    workflow = File.read!(@crosswake_ci)

    for path <- @plan09_retired_sources do
      refute File.exists?(path), "#{path} must be retired after replacement parity"
    end

    for {job, command} <- [
          {"brand-structural", "npm run test:structural"},
          {"collateral-binaries-guard", "bash script/collateral-guard.sh"},
          {"hex-page-proof", "mix hex.publish --dry-run --yes"},
          {"release-as-staleness-proof", "./script/check_release_as_staleness.sh"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "needs: [classify-change]"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    hex_page = job_body(workflow, "hex-page-proof")
    assert hex_page =~ "env:\n      MIX_ENV: dev"
    assert hex_page =~ "mix-env: dev"

    assert hex_page =~
             "name: Run library test suite (hermetic)\n        env:\n          MIX_ENV: test"

    assert hex_page =~ "name: Build docs (smoke)"
    assert hex_page =~ "mix docs"

    compatibility = job_body(workflow, "compat-release-as-staleness")
    assert compatibility =~ "name: merge-blocking-release-as-staleness"
    assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
    assert compatibility =~ "if: always()"
    refute compatibility =~ "actions/checkout"
  end

  @tag :triggers
  test "brand visual proof stays visibly red and outside required authority" do
    workflow = File.read!(@crosswake_ci)
    manifest = @leaf_manifest |> File.read!() |> Jason.decode!()
    visual = job_body(workflow, "brand-visual")
    umbrella = job_body(workflow, "merge-blocking-crosswake-ci")

    assert visual =~ "name: brand-visual"
    assert visual =~ "needs: [classify-change]"
    assert visual =~ "npm run test:visual"
    refute visual =~ "continue-on-error"
    refute visual =~ ~r/\|\|\s*true/
    refute visual =~ "if: always()"

    refute Enum.any?(manifest["proof_leaves"], &(&1["leaf_id"] == "brand-visual"))
    refute Enum.any?(manifest["required_control_nodes"], &(&1["node_id"] == "brand-visual"))

    refute Enum.any?(manifest["legacy_compatibility_contexts"], fn row ->
             row["job_id"] == "brand-visual" or row["needs_target"] == "brand-visual"
           end)

    refute umbrella =~ ~r/^      - brand-visual$/m
  end

  @tag :triggers
  @tag :runner_placement
  test "native and mixed proof moves once with exact platform ownership" do
    workflow = File.read!(@crosswake_ci)

    for path <- @plan08_task1_sources do
      refute File.exists?(path), "#{path} must be retired after replacement parity"
    end

    for {job, runner, command} <- [
          {"android-package-unit", "ubuntu-latest", "./gradlew test"},
          {"android-generated-shell-unit", "ubuntu-latest",
           "script/verify_generated_android_shell.sh"},
          {"phase5-proof", "ubuntu-latest", "script/verify_phase5_example_hosts.sh"},
          {"phase18-elixir-android-proof", "ubuntu-latest", "verify_phase18_contract.sh"},
          {"phase18-ios-proof", "macos-15", "verify_generated_ios_shell.sh"},
          {"phase79-android-proof", "ubuntu-latest", "verify_generated_android_shell.sh"},
          {"phase79-ios-proof", "macos-15", "verify_generated_ios_shell.sh"},
          {"ios-package-unit", "macos-latest", "swift test"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: #{runner}"
      assert body =~ command
      assert body =~ "needs: [classify-change]"
      assert body =~ "classification == 'full_proof'"
      assert body =~ "Remediation:"
    end

    compatibility = job_body(workflow, "compat-native-behavioral-proof")
    assert compatibility =~ "name: merge-blocking-native-behavioral-proof"
    assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
    assert compatibility =~ "if: always()"
    refute compatibility =~ "actions/checkout"
  end

  @tag :triggers
  @tag :runner_placement
  test "offline browser and Android JVM proof moves while emulator proof stays advisory" do
    workflow = File.read!(@crosswake_ci)

    for path <- @plan08_task2_retired_sources do
      refute File.exists?(path), "#{path} must be retired after replacement parity"
    end

    for {job, command} <- [
          {"guard-01-e2e-honesty", "node script/check-e2e-honesty.mjs"},
          {"guard-02-prod-route-absence", "mix phx.routes CrosswakeExample.Router"},
          {"e2e-proof", "npx playwright test"},
          {"route-tour-proof", "npx playwright test e2e/route_tour.spec.ts"},
          {"phase67-android-jvm-proof", "./gradlew testDebugUnitTest"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "needs: [classify-change]"
      assert body =~ "classification == 'full_proof'"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    compatibility = job_body(workflow, "compat-offline-sync-e2e")
    assert compatibility =~ "name: merge-blocking-offline-sync-e2e"
    assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
    assert compatibility =~ "if: always()"
    refute compatibility =~ "actions/checkout"

    advisory = File.read!(@phase68_advisory)
    assert advisory =~ ~r/^  workflow_dispatch:/m
    refute advisory =~ ~r/^  pull_request:/m
    refute advisory =~ ~r/^  push:/m
    assert advisory =~ "continue-on-error: true"
  end

  @tag :triggers
  test "mirror package and focused docs-contract proof move to one PR graph" do
    workflow = File.read!(@crosswake_ci)

    for path <- @plan08_task3_sources do
      refute File.exists?(path), "#{path} must be retired after replacement parity"
    end

    for {job, runner, command} <- [
          {"ios-mirror-parity-proof", "ubuntu-latest", "script/check_ios_mirror_parity.sh"},
          {"phase10-proof", "ubuntu-latest", "script/verify_saas_profile.sh"},
          {"phase96-threadline-docs-contract-proof", "ubuntu-latest",
           "phase96_threadline_docs_contract_test.exs"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: #{runner}"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    focused = job_body(workflow, "phase96-threadline-docs-contract-proof")
    assert focused =~ "classification == 'full_proof'"
    assert focused =~ "threadline_docs_contract"

    advisory = File.read!(".github/workflows/phase96-proof-advisory.yml")
    assert advisory =~ ~r/^  workflow_dispatch:/m
    assert advisory =~ ~r/^  schedule:/m
    refute advisory =~ ~r/^  pull_request:/m
    refute advisory =~ ~r/^  push:/m

    for {job, display_name} <- [
          {"compat-ios-mirror-parity", "merge-blocking-ios-mirror-parity"},
          {"compat-phase96-threadline-docs-contract",
           "merge-blocking Threadline docs-contract proof (hermetic)"}
        ] do
      compatibility = job_body(workflow, job)
      assert compatibility =~ "name: #{display_name}"
      assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
      assert compatibility =~ "if: always()"
      refute compatibility =~ "actions/checkout"
    end
  end

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
           "merge-blocking-crosswake-ci"},
          {"compat-contract-drift", "merge-blocking-contract-drift",
           "merge-blocking-crosswake-ci"},
          {"compat-dependency-security", "merge-blocking-dependency-security",
           "merge-blocking-crosswake-ci"},
          {"compat-requires-example-host", "merge-blocking-requires-example-host",
           "merge-blocking-crosswake-ci"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "needs:"
      assert body =~ need
      refute body =~ "actions/checkout"
    end

    contract = job_body(workflow, "compat-contract-drift")
    assert contract =~ "if: always()"
    assert contract =~ "python3"
  end

  @tag :triggers
  test "hermetic engine and commerce PR proof moves while advisories stay separate" do
    workflow = File.read!(@crosswake_ci)

    for {job, display_name, command} <- [
          {"phase130-core-hermetic-proof", "phase130-core-hermetic-proof",
           "mix test test/crosswake/proof/phase130_extraction_guards_test.exs"},
          {"phase130-companion-engine-absent-proof", "phase130-companion-engine-absent-proof",
           "mix companions.test"},
          {"phase132-core-hermetic-proof", "phase132-core-hermetic-proof",
           "phase132_compat_matrix_drift_test.exs"},
          {"phase132-companion-engine-absent-proof", "phase132-companion-engine-absent-proof",
           "crosswake_rindle"},
          {"phase23-commerce-proof", "phase23-commerce-proof",
           "phase23_commerce_support_proof_test.exs"},
          {"phase34-commerce-proof", "phase34-commerce-proof",
           "mix test --exclude requires_example_host"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    for path <- [
          ".github/workflows/phase130-proof.yml",
          ".github/workflows/phase132-proof.yml",
          ".github/workflows/phase23-proof.yml",
          ".github/workflows/phase34-proof.yml"
        ] do
      advisory = File.read!(path)
      refute advisory =~ ~r/^  pull_request:/m
      refute advisory =~ ~r/^  push:/m
      assert advisory =~ ~r/^  workflow_dispatch:/m
      assert advisory =~ ~r/^  schedule:/m
      assert advisory =~ "continue-on-error: true"
    end

    for display_name <- [
          "core hermetic proof (merge-blocking)",
          "companion engine-absent proof (merge-blocking)",
          "phase132 core hermetic proof (merge-blocking)",
          "phase132 companion engine-absent proof (merge-blocking)",
          "merge-blocking commerce support proof (hermetic)",
          "merge-blocking phase34 commerce support proof (hermetic)"
        ] do
      assert workflow =~ "name: #{display_name}"
    end
  end

  @tag :manifest
  test "migrated domain cohorts have exact leaf, control, compatibility, and umbrella parity" do
    manifest = @leaf_manifest |> File.read!() |> Jason.decode!()
    workflow = File.read!(@crosswake_ci)

    proof_ids = Enum.map(manifest["proof_leaves"], & &1["leaf_id"])
    control_ids = Enum.map(manifest["required_control_nodes"], & &1["node_id"])
    compatibility = manifest["legacy_compatibility_contexts"]
    compatibility_ids = Enum.map(compatibility, & &1["job_id"])

    assert proof_ids == Enum.sort(proof_ids)
    assert control_ids == ["classify-change"]
    assert compatibility_ids == Enum.sort(compatibility_ids)
    assert length(proof_ids) == 44
    assert length(compatibility_ids) == 27

    for id <- [
          "phase71-notification-workflow-proof",
          "phase73-auth-sensitive-admin-workflow-proof",
          "phase74-offline-draft-recovery-proof",
          "phase75-closeout-gate"
        ] do
      row = Enum.find(manifest["proof_leaves"], &(&1["leaf_id"] == id))
      assert row["irrelevance_reason"] == "all_changed_paths_allowlisted"
      assert is_binary(row["remediation_command"])
    end

    umbrella = job_body(workflow, "merge-blocking-crosswake-ci")

    for id <- proof_ids ++ control_ids do
      assert umbrella =~ ~r/^      - #{Regex.escape(id)}$/m
    end

    for row <- compatibility do
      refute umbrella =~ ~r/^      - #{Regex.escape(row["job_id"])}$/m
      body = job_body(workflow, row["job_id"])
      assert body =~ "name: #{row["display_context"]}"
      assert body =~ row["needs_target"]
      refute body =~ "actions/checkout"
    end
  end

  @tag :manifest
  test "migrated cohort has one PR workflow and no generic push duplicate" do
    assert File.read!(@crosswake_ci) =~ ~r/^on:\n  pull_request:\s*$/m
    refute File.read!(@crosswake_ci) =~ ~r/^  push:/m

    for path <- [
          ".github/workflows/phase130-proof.yml",
          ".github/workflows/phase132-proof.yml",
          ".github/workflows/phase23-proof.yml",
          ".github/workflows/phase34-proof.yml"
        ] do
      workflow = File.read!(path)
      refute workflow =~ ~r/^  pull_request:/m
      refute workflow =~ ~r/^  push:/m
    end
  end

  @tag :triggers
  test "gating, Rulestead, Rindle, and provider PR proof moves without advisory authority" do
    workflow = File.read!(@crosswake_ci)

    refute File.exists?(hd(@plan06_task1_sources))

    for {job, command} <- [
          {"phase41-gating-proof", "phase41_gating_doctor_test.exs"},
          {"phase43-rulestead-proof",
           "mix test --exclude requires_example_host --exclude advisory_only"},
          {"phase45-rindle-proof",
           "mix test --exclude requires_example_host --exclude advisory_only"},
          {"phase48-provider-adapter-proof", "phase48_provider_adapter_proof_test.exs"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    for path <- tl(@plan06_task1_sources) do
      advisory = File.read!(path)
      refute advisory =~ ~r/^  pull_request:/m
      refute advisory =~ ~r/^  push:/m
      assert advisory =~ ~r/^  workflow_dispatch:/m
      assert advisory =~ ~r/^  schedule:/m
      assert advisory =~ "continue-on-error: true"
    end

    for {job, display_name} <- [
          {"compat-phase41-gating-proof",
           "merge-blocking gating doctor and support matrix proof (hermetic)"},
          {"compat-phase43-rulestead-proof", "merge-blocking rulestead proof (hermetic)"},
          {"compat-phase45-rindle-proof", "merge-blocking rindle proof (hermetic)"},
          {"compat-phase48-provider-adapter-proof",
           "merge-blocking provider adapter proof (hermetic)"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "needs: [merge-blocking-crosswake-ci]"
      assert body =~ "if: always()"
      refute body =~ "actions/checkout"
    end
  end

  @tag :triggers
  test "operator, auth, closeout, and subscription proof use only central classification" do
    workflow = File.read!(@crosswake_ci)

    refute File.exists?(".github/workflows/phase69-proof.yml")

    for {job, command} <- [
          {"phase52-operator-proof", "phase52_operator_truth_test.exs"},
          {"phase58-auth-closeout-proof", "mix closeout.verify --security-only"},
          {"phase69-closeout-proof",
           "mix closeout.verify --cwd . --closeout-path .planning/milestones/v4.0-CLOSEOUT.md"},
          {"phase70-subscription-saas-proof", "phase70_subscription_saas_commerce_proof_test.exs"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
    end

    for path <- @plan06_task2_sources, File.exists?(path) do
      source = File.read!(path)
      refute source =~ ~r/^  pull_request:/m
      refute source =~ ~r/^  push:/m
      refute source =~ "git diff --name-only"
      refute source =~ "grep -Eq"
    end

    for path <- [
          ".github/workflows/phase52-proof.yml",
          ".github/workflows/phase58-proof.yml",
          ".github/workflows/phase70-proof.yml"
        ] do
      advisory = File.read!(path)
      assert advisory =~ ~r/^  workflow_dispatch:/m
      assert advisory =~ ~r/^  schedule:/m
      assert advisory =~ "continue-on-error: true"
    end

    for {job, display_name} <- [
          {"compat-phase52-operator-proof", "merge-blocking operator proof (hermetic)"},
          {"compat-phase58-auth-closeout-proof", "merge-blocking auth closeout proof (hermetic)"},
          {"compat-phase69-closeout-proof", "merge-blocking-closeout-proof"},
          {"compat-phase70-subscription-saas-proof",
           "merge-blocking subscription SaaS proof (hermetic)"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "needs: [merge-blocking-crosswake-ci]"
      assert body =~ "if: always()"
      refute body =~ "actions/checkout"
    end
  end

  @tag :triggers
  test "notification, auth-sensitive, recovery, and closeout proof use central classification" do
    workflow = File.read!(@crosswake_ci)

    refute File.exists?(List.last(@plan07_sources))

    for {job, command} <- [
          {"phase71-notification-workflow-proof", "phase71_notification_workflow_proof_test.exs"},
          {"phase73-auth-sensitive-admin-workflow-proof",
           "phase73_auth_sensitive_admin_workflow_proof_test.exs"},
          {"phase74-offline-draft-recovery-proof",
           "phase74_offline_draft_recovery_proof_test.exs"},
          {"phase75-closeout-gate", "mix closeout.verify"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{job}"
      assert body =~ "runs-on: ubuntu-latest"
      assert body =~ "timeout-minutes:"
      assert body =~ command
      assert body =~ "Remediation:"
      assert body =~ "needs: [classify-change]"
      assert body =~ "classification == 'full_proof'"
    end

    for path <- Enum.take(@plan07_sources, 3) do
      advisory = File.read!(path)
      refute advisory =~ ~r/^  pull_request:/m
      refute advisory =~ ~r/^  push:/m
      assert advisory =~ ~r/^  workflow_dispatch:/m
      assert advisory =~ ~r/^  schedule:/m
      assert advisory =~ "continue-on-error: true"
      refute advisory =~ "Determine closeout relevance"
      refute advisory =~ "git diff --name-only"
      refute advisory =~ "grep -Eq"
    end

    for {job, display_name} <- [
          {"compat-phase71-notification-workflow-proof",
           "merge-blocking notification workflow proof (hermetic)"},
          {"compat-phase73-auth-sensitive-admin-workflow-proof",
           "merge-blocking auth-sensitive admin workflow proof (hermetic)"},
          {"compat-phase74-offline-draft-recovery-proof",
           "merge-blocking offline draft recovery proof (hermetic)"},
          {"compat-phase75-closeout-gate", "merge-blocking phase 75 closeout gate"}
        ] do
      body = job_body(workflow, job)
      assert body =~ "name: #{display_name}"
      assert body =~ "needs: [merge-blocking-crosswake-ci]"
      assert body =~ "if: always()"
      refute body =~ "actions/checkout"
    end

    documentation = job_body(workflow, "documentation-contracts")
    assert documentation =~ "mix crosswake.adoption_context.scan"
    assert workflow =~ "classification=full_proof"
    assert workflow =~ "checkout_or_object_validation_failed"
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

    for job <- [
          "android-package-unit",
          "android-generated-shell-unit",
          "phase18-elixir-android-proof",
          "phase79-android-proof"
        ] do
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
    workflow = File.read!(@crosswake_ci)

    assert job_body(workflow, "phase5-proof") =~ "runs-on: ubuntu-latest"
    refute job_body(workflow, "phase5-proof") =~ "DEVELOPER_DIR"

    assert job_body(workflow, "phase18-elixir-android-proof") =~ "runs-on: ubuntu-latest"

    assert job_body(workflow, "phase18-elixir-android-proof") =~
             "verify_generated_android_shell.sh"

    assert job_body(workflow, "phase18-ios-proof") =~ "runs-on: macos-15"
    assert job_body(workflow, "phase18-ios-proof") =~ "verify_generated_ios_shell.sh"
    refute job_body(workflow, "phase18-elixir-android-proof") =~ "DEVELOPER_DIR"

    assert job_body(workflow, "phase79-android-proof") =~ "runs-on: ubuntu-latest"
    assert job_body(workflow, "phase79-ios-proof") =~ "runs-on: macos-15"
    assert job_body(workflow, "phase79-ios-proof") =~ "verify_generated_ios_shell.sh"
    refute job_body(workflow, "phase79-ios-proof") =~ "verify_generated_android_shell.sh"
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
