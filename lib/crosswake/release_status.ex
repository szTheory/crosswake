defmodule Crosswake.ReleaseStatus do
  @moduledoc """
  Reads Crosswake's release graph and reports local package-family release readiness.

  This is intentionally repository-local by default. Pass `live?: true` to add best-effort
  public registry probes for Hex, Maven Central, and the iOS SwiftPM mirror.
  """

  @schema_version "1.2.0"
  @candidate_version "0.2.1"
  @mirror_baseline_version "0.2.0"
  @manifest_path ".release-please-manifest.json"
  @config_path "release-please-config.json"
  @workflow_path ".github/workflows/release-please.yml"
  @android_gradle_path "packages/crosswake-shell-core-android/build.gradle.kts"
  @ios_mirror_url "https://github.com/szTheory/crosswake-shell-core-ios.git"
  @workflow_integrity_source "script/check_release_workflow_integrity.exs"
  @workflow_integrity_command "elixir script/check_release_workflow_integrity.exs"
  # D-18: a live probe only earns the `:unavailable` verdict after this many
  # failed attempts. A single network hiccup must never be reported as a real
  # answer of any kind — neither a present release nor a missing one.
  @probe_attempts 3
  @probe_retry_sleep_ms 200
  @core_path_gates [
    {"publish-hex", "."},
    {"publish-ios-core", "packages/crosswake-shell-core-ios"},
    {"publish-android-core", "packages/crosswake-shell-core-android"}
  ]
  @release_components ~w(rulestead rindle sigra chimeway threadline)
  @cleanroom_evidence_ids ~w(
    release.cleanroom.hex_metadata_floor
    release.cleanroom.exact_companion_pin
    release.cleanroom.lockfile_postcondition
    release.cleanroom.package_matrix_complete
    release.doctor.fresh_router_loaded
    release.workflow.doctor_proof_unmasked
  )
  @workflow_path_gate_ids ~w(
    release.outputs.paths_released
    release.root_hex.path_gate
    release.ios.path_gate
    release.android.path_gate
  )
  @governance_queue_ids ~w(
    release.concurrency.queue_max
    release.workflow.concurrency_queue_max
    release.workflow.no_cancel_in_progress_true
  )
  @behavioral_identity_ids ~w(
    release.aggregate_gate.behavioral_jobs_absent
    release.workflow.aggregate_gate.behavioral_jobs_absent
    release.workflow.proof_after_publish
    release.workflow.native_proof_decoupled
    release.ios.ssh_transport
    release.ios.ordinary_atomic_push
    release.workflow.native_rollup_summary
    release.workflow.native_status_artifact
    release.workflow.companion_floors_honest
    release.version_graph.lockstep_core_native_only
    release.version_graph.companions_independent
    release.version_graph.companion_floors_honest
  )
  @cleanup_evidence_ids ~w(
    release.cleanup.after_publish_and_proof
    release.cleanup.pr_only
  )

  @spec build(keyword()) :: map()
  def build(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    live? = Keyword.get(opts, :live?, false)

    manifest = read_json!(cwd, @manifest_path)
    config = read_json!(cwd, @config_path)
    workflow = read_file!(cwd, @workflow_path)
    probes = live_probes(opts)

    workflow_integrity =
      Keyword.get_lazy(opts, :workflow_integrity, fn -> workflow_integrity_evidence(cwd) end)

    core = core_components(cwd, manifest, live?, probes)
    companions = companion_components(cwd, manifest, config, live?, probes)
    release_candidate = release_candidate(core, companions, live?, probes)

    checks =
      checks(manifest, workflow, core, companions, workflow_integrity) ++
        candidate_public_checks(release_candidate, live?)

    %{
      schema_version: @schema_version,
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      status: aggregate_status(checks),
      live_checked: live?,
      core: core,
      companions: companions,
      release_candidate: release_candidate,
      checks: checks
    }
  end

  @spec render(map()) :: String.t()
  def render(status) do
    lines = [
      "Crosswake release status",
      "",
      "status: #{status_label(status.status)}",
      "live checks: #{if(status.live_checked, do: "enabled", else: "disabled")}",
      "",
      "Core/native lockstep:"
    ]

    core_lines =
      Enum.map(status.core, fn component ->
        live = live_label(component)

        "- #{component.component}: manifest=#{component.manifest_version} configured=#{component.configured_version}#{live}"
      end)

    companion_lines =
      [
        "",
        "Companions:"
      ] ++
        Enum.map(status.companions, fn companion ->
          release_as =
            case companion.release_as do
              nil -> ""
              value -> " release-as pin=#{value}"
            end

          live = live_label(companion)

          "- #{companion.package}: manifest=#{companion.manifest_version} configured=#{companion.configured_version} requires_crosswake=#{companion.core_requirement}#{release_as}#{live}"
        end)

    check_lines =
      [
        "",
        "Checks:"
      ] ++ Enum.flat_map(status.checks, &render_check_line/1)

    candidate = status.release_candidate

    candidate_lines = [
      "",
      "Exact 0.2.1 candidate (read-only):",
      "- state: #{candidate.state}",
      "- next action: #{candidate.next_action}",
      "- linked coordinates: #{Enum.map_join(candidate.linked_coordinates, ", ", & &1.coordinate)}",
      "- independent companions: #{Enum.map_join(candidate.independent_companions, ", ", & &1.package)}",
      "- mirror baseline/public: #{candidate.mirror.baseline_ref} / #{candidate.mirror.public_ref}",
      "- credentials exercised: false; external state changed: false"
    ]

    live_lines =
      if status.live_checked do
        [
          "",
          "Live registry state:"
        ] ++ Enum.map(status.core ++ status.companions, &live_registry_line/1)
      else
        []
      end

    Enum.join(
      lines ++
        core_lines ++
        companion_lines ++
        candidate_lines ++ live_lines ++ check_lines ++ summary_block(status),
      "\n"
    ) <> "\n"
  end

  # D-17: appended to the END of render/1's assembled output, after every existing
  # section, so no existing rendered line moves. On a clean run this emits nothing.
  # When both a defect AND an unknown are present, BOTH blocks emit and the process
  # still exits 1 — a confirmed defect outranks an unknown, but nothing is masked
  # (D-13). Every status word here routes through status_label/1; no internal atom
  # is ever printed. No count here is a hardcoded integer literal — all are derived
  # from status.checks.
  defp summary_block(status) do
    total = length(status.checks)
    failing = Enum.filter(status.checks, &(&1.status == :error))
    unverifiable = Enum.filter(status.checks, &(&1.status == :unverifiable))

    fail_lines =
      if failing == [] do
        []
      else
        [
          "",
          "[crosswake] FAIL (exit 1): release status ran all #{total} checks and found #{length(failing)} blocking issues."
        ] ++
          Enum.map(failing, fn check -> "[crosswake]   - #{check.code}: #{check.message}" end) ++
          [
            "[crosswake] What to do next: fix the named issues above, then re-run `mix crosswake.release.status`."
          ]
      end

    unverifiable_lines =
      if unverifiable == [] do
        []
      else
        passed = total - length(failing) - length(unverifiable)

        passed_line =
          if failing == [] do
            ["[crosswake] The #{passed} checks that did run passed."]
          else
            []
          end

        [
          "",
          "[crosswake] UNVERIFIED (exit 3): #{length(unverifiable)} of #{total} checks could not run, so their result is unknown — not clean."
        ] ++
          Enum.map(unverifiable, fn check ->
            "[crosswake]   - #{check.code}: #{check.message}"
          end) ++
          passed_line ++
          [
            "[crosswake] What to do next: restore the missing prerequisite and re-run. Do not read exit 3 as a pass."
          ]
      end

    fail_lines ++ unverifiable_lines
  end

  # D-10: every check renders as exactly one line, except the always-emitted
  # release.workflow_integrity owner check when it is failing — that one gets an
  # indented, byte-for-byte, untruncated continuation line per failing entry so the
  # scanner's own sentence reaches the surface.
  defp render_check_line(check) do
    next_action =
      if check.status == :ok or is_nil(check.next_action) do
        ""
      else
        " next action: #{check.next_action}"
      end

    summary =
      "- #{status_label(check.status)} #{check.code}: #{check.message}#{next_action}"

    if check.code == "release.workflow_integrity" and check.status != :ok do
      detail_lines =
        check
        |> Map.get(:entries, [])
        |> Enum.map(fn %{id: id, detail: detail} -> "    #{id}: #{detail}" end)

      [summary | detail_lines]
    else
      [summary]
    end
  end

  defp release_candidate(_core, companions, live?, probes) do
    candidate_live = %{
      hex: maybe_hex_live("crosswake", @candidate_version, live?, probes),
      ios: maybe_ios_mirror_live(@candidate_version, live?, probes),
      android: maybe_maven_live(@candidate_version, live?, probes)
    }

    {state, next_action} = candidate_state(candidate_live, live?)
    baseline_ios = maybe_ios_mirror_live(@mirror_baseline_version, live?, probes)

    %{
      version: @candidate_version,
      state: state,
      next_action: next_action,
      linked_coordinates: [
        candidate_coordinate(
          "hex",
          "hex:crosswake@#{@candidate_version}",
          candidate_live.hex
        ),
        candidate_coordinate(
          "ios-core",
          "swiftpm:crosswake-shell-core-ios@#{@candidate_version}",
          candidate_live.ios
        ),
        candidate_coordinate(
          "android-core",
          "maven:io.github.sztheory:crosswake-shell-core-android:#{@candidate_version}",
          candidate_live.android
        )
      ],
      independent_companions:
        Enum.map(companions, fn companion ->
          %{
            package: companion.package,
            version: companion.version,
            core_requirement: companion.core_requirement,
            relationship: "independent"
          }
        end),
      mirror: %{
        baseline_ref: "refs/tags/v#{@mirror_baseline_version}",
        baseline_status: public_status(baseline_ios),
        public_ref: "refs/tags/v#{@candidate_version}",
        public_status: public_status(candidate_live.ios),
        write_authority: "NOT CHECKED"
      },
      credentials_exercised: false,
      external_state_changed: false
    }
  end

  defp candidate_coordinate(component, coordinate, live) do
    %{
      component: component,
      coordinate: coordinate,
      relationship: "linked",
      public_status: public_status(live)
    }
  end

  defp public_status(nil), do: "NOT CHECKED"
  defp public_status(%{status: status}), do: status |> to_string() |> String.upcase()

  defp candidate_state(_candidate_live, false) do
    {"BLOCKED",
     "run mix crosswake.release.status --live, then capture the exact candidate receipt"}
  end

  defp candidate_state(candidate_live, true) do
    statuses = candidate_live |> Map.values() |> Enum.map(& &1.status)
    ok_count = Enum.count(statuses, &(&1 == :ok))

    cond do
      :unavailable in statuses ->
        {"BLOCKED", "restore live probe access and rerun mix crosswake.release.status --live"}

      ok_count == length(statuses) ->
        {"COMPLETE", "no action required; preserve the exact public receipt"}

      ok_count > 0 ->
        {"PARTIAL", "recover only the missing linked coordinate from its exact approved ref"}

      true ->
        {"BLOCKED",
         "capture candidate-local proof and the trusted mirror rehearsal before approval"}
    end
  end

  defp candidate_public_checks(_candidate, false), do: []

  defp candidate_public_checks(candidate, true) do
    status = if candidate.state == "COMPLETE", do: :ok, else: :error

    [
      %{
        status: status,
        code: "release.candidate_public_truth",
        source: "live linked-coordinate probes",
        evidence:
          Enum.map(candidate.linked_coordinates, fn coordinate ->
            "#{coordinate.component}=#{coordinate.public_status}"
          end),
        next_action: if(status == :ok, do: nil, else: candidate.next_action),
        message:
          if(status == :ok,
            do: "all three linked 0.2.1 coordinates are public",
            else: "0.2.1 linked-coordinate state is #{candidate.state}"
          )
      }
    ]
  end

  defp core_components(cwd, manifest, live?, probes) do
    version = Map.fetch!(manifest, ".")

    [
      %{
        kind: "core",
        name: "crosswake",
        component: "hex",
        path: ".",
        manifest_version: version,
        configured_version: mix_version!(cwd, "mix.exs"),
        live: maybe_hex_live("crosswake", version, live?, probes)
      },
      %{
        kind: "native",
        name: "ios-core",
        component: "ios-core",
        path: "packages/crosswake-shell-core-ios",
        manifest_version: Map.fetch!(manifest, "packages/crosswake-shell-core-ios"),
        configured_version: version,
        live: maybe_ios_mirror_live(version, live?, probes)
      },
      %{
        kind: "native",
        name: "android-core",
        component: "android-core",
        path: "packages/crosswake-shell-core-android",
        manifest_version: Map.fetch!(manifest, "packages/crosswake-shell-core-android"),
        configured_version: gradle_version!(cwd, @android_gradle_path),
        live: maybe_maven_live(version, live?, probes)
      }
    ]
  end

  defp companion_components(cwd, manifest, config, live?, probes) do
    manifest
    |> Map.keys()
    |> Enum.filter(&String.match?(&1, ~r/^packages\/crosswake_/))
    |> Enum.sort()
    |> Enum.map(fn path ->
      package = Path.basename(path)
      mix_path = Path.join(path, "mix.exs")
      version = Map.fetch!(manifest, path)

      %{
        kind: companion_kind(package),
        name: package,
        package: package,
        path: path,
        manifest_version: version,
        version: version,
        configured_version: mix_version!(cwd, mix_path),
        core_requirement: crosswake_requirement!(cwd, mix_path),
        release_as: get_in(config, ["packages", path, "release-as"]),
        release_as_tag_exists:
          release_as_tag_exists?(cwd, package, get_in(config, ["packages", path, "release-as"])),
        live: maybe_hex_live(package, version, live?, probes)
      }
    end)
  end

  defp companion_kind("crosswake_threadline"), do: "observer"
  defp companion_kind(_package), do: "companion"

  defp checks(manifest, workflow, core, companions, workflow_integrity) do
    jobs = job_blocks(workflow)

    base_checks = [
      check(
        :ok,
        "release.lockstep_manifest",
        "core/native manifest versions are #{Map.fetch!(manifest, ".")}",
        Enum.all?(core, &(&1.manifest_version == Map.fetch!(manifest, "."))),
        "core/native manifest versions must match",
        source: @manifest_path,
        evidence: Enum.map(core, &"#{&1.component}=#{&1.manifest_version}"),
        next_action: "inspect #{@manifest_path}"
      ),
      check(
        :ok,
        "release.lockstep_config",
        "core/native configured versions match manifest",
        Enum.all?(core, &(&1.configured_version == &1.manifest_version)),
        "configured root/native versions drift from manifest",
        source: "mix.exs and #{@android_gradle_path}",
        evidence: Enum.map(core, &"#{&1.component}=#{&1.configured_version}"),
        next_action: "reconcile configured version values with #{@manifest_path}"
      ),
      scanner_check(
        :ok,
        "release.workflow_path_gates",
        "root/native publish jobs use exact paths_released gates",
        "root/native publish jobs are not exact path-gated",
        workflow_integrity,
        @workflow_path_gate_ids,
        workflow =~ "paths_released:" and core_path_gates?(jobs)
      ),
      workflow_integrity_owner_check(workflow_integrity)
    ]

    proof_checks = [
      scanner_check(
        :ok,
        "release.cleanroom_dependency_floor",
        "clean-room proof uses Hex metadata floors and exact companion pins",
        "clean-room proof evidence is missing or stale",
        workflow_integrity,
        @cleanroom_evidence_ids
      )
    ]

    base_checks ++
      local_governance_checks(workflow, workflow_integrity) ++
      proof_checks ++ live_registry_checks(core, companions) ++ release_as_checks(companions)
  end

  defp local_governance_checks(workflow, workflow_integrity) do
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    [
      scanner_check(
        :ok,
        "release.governance_queue_max",
        "release workflow uses only supported concurrency keys and does not cancel in-progress runs",
        "release workflow must preserve pending release runs",
        workflow_integrity,
        @governance_queue_ids,
        governance_queue_max?(non_comment_workflow)
      ),
      scanner_check(
        :ok,
        "release.governance_behavioral_identity_gates",
        "behavioral release jobs use exact path/component gates",
        "behavioral release jobs must use exact release identity gates",
        workflow_integrity,
        @behavioral_identity_ids ++ component_gate_ids() ++ component_proof_ids(),
        behavioral_identity_gates?(jobs)
      ),
      scanner_check(
        :ok,
        "release.governance_cleanup_after_proof",
        "release-as cleanup waits for released companion publish and proof success",
        "release-as cleanup must wait for companion publish and proof success",
        workflow_integrity,
        @cleanup_evidence_ids,
        cleanup_after_proof?(jobs)
      )
    ]
  end

  defp governance_queue_max?(workflow) do
    not includes?(workflow, ~r/^\s*queue:\s*/m) and
      includes?(workflow, ~r/^\s*cancel-in-progress:\s*false\s*$/m) and
      not includes?(workflow, ~r/^\s*cancel-in-progress:\s*true\s*$/m)
  end

  defp behavioral_identity_gates?(jobs) do
    core_path_gates?(jobs) and component_publish_gates?(jobs) and
      component_proof_jobs_after_publish?(jobs) and
      behavioral_jobs_avoid_aggregate?(jobs)
  end

  defp core_path_gates?(jobs) do
    Enum.all?(@core_path_gates, fn {job, path} ->
      includes?(
        job_if(jobs, job),
        "contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}')"
      )
    end)
  end

  defp component_publish_gates?(jobs) do
    Enum.all?(@release_components, fn component ->
      job_if(jobs, "publish-hex-#{component}") == component_gate_expression(component)
    end)
  end

  defp behavioral_jobs_avoid_aggregate?(jobs) do
    Enum.all?(jobs, fn {job, _block} ->
      not behavioral_job?(job) or
        not includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
    end)
  end

  defp behavioral_job?(job) do
    String.starts_with?(job, "publish-") or
      String.starts_with?(job, "clean-room-proof-") or
      job == "release-as-cleanup"
  end

  defp cleanup_after_proof?(jobs) do
    condition = job_if(jobs, "release-as-cleanup")

    job_needs?(jobs, "release-as-cleanup", "release-please") and
      includes?(condition, "always()") and
      Enum.all?(@release_components, fn component ->
        job_needs?(jobs, "release-as-cleanup", "publish-hex-#{component}")
      end) and
      Enum.all?(@release_components, fn component ->
        job_needs?(jobs, "release-as-cleanup", "clean-room-proof-#{component}")
      end) and
      Enum.all?(@release_components, fn component ->
        includes?(
          condition,
          "needs.release-please.outputs.#{component}_release_created != 'true'"
        ) and
          includes?(condition, "needs.publish-hex-#{component}.result == 'success'") and
          includes?(condition, "needs.clean-room-proof-#{component}.result == 'success'")
      end) and
      component_proof_jobs_after_publish?(jobs)
  end

  defp job_blocks(workflow) do
    workflow
    |> strip_full_line_comments()
    |> then(fn text ->
      Regex.scan(~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/, text,
        capture: :all_but_first
      )
    end)
    |> Map.new(fn [name, block] -> {name, block} end)
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

  defp component_gate_expression(component),
    do: "${{ needs.release-please.outputs.#{component}_release_created == 'true' }}"

  defp component_proof_jobs_after_publish?(jobs) do
    Enum.all?(@release_components, &component_proof_after_publish?(jobs, &1))
  end

  defp component_proof_after_publish?(jobs, component) do
    job = "clean-room-proof-#{component}"

    job_if(jobs, job) == component_gate_expression(component) and
      job_needs?(jobs, job, "release-please") and
      job_needs?(jobs, job, "publish-hex-#{component}") and
      not includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
  end

  defp component_gate_ids do
    Enum.map(@release_components, &"release.#{&1}.component_gate")
  end

  defp component_proof_ids do
    Enum.map(@release_components, &"release.#{&1}.proof_gate")
  end

  defp strip_full_line_comments(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp includes?(text, value) when is_binary(value), do: String.contains?(text, value)
  defp includes?(text, %Regex{} = regex), do: Regex.match?(regex, text)

  # D-18: two failure kinds, two codes, both fatal.
  #
  # `:missing` means the registry ANSWERED and the release is not there — a
  # definite negative. `:unavailable` means the probe itself never got an answer
  # after retries — an unknown. This used to lump both into one `:warning` under
  # one code, so `mix crosswake.release.status --live` exited 0 while every iOS
  # adopter's `.package(from: "0.2.0")` could not resolve. That is a support-truth
  # lie in the project's own voice, and it violates the fail-closed /
  # no-silent-fallback rule.
  #
  # Both now exit 1. But an unknown must never be reported as a confirmed
  # absence, so each check names ONLY its own sources.
  #
  # One carve-out, under `release.live_registry_bootstrap_pending`: a package
  # that has never been released cannot have a broken adopter promise. See
  # `bootstrap_pending?/1` below — it is advisory, still loudly named, and
  # narrow enough that anything actually released stays fatal.
  defp live_registry_checks(core, companions) do
    entries = Enum.filter(core ++ companions, & &1.live)

    if entries == [] do
      []
    else
      # The carve-out applies ONLY to `:missing` — a registry that answered "no
      # release here". An `:unavailable` probe never got an answer, so claiming
      # the registry "has nothing" would assert a definite negative from an
      # unknown: the same misreport this function exists to prevent. A
      # bootstrap-pending package with a failed probe stays `:unverifiable`.
      {bootstrap_pending, answered} =
        entries
        |> Enum.reject(&(&1.live.status == :ok))
        |> Enum.split_with(&(&1.live.status == :missing and bootstrap_pending?(&1)))

      missing = Enum.filter(answered, &(&1.live.status == :missing))
      unavailable = Enum.filter(answered, &(&1.live.status == :unavailable))

      bootstrap_check =
        if bootstrap_pending == [] do
          []
        else
          [
            %{
              status: :warning,
              code: "release.live_registry_bootstrap_pending",
              source: "live registry probes",
              evidence: Enum.map(bootstrap_pending, &live_evidence/1),
              next_action:
                "no action needed unless these should now ship; to publish, remove the release-as bootstrap pin in release-please-config.json and let the Release PR cut a real release",
              message:
                "live registry has nothing for packages that have never been released (release-as bootstrap pin still set, no release tag): #{Enum.map_join(bootstrap_pending, ", ", &live_missing_label/1)}"
            }
          ]
        end

      presence_check =
        if missing == [] do
          []
        else
          [
            %{
              status: :error,
              code: "release.live_registry_presence",
              source: "live registry probes",
              evidence: Enum.map(missing, &live_evidence/1),
              next_action:
                "review live registry state or rerun mix crosswake.release.status --live",
              message:
                "live registry probes found no release for: #{Enum.map_join(missing, ", ", &live_missing_label/1)}"
            }
          ]
        end

      unverifiable_check =
        if unavailable == [] do
          []
        else
          [
            %{
              status: :error,
              code: "release.live_registry_unverifiable",
              source: "live registry probes",
              evidence: Enum.map(unavailable, &live_evidence/1),
              next_action:
                "the live probe failed after retries; rerun mix crosswake.release.status --live once network access is confirmed",
              message:
                "live registry probes could not confirm presence (probe failure, not a confirmed absence) for: #{Enum.map_join(unavailable, ", ", &live_missing_label/1)}"
            }
          ]
        end

      ok_check =
        if missing == [] and unavailable == [] do
          [
            %{
              status: :ok,
              code: "release.live_registry_presence",
              source: "live registry probes",
              evidence:
                entries |> Enum.filter(&(&1.live.status == :ok)) |> Enum.map(&live_evidence/1),
              next_action: nil,
              message: "all live registry probes found manifest versions"
            }
          ]
        else
          []
        end

      presence_check ++ unverifiable_check ++ ok_check ++ bootstrap_check
    end
  end

  # A companion still carrying its ONE-SHOT release-as bootstrap pin, with no
  # matching `{package}-v{version}` release tag, has never been published. Its
  # manifest version is a pre-release baseline, not a shipped version — so the
  # registry correctly has nothing there and no adopter was ever promised it.
  #
  # Treating that as a blocking error would make the release-truth command
  # permanently red for a non-problem, which is precisely the ignorable red this
  # phase exists to eliminate. It is also the exact manifest-baseline false
  # positive that check_release_as_staleness.sh already documents, and the same
  # trap D-16's parity gate avoids by keying on RELEASED git tags rather than on
  # the release-please manifest.
  #
  # The released-tag signal is authoritative in BOTH directions: anything this
  # repo actually released stays fatal when a registry cannot produce it. Core
  # and native components carry no release-as pin, so they are never exempt —
  # a missing iOS mirror tag is always an error.
  defp bootstrap_pending?(%{
         release_as: release_as,
         release_as_tag_exists: false,
         manifest_version: version
       })
       when is_binary(release_as),
       do: release_as == version

  defp bootstrap_pending?(_entry), do: false

  defp live_missing_label(%{component: component, manifest_version: version, live: live}),
    do: "#{component}@#{version} #{live.status} on #{live.source}"

  defp live_missing_label(%{package: package, version: version, live: live}),
    do: "#{package}@#{version} #{live.status} on #{live.source}"

  defp live_evidence(%{component: component, manifest_version: version, live: live}),
    do: "#{component}@#{version}=#{live.status}"

  defp live_evidence(%{package: package, manifest_version: version, live: live}),
    do: "#{package}@#{version}=#{live.status}"

  defp release_as_checks(companions) do
    stale =
      Enum.filter(companions, fn companion ->
        companion.release_as && companion.release_as_tag_exists
      end)

    [
      %{
        status: if(stale == [], do: :ok, else: :error),
        code: "release.release_as_staleness",
        source: "release-please-config.json",
        evidence:
          Enum.map(companions, fn companion ->
            "#{companion.package}:release-as=#{companion.release_as || "none"}"
          end),
        next_action:
          if(stale == [],
            do: nil,
            else: "remove stale release-as pins from release-please-config.json"
          ),
        message:
          if stale == [] do
            "no release-as pin points at an existing local release tag"
          else
            packages = Enum.map_join(stale, ", ", & &1.package)
            "stale release-as pin detected for #{packages}"
          end
      }
    ]
  end

  defp check(status_when_ok, code, ok_message, condition, error_message, opts) do
    status = if condition, do: status_when_ok, else: :error

    %{
      status: status,
      code: code,
      message: if(condition, do: ok_message, else: error_message),
      next_action: if(status == :ok, do: nil, else: Keyword.fetch!(opts, :next_action)),
      source: Keyword.fetch!(opts, :source)
    }
    |> maybe_put(:evidence, Keyword.get(opts, :evidence))
  end

  defp scanner_check(
         status_when_ok,
         code,
         ok_message,
         error_message,
         workflow_integrity,
         required_ids,
         local_ok? \\ true
       ) do
    {scanner_status, evidence, scanner_message, cause} =
      scanner_ids_result(workflow_integrity, required_ids)

    ok? = local_ok? and scanner_status == :ok

    # D-08: under either crash shape the scanner could not evaluate this check's own
    # gates. That verdict is unconditional — a scoped check never reports :ok, and
    # never a status that maps to exit 0, regardless of what `local_ok?` says about
    # code this process already read independently of the scanner.
    status =
      cond do
        scanner_status == :unverifiable -> :unverifiable
        ok? -> status_when_ok
        true -> :error
      end

    message =
      cond do
        status == :unverifiable -> scanner_message
        ok? -> ok_message
        true -> "#{error_message}: #{scanner_message}"
      end

    %{
      status: status,
      code: code,
      message: message,
      next_action: if(ok?, do: nil, else: @workflow_integrity_command),
      source: @workflow_integrity_source,
      evidence: evidence
    }
    |> maybe_put(:cause, cause)
  end

  # D-06/D-08: the single always-emitted owner check over the FULL parsed scanner
  # set — not scoped to any caller's required_ids. This is the one place a failing
  # scanner check's own verbatim `detail` reaches the surface, at a stable owning
  # code, regardless of whether any of the five scanner_check/7 call sites happen
  # to require that ID.
  #
  # Both crash shapes route here to the SAME :unverifiable status. If this owner
  # check reported :error instead, aggregate_status/1's :error > :unverifiable
  # precedence would force exit 1 on a crash — silently downgrading "could not
  # verify" into "found a defect", the opposite of what exit 3 exists to say.
  defp workflow_integrity_owner_check(%{status: status, message: message})
       when status in [:unavailable, :unverifiable] do
    %{
      status: :unverifiable,
      code: "release.workflow_integrity",
      message: message,
      next_action: @workflow_integrity_command,
      source: @workflow_integrity_source,
      evidence: [],
      entries: []
    }
  end

  defp workflow_integrity_owner_check(%{checks: checks}) do
    failing =
      checks
      |> Enum.filter(fn {_id, check} -> match?(%{status: :error}, check) end)
      |> Enum.sort_by(fn {_id, check} -> Map.get(check, :order, 0) end)

    case failing do
      [] ->
        %{
          status: :ok,
          code: "release.workflow_integrity",
          message: "release workflow integrity scanner reported no failing checks",
          next_action: nil,
          source: @workflow_integrity_source,
          evidence: [],
          entries: []
        }

      _ ->
        entries = Enum.map(failing, fn {id, check} -> %{id: id, detail: check.detail} end)

        message =
          Enum.map_join(entries, "; ", fn %{id: id, detail: detail} -> "#{id}: #{detail}" end)

        %{
          status: :error,
          code: "release.workflow_integrity",
          message: message,
          next_action: @workflow_integrity_command,
          source: @workflow_integrity_source,
          evidence: Enum.map(entries, & &1.id),
          entries: entries
        }
    end
  end

  # D-08: under EITHER crash shape (:unavailable — the scanner never started; or
  # :unverifiable — the scanner started and terminated early) this call site's own
  # gates genuinely could not be evaluated. The cascade pointer names the cause —
  # the last emitted FAIL line when one exists, otherwise the raw exit code — so a
  # maintainer reading a scoped check's message sees WHY it could not evaluate, not
  # just THAT it could not. This clause returns :unverifiable unconditionally;
  # scanner_check/7 maps it straight through regardless of local_ok?.
  defp scanner_ids_result(%{status: status} = evidence, _required_ids)
       when status in [:unavailable, :unverifiable] do
    cause = unverifiable_cause(evidence)

    message =
      "not evaluated — the scanner stopped before these gates ran (cause: #{cause}). This is not a pass."

    {:unverifiable, [], message, cause}
  end

  # D-07/D-09: `failing` is scoped to THIS call site's own `required_ids` — exactly
  # like the catch-all sibling below — so a foreign check failing elsewhere in the
  # scanner's full parsed set does not bleed into unrelated checks. It is safe
  # precisely because the verified ground truth (169-CONTEXT.md) establishes the
  # scanner evaluates eagerly and every check emits, so a scoped green here is a
  # real green; the always-emitted `release.workflow_integrity` owner check
  # (workflow_integrity_owner_check/1) is the one place the full unscoped failure
  # set surfaces. `failing` is ordered by the scanner's own emission `order:`, not
  # alphabetically. Both non-empty buckets compose into one message, failing named
  # first, so neither shadows the other.
  defp scanner_ids_result(%{status: :failed, checks: checks} = evidence, required_ids) do
    missing = Enum.reject(required_ids, &Map.has_key?(checks, &1))

    failing =
      required_ids
      |> Enum.filter(fn id -> match?(%{status: :error}, Map.get(checks, id)) end)
      |> Enum.sort_by(fn id -> Map.get(checks, id) |> Map.get(:order, 0) end)

    if missing == [] and failing == [] do
      # D-07: this call site's own required_ids are all present and all passed —
      # under a complete run, a foreign failure elsewhere does not make this scoped
      # check lie about its own scope. The unscoped failure still surfaces via the
      # always-emitted release.workflow_integrity owner check.
      {:ok, required_ids, "all scanner IDs passed", nil}
    else
      evidence_ids = Enum.uniq(failing ++ missing)

      segments =
        [failing_segment(failing, checks), missing_segment(missing, evidence)]
        |> Enum.reject(&is_nil/1)

      message =
        case segments do
          [] -> "scanner exited nonzero without parseable failing IDs"
          _ -> Enum.join(segments, "; ")
        end

      {:error, evidence_ids, message, nil}
    end
  end

  defp scanner_ids_result(%{checks: checks}, required_ids) do
    missing = Enum.reject(required_ids, &Map.has_key?(checks, &1))

    failing =
      required_ids
      |> Enum.filter(fn id -> match?(%{status: :error}, Map.get(checks, id)) end)

    cond do
      missing == [] and failing == [] ->
        {:ok, required_ids, "all scanner IDs passed", nil}

      missing != [] ->
        {:error, missing ++ failing, "missing scanner IDs: #{Enum.join(missing, ", ")}", nil}

      true ->
        {:error, failing, "failing scanner IDs: #{Enum.join(failing, ", ")}", nil}
    end
  end

  # D-08: the cause names WHY the scanner stopped — the last emitted FAIL line's ID
  # when one exists (the scanner was already reporting a real defect when it died),
  # otherwise the raw exit code as `scanner exit <n>`.
  defp unverifiable_cause(%{checks: checks} = evidence) when map_size(checks) > 0 do
    case Enum.filter(checks, fn {_id, check} -> match?(%{status: :error}, check) end) do
      [] ->
        "scanner exit #{Map.get(evidence, :exit_code, "?")}"

      failing ->
        {id, _check} = Enum.max_by(failing, fn {_id, check} -> Map.get(check, :order, 0) end)
        id
    end
  end

  defp unverifiable_cause(evidence), do: "scanner exit #{Map.get(evidence, :exit_code, "?")}"

  # D-13: nothing verified is never scored as clean. An empty checks list means
  # `build/1` produced no checks at all — that is not the same thing as every
  # check passing, so it must not fall through to `:ok`.
  def aggregate_status([]), do: :unverifiable

  # Precedence is total and deterministic: :error > :unverifiable > :warning > :ok.
  # A confirmed defect always outranks an unknown, and an unknown always outranks
  # a mere warning — permuting the input list never changes the result.
  def aggregate_status(checks) do
    cond do
      Enum.any?(checks, &(&1.status == :error)) -> :error
      Enum.any?(checks, &(&1.status == :unverifiable)) -> :unverifiable
      Enum.any?(checks, &(&1.status == :warning)) -> :warning
      true -> :ok
    end
  end

  @doc """
  Exit-code contract for `mix crosswake.release.status` and the release workflow
  scanner (`script/check_release_workflow_integrity.exs`).

  | Code | Meaning |
  |------|---------|
  | `0` | clean — every check ran and passed (`:ok` or `:warning`) |
  | `1` | ran and found a defect (`:error`) |
  | `3` | could not verify — one or more checks could not run (`:unverifiable`) |

  `2` is deliberately reserved to its existing meanings elsewhere in this repo
  (defect-found in `script/verify_generated_ios_shell.sh`, usage error in
  `script/check_required_checks_registered.sh`, shells-behind in
  `lib/mix/tasks/crosswake.shell.status.ex`) and is never returned here.
  `:warning` maps to `0`.
  """
  @spec exit_code(atom() | map()) :: 0 | 1 | 3
  def exit_code(:error), do: 1
  def exit_code(:unverifiable), do: 3
  def exit_code(%{status: status}), do: exit_code(status)
  def exit_code(_status), do: 0

  # D-16/D-17: the internal atom must never reach the maintainer as a bare word —
  # the human-facing verb is "UNVERIFIED". Every other status keeps its existing
  # rendering.
  defp status_label(:unverifiable), do: "UNVERIFIED"
  defp status_label(status), do: status |> to_string() |> String.upcase()

  defp live_label(%{live: nil}), do: ""
  defp live_label(%{live: %{status: status, source: source}}), do: " live_#{source}=#{status}"

  defp live_registry_line(%{component: component, manifest_version: version, live: live}) do
    "- #{component}: manifest version=#{version} #{live_registry_state(live)}"
  end

  defp live_registry_line(%{package: package, manifest_version: version, live: live}) do
    "- #{package}: manifest version=#{version} #{live_registry_state(live)}"
  end

  defp live_registry_state(nil), do: "live registry state=not checked"

  defp live_registry_state(%{status: status, source: source}) do
    "live registry state=#{status} source=#{source}"
  end

  defp workflow_integrity_evidence(cwd) do
    case System.cmd("elixir", [@workflow_integrity_source], cd: cwd, stderr_to_stdout: true) do
      {output, exit_code} -> classify_workflow_integrity_output(output, exit_code)
    end
  rescue
    error -> classify_workflow_integrity_output(Exception.message(error), 1)
  end

  # D-03: three (of four) states the scanner run can be in, discriminated by
  # 169-01's ROSTER/DONE lines:
  #
  #   1. No ROSTER line observed at all (crash during setup, before the check list
  #      is even built, or a raise in this function's own System.cmd/rescue path
  #      with no scanner output whatsoever) -> :unavailable. The scanner never
  #      started.
  #   2. ROSTER observed but DONE is absent, or fewer OK/FAIL lines emitted than
  #      the roster declares -> :unverifiable. The scanner started and then
  #      terminated early. DONE is the POSITIVE completeness assertion (D-02) —
  #      its absence is not evidence of completion, even when every roster line
  #      that DID print looks clean.
  #   3/4. Complete run (ROSTER + DONE + full emission count) -> :ok on exit 0,
  #      :failed on nonzero exit. Unchanged from pre-Phase-169 behavior.
  defp classify_workflow_integrity_output(output, exit_code) do
    checks = parse_workflow_integrity_output(output)
    roster_size = parse_roster_size(output)
    emitted_count = map_size(checks)

    cond do
      is_nil(roster_size) ->
        %{
          status: :unavailable,
          checks: %{},
          message:
            "scanner did not start: no roster line emitted (exit #{exit_code}). stderr: #{bounded_stderr_excerpt(output)}",
          roster_size: nil,
          exit_code: exit_code
        }

      not done_line_present?(output) or emitted_count < roster_size ->
        %{
          status: :unverifiable,
          checks: checks,
          message:
            "scanner terminated early: #{emitted_count} of #{roster_size} roster checks ran (exit #{exit_code}). stderr: #{bounded_stderr_excerpt(output)}",
          roster_size: roster_size,
          exit_code: exit_code
        }

      exit_code == 0 ->
        %{
          status: :ok,
          checks: checks,
          message: "scanner passed",
          roster_size: roster_size,
          exit_code: exit_code
        }

      true ->
        %{
          status: :failed,
          checks: checks,
          message: "scanner reported release workflow drift",
          roster_size: roster_size,
          exit_code: exit_code
        }
    end
  end

  # D-02: the ROSTER line's count is the denominator that makes "never defined"
  # (an ID absent from the scanner's declared roster) legible with a number, rather
  # than a bare unexplained absence. `nil` when no ROSTER line was observed at all
  # (e.g. a hand-built fixture map, or a crash before the roster line prints).
  defp parse_roster_size(output) do
    case Regex.run(~r/^\[crosswake\] ROSTER: (\d+) /m, output, capture: :all_but_first) do
      [count] -> String.to_integer(count)
      _ -> nil
    end
  end

  defp done_line_present?(output), do: output =~ ~r/^\[crosswake\] DONE: /m

  # T-169-04: bound the stderr excerpt embedded in a crash message to a fixed
  # maximum so an unbounded crash payload can never carry arbitrary environment
  # text into a rendered maintainer-facing report. This bound applies ONLY to
  # this excerpt — never to a check's `detail`, which D-10 forbids truncating.
  @stderr_excerpt_limit 500
  @stderr_excerpt_truncation_marker "…(truncated)… "

  defp bounded_stderr_excerpt(output) do
    trimmed = String.trim(output)

    if String.length(trimmed) > @stderr_excerpt_limit do
      @stderr_excerpt_truncation_marker <>
        String.slice(trimmed, -@stderr_excerpt_limit, @stderr_excerpt_limit)
    else
      trimmed
    end
  end

  # D-09: one composed segment per non-empty bucket, failing named first. Each
  # failing entry carries its ID and its verbatim `detail` — never a bare ID.
  defp failing_segment([], _checks), do: nil

  defp failing_segment(failing, checks) do
    details =
      Enum.map_join(failing, ", ", fn id -> "#{id}: #{Map.get(checks, id).detail}" end)

    "#{length(failing)} failing (#{details})"
  end

  # D-03: a missing required ID is explained, not presented as an unexplained new
  # problem — literal never-defined wording naming the roster size and the drift
  # pointer back to the scanner source.
  defp missing_segment([], _evidence), do: nil

  defp missing_segment(missing, evidence) do
    roster_size = Map.get(evidence, :roster_size)
    details = Enum.map_join(missing, ", ", &never_defined_detail(&1, roster_size))

    "#{length(missing)} never defined (#{details})"
  end

  defp never_defined_detail(id, nil) do
    "never defined by scanner: #{id} — not in the scanner's roster; the required-ID list in Crosswake.ReleaseStatus has drifted from #{@workflow_integrity_source}"
  end

  defp never_defined_detail(id, roster_size) do
    "never defined by scanner: #{id} — not in the scanner's #{roster_size}-check roster; the required-ID list in Crosswake.ReleaseStatus has drifted from #{@workflow_integrity_source}"
  end

  defp parse_workflow_integrity_output(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/, line,
             capture: :all_but_first
           ) do
        [status, id, detail] ->
          [{id, %{status: scanner_status(status), detail: detail}}]

        _ ->
          []
      end
    end)
    |> Enum.with_index()
    |> Enum.map(fn {{id, check}, index} -> {id, Map.put(check, :order, index)} end)
    |> Map.new()
  end

  defp scanner_status("OK"), do: :ok
  defp scanner_status("FAIL"), do: :error

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp normalize_live_result(result, base) when is_boolean(result) do
    normalize_live_result(if(result, do: :ok, else: :missing), base)
  end

  defp normalize_live_result(status, base) when status in [:ok, :missing, :unavailable] do
    Map.merge(base, %{status: status})
  end

  defp normalize_live_result(%{} = result, base) do
    result =
      result
      |> atomize_live_keys()
      |> Map.update(:status, :unavailable, &normalize_live_status/1)

    Map.merge(base, result)
  end

  defp normalize_live_result(_result, base), do: Map.merge(base, %{status: :unavailable})

  defp normalize_live_status(status) when status in [:ok, :missing, :unavailable], do: status
  defp normalize_live_status("ok"), do: :ok
  defp normalize_live_status("missing"), do: :missing
  defp normalize_live_status("unavailable"), do: :unavailable
  defp normalize_live_status(_status), do: :unavailable

  defp atomize_live_keys(result) do
    Map.new(result, fn
      {key, value} when is_binary(key) -> {String.to_existing_atom(key), value}
      pair -> pair
    end)
  end

  defp mix_version!(cwd, path) do
    cwd
    |> read_file!(path)
    |> first_capture!(~r/@version\s+"([^"]+)"/, path)
  end

  defp gradle_version!(cwd, path) do
    cwd
    |> read_file!(path)
    |> first_capture!(~r/version\s*=\s*"([^"]+)"/, path)
  end

  defp crosswake_requirement!(cwd, path) do
    cwd
    |> read_file!(path)
    |> first_capture!(~r/do:\s*\{:crosswake,\s*"([^"]+)"\}/, path)
  end

  defp release_as_tag_exists?(_cwd, _package, nil), do: false

  defp release_as_tag_exists?(cwd, package, version) do
    tag = "#{package}-v#{version}"

    case System.cmd("git", ["-C", cwd, "tag", "--list", tag], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output) == tag
      _ -> false
    end
  end

  defp maybe_hex_live(_package, _version, false, _probes), do: nil

  defp maybe_hex_live(package, version, true, probes) do
    url = "https://hex.pm/api/packages/#{package}/releases/#{version}"

    probes.http
    |> call_probe([url, %{kind: :hex, package: package, version: version}])
    |> normalize_live_result(%{
      source: "hex",
      checked: true,
      url: url,
      next_action: "verify #{package} #{version} on Hex.pm or rerun release publish proof"
    })
  end

  defp maybe_ios_mirror_live(_version, false, _probes), do: nil

  defp maybe_ios_mirror_live(version, true, probes) do
    ref = "refs/tags/v#{version}"

    probes.git_ref
    |> call_probe([@ios_mirror_url, ref])
    |> normalize_live_result(%{
      source: "ios_mirror",
      checked: true,
      remote: @ios_mirror_url,
      ref: ref,
      next_action:
        "run script/verify_ios_mirror_backfill.sh --version #{version} --ref refs/tags/ios-core-v#{version}"
    })
  end

  defp maybe_maven_live(_version, false, _probes), do: nil

  defp maybe_maven_live(version, true, probes) do
    url =
      "https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/#{version}/crosswake-shell-core-android-#{version}.pom"

    probes.http
    |> call_probe([url, %{kind: :maven, version: version}])
    |> normalize_live_result(%{
      source: "maven",
      checked: true,
      url: url,
      next_action: "verify Android Maven Central publication for #{version}"
    })
  end

  defp live_probes(opts) do
    %{
      http: Keyword.get(opts, :http_probe, &http_live_probe/2),
      git_ref: Keyword.get(opts, :git_ref_probe, &git_ref_live_probe/2)
    }
  end

  defp call_probe(fun, args) do
    {:arity, arity} = Function.info(fun, :arity)
    apply(fun, Enum.take(args, arity))
  end

  @doc """
  Runs a live probe up to `attempts` times, returning the first REAL answer.

  A real answer is anything other than `:unavailable` — `:ok` and `:missing` are
  both definite results from the registry, so the first one short-circuits
  immediately. Only when every attempt fails to get an answer is the result
  classified `:unavailable`.

  This is what makes the `release.live_registry_presence` /
  `release.live_registry_unverifiable` split honest: an `:unavailable` that
  survived three attempts is a real unknown, not a single network hiccup
  misreported as a missing release.

  It lives on the REAL probes (`git_ref_live_probe/2`, `http_live_probe/2`), not
  between `build/1` and the `http_probe:`/`git_ref_probe:` injection seam — a
  fixture-driven test must not retry its own fakes three times.
  """
  @spec probe_with_retry((-> map()), pos_integer(), non_neg_integer()) :: map()
  def probe_with_retry(fun, attempts \\ @probe_attempts, sleep_ms \\ @probe_retry_sleep_ms)

  def probe_with_retry(fun, attempts, sleep_ms) when attempts > 1 do
    case fun.() do
      %{status: :unavailable} ->
        if sleep_ms > 0, do: Process.sleep(sleep_ms)
        probe_with_retry(fun, attempts - 1, sleep_ms)

      result ->
        result
    end
  end

  def probe_with_retry(fun, _attempts, _sleep_ms), do: fun.()

  defp git_ref_live_probe(remote_url, ref) do
    probe_with_retry(fn -> git_ref_live_probe_once(remote_url, ref) end)
  end

  defp git_ref_live_probe_once(remote_url, ref) do
    with git when is_binary(git) <- System.find_executable("git") do
      case System.cmd(git, ["-c", "core.askPass=", "ls-remote", "--tags", remote_url, ref],
             env: [{"GIT_TERMINAL_PROMPT", "0"}],
             stderr_to_stdout: true
           ) do
        {output, 0} ->
          if String.contains?(output, ref) do
            %{status: :ok, evidence: ["ref=#{ref}"]}
          else
            %{status: :missing, evidence: ["ref=#{ref}"]}
          end

        {output, _} ->
          %{status: :unavailable, evidence: [concise_probe_error(output)]}
      end
    else
      _ -> %{status: :unavailable, evidence: ["git executable unavailable"]}
    end
  rescue
    error -> %{status: :unavailable, evidence: [Exception.message(error)]}
  end

  defp http_live_probe(url, context) do
    probe_with_retry(fn -> http_live_probe_once(url, context) end)
  end

  defp http_live_probe_once(url, context) do
    with curl when is_binary(curl) <- System.find_executable("curl"),
         {output, 0} <-
           System.cmd(
             curl,
             [
               "--silent",
               "--show-error",
               "--location",
               "--max-time",
               "5",
               "--write-out",
               "\n%{http_code}",
               url
             ],
             stderr_to_stdout: true
           ) do
      {body, code} = split_http_output(output)
      http_status_result(code, body, context)
    else
      {output, _exit_code} -> %{status: :unavailable, evidence: [concise_probe_error(output)]}
      _ -> %{status: :unavailable, evidence: ["curl executable unavailable"]}
    end
  rescue
    error -> %{status: :unavailable, evidence: [Exception.message(error)]}
  end

  defp split_http_output(output) do
    lines = String.split(output, "\n", trim: false)
    {status_lines, [code]} = Enum.split(lines, -1)
    {Enum.join(status_lines, "\n"), String.trim(code)}
  end

  defp http_status_result("200", body, %{kind: :hex, version: version}) do
    case Jason.decode(body) do
      {:ok, %{"version" => ^version} = release} ->
        if Map.get(release, "retirement") in [nil, false] do
          %{status: :ok, evidence: ["version=#{version}"]}
        else
          %{status: :unavailable, evidence: ["hex release is retired"]}
        end

      {:ok, _payload} ->
        %{status: :unavailable, evidence: ["hex payload version mismatch"]}

      {:error, _} ->
        %{status: :unavailable, evidence: ["hex payload malformed"]}
    end
  end

  defp http_status_result("200", _body, %{kind: :maven, version: version}) do
    %{status: :ok, evidence: ["version=#{version}"]}
  end

  defp http_status_result("404", _body, _context), do: %{status: :missing, evidence: ["http=404"]}

  defp http_status_result(code, _body, _context) do
    %{status: :unavailable, evidence: ["http=#{code}"]}
  end

  defp concise_probe_error(output) do
    output
    |> String.split("\n", trim: true)
    |> List.first()
    |> case do
      nil -> "probe failed"
      line -> String.slice(line, 0, 160)
    end
  end

  defp read_json!(cwd, path), do: cwd |> read_file!(path) |> Jason.decode!()

  defp read_file!(cwd, path), do: File.read!(Path.expand(path, cwd))

  defp first_capture!(contents, regex, path) do
    case Regex.run(regex, contents, capture: :all_but_first) do
      [value] -> value
      _ -> raise ArgumentError, "could not extract release version from #{path}"
    end
  end
end
