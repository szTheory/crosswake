defmodule Crosswake.Proof.Phase165EvidenceTest do
  @moduledoc """
  CIP-06: CI efficiency evidence is sanitized, reproducible, and candid about
  metrics the GitHub API does not expose.
  """
  use ExUnit.Case, async: true

  @monitor "scripts/ci_monitor.cjs"
  @evidence ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/baseline.json"
  @rendered ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/baseline.md"
  @contexts ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/required-context-baseline.json"

  @remote_source ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/remote-default-source.json"
  @live_observation ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json"
  @required_policy "script/required_check_policy.json"
  @final_source ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/final-remote-default-source.json"
  @after_evidence ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/after.json"
  @comparison ".planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/comparison.md"

  @tag :final_source
  test "final source binding covers the compatibility-free workflow and manifest" do
    monitor = File.read!(@monitor)

    assert monitor =~ "verify-final-remote-default-source"
    assert monitor =~ "PHASE165_FINAL_REMOTE_DEFAULT_SHA"
    assert monitor =~ ".github/workflows/crosswake-ci.yml"
    assert monitor =~ "script/ci_leaf_manifest.json"

    if File.exists?(@final_source) do
      source = @final_source |> File.read!() |> Jason.decode!()

      assert Map.keys(source) |> Enum.sort() ==
               ~w(default_branch manifest_digest repository_sha schema_version source_command verified_at workflow_digest)
               |> Enum.sort()

      assert source["repository_sha"] =~ ~r/^[0-9a-f]{40}$/
      assert source["workflow_digest"] =~ ~r/^[0-9a-f]{64}$/
      assert source["manifest_digest"] =~ ~r/^[0-9a-f]{64}$/
    end
  end

  test "final comparison is generated from canonical matched evidence" do
    monitor = File.read!(@monitor)
    assert monitor =~ "--cohorts"
    assert monitor =~ "criteria_mismatch"
    assert monitor =~ "No causal conclusion"

    if File.exists?(@after_evidence) and File.exists?(@comparison) do
      after_evidence = @after_evidence |> File.read!() |> Jason.decode!()
      source = @final_source |> File.read!() |> Jason.decode!()
      comparison = File.read!(@comparison)

      assert after_evidence["repository_sha"] == source["repository_sha"]
      assert comparison =~ "Workflow/job/check counts"
      assert comparison =~ "Runner classes"
      assert comparison =~ "not measured"
      assert comparison =~ "not exposed"
      assert comparison =~ "No causal conclusion"
      refute comparison =~ "improvement"
    end
  end

  test "monitor evidence self-test covers closed schema and timing boundaries" do
    {output, status} = System.cmd("node", [@monitor, "test-evidence"], stderr_to_stdout: true)
    assert status == 0, output
    assert output =~ "evidence self-test: pass"
  end

  test "committed baseline validates and renders only from canonical JSON" do
    assert File.exists?(@evidence)
    assert File.exists?(@rendered)

    {output, status} =
      System.cmd("node", [@monitor, "validate-evidence", @evidence], stderr_to_stdout: true)

    assert status == 0, output
    markdown = File.read!(@rendered)
    assert markdown =~ "Sample count"
    assert markdown =~ "median"
    assert markdown =~ "range"
    assert markdown =~ "not exposed"
    assert markdown =~ "not measured"
    assert markdown =~ "Source command"
    refute markdown =~ "improvement"
  end

  test "required context authority is strict, exact, sorted, and digest bound" do
    snapshot = @contexts |> File.read!() |> Jason.decode!()

    assert snapshot["strict"] == true
    assert length(snapshot["required_contexts"]) == 27
    assert snapshot["required_contexts"] == Enum.sort(snapshot["required_contexts"])
    assert snapshot["required_contexts"] == Enum.uniq(snapshot["required_contexts"])
    assert snapshot["source_digest"] =~ ~r/^[0-9a-f]{64}$/
    refute Map.has_key?(snapshot, "checks")
    refute Map.has_key?(snapshot, "url")
  end

  test "canonical evidence contains no sensitive transport fields" do
    evidence = File.read!(@evidence)

    for forbidden <- [
          ~s("actor"),
          ~s("message"),
          ~s("raw_payload"),
          ~s("log"),
          ~s("runner_identity"),
          ~s("cache_key"),
          ~s("token"),
          ~s("account_identifier"),
          ~s("device_identifier"),
          ~s("url")
        ] do
      refute evidence =~ forbidden
    end
  end

  test "live probe commands bind the immutable remote source and sanitize observations" do
    monitor = File.read!(@monitor)

    assert monitor =~ "verify-remote-default-source"
    assert monitor =~ "probe-phase165"
    assert monitor =~ "PHASE165_REMOTE_DEFAULT_SHA"
    assert monitor =~ "remote-default-source.json"
    assert monitor =~ "lower_run_cancelled"
    assert monitor =~ "newer_run_authoritative"
    assert monitor =~ "Crosswake CI"
    assert monitor =~ "planning_probe"
    assert monitor =~ "public_docs_probe"
    assert monitor =~ "public_docs"

    if File.exists?(@remote_source) do
      source = @remote_source |> File.read!() |> Jason.decode!()
      assert source["schema_version"] == 1
      assert source["repository_sha"] =~ ~r/^[0-9a-f]{40}$/

      assert source["workflow_digests"][".github/workflows/crosswake-ci.yml"] =~
               ~r/^[0-9a-f]{64}$/

      assert source["workflow_digests"][".github/workflows/cancel-obsolete-crosswake-ci.yml"] =~
               ~r/^[0-9a-f]{64}$/
    end

    if File.exists?(@live_observation) do
      {output, status} =
        System.cmd("node", [@monitor, "validate-evidence", @live_observation], stderr_to_stdout: true)

      assert status == 0, output
    end
  end

  test "required-check policy and scripts enforce additive dual authority" do
    policy = @required_policy |> File.read!() |> Jason.decode!()
    registrar = File.read!("script/register_required_checks.sh")
    audit = File.read!("script/check_required_checks_registered.sh")

    assert policy["strict"] == true
    assert policy["umbrella_context"] == "Crosswake CI"
    assert policy["dual_contexts"] == Enum.sort(policy["legacy_contexts"] ++ ["Crosswake CI"])
    assert policy["target_contexts"] == ["Crosswake CI"]
    assert policy["source_digest"] =~ ~r/^[0-9a-f]{64}$/
    assert registrar =~ "--mode"
    assert registrar =~ "add|retire"
    assert registrar =~ "--dry-run"
    assert registrar =~ "--apply"
    assert registrar =~ "--policy"
    assert audit =~ "--state"
    assert audit =~ "dual|target"
    assert audit =~ "--live"
  end
end
