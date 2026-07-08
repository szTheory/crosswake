defmodule Crosswake.Proof.Phase142ReleaseIntegrityTest do
  @moduledoc """
  Merge-blocking proof for v18 release-integrity guardrails.

  The release workflow is product surface for Crosswake's package family. These
  tests keep the v17 footguns from returning: aggregate release gates, cancelable
  publish runs, cross-platform proof cascades, and stale clean-room dependency
  floors.
  """

  use ExUnit.Case, async: true

  @workflow ".github/workflows/release-please.yml"
  @recovery_workflow ".github/workflows/hex-publish.yml"
  @scanner "script/check_release_workflow_integrity.exs"
  @cleanroom_script "script/verify_companion_cleanroom.sh"
  @guarded_helper "script/guarded_hex_publish.sh"
  @release_config "release-please-config.json"
  @doctor_task "lib/mix/tasks/crosswake.doctor.ex"

  @phase143_ids ~w(
    release.hex_publish.already_live_preflight
    release.hex_publish.no_replace
    release.hex_publish.shared_helper
    recovery.hex.component_input
    recovery.hex.exact_ref_only
    recovery.hex.package_map_complete
    recovery.hex.already_live_success_continues
    release.version_graph.lockstep_core_native_only
    release.version_graph.companions_independent
    release.version_graph.companion_floors_honest
  )

  @phase144_cleanroom_ids ~w(
    release.cleanroom.hex_metadata_floor
    release.cleanroom.exact_companion_pin
    release.cleanroom.lockfile_postcondition
    release.cleanroom.package_profiles_preserved
  )

  @phase144_doctor_ids ~w(
    release.doctor.app_config_requirement
    release.doctor.fresh_router_loaded
  )

  @phase144_release_integrity_ids ~w(
    release.workflow.aggregate_gate.behavioral_jobs_absent
    release.workflow.proof_after_publish
    release.workflow.native_proof_decoupled
    release.workflow.mirror_token_preflight
    release.workflow.concurrency_queue_max
    release.workflow.no_cancel_in_progress_true
    release.cleanroom.package_matrix_complete
    release.workflow.companion_floors_honest
    release.workflow.doctor_proof_unmasked
  )

  test "release workflow integrity script passes" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output
    assert output =~ "release.root_hex.path_gate"
    assert output =~ "release.concurrency.queue_max"
    assert output =~ "release.aggregate_gate.behavioral_jobs_absent"
    assert output =~ "release.cleanup.after_publish_and_proof"
  end

  @tag :phase143_auto_publish
  test "phase 143 guarded auto publish scanner ids pass" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output

    for check_id <- @phase143_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  test "root and native publish jobs do not gate on aggregate releases_created" do
    workflow = File.read!(@workflow)

    assert workflow =~ "paths_released:"
    assert workflow =~ "publish-hex:"
    assert workflow =~ "contains(fromJSON(needs.release-please.outputs.paths_released), '.')"

    assert workflow =~
             "contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios')"

    assert workflow =~
             "contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android')"

    refute workflow =~
             ~r/publish-hex:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/

    refute workflow =~
             ~r/publish-ios-core:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/

    refute workflow =~
             ~r/publish-android-core:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/
  end

  @tag :phase144_cleanroom
  test "phase 144 clean-room scanner ids pass" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output

    for check_id <- @phase144_cleanroom_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  @tag :phase144_doctor
  test "phase 144 doctor scanner ids pass" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output

    for check_id <- @phase144_doctor_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  @tag :phase144_release_integrity
  test "phase 144 consolidated release integrity scanner ids pass" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output

    for check_id <- @phase144_release_integrity_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  @tag :phase144_cleanroom
  test "clean-room script derives Hex metadata floor and exact companion version" do
    script = File.read!(@cleanroom_script)

    assert script =~ "requirements.crosswake.requirement"
    assert script =~ "fetch_hex_release_metadata"
    assert script =~ "parse_core_requirement_from_release"
    assert script =~ "PACKAGE_REQUIREMENT=\"== ${VERSION}\""
    assert script =~ "{:crosswake, \"${CORE_REQUIREMENT}\"}"
    assert script =~ "{:${PACKAGE}, \"${PACKAGE_REQUIREMENT}\"}"
    assert script =~ "assert_lockfile_postconditions"
    assert script =~ "Version.match?"

    refute script =~ "CROSSWAKE_CORE_REQUIREMENT"
    refute script =~ "grep -E 'do: \\{:crosswake"
  end

  @tag :phase144_cleanroom
  test "local source floor authority fails with stable check id" do
    cleanroom =
      cleanroom_script()
      |> String.replace("requirements.crosswake.requirement", "local packages/${PACKAGE}/mix.exs")
      |> Kernel.<>(
        "\nCORE_REQUIREMENT=$(grep -E 'do: {:crosswake, \"' \"$PACKAGE_DIR/mix.exs\")\n"
      )

    assert_failure_with_fixtures!(
      "release.cleanroom.hex_metadata_floor",
      cleanroom_script: cleanroom
    )
  end

  @tag :phase144_cleanroom
  test "weak companion pin fails with stable check id" do
    cleanroom =
      cleanroom_script()
      |> String.replace("PACKAGE_REQUIREMENT=\"== ${VERSION}\"", "PACKAGE_REQUIREMENT=\"~> 0.2\"")

    assert_failure_with_fixtures!(
      "release.cleanroom.exact_companion_pin",
      cleanroom_script: cleanroom
    )
  end

  @tag :phase144_cleanroom
  test "missing lockfile postcondition fails with stable check id" do
    cleanroom =
      cleanroom_script()
      |> String.replace("assert_lockfile_postconditions", "lockfile_postconditions_removed")

    assert_failure_with_fixtures!(
      "release.cleanroom.lockfile_postcondition",
      cleanroom_script: cleanroom
    )
  end

  @tag :phase144_cleanroom
  test "collapsed package profiles fail with stable check id" do
    cleanroom =
      cleanroom_script()
      |> String.replace("crosswake_threadline)", "crosswake_threadline_removed)")

    assert_failure_with_fixtures!(
      "release.cleanroom.package_profiles_preserved",
      cleanroom_script: cleanroom
    )
  end

  @tag :phase144_cleanroom
  test "D-03 fail-closed evidence fails with stable check id" do
    cases = [
      {"unknown package", "unknown Hex package", "unsupported Hex package"},
      {"invalid semver", "does not look like a valid semver string", "has a bad version"},
      {"HTTP 404", "Hex.pm returned 404", "Hex.pm was not ready"},
      {"version mismatch", "version mismatch", "version drift"},
      {"retired release", "retired or unusable", "retired release"},
      {"missing requirement", "missing requirements.crosswake.requirement",
       "missing crosswake requirement"},
      {"malformed JSON", "malformed JSON", "bad JSON"}
    ]

    for {_label, required, replacement} <- cases do
      cleanroom = String.replace(cleanroom_script(), required, replacement, global: false)

      assert_failure_with_fixtures!(
        "release.cleanroom.hex_metadata_floor",
        cleanroom_script: cleanroom
      )
    end
  end

  @tag :phase144_doctor
  test "missing doctor app config requirement fails with stable check id" do
    doctor =
      doctor_task()
      |> String.replace(~s(@requirements ["app.config"]), "")

    assert_failure_with_fixtures!(
      "release.doctor.app_config_requirement",
      doctor_task: doctor
    )
  end

  @tag :phase144_doctor
  test "doctor app start requirement fails with stable check id" do
    doctor =
      doctor_task()
      |> String.replace(
        ~s(@requirements ["app.config"]),
        ~s(@requirements ["app.config"]\n  @requirements ["app.start"])
      )

    assert_failure_with_fixtures!(
      "release.doctor.app_config_requirement",
      doctor_task: doctor
    )
  end

  @tag :phase144_doctor
  test "clean-room router preload before doctor fails with stable check id" do
    cleanroom =
      cleanroom_script()
      |> String.replace(
        ~r/^mix crosswake\.doctor --router CleanRoomHost\.Router$/m,
        """
        mix run -e 'Code.ensure_loaded?(CleanRoomHost.Router) || raise "masked router preload"'

        mix crosswake.doctor --router CleanRoomHost.Router
        """,
        global: false
      )

    assert_failure_with_fixtures!(
      "release.doctor.fresh_router_loaded",
      cleanroom_script: cleanroom
    )
  end

  test "missing queue max fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace(~r/^\s+queue:\s*max\n/m, "")

    assert_failure!("release.concurrency.queue_max", workflow)
  end

  test "conflicting true cancellation fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("cancel-in-progress: false", "cancel-in-progress: true")

    assert_failure!("release.concurrency.not_cancelled", workflow)
    assert_failure!("release.concurrency.no_true_cancellation", workflow)
  end

  test "aggregate identity in a behavioral job fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace(
        "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
        "if: ${{ needs.release-please.outputs.releases_created == 'true' }}",
        global: false
      )

    assert_failure!("release.aggregate_gate.behavioral_jobs_absent", workflow)
  end

  test "full-line comments cannot satisfy or violate semantic checks" do
    commented_queue =
      real_workflow()
      |> String.replace("  queue: max", "  # queue: max", global: false)

    assert_failure!("release.concurrency.queue_max", commented_queue)

    aggregate_comment =
      real_workflow()
      |> String.replace(
        "  publish-hex:\n    name:",
        "  publish-hex:\n    # if: ${{ needs.release-please.outputs.releases_created == 'true' }}\n    name:",
        global: false
      )

    {output, exit_code} = run_fixture(aggregate_comment)
    assert exit_code == 0, output
  end

  test "inline comments and step text cannot satisfy path gates" do
    inline_comment_decoy =
      real_workflow()
      |> replace_in_job(
        "publish-hex",
        "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
        "if: ${{ false }} # contains(fromJSON(needs.release-please.outputs.paths_released), '.')"
      )

    assert_failure!("release.root_hex.path_gate", inline_comment_decoy)

    run_text_decoy =
      real_workflow()
      |> replace_in_job(
        "publish-hex",
        "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
        "if: ${{ false }}\n    env:\n      DECOY: \"contains(fromJSON(needs.release-please.outputs.paths_released), '.')\""
      )

    assert_failure!("release.root_hex.path_gate", run_text_decoy)
  end

  test "cleanup ignoring clean-room proof fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("      - clean-room-proof-rulestead\n", "", global: false)
      |> String.replace(
        "            needs.clean-room-proof-rulestead.result == 'success'",
        "            true",
        global: false
      )

    assert_failure!("release.cleanup.after_publish_and_proof", workflow)
  end

  test "companion proof jobs must gate on the matching component after publish" do
    skipped_proof =
      real_workflow()
      |> replace_in_job(
        "clean-room-proof-rulestead",
        "if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}",
        "if: ${{ false }}"
      )

    assert_failure!("release.rulestead.proof_gate", skipped_proof)
    assert_failure!("release.cleanup.after_publish_and_proof", skipped_proof)

    proof_before_publish =
      real_workflow()
      |> replace_in_job(
        "clean-room-proof-rulestead",
        "needs: [release-please, publish-hex-rulestead]",
        "needs: [release-please]"
      )

    assert_failure!("release.rulestead.proof_gate", proof_before_publish)
    assert_failure!("release.cleanup.after_publish_and_proof", proof_before_publish)
  end

  test "cleanup direct main mutation fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("git push origin \"$branch\"", "git push origin main", global: false)

    assert_failure!("release.cleanup.pr_only", workflow)

    refs_push =
      real_workflow()
      |> String.replace(
        "git push origin \"$branch\"",
        "git push origin \"$branch\"\n          git push origin HEAD:refs/heads/main",
        global: false
      )

    assert_failure!("release.cleanup.pr_only", refs_push)
  end

  @tag :phase143_auto_publish
  test "direct automatic Hex publish fails the shared helper check" do
    workflow =
      real_workflow()
      |> replace_in_job(
        "publish-hex-sigra",
        "bash script/guarded_hex_publish.sh",
        "mix hex.publish --yes"
      )

    assert_failure!("release.hex_publish.shared_helper", workflow)
  end

  @tag :phase143_auto_publish
  test "missing already-live helper preflight fails with stable check id" do
    helper =
      guarded_helper()
      |> String.replace("already live on Hex.pm; no publish attempted", "live on Hex.pm")

    assert_failure_with_fixtures!(
      "release.hex_publish.already_live_preflight",
      helper: helper
    )
  end

  @tag :phase143_recovery
  test "root-only recovery input surface fails with stable check id" do
    recovery =
      recovery_workflow()
      |> String.replace(~r/\n      package:\n[\s\S]*?      ref:\n/, "\n      ref:\n")

    assert_failure_with_fixtures!(
      "recovery.hex.component_input",
      recovery_workflow: recovery
    )
  end

  @tag :phase143_recovery
  test "mutable recovery ref samples must stay rejected" do
    for sample <- [
          "release/v0.2.0",
          "feature/v0.2.0",
          "refs/heads/release/v0.2.0",
          "v0.2.0"
        ] do
      recovery = String.replace(recovery_workflow(), sample, "REMOVED_SAMPLE")

      assert_failure_with_fixtures!(
        "recovery.hex.exact_ref_only",
        recovery_workflow: recovery
      )
    end
  end

  @tag :phase143_recovery
  test "missing helper package map entry fails with stable check id" do
    helper =
      guarded_helper()
      |> String.replace("    crosswake_threadline)", "    crosswake_threadline_removed)")

    assert_failure_with_fixtures!(
      "recovery.hex.package_map_complete",
      helper: helper
    )
  end

  @tag :phase143_recovery
  test "already-live recovery must continue to proof" do
    helper =
      guarded_helper()
      |> String.replace("Continuing to proof.", "Stopping before proof.")

    assert_failure_with_fixtures!(
      "recovery.hex.already_live_success_continues",
      helper: helper
    )
  end

  @tag :phase143_recovery
  test "routine registry replacement syntax fails with stable check id" do
    helper = guarded_helper() <> "\nMIX_HEX_PUBLISH_FLAGS='--replace'\n"

    assert_failure_with_fixtures!(
      "release.hex_publish.no_replace",
      helper: helper
    )
  end

  @tag :phase143_version_graph
  test "companions cannot join the core native lockstep group" do
    config =
      release_config()
      |> String.replace(
        ~s("components": ["hex", "ios-core", "android-core"]),
        ~s("components": ["hex", "ios-core", "android-core", "crosswake_sigra"])
      )

    assert_failure_with_fixtures!(
      "release.version_graph.lockstep_core_native_only",
      release_config: config
    )

    assert_failure_with_fixtures!(
      "release.version_graph.companions_independent",
      release_config: config
    )
  end

  @tag :phase143_version_graph
  test "flattened companion floors fail with stable check id" do
    temp_root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase143-floors-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temp_root)
    on_exit(fn -> File.rm_rf(temp_root) end)

    for package <-
          ~w(crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline) do
      source = Path.join(["packages", package, "mix.exs"])
      target_dir = Path.join(temp_root, package)
      File.mkdir_p!(target_dir)

      contents =
        source
        |> File.read!()
        |> String.replace(~s({:crosswake, "~> 0.1"}), ~s({:crosswake, "~> 0.2"}))

      File.write!(Path.join(target_dir, "mix.exs"), contents)
    end

    {output, exit_code} =
      run_scanner(@workflow, [{"COMPANION_MIX_ROOT", temp_root}])

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: release.version_graph.companion_floors_honest"
  end

  defp assert_failure!(check_id, workflow) do
    {output, exit_code} = run_fixture(workflow)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: #{check_id}"
  end

  defp assert_failure_with_fixtures!(check_id, fixtures) do
    {output, exit_code} = run_fixture_set(fixtures)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: #{check_id}"
  end

  defp run_fixture(workflow) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase142-#{System.unique_integer([:positive])}.yml"
      )

    File.write!(path, workflow)
    on_exit(fn -> File.rm(path) end)

    run_scanner(path)
  end

  defp run_fixture_set(fixtures) do
    env =
      fixtures
      |> Enum.map(fn {name, contents} ->
        path =
          Path.join(
            System.tmp_dir!(),
            "crosswake-phase143-#{name}-#{System.unique_integer([:positive])}"
          )

        File.write!(path, contents)
        on_exit(fn -> File.rm(path) end)

        {fixture_env_name(name), path}
      end)

    run_scanner(@workflow, env)
  end

  defp fixture_env_name(:recovery_workflow), do: "HEX_PUBLISH_WORKFLOW_PATH"
  defp fixture_env_name(:helper), do: "GUARDED_HEX_PUBLISH_PATH"
  defp fixture_env_name(:release_config), do: "RELEASE_PLEASE_CONFIG_PATH"
  defp fixture_env_name(:cleanroom_script), do: "CLEANROOM_SCRIPT_PATH"
  defp fixture_env_name(:doctor_task), do: "DOCTOR_TASK_PATH"

  defp run_scanner(path, env \\ []) do
    System.cmd("elixir", [@scanner, path], stderr_to_stdout: true, env: env)
  end

  defp replace_in_job(workflow, job, pattern, replacement) do
    Regex.replace(
      ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
      workflow,
      fn block -> String.replace(block, pattern, replacement, global: false) end,
      global: false
    )
  end

  defp real_workflow, do: File.read!(@workflow)
  defp recovery_workflow, do: File.read!(@recovery_workflow)
  defp guarded_helper, do: File.read!(@guarded_helper)
  defp release_config, do: File.read!(@release_config)
  defp cleanroom_script, do: File.read!(@cleanroom_script)
  defp doctor_task, do: File.read!(@doctor_task)
end
