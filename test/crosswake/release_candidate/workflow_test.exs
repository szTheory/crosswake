defmodule Crosswake.ReleaseCandidate.WorkflowTest do
  use ExUnit.Case, async: true

  @hex_workflow ".github/workflows/hex-publish.yml"
  @ios_workflow ".github/workflows/ios-mirror-backfill.yml"
  test "trusted Hex candidate rehearsal builds six exact-head packages without publication" do
    workflow = File.read!(@hex_workflow)
    rehearsal = job_block(workflow, "rehearse-hex-candidate")

    assert workflow =~ "candidate-rehearsal"
    assert rehearsal =~ "github.event.inputs.operation == 'candidate-rehearsal'"
    assert rehearsal =~ "CANDIDATE_HEAD: \"${{ inputs.candidate_head }}\""
    assert rehearsal =~ "CANDIDATE_TREE: \"${{ inputs.candidate_tree }}\""
    assert rehearsal =~ "CANDIDATE_BASE: \"${{ inputs.candidate_base }}\""
    assert rehearsal =~ "CANDIDATE_RECEIPT: \"${{ inputs.candidate_receipt }}\""
    assert rehearsal =~ "CANDIDATE_RUN_ID: ${{ github.run_id }}"
    assert rehearsal =~ "bash script/release_candidate/hex_artifacts.sh"
    assert rehearsal =~ "candidate-rehearsal-hex"
    refute rehearsal =~ "script/guarded_hex_publish.sh"
    refute rehearsal =~ "mix hex.publish --yes"
  end

  test "credentialed mirror rehearsal is separate from credential-free baseline" do
    workflow = File.read!(@ios_workflow)
    baseline = job_block(workflow, "inspect-ios-mirror-baseline")
    rehearsal = job_block(workflow, "rehearse-ios-mirror-candidate")

    assert baseline =~ "ios_mirror.sh baseline"
    refute baseline =~ "MIRROR_DEPLOY_KEY"
    refute baseline =~ "ssh-agent"

    assert rehearsal =~ "github.event.inputs.operation == 'candidate-rehearsal'"
    assert rehearsal =~ "ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}"
    assert rehearsal =~ "ios_mirror.sh candidate"
    assert rehearsal =~ "CANDIDATE_HEAD: \"${{ inputs.candidate_head }}\""
    assert rehearsal =~ "CANDIDATE_TREE: \"${{ inputs.candidate_tree }}\""
    assert rehearsal =~ "CANDIDATE_BASE: \"${{ inputs.candidate_base }}\""
    assert rehearsal =~ "CANDIDATE_RECEIPT: \"${{ inputs.candidate_receipt }}\""
    assert rehearsal =~ "external_state_changed=false"
    assert rehearsal =~ "candidate-rehearsal-ios"
  end

  test "trusted rehearsal artifacts bind exact workflow and run identity" do
    for path <- [@hex_workflow, @ios_workflow] do
      workflow = File.read!(path)

      assert workflow =~ "workflow_sha256"
      assert workflow =~ "requested_head"
      assert workflow =~ "observed_head"
      assert workflow =~ "observed_tree"
      assert workflow =~ "observed_base"
      assert workflow =~ "run_id"
      assert workflow =~ "run_head"
      assert workflow =~ "run_conclusion"
      assert workflow =~ "external_state_changed=false"
      assert workflow =~ "if-no-files-found: error"
    end
  end

  defp job_block(workflow, job) do
    regex = ~r/(?ms)^  #{Regex.escape(job)}:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/

    case Regex.run(regex, workflow, capture: :all_but_first) do
      [block] -> block
      _ -> ""
    end
  end
end
