defmodule Crosswake.Doctor do
  @moduledoc """
  Host-truth-first diagnostics over install state, policy compilation, manifest truth,
  shell posture, bounded bridge posture, and support verification.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Doctor.Check
  alias Crosswake.Manifest
  alias Crosswake.Offline.Status, as: OfflineStatus
  alias Crosswake.Offline.Telemetry, as: OfflineTelemetry
  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  defmodule Report do
    @moduledoc false

    defstruct [
      :status,
      :install_manifest,
      :manifest,
      shells: %{},
      bridge: %{},
      offline: %{},
      support: %{},
      findings: []
    ]

    @type t :: %__MODULE__{
            status: :ok | :error,
            install_manifest: map() | nil,
            manifest: Crosswake.Manifest.Types.Root.t() | nil,
            shells: map(),
            bridge: map(),
            offline: map(),
            support: map(),
            findings: [Check.t()]
          }
  end

  @default_install_manifest "priv/crosswake/install_manifest.json"
  @marker_lines ["# crosswake:install:start", "# crosswake:install:end"]

  @platform_definitions %{
    ios: %{
      label: "iOS",
      shell_root: "native/ios/crosswake_shell",
      proof_hook: "script/verify_generated_ios_shell.sh",
      generated: [
        {"README.md", ["host-owned"]},
        {"CrosswakeShell.xcodeproj/project.pbxproj", ["PBXNativeTarget"]},
        {"CrosswakeShell/CrosswakeShellApp.swift", ["ActivationCoordinator.bundled"]},
        {"Fixtures/crosswake_manifest.json", ["\"manifest_schema_version\""]}
      ],
      manifest_first: [
        {"CrosswakeShell/CrosswakeShellApp.swift",
         ["ActivationCoordinator.bundled", "onOpenURL", "onContinueUserActivity"]},
        {"CrosswakeShell/ActivationCoordinator.swift", ["packIncompatible", "inactiveRoute"]},
        {"CrosswakeShell/LiveViewContainerViewController.swift",
         ["WKWebView", "WKNavigationDelegate", "same-origin"]},
        {"CrosswakeShell/Info.plist", ["WKAppBoundDomains"]}
      ],
      route_unavailable: [
        {"CrosswakeShell/RouteUnavailableView.swift", ["Update app", "Open safe fallback"]},
        {"Fixtures/route_denial.json", ["pack_incompatible"]}
      ],
      bridge: [
        {"CrosswakeShell/BridgeChannel.swift",
         ["app.info.get", "haptics.impact", "files.pick", "request", "reply"]}
      ]
    },
    android: %{
      label: "Android",
      shell_root: "native/android/crosswake_shell",
      proof_hook: "script/verify_generated_android_shell.sh",
      generated: [
        {"README.md", ["host-owned"]},
        {"app/build.gradle", ["applicationId \"dev.crosswake.shell\""]},
        {"app/src/main/java/dev/crosswake/shell/MainActivity.kt",
         ["ActivationCoordinator.bundled"]},
        {"app/src/main/assets/crosswake_manifest.json", ["\"manifest_schema_version\""]}
      ],
      manifest_first: [
        {"app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt",
         ["pack_incompatible", "inactive_route"]},
        {"app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt",
         ["WebView", "Allowlisted"]},
        {"app/src/main/AndroidManifest.xml",
         ["android.intent.category.BROWSABLE", "android.intent.action.VIEW"]}
      ],
      route_unavailable: [
        {"app/src/main/res/layout/activity_route_unavailable.xml",
         ["Update app", "Open safe fallback"]},
        {"app/src/main/assets/route_denial.json", ["pack_incompatible"]}
      ],
      bridge: [
        {"app/src/main/java/dev/crosswake/shell/BridgeChannel.kt",
         ["app.info.get", "haptics.impact", "files.pick", "request", "reply"]}
      ]
    }
  }

  @spec run(keyword()) :: Report.t()
  def run(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())

    install_manifest_path =
      Path.expand(Keyword.get(opts, :install_manifest_path, @default_install_manifest), cwd)

    {install_manifest, findings} = load_install_manifest(install_manifest_path)
    findings = findings ++ router_and_policy_findings(install_manifest, cwd)
    {manifest, findings} = compile_and_validate_manifest(findings, opts)

    {shells, bridge, support, phase_3_findings} = phase_3_posture(manifest, cwd, opts)
    {offline, phase_4_findings} = phase_4_posture(manifest)
    phase_10_findings = phase_10_posture(manifest)
    
    findings = findings ++ phase_3_findings ++ phase_4_findings ++ phase_10_findings

    %Report{
      status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
      install_manifest: install_manifest,
      manifest: manifest,
      shells: shells,
      bridge: bridge,
      offline: offline,
      support: support,
      findings: findings
    }
  end

  defp load_install_manifest(path) do
    case File.read(path) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, manifest} ->
            {manifest, []}

          {:error, error} ->
            {nil,
             [
               check(
                 :error,
                 "install_manifest_invalid",
                 "installer_state",
                 "install manifest at #{path} is not valid JSON",
                 Exception.message(error)
               )
             ]}
        end

      {:error, :enoent} ->
        {nil,
         [
           check(
             :error,
             "install_manifest_missing",
             "installer_state",
             "install manifest not found at #{path}",
             "run mix crosswake.install before mix crosswake.doctor"
           )
         ]}

      {:error, reason} ->
        {nil,
         [
           check(
             :error,
             "install_manifest_unreadable",
             "installer_state",
             "could not read install manifest at #{path}",
             :file.format_error(reason) |> IO.iodata_to_binary()
           )
         ]}
    end
  end

  defp router_and_policy_findings(nil, _cwd), do: []

  defp router_and_policy_findings(install_manifest, cwd) do
    router_path = Path.expand(Map.get(install_manifest, "router_path", ""), cwd)
    policy_path = policy_path(install_manifest, cwd)

    []
    |> validate_router_markers(router_path)
    |> validate_policy_path(policy_path, install_manifest)
  end

  defp validate_router_markers(findings, path) do
    case File.read(path) do
      {:ok, contents} ->
        missing =
          @marker_lines
          |> Enum.reject(&String.contains?(contents, &1))

        if missing == [] do
          findings
        else
          [
            check(
              :error,
              "router_markers_missing",
              "router_markers",
              "router markers are missing from #{path}",
              "re-run mix crosswake.install to restore #{Enum.join(missing, ", ")}"
            )
            | findings
          ]
        end

      {:error, _reason} ->
        [
          check(
            :error,
            "router_missing",
            "router_markers",
            "router file not found at #{path}",
            "point the install manifest at the current Phoenix router"
          )
          | findings
        ]
    end
  end

  defp validate_policy_path(findings, nil, _install_manifest) do
    [
      check(
        :error,
        "policy_file_missing",
        "policy_module",
        "install manifest does not point to a policy file",
        "re-run mix crosswake.install so doctor can verify the host-owned policy module"
      )
      | findings
    ]
  end

  defp validate_policy_path(findings, path, install_manifest) do
    if File.exists?(path) do
      findings
    else
      [
        check(
          :error,
          "policy_file_missing",
          "policy_module",
          "policy module #{Map.get(install_manifest, "policy_module")} is missing at #{path}",
          "restore the host-owned Crosswake policy module"
        )
        | findings
      ]
    end
  end

  defp compile_and_validate_manifest(findings, opts) do
    route_source = Keyword.get(opts, :route_source)
    warn_on_unmanaged? = Keyword.get(opts, :warn_on_unmanaged?, true)

    case Compiler.compile(route_source, warn_on_unmanaged?: warn_on_unmanaged?) do
      {:ok, %{warnings: warnings}} ->
        warning_findings =
          Enum.map(warnings, fn warning ->
            check(
              :warning,
              "unmanaged_routes",
              "policy_compile",
              warning.message,
              "decide whether unmanaged routes are intentionally outside Crosswake ownership"
            )
          end)

        manifest_opts =
          case Keyword.fetch(opts, :support_matrix) do
            {:ok, support_matrix} -> [support_matrix: support_matrix]
            :error -> []
          end

        case Manifest.compile(route_source, manifest_opts) do
          {:ok, %{manifest: manifest}} ->
            support_findings =
              manifest.support_matrix
              |> SupportMatrix.validate()
              |> Enum.map(fn error ->
                check(
                  :error,
                  "support_matrix_invalid",
                  "support_matrix",
                  error.message,
                  error.hint
                )
              end)

            {manifest, findings ++ warning_findings ++ support_findings}

          {:error, %Diagnostic{errors: errors}} ->
            manifest_findings =
              Enum.map(errors, fn error ->
                check(
                  :error,
                  "manifest_invalid",
                  "manifest_contract",
                  error.message,
                  error.hint,
                  %{
                    key: error.key,
                    route_id: error.route_id,
                    path: error.path
                  }
                )
              end)

            {nil, findings ++ warning_findings ++ manifest_findings}
        end

      {:error, %Diagnostic{errors: errors}} ->
        compile_findings =
          Enum.map(errors, fn error ->
            check(:error, "policy_compile_failed", "policy_compile", error.message, error.hint, %{
              key: error.key,
              route_id: error.route_id,
              path: error.path
            })
          end)

        {nil, findings ++ compile_findings}
    end
  end

  defp phase_3_posture(nil, _cwd, _opts) do
    {%{}, %{}, %{status: :verification_required, blocking_platforms: [:ios, :android]}, []}
  end

  defp phase_3_posture(manifest, cwd, opts) do
    shells =
      Enum.into([:ios, :android], %{}, fn platform ->
        {platform, shell_posture(platform, cwd, opts)}
      end)

    bridge = bridge_posture(manifest)
    support = support_posture(shells)

    findings =
      shell_findings(shells) ++
        bridge_posture_findings(bridge) ++
        support_posture_findings(support, shells)

    {shells, bridge, support, findings}
  end

  defp phase_4_posture(nil), do: {%{}, []}

  defp phase_4_posture(manifest) do
    offline_routes =
      manifest.routes
      |> Map.values()
      |> Enum.filter(fn route ->
        route.cache_contract != nil or route.island_contract != nil
      end)
      |> Enum.map(fn route ->
        {route.id,
         %{
           runtime: route.runtime,
           offline: route.offline,
           sync_seam:
             cond do
               route.island_contract != nil -> route.island_contract.sync_seam
               route.sync != [] -> List.first(route.sync)
               true -> nil
             end,
           cache_contract: route.cache_contract != nil,
           island_contract: route.island_contract != nil
         }}
      end)
      |> Map.new()

    status_vocabulary = Enum.map(OfflineStatus.states(), &Atom.to_string/1)
    telemetry_keys = Enum.map(OfflineTelemetry.metadata_keys(), &Atom.to_string/1)
    terminal_outcomes = Enum.map(OfflineTelemetry.terminal_outcomes(), &Atom.to_string/1)

    coherent? =
      Enum.all?(offline_routes, fn {_route_id, route} ->
        case route.offline do
          :cached_read_only -> route.cache_contract and not route.island_contract
          :local_first -> route.island_contract
          :unavailable -> true
        end
      end)

    offline = %{
      status: if(coherent?, do: :supported, else: :incomplete),
      states: status_vocabulary,
      telemetry: %{
        metadata_keys: telemetry_keys,
        terminal_outcomes: terminal_outcomes
      },
      routes: stringify_offline_routes(offline_routes)
    }

    findings = [
      check(
        if(coherent?, do: :advisory, else: :error),
        if(coherent?, do: "offline_posture_ready", else: "offline_posture_incomplete"),
        "offline_posture",
        "offline posture exposes route-local cached, saved locally, queued for replay, replay failed, and conflict requires attention vocabulary",
        if(coherent?,
          do:
            "doctor and JSON output now describe explicit cached-route and study-session island posture from typed contract truth",
          else: "restore explicit cache and island contract truth for every offline route"
        ),
        %{
          status: Atom.to_string(offline.status),
          states: status_vocabulary,
          telemetry_keys: telemetry_keys,
          terminal_outcomes: terminal_outcomes,
          routes: offline.routes
        }
      )
    ]

    {offline, findings}
  end

  defp phase_10_posture(nil), do: []

  defp phase_10_posture(manifest) do
    Enum.reduce(manifest.routes, [], fn {_id, route}, acc ->
      acc =
        if route.runtime == :offline_island and "background_sync" in route.capabilities do
          [
            check(
              :error,
              "unsupported_capability",
              "route_policy",
              "Route #{route.path} requests background_sync which is an explicit v1 boundary",
              "Remove background_sync capability. See Boundary Warnings in guides/offline.md",
              %{capability: "background_sync", route_id: route.id, path: route.path}
            )
            | acc
          ]
        else
          acc
        end

      acc =
        if "generic_plugin_bus" in route.capabilities do
          [
            check(
              :error,
              "unsupported_capability",
              "route_policy",
              "Route #{route.path} requests generic_plugin_bus which is an explicit v1 boundary",
              "Remove generic_plugin_bus capability. See Boundary Warnings in guides/packs.md",
              %{capability: "generic_plugin_bus", route_id: route.id, path: route.path}
            )
            | acc
          ]
        else
          acc
        end

      acc
    end)
  end

  defp shell_posture(platform, cwd, opts) do
    definition = Map.fetch!(@platform_definitions, platform)
    shell_root = shell_root(platform, cwd, opts)

    generated = inspect_artifacts(shell_root, definition.generated)
    manifest_first = inspect_artifacts(shell_root, definition.manifest_first)
    route_unavailable = inspect_artifacts(shell_root, definition.route_unavailable)
    bridge = inspect_artifacts(shell_root, definition.bridge)
    proof = proof_posture(platform, cwd, opts)

    %{
      platform: platform,
      label: definition.label,
      shell_root: shell_root,
      generated: generated,
      manifest_first: manifest_first,
      route_unavailable: route_unavailable,
      bridge: bridge,
      proof: proof
    }
  end

  defp bridge_posture(manifest) do
    declared_routes =
      manifest.routes
      |> Map.values()
      |> Enum.map(fn route ->
        {route.id, route.capabilities}
      end)
      |> Map.new()

    declared_capabilities =
      declared_routes
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    command_posture =
      Enum.map(Registry.allowed_commands(), fn command ->
        capability = Registry.command_capability(command)

        routes =
          declared_routes
          |> Enum.flat_map(fn {route_id, capabilities} ->
            if capability in capabilities, do: [route_id], else: []
          end)
          |> Enum.sort()

        capability_entry = Map.get(manifest.capability_registry, capability)

        %{
          command: command,
          capability: capability,
          declared_on_routes: routes,
          manifest_version: capability_entry && capability_entry.version,
          executable?: routes != [] and capability_entry != nil
        }
      end)

    %{
      protocol: Contract.protocol(),
      version: Contract.version(),
      allowed_commands: Registry.allowed_commands(),
      denial_reasons: Enum.map(Denial.reasons(), &Atom.to_string/1),
      command_posture: command_posture,
      unsupported_declared_capabilities:
        declared_capabilities -- Enum.map(command_posture, & &1.capability)
    }
  end

  defp support_posture(shells) do
    proof_statuses =
      Enum.into(shells, %{}, fn {platform, shell} ->
        {platform, shell.proof.status}
      end)

    blocking_platforms =
      proof_statuses
      |> Enum.flat_map(fn
        {_platform, :passed} -> []
        {platform, _other} -> [platform]
      end)

    %{
      status: if(blocking_platforms == [], do: :supported, else: :verification_required),
      blocking_platforms: blocking_platforms,
      proof_statuses: proof_statuses
    }
  end

  defp shell_findings(shells) do
    Enum.flat_map(shells, fn {_platform, shell} ->
      [
        shell_generation_finding(shell),
        shell_activation_finding(shell),
        shell_bridge_finding(shell),
        shell_proof_finding(shell)
      ]
    end)
  end

  defp bridge_posture_findings(bridge) do
    unsupported = bridge.unsupported_declared_capabilities

    unsupported_message =
      if unsupported == [] do
        "all manifest-declared bridge capabilities stay inside the bounded Phase 3 command set"
      else
        "manifest-declared capabilities outside the bounded bridge stay unavailable to the bridge: #{Enum.join(unsupported, ", ")}"
      end

    [
      check(
        if(unsupported == [], do: :advisory, else: :warning),
        if(unsupported == [], do: "bridge_posture_ok", else: "bridge_posture_bounded"),
        "bridge_posture",
        "bounded bridge exposes #{Enum.join(bridge.allowed_commands, ", ")} and denies #{Enum.join(bridge.denial_reasons, ", ")}",
        unsupported_message,
        %{
          protocol: bridge.protocol,
          version: bridge.version,
          allowed_commands: bridge.allowed_commands,
          denial_reasons: bridge.denial_reasons,
          commands: bridge.command_posture,
          unsupported_declared_capabilities: unsupported
        }
      )
    ]
  end

  defp support_posture_findings(%{status: :supported} = support, shells) do
    [
      check(
        :advisory,
        "support_claim_supported",
        "support_posture",
        "shell support claims are unlocked because both generated-project proof hooks passed",
        "keep host-owned iOS and Android proof hooks green before widening public support",
        %{
          status: Atom.to_string(support.status),
          proof_statuses: stringify_keys(support.proof_statuses),
          shells: shell_support_details(shells)
        }
      )
    ]
  end

  defp support_posture_findings(%{status: :verification_required} = support, shells) do
    [
      check(
        :error,
        "support_claim_verification_required",
        "support_posture",
        "support claims are verification required until both generated iOS and Android proof hooks pass",
        "run mix crosswake.doctor --native-checks after the host-owned shell projects and proof hooks are in place",
        %{
          status: Atom.to_string(support.status),
          blocking_platforms: Enum.map(support.blocking_platforms, &Atom.to_string/1),
          proof_statuses: stringify_keys(support.proof_statuses),
          shells: shell_support_details(shells)
        }
      )
    ]
  end

  defp shell_generation_finding(shell) do
    build_artifact_finding(
      shell,
      "shell_generation",
      shell.generated,
      "generated real host-owned #{shell.label} shell artifacts",
      "generate the host-owned #{shell.label} shell with mix crosswake.gen.shell #{platform_name(shell.platform)}"
    )
  end

  defp shell_activation_finding(shell) do
    combined_missing = shell.manifest_first.missing ++ shell.route_unavailable.missing
    ok? = shell.manifest_first.ok? and shell.route_unavailable.ok?

    check(
      if(ok?, do: :advisory, else: :warning),
      if(ok?, do: "shell_activation_ready", else: "shell_activation_incomplete"),
      "shell_activation",
      "#{shell.label} shell is manifest-first and exposes route unavailable + pack_incompatible denial surfaces",
      if(ok?,
        do:
          "activation stays fail-closed before any web container loads and route unavailable remains part of the product contract",
        else:
          "restore manifest-first activation and route unavailable artifacts: #{Enum.join(combined_missing, ", ")}"
      ),
      %{
        platform: Atom.to_string(shell.platform),
        manifest_first: shell.manifest_first.ok?,
        route_unavailable: shell.route_unavailable.ok?,
        missing: combined_missing
      }
    )
  end

  defp shell_bridge_finding(shell) do
    build_artifact_finding(
      shell,
      "shell_bridge",
      shell.bridge,
      "#{shell.label} shell carries the bounded bridge channel for app.info.get, haptics.impact, and files.pick",
      "restore the bounded bridge channel so route-scoped commands stay typed, versioned, and request/reply-only"
    )
  end

  defp shell_proof_finding(shell) do
    {severity, code, hint} =
      case shell.proof.status do
        :passed ->
          {:advisory, "proof_hook_passed",
           "generated-project proof passed on the same host-owned artifact class adopters ship"}

        :failed ->
          {:error, "proof_hook_failed",
           "fix the proof hook failure before treating #{shell.label} shell support as supported"}

        :missing ->
          {:error, "proof_hook_missing",
           "restore #{shell.proof.script_path} before claiming #{shell.label} shell support"}

        :verification_required ->
          {:error, "proof_hook_verification_required",
           "run #{shell.proof.script_path} through mix crosswake.doctor --native-checks before claiming #{shell.label} shell support"}
      end

    check(
      severity,
      code,
      "proof_posture",
      "#{shell.label} generated-project proof hook is #{proof_label(shell.proof.status)}",
      hint,
      %{
        platform: Atom.to_string(shell.platform),
        status: proof_label(shell.proof.status),
        script_path: shell.proof.script_path,
        exit_status: shell.proof.exit_status,
        output_excerpt: shell.proof.output_excerpt
      }
    )
  end

  defp build_artifact_finding(shell, check_name, inspection, ok_message, missing_hint) do
    check(
      if(inspection.ok?, do: :advisory, else: :warning),
      if(inspection.ok?, do: "#{check_name}_ready", else: "#{check_name}_missing"),
      check_name,
      ok_message,
      if(inspection.ok?, do: "canonical shell artifacts are present", else: missing_hint),
      %{
        platform: Atom.to_string(shell.platform),
        root: shell.shell_root,
        present: inspection.ok?,
        missing: inspection.missing
      }
    )
  end

  defp inspect_artifacts(root, checks) do
    missing =
      Enum.flat_map(checks, fn {relative_path, patterns} ->
        path = Path.join(root, relative_path)

        case File.read(path) do
          {:ok, contents} ->
            missing_patterns =
              Enum.reject(patterns, fn pattern ->
                String.contains?(contents, pattern)
              end)

            if missing_patterns == [] do
              []
            else
              ["#{relative_path} missing #{Enum.join(missing_patterns, ", ")}"]
            end

          {:error, _reason} ->
            ["#{relative_path} missing"]
        end
      end)

    %{ok?: missing == [], missing: missing}
  end

  defp proof_posture(platform, cwd, opts) do
    script_path = proof_hook_path(platform, cwd, opts)
    native_checks? = Keyword.get(opts, :check_native_tools?, false) == true

    cond do
      not File.exists?(script_path) ->
        %{
          status: :missing,
          script_path: script_path,
          exit_status: nil,
          output_excerpt: nil
        }

      not native_checks? ->
        %{
          status: :verification_required,
          script_path: script_path,
          exit_status: nil,
          output_excerpt: nil
        }

      true ->
        run_proof_hook(script_path, cwd, opts)
    end
  end

  defp run_proof_hook(script_path, cwd, _opts) do
    {output, exit_status} =
      System.cmd("bash", [script_path],
        cd: cwd,
        stderr_to_stdout: true
      )

    %{
      status: if(exit_status == 0, do: :passed, else: :failed),
      script_path: script_path,
      exit_status: exit_status,
      output_excerpt: excerpt(output)
    }
  end

  defp shell_root(platform, cwd, opts) do
    key =
      case platform do
        :ios -> :ios_shell_root
        :android -> :android_shell_root
      end

    definition = Map.fetch!(@platform_definitions, platform)

    path =
      case Keyword.get(opts, key) do
        nil -> definition.shell_root
        configured -> configured
      end

    Path.expand(path, cwd)
  end

  defp proof_hook_path(platform, cwd, opts) do
    key =
      case platform do
        :ios -> :ios_proof_hook_path
        :android -> :android_proof_hook_path
      end

    definition = Map.fetch!(@platform_definitions, platform)

    path =
      case Keyword.get(opts, key) do
        nil -> definition.proof_hook
        configured -> configured
      end

    Path.expand(path, cwd)
  end

  defp shell_support_details(shells) do
    Enum.into(shells, %{}, fn {platform, shell} ->
      {Atom.to_string(platform),
       %{
         generated: shell.generated.ok?,
         manifest_first: shell.manifest_first.ok?,
         route_unavailable: shell.route_unavailable.ok?,
         bridge: shell.bridge.ok?,
         proof_status: proof_label(shell.proof.status)
       }}
    end)
  end

  defp platform_name(:ios), do: "ios"
  defp platform_name(:android), do: "android"

  defp proof_label(:passed), do: "supported"
  defp proof_label(:failed), do: "failed"
  defp proof_label(:missing), do: "unsupported"
  defp proof_label(:verification_required), do: "verification required"

  defp excerpt(nil), do: nil

  defp excerpt(output) do
    output
    |> to_string()
    |> String.trim()
    |> String.split("\n")
    |> Enum.take(-8)
    |> Enum.join("\n")
    |> case do
      "" -> nil
      text -> text
    end
  end

  defp stringify_keys(map) do
    Enum.into(map, %{}, fn {key, value} ->
      {Atom.to_string(key), proof_label(value)}
    end)
  end

  defp stringify_offline_routes(routes) do
    Enum.into(routes, %{}, fn {route_id, route} ->
      {route_id,
       %{
         "runtime" => Atom.to_string(route.runtime),
         "offline" => Atom.to_string(route.offline),
         "sync_seam" => route.sync_seam,
         "cache_contract" => route.cache_contract,
         "island_contract" => route.island_contract
       }}
    end)
  end

  defp policy_path(install_manifest, cwd) do
    file_candidates =
      install_manifest
      |> Map.get("files", %{})
      |> Map.get("created_or_reused", [])
      |> Enum.filter(&String.ends_with?(&1, "/crosswake/policy.ex"))

    case file_candidates do
      [path | _rest] -> Path.expand(path, cwd)
      [] -> nil
    end
  end

  defp check(severity, code, check_name, message, hint, details \\ %{}) do
    %Check{
      severity: severity,
      code: code,
      check: check_name,
      message: message,
      hint: hint,
      details: details
    }
  end
end
