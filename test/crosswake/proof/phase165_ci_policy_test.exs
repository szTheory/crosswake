defmodule Crosswake.Proof.Phase165CiPolicyTest do
  @moduledoc """
  CIP-05/CIP-07 tracer proof for fail-closed documentation classification,
  one literal documentation leaf, and the checkout-free Crosswake CI umbrella.
  """
  use ExUnit.Case, async: true

  @classifier "script/classify_ci_change.py"
  @allowlist "script/ci_docs_allowlist.json"
  @manifest "script/ci_leaf_manifest.json"
  @workflow ".github/workflows/crosswake-ci.yml"

  @moduletag :classifier

  test "classifier adversarial and shallow-history integration fixtures pass" do
    {output, status} = System.cmd("python3", [@classifier, "--self-test"], stderr_to_stdout: true)
    assert status == 0, output
    assert output =~ "classifier self-test: pass"
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
    assert Enum.all?(fixture["cases"], &(&1["classification"] in ["documentation_only", "full_proof"]))
    assert "mixed" in names
    assert "rename_crosses_boundary" in names
    assert "empty" in names
  end

  @tag :manifest
  test "manifest freezes one proof leaf and one required control node" do
    manifest = @manifest |> File.read!() |> Jason.decode!()

    assert manifest["proof_leaves"] == [
             %{
               "leaf_id" => "documentation-contracts",
               "display_name" => "documentation-contracts",
               "family" => "documentation_contracts",
               "remediation_command" =>
                 "mix crosswake.adoption_context.scan && mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs",
               "irrelevance_reason" => nil
             }
           ]

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
    assert umbrella =~ "needs: [classify-change, documentation-contracts]"
    assert umbrella =~ ~s([ "$CONTROL_RESULT" != 'success' ])
    assert umbrella =~ ~s([ "$DOCUMENTATION_RESULT" != 'success' ])
    assert umbrella =~ "documentation_only|full_proof"
    refute umbrella =~ "actions/checkout"
    refute umbrella =~ "uses: ./"
    refute umbrella =~ "pip install"
    refute umbrella =~ ~r/^\s+run:\s+mix /m
    refute umbrella =~ "script/"
  end
end
