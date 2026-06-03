defmodule Mix.Tasks.Closeout.VerifyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "closeout.verify"

  setup do
    on_exit(fn -> Mix.Task.reenable(@task) end)
  end

  test "mix closeout.verify prints the shared verifier report and exits cleanly when closeout passes" do
    cwd = complete_fixture!("pass")

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--cwd", cwd])
      end)

    assert output =~ "closeout.verify passed"
    assert output =~ "closeout.release.changelog_continuity"
  end

  test "mix closeout.verify raises on blocking closeout drift" do
    cwd = complete_fixture!("fail")
    File.write!(Path.join(cwd, ".planning/milestones/v3.9-CLOSEOUT.md"), "# no frontmatter\n")

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/closeout verification found blocking issues/, fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--cwd", cwd])
        end
      end)

    assert output =~ "closeout.verify failed"
    assert output =~ "closeout.ledger.frontmatter"
    assert output =~ "posture=merge-blocking"
  end

  test "mix closeout.verify rejects unsupported options" do
    try do
      assert_raise Mix.Error, ~r/invalid options/, fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--format", "json"])
      end
    after
      Mix.Task.reenable(@task)
    end
  end

  test "mix closeout.verify accepts an explicit Phase 58 security closeout artifact" do
    cwd = complete_fixture!("security")
    security_path = Path.join(cwd, ".planning/phases/58-fixture/58-SECURITY.md")
    File.mkdir_p!(Path.dirname(security_path))
    File.write!(security_path, security_closeout())

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--cwd", cwd, "--security-closeout", security_path])
      end)

    assert output =~ "closeout.verify passed"
    assert output =~ "closeout.security.phase58"
  end

  test "mix closeout.verify can run Phase 58 security closeout without v3.6 ledger checks" do
    cwd = complete_fixture!("security-only")
    File.write!(Path.join(cwd, ".planning/REQUIREMENTS.md"), "v3.8 active requirements\n")
    File.write!(Path.join(cwd, ".planning/ROADMAP.md"), "$gsd-discuss-phase 58\n")

    security_path = Path.join(cwd, ".planning/phases/58-fixture/58-SECURITY.md")
    File.mkdir_p!(Path.dirname(security_path))
    File.write!(security_path, security_closeout())

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)

        Mix.Task.run(@task, [
          "--cwd",
          cwd,
          "--security-only",
          "--security-closeout",
          security_path
        ])
      end)

    assert output =~ "closeout.verify passed"
    assert output =~ "closeout.security.phase58"
    refute output =~ "closeout.requirements.state"
  end

  test "mix closeout.verify rejects Phase 58 security closeout missing ledger table structure" do
    cwd = complete_fixture!("security-missing-table")
    security_path = Path.join(cwd, ".planning/phases/58-fixture/58-SECURITY.md")
    File.mkdir_p!(Path.dirname(security_path))

    File.write!(
      security_path,
      String.replace(security_closeout(), "| Surface | STRIDE |", "| Surface |")
    )

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/closeout verification found blocking issues/, fn ->
          Mix.Task.reenable(@task)

          Mix.Task.run(@task, [
            "--cwd",
            cwd,
            "--security-only",
            "--security-closeout",
            security_path
          ])
        end
      end)

    assert output =~ "closeout.verify failed"
    assert output =~ "closeout.security.phase58"
    assert output =~ "missing table sections:"
  end

  test "mix closeout.verify rejects unresolved high or critical Phase 58 findings" do
    cwd = complete_fixture!("security-unresolved-high")
    security_path = Path.join(cwd, ".planning/phases/58-fixture/58-SECURITY.md")
    File.mkdir_p!(Path.dirname(security_path))

    File.write!(
      security_path,
      String.replace(security_closeout(), "| Closed |", "| Open |", global: false)
    )

    output =
      capture_io(fn ->
        assert_raise Mix.Error, ~r/closeout verification found blocking issues/, fn ->
          Mix.Task.reenable(@task)

          Mix.Task.run(@task, [
            "--cwd",
            cwd,
            "--security-only",
            "--security-closeout",
            security_path
          ])
        end
      end)

    assert output =~ "closeout.verify failed"
    assert output =~ "unresolved high/critical findings: 1"
  end

  defp complete_fixture!(name) do
    cwd =
      Path.join(
        System.tmp_dir!(),
        "crosswake-closeout-task-#{name}-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(cwd)

    File.mkdir_p!(Path.join(cwd, ".planning/milestones"))
    File.mkdir_p!(Path.join(cwd, ".planning/threads"))
    File.mkdir_p!(Path.join(cwd, ".planning/seeds"))

    File.write!(Path.join(cwd, "CHANGELOG.md"), changelog())
    File.write!(Path.join(cwd, ".planning/REQUIREMENTS.md"), "| REL-01 | Phase 63 | Validated |")
    File.write!(Path.join(cwd, ".planning/ROADMAP.md"), "$gsd-discuss-phase 59")
    File.write!(Path.join(cwd, ".planning/STATE.md"), "Status: Ready to discuss\n")

    File.write!(
      Path.join(cwd, ".planning/milestones/v3.9-CLOSEOUT.md"),
      complete_closeout()
    )

    for phase <- 59..63 do
      phase_dir = Path.join(cwd, ".planning/phases/#{phase}-fixture")
      File.mkdir_p!(phase_dir)
      File.write!(Path.join(phase_dir, "#{phase}-VERIFICATION.md"), "status: passed\n")
      File.write!(Path.join(phase_dir, "#{phase}-VALIDATION.md"), "nyquist_compliant: true\n")

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

    cwd
  end

  defp complete_closeout do
    """
    ---
    milestone: v3.9
    milestone_name: Chimeway Notification Seam
    status: complete
    shipped_date: 2026-06-03
    requirements_state:
      status: complete
    roadmap_parity:
      status: complete
    phase_verification_coverage:
      status: complete
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
  end

  defp changelog do
    """
    # Changelog

    ## Planning milestones vs Hex releases

    planning milestones are distinct from the latest published Hex release.

    ## [Unreleased]

    ### Unpublished support claims

    ### Verification-required and advisory surfaces

    ### Deferred non-shipped claims

    Provider and shell claims are not shipped.

    ### Published Hex truth

    Latest published Hex release remains 0.1.0.

    ## [0.1.0]
    """
  end

  defp security_closeout do
    sections = [
      "## Token And Locator Handling",
      "## Handoff Tickets",
      "## Step-Up Ceremony",
      "## Auth Return Boundaries",
      "## Telemetry And Diagnostics",
      "## Denial Sanitization",
      "## Session Renewal And LiveView Invalidation",
      "## Doctor Support Operator And Docs Truth",
      "## Proof And Non-Claims",
      "## Findings Disposition"
    ]

    section_tables =
      Enum.map_join(sections, "\n", fn section ->
        """
        #{section}

        | Surface | STRIDE | Adversarial scenario | Control | Evidence | Residual risk | Disposition |
        |---------|--------|----------------------|---------|----------|---------------|-------------|
        | High - Sigra auth surface | Spoofing/Tampering | Client evidence attempts to set `SessionAuthorityLane`. | Telemetry is diagnostic evidence only; provider/device proof remains advisory; direct shell/WebView token authority is non-shipped. | test fixture | None | Closed |
        """
      end)

    """
    # Phase 58 Security Closeout

    #{section_tables}
    """
  end
end
