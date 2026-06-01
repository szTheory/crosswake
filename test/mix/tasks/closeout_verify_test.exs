defmodule Mix.Tasks.Closeout.VerifyTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "closeout.verify"

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
    File.write!(Path.join(cwd, ".planning/milestones/v3.6-CLOSEOUT.md"), "# no frontmatter\n")

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
    assert_raise Mix.Error, ~r/invalid options/, fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, ["--format", "json"])
    end
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
    File.write!(Path.join(cwd, ".planning/REQUIREMENTS.md"), "| REL-01 | Phase 53 | Validated |")
    File.write!(Path.join(cwd, ".planning/ROADMAP.md"), "$gsd-discuss-phase 48")
    File.write!(Path.join(cwd, ".planning/STATE.md"), "Status: Ready to discuss\n")

    File.write!(
      Path.join(cwd, ".planning/milestones/v3.6-CLOSEOUT.md"),
      complete_closeout()
    )

    for phase <- 48..53 do
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
    milestone: v3.6
    milestone_name: Operator Truth and Production Diagnostics
    status: complete
    shipped_date: 2026-06-01
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
end
