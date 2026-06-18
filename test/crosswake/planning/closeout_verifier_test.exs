defmodule Crosswake.Planning.CloseoutVerifierTest do
  use ExUnit.Case, async: true

  alias Crosswake.Planning.CloseoutVerifier
  @fixture_evidence_file "test/crosswake/planning/fixture_validation_test.exs"
  @debt_real_ledger_paths [
    ".planning/milestones/v3.8-phases/54-sigra-session-authority-contract-and-route-gate-semantics/54-VALIDATION.md",
    ".planning/milestones/v3.8-phases/55-session-handoff-tickets-and-authority-projection/55-VALIDATION.md",
    ".planning/milestones/v3.8-phases/56-step-up-intent-and-plug-liveview-ceremony/56-VALIDATION.md",
    ".planning/milestones/v3.8-phases/57-oauth-passkey-and-native-return-boundaries/57-VALIDATION.md",
    ".planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-VALIDATION.md",
    ".planning/milestones/v3.9-phases/62-diagnostics-support-truth-and-docs/62-VALIDATION.md",
    ".planning/milestones/v3.9-phases/63-hermetic-proof-and-advisory-promotion-criteria/63-VALIDATION.md"
  ]
  @debt_v36_exception_path ".planning/milestones/v3.6-VALIDATION-EXCEPTION.md"
  @debt_v36_affected_phases ~w(48 49 52 53)

  test "report exposes stable closeout check ids and actionable render text" do
    report = CloseoutVerifier.run(cwd: File.cwd!())

    assert report.schema_version == "1.0.0"
    assert report.status in [:passed, :failed]
    assert is_map(report.summary)

    ids = Enum.map(report.checks, & &1.id)
    assert "closeout.ledger.frontmatter" in ids
    assert "closeout.exceptions.deferred_shape" in ids
    assert "closeout.expected_phases" in ids
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

  test "no active closeout: closeout-artifact checks stay present but pass" do
    tmp = tmp_dir!("no-active-closeout")
    # write_minimal_files! sets STATE.md milestone: v3.9 but we deliberately do
    # NOT create v3.9-CLOSEOUT.md — i.e. an ordinary mid-milestone planning edit,
    # not a closeout. The gate must not block.
    write_minimal_files!(tmp)

    report = CloseoutVerifier.run(cwd: tmp)

    assert report.status == :passed

    for id <- ~w(
          closeout.ledger.frontmatter
          closeout.expected_phases
          closeout.requirements.state
          closeout.roadmap.parity
          closeout.verification.coverage
          closeout.summaries.frontmatter
          closeout.validation.ledger
          closeout.handoff.thread_seed_disposition
        ) do
      check = find_check!(report, id)
      refute check.blocking, "#{id} should not block when no closeout is active"
      assert check.result == :pass
      assert check.observed =~ "no active closeout"
    end

    # Closeout-independent checks still evaluate normally.
    assert find_check!(report, "closeout.release.changelog_continuity")
    assert find_check!(report, "closeout.validation.prior_debt")
  end

  test "missing expected_phases in an active closeout fails closed without guessed phase observations" do
    tmp = tmp_dir!("missing-expected-phases")
    write_minimal_files!(tmp)

    write_closeout!(tmp,
      phase_verification_coverage: "phase_verification_coverage:\n  status: complete\n"
    )

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.expected_phases")

    assert report.status == :failed
    assert check.blocking
    assert check.observed =~ "missing"

    for id <- ~w(
          closeout.verification.coverage
          closeout.summaries.frontmatter
          closeout.validation.ledger
        ) do
      dependent = find_check!(report, id)
      refute dependent.blocking
      assert dependent.observed =~ "skipped: invalid expected_phases contract"
      refute dependent.observed =~ "64"
      refute dependent.observed =~ "69"
    end
  end

  test "malformed expected_phases contracts are blocking" do
    cases = [
      {"empty inline array",
       "phase_verification_coverage:\n  status: complete\n  expected_phases: []\n"},
      {"junk value",
       "phase_verification_coverage:\n  status: complete\n  expected_phases: definitely-not-an-array\n"},
      {"block list",
       "phase_verification_coverage:\n  status: complete\n  expected_phases:\n    - \"64\"\n"}
    ]

    for {name, coverage} <- cases do
      tmp = tmp_dir!("malformed-expected-#{String.replace(name, " ", "-")}")
      write_minimal_files!(tmp)
      write_closeout!(tmp, phase_verification_coverage: coverage)

      report = CloseoutVerifier.run(cwd: tmp)
      check = find_check!(report, "closeout.expected_phases")

      assert check.blocking, "#{name} should block"
      assert check.observed =~ "expected_phases"
    end
  end

  test "top-level and nested inline expected_phases arrays are accepted" do
    cases = [
      {"top-level", [top_level_expected_phases?: true]},
      {"nested", []}
    ]

    for {name, opts} <- cases do
      tmp = tmp_dir!("valid-expected-#{name}")
      write_minimal_files!(tmp)
      write_closeout!(tmp, opts)
      write_phase_artifacts!(tmp, "64")

      report = CloseoutVerifier.run(cwd: tmp)
      check = find_check!(report, "closeout.expected_phases")

      refute check.blocking
      assert check.result == :pass
      assert check.details.phases == ["64"]
    end
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
    write_evidence_file!(tmp)
    File.write!(Path.join(ledger_dir, "48-VALIDATION.md"), validation_ledger())

    report = CloseoutVerifier.run(cwd: tmp)
    check = find_check!(report, "closeout.validation.prior_debt")

    refute check.blocking
    assert check.result == :pass
  end

  test "prior debt satisfied by status: resolved passes closeout" do
    tmp = tmp_dir!("prior-debt-satisfied-resolved")
    write_complete_closeout!(tmp)
    write_minimal_files!(tmp)
    write_prior_closeout!(tmp, "v3.6", "resolved", revisit_phase: "48", expected_phases: ["48"])

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

  test "validation_ledger_check blocks when an expected phase resolves to zero ledgers" do
    tmp = tmp_dir!("zero-ledgers")
    write_minimal_files!(tmp)
    write_closeout!(tmp, expected_phases: ["64"])
    write_verification_and_summary!(tmp, "64")

    check = find_check!(CloseoutVerifier.run(cwd: tmp), "closeout.validation.ledger")

    assert check.blocking
    assert check.observed =~ "64"
    assert check.details.problematic == ["64"]
  end

  test "validation ledgers require tested_by and structured evidence frontmatter" do
    tmp = tmp_dir!("bare-ledger-evidence")
    write_minimal_files!(tmp)
    write_closeout!(tmp, expected_phases: ["64"])
    write_phase_artifacts!(tmp, "64", validation: "---\nnyquist_compliant: true\n---\n")

    check = find_check!(CloseoutVerifier.run(cwd: tmp), "closeout.validation.ledger")

    assert check.blocking
    assert check.observed =~ "64"
  end

  test "validation ledger evidence rejects missing test files and unsupported commands" do
    cases = [
      {"missing test file", invalid_test_file_ledger()},
      {"unsupported command",
       validation_ledger("""
        - type: command
          ref: "npm test"
       """)}
    ]

    for {name, ledger} <- cases do
      tmp = tmp_dir!("invalid-evidence-#{String.replace(name, " ", "-")}")
      write_minimal_files!(tmp)
      write_closeout!(tmp, expected_phases: ["64"])
      write_phase_artifacts!(tmp, "64", validation: ledger)

      check = find_check!(CloseoutVerifier.run(cwd: tmp), "closeout.validation.ledger")

      assert check.blocking, "#{name} should block"
      assert check.details.problematic == ["64"]
    end
  end

  test "validation ledger evidence accepts local test files, allowed commands, ci runs, and artifacts" do
    cases = [
      {"test file",
       validation_ledger("""
        - type: test_file
          ref: #{@fixture_evidence_file}
       """)},
      {"mix test command",
       validation_ledger("""
        - type: command
          ref: "mix test #{@fixture_evidence_file}"
       """)},
      {"mix compile command",
       validation_ledger("""
        - type: command
          ref: "mix compile"
       """)},
      {"mix closeout.verify command",
       validation_ledger("""
        - type: command
          ref: "mix closeout.verify"
       """)},
      {"ci run",
       validation_ledger("""
        - type: ci_run
          ref: "26498172516"
       """)},
      {"artifact",
       validation_ledger("""
        - type: artifact
          ref: "phase-64-validation"
       """)}
    ]

    for {name, ledger} <- cases do
      tmp = tmp_dir!("valid-evidence-#{String.replace(name, " ", "-")}")
      write_minimal_files!(tmp)
      write_closeout!(tmp, expected_phases: ["64"])
      write_evidence_file!(tmp)
      write_phase_artifacts!(tmp, "64", validation: ledger)

      check = find_check!(CloseoutVerifier.run(cwd: tmp), "closeout.validation.ledger")

      refute check.blocking, "#{name} should pass"
      assert check.result == :pass
    end
  end

  test "accepted validation-ledger exception satisfies a zero-ledger historical phase" do
    tmp = tmp_dir!("accepted-exception")
    write_minimal_files!(tmp)
    write_closeout!(tmp, milestone: "v3.6", expected_phases: ["48"])
    write_validation_exception!(tmp, "v3.6", ["48"])

    check =
      find_check!(
        CloseoutVerifier.run(
          cwd: tmp,
          closeout_path: Path.join(tmp, ".planning/milestones/v3.6-CLOSEOUT.md")
        ),
        "closeout.validation.ledger"
      )

    refute check.blocking
    assert check.result == :pass
  end

  test "DEBT-01 repository source contracts cover historical ledger evidence and the v3.6 exception" do
    cwd = File.cwd!()

    for path <- @debt_real_ledger_paths do
      content = File.read!(Path.join(cwd, path))
      frontmatter = repo_frontmatter!(content)

      assert frontmatter =~ ~r/^nyquist_compliant:\s*true\b/m
      assert frontmatter =~ ~r/^tested_by:\s*\n\s+-\s*"?mix (?:test|compile|closeout\.verify)/m
      assert frontmatter =~ ~r/^evidence:\s*\n/m
      assert Regex.match?(~r/^\s*-\s+type:\s*\w+\s*\n\s+ref:\s*.+$/m, frontmatter)
    end

    v38_check =
      CloseoutVerifier.run(
        cwd: cwd,
        closeout_path: write_repo_closeout_contract!("v3.8", ~w(54 55 56 57 58))
      )
      |> find_check!("closeout.validation.ledger")

    refute v38_check.blocking

    v39_check =
      CloseoutVerifier.run(
        cwd: cwd,
        closeout_path: write_repo_closeout_contract!("v3.9", ~w(62 63))
      )
      |> find_check!("closeout.validation.ledger")

    refute v39_check.blocking

    exception_frontmatter =
      cwd
      |> Path.join(@debt_v36_exception_path)
      |> File.read!()
      |> repo_frontmatter!()

    assert exception_frontmatter =~ ~r/^status:\s*accepted_exception\b/m
    assert exception_frontmatter =~ ~r/^scope:\s*validation-ledger-finalization\b/m
    assert exception_frontmatter =~ ~r/^not_reconstructable:\s*true\b/m
    assert exception_frontmatter =~ ~r/^resolved_at:\s*2026-06-18\b/m

    for phase <- @debt_v36_affected_phases do
      assert exception_frontmatter =~ phase
      assert Path.wildcard(Path.join(cwd, ".planning/milestones/v3.6-phases/#{phase}-*")) == []
    end

    assert exception_frontmatter =~ ".planning/milestones/v3.6-CLOSEOUT.md"
    assert exception_frontmatter =~ ".planning/milestones/v3.6-ROADMAP.md"
    assert exception_frontmatter =~ ".planning/milestones/v3.6-REQUIREMENTS.md"
    assert exception_frontmatter =~ "test/crosswake/proof/phase52_operator_truth_test.exs"

    v36_check =
      CloseoutVerifier.run(
        cwd: cwd,
        closeout_path: write_repo_closeout_contract!("v3.6", @debt_v36_affected_phases)
      )
      |> find_check!("closeout.validation.ledger")

    refute v36_check.blocking

    prior_debt_check =
      CloseoutVerifier.run(cwd: cwd)
      |> find_check!("closeout.validation.prior_debt")

    refute prior_debt_check.observed =~ "(stale)"
  end

  test "resolved_gaps scope keyword does not re-open the validation-ledger escape hatch" do
    tmp = tmp_dir!("resolved-gaps-no-escape")
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    # Current-milestone closeout where validation-ledger-finalization appears
    # ONLY inside a resolved_gaps entry (no active deferral). A non-compliant
    # ledger must still block — the resolved gap must NOT keep the escape open.
    File.write!(
      Path.join(tmp, ".planning/milestones/v3.9-CLOSEOUT.md"),
      """
      ---
      milestone: v3.9
      milestone_name: Test Milestone
      status: complete
      shipped_date: 2026-01-01
      requirements_state: {status: complete}
      roadmap_parity: {status: complete}
      phase_verification_coverage:
        status: complete
        expected_phases: ["59"]
      summary_frontmatter_coverage: {status: complete}
      validation_ledger_status:
        status: complete
      thread_seed_disposition: {status: complete}
      release_changelog_continuity: {status: complete}
      public_support_claim_changes: {status: complete}
      deferred_with_reason: []
      exceptions: []
      resolved_gaps:
        - owner: maintainer
          scope: validation-ledger-finalization
          reason: "Closed in a prior pass."
          revisit_phase: 64
          evidence: "archived"
          status: resolved
      ---
      """
    )

    write_minimal_files!(tmp)

    # Non-compliant ledger for the only expected phase
    ledger_dir = Path.join(tmp, ".planning/milestones/v3.9-phases/59-x")
    File.mkdir_p!(ledger_dir)
    File.write!(Path.join(ledger_dir, "59-VALIDATION.md"), "nyquist_compliant: false\n")

    check = find_check!(CloseoutVerifier.run(cwd: tmp), "closeout.validation.ledger")

    assert check.blocking
    assert check.observed =~ "59"
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

  defp repo_frontmatter!(content) do
    case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
      [frontmatter] -> frontmatter
      nil -> flunk("expected frontmatter")
    end
  end

  defp write_repo_closeout_contract!(milestone_id, expected_phases) do
    tmp = tmp_dir!("repo-closeout-#{milestone_id}")
    expected_str = Enum.map_join(expected_phases, ", ", &~s("#{&1}"))
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    path = Path.join(tmp, ".planning/milestones/#{milestone_id}-CLOSEOUT.md")

    File.write!(
      path,
      """
      ---
      milestone: #{milestone_id}
      milestone_name: Historical source-contract fixture
      status: complete
      shipped_date: 2026-06-18
      requirements_state:
        status: complete
      roadmap_parity:
        status: complete
      phase_verification_coverage:
        status: complete
        expected_phases: [#{expected_str}]
      summary_frontmatter_coverage:
        status: complete
      validation_ledger_status:
        status: complete
      thread_seed_disposition:
        status: complete
      release_changelog_continuity:
        status: complete
      public_support_claim_changes:
        status: complete
      deferred_with_reason: []
      exceptions: []
      resolved_gaps: []
      ---
      """
    )

    path
  end

  defp write_complete_closeout!(tmp) do
    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    write_closeout!(tmp, expected_phases: ["64"])
    write_phase_artifacts!(tmp, "64")
  end

  defp write_closeout!(tmp, opts) do
    milestone_id = Keyword.get(opts, :milestone, "v3.9")
    expected_phases = Keyword.get(opts, :expected_phases, ["64"])
    expected_str = Enum.map_join(expected_phases, ", ", &~s("#{&1}"))

    top_level =
      if Keyword.get(opts, :top_level_expected_phases?, false) do
        "expected_phases: [#{expected_str}]\n"
      else
        ""
      end

    default_coverage =
      if Keyword.get(opts, :top_level_expected_phases?, false) do
        "phase_verification_coverage:\n  status: complete\n"
      else
        "phase_verification_coverage:\n  status: complete\n  expected_phases: [#{expected_str}]\n"
      end

    phase_verification_coverage =
      Keyword.get(opts, :phase_verification_coverage, default_coverage)

    File.mkdir_p!(Path.join(tmp, ".planning/milestones"))

    File.write!(
      Path.join(tmp, ".planning/milestones/#{milestone_id}-CLOSEOUT.md"),
      """
      ---
      milestone: #{milestone_id}
      milestone_name: Operator Truth and Production Diagnostics
      status: complete
      shipped_date: 2026-06-01
      requirements_state:
        status: complete
      roadmap_parity:
        status: complete
      #{top_level}#{phase_verification_coverage}summary_frontmatter_coverage:
        status: complete
      validation_ledger_status:
        status: complete
      thread_seed_disposition:
        status: complete
      release_changelog_continuity:
        status: complete
      public_support_claim_changes:
        status: complete
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
    # The verifier derives the active milestone from STATE.md frontmatter to
    # locate `<milestone>-CLOSEOUT.md`. These fixtures all write a v3.9 closeout,
    # so STATE.md must declare milestone: v3.9.
    File.write!(Path.join(tmp, ".planning/STATE.md"), "---\nmilestone: v3.9\n---\n")
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

  defp write_phase_artifacts!(tmp, phase, opts \\ []) do
    write_verification_and_summary!(tmp, phase)

    validation =
      case Keyword.fetch(opts, :validation) do
        {:ok, content} ->
          content

        :error ->
          write_evidence_file!(tmp)
          validation_ledger()
      end

    phase_dir = Path.join(tmp, ".planning/phases/#{phase}-fixture")
    File.write!(Path.join(phase_dir, "#{phase}-VALIDATION.md"), validation)
  end

  defp write_verification_and_summary!(tmp, phase) do
    phase_dir = Path.join(tmp, ".planning/phases/#{phase}-fixture")
    File.mkdir_p!(phase_dir)
    File.write!(Path.join(phase_dir, "#{phase}-VERIFICATION.md"), "status: passed\n")

    File.write!(
      Path.join(phase_dir, "#{phase}-01-SUMMARY.md"),
      """
      ---
      phase: #{phase}-fixture
      plan: "01"
      requirements-completed: [REL-01]
      ---
      """
    )
  end

  defp write_evidence_file!(tmp) do
    path = Path.join(tmp, @fixture_evidence_file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "defmodule FixtureValidationTest do\n  use ExUnit.Case\nend\n")
  end

  defp validation_ledger(evidence \\ nil) do
    evidence =
      evidence ||
        """
         - type: test_file
           ref: #{@fixture_evidence_file}
         - type: command
           ref: "mix test #{@fixture_evidence_file}"
        """

    """
    ---
    nyquist_compliant: true
    tested_by:
      - "mix test #{@fixture_evidence_file}"
    evidence:
    #{evidence}---
    """
  end

  defp invalid_test_file_ledger do
    validation_ledger("""
     - type: test_file
       ref: test/crosswake/planning/missing_validation_test.exs
    """)
  end

  defp write_validation_exception!(tmp, milestone_id, phases) do
    affected = Enum.map_join(phases, ", ", &~s("#{&1}"))
    write_evidence_file!(tmp)

    File.write!(
      Path.join(tmp, ".planning/milestones/#{milestone_id}-VALIDATION-EXCEPTION.md"),
      """
      ---
      status: accepted_exception
      scope: validation-ledger-finalization
      affected_phases: [#{affected}]
      not_reconstructable: true
      owner: maintainer
      resolved_at: 2026-06-18
      evidence:
        - type: planning_artifact
          ref: .planning/milestones/#{milestone_id}-CLOSEOUT.md
        - type: test_file
          ref: #{@fixture_evidence_file}
      reason: "Historical phase directories were not archived before phase numbers were reused."
      ---
      """
    )
  end
end
