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

  test "classifier adversarial and shallow-history integration fixtures pass" do
    {output, status} = System.cmd("python3", [@classifier, "--self-test"], stderr_to_stdout: true)
    assert status == 0, output
    assert output =~ "classifier self-test: pass"
  end

  test "allowlist is the exact narrow documentation contract" do
    allowlist = @allowlist |> File.read!() |> Jason.decode!()

    assert allowlist == %{
             "schema_version" => 1,
             "exact" => ["CONTRIBUTING.md", "README.md", "SETUP.md", "examples/QUICK_START.md"],
             "trees" => [".planning", "brandbook", "docs", "guides"],
             "excluded" => [
               "docs/COMPANION-PUBLISH-RUNBOOK.md",
               "docs/PORT-REGISTRY.md",
               "docs/_contract_snippet.md"
             ]
           }
  end

  test "manifest freezes one proof leaf and one required control node" do
    manifest = @manifest |> File.read!() |> Jason.decode!()

    assert manifest["proof_leaves"] == [
             %{
               "id" => "documentation-contracts",
               "name" => "documentation-contracts",
               "family" => "documentation_contracts",
               "remediation" =>
                 "mix crosswake.adoption_context.scan && mix test test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs",
               "irrelevant_when" => "full_proof_tracer_not_scheduled"
             }
           ]

    assert manifest["required_control_nodes"] == ["classify-change"]
    assert manifest["legacy_compatibility_contexts"] == []
  end

  test "workflow is PR-only and umbrella is static, always, and checkout-free" do
    workflow = File.read!(@workflow)

    assert workflow =~ ~r/^on:\n  pull_request:\s*$/m
    refute workflow =~ ~r/^\s+push:/m
    refute workflow =~ ~r/^\s+paths(?:-ignore)?:/m
    assert workflow =~ "group: crosswake-ci-${{ github.repository }}-pr-${{ github.event.pull_request.number }}"
    assert workflow =~ "cancel-in-progress: false"
    assert workflow =~ "fetch-depth: 0"
    assert workflow =~ "git cat-file -e \"$base_sha^{commit}\""
    assert workflow =~ "git cat-file -e \"$merge_sha^{commit}\""

    umbrella = workflow |> String.split("  merge-blocking-crosswake-ci:", parts: 2) |> List.last()
    assert umbrella =~ "name: Crosswake CI"
    assert umbrella =~ "if: always()"
    assert umbrella =~ "needs: [classify-change, documentation-contracts]"
    refute umbrella =~ "actions/checkout"
    refute umbrella =~ "uses: ./"
    refute umbrella =~ "pip install"
    refute umbrella =~ "mix "
    refute umbrella =~ "script/"
  end
end
