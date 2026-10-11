defmodule Crosswake.ReleaseCandidate.CompanionAttestationTest do
  use ExUnit.Case, async: true

  test "hosted companion adapter rejects stale and mismatched source facts" do
    {output, status} =
      System.cmd("python3", ["test/support/companion_attestation_check.py"],
        stderr_to_stdout: true
      )

    assert status == 0, output
  end

  test "hosted companion receipt has no publication credentials or core attestation requirements" do
    source = File.read!(".github/workflows/ios-mirror-backfill.yml")
    [_, rest] = String.split(source, "  attest-companion-receipt:", parts: 2)
    [job | _] = String.split(rest, "  attest-candidate-receipt:", parts: 2)
    assert job =~ "inputs.package == 'crosswake_chimeway'"
    assert job =~ "actions: read"
    assert job =~ "contents: read"
    [settings, steps] = String.split(job, "    steps:", parts: 2)
    refute settings =~ "runner.temp"
    assert steps =~ "        env:\n          OUTPUT_DIR: ${{ runner.temp }}/companion-receipt-attestation"
    assert job =~ "mix crosswake.release.receipt"
    assert job =~ "phase168-candidate-receipt-${{ inputs.candidate_head }}"

    for forbidden <- [
          "secrets.",
          "MIRROR_DEPLOY_KEY",
          "hex.publish",
          "gh pr merge",
          "ios_run_id",
          "maven_run_id"
        ] do
      refute job =~ forbidden
    end
  end
end
