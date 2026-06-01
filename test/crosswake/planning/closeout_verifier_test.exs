defmodule Crosswake.Planning.CloseoutVerifierTest do
  use ExUnit.Case, async: true

  alias Crosswake.Planning.CloseoutVerifier

  test "report exposes stable closeout check ids and actionable render text" do
    report = CloseoutVerifier.run(cwd: File.cwd!())

    assert report.schema_version == "1.0.0"
    assert report.status in [:passed, :failed]
    assert is_map(report.summary)

    ids = Enum.map(report.checks, & &1.id)
    assert "closeout.ledger.frontmatter" in ids
    assert "closeout.exceptions.deferred_shape" in ids
    assert "closeout.release.changelog_continuity" in ids
    assert "closeout.requirements.state" in ids
    assert "closeout.roadmap.parity" in ids
    assert "closeout.verification.coverage" in ids
    assert "closeout.summaries.frontmatter" in ids
    assert "closeout.validation.ledger" in ids
    assert "closeout.handoff.thread_seed_disposition" in ids

    rendered = CloseoutVerifier.render(report)
    assert rendered =~ "closeout.verify"
    assert rendered =~ "posture=merge-blocking"
  end

  test "missing closeout frontmatter fails closed with a closeout stable id" do
    tmp = tmp_dir!("missing-frontmatter")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md"),
      "# Missing frontmatter\n"
    )

    write_minimal_files!(tmp)

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.ledger.frontmatter")

    assert report.status == :failed
    assert check.blocking
    assert check.observed =~ "milestone"
    assert CloseoutVerifier.render(report) =~ "closeout.ledger.frontmatter"
  end

  test "malformed deferred_with_reason entries fail closed" do
    tmp = tmp_dir!("malformed-deferred")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md"),
      """
      ---
      milestone: v3.6
      milestone_name: Operator Truth and Production Diagnostics
      status: live
      shipped_date: null
      requirements_state: {status: pending}
      roadmap_parity: {status: pending}
      phase_verification_coverage: {status: pending}
      summary_frontmatter_coverage: {status: pending}
      validation_ledger_status: {status: pending}
      thread_seed_disposition: {status: pending}
      release_changelog_continuity: {status: pending}
      public_support_claim_changes: {status: pending}
      deferred_with_reason:
        - owner: maintainer
          scope: validation-ledger-finalization
      exceptions: []
      resolved_gaps: []
      ---
      """
    )

    write_minimal_files!(tmp)

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.exceptions.deferred_shape")

    assert check.blocking
    assert check.observed =~ "reason"
    assert check.hint =~ "owner, scope, reason"
  end

  test "release continuity requires the richer unreleased split and rejects false shipped language" do
    tmp = tmp_dir!("release-continuity")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)

    File.write!(
      Path.join(tmp, "CHANGELOG.md"),
      """
      # Changelog

      ## [Unreleased]

      StoreKit provider adapter shipped.

      ## [0.1.0]
      """
    )

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.release.changelog_continuity")

    assert check.blocking
    assert "Unpublished support claims" in check.details.missing_sections
    assert "StoreKit provider adapter shipped" in check.details.false_claims
  end

  defp find_check!(report, id) do
    Enum.find(report.checks, &(&1.id == id)) || flunk("missing check #{id}")
  end

  defp tmp_dir!(name) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-closeout-#{name}-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end

  defp write_complete_closeout!(tmp) do
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md"),
      """
      ---
      milestone: v3.6
      milestone_name: Operator Truth and Production Diagnostics
      status: complete
      shipped_date: 2026-06-01
      requirements_state: {status: complete}
      roadmap_parity: {status: complete}
      phase_verification_coverage: {status: complete}
      summary_frontmatter_coverage: {status: complete}
      validation_ledger_status: {status: complete}
      thread_seed_disposition: {status: complete}
      release_changelog_continuity: {status: complete}
      public_support_claim_changes: {status: complete}
      deferred_with_reason: []
      exceptions: []
      resolved_gaps: []
      ---
      """
    )
  end

  defp write_minimal_files!(tmp) do
    File.mkdir_p!(Path.join(tmp, ".planning"))
    File.write!(Path.join(tmp, ".planning/REQUIREMENTS.md"), "| REL-01 | Phase 53 | Validated |")
    File.write!(Path.join(tmp, ".planning/ROADMAP.md"), "$gsd-discuss-phase 48")
    File.write!(Path.join(tmp, "CHANGELOG.md"), File.read!("CHANGELOG.md"))
  end
end
