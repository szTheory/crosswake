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
      assert block =~ "needs.approved-release-guard.outputs.approved_version"
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

  test "partial 0.2.1 recovery is bound to the approved immutable release identity" do
    hex_workflow = File.read!(@hex_workflow)
    ios_workflow = File.read!(@ios_workflow)
    android_script = File.read!("script/release_candidate/android_publication.sh")
    hex_recovery = job_block(hex_workflow, "publish")
    android_recovery = job_block(hex_workflow, "recover-android-core")
    ios_publish = job_block(ios_workflow, "publish-ios-mirror")

    approved = [
      "b780a19863936619394087f1ffd384f1dca17c93",
      "1051ab90cf75e918c6f596f84578ac77eadf45af",
      "ecf63228243bfe7c2d6a377be996aa374b31d91f",
      "359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78"
    ]

    for identity <- approved do
      assert hex_recovery =~ identity
      assert android_recovery =~ identity
      assert ios_publish =~ identity
    end

    assert ios_publish =~ "9533049d1ee5239b122b43749ff90f8ace7c7f6b"
    assert ios_publish =~ "658d60253c58b7e0aedb576f16f40766fa677f23"
    assert ios_publish =~ "424ab96ede1b92f2b751b54bce04c6e607f0f3c8"
    assert ios_publish =~ "ios_mirror.sh publish"
    assert ios_publish =~ ~s(CROSSWAKE_IOS_MIRROR_EXECUTE: "true")
    refute ios_publish =~ "force"

    assert hex_workflow =~ "android-recovery"
    assert android_recovery =~ "android_publication.sh"
    assert android_recovery =~ "--recover"
    assert android_recovery =~ "ref: e089bfc0e8a4edf0b024a2a284c8a384216bd64d"
    assert android_recovery =~ "path: recovery-tools"
    assert android_recovery =~ "path: release-source"
    refute android_recovery =~ "ref: ${{ github.sha }}"
    refute android_recovery =~ "ref: main"
    refute android_recovery =~ "refs/heads/"

    assert android_recovery =~
             ~s(bash "$GITHUB_WORKSPACE/recovery-tools/script/release_candidate/android_publication.sh")

    assert android_recovery =~ ~s(--release-root "$GITHUB_WORKSPACE/release-source")
    assert android_script =~ "--release-root"
    assert android_script =~ ~s(git -C "$RELEASE_ROOT" rev-parse HEAD)
    refute android_recovery =~ "--execute"

    # 171-04 Task 1b generalized android_publication.sh's PUBLIC_POM to interpolate
    # ${VERSION} instead of the phase168 literal 0.2.1 (WELD-06).
    assert android_script =~
             "io/github/sztheory/crosswake-shell-core-android/${VERSION}/crosswake-shell-core-android-${VERSION}.pom"

    refute android_script =~ "io/crosswake/crosswake-shell-core/"
    refute hex_recovery =~ "--replace"
    refute android_recovery =~ "--replace"
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

  test "coordinate derivation is a function of the input version, not a frozen literal" do
    children = %{
      hex: "success",
      ios_mirror: "success",
      android: "success",
      ios_public_proof: "success",
      android_public_proof: "success",
      exact_public: "success"
    }

    result_a = Workflow.rollup!(rollup_input(children, "0.2.2"))
    result_b = Workflow.rollup!(rollup_input(children, "9.9.9"))

    assert [_ | _] = result_a.successful_coordinates
    assert [_ | _] = result_b.successful_coordinates

    assert result_a.successful_coordinates ==
             Enum.sort([
               "hex:crosswake@0.2.2",
               "swift:crosswake-shell-core-ios@0.2.2",
               "maven:io.crosswake:crosswake-shell-core@0.2.2"
             ])

    for {a, b} <- Enum.zip(result_a.successful_coordinates, result_b.successful_coordinates) do
      refute a == b
    end

    assert result_a.state == result_b.state
    assert result_a.version == "0.2.2"
    assert result_b.version == "9.9.9"

    # receipt_external_state's pass/fail topology (publication, failed_step, changed,
    # all_linked_proven) is version-independent; its embedded successful_coordinates is
    # necessarily version-bearing, same as the top-level field above.
    topology_keys = [:publication, :failed_step, :changed, :all_linked_proven]

    assert Map.take(result_a.receipt_external_state, topology_keys) ==
             Map.take(result_b.receipt_external_state, topology_keys)

    assert result_a.receipt_external_state.successful_coordinates ==
             result_a.successful_coordinates

    assert result_b.receipt_external_state.successful_coordinates ==
             result_b.successful_coordinates
  end

  test "rollup! requires a version key and rejects non-semver version strings" do
    children = %{
      hex: "success",
      ios_mirror: "success",
      android: "success",
      ios_public_proof: "success",
      android_public_proof: "success",
      exact_public: "success"
    }

    assert_raise ArgumentError, "release workflow observation is invalid", fn ->
      Workflow.rollup!(%{
        approved_ref: String.duplicate("a", 40),
        candidate_receipt: String.duplicate("b", 64),
        children: children
      })
    end

    for bad_version <- ["0.2", "0.2.1-rc1", "v0.2.1", "0.2.1.0", "latest", ""] do
      assert_raise ArgumentError, "release workflow observation is invalid", fn ->
        Workflow.rollup!(rollup_input(children, bad_version))
      end
    end
  end

  test "validate! round-trips a non-candidate version and rejects a version/coordinate mismatch" do
    children = %{
      hex: "success",
      ios_mirror: "success",
      android: "success",
      ios_public_proof: "success",
      android_public_proof: "success",
      exact_public: "success"
    }

    result = Workflow.rollup!(rollup_input(children, "3.4.5"))
    assert Workflow.validate!(result) == result

    assert_raise ArgumentError, "release workflow observation is invalid", fn ->
      Workflow.validate!(%{result | version: "9.9.9"})
    end
  end

  defp job_block(workflow, job) do
    regex = ~r/(?ms)^  #{Regex.escape(job)}:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/

    case Regex.run(regex, workflow, capture: :all_but_first) do
      [block] -> block
      _ -> ""
    end
  end

  defp rollup_input(children, version \\ "0.2.1") do
    %{
      approved_ref: String.duplicate("a", 40),
      candidate_receipt: String.duplicate("b", 64),
      children: children,
      version: version
    }
  end

  defp coordinate(:hex), do: "hex:crosswake@0.2.1"
  defp coordinate(:ios_mirror), do: "swift:crosswake-shell-core-ios@0.2.1"
  defp coordinate(:android), do: "maven:io.crosswake:crosswake-shell-core@0.2.1"
end
