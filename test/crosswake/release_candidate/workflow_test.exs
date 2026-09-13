defmodule Crosswake.ReleaseCandidate.WorkflowTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Workflow

  @hex_workflow ".github/workflows/hex-publish.yml"
  @ios_workflow ".github/workflows/ios-mirror-backfill.yml"
  @release_workflow ".github/workflows/release-please.yml"
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

    assert :binary.match(rehearsal, "mix deps.get --check-locked") <
             :binary.match(rehearsal, "bash script/release_candidate/hex_artifacts.sh")

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

  test "linked publication is gated by approved merge parent and identical tree" do
    workflow = File.read!(@release_workflow)
    guard = job_block(workflow, "approved-release-guard")

    assert guard =~ "approved_head"
    assert guard =~ "approved_tree"
    assert guard =~ "merge_oid"
    assert guard =~ "merge_parents"
    assert guard =~ "merge_tree"
    assert guard =~ "candidate_receipt"
    assert guard =~ "git rev-list --parents -n 1"
    assert guard =~ "[ \"$parent_count\" -eq 3 ]"
    assert guard =~ "[ \"$approved_head\" = \"$second_parent\" ]"
    assert guard =~ "[ \"$merge_tree\" = \"$approved_tree\" ]"
    assert guard =~ "READY FOR APPROVAL"
    assert guard =~ ".external_state.changed == false"

    for job <- ~w(publish-hex publish-ios-core publish-android-core) do
      block = job_block(workflow, job)
      assert block =~ "approved-release-guard"
      assert block =~ "0.2.1"
      refute block =~ "environment:"
    end
  end

  test "canonical approval receipt is attested separately from credential-free candidate CI" do
    ios_workflow = File.read!(@ios_workflow)
    release_workflow = File.read!(@release_workflow)
    attestation = job_block(ios_workflow, "attest-candidate-receipt")
    guard = job_block(release_workflow, "approved-release-guard")
    exact_public = job_block(release_workflow, "exact-public-proof")

    assert ios_workflow =~ "candidate-receipt-attestation"
    assert attestation =~ "phase168-candidate-ci-${CANDIDATE_HEAD}"
    assert attestation =~ "candidate-rehearsal-hex"
    assert attestation =~ "candidate-rehearsal-ios"
    assert attestation =~ "Crosswake.ReleaseCandidate.Receipt.validate!"
    assert attestation =~ "phase168-candidate-receipt-${{ inputs.candidate_head }}"
    assert attestation =~ "candidate-receipt.json"
    assert attestation =~ "artifacts.json"

    assert guard =~ "phase168-candidate-receipt-${approved_head}"
    assert guard =~ "candidate_receipt_run_id"
    assert guard =~ "phase168-candidate-ci-${approved_head}"
    assert guard =~ "release-candidate-ci-receipt.json"
    assert exact_public =~ "candidate_receipt_run_id"

    assert exact_public =~
             "phase168-candidate-receipt-${{ needs.approved-release-guard.outputs.approved_head }}"

    refute guard =~
             ~s(--name "phase168-candidate-receipt-${approved_head}" --dir "$receipt_dir")
  end

  test "rollback of an untagged failed release remains a reversible proposal refresh" do
    workflow = File.read!(@release_workflow)
    guard = job_block(workflow, "approved-release-guard")

    assert guard =~ "linked_candidate=false"
    assert guard =~ "linked_candidate=true"
    assert guard =~ ~s([ "$linked_candidate" = "true" ] || exit 0)
    assert guard =~ "linked_release=false"
  end

  test "proposal refresh cannot be reported as a partial native release" do
    workflow = File.read!(@release_workflow)
    rollup = job_block(workflow, "native-release-rollup")

    assert rollup =~ "approved-release-guard"
    assert rollup =~ "LINKED_RELEASE: ${{ needs.approved-release-guard.outputs.linked_release }}"
    assert rollup =~ ~s([ "$LINKED_RELEASE" != "true" ])
    assert rollup =~ ~s(printf "false")
  end

  test "postapproval graph contains only the three linked core coordinates" do
    workflow = File.read!(@release_workflow)
    android = job_block(workflow, "publish-android-core")
    ios = job_block(workflow, "publish-ios-core")
    rollup = job_block(workflow, "linked-release-rollup")

    assert android =~ "script/release_candidate/android_publication.sh"
    assert ios =~ "script/release_candidate/ios_mirror.sh publish"
    assert ios =~ "--approval-receipt"
    refute ios =~ "--force"

    for child <-
          ~w(publish-hex publish-android-core publish-ios-core clean-room-proof-ios clean-room-proof-android exact-public-proof) do
      assert rollup =~ child
    end

    assert rollup =~ "child_states"
    assert rollup =~ "successful_coordinates"
    assert rollup =~ "failed_step"
    assert rollup =~ "failed_ref"
    assert rollup =~ "COMPLETE"
    assert rollup =~ "PARTIAL"

    refute workflow =~ "release/v0.2.1"
    refute workflow =~ "rc-v0.2.1"
    refute workflow =~ "merge-companion"
  end

  test "every child failure preserves exact prior public success as PARTIAL" do
    assert Code.ensure_loaded?(Workflow)
    assert function_exported?(Workflow, :rollup!, 1)

    ordered = ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a

    for {failed_child, index} <- Enum.with_index(ordered) do
      children =
        ordered
        |> Enum.with_index()
        |> Map.new(fn {child, child_index} ->
          status =
            cond do
              child == failed_child -> "failed"
              child_index > index -> "skipped"
              true -> "success"
            end

          {child, status}
        end)

      result = Workflow.rollup!(rollup_input(children))

      assert result.child_states == children
      assert result.failed_step == Atom.to_string(failed_child)
      assert result.failed_ref == String.duplicate("a", 40)
      assert result.next_action == "retry_failed_step_from_exact_ref_or_publish_forward_fix"

      expected_coordinates =
        [:hex, :ios_mirror, :android]
        |> Enum.filter(&(Map.fetch!(children, &1) == "success"))
        |> Enum.map(&coordinate/1)
        |> Enum.sort()

      assert result.successful_coordinates == expected_coordinates
      assert result.state == if(expected_coordinates == [], do: "BLOCKED", else: "PARTIAL")
    end
  end

  test "complete requires every linked publication and exact-public proof" do
    children = %{
      hex: "success",
      ios_mirror: "success",
      android: "success",
      ios_public_proof: "success",
      android_public_proof: "success",
      exact_public: "success"
    }

    result = Workflow.rollup!(rollup_input(children))

    assert result.state == "COMPLETE"

    assert result.successful_coordinates ==
             Enum.sort([coordinate(:hex), coordinate(:ios_mirror), coordinate(:android)])

    assert result.failed_step == nil
    assert result.failed_ref == nil
    assert result.next_action == "no_action_required"
  end

  test "partial recovery rejects mutable refs, lost success, and impossible resumes" do
    baseline = %{
      hex: "success",
      ios_mirror: "failed",
      android: "success",
      ios_public_proof: "skipped",
      android_public_proof: "success",
      exact_public: "skipped"
    }

    assert_raise ArgumentError, "release workflow observation is invalid", fn ->
      Workflow.rollup!(rollup_input(baseline) |> Map.put(:approved_ref, "main"))
    end

    assert_raise ArgumentError, "release workflow observation is invalid", fn ->
      Workflow.validate!(%{
        Workflow.rollup!(rollup_input(baseline))
        | successful_coordinates: [coordinate(:android)]
      })
    end

    assert_raise ArgumentError, "release workflow observation is invalid", fn ->
      Workflow.rollup!(
        rollup_input(%{baseline | ios_public_proof: "success", exact_public: "success"})
      )
    end
  end

  defp job_block(workflow, job) do
    regex = ~r/(?ms)^  #{Regex.escape(job)}:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/

    case Regex.run(regex, workflow, capture: :all_but_first) do
      [block] -> block
      _ -> ""
    end
  end

  defp rollup_input(children) do
    %{
      approved_ref: String.duplicate("a", 40),
      candidate_receipt: String.duplicate("b", 64),
      children: children
    }
  end

  defp coordinate(:hex), do: "hex:crosswake@0.2.1"
  defp coordinate(:ios_mirror), do: "swift:crosswake-shell-core-ios@0.2.1"
  defp coordinate(:android), do: "maven:io.crosswake:crosswake-shell-core@0.2.1"
end
