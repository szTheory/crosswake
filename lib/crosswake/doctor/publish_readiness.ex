defmodule Crosswake.Doctor.PublishReadiness do
  @moduledoc """
  Deterministic release/support readiness checks for `mix crosswake.doctor --check-publish`.

  The report is a sidecar contract: route readiness is derived through
  `Crosswake.OperatorInspection`, while support vocabulary comes from
  `Crosswake.SupportMatrix`. It does not replace doctor findings or the
  route-authoritative `mix crosswake.inspect` inventory.
  """

  alias Crosswake.Doctor.Check
  alias Crosswake.OperatorInspection
  alias Crosswake.SupportMatrix

  @schema_version "1.0.0"
  @allowed_docs [
    "guides/support_matrix.md",
    "guides/compatibility.md",
    "guides/companions.md",
    "guides/commerce.md",
    "guides/native_shell.md",
    "guides/capabilities.md",
    "guides/install.md",
    "guides/adoption.md",
    "CHANGELOG.md"
  ]

  defmodule Report do
    @moduledoc false

    @enforce_keys [:schema_version, :status, :summary, :checks]
    defstruct [:schema_version, :status, :summary, :checks]

    @type t :: %__MODULE__{
            schema_version: String.t(),
            status: :ready | :not_ready,
            summary: map(),
            checks: [Crosswake.Doctor.PublishReadiness.ReadinessCheck.t()]
          }
  end

  defmodule ReadinessCheck do
    @moduledoc false

    @enforce_keys [
      :id,
      :code,
      :category,
      :severity,
      :result,
      :blocking,
      :message,
      :hint,
      :docs_reference,
      :proof_class,
      :rebuild_requirement,
      :claim_scope,
      :details
    ]
    defstruct [
      :id,
      :code,
      :category,
      :severity,
      :result,
      :blocking,
      :message,
      :hint,
      :docs_reference,
      :proof_class,
      :rebuild_requirement,
      :claim_scope,
      :details
    ]

    @type result :: :pass | :fail | :verification_required | :advisory

    @type t :: %__MODULE__{
            id: String.t(),
            code: String.t(),
            category: atom(),
            severity: Check.severity(),
            result: result(),
            blocking: boolean(),
            message: String.t(),
            hint: String.t(),
            docs_reference: String.t(),
            proof_class: :merge_blocking | :advisory | :not_applicable,
            rebuild_requirement: map(),
            claim_scope: String.t(),
            details: map()
          }
  end

  @spec run(keyword()) :: Report.t()
  def run(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    support_matrix = Keyword.get_lazy(opts, :support_matrix, &SupportMatrix.canonical/0)
    inspection = inspection(opts)
    checks = build_checks(cwd, support_matrix, inspection, opts)
    status = if Enum.any?(checks, & &1.blocking), do: :not_ready, else: :ready

    %Report{
      schema_version: @schema_version,
      status: status,
      summary: summary(checks),
      checks: checks
    }
  end

  @spec findings(Report.t()) :: [Check.t()]
  def findings(%Report{} = report) do
    report.checks
    |> Enum.reject(&(&1.result == :pass))
    |> Enum.map(fn check ->
      %Check{
        severity: check.severity,
        code: check.code,
        check: Atom.to_string(check.category),
        message: check.message,
        hint: check.hint,
        details: %{
          id: check.id,
          blocking: check.blocking,
          result: check.result,
          docs_reference: check.docs_reference,
          proof_class: check.proof_class,
          rebuild_requirement: check.rebuild_requirement,
          claim_scope: check.claim_scope,
          readiness_details: check.details
        }
      }
    end)
  end

  @spec to_map(Report.t()) :: map()
  def to_map(%Report{} = report) do
    %{
      "schema_version" => report.schema_version,
      "status" => Atom.to_string(report.status),
      "summary" => atomize_values(report.summary),
      "checks" => Enum.map(report.checks, &check_to_map/1)
    }
  end

  defp inspection(opts) do
    cond do
      inspection = Keyword.get(opts, :inspection) ->
        inspection

      manifest = Keyword.get(opts, :manifest) ->
        OperatorInspection.from_manifest(manifest, opts)

      route_source = Keyword.get(opts, :route_source) ->
        OperatorInspection.inspect(Keyword.put(opts, :route_source, route_source))

      true ->
        nil
    end
  end

  defp build_checks(cwd, support_matrix, inspection, opts) do
    [
      publish_parity_check(cwd, opts),
      companion_dependency_health_check(inspection),
      provider_adapter_readiness_check(support_matrix, inspection),
      notification_token_readiness_check(support_matrix, inspection),
      auth_session_predicate_readiness_check(support_matrix, inspection),
      native_shell_verification_gap_check(support_matrix, inspection),
      docs_support_parity_check(cwd, opts),
      proof_posture_check(support_matrix, inspection),
      generator_coordinate_parity_check(cwd),
      contract_version_parity_check(cwd)
    ]
  end

  defp publish_parity_check(cwd, opts) do
    project_config = Keyword.get_lazy(opts, :project_config, &Mix.Project.config/0)
    package = Keyword.get(project_config, :package, [])
    expected_version = Keyword.get(project_config, :version)
    source_url = Keyword.get(project_config, :source_url)
    changelog = changelog_contents(cwd, opts)

    errors =
      []
      |> require_truth(
        is_binary(expected_version) and expected_version != "",
        "mix.exs version must be set"
      )
      |> require_truth(
        Keyword.get(package, :name) == "crosswake",
        "Hex package name must be crosswake"
      )
      |> require_truth(
        valid_source_url?(source_url),
        "source_url must be a non-empty https URL"
      )
      |> require_truth(
        changelog =~ "[Unreleased]",
        "CHANGELOG.md must keep an [Unreleased] section"
      )
      |> require_truth(
        unreleased_split?(changelog),
        "CHANGELOG.md [Unreleased] must split unpublished support claims, advisory surfaces, deferred non-shipped claims, and published Hex truth"
      )
      |> require_truth(
        published_hex_truth?(changelog),
        "CHANGELOG.md must distinguish planning milestones from published Hex 0.1.0"
      )
      |> require_truth(
        no_false_shipped_claims?(changelog),
        "CHANGELOG.md must not describe deferred provider, auth, notification, or shell work as shipped"
      )
      |> require_truth(
        is_binary(expected_version) and changelog =~ "[#{expected_version}]",
        "CHANGELOG.md must include the current [#{expected_version}] release"
      )

    result_check(
      id: "publish.parity",
      code: publish_parity_code(errors),
      category: :publish_parity,
      passed?: errors == [],
      message:
        if(errors == [],
          do: "local Hex metadata and CHANGELOG.md preserve published-versus-unreleased truth",
          else: "local publish parity failed: #{Enum.join(Enum.reverse(errors), "; ")}"
        ),
      hint:
        "Keep package metadata, links, docs extras, files allowlist, [Unreleased], and [#{expected_version}] aligned before publishing.",
      docs_reference: "CHANGELOG.md",
      proof_class: :merge_blocking,
      claim_scope: "Hex metadata and release/changelog truth",
      details: %{
        package_name: Keyword.get(package, :name),
        version: expected_version,
        source_url: source_url,
        changelog_sections: changelog_sections(changelog),
        unreleased_subsections: unreleased_subsections(changelog),
        errors: Enum.reverse(errors)
      }
    )
  end

  defp companion_dependency_health_check(inspection) do
    routes = routes(inspection)
    companion_routes = Enum.filter(routes, fn {_id, route} -> route.companion.gated_by != nil end)

    if companion_routes == [] do
      advisory_check(
        id: "companion.dependency_health",
        code: "diag.companion.no_bound_routes",
        category: :companion_dependency_health,
        result: :pass,
        severity: :advisory,
        message: "no companion-gated routes are present in the inspected route set",
        hint: "Run this check against the host router that declares companion-gated routes.",
        docs_reference: "guides/companions.md",
        proof_class: :not_applicable,
        claim_scope: "First-party companion dependency health",
        details: %{route_ids: []}
      )
    else
      advisory_check(
        id: "companion.dependency_health",
        code: "diag.companion.dependency_verification_required",
        category: :companion_dependency_health,
        result: :verification_required,
        severity: :warning,
        message:
          "companion-gated routes require dependency and gate-state verification before publish",
        hint:
          "Confirm optional companion dependencies, gate state, and fail-closed fallback posture.",
        docs_reference: "guides/companions.md",
        proof_class: :advisory,
        claim_scope: "First-party companion dependency health",
        details: %{
          route_ids: route_ids(companion_routes),
          companions:
            companion_routes
            |> Enum.map(fn {_id, route} -> route.companion.gated_by end)
            |> Enum.uniq()
        }
      )
    end
  end

  defp provider_adapter_readiness_check(support_matrix, inspection) do
    _canonical = SupportMatrix.commerce_corridors()
    _packages = SupportMatrix.package_surfaces(support_matrix)
    route_ids = route_ids_with(inspection, fn route -> not is_nil(route.commerce) end)

    advisory_check(
      id: "provider.adapter_readiness",
      code: "diag.provider.adapter_shipped_seams",
      category: :provider_adapter_readiness,
      result: :verification_required,
      severity: :warning,
      message:
        "StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass",
      hint:
        "Keep storefront/provider evidence advisory and route entitlement authority through backend reconciliation.",
      docs_reference: "guides/commerce.md",
      proof_class: :advisory,
      rebuild_requirement: %{
        native_required: true,
        companion_required: false,
        reasons: ["provider SDK proof remains advisory until promotion criteria pass"],
        action_classes: ["provider_adapter"]
      },
      claim_scope: "Commerce provider adapter readiness",
      details: %{
        shipped_seams?: true,
        advisory_provider_proof?: true,
        storekit_check_id: "diag.provider.storekit.advisory_proof",
        play_billing_check_id: "diag.provider.play_billing.advisory_proof",
        setup_required: ["storekit_sandbox_account", "play_billing_license_tester"],
        native_rebuild_required?: true,
        deferred: [:revenue_cat],
        route_ids: route_ids,
        promotion_rule_ids: promotion_rule_ids(provider_adapter_claim_ids()),
        required_docs_anchors: required_docs_anchors(provider_adapter_claim_ids()),
        demotion_trigger: demotion_trigger(provider_adapter_claim_ids())
      }
    )
  end

  defp notification_token_readiness_check(_support_matrix, inspection) do
    route_ids = route_ids_with(inspection, & &1.notifications.token_capability_declared)
    claim_ids = ["notification_token.provider_snapshot"]

    advisory_check(
      id: "notification.token_readiness",
      code: "diag.notification.token_provider_snapshot_only",
      category: :notification_token_readiness,
      result: if(route_ids == [], do: :pass, else: :verification_required),
      severity: if(route_ids == [], do: :advisory, else: :warning),
      message:
        if(route_ids == [],
          do: "no notification-token routes are present in the inspected route set",
          else:
            "notification_token readiness is provider snapshot only; Chimeway delivery is not supported in v3.6"
        ),
      hint:
        "Use notification token posture for readiness diagnostics only; delivery integration is deferred to Chimeway.",
      docs_reference: "guides/capabilities.md",
      proof_class: if(route_ids == [], do: :not_applicable, else: :advisory),
      rebuild_requirement: %{
        native_required: false,
        companion_required: route_ids != [],
        reasons: [
          "notification_token provider snapshot readiness requires companion-native proof"
        ],
        action_classes: ["companion_native"]
      },
      claim_scope: "Notification token provider readiness, not notification delivery",
      details: %{
        delivery_supported?: false,
        supported_providers: notification_providers(inspection),
        route_ids: route_ids,
        promotion_rule_ids: if(route_ids == [], do: [], else: promotion_rule_ids(claim_ids)),
        required_docs_anchors:
          if(route_ids == [], do: [], else: required_docs_anchors(claim_ids)),
        demotion_trigger: if(route_ids == [], do: nil, else: demotion_trigger(claim_ids))
      }
    )
  end

  defp auth_session_predicate_readiness_check(support_matrix, inspection) do
    auth_truth = SupportMatrix.auth_contract_truth()
    auth_row = List.first(auth_truth, %{})
    _release = SupportMatrix.release_boundaries(support_matrix)
    route_ids = route_ids_with(inspection, &(&1.auth.fallback == :step_up_required))
    claim_ids = ["auth.sigra.session_authority"]

    advisory_check(
      id: "auth.session_predicate_readiness",
      code: "diag.auth.sigra_session_authority",
      category: :auth_session_predicate_readiness,
      result: if(route_ids == [], do: :pass, else: :verification_required),
      severity: if(route_ids == [], do: :advisory, else: :warning),
      message:
        if(route_ids == [],
          do: "no Sigra auth predicate routes are present in the inspected route set",
          else:
            "Sigra session-authority route evaluation, handoff ticket/server-record contract machinery, step-up intent plus Plug/LiveView ceremony, OAuth/passkey/native auth-return boundary contracts are shipped, and stable auth telemetry plus security closeout are shipped; refresh-token helpers, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI are not shipped"
        ),
      hint:
        "Keep auth predicates, handoff redemption, step-up completion, auth-return validation, telemetry, and security closeout backend-owned or evidence-only; fail closed with step_up_required.",
      docs_reference: "guides/companions.md",
      proof_class: if(route_ids == [], do: :not_applicable, else: :advisory),
      rebuild_requirement: %{
        native_required: false,
        companion_required: route_ids != [],
        reasons: ["Sigra session-authority route evaluation requires companion support truth"],
        action_classes: ["companion_native"]
      },
      claim_scope: "Sigra session-authority route readiness",
      details: %{
        posture: :session_authority,
        fallback: :step_up_required,
        shipped_contracts: Map.get(auth_row, :shipped_contracts, []),
        handoff: Map.get(auth_row, :handoff, %{}),
        step_up: Map.get(auth_row, :step_up, %{}),
        auth_return: Map.get(auth_row, :auth_return, %{}),
        contract_surface: Map.get(auth_row, :contract_surface),
        contract_proof_class: Map.get(auth_row, :contract_proof_class),
        route_authority_source: Map.get(auth_row, :route_authority_source),
        evidence_authority: Map.get(auth_row, :evidence_authority, %{}),
        host_readiness: Map.get(auth_row, :host_readiness),
        provider_device_proof: Map.get(auth_row, :provider_device_proof),
        telemetry:
          auth_row
          |> Map.get(:telemetry, %{})
          |> Map.drop([:forbidden_metadata_keys]),
        security_closeout: Map.get(auth_row, :security_closeout, %{}),
        route_predicates: Map.get(auth_row, :route_predicates, []),
        denial_codes: Map.get(auth_row, :denial_codes, []),
        safe_detail_keys: Map.get(auth_row, :safe_detail_keys, []),
        deferred: Map.get(auth_row, :deferred, []),
        route_ids: route_ids,
        promotion_rule_ids: if(route_ids == [], do: [], else: promotion_rule_ids(claim_ids)),
        required_docs_anchors:
          if(route_ids == [], do: [], else: required_docs_anchors(claim_ids)),
        demotion_trigger: if(route_ids == [], do: nil, else: demotion_trigger(claim_ids))
      }
    )
  end

  defp native_shell_verification_gap_check(support_matrix, inspection) do
    route_ids =
      route_ids_with(inspection, fn route ->
        route.rebuild.native_required or route.rebuild.companion_required or
          route.support.status == :verification_required
      end)

    android_shell =
      support_matrix
      |> Map.get(:shells, [])
      |> Enum.find(&(&1.target == "android_shell"))

    claim_ids = ["shell.ios.generated_project", "shell.android.generated_project"]

    advisory_check(
      id: "shell.native_verification_gap",
      code: "diag.shell.verification_required",
      category: :native_shell_verification_gap,
      result: :verification_required,
      severity: :warning,
      message:
        "native shell support is verification-required where route rebuild, Android shell, or companion/provider posture applies",
      hint:
        "Run generated-shell proof and document rebuild requirements before claiming fully verified native support.",
      docs_reference: "guides/native_shell.md",
      proof_class: :advisory,
      rebuild_requirement: %{
        native_required: route_ids != [],
        companion_required: companion_rebuild?(inspection),
        reasons: rebuild_reasons(inspection),
        action_classes: rebuild_action_classes(inspection, ["native_shell"])
      },
      claim_scope: "Native shell verification and rebuild readiness",
      details: %{
        support_status: android_shell && android_shell.status,
        proof_status: android_shell && android_shell.proof_status,
        route_ids: route_ids,
        promotion_rule_ids: promotion_rule_ids(claim_ids),
        required_docs_anchors: required_docs_anchors(claim_ids),
        demotion_trigger: demotion_trigger(claim_ids)
      }
    )
  end

  defp docs_support_parity_check(cwd, opts) do
    project_config = Keyword.get_lazy(opts, :project_config, &Mix.Project.config/0)
    docs = Keyword.get(project_config, :docs, [])
    extras = Keyword.get(docs, :extras, [])
    missing = Enum.reject(@allowed_docs, &(&1 in extras))
    missing_files = Enum.reject(@allowed_docs, &File.exists?(Path.join(cwd, &1)))

    result_check(
      id: "docs.support_parity",
      code:
        if(missing == [] and missing_files == [],
          do: "diag.docs.support_parity",
          else: "diag.docs.support_parity_missing"
        ),
      category: :docs_support_parity,
      passed?: missing == [] and missing_files == [],
      message:
        if(missing == [] and missing_files == [],
          do: "docs extras and support guidance cover the v3.6 readiness claim surface",
          else:
            "docs/support parity is incomplete for #{Enum.join(missing ++ missing_files, ", ")}"
        ),
      hint:
        "Keep support, compatibility, companions, commerce, native shell, capabilities, install, and changelog guidance in docs extras.",
      docs_reference: "guides/support_matrix.md",
      proof_class: :merge_blocking,
      claim_scope: "Docs/support parity",
      details: %{docs_extras: extras, missing_docs_extras: missing, missing_files: missing_files}
    )
  end

  defp proof_posture_check(support_matrix, inspection) do
    _canonical = SupportMatrix.canonical()
    route_ids = route_ids_with(inspection, &(&1.support.proof_class == :advisory))
    commerce = SupportMatrix.commerce_corridors()

    advisory_check(
      id: "proof.posture",
      code: "diag.docs.proof_posture_advisory_surfaces",
      category: :proof_posture,
      result: if(route_ids == [], do: :pass, else: :advisory),
      severity: if(route_ids == [], do: :advisory, else: :warning),
      message:
        if(route_ids == [],
          do: "inspected route proof posture has no advisory route surfaces",
          else:
            "advisory proof surfaces remain visible and are not equivalent to supported status"
        ),
      hint:
        "Keep hermetic merge-blocking proof separate from provider, storefront, device, and shell advisory checks.",
      docs_reference: "guides/support_matrix.md",
      proof_class: if(route_ids == [], do: :merge_blocking, else: :advisory),
      claim_scope: "Proof posture and advisory promotion readiness",
      details: %{
        advisory_route_ids: route_ids,
        commerce_advisory_provider_proof:
          Enum.filter(commerce, & &1.advisory_provider_proof) |> Enum.map(& &1.corridor_role),
        release_boundaries:
          SupportMatrix.release_boundaries(support_matrix) |> Enum.map(& &1.target)
      }
    )
  end

  defp generator_coordinate_parity_check(cwd) do
    version = Application.spec(:crosswake, :vsn) |> to_string()

    ios_template_relative =
      "priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex"

    android_template_relative = "priv/templates/crosswake/shell/android/app/build.gradle.eex"
    ios_template = Path.join(cwd, ios_template_relative)
    android_template = Path.join(cwd, android_template_relative)

    {_ios_ok?, ios_errors} = check_ios_template(ios_template, version)
    {_android_ok?, android_errors} = check_android_template(android_template, version)
    errors = ios_errors ++ android_errors

    result_check(
      id: "generator.coordinate_parity",
      code:
        if(errors == [],
          do: "diag.generator.coordinate_parity_ok",
          else: "diag.generator.coordinate_parity_failed"
        ),
      category: :generator_coordinate_parity,
      passed?: errors == [],
      message:
        if(errors == [],
          do:
            "generated native dep coordinates point at published registries with version #{version}",
          else: "generator coordinate parity failed: #{Enum.join(errors, "; ")}"
        ),
      hint:
        "Run mix crosswake.gen.shell ios|android (without --local) and inspect the generated dep coordinates.",
      docs_reference: "guides/install.md",
      proof_class: :merge_blocking,
      claim_scope: "Generated native dep coordinate truth",
      details: %{
        version: version,
        ios_template: ios_template_relative,
        android_template: android_template_relative,
        errors: errors
      }
    )
  end

  # Surface paths for the contract_version_parity_check.
  # Manifests: bridge_protocol_version lives at ["compatibility"]["bridge_protocol_version"].
  # Generated JSONs: bridge_protocol_version lives at the document root.
  @manifest_surfaces [
    "examples/ios_shell_host/Fixtures/crosswake_manifest.json",
    "examples/android_shell_host/app/src/main/assets/crosswake_manifest.json"
  ]
  @generated_json_surfaces [
    "examples/ios_shell_host/Fixtures/route_activation.json",
    "examples/android_shell_host/app/src/main/assets/route_activation.json",
    "test/fixtures/bridge_contract_vectors.json"
  ]
  @all_contract_surfaces @manifest_surfaces ++ @generated_json_surfaces

  defp contract_version_parity_check(cwd) do
    expected = Crosswake.Bridge.Contract.version()

    manifest_errors =
      Enum.flat_map(@manifest_surfaces, fn rel ->
        path = Path.join(cwd, rel)

        case File.read(path) do
          {:ok, contents} ->
            case Jason.decode(contents) do
              {:ok, decoded} ->
                actual = get_in(decoded, ["compatibility", "bridge_protocol_version"])

                if actual == expected do
                  []
                else
                  ["#{rel}: found #{inspect(actual)}, expected #{inspect(expected)}"]
                end

              {:error, reason} ->
                ["#{rel}: JSON decode failed — #{inspect(reason)}"]
            end

          {:error, reason} ->
            ["#{rel}: file read failed — #{inspect(reason)}"]
        end
      end)

    generated_errors =
      Enum.flat_map(@generated_json_surfaces, fn rel ->
        path = Path.join(cwd, rel)

        case File.read(path) do
          {:ok, contents} ->
            case Jason.decode(contents) do
              {:ok, decoded} ->
                actual = decoded["bridge_protocol_version"]

                if actual == expected do
                  []
                else
                  ["#{rel}: found #{inspect(actual)}, expected #{inspect(expected)}"]
                end

              {:error, reason} ->
                ["#{rel}: JSON decode failed — #{inspect(reason)}"]
            end

          {:error, reason} ->
            ["#{rel}: file read failed — #{inspect(reason)}"]
        end
      end)

    errors = manifest_errors ++ generated_errors

    result_check(
      id: "contract.version_parity",
      code:
        if(errors == [],
          do: "diag.contract.version_parity_ok",
          else: "diag.contract.version_parity_failed"
        ),
      category: :contract_version_parity,
      passed?: errors == [],
      message:
        if(errors == [],
          do:
            "all committed contract surfaces carry bridge_protocol_version #{expected}",
          else: "contract version parity failed: #{Enum.join(errors, "; ")}"
        ),
      hint: "Run mix crosswake.contract.gen and commit the regenerated surfaces. Hand-maintained crosswake_manifest.json files require manual updates.",
      docs_reference: "guides/compatibility.md",
      proof_class: :merge_blocking,
      claim_scope: "Contract version parity across committed surfaces",
      details: %{
        version: expected,
        surfaces: @all_contract_surfaces,
        errors: errors
      }
    )
  end

  defp check_ios_template(template_path, version) do
    with {:ok, rendered} <- eval_generator_template(template_path, version) do
      errors =
        []
        |> require_truth(
          rendered =~ "github.com/szTheory/crosswake-shell-core-ios",
          "iOS URL missing szTheory org"
        )
        |> require_truth(
          rendered =~ version,
          "iOS template missing version #{version}"
        )
        |> require_truth(
          rendered =~ "upToNextMajorVersion",
          "iOS template must use upToNextMajorVersion"
        )
        |> require_truth(
          not (rendered =~ "XCLocalSwiftPackageReference"),
          "iOS non-local branch must not emit XCLocalSwiftPackageReference"
        )
        |> require_truth(
          not (rendered =~ "crosswake/crosswake-shell-core-ios"),
          "iOS template must not reference old crosswake/ org"
        )

      {errors == [], Enum.reverse(errors)}
    else
      {:error, reason} -> {false, ["iOS template could not render: #{reason}"]}
    end
  end

  defp check_android_template(template_path, version) do
    with {:ok, rendered} <- eval_generator_template(template_path, version) do
      errors =
        []
        |> require_truth(
          rendered =~ "io.github.sztheory:crosswake-shell-core-android",
          "Android GAV missing io.github.sztheory"
        )
        |> require_truth(
          rendered =~ version,
          "Android template missing version #{version}"
        )
        |> require_truth(
          not (rendered =~ "dev.crosswake:shell-core-android"),
          "Android template must not reference dev.crosswake:shell-core-android"
        )
        |> require_truth(
          not (rendered =~ "project(':crosswake"),
          "Android non-local branch must not reference local project"
        )

      {errors == [], Enum.reverse(errors)}
    else
      {:error, reason} -> {false, ["Android template could not render: #{reason}"]}
    end
  end

  defp eval_generator_template(template_path, version) do
    {:ok,
     EEx.eval_file(template_path, assigns: [local: false, version: version, capabilities: []])}
  rescue
    error -> {:error, Exception.message(error)}
  end

  defp provider_adapter_claim_ids do
    [
      "purchase_intent.provider.storekit",
      "purchase_intent.provider.play_billing",
      "restore_intent.provider.storekit",
      "restore_intent.provider.play_billing"
    ]
  end

  defp promotion_rule_ids(claim_ids) do
    claim_ids
    |> promotion_rules_for()
    |> Enum.map(& &1.claim_id)
  end

  defp required_docs_anchors(claim_ids) do
    claim_ids
    |> promotion_rules_for()
    |> Enum.flat_map(& &1.required_docs_anchors)
    |> Enum.uniq()
  end

  defp demotion_trigger(claim_ids) do
    claim_ids
    |> promotion_rules_for()
    |> Enum.map(& &1.demotion_trigger)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp promotion_rules_for(claim_ids) do
    claim_ids = MapSet.new(claim_ids)
    Enum.filter(SupportMatrix.promotion_rules(), &(&1.claim_id in claim_ids))
  end

  defp result_check(opts) do
    passed? = Keyword.fetch!(opts, :passed?)

    check(
      Keyword.merge(opts,
        result: if(passed?, do: :pass, else: :fail),
        severity: if(passed?, do: :advisory, else: :error),
        blocking: not passed?
      )
    )
  end

  defp advisory_check(opts) do
    severity = Keyword.fetch!(opts, :severity)
    result = Keyword.fetch!(opts, :result)
    check(Keyword.put(opts, :blocking, severity == :error and result == :fail))
  end

  defp check(opts) do
    %ReadinessCheck{
      id: Keyword.fetch!(opts, :id),
      code: Keyword.fetch!(opts, :code),
      category: Keyword.fetch!(opts, :category),
      severity: Keyword.fetch!(opts, :severity),
      result: Keyword.fetch!(opts, :result),
      blocking: Keyword.fetch!(opts, :blocking),
      message: Keyword.fetch!(opts, :message),
      hint: Keyword.fetch!(opts, :hint),
      docs_reference: Keyword.fetch!(opts, :docs_reference),
      proof_class: Keyword.fetch!(opts, :proof_class),
      rebuild_requirement:
        Keyword.get(opts, :rebuild_requirement, %{
          native_required: false,
          companion_required: false,
          reasons: []
        }),
      claim_scope: Keyword.fetch!(opts, :claim_scope),
      details: Keyword.fetch!(opts, :details)
    }
  end

  defp require_truth(errors, true, _message), do: errors
  defp require_truth(errors, false, message), do: [message | errors]

  defp publish_parity_code([]), do: "diag.publish.local_truth"

  defp publish_parity_code(errors) do
    if Enum.any?(errors, &String.contains?(&1, "[Unreleased]")) do
      "diag.publish.changelog_missing_unreleased"
    else
      "diag.publish.local_truth_failed"
    end
  end

  defp valid_source_url?(source_url) when is_binary(source_url) do
    case URI.parse(source_url) do
      %URI{scheme: "https", host: host} when is_binary(host) ->
        source_url != "" and host != ""

      _other ->
        false
    end
  end

  defp valid_source_url?(_source_url), do: false

  defp changelog_contents(cwd, opts) do
    Keyword.get_lazy(opts, :changelog_contents, fn ->
      case cwd |> Path.join("CHANGELOG.md") |> File.read() do
        {:ok, contents} -> contents
        {:error, _reason} -> ""
      end
    end)
  end

  defp changelog_sections(contents) do
    Regex.scan(~r/^## \[([^\]]+)\]/m, contents)
    |> Enum.map(fn [_full, section] -> section end)
  end

  defp unreleased_split?(contents) do
    required = [
      "Unpublished support claims",
      "Verification-required and advisory surfaces",
      "Deferred non-shipped claims",
      "Published Hex truth"
    ]

    subsections = unreleased_subsections(contents)
    Enum.all?(required, &(&1 in subsections))
  end

  defp unreleased_subsections(contents) do
    contents
    |> changelog_section("## [Unreleased]")
    |> then(&Regex.scan(~r/^### (.+)$/m, &1))
    |> Enum.map(fn [_full, heading] -> heading end)
  end

  defp published_hex_truth?(contents) do
    String.contains?(contents, "published Hex release") and
      String.contains?(contents, "planning milestones") and
      String.contains?(contents, "## [0.1.0]")
  end

  defp no_false_shipped_claims?(contents) do
    false_claims = [
      "StoreKit provider adapter shipped",
      "Play Billing provider adapter shipped",
      "Chimeway delivery is supported",
      "standalone native shell packages are shipped",
      "full Sigra machinery is shipped"
    ]

    Enum.all?(false_claims, &(not String.contains?(contents, &1)))
  end

  defp changelog_section(contents, heading) do
    pattern = ~r/^#{Regex.escape(heading)}\r?\n(.*?)(?=^## \[|\z)/ms

    case Regex.run(pattern, contents, capture: :all_but_first) do
      [section] -> section
      nil -> ""
    end
  end

  defp routes(nil), do: []

  defp routes(%{routes: routes}) when is_map(routes) do
    routes
    |> Map.to_list()
    |> Enum.sort_by(fn {id, _route} -> to_string(id) end)
  end

  defp route_ids(routes) do
    routes
    |> Enum.map(fn {id, _route} -> id end)
    |> Enum.sort()
  end

  defp route_ids_with(inspection, fun) do
    inspection
    |> routes()
    |> Enum.filter(fn {_id, route} -> fun.(route) end)
    |> route_ids()
  end

  defp notification_providers(nil), do: []

  defp notification_providers(inspection) do
    inspection
    |> routes()
    |> Enum.flat_map(fn {_id, route} -> route.notifications.supported_providers || [] end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp companion_rebuild?(inspection) do
    inspection
    |> routes()
    |> Enum.any?(fn {_id, route} -> route.rebuild.companion_required end)
  end

  defp rebuild_reasons(nil), do: []

  defp rebuild_reasons(inspection) do
    inspection
    |> routes()
    |> Enum.flat_map(fn {_id, route} -> route.rebuild.reasons end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp rebuild_action_classes(nil, fallback), do: fallback

  defp rebuild_action_classes(inspection, fallback) do
    action_classes =
      inspection
      |> routes()
      |> Enum.flat_map(fn {_id, route} -> Map.get(route.rebuild, :action_classes, []) end)
      |> Enum.uniq()
      |> Enum.sort()

    if action_classes == [], do: fallback, else: action_classes
  end

  defp summary(checks) do
    %{
      total_count: length(checks),
      blocking_count: Enum.count(checks, & &1.blocking),
      error_count: Enum.count(checks, &(&1.severity == :error)),
      warning_count: Enum.count(checks, &(&1.severity == :warning)),
      advisory_count: Enum.count(checks, &(&1.severity == :advisory)),
      pass_count: Enum.count(checks, &(&1.result == :pass)),
      verification_required_count: Enum.count(checks, &(&1.result == :verification_required)),
      advisory_result_count: Enum.count(checks, &(&1.result == :advisory))
    }
  end

  defp check_to_map(%ReadinessCheck{} = check) do
    %{
      "id" => check.id,
      "code" => check.code,
      "category" => Atom.to_string(check.category),
      "severity" => Atom.to_string(check.severity),
      "result" => Atom.to_string(check.result),
      "blocking" => check.blocking,
      "message" => check.message,
      "hint" => check.hint,
      "docs_reference" => check.docs_reference,
      "proof_class" => Atom.to_string(check.proof_class),
      "rebuild_requirement" => stringify(check.rebuild_requirement),
      "claim_scope" => check.claim_scope,
      "details" => stringify(check.details)
    }
  end

  defp atomize_values(map) when is_map(map), do: stringify(map)

  defp stringify(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify()

  defp stringify(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), stringify(value)} end)
    |> Map.new()
  end

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
  defp stringify(value) when is_boolean(value), do: value
  defp stringify(nil), do: nil
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: value
end
