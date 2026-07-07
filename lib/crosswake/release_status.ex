defmodule Crosswake.ReleaseStatus do
  @moduledoc """
  Reads Crosswake's release graph and reports local package-family release readiness.

  This is intentionally repository-local by default. Pass `live?: true` to add best-effort
  public registry probes for Hex, Maven Central, and the iOS SwiftPM mirror.
  """

  @schema_version "1.0.0"
  @manifest_path ".release-please-manifest.json"
  @config_path "release-please-config.json"
  @workflow_path ".github/workflows/release-please.yml"
  @android_gradle_path "packages/crosswake-shell-core-android/build.gradle.kts"
  @ios_mirror_url "https://github.com/szTheory/crosswake-shell-core-ios.git"
  @workflow_integrity_command "elixir script/check_release_workflow_integrity.exs"
  @core_path_gates [
    {"publish-hex", "."},
    {"publish-ios-core", "packages/crosswake-shell-core-ios"},
    {"publish-android-core", "packages/crosswake-shell-core-android"}
  ]
  @release_components ~w(rulestead rindle sigra chimeway threadline)

  @spec build(keyword()) :: map()
  def build(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    live? = Keyword.get(opts, :live?, false)

    manifest = read_json!(cwd, @manifest_path)
    config = read_json!(cwd, @config_path)
    workflow = read_file!(cwd, @workflow_path)
    probes = live_probes(opts)

    core = core_components(cwd, manifest, live?, probes)
    companions = companion_components(cwd, manifest, config, live?, probes)
    checks = checks(cwd, manifest, config, workflow, core, companions)

    %{
      schema_version: @schema_version,
      generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      status: aggregate_status(checks),
      live_checked: live?,
      core: core,
      companions: companions,
      checks: checks
    }
  end

  @spec render(map()) :: String.t()
  def render(status) do
    lines = [
      "Crosswake release status",
      "",
      "status: #{status.status}",
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
              value -> " release-as=#{value}"
            end

          live = live_label(companion)

          "- #{companion.package}: version=#{companion.version} requires_crosswake=#{companion.core_requirement}#{release_as}#{live}"
        end)

    check_lines =
      [
        "",
        "Checks:"
      ] ++
        Enum.map(status.checks, fn check ->
          "- #{String.upcase(to_string(check.status))} #{check.code}: #{check.message}"
        end)

    Enum.join(lines ++ core_lines ++ companion_lines ++ check_lines, "\n") <> "\n"
  end

  defp core_components(cwd, manifest, live?, probes) do
    version = Map.fetch!(manifest, ".")

    [
      %{
        component: "hex",
        path: ".",
        manifest_version: version,
        configured_version: mix_version!(cwd, "mix.exs"),
        live: maybe_hex_live("crosswake", version, live?, probes)
      },
      %{
        component: "ios-core",
        path: "packages/crosswake-shell-core-ios",
        manifest_version: Map.fetch!(manifest, "packages/crosswake-shell-core-ios"),
        configured_version: version,
        live: maybe_ios_mirror_live(version, live?, probes)
      },
      %{
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

      %{
        package: package,
        path: path,
        version: Map.fetch!(manifest, path),
        configured_version: mix_version!(cwd, mix_path),
        core_requirement: crosswake_requirement!(cwd, mix_path),
        release_as: get_in(config, ["packages", path, "release-as"]),
        release_as_tag_exists:
          release_as_tag_exists?(cwd, package, get_in(config, ["packages", path, "release-as"])),
        live: maybe_hex_live(package, Map.fetch!(manifest, path), live?, probes)
      }
    end)
  end

  defp checks(cwd, manifest, _config, workflow, core, companions) do
    base_checks = [
      check(
        :ok,
        "release.lockstep_manifest",
        "core/native manifest versions are #{Map.fetch!(manifest, ".")}",
        Enum.all?(core, &(&1.manifest_version == Map.fetch!(manifest, "."))),
        "core/native manifest versions must match"
      ),
      check(
        :ok,
        "release.lockstep_config",
        "core/native configured versions match manifest",
        Enum.all?(core, &(&1.configured_version == &1.manifest_version)),
        "configured root/native versions drift from manifest"
      ),
      check(
        :ok,
        "release.workflow_path_gates",
        "root/native publish jobs use paths_released gates",
        workflow =~ "paths_released:" and
          workflow =~ "contains(fromJSON(needs.release-please.outputs.paths_released), '.')",
        "root/native publish jobs are not path-gated"
      )
    ]

    proof_checks = [
      check(
        :ok,
        "release.cleanroom_dependency_floor",
        "clean-room harness derives package floors and exact companion version",
        cleanroom_script_hardened?(cwd),
        "clean-room harness still has stale hardcoded dependency requirements"
      )
    ]

    base_checks ++
      local_governance_checks(workflow) ++
      proof_checks ++ live_registry_checks(core, companions) ++ release_as_checks(companions)
  end

  defp local_governance_checks(workflow) do
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    [
      check(
        :ok,
        "release.governance_queue_max",
        "release workflow queues pending runs with queue: max and cancel-in-progress: false",
        governance_queue_max?(non_comment_workflow),
        "release workflow must set queue: max, cancel-in-progress: false, and avoid cancel-in-progress: true; next: #{@workflow_integrity_command}"
      ),
      check(
        :ok,
        "release.governance_behavioral_identity_gates",
        "behavioral release jobs use exact path/component gates",
        behavioral_identity_gates?(jobs),
        "behavioral release jobs must use exact paths_released/component gates and avoid aggregate releases_created gates; next: #{@workflow_integrity_command}"
      ),
      check(
        :ok,
        "release.governance_cleanup_after_proof",
        "release-as cleanup waits for released companion publish and proof success",
        cleanup_after_proof?(jobs),
        "release-as cleanup must wait for each released companion publish and clean-room proof success; next: #{@workflow_integrity_command}"
      )
    ]
  end

  defp governance_queue_max?(workflow) do
    includes?(workflow, ~r/^\s*queue:\s*max\s*$/m) and
      includes?(workflow, ~r/^\s*cancel-in-progress:\s*false\s*$/m) and
      not includes?(workflow, ~r/^\s*cancel-in-progress:\s*true\s*$/m)
  end

  defp behavioral_identity_gates?(jobs) do
    Enum.all?(@core_path_gates, fn {job, path} ->
      job_block(jobs, job)
      |> includes?("contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}')")
    end) and
      Enum.all?(@release_components, fn component ->
        block = job_block(jobs, "publish-hex-#{component}")

        includes?(block, "needs.release-please.outputs.#{component}_release_created == 'true'") and
          not includes?(block, "needs.release-please.outputs.releases_created")
      end) and
      behavioral_jobs_avoid_aggregate?(jobs)
  end

  defp behavioral_jobs_avoid_aggregate?(jobs) do
    Enum.all?(jobs, fn {job, block} ->
      not behavioral_job?(job) or
        not includes?(block, "needs.release-please.outputs.releases_created")
    end)
  end

  defp behavioral_job?(job) do
    String.starts_with?(job, "publish-") or
      String.starts_with?(job, "clean-room-proof-") or
      job == "release-as-cleanup"
  end

  defp cleanup_after_proof?(jobs) do
    block = job_block(jobs, "release-as-cleanup")

    includes?(block, "- release-please") and
      includes?(block, "always()") and
      Enum.all?(@release_components, fn component ->
        includes?(block, "- publish-hex-#{component}")
      end) and
      Enum.all?(@release_components, fn component ->
        includes?(block, "- clean-room-proof-#{component}")
      end) and
      Enum.all?(@release_components, fn component ->
        includes?(block, "needs.release-please.outputs.#{component}_release_created != 'true'") and
          includes?(block, "needs.publish-hex-#{component}.result == 'success'") and
          includes?(block, "needs.clean-room-proof-#{component}.result == 'success'")
      end)
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

  defp strip_full_line_comments(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp includes?(text, value) when is_binary(value), do: String.contains?(text, value)
  defp includes?(text, %Regex{} = regex), do: Regex.match?(regex, text)

  defp live_registry_checks(core, companions) do
    entries = Enum.filter(core ++ companions, & &1.live)

    if entries == [] do
      []
    else
      missing = Enum.reject(entries, &(&1.live.status == :ok))

      [
        %{
          status: if(missing == [], do: :ok, else: :warning),
          code: "release.live_registry_presence",
          message:
            if missing == [] do
              "all live registry probes found manifest versions"
            else
              "live registry probes missing: #{Enum.map_join(missing, ", ", &live_missing_label/1)}"
            end
        }
      ]
    end
  end

  defp live_missing_label(%{component: component, manifest_version: version, live: live}),
    do: "#{component}@#{version} on #{live.source}"

  defp live_missing_label(%{package: package, version: version, live: live}),
    do: "#{package}@#{version} on #{live.source}"

  defp release_as_checks(companions) do
    stale =
      Enum.filter(companions, fn companion ->
        companion.release_as && companion.release_as_tag_exists
      end)

    [
      %{
        status: if(stale == [], do: :ok, else: :error),
        code: "release.release_as_staleness",
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

  defp check(status_when_ok, code, ok_message, true, _error_message),
    do: %{status: status_when_ok, code: code, message: ok_message}

  defp check(_status_when_ok, code, _ok_message, false, error_message),
    do: %{status: :error, code: code, message: error_message}

  defp aggregate_status(checks) do
    cond do
      Enum.any?(checks, &(&1.status == :error)) -> :error
      Enum.any?(checks, &(&1.status == :warning)) -> :warning
      true -> :ok
    end
  end

  defp live_label(%{live: nil}), do: ""
  defp live_label(%{live: %{status: status, source: source}}), do: " live_#{source}=#{status}"

  defp cleanroom_script_hardened?(cwd) do
    script = read_file!(cwd, "script/verify_companion_cleanroom.sh")

    script =~ "CORE_REQUIREMENT=" and
      script =~ "PACKAGE_REQUIREMENT=\"${PACKAGE_REQUIREMENT:-== ${VERSION}}\"" and
      script =~ "{:crosswake, \"${CORE_REQUIREMENT}\"}" and
      script =~ "{:${PACKAGE}, \"${PACKAGE_REQUIREMENT}\"}"
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
    %{source: "hex", status: if(probes.http.(url), do: :ok, else: :missing)}
  end

  defp maybe_ios_mirror_live(_version, false, _probes), do: nil

  defp maybe_ios_mirror_live(version, true, probes) do
    ref = "refs/tags/v#{version}"
    status = if probes.git_ref.(@ios_mirror_url, ref), do: :ok, else: :missing
    %{source: "ios_mirror", status: status}
  end

  defp maybe_maven_live(_version, false, _probes), do: nil

  defp maybe_maven_live(version, true, probes) do
    url =
      "https://repo1.maven.org/maven2/io/github/sztheory/crosswake-shell-core-android/#{version}/crosswake-shell-core-android-#{version}.pom"

    %{source: "maven", status: if(probes.http.(url), do: :ok, else: :missing)}
  end

  defp live_probes(opts) do
    %{
      http: Keyword.get(opts, :http_probe, &http_ok?/1),
      git_ref: Keyword.get(opts, :git_ref_probe, &git_ref_exists?/2)
    }
  end

  defp git_ref_exists?(remote_url, ref) do
    case System.cmd("git", ["ls-remote", "--tags", remote_url, ref], stderr_to_stdout: true) do
      {output, 0} -> String.contains?(output, ref)
      _ -> false
    end
  rescue
    _ -> false
  end

  defp http_ok?(url) do
    with curl when is_binary(curl) <- System.find_executable("curl"),
         {_output, 0} <-
           System.cmd(
             curl,
             [
               "--fail",
               "--silent",
               "--show-error",
               "--location",
               "--max-time",
               "5",
               "--output",
               "/dev/null",
               url
             ],
             stderr_to_stdout: true
           ) do
      true
    else
      _ -> false
    end
  rescue
    _ -> false
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
