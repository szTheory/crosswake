defmodule Crosswake.ReleaseCandidate.WorkflowTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Workflow

  @hex_workflow ".github/workflows/hex-publish.yml"
  @ios_workflow ".github/workflows/ios-mirror-backfill.yml"
  @release_workflow ".github/workflows/release-please.yml"
  @proof_workflow ".github/workflows/exact-public-proof.yml"
  @proof_uses "uses: ./.github/workflows/exact-public-proof.yml"
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
    proof_workflow = File.read!(@proof_workflow)

    assert ios_workflow =~ "candidate-receipt-attestation"
    assert attestation =~ "phase168-candidate-ci-${CANDIDATE_HEAD}"
    assert attestation =~ "candidate-rehearsal-hex"
    assert attestation =~ "candidate-rehearsal-ios"
    assert attestation =~ "Decode closed attestation run selector"
    assert attestation =~ "assemble_attested_receipt.exs"
    assert attestation =~ "Crosswake.ReleaseCandidate.Receipt.validate!"
    assert attestation =~ "phase168-candidate-receipt-${{ inputs.candidate_head }}"
    assert attestation =~ "candidate-receipt.json"
    assert attestation =~ "artifacts.json"

    assert guard =~ "phase168-candidate-receipt-${approved_head}"
    assert guard =~ "candidate_receipt_run_id"
    assert guard =~ "phase168-candidate-ci-${approved_head}"
    assert guard =~ "release-candidate-ci-receipt.json"
    # Phase 173-01 Task 2 MOVED the candidate-receipt download out of the
    # exact-public-proof job block and into the reusable proof workflow. These
    # assertions follow their subject; none of them was deleted, and each moved
    # assertion gained a companion asserting the caller passes the matching
    # input. An assertion dropped because its subject moved is the
    # absence-scored-as-success defect this milestone exists to remove.
    assert proof_workflow =~
             ~s(gh run download "$RUN_ID" --name "phase168-candidate-receipt-${{ inputs.approved_head }}")

    assert proof_workflow =~ "RUN_ID: ${{ inputs.candidate_receipt_run_id }}"
    assert proof_workflow =~ "artifacts.json"

    assert exact_public =~ "candidate_receipt_run_id"

    assert exact_public =~
             "candidate_receipt_run_id: ${{ needs.approved-release-guard.outputs.candidate_receipt_run_id }}"

    assert exact_public =~
             "approved_head: ${{ needs.approved-release-guard.outputs.approved_head }}"

    refute exact_public =~ "phase168-candidate-receipt-"

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

  test "linked release rollup resolves locked dependencies before evaluating project code" do
    workflow = File.read!(@release_workflow)
    rollup = job_block(workflow, "linked-release-rollup")

    assert rollup != "", "no linked-release-rollup job found in #{@release_workflow}"

    assert {deps_offset, _length} =
             :binary.match(rollup, "mix deps.get --check-locked"),
           "linked-release-rollup must resolve the locked dependency graph"

    assert {evaluator_offset, _length} =
             :binary.match(
               rollup,
               "mix run --no-start -e 'Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()'"
             ),
           "linked-release-rollup must execute the release evaluator"

    assert deps_offset < evaluator_offset,
           "linked-release-rollup must resolve dependencies before invoking project code"
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

  # Phase 173-03 Task 1 (ROADMAP SC#3, XPUB-07). The every-child-failure loop
  # above CANNOT construct the combination that matters most here. That loop
  # marks every child AFTER the failed one as "skipped", so the exact-public
  # child -- last in the order -- is only ever reached as "failed", with nothing
  # after it to be skipped. A skipped exact-public proof standing beside five
  # successes was therefore never asserted anywhere in this suite. It is
  # constructed directly below rather than folded into that loop, because
  # burying it there would hide the fact that the loop cannot reach it.
  #
  # `lib/crosswake/release_candidate/workflow.ex` is NOT modified by this phase.
  # The criterion is that its fail-closed semantics are UNCHANGED; editing the
  # module to make any assertion below pass would invert the criterion.
  @five_successes %{
    hex: "success",
    ios_mirror: "success",
    android: "success",
    ios_public_proof: "success",
    android_public_proof: "success"
  }

  test "a skipped exact-public proof beside five successes still rolls up not-complete" do
    children = Map.put(@five_successes, :exact_public, "skipped")

    result = Workflow.rollup!(rollup_input(children))

    refute result.state == "COMPLETE"
    assert result.state == "PARTIAL"
    assert result.failed_step == "exact_public"
    assert result.failed_ref == String.duplicate("a", 40)
    assert result.next_action == "retry_failed_step_from_exact_ref_or_publish_forward_fix"
    assert result.receipt_external_state.all_linked_proven == false

    # The three public coordinates really did publish and are immutable. A
    # fail-closed rollup must refuse to call the release complete WITHOUT
    # erasing them -- both halves, or the refusal is useless for recovery.
    assert result.successful_coordinates ==
             Enum.sort([coordinate(:hex), coordinate(:ios_mirror), coordinate(:android)])
  end

  test "a skipped exact-public proof is not distinguished from a failed one" do
    skipped = Workflow.rollup!(rollup_input(Map.put(@five_successes, :exact_public, "skipped")))
    failed = Workflow.rollup!(rollup_input(Map.put(@five_successes, :exact_public, "failed")))

    assert skipped.state == failed.state
    assert skipped.failed_step == failed.failed_step
    assert skipped.failed_ref == failed.failed_ref
    assert skipped.next_action == failed.next_action
    assert skipped.successful_coordinates == failed.successful_coordinates
    assert skipped.receipt_external_state == failed.receipt_external_state

    # Equality alone would also hold if BOTH rolled up to COMPLETE, so the
    # direction is pinned: it is the skip that is dragged down to the failure,
    # never the failure lifted up to the skip.
    assert skipped.failed_step == "exact_public"
    refute skipped.state == "COMPLETE"
  end

  test "no accepted non-success status for the exact-public child ever yields COMPLETE" do
    non_success = ~w(failed skipped)

    # Cardinality pinned at the assertion site. The module accepts exactly three
    # statuses, so these two ARE the whole non-success set rather than a sample
    # of it; the rejection sweep below is what makes that claim falsifiable.
    assert length(non_success) == 2

    for status <- non_success do
      result = Workflow.rollup!(rollup_input(Map.put(@five_successes, :exact_public, status)))

      refute result.state == "COMPLETE", "exact_public=#{status} produced COMPLETE"
      assert result.failed_step == "exact_public"
    end

    # `cancelled` is a real GitHub job result and is NOT in the accepted set: it
    # is rejected outright rather than silently tolerated as some third thing.
    for rejected <- ["cancelled", "neutral", "SUCCESS", "success ", ""] do
      assert_raise ArgumentError, "release workflow observation is invalid", fn ->
        Workflow.rollup!(rollup_input(Map.put(@five_successes, :exact_public, rejected)))
      end
    end

    # Control: the sweep is sensitive to the status, not failing on every input.
    assert Workflow.rollup!(rollup_input(Map.put(@five_successes, :exact_public, "success"))).state ==
             "COMPLETE"
  end

  test "the rollup still depends on the exact-public proof job and still reads its result" do
    workflow = File.read!(@release_workflow)
    rollup = strip_full_line_comments(job_block(workflow, "linked-release-rollup"))

    assert rollup != "", "no linked-release-rollup job found in #{@release_workflow}"

    needs =
      rollup
      |> String.split("\n")
      |> Enum.drop_while(&(String.trim(&1) != "needs:"))
      |> Enum.drop(1)
      |> Enum.take_while(&String.starts_with?(&1, "      - "))
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

    # Cardinality pinned: the eight dependencies the rollup is declared with. A
    # bare `in` on an unpinned list cannot tell a preserved edge from a list
    # that grew a near-duplicate.
    assert length(needs) == 8
    assert "exact-public-proof" in needs

    # The dependency alone proves ordering, not observation. This is the edge
    # that 173-01's graph change could have severed: the rollup must still read
    # that job's result into the child state the fail-closed comparison above
    # consumes.
    assert rollup =~ "EXACT_PUBLIC_STATE: ${{ needs.exact-public-proof.result }}"

    # ...and the job it depends on really is the reusable-workflow CALLER that
    # 173-01 made it, so the result being read is a caller's aggregate result
    # and not a leftover inline job that happens to share the name.
    proof_job = strip_full_line_comments(job_block(workflow, "exact-public-proof"))
    assert proof_job =~ @proof_uses
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

  test "one reusable workflow carries the only copy of the exact-public proof body" do
    proof_workflow = File.read!(@proof_workflow)

    assert proof_workflow =~ "workflow_call:"
    assert proof_workflow =~ "bash script/assert_publication_record.sh"
    assert proof_workflow =~ "--source-mode exact-public"

    # No `secrets:` key at all. The proof body reads only the ambient job token;
    # inheriting secrets it does not need is an elevation-of-privilege shape.
    refute proof_workflow =~ ~r/^\s*secrets:/m

    assert proof_workflow =~ "actions: read"
    assert proof_workflow =~ "contents: read"

    # The expected triple comes from the workflow's OWN inputs, never from the
    # record being verified (SEED-019).
    assert proof_workflow =~ ~s(--package "$PACKAGE")
    assert proof_workflow =~ ~s(--version "$VERSION")
    assert proof_workflow =~ ~s(--approved-head "$APPROVED_HEAD")
    assert proof_workflow =~ "PACKAGE: ${{ inputs.package }}"
    assert proof_workflow =~ "VERSION: ${{ inputs.version }}"
    assert proof_workflow =~ "APPROVED_HEAD: ${{ inputs.approved_head }}"

    # The record decision is made by a step that RUNS, before the proof body.
    assert :binary.match(proof_workflow, "bash script/assert_publication_record.sh") <
             :binary.match(proof_workflow, "--source-mode exact-public")

    # Exactly one copy of the proof body exists across the release graph.
    for lane_workflow <- [@release_workflow, @hex_workflow] do
      refute File.read!(lane_workflow) =~ "--source-mode exact-public"
    end
  end

  test "both publish lanes emit one publication record through the one shared emitter" do
    release_workflow = File.read!(@release_workflow)
    hex_workflow = File.read!(@hex_workflow)
    ordinary = job_block(release_workflow, "publish-hex")
    recovery = job_block(hex_workflow, "publish")

    emitter_flags = ~w(--package --version --approved-head --ref --lane --run-id --output)

    for block <- [ordinary, recovery] do
      assert block =~ "bash script/write_publication_record.sh"

      # Same flags, in the same order, in both lanes. Scoped to the emitter
      # invocation itself: matching over the whole job block would pick up the
      # guarded_hex_publish.sh flags above it and prove nothing about this one.
      invocation = emitter_invocation(block)

      assert emitter_flags
             |> Enum.map(fn flag ->
               assert invocation =~ flag
               {at, _len} = :binary.match(invocation, flag)
               at
             end)
             |> then(&(&1 == Enum.sort(&1)))

      assert block =~ "if-no-files-found: error"
      assert block =~ "name: publication-record-"
    end

    assert ordinary =~ ~s(--lane "ordinary")
    assert recovery =~ ~s(--lane "recovery")

    # Exactly one emitter invocation per lane -- a second would make the record
    # ambiguous about which publish it attests.
    assert length(String.split(ordinary, "bash script/write_publication_record.sh")) == 2
    assert length(String.split(recovery, "bash script/write_publication_record.sh")) == 2

    # The pre-merge candidate receipt is a DIFFERENT artifact with a different
    # meaning (it asserts nothing had been published yet). The post-publish
    # record must never be folded into it.
    refute ordinary =~ "phase168-candidate-receipt"
    refute recovery =~ "phase168-candidate-receipt"
  end

  test "native recovery is deliberately left outside this phase's Hex convergence" do
    hex_workflow = File.read!(@hex_workflow)
    android_recovery = job_block(hex_workflow, "recover-android-core")

    refute android_recovery =~ @proof_uses
    refute android_recovery =~ "script/write_publication_record.sh"
  end

  test "every caller of the reusable exact-public proof grants actions: read at job level" do
    callers = proof_callers()

    # Absence must never score as success: with zero callers every assertion in
    # the loop below would pass vacuously, and this check would silently stop
    # guarding anything.
    assert callers != [], "no job anywhere calls #{@proof_uses}"

    # Both lanes, by name, plus the credential-free fire drill (Phase 173-04):
    # `callers != []` alone would still pass if the recovery lane silently
    # stopped calling the shared proof, or if the fire drill silently started
    # calling a private copy instead -- which is the exact convergence and
    # non-drift this phase exists to establish and hold.
    assert Enum.sort(Enum.map(callers, fn {path, job, _block} -> {path, job} end)) ==
             Enum.sort([
               {@release_workflow, "exact-public-proof"},
               {@hex_workflow, "recovery-exact-public-proof"},
               {@hex_workflow, "recovery-fire-drill"}
             ])

    # `record_verdict: false` is the one way a caller reaches the proof body
    # without its verdict entering the release ledger, the copy of record that
    # outlives the proof artifact. Exactly one caller may do that: the drill,
    # which is not a release and must not be written down as one. A REAL lane
    # acquiring this input is a release that quietly stops being recorded --
    # absence scored as success, invisible by construction unless pinned here.
    opted_out =
      for {path, job, block} <- callers,
          block =~ ~r/^\s+record_verdict:\s+false\s*$/m,
          do: {path, job}

    assert Enum.sort(opted_out) == [{@hex_workflow, "recovery-fire-drill"}]

    # Character-identical `uses:` from both lanes. A near-copy is how two lanes
    # drift while each still looks correct in isolation.
    assert callers
           |> Enum.map(fn {_path, _job, block} ->
             block
             |> String.split("\n")
             |> Enum.find(&String.contains?(&1, @proof_uses))
             |> String.trim()
           end)
           |> Enum.uniq() == [@proof_uses]

    for {path, job, block} <- callers do
      # Runtime authorization, not syntax. Both lane workflows declare a
      # top-level `permissions:` key, so `actions` is `none` for any job that
      # does not grant it, and a called workflow can only NARROW the caller's
      # token -- never widen it. Dropping this block yields a forbidden response
      # at release time on a real release; actionlint cannot decide that, which
      # is why it is asserted here rather than linted.
      assert block =~ "permissions:", "#{path} job #{job} declares no job-level permissions block"
      assert block =~ "actions: read", "#{path} job #{job} does not grant actions: read"

      # Every scope the called file asks for anywhere, asserted by VALUE against
      # what this caller grants. The requirement is DERIVED from
      # #{@proof_workflow} rather than written down here, because the binding
      # rule is a property of that file: GitHub validates EVERY nested job's
      # `permissions:` request against the calling job's grant when the workflow
      # is parsed -- before any `if:` runs, and for every job in the file no
      # matter which operation was dispatched. So the real requirement on a
      # caller is the scope-wise MAXIMUM over the called file's jobs, not the
      # need of whichever job comes to mind.
      #
      # This check previously hard-coded `contents in ["read", "write"]` on the
      # reasoning that the proof body only reads. That reasoning is true and
      # irrelevant: `record-ledger` in the same file requests `contents: write`
      # and `pull-requests: write`, so `contents: read` is never sufficient. A
      # caller shipped under-granted on exactly that permissive branch and made
      # the ENTIRE hex-publish.yml invalid -- every dispatch of it, candidate
      # rehearsal and real emergency recovery alike, ended in `startup_failure`
      # with no job at all (runs 35299245680 and 35299415965 on 91bcb093).
      for {scope, needed} <- required_caller_grants() do
        granted =
          case Regex.run(~r/^\s+#{Regex.escape(scope)}:\s+(\S+)/m, block, capture: :all_but_first) do
            [value] -> value
            _ -> nil
          end

        assert permission_rank(granted) >= permission_rank(needed),
               "#{path} job #{job} grants #{scope}: #{inspect(granted)}, but #{@proof_workflow} has a job requesting #{scope}: #{needed}. A called workflow can only NARROW the caller's token, so GitHub rejects the whole calling file at parse time and every dispatch of it fails to start."
      end

      refute block =~ "secrets: inherit"

      # A caller job is the reusable workflow call; these keys move INTO the
      # called file and are a parse error if left behind.
      refute block =~ ~r/^    runs-on:/m
      refute block =~ ~r/^    timeout-minutes:/m
      refute block =~ ~r/^    steps:/m
    end
  end

  # Comment prose is not configuration. Without this the caller-permission
  # assertions below would match the explanatory comment that mentions
  # `permissions:` and `actions: read`, and would pass against a caller job that
  # declares neither -- observed while mutation-testing this very check.
  defp strip_full_line_comments(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reject(&(&1 |> String.trim_leading() |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  # The emitter step's own `run:` body, from the script name to the blank line
  # that ends the step.
  defp emitter_invocation(block) do
    [_, rest] = String.split(block, "bash script/write_publication_record.sh", parts: 2)
    [invocation | _] = String.split(rest, "\n\n", parts: 2)
    invocation
  end

  # The scope-wise maximum of every job-level `permissions:` request in the
  # called workflow -- the grant a caller must meet or exceed for GitHub to
  # accept the calling file at all. Read from the file so that a job added there
  # tomorrow raises the bar here automatically instead of silently outrunning a
  # literal written down in this test (SEED-019: a roster derived from the thing
  # it polices is the one shape that cannot catch a new non-compliant subject).
  defp required_caller_grants do
    workflow = File.read!(@proof_workflow)

    [_, jobs_section] = String.split(workflow, ~r/^jobs:\n/m, parts: 2)

    grants =
      ~r/(?ms)^  [A-Za-z0-9_-]+:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
      |> Regex.scan(jobs_section, capture: :all_but_first)
      |> Enum.flat_map(fn [block] ->
        Regex.scan(~r/^\s+([a-z-]+):\s+(read|write)\s*$/m, strip_full_line_comments(block),
          capture: :all_but_first
        )
      end)
      |> Enum.reduce(%{}, fn [scope, value], acc ->
        Map.update(acc, scope, value, fn existing ->
          if permission_rank(value) > permission_rank(existing), do: value, else: existing
        end)
      end)

    # Absence must never score as success: an empty map would make the caller
    # loop above iterate zero times and assert nothing at all.
    assert grants != %{},
           "#{@proof_workflow} declares no job-level permissions; the caller grant check would be vacuous"

    grants
  end

  defp permission_rank(nil), do: 0
  defp permission_rank("none"), do: 0
  defp permission_rank("read"), do: 1
  defp permission_rank("write"), do: 2
  defp permission_rank(_other), do: 0

  defp proof_callers do
    ".github/workflows/*.yml"
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.flat_map(fn path ->
      workflow = File.read!(path)

      ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
      |> Regex.scan(workflow, capture: :all_but_first)
      |> Enum.map(fn [job, block] -> [job, strip_full_line_comments(block)] end)
      |> Enum.filter(fn [_job, block] -> String.contains?(block, @proof_uses) end)
      |> Enum.map(fn [job, block] -> {path, job, block} end)
    end)
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
