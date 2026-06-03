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
    assert "closeout.validation.prior_debt" in ids
    assert "closeout.handoff.thread_seed_disposition" in ids

    rendered = CloseoutVerifier.render(report)
    assert rendered =~ "closeout.verify"
    assert rendered =~ "posture=merge-blocking"
  end

  test "missing closeout frontmatter fails closed with a closeout stable id" do
    tmp = tmp_dir!("missing-frontmatter")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/v3.9-CLOSEOUT.md"),
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
      Path.join(tmp, ".planning/milestones/v3.9-CLOSEOUT.md"),
      """
      ---
      milestone: v3.9
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

  test "prior validation-ledger debt from another milestone blocks closeout" do
    tmp = tmp_dir!("prior-debt-blocks")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)
    write_prior_closeout!(tmp, "v3.6", "routed", revisit_phase: "48")

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.validation.prior_debt")

    assert report.status == :failed
    assert check.blocking
    assert check.observed =~ "v3.6"
  end

  test "prior debt satisfied by compliant ledgers passes closeout" do
    tmp = tmp_dir!("prior-debt-satisfied-ledgers")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)
    write_prior_closeout!(tmp, "v3.6", "routed", revisit_phase: "48", expected_phases: ["48"])

    # Write a compliant archived VALIDATION.md for phase 48 under v3.6-phases
    ledger_dir = Path.join(tmp, ".planning/milestones/v3.6-phases/48-x")
    File.mkdir_p!(ledger_dir)
    File.write!(Path.join(ledger_dir, "48-VALIDATION.md"), "nyquist_compliant: true\n")

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.validation.prior_debt")

    refute check.blocking
    assert check.result == :pass
  end

  test "prior debt satisfied by status: resolved passes closeout" do
    tmp = tmp_dir!("prior-debt-satisfied-resolved")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)
    write_prior_closeout!(tmp, "v3.6", "resolved", revisit_phase: "48", expected_phases: [])

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.validation.prior_debt")

    refute check.blocking
    assert check.result == :pass
  end

  test "stale deferral is surfaced as blocking with stale annotation" do
    tmp = tmp_dir!("stale-deferral")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)
    write_prior_closeout!(tmp, "v3.6", "routed", revisit_phase: "48")

    # Create an archived phases dir to make phase 48 appear shipped (stale)
    stale_dir = Path.join(tmp, ".planning/milestones/v3.7-phases/48-x")
    File.mkdir_p!(stale_dir)

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.validation.prior_debt")

    assert check.blocking
    assert check.observed =~ "stale"
  end

  test "validation_ledger_check flags archived missing ledger as blocking when no deferral" do
    tmp = tmp_dir!("archived-missing-ledger")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    # Closeout referencing phase 48 with no validation deferral but status complete
    File.write!(
      Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md"),
      """
      ---
      milestone: v3.6
      milestone_name: Test Milestone
      status: complete
      shipped_date: 2026-01-01
      requirements_state: {status: complete}
      roadmap_parity: {status: complete}
      phase_verification_coverage:
        status: complete
        expected_phases: ["48", "49"]
      summary_frontmatter_coverage: {status: complete}
      validation_ledger_status:
        status: complete
      thread_seed_disposition: {status: complete}
      release_changelog_continuity: {status: complete}
      public_support_claim_changes: {status: complete}
      deferred_with_reason: []
      exceptions: []
      resolved_gaps: []
      ---
      """
    )

    write_minimal_files!(tmp)

    # Write a compliant archived ledger only for phase 48, leave phase 49 missing
    ledger_dir = Path.join(tmp, ".planning/milestones/v3.6-phases/48-x")
    File.mkdir_p!(ledger_dir)
    File.write!(Path.join(ledger_dir, "48-VALIDATION.md"), "nyquist_compliant: true\n")

    report =
      CloseoutVerifier.run(
        cwd: tmp,
        closeout_path: Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md")
      )

    check = find_check!(report, "closeout.validation.ledger")

    assert check.blocking
    assert check.observed =~ "49"
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
      Path.join(tmp, ".planning/milestones/v3.9-CLOSEOUT.md"),
      """
      ---
      milestone: v3.9
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
    File.write!(Path.join(tmp, ".planning/REQUIREMENTS.md"), "| REL-01 | Phase 63 | Validated |")
    File.write!(Path.join(tmp, ".planning/ROADMAP.md"), "$gsd-discuss-phase 48")
    File.write!(Path.join(tmp, "CHANGELOG.md"), File.read!("CHANGELOG.md"))
  end

  defp write_prior_closeout!(tmp, milestone_id, status, opts) do
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))
    revisit = Keyword.get(opts, :revisit_phase, "99")
    expected = Keyword.get(opts, :expected_phases, ["48", "49", "50", "51", "52", "53"])
    expected_str = Enum.map_join(expected, ", ", &~s("#{&1}"))

    File.write!(
      Path.join(tmp, ".planning/milestones/#{milestone_id}-CLOSEOUT.md"),
      """
      ---
      milestone: #{milestone_id}
      milestone_name: Prior Milestone
      status: complete
      shipped_date: 2026-01-01
      requirements_state: {status: complete}
      roadmap_parity: {status: complete}
      phase_verification_coverage:
        status: deferred_with_reason
        expected_phases: [#{expected_str}]
      summary_frontmatter_coverage: {status: complete}
      validation_ledger_status:
        status: deferred_with_reason
      thread_seed_disposition: {status: complete}
      release_changelog_continuity: {status: complete}
      public_support_claim_changes: {status: complete}
      deferred_with_reason:
        - owner: maintainer
          scope: validation-ledger-finalization
          reason: "Draft ledgers remain bookkeeping gaps."
          revisit_phase: #{revisit}
          evidence: ".planning/phases/*/*-VALIDATION.md"
          status: #{status}
      exceptions: []
      resolved_gaps: []
      ---
      """
    )
  end
end
