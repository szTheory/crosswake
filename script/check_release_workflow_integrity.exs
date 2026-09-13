#!/usr/bin/env elixir

defmodule Crosswake.ReleaseWorkflowIntegrity do
  @default_workflow ".github/workflows/release-please.yml"
  @default_recovery_workflow ".github/workflows/hex-publish.yml"
  @default_helper "script/guarded_hex_publish.sh"
  @default_cleanroom_script "script/verify_companion_cleanroom.sh"
  @default_doctor_task "lib/mix/tasks/crosswake.doctor.ex"
  @default_ios_backfill_script "script/release_candidate/ios_mirror.sh"
  @default_ios_backfill_workflow ".github/workflows/ios-mirror-backfill.yml"
  @default_android_publication "script/release_candidate/android_publication.sh"
  @default_release_workflow_policy "lib/crosswake/release_candidate/workflow.ex"
  @default_release_config "release-please-config.json"
  @default_manifest ".release-please-manifest.json"
  @default_ci_workflow ".github/workflows/crosswake-ci.yml"
  @default_companion_root "packages"
  @components ~w(rulestead rindle sigra chimeway threadline)
  @hex_packages ~w(crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline)
  @companion_floors %{
    "crosswake_rulestead" => "~> 0.2",
    "crosswake_rindle" => "~> 0.2",
    "crosswake_sigra" => "~> 0.2",
    "crosswake_chimeway" => "~> 0.2",
    "crosswake_threadline" => "~> 0.2"
  }

  def run(argv \\ System.argv(), env_path \\ System.get_env("RELEASE_WORKFLOW_PATH")) do
    workflow_path = workflow_path(argv, env_path)
    workflow = File.read!(workflow_path)
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    recovery_workflow =
      File.read!(path_from_env("HEX_PUBLISH_WORKFLOW_PATH", @default_recovery_workflow))

    non_comment_recovery = strip_full_line_comments(recovery_workflow)
    helper = File.read!(path_from_env("GUARDED_HEX_PUBLISH_PATH", @default_helper))
    non_comment_helper = strip_full_line_comments(helper)

    cleanroom_script =
      File.read!(path_from_env("CLEANROOM_SCRIPT_PATH", @default_cleanroom_script))

    non_comment_cleanroom_script = strip_full_line_comments(cleanroom_script)
    doctor_task = File.read!(path_from_env("DOCTOR_TASK_PATH", @default_doctor_task))
    non_comment_doctor_task = strip_full_line_comments(doctor_task)

    ios_backfill_script =
      File.read!(path_from_env("IOS_BACKFILL_SCRIPT_PATH", @default_ios_backfill_script))

    non_comment_ios_backfill_script = strip_full_line_comments(ios_backfill_script)

    ios_backfill_workflow =
      File.read!(path_from_env("IOS_BACKFILL_WORKFLOW_PATH", @default_ios_backfill_workflow))

    non_comment_ios_backfill_workflow = strip_full_line_comments(ios_backfill_workflow)

    android_publication =
      File.read!(path_from_env("ANDROID_PUBLICATION_PATH", @default_android_publication))

    non_comment_android_publication = strip_full_line_comments(android_publication)

    release_workflow_policy =
      File.read!(path_from_env("RELEASE_WORKFLOW_POLICY_PATH", @default_release_workflow_policy))

    non_comment_release_workflow_policy = strip_full_line_comments(release_workflow_policy)

    release_config =
      path_from_env("RELEASE_PLEASE_CONFIG_PATH", @default_release_config)
      |> File.read!()
      |> JSON.decode!()

    release_manifest =
      path_from_env("RELEASE_PLEASE_MANIFEST_PATH", @default_manifest)
      |> File.read!()
      |> JSON.decode!()

    companion_root = path_from_env("COMPANION_MIX_ROOT", @default_companion_root)

    ci_workflow =
      path_from_env("CROSSWAKE_CI_WORKFLOW_PATH", @default_ci_workflow)
      |> File.read!()
      |> strip_full_line_comments()

    checks =
      [
        concurrency_not_cancelled(non_comment_workflow),
        concurrency_queue_max(non_comment_workflow),
        no_true_cancellation(non_comment_workflow),
        paths_released(non_comment_workflow),
        path_gate(jobs, "release.root_hex.path_gate", "publish-hex", "."),
        path_gate(
          jobs,
          "release.ios.path_gate",
          "publish-ios-core",
          "packages/crosswake-shell-core-ios"
        ),
        path_gate(
          jobs,
          "release.android.path_gate",
          "publish-android-core",
          "packages/crosswake-shell-core-android"
        ),
        aggregate_gate_absent(jobs),
        ios_proof_decoupled(jobs),
        android_proof_decoupled(jobs),
        workflow_aggregate_gate_absent(jobs),
        workflow_proof_after_publish(jobs),
        workflow_native_proof_decoupled(jobs),
        native_rollup_summary(jobs),
        native_status_artifact(jobs),
        release_ios_ssh_transport(jobs),
        approved_release_merge_guard(jobs),
        linked_release_children(jobs, non_comment_helper, non_comment_android_publication),
        release_ios_ordinary_atomic_push(jobs),
        release_ios_checkout_ref_pinned(jobs),
        release_ios_independent_publication(jobs),
        partial_release_truth(
          jobs,
          non_comment_release_workflow_policy,
          non_comment_recovery,
          non_comment_android_publication
        ),
        phase168_partial_recovery_routes(
          non_comment_recovery,
          non_comment_ios_backfill_workflow,
          non_comment_android_publication
        ),
        native_rollup_fails_closed(jobs),
        release_failure_alert_native(jobs),
        ios_mirror_four_mode_adapter(non_comment_ios_backfill_script),
        trusted_hex_candidate_rehearsal(non_comment_recovery),
        trusted_ios_candidate_rehearsal(non_comment_ios_backfill_workflow),
        trusted_candidate_receipt_attestation(non_comment_ios_backfill_workflow),
        trusted_rehearsal_identity(non_comment_recovery, non_comment_ios_backfill_workflow),
        trusted_rehearsal_no_mutation(non_comment_recovery, non_comment_ios_backfill_workflow),
        workflow_concurrency_queue_max(non_comment_workflow),
        workflow_no_cancel_in_progress_true(non_comment_workflow),
        cleanup_after_publish_and_proof(jobs),
        cleanup_pr_only(jobs),
        cleanup_pr_deduped(jobs),
        hex_publish_already_live_preflight(non_comment_helper),
        hex_publish_no_replace(non_comment_workflow, non_comment_recovery, non_comment_helper),
        hex_publish_shared_helper(jobs, non_comment_workflow),
        recovery_component_input(non_comment_recovery),
        recovery_exact_ref_only(non_comment_recovery),
        recovery_package_map_complete(non_comment_helper, non_comment_recovery),
        recovery_already_live_success_continues(non_comment_helper),
        cleanroom_hex_metadata_floor(non_comment_cleanroom_script),
        cleanroom_exact_companion_pin(non_comment_cleanroom_script),
        cleanroom_lockfile_postcondition(non_comment_cleanroom_script),
        cleanroom_package_profiles_preserved(non_comment_cleanroom_script),
        doctor_app_config_requirement(non_comment_doctor_task),
        doctor_fresh_router_loaded(non_comment_cleanroom_script),
        cleanroom_package_matrix_complete(jobs, non_comment_cleanroom_script),
        workflow_companion_floors_honest(companion_root),
        workflow_doctor_proof_unmasked(non_comment_doctor_task, non_comment_cleanroom_script),
        version_graph_lockstep_core_native_only(release_config),
        version_graph_companions_independent(release_config, release_manifest),
        version_graph_companion_floors_honest(companion_root),
        candidate_ci_contract(ci_workflow)
      ] ++ component_gates(jobs) ++ component_proof_gates(jobs)

    failures = Enum.filter(checks, &match?({:error, _, _}, &1))

    for {status, id, detail} <- checks do
      prefix = if status == :ok, do: "OK", else: "FAIL"
      IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
    end

    if failures == [] do
      System.halt(0)
    else
      System.halt(1)
    end
  end

  defp workflow_path([path | _], _env_path) when is_binary(path) and path != "", do: path
  defp workflow_path(_, env_path) when is_binary(env_path) and env_path != "", do: env_path
  defp workflow_path(_, _), do: @default_workflow

  defp path_from_env(name, default) do
    case System.get_env(name) do
      value when is_binary(value) and value != "" -> value
      _ -> default
    end
  end

  defp job_blocks(workflow) do
    ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
    |> Regex.scan(workflow, capture: :all_but_first)
    |> Map.new(fn [name, block] -> {name, strip_full_line_comments(block)} end)
  end

  defp strip_full_line_comments(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp job_block(jobs, job), do: Map.get(jobs, job, "")

  defp job_if(jobs, job), do: jobs |> job_block(job) |> job_key("if") |> normalize_expression()

  defp job_needs(jobs, job) do
    jobs
    |> job_block(job)
    |> job_key("needs")
    |> then(&Regex.scan(~r/[A-Za-z0-9_-]+/, &1))
    |> List.flatten()
  end

  defp job_needs?(jobs, job, need), do: need in job_needs(jobs, job)

  defp job_key(block, key) do
    lines = String.split(block, "\n", trim: false)
    key_regex = ~r/^    #{Regex.escape(key)}:\s*(.*)$/

    case Enum.find_index(lines, &Regex.match?(key_regex, &1)) do
      nil ->
        ""

      index ->
        line = Enum.at(lines, index)
        [raw_value] = Regex.run(key_regex, line, capture: :all_but_first)
        raw_value = raw_value |> strip_inline_comment() |> String.trim()

        if raw_value == "" or raw_value in ["|", "|-", ">", ">-"] do
          lines
          |> Enum.drop(index + 1)
          |> Enum.take_while(&(not job_level_key?(&1)))
          |> Enum.join("\n")
        else
          raw_value
        end
    end
  end

  defp job_level_key?(line), do: Regex.match?(~r/^    [A-Za-z0-9_-]+:\s*/, line)

  defp strip_inline_comment(line), do: line |> String.split(~r/\s+#/, parts: 2) |> hd()

  defp normalize_expression(value) do
    value
    |> String.split("\n", trim: false)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp check(id, true, detail), do: {:ok, id, detail}
  defp check(id, false, detail), do: {:error, id, detail}

  defp candidate_ci_contract(workflow) do
    jobs = job_blocks(workflow)
    classifier = job_block(jobs, "classify-change")
    fixtures = job_block(jobs, "release-candidate-fixtures")
    full = job_block(jobs, "release-candidate-full-proof")
    umbrella = job_block(jobs, "merge-blocking-crosswake-ci")

    classifier_closed? =
      includes?(classifier, "release_candidate_scope=full_matrix") and
        includes?(classifier, "release_candidate_reason=checkout_or_object_validation_failed") and
        includes?(classifier, "release_candidate_scope=fast_fixtures") and
        includes?(classifier, "release_candidate_reason=release_inputs_unchanged") and
        includes?(classifier, "release_please_candidate") and
        includes?(classifier, "release_sensitive_input_changed")

    fixtures_complete? =
      job_if(jobs, "release-candidate-fixtures") ==
        "needs.classify-change.result == 'success'" and
        includes?(fixtures, "test/crosswake/release_candidate") and
        includes?(fixtures, "script/check_release_workflow_integrity.exs")

    full_complete? =
      job_if(jobs, "release-candidate-full-proof") ==
        "needs.classify-change.outputs.release_candidate_scope == 'full_matrix'" and
        includes?(full, "ref: ${{ github.event.pull_request.head.sha }}") and
        includes?(full, "script/release_candidate/hex_artifacts.sh") and
        includes?(full, "script/verify_companion_cleanroom.sh") and
        includes?(full, "test/crosswake/release_candidate/coordinate_test.exs") and
        includes?(full, "test/crosswake/release_candidate/mirror_test.exs") and
        includes?(full, "test/crosswake/release_candidate/workflow_test.exs") and
        includes?(full, "test/crosswake/release_candidate/receipt_test.exs") and
        includes?(full, "release-candidate-ci-receipt.json") and
        includes?(full, "package_count\": 6") and includes?(full, "profile_count\": 5") and
        includes?(full, "install_count\": 2") and
        includes?(full, "mix crosswake.release.candidate --version 0.2.1 --ref <40sha>") and
        not includes?(full, "HEX_API_KEY") and not includes?(full, "MIRROR_DEPLOY_KEY") and
        not includes?(full, "git push")

    umbrella_closed? =
      includes?(umbrella, "release-candidate-fixtures") and
        includes?(umbrella, "release-candidate-full-proof") and
        includes?(umbrella, "release_inputs_unchanged") and
        includes?(umbrella, "candidate scope or reason was missing or unknown")

    check(
      "release.ci.candidate_matrix",
      classifier_closed? and fixtures_complete? and full_complete? and umbrella_closed?,
      "Crosswake CI must always run stable fixtures and fail open to exact-head non-vacuous full candidate proof without credentials"
    )
  end

  defp includes?(text, value) when is_binary(value), do: String.contains?(text, value)
  defp includes?(text, %Regex{} = regex), do: Regex.match?(regex, text)

  defp hex_publish_already_live_preflight(helper) do
    check(
      "release.hex_publish.already_live_preflight",
      includes?(helper, "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}") and
        includes?(helper, "json.load") and
        includes?(helper, "seen_version") and
        includes?(helper, "[crosswake] OK:") and
        includes?(helper, "already live on Hex.pm; no publish attempted") and
        includes?(helper, "Continuing to proof"),
      "guarded Hex helper must parse exact Hex release JSON and report already-live package/version as success"
    )
  end

  defp hex_publish_no_replace(workflow, recovery_workflow, helper) do
    check(
      "release.hex_publish.no_replace",
      not includes?(workflow, "--replace") and not includes?(recovery_workflow, "--replace") and
        not includes?(helper, "--replace"),
      "normal publish and recovery paths must not use routine registry replacement syntax"
    )
  end

  defp hex_publish_shared_helper(jobs, workflow) do
    expected_jobs =
      [{"publish-hex", "crosswake"}] ++
        Enum.map(@components, &{"publish-hex-#{&1}", "crosswake_#{&1}"})

    helper_jobs_ok? =
      Enum.all?(expected_jobs, fn {job, package} ->
        block = job_block(jobs, job)
        includes?(block, "script/guarded_hex_publish.sh") and includes?(block, package)
      end)

    check(
      "release.hex_publish.shared_helper",
      helper_jobs_ok? and not includes?(workflow, "mix hex.publish --yes"),
      "all automatic Hex jobs must call script/guarded_hex_publish.sh and avoid direct publish commands"
    )
  end

  defp recovery_component_input(recovery_workflow) do
    has_inputs? =
      includes?(recovery_workflow, ~r/^\s+package:\s*$/m) and
        includes?(recovery_workflow, ~r/^\s+ref:\s*$/m) and
        includes?(recovery_workflow, ~r/^\s+release_version:\s*$/m)

    has_packages? = Enum.all?(@hex_packages, &includes?(recovery_workflow, &1))

    check(
      "recovery.hex.component_input",
      has_inputs? and has_packages? and not includes?(recovery_workflow, "inputs.tag"),
      "manual Hex recovery must expose package/ref/release_version inputs for exactly the Hex package family"
    )
  end

  defp recovery_exact_ref_only(recovery_workflow) do
    forbidden_samples =
      ~w(release/v0.2.0 feature/v0.2.0 refs/tags/v0.2.0 refs/heads/release/v0.2.0 refs/heads/* heads/* main master)

    check(
      "recovery.hex.exact_ref_only",
      includes?(recovery_workflow, "^[0-9a-f]{40}$") and
        includes?(
          recovery_workflow,
          "EXPECTED_TAG_REF=\"refs/tags/${TAG_COMPONENT}-v${EXPECTED_VERSION}\""
        ) and
        includes?(recovery_workflow, "crosswake) TAG_COMPONENT=\"hex\"") and
        includes?(recovery_workflow, "crosswake_sigra|crosswake_chimeway|crosswake_threadline") and
        includes?(recovery_workflow, "[ \"$RECOVERY_REF\" = \"$EXPECTED_TAG_REF\" ]") and
        includes?(recovery_workflow, "actions/checkout") and
        includes?(recovery_workflow, "ref: ${{ inputs.ref }}") and
        Enum.all?(forbidden_samples, &includes?(recovery_workflow, &1)) and
        includes?(recovery_workflow, "git rev-parse HEAD"),
      "manual Hex recovery must reject mutable/bare refs, require package-scoped release tags, and print the checked-out SHA"
    )
  end

  defp recovery_package_map_complete(helper, recovery_workflow) do
    helper_cases_ok? =
      Enum.all?(@hex_packages, fn package ->
        includes?(helper, ~r/^\s*#{Regex.escape(package)}\)/m)
      end)

    recovery_options_ok? = Enum.all?(@hex_packages, &includes?(recovery_workflow, &1))

    check(
      "recovery.hex.package_map_complete",
      helper_cases_ok? and recovery_options_ok?,
      "guarded helper and manual recovery options must cover root Hex plus all five companion Hex packages"
    )
  end

  defp recovery_already_live_success_continues(helper) do
    check(
      "recovery.hex.already_live_success_continues",
      includes?(helper, "already live on Hex.pm; no publish attempted. Continuing to proof.") and
        includes?(helper, "emit_outputs \"already_live\"") and
        includes?(helper, "proof=continue"),
      "already-live package/version state must exit successfully with proof continuation state"
    )
  end

  defp cleanroom_hex_metadata_floor(script) do
    required_evidence = [
      "package_config",
      "validate_inputs",
      "fetch_hex_release_metadata",
      "parse_core_requirement_from_release",
      "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}",
      "requirements.crosswake.requirement",
      "json.load",
      "unknown Hex package",
      "does not look like a valid semver string",
      "Hex.pm returned 404",
      "version mismatch",
      "retired or unusable",
      "missing requirements.crosswake.requirement",
      "malformed JSON"
    ]

    local_floor_evidence? =
      includes?(script, "CROSSWAKE_CORE_REQUIREMENT") or
        includes?(script, "PACKAGE_DIR") or
        includes?(script, "companion_compatibility.md") or
        includes?(script, ~r/grep\s+-E[^\n]*:crosswake/)

    check(
      "release.cleanroom.hex_metadata_floor",
      Enum.all?(required_evidence, &includes?(script, &1)) and not local_floor_evidence?,
      "clean-room proof must derive the core floor from exact Hex metadata requirements.crosswake.requirement and fail closed on bad package/version/release metadata"
    )
  end

  defp cleanroom_exact_companion_pin(script) do
    check(
      "release.cleanroom.exact_companion_pin",
      includes?(script, "PACKAGE_REQUIREMENT=\"== ${VERSION}\"") and
        includes?(script, "{:${PACKAGE}, \"${PACKAGE_REQUIREMENT}\"}") and
        not includes?(script, "PACKAGE_REQUIREMENT=\"${PACKAGE_REQUIREMENT:-== ${VERSION}}\"") and
        not includes?(script, "{:\"${PACKAGE}\", \"~> 0.1\"}") and
        not includes?(script, "{:\"${PACKAGE}\", \"~> 0.2\"}"),
      "clean-room proof must install the companion under test as == VERSION, not a range or env fallback"
    )
  end

  defp cleanroom_lockfile_postcondition(script) do
    check(
      "release.cleanroom.lockfile_postcondition",
      includes?(script, "assert_lockfile_postconditions") and
        includes?(script, "lock_version_for") and
        includes?(script, ~r/mix deps\.get\s*\nassert_lockfile_postconditions/) and
        includes?(script, "mix.lock") and
        includes?(script, "Version.match?") and
        includes?(script, "SELECTED_CORE_VERSION") and
        includes?(script, "assert_absent_lock_deps"),
      "clean-room proof must assert mix.lock selected the exact companion and a crosswake version matching the derived floor"
    )
  end

  defp cleanroom_package_profiles_preserved(script) do
    all_package_cases? =
      Enum.all?(@components, fn component ->
        includes?(script, ~r/^\s*crosswake_#{component}\)/m)
      end)

    check(
      "release.cleanroom.package_profiles_preserved",
      all_package_cases? and
        includes?(script, "PROFILE=\"engine-present\"") and
        includes?(script, "PROFILE=\"no-engine-companion\"") and
        includes?(script, "PROFILE=\"threadline-observer\"") and
        includes?(script, "assert_absent_lock_deps crosswake_sigra") and
        includes?(script, "assert_absent_lock_deps crosswake_sigra crosswake_chimeway") and
        includes?(script, "observer-not-registered") and
        includes?(script, "config :crosswake, :companions, [${COMPANION_MODULE}]"),
      "clean-room proof must preserve all five package profiles, Chimeway/Sigra absence, and Threadline observer non-registration"
    )
  end

  defp cleanroom_package_matrix_complete(jobs, script) do
    workflow_jobs_complete? =
      Enum.all?(@components, fn component ->
        job = "clean-room-proof-#{component}"
        block = job_block(jobs, job)

        Map.has_key?(jobs, job) and
          cleanroom_job_invokes_package?(block, component)
      end)

    script_packages_complete? =
      Enum.all?(@components, fn component ->
        includes?(script, ~r/^\s*crosswake_#{component}\)/m) and
          includes?(script, "crosswake_#{component}")
      end)

    threadline_runtime = threadline_runtime_config_section(script)

    chimeway_absence? = includes?(script, "assert_absent_lock_deps crosswake_sigra")

    threadline_absence? =
      includes?(script, "assert_absent_lock_deps crosswake_sigra crosswake_chimeway") and
        includes?(threadline_runtime, "observer-not-registered") and
        not includes?(threadline_runtime, "config :crosswake, :companions")

    check(
      "release.cleanroom.package_matrix_complete",
      workflow_jobs_complete? and script_packages_complete? and chimeway_absence? and
        threadline_absence?,
      "release-please.yml and script/verify_companion_cleanroom.sh must cover all five package proof jobs, Release Please version args, chimeway/threadline sibling absence, and threadline observer non-registration; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp cleanroom_job_invokes_package?(block, component) do
    package = "crosswake_#{component}"

    includes?(
      block,
      ~r/bash\s+script\/verify_companion_cleanroom\.sh\s+#{Regex.escape(package)}\s+"?\$\{\{\s*needs\.release-please\.outputs\.#{component}_version\s*\}\}"?/s
    )
  end

  defp threadline_runtime_config_section(script) do
    marker = ~s(if [ "$PACKAGE" = "crosswake_threadline" ]; then)
    stop = ~s(elif [ "$NO_ENGINE" = "1" ]; then)

    case String.split(script, marker) do
      [_] ->
        ""

      parts ->
        parts
        |> List.last()
        |> String.split(stop, parts: 2)
        |> hd()
    end
  end

  defp doctor_app_config_requirement(doctor_task) do
    requirements =
      ~r/@requirements\s+\[(.*?)\]/s
      |> Regex.scan(doctor_task, capture: :all_but_first)
      |> List.flatten()

    has_app_config? = Enum.any?(requirements, &String.contains?(&1, ~s("app.config")))
    has_app_start? = Enum.any?(requirements, &String.contains?(&1, "app.start"))

    check(
      "release.doctor.app_config_requirement",
      has_app_config? and not has_app_start?,
      "mix crosswake.doctor must require app.config and must not require app.start before loading host routers"
    )
  end

  defp doctor_fresh_router_loaded(cleanroom_script) do
    doctor_command? =
      includes?(
        cleanroom_script,
        ~r/^\s*mix\s+crosswake\.doctor\s+--router\s+CleanRoomHost\.Router\s*$/m
      )

    script_preloads_router? =
      includes?(cleanroom_script, "Code.ensure_loaded?(CleanRoomHost.Router)") or
        includes?(cleanroom_script, "Code.ensure_compiled(CleanRoomHost.Router)") or
        includes?(cleanroom_script, "Code.ensure_compiled?(CleanRoomHost.Router)")

    check(
      "release.doctor.fresh_router_loaded",
      doctor_command? and not script_preloads_router?,
      "clean-room proof must rely on mix crosswake.doctor --router CleanRoomHost.Router without a separate router preload"
    )
  end

  defp workflow_doctor_proof_unmasked(doctor_task, cleanroom_script) do
    requirements =
      ~r/@requirements\s+\[(.*?)\]/s
      |> Regex.scan(doctor_task, capture: :all_but_first)
      |> List.flatten()

    doctor_owns_app_config? =
      Enum.any?(requirements, &String.contains?(&1, ~s("app.config"))) and
        Enum.all?(requirements, &(not String.contains?(&1, "app.start")))

    doctor_command? =
      includes?(
        cleanroom_script,
        ~r/^\s*mix\s+crosswake\.doctor\s+--router\s+CleanRoomHost\.Router\s*$/m
      )

    script_preloads_router? =
      includes?(cleanroom_script, "Code.ensure_loaded?(CleanRoomHost.Router)") or
        includes?(cleanroom_script, "Code.ensure_compiled(CleanRoomHost.Router)") or
        includes?(cleanroom_script, "Code.ensure_compiled?(CleanRoomHost.Router)")

    check(
      "release.workflow.doctor_proof_unmasked",
      doctor_owns_app_config? and doctor_command? and not script_preloads_router?,
      "lib/mix/tasks/crosswake.doctor.ex must own app.config readiness and script/verify_companion_cleanroom.sh must not preload CleanRoomHost.Router before the doctor command; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp version_graph_lockstep_core_native_only(config) do
    linked =
      config
      |> Map.get("plugins", [])
      |> Enum.find(%{}, &(Map.get(&1, "type") == "linked-versions"))
      |> Map.get("components", [])

    check(
      "release.version_graph.lockstep_core_native_only",
      MapSet.new(linked) == MapSet.new(~w(hex ios-core android-core)),
      "Release Please linked-versions group must contain only hex, ios-core, and android-core"
    )
  end

  defp version_graph_companions_independent(config, manifest) do
    packages = Map.get(config, "packages", %{})

    linked_components =
      config
      |> Map.get("plugins", [])
      |> Enum.find(%{}, &(Map.get(&1, "type") == "linked-versions"))
      |> Map.get("components", [])
      |> MapSet.new()

    companions_ok? =
      Enum.all?(@components, fn component ->
        path = "packages/crosswake_#{component}"
        package = Map.get(packages, path, %{})

        Map.get(package, "component") == "crosswake_#{component}" and
          Map.get(package, "separate-pull-requests") == true and
          not MapSet.member?(linked_components, "crosswake_#{component}") and
          Map.has_key?(manifest, path)
      end)

    check(
      "release.version_graph.companions_independent",
      companions_ok?,
      "all crosswake_* companions must remain separately versioned Release Please components"
    )
  end

  defp version_graph_companion_floors_honest(companion_root) do
    floors_ok? =
      Enum.all?(@companion_floors, fn {package, floor} ->
        mix_path = Path.join([companion_root, package, "mix.exs"])

        File.exists?(mix_path) and
          File.read!(mix_path)
          |> includes?(~r/\{:crosswake,\s*"#{Regex.escape(floor)}"\}/)
      end)

    check(
      "release.version_graph.companion_floors_honest",
      floors_ok?,
      "companion crosswake_dep floors must match the independently owned current core requirements"
    )
  end

  defp workflow_companion_floors_honest(companion_root) do
    floors_ok? =
      Enum.all?(@companion_floors, fn {package, floor} ->
        mix_path = Path.join([companion_root, package, "mix.exs"])

        File.exists?(mix_path) and
          File.read!(mix_path)
          |> includes?(~r/\{:crosswake,\s*"#{Regex.escape(floor)}"\}/)
      end)

    check(
      "release.workflow.companion_floors_honest",
      floors_ok?,
      "package mix.exs files must match the independently owned current core floors; inspect packages/crosswake_*/mix.exs and rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp concurrency_not_cancelled(workflow) do
    check(
      "release.concurrency.not_cancelled",
      includes?(workflow, ~r/^\s*cancel-in-progress:\s*false\s*$/m),
      "release workflow publish/proof jobs must keep cancel-in-progress: false; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp concurrency_queue_max(workflow) do
    check(
      "release.concurrency.queue_max",
      not includes?(workflow, ~r/^\s*queue:/m),
      "release workflow concurrency must use only GitHub-supported keys; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp no_true_cancellation(workflow) do
    check(
      "release.concurrency.no_true_cancellation",
      not includes?(workflow, ~r/^\s*cancel-in-progress:\s*true\s*$/m),
      "release workflow must not combine release preservation with cancel-in-progress: true; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp workflow_concurrency_queue_max(workflow) do
    check(
      "release.workflow.concurrency_queue_max",
      not includes?(workflow, ~r/^\s*queue:/m),
      ".github/workflows/release-please.yml concurrency must use only supported group and cancel-in-progress keys; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp workflow_no_cancel_in_progress_true(workflow) do
    check(
      "release.workflow.no_cancel_in_progress_true",
      not includes?(workflow, ~r/^\s*cancel-in-progress:\s*true\s*$/m),
      ".github/workflows/release-please.yml must not set cancel-in-progress: true for release publish/proof runs; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp paths_released(workflow) do
    check(
      "release.outputs.paths_released",
      includes?(workflow, ~r/^\s*paths_released:/m),
      "release-please must expose paths_released for path-specific publish gates; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp path_gate(jobs, id, job, path) do
    expression = job_if(jobs, job)

    check(
      id,
      includes?(
        expression,
        "contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}')"
      ) and
        not includes?(expression, "releases_created"),
      "#{job} must gate on paths_released exact path #{path}; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp path_gate_expression(path),
    do: "${{ contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}') }}"

  defp component_gate_expression(component),
    do: "${{ needs.release-please.outputs.#{component}_release_created == 'true' }}"

  defp aggregate_gate_absent(jobs) do
    offenders =
      jobs
      |> Enum.filter(fn {job, _block} ->
        behavioral_job?(job) and
          includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    detail =
      case offenders do
        [] ->
          "behavioral jobs must not gate on aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"

        jobs ->
          "behavioral jobs use aggregate releases_created: #{Enum.join(jobs, ", ")}; use exact path/component gates"
      end

    check("release.aggregate_gate.behavioral_jobs_absent", offenders == [], detail)
  end

  defp workflow_aggregate_gate_absent(jobs) do
    offenders =
      jobs
      |> Enum.filter(fn {job, _block} ->
        behavioral_job?(job) and
          includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    detail =
      case offenders do
        [] ->
          ".github/workflows/release-please.yml behavioral jobs must not gate on aggregate releases_created; rerun elixir script/check_release_workflow_integrity.exs"

        jobs ->
          "behavioral jobs use aggregate releases_created: #{Enum.join(jobs, ", ")}; use exact path/component gates in .github/workflows/release-please.yml"
      end

    check("release.workflow.aggregate_gate.behavioral_jobs_absent", offenders == [], detail)
  end

  defp behavioral_job?(job) do
    String.starts_with?(job, "publish-") or
      String.starts_with?(job, "clean-room-proof-") or
      job == "release-as-cleanup"
  end

  defp ios_proof_decoupled(jobs) do
    check(
      "release.ios_proof.decoupled",
      job_needs?(jobs, "clean-room-proof-ios", "release-please") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-ios-core") and
        not job_needs?(jobs, "clean-room-proof-ios", "publish-android-core") and
        job_if(jobs, "clean-room-proof-ios") ==
          path_gate_expression("packages/crosswake-shell-core-ios"),
      "iOS clean-room proof must depend on iOS publish and not Android publish; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp android_proof_decoupled(jobs) do
    check(
      "release.android_proof.decoupled",
      job_needs?(jobs, "clean-room-proof-android", "release-please") and
        job_needs?(jobs, "clean-room-proof-android", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-android", "publish-android-core") and
        not job_needs?(jobs, "clean-room-proof-android", "publish-ios-core") and
        job_if(jobs, "clean-room-proof-android") ==
          path_gate_expression("packages/crosswake-shell-core-android"),
      "Android clean-room proof must depend on Android publish and not iOS mirror; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp workflow_native_proof_decoupled(jobs) do
    ios_ok? =
      job_needs?(jobs, "clean-room-proof-ios", "release-please") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-ios-core") and
        not job_needs?(jobs, "clean-room-proof-ios", "publish-android-core") and
        job_if(jobs, "clean-room-proof-ios") ==
          path_gate_expression("packages/crosswake-shell-core-ios")

    android_ok? =
      job_needs?(jobs, "clean-room-proof-android", "release-please") and
        job_needs?(jobs, "clean-room-proof-android", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-android", "publish-android-core") and
        not job_needs?(jobs, "clean-room-proof-android", "publish-ios-core") and
        job_if(jobs, "clean-room-proof-android") ==
          path_gate_expression("packages/crosswake-shell-core-android")

    check(
      "release.workflow.native_proof_decoupled",
      ios_ok? and android_ok?,
      "native clean-room proofs in .github/workflows/release-please.yml must depend only on their own native publish job plus root Hex publish; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  # REWRITE (not rename) of the retired release.mirror_token.preflight and
  # release.workflow.mirror_token_preflight checks. Both asserted on machinery
  # (the old HTTPS token secret, the anonymous public-repo read probe) that no
  # longer exists once SSH transport landed — collapsed into one check
  # asserting the new SSH-preflight shape (D-03/D-04).
  defp release_ios_ssh_transport(jobs) do
    block = job_block(jobs, "publish-ios-core")

    check(
      "release.ios.ssh_transport",
      includes?(block, "persist-credentials: false") and
        includes?(block, "webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555") and
        includes?(block, "ssh-keyscan") and
        includes?(block, "git@github.com:szTheory/crosswake-shell-core-ios.git") and
        includes?(block, "MIRROR_DEPLOY_KEY is not configured") and
        not includes?(block, "x-access-token"),
      "publish-ios-core must authenticate over SSH via MIRROR_DEPLOY_KEY with persist-credentials: false, an ssh-keyscan known_hosts step, and a fail-fast preflight, never an HTTPS URL-embedded token; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp approved_release_merge_guard(jobs) do
    block = job_block(jobs, "approved-release-guard")

    required_outputs =
      ~w(approved_head approved_tree merge_oid merge_parents merge_tree candidate_receipt candidate_run_id candidate_receipt_run_id)

    check(
      "release.approval.merge_tree_guard",
      Enum.all?(required_outputs, &includes?(block, &1)) and
        includes?(block, "git rev-list --parents -n 1") and
        includes?(block, ~s([ "$parent_count" -eq 3 ])) and
        includes?(block, ~s([ "$approved_head" = "$second_parent" ])) and
        includes?(block, ~s([ "$merge_tree" = "$approved_tree" ])) and
        includes?(block, "linked_candidate=false") and
        includes?(block, ~s([ "$linked_candidate" = "true" ] || exit 0)) and
        includes?(block, "phase168-candidate-receipt-${approved_head}") and
        includes?(block, "phase168-candidate-ci-${approved_head}") and
        includes?(block, "release-candidate-ci-receipt.json") and
        includes?(block, ~s(.state == "READY FOR APPROVAL")) and
        includes?(block, ~s(.identity.bound == .identity.observed)) and
        includes?(block, ".external_state.changed == false") and
        job_needs?(jobs, "release-please", "approved-release-guard"),
      "Release Please must run only after exact approved-head parentage, identical tree, and READY receipt validation"
    )
  end

  defp linked_release_children(jobs, helper, android_publication) do
    rollup = job_block(jobs, "linked-release-rollup")
    exact_public = job_block(jobs, "exact-public-proof")

    guarded_children? =
      Enum.all?(~w(publish-hex publish-ios-core publish-android-core), fn job ->
        block = job_block(jobs, job)

        job_needs?(jobs, job, "approved-release-guard") and
          includes?(
            job_if(jobs, job),
            "needs.approved-release-guard.outputs.linked_release == 'true'"
          ) and
          includes?(job_if(jobs, job), "needs.release-please.outputs.version == '0.2.1'") and
          not includes?(block, "environment:")
      end)

    graph_children =
      ~w(publish-hex publish-ios-core publish-android-core clean-room-proof-ios clean-room-proof-android exact-public-proof)

    companions_excluded? =
      Enum.all?(@components, fn component ->
        not job_needs?(jobs, "publish-hex-#{component}", "approved-release-guard")
      end)

    check(
      "release.approval.linked_graph",
      guarded_children? and companions_excluded? and
        includes?(job_block(jobs, "publish-hex"), "--candidate-receipt") and
        includes?(helper, "verify_approved_identity") and
        includes?(job_block(jobs, "publish-android-core"), "android_publication.sh") and
        includes?(android_publication, "APPROVED_HEAD") and
        includes?(exact_public, "exact-public") and
        Enum.all?(graph_children, &job_needs?(jobs, "linked-release-rollup", &1)) and
        includes?(rollup, "child_states") and includes?(rollup, "successful_coordinates") and
        includes?(rollup, "Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()") and
        includes?(rollup, "APPROVED_REF") and includes?(rollup, "CANDIDATE_RECEIPT"),
      "the fixed postapproval graph must contain only guarded Hex/iOS/Android 0.2.1 children, exact-public proof, and a closed linked rollup"
    )
  end

  defp release_ios_ordinary_atomic_push(jobs) do
    block = job_block(jobs, "publish-ios-core")

    check(
      "release.ios.ordinary_atomic_push",
      includes?(block, "script/release_candidate/ios_mirror.sh publish") and
        includes?(block, "--approval-receipt") and includes?(block, "--expected-old-ref") and
        includes?(block, "--expected-new-ref") and not includes?(block, "--force"),
      "ordinary iOS publication must delegate to the exact approved adapter and contain no force path"
    )
  end

  # New check (D-11/D-20). Both clauses are required: copying
  # publish-android-core's checkout block verbatim has the ref but drops
  # fetch-depth: 0, silently handing `git subtree split` a shallow clone.
  defp release_ios_checkout_ref_pinned(jobs) do
    block = job_block(jobs, "publish-ios-core")

    check(
      "release.ios.checkout_ref_pinned",
      includes?(block, "ref: ${{ needs.release-please.outputs.tag_name }}") and
        includes?(block, "fetch-depth: 0"),
      "publish-ios-core must checkout at the release tag with full history, not the retroactive github.sha; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp release_ios_independent_publication(jobs) do
    check(
      "release.ios.independent_publication",
      job_needs?(jobs, "publish-ios-core", "release-please") and
        job_needs?(jobs, "publish-ios-core", "approved-release-guard") and
        not job_needs?(jobs, "publish-ios-core", "publish-hex") and
        not job_needs?(jobs, "publish-ios-core", "publish-android-core"),
      "the guarded iOS publication must remain independent of sibling registry outcomes so partial public truth is observable"
    )
  end

  defp partial_release_truth(jobs, policy, recovery_workflow, android_publication) do
    rollup = job_block(jobs, "linked-release-rollup")

    policy_contract? =
      Enum.all?(
        ~w(rollup! validate! receipt_external_state COMPLETE PARTIAL BLOCKED successful_coordinates failed_step failed_ref retry_failed_step_from_exact_ref_or_publish_forward_fix),
        &includes?(policy, &1)
      ) and
        includes?(
          policy,
          "@children ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a"
        ) and
        includes?(policy, "exact_hex!(input.approved_ref, 40)")

    exact_hex_recovery? =
      Enum.all?(~w(approved_head approved_tree merge_oid candidate_receipt), fn input ->
        includes?(recovery_workflow, input)
      end) and
        includes?(recovery_workflow, ~s(--merge-oid "${{ inputs.merge_oid }}")) and
        includes?(recovery_workflow, ~s(--candidate-receipt "${{ inputs.candidate_receipt }}"))

    exact_android_recovery? =
      includes?(android_publication, "--recover") and
        includes?(android_publication, ~S|[ "$(git rev-parse HEAD)" = "$SOURCE_REF" ]|) and
        includes?(android_publication, "already public; exact-ref recovery is complete") and
        not includes?(android_publication, "--replace") and
        not includes?(android_publication, "--force")

    check(
      "release.partial.exact_ref_recovery",
      policy_contract? and exact_hex_recovery? and exact_android_recovery? and
        includes?(rollup, "Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()") and
        includes?(rollup, "if: ${{ always() }}"),
      "partial rollup must retain fixed child truth and allow only exact-ref/idempotent or forward-fix recovery without replacement"
    )
  end

  defp phase168_partial_recovery_routes(recovery_workflow, ios_workflow, android_publication) do
    hex_recovery = recovery_workflow |> job_blocks() |> job_block("publish")
    android_recovery = recovery_workflow |> job_blocks() |> job_block("recover-android-core")
    ios_publish = ios_workflow |> job_blocks() |> job_block("publish-ios-mirror")

    approved_identity = [
      "b780a19863936619394087f1ffd384f1dca17c93",
      "1051ab90cf75e918c6f596f84578ac77eadf45af",
      "ecf63228243bfe7c2d6a377be996aa374b31d91f",
      "359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78"
    ]

    exact_registry_identity? =
      Enum.all?(approved_identity, fn identity ->
        includes?(hex_recovery, identity) and includes?(android_recovery, identity)
      end)

    exact_ios_identity? =
      Enum.all?(
        approved_identity ++
          [
            "9533049d1ee5239b122b43749ff90f8ace7c7f6b",
            "658d60253c58b7e0aedb576f16f40766fa677f23",
            "424ab96ede1b92f2b751b54bce04c6e607f0f3c8"
          ],
        &includes?(ios_publish, &1)
      )

    check(
      "release.partial.phase168_recovery_routes",
      exact_registry_identity? and exact_ios_identity? and
        includes?(hex_recovery, ~s([ "$RECOVERY_REF" = "$PHASE168_MERGE_OID" ])) and
        includes?(android_recovery, "github.event.inputs.operation == 'android-recovery'") and
        includes?(android_recovery, "android_publication.sh") and
        includes?(android_recovery, "--recover") and not includes?(android_recovery, "--execute") and
        includes?(ios_publish, "github.event.inputs.operation == 'publish'") and
        includes?(ios_publish, "ios_mirror.sh publish") and
        includes?(ios_publish, ~s(CROSSWAKE_IOS_MIRROR_EXECUTE: "true")) and
        not includes?(ios_publish, "force") and
        includes?(
          android_publication,
          "io/github/sztheory/crosswake-shell-core-android/0.2.1/crosswake-shell-core-android-0.2.1.pom"
        ) and
        not includes?(android_publication, "io/crosswake/crosswake-shell-core/0.2.1") and
        not includes?(android_publication, "--replace") and
        not includes?(android_publication, "--force"),
      "Phase 168 partial recovery must bind Hex, Maven, and atomic iOS publication to the approved immutable b780/1051/ecf/359 identity, correct public coordinates, and no tag movement or package replacement"
    )
  end

  # New check (D-17).
  defp native_rollup_fails_closed(jobs) do
    block = job_block(jobs, "native-release-rollup")

    check(
      "release.workflow.native_rollup_fails_closed",
      includes?(block, ~s(native_core" != "complete")) and
        includes?(block, "exit 1") and
        includes?(block, "if: ${{ always() }}"),
      "native-release-rollup must exit 1 when a native platform released this run without proving complete, and its artifact upload must still run via if: ${{ always() }}; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  # New check (D-15).
  defp release_failure_alert_native(jobs) do
    block = job_block(jobs, "release-failure-alert")

    required_needs =
      Enum.all?(
        ~w(publish-ios-core clean-room-proof-ios publish-android-core clean-room-proof-android native-release-rollup),
        &job_needs?(jobs, "release-failure-alert", &1)
      )

    required_results =
      Enum.all?(
        ~w(needs.publish-ios-core.result needs.clean-room-proof-ios.result needs.publish-android-core.result needs.clean-room-proof-android.result needs.native-release-rollup.result),
        &includes?(block, &1)
      )

    check(
      "release.workflow.release_failure_alert_native",
      required_needs and required_results,
      "release-failure-alert must need the four native jobs plus native-release-rollup and echo each of their results, so a mirror-push or native proof failure opens a tracking issue; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp native_rollup_summary(jobs) do
    block = job_block(jobs, "native-release-rollup")

    required_needs =
      Enum.all?(
        ~w(approved-release-guard release-please publish-ios-core clean-room-proof-ios publish-android-core clean-room-proof-android),
        &job_needs?(jobs, "native-release-rollup", &1)
      )

    required_results =
      Enum.all?(
        ~w(needs.publish-ios-core.result needs.clean-room-proof-ios.result needs.publish-android-core.result needs.clean-room-proof-android.result),
        &includes?(block, &1)
      )

    check(
      "release.workflow.native_rollup_summary",
      required_needs and job_if(jobs, "native-release-rollup") == "${{ always() }}" and
        required_results and
        includes?(block, "needs.approved-release-guard.outputs.linked_release") and
        includes?(block, ~s([ "$LINKED_RELEASE" != "true" ])) and
        includes?(block, "$GITHUB_STEP_SUMMARY") and
        includes?(block, "native_core=\"partial\"") and
        includes?(block, "native_core=${native_core}") and includes?(block, "next_action") and
        includes?(block, "Fix MIRROR_DEPLOY_KEY or run the iOS mirror backfill workflow."),
      "native-release-rollup must always summarize native publish/proof results, ignore proposal-only paths unless the exact linked-release guard passed, expose partial native_core state, and give a next safe action"
    )
  end

  defp native_status_artifact(jobs) do
    block = job_block(jobs, "native-release-rollup")

    # Version-agnostic on purpose: the invariant is that the rollup ALWAYS uploads the
    # status file and fails closed when it is missing — not which action version does it.
    # Pinning a literal `@v4` here made a routine dependabot bump (#50) red-line four
    # merge-blocking lanes, and blocked SHA-pinning this step per REL-05.
    check(
      "release.workflow.native_status_artifact",
      includes?(block, "native-release-status.json") and
        includes?(block, ~r{uses:\s*actions/upload-artifact@\S+}) and
        includes?(block, "if: ${{ always() }}") and
        includes?(block, "name: native-release-status") and
        includes?(block, "if-no-files-found: error"),
      "native-release-rollup must write native-release-status.json and always upload it as the native-release-status artifact, failing closed if absent"
    )
  end

  defp ios_mirror_four_mode_adapter(script) do
    check(
      "release.ios_mirror.four_modes",
      Enum.all?(~w(baseline candidate publish recovery), &includes?(script, &1)) and
        includes?(script, ~r/push\s+--dry-run\s+--porcelain\s+--atomic/) and
        includes?(script, "CROSSWAKE_IOS_MIRROR_EXECUTE") and
        includes?(script, ~s(--force-with-lease=refs/heads/main:${EXPECTED_OLD_REF})),
      "the iOS adapter must retain separate baseline, candidate, ordinary publication, and exact-ref recovery modes"
    )
  end

  defp trusted_hex_candidate_rehearsal(workflow) do
    jobs = job_blocks(workflow)
    block = job_block(jobs, "rehearse-hex-candidate")

    check(
      "release.rehearsal.hex_candidate",
      job_if(jobs, "rehearse-hex-candidate") ==
        "${{ github.event.inputs.operation == 'candidate-rehearsal' }}" and
        includes?(block, "script/release_candidate/hex_artifacts.sh") and
        includes?(block, "package_count\":6") and
        includes?(block, "candidate-rehearsal-hex") and
        not includes?(block, "script/guarded_hex_publish.sh") and
        not includes?(block, "mix hex.publish --yes"),
      "trusted Hex candidate rehearsal must build exactly six packages without any publication path"
    )
  end

  defp trusted_ios_candidate_rehearsal(workflow) do
    jobs = job_blocks(workflow)
    baseline = job_block(jobs, "inspect-ios-mirror-baseline")
    rehearsal = job_block(jobs, "rehearse-ios-mirror-candidate")

    check(
      "release.rehearsal.ios_candidate",
      includes?(baseline, "ios_mirror.sh baseline") and
        not includes?(baseline, "MIRROR_DEPLOY_KEY") and
        not includes?(baseline, "ssh-agent") and
        job_if(jobs, "rehearse-ios-mirror-candidate") ==
          "${{ github.event.inputs.operation == 'candidate-rehearsal' }}" and
        includes?(rehearsal, "ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}") and
        includes?(rehearsal, "ios_mirror.sh candidate") and
        includes?(rehearsal, "authorization_result") and
        includes?(rehearsal, "external_state_changed") and
        includes?(rehearsal, "candidate-rehearsal-ios"),
      "mirror baseline must be credential-free and candidate rehearsal must use the scoped deploy key only for an exact dry-run"
    )
  end

  defp trusted_candidate_receipt_attestation(workflow) do
    check(
      "release.candidate.receipt_attestation",
      includes?(workflow, "candidate-receipt-attestation") and
        includes?(workflow, "attest-candidate-receipt:") and
        includes?(workflow, "phase168-candidate-ci-${CANDIDATE_HEAD}") and
        includes?(workflow, "candidate-rehearsal-hex") and
        includes?(workflow, "candidate-rehearsal-ios") and
        includes?(workflow, "Crosswake.ReleaseCandidate.Receipt.validate!") and
        includes?(workflow, "phase168-candidate-receipt-${{ inputs.candidate_head }}") and
        includes?(workflow, "candidate-receipt.json") and
        includes?(workflow, "artifacts.json") and
        includes?(workflow, "external_state_changed=false"),
      "the existing trusted iOS workflow must attest one canonical READY receipt against exact CI, Hex, iOS, mirror, and zero-mutation evidence"
    )
  end

  defp trusted_rehearsal_identity(hex_workflow, ios_workflow) do
    required =
      ~w(requested_head observed_head observed_tree observed_base candidate_receipt run_id run_head run_conclusion workflow_sha256)

    check(
      "release.rehearsal.exact_identity",
      Enum.all?([hex_workflow, ios_workflow], fn workflow ->
        Enum.all?(required, &includes?(workflow, &1)) and
          includes?(workflow, "if-no-files-found: error")
      end),
      "both trusted rehearsal artifacts must bind requested/observed Git identity, receipt, workflow blob, and exact run identity"
    )
  end

  defp trusted_rehearsal_no_mutation(hex_workflow, ios_workflow) do
    hex = job_block(job_blocks(hex_workflow), "rehearse-hex-candidate")
    ios = job_block(job_blocks(ios_workflow), "rehearse-ios-mirror-candidate")

    check(
      "release.rehearsal.no_mutation",
      includes?(hex, "external_state_changed=false") and
        includes?(ios, "external_state_changed=false") and
        not includes?(hex, "HEX_API_KEY") and
        not includes?(hex, "guarded_hex_publish.sh") and
        not includes?(ios, "CROSSWAKE_IOS_MIRROR_EXECUTE"),
      "candidate rehearsal must fail closed without registry, ref, tag, or package mutation authority"
    )
  end

  defp cleanup_after_publish_and_proof(jobs) do
    condition = job_if(jobs, "release-as-cleanup")

    has_release_please_need? = job_needs?(jobs, "release-as-cleanup", "release-please")
    has_always? = includes?(condition, "always()")

    has_all_publish_needs? =
      Enum.all?(@components, &job_needs?(jobs, "release-as-cleanup", "publish-hex-#{&1}"))

    has_all_proof_needs? =
      Enum.all?(@components, &job_needs?(jobs, "release-as-cleanup", "clean-room-proof-#{&1}"))

    has_all_result_implications? =
      Enum.all?(@components, fn component ->
        includes?(
          condition,
          "needs.release-please.outputs.#{component}_release_created != 'true'"
        ) and
          includes?(condition, "needs.publish-hex-#{component}.result == 'success'") and
          includes?(condition, "needs.clean-room-proof-#{component}.result == 'success'")
      end)

    check(
      "release.cleanup.after_publish_and_proof",
      has_release_please_need? and has_always? and has_all_publish_needs? and
        has_all_proof_needs? and has_all_result_implications? and
        companion_proof_jobs_after_publish?(jobs),
      "release-as-cleanup must need every companion publish/proof job and require success for released components; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp workflow_proof_after_publish(jobs) do
    check(
      "release.workflow.proof_after_publish",
      companion_proof_jobs_after_publish?(jobs),
      "every clean-room-proof-* companion job in .github/workflows/release-please.yml must gate on its component release output and need its matching publish-hex-* job; rerun elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp cleanup_pr_only(jobs) do
    block = job_block(jobs, "release-as-cleanup")

    direct_main_push? =
      includes?(
        block,
        ~r/\bgit\s+push\s+\S+\s+(?:main|refs\/heads\/main|[^\s]+:(?:refs\/heads\/)?main)(?:\s|$)/
      )

    check(
      "release.cleanup.pr_only",
      includes?(block, "git checkout -b \"$branch\"") and
        includes?(block, "git push origin \"$branch\"") and
        includes?(block, "gh pr create") and
        includes?(block, "--base main") and
        not direct_main_push?,
      "release-as-cleanup must push a branch and open a PR, never push directly to main; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  # The cleanup job's branch name embeds github.run_id, so it never collides, and its
  # dirty-worktree check runs against a fresh main that still carries the pin — neither
  # can notice an already-open cleanup PR. Without an explicit guard every release run
  # opens another duplicate (#65/#68/#72). Assert the guard so it cannot regress.
  defp cleanup_pr_deduped(jobs) do
    block = job_block(jobs, "release-as-cleanup")

    check(
      "release.cleanup.deduped",
      includes?(block, ~r/gh\s+pr\s+list[^\n]*--state\s+open/) and
        includes?(block, "chore/release-as-cleanup-") and
        includes?(block, ~r/already open|not opening a duplicate/),
      "release-as-cleanup must check for an already-open cleanup PR before gh pr create, and bail instead of opening a duplicate; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp component_gates(jobs) do
    for component <- @components do
      job = "publish-hex-#{component}"

      check(
        "release.#{component}.component_gate",
        job_if(jobs, job) == component_gate_expression(component),
        "#{job} must gate on #{component}_release_created, not aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"
      )
    end
  end

  defp component_proof_gates(jobs) do
    for component <- @components do
      job = "clean-room-proof-#{component}"

      check(
        "release.#{component}.proof_gate",
        component_proof_after_publish?(jobs, component),
        "#{job} must gate on #{component}_release_created and need publish-hex-#{component}; run elixir script/check_release_workflow_integrity.exs"
      )
    end
  end

  defp companion_proof_jobs_after_publish?(jobs) do
    Enum.all?(@components, &component_proof_after_publish?(jobs, &1))
  end

  defp component_proof_after_publish?(jobs, component) do
    job = "clean-room-proof-#{component}"

    job_if(jobs, job) == component_gate_expression(component) and
      job_needs?(jobs, job, "release-please") and
      job_needs?(jobs, job, "publish-hex-#{component}") and
      not includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
  end
end

Crosswake.ReleaseWorkflowIntegrity.run()
