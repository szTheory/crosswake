defmodule Crosswake.Proof.Phase135CiOpsProofTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 135 PROOF-03 (CI-Ops Hardening — Release-As Automation).

  Audit-then-prove: all five PROOF-03 production artifacts (SC1–SC5) landed on local main
  2026-06-26. This file proves them GREEN with no production-code change expected (D-01).

  async: true — each test owns a unique GIT_DIR / temp file via System.unique_integer([:positive]);
  no Application.put_env / shared global state (unlike phase133).

  Carries NO @moduletag — runs in the hermetic untagged lane (D-18 precedent from phase133).
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  # ---------------------------------------------------------------------------
  # SC1: staleness guard RED→GREEN via GIT_DIR-env injection
  # Marquee proof: demonstrates the guard (not merely asserts it).
  # ---------------------------------------------------------------------------

  test "SC1: staleness guard turns RED on a stale pin and GREEN after removal" do
    # Create a hermetic temp git repo — isolated from the real repo entirely.
    tmp_root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase135-sc1-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(tmp_root) end)

    File.mkdir_p!(tmp_root)
    git_dir = Path.join(tmp_root, ".git")

    # git init + empty commit + the synthetic tag that makes SC1 fire
    {_, 0} = System.cmd("git", ["init", tmp_root], stderr_to_stdout: true)
    {_, 0} = System.cmd("git", ["-C", tmp_root, "config", "user.email", "test@example.com"])
    {_, 0} = System.cmd("git", ["-C", tmp_root, "config", "user.name", "Test"])

    {_, 0} =
      System.cmd(
        "git",
        ["-C", tmp_root, "commit", "--allow-empty", "-m", "init"],
        stderr_to_stdout: true
      )

    # Tag that represents "crosswake_rulestead 0.1.0 already released"
    {_, 0} =
      System.cmd("git", ["-C", tmp_root, "tag", "crosswake_rulestead-v0.1.0"],
        stderr_to_stdout: true
      )

    # RED fixture: crosswake_rulestead has release-as: "0.1.0" AND a key AFTER it
    # (avoids trailing-comma JSONDecodeError — research Pitfall 1)
    red_config_path = Path.join(tmp_root, "red-config.json")

    red_config = """
    {
      "packages": {
        "packages/crosswake_rulestead": {
          "component": "crosswake_rulestead",
          "release-type": "elixir",
          "release-as": "0.1.0",
          "extra-files": []
        }
      }
    }
    """

    File.write!(red_config_path, red_config)

    # Inject GIT_DIR so the script's bare `git rev-parse` checks the temp repo's tags.
    # Merge with System.get_env() so PATH and other env vars (including bash itself) are intact.
    env = System.get_env() |> Map.put("GIT_DIR", git_dir) |> Map.to_list()

    {red_output, red_exit} =
      System.cmd("bash", ["script/check_release_as_staleness.sh", red_config_path],
        env: env,
        stderr_to_stdout: true
      )

    assert red_exit == 1,
           ProofAssertions.stable_id_message(
             "proof.sc1.staleness_guard.red_exit",
             "check_release_as_staleness.sh must exit 1 when release-as pin equals an existing tag",
             "script/check_release_as_staleness.sh",
             "exit code was #{red_exit}, output: #{red_output}",
             "script/check_release_as_staleness.sh",
             "verify GIT_DIR injection passes the temp repo's .git dir to the bare git rev-parse call",
             :merge_blocking
           )

    assert String.contains?(red_output, "STALE"),
           ProofAssertions.stable_id_message(
             "proof.sc1.staleness_guard.red_output",
             "check_release_as_staleness.sh must print STALE when pin equals existing tag",
             "script/check_release_as_staleness.sh",
             "output was: #{red_output}",
             "script/check_release_as_staleness.sh",
             "check the 'STALE: ...' output line in the while-loop body",
             :merge_blocking
           )

    # GREEN fixture: identical but with release-as removed
    green_config_path = Path.join(tmp_root, "green-config.json")

    green_config = """
    {
      "packages": {
        "packages/crosswake_rulestead": {
          "component": "crosswake_rulestead",
          "release-type": "elixir",
          "extra-files": []
        }
      }
    }
    """

    File.write!(green_config_path, green_config)

    {green_output, green_exit} =
      System.cmd("bash", ["script/check_release_as_staleness.sh", green_config_path],
        env: env,
        stderr_to_stdout: true
      )

    assert green_exit == 0,
           ProofAssertions.stable_id_message(
             "proof.sc1.staleness_guard.green_exit",
             "check_release_as_staleness.sh must exit 0 when no release-as pin is set",
             "script/check_release_as_staleness.sh",
             "exit code was #{green_exit}, output: #{green_output}",
             "script/check_release_as_staleness.sh",
             "a config with no release-as key should emit OK and exit 0",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC2: strip_release_as.py strips both keys then is a no-op (idempotent)
  # ---------------------------------------------------------------------------

  test "SC2: strip_release_as.py strips both keys then is a no-op (idempotent, minimal-diff)" do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase135-sc2-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    File.mkdir_p!(tmp_dir)
    config_path = Path.join(tmp_dir, "release-please-config.json")

    # Fixture: release-as is NOT the last key in the block (followed by extra-files).
    # This avoids the trailing-comma JSONDecodeError — the real rulestead config has release-as
    # as key 4/6, so this is a faithful (not contrived) fixture (research Pitfall 1).
    fixture = """
    {
      "packages": {
        "packages/crosswake_rulestead": {
          "component": "crosswake_rulestead",
          "release-type": "elixir",
          "release-as": "0.1.0",
          "_TODO_release_as": "Remove after first release",
          "extra-files": []
        }
      }
    }
    """

    File.write!(config_path, fixture)

    # Run 1 — should strip both keys
    {run1_output, run1_exit} =
      System.cmd("python3", ["script/strip_release_as.py", "crosswake_rulestead", config_path],
        stderr_to_stdout: true
      )

    assert run1_exit == 0,
           ProofAssertions.stable_id_message(
             "proof.sc2.strip.run1_exit",
             "strip_release_as.py run 1 must exit 0",
             "script/strip_release_as.py",
             "exit code was #{run1_exit}, output: #{run1_output}",
             "script/strip_release_as.py",
             "check that the component 'crosswake_rulestead' is found in the fixture",
             :merge_blocking
           )

    assert String.contains?(run1_output, "stripped"),
           ProofAssertions.stable_id_message(
             "proof.sc2.strip.run1_output_stripped",
             "strip_release_as.py run 1 must print 'stripped'",
             "script/strip_release_as.py",
             "output was: #{run1_output}",
             "script/strip_release_as.py",
             "check the print statement after successful key removal",
             :merge_blocking
           )

    # Parse the result and assert both keys are gone, other keys survive
    result_data = Jason.decode!(File.read!(config_path))
    block = get_in(result_data, ["packages", "packages/crosswake_rulestead"])

    refute Map.has_key?(block, "release-as"),
           ProofAssertions.stable_id_message(
             "proof.sc2.strip.release_as_removed",
             "run 1: 'release-as' key must be removed from the component block",
             "script/strip_release_as.py",
             "block after run 1: #{inspect(block)}",
             "script/strip_release_as.py",
             "check the line-surgery loop that removes lines starting with '\"release-as\"'",
             :merge_blocking
           )

    refute Map.has_key?(block, "_TODO_release_as"),
           ProofAssertions.stable_id_message(
             "proof.sc2.strip._todo_removed",
             "run 1: '_TODO_release_as' key must be removed from the component block",
             "script/strip_release_as.py",
             "block after run 1: #{inspect(block)}",
             "script/strip_release_as.py",
             "check the line-surgery loop that removes lines starting with '\"_TODO_release_as\"'",
             :merge_blocking
           )

    # Minimal-diff: other keys survive
    assert Map.has_key?(block, "component"),
           "run 1: 'component' key must survive after strip (minimal-diff)"

    assert Map.has_key?(block, "extra-files"),
           "run 1: 'extra-files' key must survive after strip (minimal-diff)"

    # Run 2 — idempotent no-op
    {run2_output, run2_exit} =
      System.cmd("python3", ["script/strip_release_as.py", "crosswake_rulestead", config_path],
        stderr_to_stdout: true
      )

    assert run2_exit == 0,
           ProofAssertions.stable_id_message(
             "proof.sc2.strip.run2_exit",
             "strip_release_as.py run 2 must exit 0 (idempotent)",
             "script/strip_release_as.py",
             "exit code was #{run2_exit}, output: #{run2_output}",
             "script/strip_release_as.py",
             "check the early-return path when both keys are already absent",
             :merge_blocking
           )

    assert String.contains?(run2_output, "no change"),
           ProofAssertions.stable_id_message(
             "proof.sc2.strip.run2_output_no_change",
             "strip_release_as.py run 2 must print 'no change' (idempotent)",
             "script/strip_release_as.py",
             "output was: #{run2_output}",
             "script/strip_release_as.py",
             "check the 'no change' print in the early-return path",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC2 wiring: release-as-cleanup job is structurally wired in release-please.yml
  # ---------------------------------------------------------------------------

  test "SC2: release-as-cleanup job is wired in release-please.yml" do
    source = File.read!(".github/workflows/release-please.yml")

    assert String.contains?(source, "release-as-cleanup"),
           ProofAssertions.stable_id_message(
             "proof.sc2.wiring.job_name",
             "release-please.yml must contain 'release-as-cleanup' job",
             ".github/workflows/release-please.yml",
             "job name not found in workflow",
             ".github/workflows/release-please.yml",
             "add the release-as-cleanup: job per PROOF-03b recipe Step 12f",
             :merge_blocking
           )

    assert String.contains?(source, "script/strip_release_as.py crosswake_rulestead"),
           ProofAssertions.stable_id_message(
             "proof.sc2.wiring.rulestead_invocation",
             "release-please.yml must invoke 'script/strip_release_as.py crosswake_rulestead'",
             ".github/workflows/release-please.yml",
             "invocation not found in workflow",
             ".github/workflows/release-please.yml",
             "add the strip_release_as.py crosswake_rulestead call to the release-as-cleanup job",
             :merge_blocking
           )

    assert String.contains?(source, "script/strip_release_as.py crosswake_rindle"),
           ProofAssertions.stable_id_message(
             "proof.sc2.wiring.rindle_invocation",
             "release-please.yml must invoke 'script/strip_release_as.py crosswake_rindle'",
             ".github/workflows/release-please.yml",
             "invocation not found in workflow",
             ".github/workflows/release-please.yml",
             "add the strip_release_as.py crosswake_rindle call to the release-as-cleanup job",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC3: release-failure-alert is wired with if: failure() over the four companion jobs
  # (PROOF-03c: alert fires on actual failure, NOT on always() which would page on every skip)
  # ---------------------------------------------------------------------------

  test "SC3: release-failure-alert is wired with if: failure() over the four companion jobs" do
    source = File.read!(".github/workflows/release-please.yml")

    assert String.contains?(source, "release-failure-alert:"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.job_name",
             "release-please.yml must contain 'release-failure-alert:' job",
             ".github/workflows/release-please.yml",
             "job name not found in workflow",
             ".github/workflows/release-please.yml",
             "add the release-failure-alert: job per PROOF-03c",
             :merge_blocking
           )

    assert String.contains?(source, "if: ${{ failure() }}"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.if_failure",
             "release-failure-alert job must use 'if: \\${{ failure() }}'",
             ".github/workflows/release-please.yml",
             "if: failure() condition not found in workflow",
             ".github/workflows/release-please.yml",
             "set `if: \\${{ failure() }}` on the release-failure-alert job — NOT always()",
             :merge_blocking
           )

    assert String.contains?(source, "publish-hex-rulestead"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.needs_rulestead",
             "release-failure-alert must need 'publish-hex-rulestead'",
             ".github/workflows/release-please.yml",
             "'publish-hex-rulestead' not found in workflow needs",
             ".github/workflows/release-please.yml",
             "add publish-hex-rulestead to the release-failure-alert needs list",
             :merge_blocking
           )

    assert String.contains?(source, "publish-hex-rindle"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.needs_rindle",
             "release-failure-alert must need 'publish-hex-rindle'",
             ".github/workflows/release-please.yml",
             "'publish-hex-rindle' not found in workflow needs",
             ".github/workflows/release-please.yml",
             "add publish-hex-rindle to the release-failure-alert needs list",
             :merge_blocking
           )

    assert String.contains?(source, "clean-room-proof-rulestead"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.needs_clean_room_rulestead",
             "release-failure-alert must need 'clean-room-proof-rulestead'",
             ".github/workflows/release-please.yml",
             "'clean-room-proof-rulestead' not found in workflow needs",
             ".github/workflows/release-please.yml",
             "add clean-room-proof-rulestead to the release-failure-alert needs list",
             :merge_blocking
           )

    assert String.contains?(source, "clean-room-proof-rindle"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.needs_clean_room_rindle",
             "release-failure-alert must need 'clean-room-proof-rindle'",
             ".github/workflows/release-please.yml",
             "'clean-room-proof-rindle' not found in workflow needs",
             ".github/workflows/release-please.yml",
             "add clean-room-proof-rindle to the release-failure-alert needs list",
             :merge_blocking
           )

    # Negative gate (PROOF-03c anti-pattern): the alert must NOT use always()
    # always() would fire on skipped jobs every non-release run — pages on every push, not just failures.
    # Note: this refute checks the whole file; no other assertion in this file asserts the literal
    # "if: always()" as a positive, so this negative gate cannot shadow an acceptance literal.
    refute String.contains?(source, "if: always()"),
           ProofAssertions.stable_id_message(
             "proof.sc3.alert.not_always",
             "release-failure-alert must NOT use 'if: always()' (PROOF-03c anti-pattern)",
             ".github/workflows/release-please.yml",
             "found 'if: always()' in workflow — this would page on every non-release run",
             ".github/workflows/release-please.yml",
             "change 'if: always()' to 'if: \\${{ failure() }}' on the alert job",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC4: extract_companion.md Step 12f references the CI automation
  # ---------------------------------------------------------------------------

  test "SC4: extract_companion.md Step 12f references the CI automation (PROOF-03)" do
    source = File.read!("script/extract_companion.md")

    assert String.contains?(source, "12f"),
           ProofAssertions.stable_id_message(
             "proof.sc4.recipe.step_12f",
             "extract_companion.md must contain Step '12f'",
             "script/extract_companion.md",
             "Step 12f not found",
             "script/extract_companion.md",
             "add Step 12f describing the CI-automated release-as removal (PROOF-03)",
             :merge_blocking
           )

    assert String.contains?(source, "PROOF-03"),
           ProofAssertions.stable_id_message(
             "proof.sc4.recipe.proof03_ref",
             "extract_companion.md must reference 'PROOF-03'",
             "script/extract_companion.md",
             "PROOF-03 reference not found",
             "script/extract_companion.md",
             "add PROOF-03 reference in Step 12f so future companions inherit 0-human release ops",
             :merge_blocking
           )

    assert String.contains?(source, "CI-automated"),
           ProofAssertions.stable_id_message(
             "proof.sc4.recipe.ci_automated",
             "extract_companion.md must contain 'CI-automated'",
             "script/extract_companion.md",
             "'CI-automated' not found",
             "script/extract_companion.md",
             "Step 12f must state that release-as removal is CI-automated (PROOF-03)",
             :merge_blocking
           )

    assert String.contains?(source, "release-as-cleanup"),
           ProofAssertions.stable_id_message(
             "proof.sc4.recipe.cleanup_job",
             "extract_companion.md must reference 'release-as-cleanup'",
             "script/extract_companion.md",
             "'release-as-cleanup' not found",
             "script/extract_companion.md",
             "Step 12f must name the release-as-cleanup job from release-please.yml",
             :merge_blocking
           )

    assert String.contains?(source, "merge-blocking-release-as-staleness"),
           ProofAssertions.stable_id_message(
             "proof.sc4.recipe.staleness_check",
             "extract_companion.md must reference 'merge-blocking-release-as-staleness'",
             "script/extract_companion.md",
             "'merge-blocking-release-as-staleness' not found",
             "script/extract_companion.md",
             "Step 12f must name the merge-blocking-release-as-staleness guard lane",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # SC5: registration tooling is dry-run-default / parametric / idempotent
  #      and the detector is fail-closed; discovery is live (not hardcoded)
  # ---------------------------------------------------------------------------

  test "SC5: registration tooling is dry-run-default, parametric, idempotent and detector is fail-closed" do
    register_source = File.read!("script/register_required_checks.sh")

    assert String.contains?(register_source, ~s(DRY_RUN="${DRY_RUN:-1}")),
           ProofAssertions.stable_id_message(
             "proof.sc5.register.dry_run_default",
             "register_required_checks.sh must default DRY_RUN to 1",
             "script/register_required_checks.sh",
             "DRY_RUN default not found",
             "script/register_required_checks.sh",
             "add DRY_RUN=\"${DRY_RUN:-1}\" so the script is safe-by-default (never mutates in CI)",
             :merge_blocking
           )

    assert String.contains?(register_source, "list_merge_blocking_checks.py"),
           ProofAssertions.stable_id_message(
             "proof.sc5.register.parametric",
             "register_required_checks.sh must invoke 'list_merge_blocking_checks.py' (parametric)",
             "script/register_required_checks.sh",
             "list_merge_blocking_checks.py not found",
             "script/register_required_checks.sh",
             "the registrar must discover lanes from list_merge_blocking_checks.py (not hardcode them)",
             :merge_blocking
           )

    assert String.contains?(register_source, "unique_by(.context)"),
           ProofAssertions.stable_id_message(
             "proof.sc5.register.idempotent",
             "register_required_checks.sh must use 'unique_by(.context)' (idempotent)",
             "script/register_required_checks.sh",
             "unique_by(.context) not found",
             "script/register_required_checks.sh",
             "the jq pipeline must deduplicate by context so re-runs are idempotent",
             :merge_blocking
           )

    detector_source = File.read!("script/check_required_checks_registered.sh")

    assert String.contains?(detector_source, "list_merge_blocking_checks.py"),
           ProofAssertions.stable_id_message(
             "proof.sc5.detector.parametric",
             "check_required_checks_registered.sh must invoke 'list_merge_blocking_checks.py'",
             "script/check_required_checks_registered.sh",
             "list_merge_blocking_checks.py not found",
             "script/check_required_checks_registered.sh",
             "the detector must use the same discovery script as the registrar",
             :merge_blocking
           )

    assert String.contains?(detector_source, "exit 1"),
           ProofAssertions.stable_id_message(
             "proof.sc5.detector.fail_closed_gap",
             "check_required_checks_registered.sh must exit 1 on GAP (fail-closed)",
             "script/check_required_checks_registered.sh",
             "exit 1 not found",
             "script/check_required_checks_registered.sh",
             "add 'exit 1' for the GAP path — a lane not registered is advisory in practice",
             :merge_blocking
           )

    assert String.contains?(detector_source, "exit 3"),
           ProofAssertions.stable_id_message(
             "proof.sc5.detector.fail_closed_unverified",
             "check_required_checks_registered.sh must exit 3 on UNVERIFIED (fail-closed)",
             "script/check_required_checks_registered.sh",
             "exit 3 not found",
             "script/check_required_checks_registered.sh",
             "add 'exit 3' for the UNVERIFIED path — NOT a pass (requires admin gh auth)",
             :merge_blocking
           )

    # Live discovery: run the parametric discovery script and assert:
    # 1) exits 0 (no PyYAML missing, no YAML parse errors)
    # 2) merge-blocking-release-as-staleness appears in the output
    # DO NOT hardcode all 20 lane names — this would require a test edit on every future lane.
    {discovery_output, discovery_exit} =
      System.cmd("python3", ["script/list_merge_blocking_checks.py"],
        stderr_to_stdout: true
      )

    assert discovery_exit == 0,
           ProofAssertions.stable_id_message(
             "proof.sc5.discovery.exit_0",
             "list_merge_blocking_checks.py must exit 0",
             "script/list_merge_blocking_checks.py",
             "exit code was #{discovery_exit}, output: #{discovery_output}",
             "script/list_merge_blocking_checks.py",
             "if non-zero: check that PyYAML is installed (pip install pyyaml) or YAML parse error",
             :merge_blocking
           )

    assert String.contains?(discovery_output, "merge-blocking-release-as-staleness"),
           ProofAssertions.stable_id_message(
             "proof.sc5.discovery.staleness_lane",
             "list_merge_blocking_checks.py must emit 'merge-blocking-release-as-staleness'",
             "script/list_merge_blocking_checks.py",
             "output was: #{discovery_output}",
             "script/list_merge_blocking_checks.py",
             "check that the release-as-staleness-gate.yml job name contains 'merge-blocking-release-as-staleness'",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Deferred core-hermetic failures are now green (Open Question Q1 — resolved)
  #
  # DECISION: nested `mix test` (assert exit code), NOT a structural file read.
  # Rationale: git-log shows both files were already green before the 2026-06-26 Phase 135
  # window — their last edits are in phases 111/124/124-02, unrelated to v16.0. The "fix" was
  # upstream STATE/REQUIREMENTS state that unblocked the test runner from seeing them. A
  # structural read cannot prove "green"; the faithful proof is to actually run them and assert exit 0.
  # ---------------------------------------------------------------------------

  test "deferred core-hermetic failures are now green: milestone_transition_reset" do
    {output, exit_code} =
      System.cmd(
        "mix",
        ["test", "test/crosswake/planning/milestone_transition_reset_test.exs", "--seed", "0"],
        stderr_to_stdout: true
      )

    assert exit_code == 0,
           ProofAssertions.stable_id_message(
             "proof.deferred.milestone_transition_reset.green",
             "milestone_transition_reset_test.exs must be green (exit 0)",
             "test/crosswake/planning/milestone_transition_reset_test.exs",
             "exit code was #{exit_code}, output:\n#{output}",
             "test/crosswake/planning/milestone_transition_reset_test.exs",
             "see the nested mix test output above for the failing assertion",
             :merge_blocking
           )
  end

  test "deferred core-hermetic failures are now green: phase52_operator_truth" do
    {output, exit_code} =
      System.cmd(
        "mix",
        ["test", "test/crosswake/proof/phase52_operator_truth_test.exs", "--seed", "0"],
        stderr_to_stdout: true
      )

    assert exit_code == 0,
           ProofAssertions.stable_id_message(
             "proof.deferred.phase52_operator_truth.green",
             "phase52_operator_truth_test.exs must be green (exit 0)",
             "test/crosswake/proof/phase52_operator_truth_test.exs",
             "exit code was #{exit_code}, output:\n#{output}",
             "test/crosswake/proof/phase52_operator_truth_test.exs",
             "see the nested mix test output above for the failing assertion",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-18).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 135 CI-ops proof file must not carry @moduletag: tags — it runs untagged (D-18)"
  end
end
