defmodule Crosswake.Proof.Phase165CiPolicyTest do
  @moduledoc """
  CIP-05/CIP-07 tracer proof for fail-closed documentation classification,
  literal named proof leaves, and the checkout-free Crosswake CI umbrella.
  """
  use ExUnit.Case, async: true

  @classifier "script/classify_ci_change.py"
  @allowlist "script/ci_docs_allowlist.json"
  @manifest "script/ci_leaf_manifest.json"
  @workflow ".github/workflows/crosswake-ci.yml"
  @cancellation_fixture "test/fixtures/ci/cancellation/cases.json"
  @cancellation_selector "script/select_obsolete_ci_runs.py"
  @aggregate "script/check_phase165_efficient_ci.sh"
  @monitor "scripts/ci_monitor.cjs"

  @moduletag :classifier

  test "classifier adversarial and shallow-history integration fixtures pass" do
    {output, status} = System.cmd("python3", [@classifier, "--self-test"], stderr_to_stdout: true)
    assert status == 0, output
    assert output =~ "classifier self-test: pass"
  end

  @tag :tmp_dir
  test "required action audit rejects mutable third-party refs", %{tmp_dir: tmp} do
    fixture = Path.join(tmp, "mutable-action.yml")
    File.write!(fixture, "steps:\n  - uses: actions/checkout@v7\n")

    {output, status} =
      System.cmd("node", [@monitor, "check-actions", fixture], stderr_to_stdout: true)

    assert status != 0
    assert output =~ "mutable_refs=1"
    assert File.read!(@aggregate) =~ "node scripts/ci_monitor.cjs check-actions"
  end

  test "classifier schedules focused Threadline proof only for public documentation" do
    classifier = File.read!(@classifier)

    assert classifier =~ "threadline_docs_contract"
    assert classifier =~ "public_docs"
    assert classifier =~ "affected_families"
  end

  test "public documentation schedules every migrated public proof family" do
    classifier = File.read!(@classifier)
    workflow = File.read!(@workflow)

    assert classifier =~ ~s(scheduled_families.extend(["public_docs", "threadline_docs_contract"]))

    for job <- ["brand-structural", "brand-visual", "collateral-binaries-guard", "hex-page-proof"] do
      body = workflow |> String.split("  #{job}:", parts: 2) |> List.last()
      assert body =~ "contains(fromJSON(needs.classify-change.outputs.scheduled_families), 'public_docs')"
    end
  end

  test "allowlist is the exact narrow documentation contract" do
    allowlist = @allowlist |> File.read!() |> Jason.decode!()

    assert allowlist == %{
             "schema_version" => 2,
             "families" => [
               %{
                 "family" => "planning",
                 "exact" => [],
                 "trees" => [".planning"],
                 "extensions" => [".md"],
                 "proof_owner" => "documentation-contracts"
               },
               %{
                 "family" => "public_docs",
                 "exact" => [
                   "CONTRIBUTING.md",
                   "README.md",
                   "SETUP.md",
                   "examples/QUICK_START.md"
                 ],
                 "trees" => ["brandbook", "docs", "guides"],
                 "extensions" => [".md"],
                 "proof_owner" => "documentation-contracts"
               }
             ],
             "excluded" => [
               "docs/COMPANION-PUBLISH-RUNBOOK.md",
               "docs/PORT-REGISTRY.md",
               "docs/_contract_snippet.md"
             ]
           }
  end

  test "fixture corpus is closed, adversarial, and deterministic" do
    fixture = "test/fixtures/ci/classifier/cases.json" |> File.read!() |> Jason.decode!()
    assert fixture["schema_version"] == 1
    names = Enum.map(fixture["cases"], & &1["name"])
    assert names == Enum.sort(names)
    assert Enum.uniq(names) == names

    assert Enum.all?(
             fixture["cases"],
             &(&1["classification"] in ["documentation_only", "full_proof"])
           )

    assert "mixed" in names
    assert "rename_crosses_boundary" in names
    assert "empty" in names
  end

  @tag :manifest
  test "manifest preserves the documentation owner and one required control node" do
    manifest = @manifest |> File.read!() |> Jason.decode!()

    documentation =
      Enum.find(manifest["proof_leaves"], &(&1["leaf_id"] == "documentation-contracts"))

    executable =
      Enum.reject(manifest["proof_leaves"], &(&1["leaf_id"] == "documentation-contracts"))

    assert documentation["leaf_id"] == "documentation-contracts"
    assert documentation["family"] == "documentation_contracts"
    assert documentation["irrelevance_reason"] == nil
    assert documentation["remediation_command"] =~ "mix crosswake.adoption_context.scan"
    assert length(executable) == 43

    assert Enum.all?(executable, fn leaf ->
             leaf["irrelevance_reason"] in [
               "all_changed_paths_allowlisted",
               "public_docs_unaffected"
             ]
           end)

    assert manifest["required_control_nodes"] == [
             %{
               "node_id" => "classify-change",
               "display_name" => "classify-change",
               "required_result" => "success"
             }
           ]

    assert manifest["legacy_compatibility_contexts"] == []
  end

  @tag :manifest
  test "manifest, workflow, static needs, and producers have exact parity" do
    {output, status} =
      System.cmd("python3", ["script/check_ci_leaf_manifest.py", "--self-test"],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "ci leaf manifest self-test: pass"
  end

  test "workflow is PR-only and umbrella is static, always, and checkout-free" do
    workflow = File.read!(@workflow)

    assert workflow =~ ~r/^on:\n  pull_request:\s*$/m
    refute workflow =~ ~r/^\s+push:/m
    refute workflow =~ ~r/^\s+paths(?:-ignore)?:/m

    assert workflow =~
             "group: crosswake-ci-${{ github.repository }}-pr-${{ github.event.pull_request.number }}"

    assert workflow =~ "cancel-in-progress: false"
    assert workflow =~ "fetch-depth: 0"
    assert workflow =~ "git cat-file -e \"$base_sha^{commit}\""
    assert workflow =~ "git cat-file -e \"$merge_sha^{commit}\""

    umbrella = workflow |> String.split("  merge-blocking-crosswake-ci:", parts: 2) |> List.last()
    assert umbrella =~ "name: Crosswake CI"
    assert umbrella =~ "if: always()"
    assert umbrella =~ ~r/^      - classify-change$/m
    assert umbrella =~ ~r/^      - documentation-contracts$/m
    assert umbrella =~ "classification not in {\"documentation_only\", \"full_proof\"}"
    assert umbrella =~ "required classification control did not succeed"
    assert umbrella =~ "proof leaf did not reach a closed accepted result"
    refute umbrella =~ "actions/checkout"
    refute umbrella =~ "uses: ./"
    refute umbrella =~ "pip install"
    refute umbrella =~ ~r/^\s+run:\s+mix /m

    for field <- [
          "Classification:",
          "Reason:",
          "Scheduled proof families:",
          "Explicitly irrelevant families:",
          "Expected/observed proof leaves:",
          "Observed proof leaves use count units; hosted-runner timing is not measured.",
          "Remediation: python3 script/check_ci_leaf_manifest.py --self-test"
        ] do
      assert umbrella =~ field
    end
  end

  @tag :maximum_shape
  test "reviewed maximum umbrella graph fits the static checkout-free bounds" do
    {output, status} =
      System.cmd(
        "python3",
        [
          "script/check_ci_leaf_manifest.py",
          "--maximum-shape",
          "test/fixtures/ci/maximum-shape-crosswake-ci.yml",
          "--needs-fixture",
          "test/fixtures/ci/maximum-shape-needs.json"
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ ~r/maximum-shape: pass jobs=\d+ needs_bytes=\d+/
  end

  @tag :cancellation
  test "cancellation selector closes every fixture and preserves deterministic ordering" do
    fixture = @cancellation_fixture |> File.read!() |> Jason.decode!()

    assert fixture["schema_version"] == 1
    names = Enum.map(fixture["cases"], & &1["name"])
    assert names == Enum.sort(names)
    assert Enum.uniq(names) == names

    {output, status} =
      System.cmd("python3", [@cancellation_selector, "--self-test"], stderr_to_stdout: true)

    assert status == 0, output
    assert output =~ "cancellation selector self-test: pass"
  end

  @tag :cancellation
  test "older controller perspective can never select a newer authoritative run" do
    fixture = @cancellation_fixture |> File.read!() |> Jason.decode!()
    inversion = Enum.find(fixture["cases"], &(&1["name"] == "two_controller_inversion"))

    assert inversion["expected"]["older_controller_ids"] == []
    assert inversion["expected"]["newer_controller_ids"] == [100]
    assert inversion["expected"]["authoritative_run_id"] == 101
  end

  test "one credential-free aggregate composes every recurring Phase 165 contract" do
    aggregate = File.read!(@aggregate)

    for command <- [
          "python3 script/classify_ci_change.py --self-test",
          "python3 script/select_obsolete_ci_runs.py --self-test",
          "python3 script/check_aggregator_result_semantics.py --self-test",
          "python3 script/check_ci_leaf_manifest.py --self-test",
          "python3 script/list_merge_blocking_checks.py --emitters",
          "script/check_required_checks_registered.sh --local-only",
          "node scripts/ci_monitor.cjs test-evidence",
          "mix test test/crosswake/proof/phase165_ci_policy_test.exs",
          "mix test test/crosswake/proof/phase165_ci_integrity_test.exs",
          "mix test test/crosswake/proof/phase165_evidence_test.exs",
          "actionlint .github/workflows/crosswake-ci.yml"
        ] do
      assert aggregate =~ command
    end

    refute aggregate =~ "register_required_checks.sh"
    refute aggregate =~ "--apply"
    refute aggregate =~ "capture-evidence"
    refute aggregate =~ ~r/(queue|execution)[_-]time.*(?:limit|threshold)/i
    refute aggregate =~ ~r/\b(retry|rerun|re-run)\b.*\b(proof|test|assert)/i
  end
end
