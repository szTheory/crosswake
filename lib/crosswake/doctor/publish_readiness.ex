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
      notification_token_readiness_check(inspection),
      auth_session_predicate_readiness_check(support_matrix, inspection),
      native_shell_verification_gap_check(support_matrix, inspection),
      docs_support_parity_check(cwd, opts),
      proof_posture_check(support_matrix, inspection)
    ]
  end

  defp publish_parity_check(cwd, opts) do
    project_config = Keyword.get_lazy(opts, :project_config, &Mix.Project.config/0)
    package = Keyword.get(project_config, :package, [])
    changelog = changelog_contents(cwd, opts)

    errors =
      []
      |> require_truth(
        Keyword.get(project_config, :version) == "0.1.0",
        "mix.exs version must match published 0.1.0 truth"
      )
      |> require_truth(
        Keyword.get(package, :name) == "crosswake",
        "Hex package name must be crosswake"
      )
      |> require_truth(
        is_binary(Keyword.get(project_config, :source_url)),
        "source_url must be present"
      )
      |> require_truth(
        changelog =~ "[Unreleased]",
        "CHANGELOG.md must keep an [Unreleased] section"
      )
      |> require_truth(
        changelog =~ "[0.1.0]",
        "CHANGELOG.md must keep the published [0.1.0] release"
      )

    result_check(
      id: "publish.parity",
      code:
        if(Enum.any?(errors, &String.contains?(&1, "[Unreleased]")),
          do: "diag.publish.changelog_missing_unreleased",
          else: "diag.publish.local_truth"
        ),
      category: :publish_parity,
      passed?: errors == [],
      message:
        if(errors == [],
          do: "local Hex metadata and CHANGELOG.md preserve published-versus-unreleased truth",
          else: "local publish parity failed: #{Enum.join(Enum.reverse(errors), "; ")}"
        ),
      hint:
        "Keep package metadata, links, docs extras, files allowlist, [Unreleased], and [0.1.0] aligned before publishing.",
      docs_reference: "CHANGELOG.md",
      proof_class: :merge_blocking,
      claim_scope: "Hex metadata and release/changelog truth",
      details: %{
        package_name: Keyword.get(package, :name),
        version: Keyword.get(project_config, :version),
        source_url: Keyword.get(project_config, :source_url),
        changelog_sections: changelog_sections(changelog),
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
      code: "diag.provider.adapters_not_shipped",
      category: :provider_adapter_readiness,
      result: :verification_required,
      severity: :warning,
      message:
        "StoreKit and Play Billing provider adapters are not shipped; commerce routes stay seam-only until v3.7 adapters land",
      hint:
        "Keep storefront/provider evidence advisory and route entitlement authority through backend reconciliation.",
      docs_reference: "guides/commerce.md",
      proof_class: :advisory,
      rebuild_requirement: %{
        native_required: true,
        companion_required: false,
        reasons: ["provider SDK adapter implementation is deferred"]
      },
      claim_scope: "Commerce provider adapter readiness",
      details: %{
        shipped?: false,
        deferred: [:storekit, :play_billing, :revenue_cat],
        route_ids: route_ids
      }
    )
  end

  defp notification_token_readiness_check(inspection) do
    route_ids = route_ids_with(inspection, & &1.notifications.token_capability_declared)

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
      claim_scope: "Notification token provider readiness, not notification delivery",
      details: %{
        delivery_supported?: false,
        supported_providers: notification_providers(inspection),
        route_ids: route_ids
      }
    )
  end

  defp auth_session_predicate_readiness_check(support_matrix, inspection) do
    _auth_truth = SupportMatrix.auth_contract_truth()
    _release = SupportMatrix.release_boundaries(support_matrix)
    route_ids = route_ids_with(inspection, &(&1.auth.fallback == :step_up_required))

    advisory_check(
      id: "auth.session_predicate_readiness",
      code: "diag.auth.sigra_contract_only",
      category: :auth_session_predicate_readiness,
      result: if(route_ids == [], do: :pass, else: :verification_required),
      severity: if(route_ids == [], do: :advisory, else: :warning),
      message:
        if(route_ids == [],
          do: "no Sigra auth predicate routes are present in the inspected route set",
          else:
            "Sigra auth/session readiness is contract-only; handoff, ceremony, passkey, OAuth, and refresh-token machinery are not shipped"
        ),
      hint:
        "Keep auth predicates backend-owned and fail closed with step_up_required until full Sigra machinery ships.",
      docs_reference: "guides/companions.md",
      proof_class: if(route_ids == [], do: :not_applicable, else: :advisory),
      claim_scope: "Sigra auth predicate readiness",
      details: %{
        posture: :contract_only,
        fallback: :step_up_required,
        deferred: [:handoff, :ceremony, :passkey, :oauth, :refresh_tokens, :native_auth_ui],
        route_ids: route_ids
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
        reasons: rebuild_reasons(inspection)
      },
      claim_scope: "Native shell verification and rebuild readiness",
      details: %{
        support_status: android_shell && android_shell.status,
        proof_status: android_shell && android_shell.proof_status,
        route_ids: route_ids
      }
    )
  end

  defp docs_support_parity_check(cwd, opts) do
    project_config = Keyword.get_lazy(opts, :project_config, &Mix.Project.config/0)
    docs = Keyword.get(project_config, :docs, [])
    extras = Keyword.get(docs, :extras, [])
    missing = Enum.reject(@allowed_docs, &(&1 in extras or &1 == "CHANGELOG.md"))
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

  defp routes(nil), do: []
  defp routes(%{routes: routes}) when is_map(routes), do: Map.to_list(routes)

  defp route_ids(routes), do: Enum.map(routes, fn {id, _route} -> id end)

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
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value), do: value
end
