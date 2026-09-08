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
end
