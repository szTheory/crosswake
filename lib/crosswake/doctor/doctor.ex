defmodule Crosswake.Doctor do
  @moduledoc """
  Host-truth-first diagnostics over install state, policy compilation, manifest truth,
  shell posture, bounded bridge posture, and support verification.
  """

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.FindingPolicy
  alias Crosswake.Doctor.PublishReadiness
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
      commerce_summary: %{},
      publish_readiness: nil,
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
            commerce_summary: map(),
            publish_readiness: PublishReadiness.Report.t() | nil,
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
        {"CrosswakeShell/ActivationCoordinator.swift",
         ["packIncompatible", "inactiveRoute", "externalEntryDenied"]},
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
         [
           "app.info.get",
           "haptics.impact",
           "permissions.status",
           "files.pick",
           "request",
           "reply"
         ]}
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
         ["pack_incompatible", "inactive_route", "external_entry_denied"]},
        {"app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt", ["WebView", "Allowlisted"]},
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
         [
           "app.info.get",
           "haptics.impact",
           "permissions.status",
           "files.pick",
           "request",
           "reply"
         ]}
      ]
    }
  }

  @spec run(keyword()) :: Report.t()
  def run(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())

    install_manifest_path =
      Path.expand(
        Keyword.get(opts, :install_manifest_path) || @default_install_manifest,
        cwd
      )

    {install_manifest, findings} = load_install_manifest(install_manifest_path)
    findings = findings ++ router_and_policy_findings(install_manifest, cwd)
    {manifest, findings} = compile_and_validate_manifest(findings, opts)

    {shells, bridge, support, phase_3_findings} = phase_3_posture(manifest, cwd, opts)
    {offline, phase_4_findings} = phase_4_posture(manifest)
    phase_10_findings = phase_10_posture(manifest)
    phase_19_findings = phase_19_commerce_corridor_posture(manifest)

    {commerce_summary, phase_23_findings} = phase_23_commerce_summary(manifest, opts)

    phase_38_findings = phase_38_companion_seam_findings()
    phase_41_findings = phase_41_gating_findings(manifest)
    phase_46_findings = phase_46_auth_findings(manifest)
    phase_62_findings = phase_62_notification_findings(manifest)
    phase_95_findings = phase_95_threadline_findings(install_manifest, cwd)
    phase_65_findings = phase_65_diagnostic_export_findings()
    phase_66_findings = phase_66_generator_drift_findings(manifest, cwd, opts)
    phase_154_findings = legacy_capability_id_findings(manifest) ++ capability_rebuild_findings(manifest)
    publish_readiness = publish_readiness(manifest, opts, cwd)

    publish_findings =
      if publish_readiness, do: PublishReadiness.findings(publish_readiness), else: []

    findings =
      findings ++
        phase_3_findings ++
        phase_4_findings ++
        phase_10_findings ++
        phase_19_findings ++
        phase_23_findings ++
        phase_38_findings ++
        phase_41_findings ++
        phase_46_findings ++
        phase_62_findings ++
        phase_95_findings ++
        phase_65_findings ++
        phase_66_findings ++
        phase_154_findings ++
        publish_findings

    %Report{
      status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
      install_manifest: install_manifest,
      manifest: manifest,
      shells: shells,
      bridge: bridge,
      offline: offline,
      support: support,
      commerce_summary: commerce_summary,
      publish_readiness: publish_readiness,
      findings: findings
    }
  end

  defp publish_readiness(manifest, opts, cwd) do
    if Keyword.get(opts, :check_publish?) == true do
      PublishReadiness.run(
        opts
        |> Keyword.put(:manifest, manifest)
        |> Keyword.put(:cwd, cwd)
      )
    end
  end

  @doc """
  Builds the typed commerce summary surface published alongside the findings stream.

  Returns a map with `:corridors`, `:prerequisites`, `:snapshot_freshness`,
  `:proof_posture`, and `:rebuild_requirements` keys derived from the compiled
  manifest and canonical support matrix entries. Use the `:entitlement_snapshot_freshness`
  option (one of `:fresh`, `:stale`, `:unknown`, `:not_applicable`) to communicate
  the host-side freshness posture; the default is `:not_applicable` when no commerce
  routes are declared and `:unknown` otherwise.
  """
  @spec commerce_summary(Manifest.Types.Root.t() | nil, keyword()) :: map()
  def commerce_summary(manifest, opts \\ []) do
    {summary, _findings} = phase_23_commerce_summary(manifest, opts)
    summary
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
             :warning,
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
            manifest_findings = Enum.map(errors, &manifest_compile_check/1)

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
    support = support_posture(shells, manifest)

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

  defp phase_19_commerce_corridor_posture(nil), do: []

  defp phase_19_commerce_corridor_posture(manifest) do
    manifest.routes
    |> Map.values()
    |> Enum.filter(&(not is_nil(&1.commerce)))
    |> Enum.flat_map(fn route ->
      target = commerce_corridor_target(manifest, route.id)

      manifest
      |> RouteGate.evaluate(route.id, target)
      |> Map.get(:denials, [])
      |> Enum.filter(&commerce_doctor_denial?/1)
      |> Enum.map(&commerce_denial_check(route, &1))
    end)
  end

  # Phase 38: Companion seam — fail-closed dependency check (D-04, D-11b)
  #
  # Reads the host companion registry at runtime via Application.get_env so that
  # the proof test can register fixtures via Application.put_env. (compile_env
  # would be read at compile time and would not observe put_env in tests.)
  #
  # Per-companion config map key choice (D-03, Claude's discretion): the enabled?/1
  # map is fetched as Application.get_env(:crosswake, companion_id, %{}) — i.e. the
  # companion's own atom ID becomes the key under :crosswake. This mirrors the
  # FunWithFlags-style convention from CONTEXT.md and avoids coupling the doctor to
  # any companion-specific config shape. Documented in 38-02-SUMMARY.md.
  defp phase_38_companion_seam_findings do
    companions = Application.get_env(:crosswake, :companions, [])

    Enum.flat_map(companions, fn companion ->
      companion_id = companion.companion_id()
      config_map = Application.get_env(:crosswake, companion_id, %{})
      enabled = companion.enabled?(config_map)

      result =
        :telemetry.span(
          [:crosswake, :companion, :validate_dependency],
          %{companion_id: companion_id, route_id: nil},
          fn ->
            dep_result = companion.validate_dependency()
            {dep_result, %{companion_id: companion_id, route_id: nil, result: dep_result}}
          end
        )

      case {enabled, result} do
        {true, {:error, mods}} ->
          mod_names = Enum.map_join(mods, ", ", &inspect/1)

          # D-06: missing_kind :engine_unvalidated — the doctor cold path always calls
          # validate_dependency/0 directly, so a returned {:error, _} is always engine_unvalidated.
          # D-05: shared code string "companion.dependency_missing" with RouteGate hot path.
          [
            check(
              :error,
              "companion.dependency_missing",
              "companion.#{companion_id}",
              "[crosswake] Companion #{inspect(companion_id)} is enabled but its dependency " <>
                "is not loaded: #{mod_names}. " <>
                "Companion dependencies are not pulled transitively; the host app must declare them explicitly.",
              "Add #{mod_names} to your application's deps in mix.exs.",
              %{missing_modules: mods, missing_kind: :engine_unvalidated}
            )
          ]

        {false, :ok} ->
          [
            check(
              :advisory,
              "companion.disabled_dependency_present",
              "companion.#{companion_id}",
              "Companion #{inspect(companion_id)} is disabled but its optional " <>
                "dependency is present.",
              "No action required. Enable the companion in your host config if you " <>
                "want to activate it.",
              %{}
            )
          ]

        _ ->
          []
      end
    end)
  end

  # Phase 41: Gating doctor category — one finding per gated route (D-01, D-02)
  #
  # Emits:
  #   - :advisory "gating.route_gated" per gated route (one per route with gated_by != nil)
  #   - :error "gating.flag_reference_unknown" when gated_by atom resolves to no companion (D-04, D-05)
  #   - :warning "gating.fallback_route_unknown" when on_unavailable fallback target absent (D-10)
  #
  # Uses Application.get_env (not compile_env) so proof tests can register fixtures via put_env.
  # Does NOT call validate_dependency or report_state — Phase 38 owns dependency validation,
  # SupportMatrix owns state reads.
  defp phase_41_gating_findings(nil), do: []

  defp phase_41_gating_findings(manifest) do
    companions = Application.get_env(:crosswake, :companions, [])

    known_companion_ids =
      companions
      |> Enum.map(& &1.companion_id())
      |> MapSet.new()

    manifest.routes
    |> Map.values()
    |> Enum.filter(&(not is_nil(&1.gated_by)))
    |> Enum.flat_map(fn route ->
      advisory_finding = gating_advisory_finding(route)
      error_finding = gating_flag_reference_error(route, known_companion_ids)
      warning_finding = gating_fallback_route_warning(route, manifest)

      [advisory_finding] ++ error_finding ++ warning_finding
    end)
  end

  # One :advisory finding per gated route surfacing the posture and optional fallback hint (D-03, D-09)
  defp gating_advisory_finding(route) do
    {posture_label, hint} =
      case route.on_unavailable do
        {:fallback_phoenix, fallback_id} ->
          label = "redirect to :#{fallback_id} (fallback_phoenix)"

          hint_text =
            "deliberate redirect posture — gate denial navigates to :#{fallback_id} instead of halting"

          {label, hint_text}

        :deny ->
          {"deny (explicit)", nil}

        nil ->
          {"fail-closed (default/implicit deny)", nil}
      end

    on_unavailable_serialized =
      case route.on_unavailable do
        {:fallback_phoenix, id} -> "fallback_phoenix:#{id}"
        :deny -> "deny"
        nil -> nil
      end

    check(
      :advisory,
      "gating.route_gated",
      "gating.#{route.id}",
      "Route \"#{route.id}\" is gated by :#{route.gated_by}; on_unavailable: #{posture_label}",
      hint,
      %{route_id: route.id, gated_by: route.gated_by, on_unavailable: on_unavailable_serialized}
    )
  end

  # :error finding when gated_by atom does not resolve to any registered companion (D-04, D-05)
  defp gating_flag_reference_error(route, known_companion_ids) do
    if MapSet.member?(known_companion_ids, route.gated_by) do
      []
    else
      [
        check(
          :error,
          "gating.flag_reference_unknown",
          "gating.#{route.id}",
          "Route \"#{route.id}\" declares gated_by: :#{route.gated_by} but no registered companion has that companion_id",
          "Register a companion module whose companion_id/0 returns :#{route.gated_by}, " <>
            "or correct the gated_by declaration in your route policy.",
          %{route_id: route.id, gated_by: route.gated_by}
        )
      ]
    end
  end

  # :warning finding when fallback route target is absent from manifest routes (D-10)
  defp gating_fallback_route_warning(route, manifest) do
    case route.on_unavailable do
      {:fallback_phoenix, fallback_id} ->
        if Map.has_key?(manifest.routes, to_string(fallback_id)) do
          []
        else
          [
            check(
              :warning,
              "gating.fallback_route_unknown",
              "gating.#{route.id}",
              "Route \"#{route.id}\" declares on_unavailable: {:fallback_phoenix, :#{fallback_id}} " <>
                "but :#{fallback_id} is not present in the manifest routes",
              "Add route :#{fallback_id} to your router, or correct the on_unavailable declaration.",
              %{route_id: route.id, fallback_route_id: fallback_id}
            )
          ]
        end

      _ ->
        []
    end
  end

  defp phase_46_auth_findings(nil), do: []

  defp phase_46_auth_findings(manifest) do
    routes =
      manifest.routes
      |> Map.values()
      |> Enum.filter(&(not is_nil(&1.auth_min_level) or not is_nil(&1.requires_recent_auth)))

    route_findings =
      Enum.map(routes, fn route ->
        check(
          :advisory,
          "auth.route_predicated",
          "auth.#{route.id}",
          "Route \"#{route.id}\" declares auth predicates auth_min_level=#{route.auth_min_level} requires_recent_auth=#{route.requires_recent_auth} auth_posture=#{route.auth_posture}",
          "Crosswake enforces fail-closed session-authority evaluation via :step_up_required when predicate checks fail.",
          %{
            route_id: route.id,
            auth_min_level: route.auth_min_level,
            requires_recent_auth: route.requires_recent_auth,
            auth_posture: route.auth_posture,
            fallback: :step_up_required
          }
        )
      end)

    contract_finding =
      if routes == [] do
        []
      else
        auth_truth = Crosswake.SupportMatrix.auth_contract_truth() |> List.first(%{})

        [
          check(
            :advisory,
            "auth.step_up_required_contract",
            "auth.contract_posture",
            "Auth contract surface includes backend session-authority evaluation, shipped Phase 55 handoff contract machinery, shipped Phase 56 step-up intent ceremony, shipped Phase 57 auth-return boundary contracts, stable Phase 58 auth telemetry, and Phase 58 security closeout.",
            "Session-authority scope: typed AuthContext/SessionAuthorityLane input, explicit auth_posture, route-local auth_return seams, canonical auth.step_up.*, auth.handoff.*, auth.step_up_intent.*, and auth.return.* denial codes, fail-closed :step_up_required denial, backend-owned handoff ticket/server-record redemption proof, server-owned step-up intent plus Plug/LiveView ceremony proof, host-owned auth-return attempt replay proof, low-cardinality auth telemetry, and STRIDE-style security closeout. Refresh-token helpers, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI remain deferred.",
            %{
              fallback: :step_up_required,
              posture: :session_authority,
              shipped_contracts: Map.get(auth_truth, :shipped_contracts, []),
              handoff: Map.get(auth_truth, :handoff, %{}),
              step_up: Map.get(auth_truth, :step_up, %{}),
              auth_return: Map.get(auth_truth, :auth_return, %{}),
              contract_surface: Map.get(auth_truth, :contract_surface),
              contract_proof_class: Map.get(auth_truth, :contract_proof_class),
              route_authority_source: Map.get(auth_truth, :route_authority_source),
              evidence_authority: Map.get(auth_truth, :evidence_authority, %{}),
              host_readiness: Map.get(auth_truth, :host_readiness),
              provider_device_proof: Map.get(auth_truth, :provider_device_proof),
              telemetry:
                auth_truth
                |> Map.get(:telemetry, %{})
                |> Map.drop([:forbidden_metadata_keys]),
              security_closeout: Map.get(auth_truth, :security_closeout, %{}),
              # denial_codes and safe_detail_keys are obtained at runtime via the :companions
              # registry using the denial_codes/0 optional callback. auth_contract_truth/0
              # already populates these fields from the registry (DECOUPLE-03 / T-136-04).
              # Fallback to [] when no companion exposes denial_codes/0.
              denial_codes:
                Map.get(auth_truth, :denial_codes) ||
                  Enum.flat_map(
                    Application.get_env(:crosswake, :companions, []),
                    fn mod ->
                      if function_exported?(mod, :denial_codes, 0), do: mod.denial_codes(), else: []
                    end
                  ),
              safe_detail_keys: Map.get(auth_truth, :safe_detail_keys, []),
              deferred: Map.get(auth_truth, :deferred, [])
            }
          )
        ]
      end

    route_findings ++ contract_finding
  end

  defp phase_62_notification_findings(nil), do: []

  defp phase_62_notification_findings(manifest) do
    routes = manifest.routes |> Map.values()
    capabilities = Map.keys(manifest.capability_registry || %{})
    
    has_notifications? = Enum.any?(routes, fn route ->
      "notification_token" in route.capabilities or route.notification_open == true
    end) or "notification_token" in capabilities

    if has_notifications? do
      truth = SupportMatrix.notification_support_truth() |> List.first(%{})
      telemetry = Map.get(truth, :telemetry, %{})
      
      [
        check(
          :advisory,
          "notification.telemetry_contract",
          "notification_posture",
          "Crosswake notifications expose strict telemetry for diagnostics. Raw APNs/FCM payloads, device tokens, and PII are forbidden.",
          "Check chimeway telemetry events for delivery status. Do not attempt to log raw push tokens.",
          %{
            event_names: Map.get(telemetry, :event_names, []),
            metadata_keys: Map.get(telemetry, :metadata_keys, []),
            forbidden_metadata_keys: Map.get(telemetry, :forbidden_metadata_keys, []),
            authority_source: Map.get(telemetry, :authority_source),
            proof_class: Map.get(telemetry, :proof_class)
          }
        ),
        check(
          :advisory,
          "notification.delivery_deferred",
          "notification_posture",
          Map.get(truth, :posture, ""),
          "Use the local notification_token capability to read push tokens. Do not expect Crosswake to deliver remote push notifications to APNs or FCM; delivery execution remains deferred.",
          %{
            delivery_supported: Map.get(truth, :delivery_supported, false),
            deferred: Map.get(truth, :deferred, [])
          }
        )
      ]
    else
      []
    end
  end

  defp phase_65_diagnostic_export_findings do
    truth = SupportMatrix.diagnostic_export_support_truth() |> List.first(%{})
    telemetry = Map.get(truth, :telemetry, %{})

    [
      check(
        :advisory,
        "diagnostic_export.contract_shipped",
        "diagnostic_export_posture",
        "Diagnostics-export envelope and sanitize contract are shipped; the merge-blocking allowlist proof is enforced. Native MetricKit/ApplicationExitInfo transport is deferred to Phase 67.",
        "The host owns the endpoint and the data. Configure your endpoint to receive POST payloads matching the DiagnosticExport.Envelope contract. No Elixir HTTP-sending code ships in the library.",
        %{
          delivery_supported: Map.get(truth, :delivery_supported, false),
          deferred: Map.get(truth, :deferred, []),
          authority_source: Map.get(telemetry, :authority_source, :host_configured_endpoint),
          proof_class: Map.get(telemetry, :proof_class, :merge_blocking),
          forbidden_metadata_keys: Map.get(telemetry, :forbidden_metadata_keys, [])
        }
      )
    ]
  end

  # Phase 95: Threadline posture doctor checks (OPER-03)
  #
  # Emits findings for:
  #   - threadline.plug_missing (:advisory) — Crosswake.Plug.Threadline absent from router
  #   - threadline.ledger_not_configured (:advisory) — no :audit_ledger config
  #   - threadline.pii_forbidden_field_present (:error) — Ecto schema fields intersect forbidden keys (D-03)
  #   - threadline.ledger_schema_drift (:warning) — Ecto schema missing canonical ledger columns (LEDG-02)
  #
  # Uses Application.get_env (not compile_env) so proof tests can register fixtures via put_env.
  # Reads the router file from install_manifest router_path to check for plug presence.
  #
  # Only the router plug check depends on the install manifest. The ledger
  # checks — including the :error-class PII safety check — depend solely on
  # Application env, so they run even when the manifest is missing; a host
  # with a PII-bearing ledger schema that has not yet run `mix
  # crosswake.install` must still receive the PII finding (IN-07).
  defp phase_95_threadline_findings(install_manifest, cwd) do
    plug_findings =
      case install_manifest do
        nil ->
          []

        manifest ->
          router_path = Path.expand(Map.get(manifest, "router_path", ""), cwd)
          check_threadline_plug(router_path)
      end

    audit_ledger_config = Application.get_env(:crosswake, :audit_ledger)
    ledger_findings = check_audit_ledger_configured(audit_ledger_config)

    schema = ledger_schema(audit_ledger_config)

    schema_findings =
      if is_atom(schema) and not is_nil(schema) and Code.ensure_loaded?(schema) do
        check_ledger_schema(schema)
      else
        []
      end

    plug_findings ++ ledger_findings ++ schema_findings
  end

  # Normalizes the four documented :audit_ledger config shapes to a schema module or nil.
  # Resolution order:
  #   nil                     → nil
  #   keyword list            → Keyword.get(list, :schema)  (CR-04: never string-key access on keyword)
  #   map                     → Map.get(config, :schema) || Map.get(config, "schema")
  #   bare atom (module ref)  → config itself
  #   anything else           → nil
  defp ledger_schema(nil), do: nil

  defp ledger_schema(config) when is_list(config) do
    if Keyword.keyword?(config) do
      Keyword.get(config, :schema)
    else
      nil
    end
  end

  defp ledger_schema(config) when is_map(config) do
    Map.get(config, :schema) || Map.get(config, "schema")
  end

  defp ledger_schema(config) when is_atom(config) and not is_nil(config) and not is_boolean(config) do
    config
  end

  defp ledger_schema(_config), do: nil

  defp check_threadline_plug(router_path) do
    case File.read(router_path) do
      {:ok, contents} ->
        if String.contains?(contents, "plug Crosswake.Plug.Threadline") do
          []
        else
          [
            check(
              :advisory,
              "threadline.plug_missing",
              "threadline_posture",
              "Crosswake.Plug.Threadline is not present in the router at #{router_path}",
              "Add `plug Crosswake.Plug.Threadline` to your Phoenix router pipeline to enable X-Crosswake-Thread-Id propagation and telemetry spans. See guides/threadline.md.",
              %{router_path: router_path}
            )
          ]
        end

      {:error, _reason} ->
        []
    end
  end

  defp check_audit_ledger_configured(nil) do
    [
      check(
        :advisory,
        "threadline.ledger_not_configured",
        "threadline_posture",
        "Crosswake audit ledger is not configured — threadline posture is ephemeral only",
        "Configure `:audit_ledger` under `:crosswake` in your host config and run `mix crosswake.gen.audit` to scaffold the host-owned ledger schema and migration. See guides/threadline.md.",
        %{}
      )
    ]
  end

  defp check_audit_ledger_configured(_config), do: []

  # LEDG-02 canonical 15-column set
  @canonical_ledger_columns [
    :thread_id,
    :correlation_id,
    :route_id,
    :actor_ref,
    :actor_kind,
    :event_class,
    :event_type,
    :outcome,
    :provenance,
    :occurred_at,
    :recorded_at,
    :idempotency_key,
    :metadata,
    :row_hash,
    :prev_hash
  ]

  defp check_ledger_schema(schema) do
    # A loadable module that does not implement __schema__/1 is not an Ecto
    # schema. Falling through to the field checks would report every canonical
    # column as missing — a misleading diagnosis — while the PII check silently
    # passes. Emit a distinct invalid-schema finding instead (IN-06).
    if function_exported?(schema, :__schema__, 1) do
      schema_fields =
        try do
          schema.__schema__(:fields)
        rescue
          _ -> []
        end

      forbidden_keys =
        SupportMatrix.audit_ledger_support_truth()
        |> hd()
        |> get_in([:telemetry, :forbidden_metadata_keys])

      pii_findings = check_pii_fields(schema, schema_fields, forbidden_keys)
      drift_findings = check_schema_drift(schema, schema_fields)

      pii_findings ++ drift_findings
    else
      [
        check(
          :advisory,
          "threadline.ledger_schema_invalid",
          "threadline_posture",
          "Configured audit ledger module #{inspect(schema)} is not an Ecto schema (no __schema__/1)",
          "Point `:audit_ledger` at an Ecto schema module, or run `mix crosswake.gen.audit` to scaffold one. PII and schema-drift checks were skipped because the module exposes no fields. See guides/threadline.md.",
          %{schema: inspect(schema)}
        )
      ]
    end
  end

  defp check_pii_fields(schema, schema_fields, forbidden_keys) do
    # Exclude canonical ledger columns from the forbidden set so that :actor_ref
    # (which is both a required canonical column and a forbidden metadata key)
    # does not falsely trigger a PII error on a compliant schema. (CR-01)
    ledger_forbidden =
      MapSet.difference(MapSet.new(forbidden_keys), MapSet.new(@canonical_ledger_columns))

    offending = MapSet.intersection(MapSet.new(schema_fields), ledger_forbidden)

    if MapSet.size(offending) > 0 do
      offending_list = MapSet.to_list(offending) |> Enum.sort()

      [
        check(
          :error,
          "threadline.pii_forbidden_field_present",
          "threadline_posture",
          "Ecto schema #{inspect(schema)} contains PII-forbidden field(s): #{Enum.join(offending_list, ", ")}",
          "Remove PII-forbidden fields #{inspect(offending_list)} from the audit ledger schema #{inspect(schema)}. The Crosswake audit ledger must be PII-free by construction. See D-03 and guides/threadline.md.",
          %{schema: inspect(schema), offending_keys: offending_list}
        )
      ]
    else
      []
    end
  end

  defp check_schema_drift(schema, schema_fields) do
    schema_field_set = MapSet.new(schema_fields)
    canonical_set = MapSet.new(@canonical_ledger_columns)
    missing = MapSet.difference(canonical_set, schema_field_set) |> MapSet.to_list() |> Enum.sort()

    if missing == [] do
      []
    else
      [
        check(
          :warning,
          "threadline.ledger_schema_drift",
          "threadline_posture",
          "Ecto schema #{inspect(schema)} is missing canonical ledger columns: #{Enum.join(missing, ", ")}",
          "Add the missing columns #{inspect(missing)} to the audit ledger schema #{inspect(schema)}. All 15 canonical columns defined in LEDG-02 must be present. Run `mix crosswake.gen.audit` to regenerate the migration template.",
          %{schema: inspect(schema), missing_columns: missing}
        )
      ]
    end
  end

  defp phase_23_commerce_summary(nil, _opts) do
    {%{
       corridors: [],
       prerequisites: %{},
       snapshot_freshness: :not_applicable,
       proof_posture: %{merge_blocking: [], advisory: []},
       rebuild_requirements: []
     }, []}
  end

  defp phase_23_commerce_summary(manifest, opts) do
    commerce_routes =
      manifest.routes
      |> Map.values()
      |> Enum.filter(&(not is_nil(&1.commerce)))

    proof_class_map = SupportMatrix.commerce_corridor_proof_classes()
    corridor_entries = SupportMatrix.commerce_corridors()
    corridor_entries_by_role = Map.new(corridor_entries, &{&1.corridor_role, &1})

    corridors = commerce_corridors_summary(commerce_routes, corridor_entries_by_role)
    prerequisites = commerce_prerequisites_summary(commerce_routes, corridor_entries_by_role)

    snapshot_freshness =
      commerce_snapshot_freshness(
        commerce_routes,
        Keyword.get(opts, :entitlement_snapshot_freshness)
      )

    rebuild_requirements =
      commerce_rebuild_requirements(commerce_routes, corridor_entries_by_role)

    stale_findings = stale_snapshot_findings(commerce_routes, snapshot_freshness)
    rebuild_findings = native_rebuild_findings(rebuild_requirements, opts)

    unknown_role_findings =
      unknown_corridor_role_findings(commerce_routes, corridor_entries_by_role)

    extra_findings = stale_findings ++ rebuild_findings ++ unknown_role_findings

    proof_posture =
      build_proof_posture(commerce_routes, corridors, proof_class_map, extra_findings)

    summary = %{
      corridors: corridors,
      prerequisites: prerequisites,
      snapshot_freshness: snapshot_freshness,
      proof_posture: proof_posture,
      rebuild_requirements: rebuild_requirements
    }

    {summary, extra_findings}
  end

  defp commerce_corridors_summary(commerce_routes, corridor_entries_by_role) do
    commerce_routes
    |> Enum.map(fn route ->
      role = route.commerce.role |> Atom.to_string()

      case Map.fetch(corridor_entries_by_role, role) do
        {:ok, entry} ->
          %{
            route_id: route.id,
            corridor_ref: route.commerce.corridor_ref,
            role: role,
            owner_posture: entry.owner_posture,
            native_rebuild_required: entry.native_rebuild_required,
            proof_class: entry.proof_class,
            advisory_provider_proof: entry.advisory_provider_proof
          }

        :error ->
          # Fail-closed surface row for an unknown corridor role. Paired with a
          # merge-blocking commerce.corridor.role_unknown finding emitted by
          # unknown_corridor_role_findings/2 so the unknown row is never silent.
          %{
            route_id: route.id,
            corridor_ref: route.commerce.corridor_ref,
            role: role,
            owner_posture: :unknown,
            native_rebuild_required: :unknown,
            proof_class: :unknown,
            advisory_provider_proof: false
          }
      end
    end)
    |> Enum.sort_by(& &1.route_id)
  end

  defp unknown_corridor_role_findings([], _corridor_entries_by_role), do: []

  defp unknown_corridor_role_findings(commerce_routes, corridor_entries_by_role) do
    commerce_routes
    |> Enum.filter(fn route ->
      role = route.commerce.role |> Atom.to_string()
      not Map.has_key?(corridor_entries_by_role, role)
    end)
    |> Enum.map(fn route ->
      role = route.commerce.role |> Atom.to_string()

      check(
        :error,
        "commerce.corridor.role_unknown",
        "commerce_summary",
        "route #{route.id} declares corridor role #{role} which is not in the canonical SupportMatrix commerce corridor taxonomy",
        "declare #{role} in Crosswake.SupportMatrix.commerce_corridors/0 or change the route to a canonical corridor role before relying on commerce support truth",
        %{
          route_id: route.id,
          corridor_ref: route.commerce.corridor_ref,
          role: role,
          proof_class: "merge_blocking"
        }
      )
    end)
  end

  defp commerce_prerequisites_summary(commerce_routes, corridor_entries_by_role) do
    commerce_routes
    |> Enum.map(fn route ->
      role = route.commerce.role |> Atom.to_string()
      entry = Map.get(corridor_entries_by_role, role)
      {route.id, (entry && entry.prerequisites) || []}
    end)
    |> Map.new()
  end

  defp commerce_snapshot_freshness([], _opt), do: :not_applicable

  defp commerce_snapshot_freshness(_routes, nil), do: :unknown

  # :not_applicable is reserved as the default when no commerce routes are
  # declared (see the docstring for commerce_summary/2). When commerce routes
  # ARE present, a caller-supplied :not_applicable would silently bypass the
  # fail-closed commerce.entitlement.stale_snapshot finding (because
  # stale_snapshot_findings/2 matches :not_applicable as the catch-all). Coerce
  # to :unknown so the fail-closed merge-blocking diagnostic still fires per
  # phase 23 D-04 (stale or unknown freshness is fail-closed and merge-blocking).
  defp commerce_snapshot_freshness(_routes, :not_applicable), do: :unknown

  defp commerce_snapshot_freshness(_routes, freshness)
       when freshness in [:fresh, :stale, :unknown],
       do: freshness

  defp commerce_snapshot_freshness(_routes, _other), do: :unknown

  defp commerce_rebuild_requirements(commerce_routes, corridor_entries_by_role) do
    commerce_routes
    |> Enum.filter(fn route ->
      role = route.commerce.role |> Atom.to_string()
      entry = Map.get(corridor_entries_by_role, role)
      entry && entry.native_rebuild_required
    end)
    |> Enum.map(fn route ->
      %{
        route_id: route.id,
        corridor_ref: route.commerce.corridor_ref,
        role: route.commerce.role |> Atom.to_string()
      }
    end)
    |> Enum.sort_by(& &1.route_id)
  end

  defp stale_snapshot_findings([], _freshness), do: []

  defp stale_snapshot_findings(_routes, freshness) when freshness in [:stale, :unknown] do
    [
      check(
        :warning,
        "commerce.entitlement.stale_snapshot",
        "commerce_summary",
        "entitlement snapshot freshness is #{freshness}; access decisions stay fail-closed until backend authority refreshes the projection",
        "refresh the backend entitlement projection and rerun doctor; doctor will not advance commerce support truth while snapshot freshness is stale or unknown",
        %{
          freshness: Atom.to_string(freshness),
          proof_class: "merge_blocking"
        }
      )
    ]
  end

  defp stale_snapshot_findings(_routes, _freshness), do: []

  defp native_rebuild_findings([], _opts), do: []

  defp native_rebuild_findings(rebuild_requirements, opts) do
    case Keyword.get(opts, :native_rebuild_satisfied?, false) do
      true ->
        []

      false ->
        Enum.map(rebuild_requirements, fn requirement ->
          check(
            :warning,
            "commerce.corridor.native_rebuild_required",
            "commerce_summary",
            "route #{requirement.route_id} corridor #{requirement.corridor_ref} (#{requirement.role}) requires a native or companion rebuild before commerce support can advance",
            "rebuild the corridor's native or companion artifacts and rerun doctor with native_rebuild_satisfied?: true after the corresponding proof lane passes",
            %{
              route_id: requirement.route_id,
              corridor_ref: requirement.corridor_ref,
              role: requirement.role,
              proof_class: "merge_blocking"
            }
          )
        end)
    end
  end

  # Lenient proof_class comparison so call sites that store either the atom
  # form (matching the SupportMatrix source of truth) or the legacy string
  # form (used today by commerce_summary findings) both match. The codebase
  # already defensively handles both shapes in the formatters; until every
  # emission site converges on the atom form, build_proof_posture/4 uses this
  # helper so a future caller storing :merge_blocking does not silently drop
  # the finding from the proof posture buckets.
  defp proof_class_eq?(value, target_atom) when is_atom(target_atom) do
    value == target_atom or value == Atom.to_string(target_atom)
  end

  defp build_proof_posture(commerce_routes, _corridors, _proof_class_map, extra_findings) do
    merge_blocking_extra =
      Enum.filter(extra_findings, fn finding ->
        proof_class_eq?(Map.get(finding.details, :proof_class), :merge_blocking)
      end)

    advisory_extra =
      Enum.filter(extra_findings, fn finding ->
        proof_class_eq?(Map.get(finding.details, :proof_class), :advisory)
      end)

    base_merge_blocking =
      commerce_routes
      |> Enum.map(fn route -> "corridor_contract:" <> route.id end)
      |> Enum.sort()

    base_advisory =
      commerce_routes
      |> Enum.filter(fn route ->
        SupportMatrix.commerce_corridor_proof_classes()
        |> Map.get(route.commerce.role |> Atom.to_string(), %{})
        |> Map.get(:advisory_provider_proof, false)
      end)
      |> Enum.map(fn route -> "provider_storefront:" <> route.id end)
      |> Enum.sort()

    %{
      merge_blocking: base_merge_blocking ++ Enum.map(merge_blocking_extra, & &1.code),
      advisory: base_advisory ++ Enum.map(advisory_extra, & &1.code)
    }
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

  defp support_posture(shells, manifest) do
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
      proof_statuses: proof_statuses,
      release_policy: release_policy_snapshot(manifest)
    }
  end

  defp release_policy_snapshot(manifest) do
    compatibility = manifest.compatibility
    support_matrix = manifest.support_matrix

    %{
      crosswake_version: manifest.crosswake_version,
      manifest_schema_version: compatibility.manifest_schema_version,
      bridge_protocol_version: compatibility.bridge_protocol_version,
      native_runtime_version: compatibility.native_runtime_version,
      package_version_truth: "Package versions alone do not determine support truth.",
      companion_requirement:
        "Future companions must declare minimum compatible ranges for core, manifest_schema_version, bridge_protocol_version, native_runtime_version, and exposed capability-family majors.",
      capability_families: support_matrix.capability_families,
      package_surfaces: support_matrix.package_surfaces,
      release_boundaries: support_matrix.release_boundaries,
      change_classes: support_matrix.change_classes,
      rebuild_matrix: Crosswake.SupportMatrix.rebuild_matrix(support_matrix),
      evidence_posture: evidence_posture_snapshot(support_matrix)
    }
  end

  # D-16: Evidence posture summary keyed by platform — a fixed Phase-64 posture map.
  # iOS is :device_verified (host-owned iOS shell with device-backed proof artifacts).
  # Android is :jvm_hermetic (CI-only JVM proof; no device proof lane until Phases 67/68).
  # NOTE: This is a compile-time constant for Phase 64. It does NOT derive from the
  # rebuild_matrix rows at runtime. When device-verified Android evidence arrives in
  # Phase 67/68, this function should read support_matrix.rebuild_matrix evidence_tier
  # values and derive ios/android from them.
  defp evidence_posture_snapshot(_support_matrix) do
    %{ios: :device_verified, android: :jvm_hermetic}
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
    {severity, code, message, hint} = FindingPolicy.support_claim(:supported)

    [
      check(
        severity,
        code,
        "support_posture",
        message,
        hint,
        %{
          status: Atom.to_string(support.status),
          proof_statuses: stringify_keys(support.proof_statuses),
          shells: shell_support_details(shells)
        }
      )
    ] ++ capability_posture_findings(support)
  end

  defp support_posture_findings(%{status: :verification_required} = support, shells) do
    {severity, code, message, hint} = FindingPolicy.support_claim(:verification_required)

    [
      check(
        severity,
        code,
        "support_posture",
        message,
        hint,
        %{
          status: Atom.to_string(support.status),
          blocking_platforms: Enum.map(support.blocking_platforms, &Atom.to_string/1),
          proof_statuses: stringify_keys(support.proof_statuses),
          shells: shell_support_details(shells)
        }
      )
    ] ++ capability_posture_findings(support)
  end

  defp capability_posture_findings(support) do
    {merge_blocking, advisory} =
      support.release_policy.capability_families
      |> Enum.split_with(&(&1.proof_class == :merge_blocking))

    mb_check =
      if merge_blocking != [] do
        check(
          if(support.status == :supported, do: :advisory, else: :warning),
          "capability_proof_merge_blocking",
          "capability_posture",
          "merge-blocking capability proofs are required for: #{Enum.map(merge_blocking, & &1.family) |> Enum.join(", ")}",
          "merge-blocking capability proofs must pass to claim support truth",
          %{
            capabilities: Enum.map(merge_blocking, & &1.family),
            proof_class: "merge_blocking"
          }
        )
      end

    adv_check =
      if advisory != [] do
        check(
          :advisory,
          "capability_proof_advisory",
          "capability_posture",
          "advisory capability proofs are abstract for: #{Enum.map(advisory, & &1.family) |> Enum.join(", ")}",
          "advisory capabilities do not block standard CI but require environment-sensitive verification before widening claims",
          %{
            capabilities: Enum.map(advisory, & &1.family),
            proof_class: "advisory",
            promotion_path:
              "advisory-to-merge-blocking promotion requires an explicit requirement/roadmap scope change plus sustained stability evidence from the advisory lane; advisory results never assert core support truth"
          }
        )
      end

    [mb_check, adv_check] |> Enum.reject(&is_nil/1)
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
      "#{shell.label} shell carries the bounded bridge channel for app.info.get, haptics.impact, permissions.status, and files.pick",
      "restore the bounded bridge channel so route-scoped commands stay typed, versioned, and request/reply-only"
    )
  end

  defp shell_proof_finding(shell) do
    {severity, code, hint} =
      FindingPolicy.shell_proof(shell.proof.status, shell.label, shell.proof.script_path)

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

  defp manifest_compile_check(error) do
    base_details = %{
      key: error.key,
      route_id: error.route_id,
      path: error.path
    }

    cond do
      String.contains?(error.message, "declares undeclared corridor_ref") ->
        check(
          :error,
          "commerce.corridor.undeclared",
          "commerce_corridor",
          error.message,
          "declare the corridor profile before manifest generation",
          Map.merge(base_details, %{
            denial_code: "commerce.corridor.undeclared",
            fallback_hint: "return_to_phoenix_guidance",
            proof_class: "merge_blocking"
          })
        )

      String.contains?(error.message, "must provide non-empty prerequisites") ->
        check(
          :error,
          "commerce.corridor.prerequisite_missing",
          "commerce_corridor",
          error.message,
          "restore canonical corridor prerequisites before shipping commerce routes",
          Map.merge(base_details, %{
            denial_code: "commerce.corridor.prerequisite_missing",
            fallback_hint: "return_to_phoenix_guidance",
            proof_class: "merge_blocking"
          })
        )

      true ->
        check(
          :error,
          "manifest_invalid",
          "manifest_contract",
          error.message,
          error.hint,
          base_details
        )
    end
  end

  defp commerce_corridor_target(manifest, route_id) do
    %Compatibility.Target{
      manifest_schema_version: manifest.compatibility.manifest_schema_version,
      bridge_protocol_version: manifest.compatibility.bridge_protocol_version,
      native_runtime_version: manifest.compatibility.native_runtime_version,
      origin: manifest.host.origin,
      active_route_id: route_id,
      manifest_source: :bundled,
      capabilities: %{},
      packs: %{}
    }
  end

  defp commerce_doctor_denial?(denial) do
    denial.reason == :commerce_corridor and
      denial.code in [
        "commerce.corridor.undeclared",
        "commerce.corridor.prerequisite_missing",
        "commerce.corridor.runtime_incompatible"
      ]
  end

  defp commerce_denial_check(route, denial) do
    role = Map.get(denial.details, :role, route.commerce.role)
    corridor_ref = Map.get(denial.details, :corridor_ref, route.commerce.corridor_ref)
    fallback_hint = commerce_fallback_hint(denial)
    proof_class = commerce_role_proof_class(role)

    check(
      :error,
      denial.code,
      "commerce_corridor",
      "route #{route.id} triggered #{denial.code}",
      fallback_hint,
      %{
        route_id: route.id,
        corridor_ref: corridor_ref,
        role: role,
        denial_code: denial.code,
        fallback_hint: fallback_hint,
        proof_class: proof_class
      }
    )
  end

  defp commerce_role_proof_class(role) when is_atom(role),
    do: commerce_role_proof_class(Atom.to_string(role))

  defp commerce_role_proof_class(role) when is_binary(role) do
    case SupportMatrix.commerce_corridor_proof_classes() |> Map.get(role) do
      %{proof_class: pc} -> Atom.to_string(pc)
      _ -> "merge_blocking"
    end
  end

  defp commerce_role_proof_class(_), do: "merge_blocking"

  defp commerce_fallback_hint(denial) do
    denial.recovery
    |> Map.get(:fallback, :return_to_phoenix_guidance)
    |> to_string()
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

  # D-58/D-59/D-63: names every route capability declaration that uses a
  # legacy (dotted-command) id instead of the family id, at advisory
  # severity only — the legacy declaration keeps authorizing forever, so
  # this can never fail doctor's exit code.
  #
  # This lives here, not as a compile-time deprecation warning, because a
  # compile-time warning is mechanically impossible where it would matter:
  # Crosswake.Router's macros only stash route metadata (no validation runs
  # at router macro-expansion time), Policy.Validator never runs at router
  # expansion either, and Compiler.emit_warnings/2 is gated behind a flag
  # that only test support passes. The compiled manifest, read here, is the
  # only point in the pipeline where "this route declared a legacy id" is
  # knowable — so doctor's advisory finding is the only honest surface for
  # this nudge (D-59). Do not "improve" this into a compile-time warning —
  # there is no hook to attach one to.
  defp legacy_capability_id_findings(nil), do: []

  defp legacy_capability_id_findings(manifest) do
    family_id_by_legacy_id =
      manifest.capability_registry
      |> Map.values()
      |> Enum.flat_map(fn capability ->
        Enum.map(capability.legacy_ids, &{&1, capability.id})
      end)
      |> Map.new()

    manifest.routes
    |> Map.values()
    |> Enum.flat_map(fn route ->
      route.capabilities
      |> Enum.filter(&Map.has_key?(family_id_by_legacy_id, &1))
      |> Enum.map(&legacy_capability_id_finding(route, &1, family_id_by_legacy_id))
    end)
  end

  # D-49: the one genuinely missing CTRL-05 leg — doctor had no capability-level
  # rebuild finding at all (capability_posture_findings/1 groups by proof_class
  # only, and native_rebuild_findings/2 is fed exclusively by commerce
  # corridors). A developer with a rebuild: :native_required or
  # :companion_required capability declared on a route now gets named rebuild
  # guidance, mirroring native_rebuild_findings/2's exact
  # check(:warning, code, subject, message, hint, details) shape (no new
  # aggregation mechanism).
  #
  # Scoped to capabilities that are BOTH non-:none rebuild AND declared on at
  # least one route in the compiled manifest — a capability the developer has
  # not actually taken on gets no warning. Ordering is deterministic (sorted by
  # capability id, then route id) so repeated runs over the same manifest
  # produce identically ordered findings.
  defp capability_rebuild_findings(nil), do: []

  defp capability_rebuild_findings(manifest) do
    routes = Map.values(manifest.routes)

    manifest.capability_registry
    |> Map.values()
    |> Enum.filter(&(&1.rebuild != :none))
    |> Enum.sort_by(& &1.id)
    |> Enum.flat_map(fn capability ->
      routes
      |> Enum.filter(&(capability.id in &1.capabilities))
      |> Enum.sort_by(& &1.id)
      |> Enum.map(&capability_rebuild_finding(&1, capability))
    end)
  end

  defp capability_rebuild_finding(route, capability) do
    check(
      :warning,
      "bridge.capability.native_rebuild_required",
      "route:#{route.id}",
      "route #{route.id} declares capability #{capability.id}, which requires a #{rebuild_shell_label(capability.rebuild)} rebuild before this control ships",
      capability_rebuild_hint(capability.rebuild),
      %{
        route_id: route.id,
        capability_id: capability.id,
        rebuild: Atom.to_string(capability.rebuild)
      }
    )
  end

  defp rebuild_shell_label(:native_required), do: "native"
  defp rebuild_shell_label(:companion_required), do: "companion"

  defp capability_rebuild_hint(:native_required) do
    "rebuild and resubmit the native shell binary before this control can ship — OTA/remote manifest updates cannot satisfy a native rebuild"
  end

  defp capability_rebuild_hint(:companion_required) do
    "publish or upgrade the companion package that backs this capability — this does not require a native shell rebuild"
  end

  defp legacy_capability_id_finding(route, legacy_id, family_id_by_legacy_id) do
    family_id = Map.fetch!(family_id_by_legacy_id, legacy_id)

    check(
      :warning,
      "capability.legacy_capability_id",
      "route:#{route.id}",
      "route #{route.id} declares the legacy capability id #{inspect(legacy_id)}; the family id #{inspect(family_id)} is the vocabulary Crosswake teaches going forward",
      "declare capabilities: [#{inspect(family_id)}] in route policy instead of #{inspect(legacy_id)} — the legacy id keeps authorizing indefinitely (no compile-time warning, no removal); this finding is advisory only and never fails doctor",
      %{
        route_id: route.id,
        legacy_capability_id: legacy_id,
        family_capability_id: family_id
      }
    )
  end

  defp phase_66_generator_drift_findings(nil, _cwd, _opts), do: []

  defp phase_66_generator_drift_findings(manifest, cwd, opts) do
    ios_shell_root = shell_root(:ios, cwd, opts)
    android_shell_root = shell_root(:android, cwd, opts)

    ios_files = [
      Path.join(ios_shell_root, "CrosswakeShell/Info.plist"),
      Path.join(ios_shell_root, "CrosswakeShell/CrosswakeShell.entitlements"),
      Path.join(ios_shell_root, "CrosswakeShell/PrivacyInfo.xcprivacy")
    ]
    android_files = [
      Path.join(android_shell_root, "app/src/main/AndroidManifest.xml")
    ]

    placeholder_findings = 
      (ios_files ++ android_files)
      |> Enum.flat_map(&check_shell_unreplaced_placeholders/1)

    ios_contents = read_all_files(ios_files)
    android_contents = read_all_files(android_files)

    capabilities = Map.keys(manifest.capability_registry || %{})
    
    ios_drift = if ios_contents != "", do: check_drift(capabilities, ios_contents, :ios), else: []
    android_drift = if android_contents != "", do: check_drift(capabilities, android_contents, :android), else: []

    placeholder_findings ++ ios_drift ++ android_drift
  end

  defp check_shell_unreplaced_placeholders(path) do
    case File.read(path) do
      {:ok, contents} ->
        if String.contains?(contents, "ADOPT:") do
          [
            check(
              :error,
              "shell_unreplaced_placeholders",
              "shell_generator",
              "File #{Path.basename(path)} contains unreplaced ADOPT: markers",
              "Replace the ADOPT: markers with your host-owned values in #{path}"
            )
          ]
        else
          []
        end
      _ ->
        []
    end
  end

  defp read_all_files(paths) do
    paths
    |> Enum.map(&File.read/1)
    |> Enum.flat_map(fn 
      {:ok, content} -> [content]
      _ -> []
    end)
    |> Enum.join("\n")
  end

  defp check_drift(capabilities, contents, platform) do
    Enum.flat_map(capabilities, fn cap ->
      expected_strings = capability_expected_strings(cap, platform)
      missing_string = Enum.find(expected_strings, fn str -> not String.contains?(contents, str) end)
      
      if missing_string do
        [
          check(
            :error,
            "shell_permission_drift",
            "shell_generator",
            "Capability #{cap} is declared but missing its required permission/entitlement string in #{platform} native files",
            "Add #{missing_string} to your #{platform} native shell project to satisfy the declared #{cap} capability",
            %{capability: cap, missing: missing_string, platform: platform}
          )
        ]
      else
        []
      end
    end)
  end

  defp capability_expected_strings(cap, :ios) when cap in ["notification_token", "push.notifications"] do
    ["aps-environment", "NSPrivacyCollectedDataTypeDeviceID"]
  end
  defp capability_expected_strings(cap, :android) when cap in ["notification_token", "push.notifications"] do
    ["POST_NOTIFICATIONS"]
  end

  defp capability_expected_strings(cap, :ios) when cap in ["media_capture", "camera", "camera.capture"] do
    ["NSCameraUsageDescription"]
  end
  defp capability_expected_strings(cap, :android) when cap in ["media_capture", "camera", "camera.capture"] do
    ["android.permission.CAMERA"]
  end

  defp capability_expected_strings(cap, :ios) when cap in ["haptics", "haptics.impact"], do: []
  defp capability_expected_strings(cap, :android) when cap in ["haptics", "haptics.impact"] do
    ["android.permission.VIBRATE"]
  end

  defp capability_expected_strings(cap, :ios) when cap in ["file_picker", "files.pick"] do
    ["NSPhotoLibraryUsageDescription"]
  end
  defp capability_expected_strings(cap, :android) when cap in ["file_picker", "files.pick"], do: []

  defp capability_expected_strings("deep_link", :ios) do
    ["com.apple.developer.associated-domains"]
  end
  defp capability_expected_strings("deep_link", :android) do
    ["android.intent.action.VIEW"]
  end

  defp capability_expected_strings(_, _), do: []
end
