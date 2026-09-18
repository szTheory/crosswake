defmodule Crosswake.Proof.Phase173RecoveryProofConvergenceTest do
  @moduledoc """
  Merge-blocking proof that BOTH Hex publication lanes satisfy one publication-record
  contract, decided by one checker against one declared lane roster.

  A proof body shared by two callers is only as good as the evidence that both callers
  actually satisfy it. Without fixtures, "identically" is a resemblance an author
  asserts, not a property a check decides — so every check this module names is
  exercised by a fixture that turns it RED, built by mutating the REAL workflow text
  through `Crosswake.ReleaseWorkflowFixtures`' raise-on-no-op guard.

  Two fixtures model two graphs: the ordinary `release-please.yml` graph and the
  `workflow_dispatch` recovery graph in `hex-publish.yml`. Each lane has its own
  removal fixture, because a single fixture covering "some lane" would let one lane
  regress while the check stayed green — the exact failure mode this phase closes.
  """

  use ExUnit.Case, async: true

  alias Crosswake.ReleaseWorkflowFixtures, as: Fixtures

  @release_workflow ".github/workflows/release-please.yml"
  @recovery_workflow ".github/workflows/hex-publish.yml"
  @proof_workflow ".github/workflows/exact-public-proof.yml"

  @identical "release.recovery.publication_record_identical"
  @fails_closed "release.recovery.proof_record_fails_closed"
  @lane_gated "release.recovery.proof_applicability_lane_gated"

  @new_check_ids [@identical, @fails_closed, @lane_gated]

  describe "the real tree" do
    test "emits every phase-173 check as passing" do
      {output, exit_code} = Fixtures.run_scanner(@release_workflow)

      assert exit_code == 0, output

      for id <- @new_check_ids do
        assert output =~ "[crosswake] OK: #{id}", "expected #{id} to pass, got:\n#{output}"
      end
    end
  end

  describe "the publication-record contract, per lane" do
    test "the ORDINARY lane losing its record-writing step turns the identity check red" do
      mutated =
        Fixtures.remove_step!(real_release(), "publish-hex", "Write the publication record")

      assert_red!(@identical, %{release_workflow: mutated})
    end

    # The criterion this plan exists to decide, so it is asserted as a PAIR in one body:
    # a red-only assertion cannot tell a check that is genuinely sensitive to the recovery
    # graph from one that fails on every input. The control's green is asserted explicitly.
    test "the RECOVERY lane losing its record-writing step turns the identity check red, while an unmutated control stays green" do
      mutated = Fixtures.remove_step!(real_recovery(), "publish", "Write the publication record")

      {mutated_output, mutated_code} = Fixtures.run_fixture_set(%{recovery_workflow: mutated})

      assert mutated_code == 1, mutated_output
      assert mutated_output =~ "[crosswake] FAIL: #{@identical}"
      assert mutated_output =~ "recovery lane"

      {control_output, control_code} =
        Fixtures.run_fixture_set(%{recovery_workflow: real_recovery()})

      assert control_code == 0, control_output
      assert control_output =~ "[crosswake] OK: #{@identical}"
      refute control_output =~ "[crosswake] FAIL:"
    end

    test "two callers naming different reusable workflows turn the identity check red, though both lanes still write a record" do
      mutated =
        Fixtures.replace_in_job(
          real_recovery(),
          "recovery-exact-public-proof",
          "uses: ./.github/workflows/exact-public-proof.yml",
          "uses: ./.github/workflows/exact-public-proof-recovery.yml"
        )

      # The record-writing step is untouched: this is precisely the drift a
      # presence-only check passes and an identity check catches.
      assert mutated =~ "bash script/write_publication_record.sh"

      assert_red!(@identical, %{recovery_workflow: mutated})
    end

    test "a caller job losing its actions: read grant turns the identity check red" do
      mutated =
        Fixtures.replace_in_job(
          real_recovery(),
          "recovery-exact-public-proof",
          "    permissions:\n      actions: read\n      contents: write\n      pull-requests: write\n",
          "    permissions:\n      contents: write\n      pull-requests: write\n"
        )

      {output, exit_code} = Fixtures.run_fixture_set(%{recovery_workflow: mutated})

      assert exit_code == 1, output
      assert output =~ "[crosswake] FAIL: #{@identical}"
      assert output =~ "actions: read"
    end
  end

  describe "the shared proof body fails closed" do
    test "a job condition gating on an upstream result turns the fails-closed check red" do
      mutated =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          "if: ${{ always() }}",
          "if: ${{ needs.publish.result == 'success' }}"
        )

      assert_red!(@fails_closed, %{exact_public_proof_workflow: mutated})
    end

    test "swallowing the record assertion's failure turns the fails-closed check red" do
      continue_on_error =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          "      - name: Assert the publication record for the exact coordinate\n",
          "      - name: Assert the publication record for the exact coordinate\n        continue-on-error: true\n"
        )

      or_true =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          ~s(          --record "$RUNNER_TEMP/publication-record/publication-record.json"),
          ~s(          --record "$RUNNER_TEMP/publication-record/publication-record.json" || true)
        )

      assert_red!(@fails_closed, %{exact_public_proof_workflow: continue_on_error})
      assert_red!(@fails_closed, %{exact_public_proof_workflow: or_true})
    end

    test "reading the expected version out of the record turns the fails-closed check red" do
      mutated =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          "VERSION: ${{ inputs.version }}",
          "VERSION: ${{ steps.record.outputs.version }}"
        )

      assert_red!(@fails_closed, %{exact_public_proof_workflow: mutated})
    end

    # Pairs with the conjunct that FORBIDS record-derived provenance, as distinct from
    # the one that REQUIRES input-derived provenance. Here the three input-sourced
    # assignments all remain, so only the forbidding conjunct can flip — without this
    # fixture that conjunct would be unfalsified, and an unfalsified conjunct in an AND
    # is indistinguishable from a dead one.
    test "adding a record-derived expected value alongside the input-derived ones turns the fails-closed check red" do
      mutated =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          "          RUN_ID: ${{ github.run_id }}\n",
          "          RUN_ID: ${{ github.run_id }}\n          VERSION: ${{ steps.record.outputs.version }}\n"
        )

      assert mutated =~ "VERSION: ${{ inputs.version }}"

      assert_red!(@fails_closed, %{exact_public_proof_workflow: mutated})
    end
  end

  describe "the not-applicable branch is reachable from the ordinary lane only" do
    # hex-publish.yml declares approved_head and merge_oid as `required: false` with
    # `default: ''`, and the recovery caller passes them straight through. Un-laned,
    # the applicability step answers "not a linked release" to a blank recovery
    # dispatch, every proof step is skipped by its step-level `if:`, and the job
    # concludes SUCCESS after a real publish. Absence scored as success, inside the
    # artifact built to remove it.
    test "restoring the un-laned branch turns the lane-gate check red, while an unmutated control stays green" do
      mutated =
        Fixtures.replace_in_job(
          real_proof(),
          "exact-public-proof",
          ~s(if [ "$LANE" != "ordinary" ]; then),
          "if false; then"
        )

      {mutated_output, mutated_code} =
        Fixtures.run_fixture_set(%{exact_public_proof_workflow: mutated})

      assert mutated_code == 1, mutated_output
      assert mutated_output =~ "[crosswake] FAIL: #{@lane_gated}"
      assert mutated_output =~ "recovery lane"

      {control_output, control_code} =
        Fixtures.run_fixture_set(%{exact_public_proof_workflow: real_proof()})

      assert control_code == 0, control_output
      assert control_output =~ "[crosswake] OK: #{@lane_gated}"
      refute control_output =~ "[crosswake] FAIL:"
    end

    # Pairs with the ordering conjunct, which the un-laned fixture above cannot reach:
    # here the gate itself survives, and only the requirement that the lane be VALIDATED
    # before any branch can exit zero on it is broken. This restores the pre-fix ordering
    # exactly — the lane `case` used to sit below the applicability branch, so an
    # unvalidated lane decided whether to skip the proof.
    test "validating the lane only after the branch that exits zero on it turns the lane-gate check red" do
      lane_case = """
                case "$LANE" in
                  ordinary|recovery) ;;
                  *)
                    echo "[crosswake] FAIL: lane '${LANE}' is not a declared publication lane."
                    echo "[crosswake] What to do next: call this workflow with lane: ordinary (release-please.yml) or lane: recovery (hex-publish.yml)."
                    exit 1
                    ;;
                esac

      """

      moved =
        real_proof()
        |> Fixtures.replace_in_job("exact-public-proof", lane_case, "")
        |> Fixtures.replace_in_job(
          "exact-public-proof",
          ~s(          printf '%s' "$APPROVED_HEAD" | grep -Eq),
          lane_case <> ~s(          printf '%s' "$APPROVED_HEAD" | grep -Eq)
        )

      assert moved =~ ~s(case "$LANE" in)
      assert moved =~ ~s(if [ "$LANE" != "ordinary" ]; then)

      assert_red!(@lane_gated, %{exact_public_proof_workflow: moved})
    end
  end

  defp assert_red!(check_id, fixtures) do
    {output, exit_code} = Fixtures.run_fixture_set(fixtures)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: #{check_id}"
  end

  defp real_release, do: File.read!(@release_workflow)
  defp real_recovery, do: File.read!(@recovery_workflow)
  defp real_proof, do: File.read!(@proof_workflow)
end
