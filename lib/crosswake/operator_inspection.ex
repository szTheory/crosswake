defmodule Crosswake.OperatorInspection do
  @moduledoc """
  Route-authoritative operator inspection contract.
  """

  import Kernel, except: [inspect: 1]

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Doctor.Check
  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types, as: ManifestTypes
  alias Crosswake.OperatorInspection.Types
  alias Crosswake.SupportMatrix

  @spec inspect(keyword()) :: Types.Document.t()
  def inspect(opts) when is_list(opts) do
    route_source = Keyword.fetch!(opts, :route_source)

    case Manifest.compile(route_source, opts) do
      {:ok, %{manifest: manifest}} ->
        from_manifest(manifest, opts)

      {:error, diagnostic} ->
        raise ArgumentError,
              "could not compile Crosswake manifest for inspection: #{Kernel.inspect(diagnostic)}"
    end
  end

  @spec from_manifest(ManifestTypes.Root.t(), keyword()) :: Types.Document.t()
  def from_manifest(%ManifestTypes.Root{} = manifest, opts \\ []) do
    route_entries =
      manifest.routes
      |> Enum.sort_by(fn {route_id, _route} -> route_id end)
      |> Enum.map(fn {route_id, route} -> {route_id, inspect_route(route, manifest)} end)
      |> Map.new()

    findings = route_entries |> findings_from_routes() |> Enum.sort_by(&{&1.check, &1.code})

    Types.document(
      generated_at: generated_at(opts),
      crosswake_version: manifest.crosswake_version,
      source: source(manifest),
      summary: summary(route_entries, findings),
      routes: route_entries,
      indexes: indexes(route_entries),
      findings: findings,
      provenance: provenance(opts)
    )
  end

  defp inspect_route(route, manifest) do
    capabilities = Enum.map(route.capabilities, &capability_entry(&1, manifest))
    commerce = commerce_entry(route, manifest)
    companion = companion_entry(route)
    auth = auth_entry(route)
    notifications = notifications_entry(route)
    rebuild = rebuild_entry(capabilities, commerce, companion)
    denials = denials_entry(capabilities, commerce, companion, auth)
    support = support_entry(capabilities, commerce, companion, auth, notifications, rebuild)

    Types.route(
      id: route.id,
      path: route.path,
      runtime: route.runtime,
      entry: route.entry,
      ownership: ownership_entry(route),
      offline: offline_entry(route),
      capabilities: capabilities,
      commerce: commerce,
      companion: companion,
      auth: auth,
      notifications: notifications,
      support: support,
      rebuild: rebuild,
      denials: denials,
      conditions: conditions(route, support, rebuild, commerce, auth, notifications, companion)
    )
  end

  defp source(manifest) do
    %{
      manifest_schema_version: manifest.manifest_schema_version,
      bridge_protocol_version: manifest.compatibility.bridge_protocol_version,
      native_runtime_version: manifest.compatibility.native_runtime_version
    }
  end

  defp provenance(opts) do
    %{
      generator: "Crosswake.OperatorInspection",
      git_sha: Keyword.get(opts, :git_sha),
      inputs: ["manifest", "support_matrix", "route_policy"]
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp generated_at(opts) do
    opts
    |> Keyword.get_lazy(:generated_at, fn ->
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    end)
    |> case do
      %DateTime{} = dt -> DateTime.to_iso8601(dt)
      other -> other
    end
  end

  defp ownership_entry(route) do
    %{
      owner_plane: owner_plane(route),
      fail_closed: true
    }
  end

  defp owner_plane(%{runtime: :offline_island}), do: :offline_island
  defp owner_plane(%{runtime: :native_screen}), do: :native_screen
  defp owner_plane(%{gated_by: gated_by}) when not is_nil(gated_by), do: :companion
  defp owner_plane(_route), do: :phoenix

  defp offline_entry(route) do
    %{
      mode: route.offline,
      cache_contract: !is_nil(route.cache_contract),
      island_contract: !is_nil(route.island_contract)
    }
  end

  defp capability_entry(capability_id, manifest) do
    capability = Map.get(manifest.capability_registry, capability_id)

    if capability do
      capability
      |> ManifestTypes.to_map()
      |> Map.take([
        "id",
        "family",
        "owner",
        "package_class",
        "proof_class",
        "rebuild",
        "prerequisites",
        "denial",
        "fallback",
        "guide",
        "status"
      ])
    else
      %{
        "id" => capability_id,
        "family" => capability_id,
        "status" => "unsupported",
        "proof_class" => "advisory",
        "rebuild" => "none",
        "denial" => "unavailable_capability",
        "prerequisites" => ["declared route capability"]
      }
    end
  end

  defp commerce_entry(%{commerce: nil}, _manifest), do: nil

  defp commerce_entry(%{commerce: commerce}, manifest) do
    role = commerce.role
    corridor = Map.get(manifest.commerce_corridors, commerce.corridor_ref)
    support_entry = commerce_support_entry(role)

    %{
      corridor_ref: commerce.corridor_ref,
      role: role,
      owner_posture: commerce_owner(corridor, role, support_entry),
      prerequisites: commerce_prerequisites(corridor, support_entry),
      proof_class: support_entry && support_entry.proof_class,
      advisory_provider_proof: support_entry && support_entry.advisory_provider_proof,
      rebuild: commerce_rebuild(support_entry),
      fallback: commerce_fallback(corridor, support_entry),
      denial_codes: commerce_denials(support_entry)
    }
  end

  defp commerce_support_entry(role) do
    role_string = Atom.to_string(role)
    Enum.find(SupportMatrix.commerce_corridors(), &(&1.corridor_role == role_string))
  end

  defp commerce_owner(nil, _role, nil), do: nil

  defp commerce_owner(nil, role, _support_entry),
    do:
      if(role in [:purchase_intent, :restore_intent],
        do: :native_or_companion_required,
        else: :phoenix_owned
      )

  defp commerce_owner(corridor, role, _support_entry), do: Map.get(corridor.role_ownership, role)

  defp commerce_prerequisites(nil, nil), do: []
  defp commerce_prerequisites(nil, support_entry), do: support_entry.prerequisites
  defp commerce_prerequisites(corridor, _support_entry), do: corridor.prerequisites

  defp commerce_rebuild(nil),
    do: %{native_required: false, companion_required: false, reasons: []}

  defp commerce_rebuild(%{
         rebuild_requirement: %{
           native_rebuild_required: native_required,
           rebuild_trigger: trigger
         }
       }) do
    %{
      native_required: native_required,
      companion_required: false,
      reasons: if(native_required, do: [trigger], else: [])
    }
  end

  defp commerce_fallback(nil, nil), do: nil
  defp commerce_fallback(nil, support_entry), do: support_entry.fallback_behavior
  defp commerce_fallback(corridor, _support_entry), do: corridor.fallback

  defp commerce_denials(nil), do: []
  defp commerce_denials(support_entry), do: support_entry.denial_codes

  defp companion_entry(route) do
    state =
      route.gated_by &&
        Enum.find(SupportMatrix.gating_truth(), &(&1.companion_id == route.gated_by))

    %{
      gated_by: route.gated_by,
      on_unavailable: on_unavailable_label(route.on_unavailable),
      gate_state: state && state.gate_state,
      dependency_status: if(route.gated_by, do: :verification_required, else: :not_applicable),
      posture: if(route.gated_by, do: :first_party_typed_companion, else: :not_applicable)
    }
  end

  defp on_unavailable_label({:fallback_phoenix, id}), do: "fallback_phoenix:#{id}"
  defp on_unavailable_label(value), do: value

  defp auth_entry(route) do
    predicated? =
      not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth) or
        not is_nil(route.auth_posture)

    %{
      auth_min_level: route.auth_min_level,
      requires_recent_auth: route.requires_recent_auth,
      auth_posture: route.auth_posture,
      readiness: if(predicated?, do: :verification_required, else: :supported),
      posture: if(predicated?, do: :session_authority, else: :not_applicable),
      fallback: if(predicated?, do: :step_up_required, else: nil),
      denial_codes: if(predicated?, do: Crosswake.Companions.Sigra.DenialCodes.codes(), else: []),
      non_goals:
        if(predicated?,
          do: [:handoff, :ceremony, :passkey, :oauth, :refresh_tokens, :native_auth_ui],
          else: []
        )
    }
  end

  defp notifications_entry(route) do
    declared? = "notification_token" in route.capabilities

    %{
      token_capability_declared: declared?,
      provider_readiness: if(declared?, do: :verification_required, else: :not_applicable),
      posture: if(declared?, do: :provider_snapshot, else: :not_applicable),
      supported_providers: NotificationToken.supported_providers(),
      delivery_supported: false
    }
  end

  defp rebuild_entry(capabilities, commerce, companion) do
    capability_reasons =
      capabilities
      |> Enum.filter(&(&1["rebuild"] in ["native-required", "companion-required"]))
      |> Enum.map(&"capability #{&1["id"]} requires #{&1["rebuild"]}")

    commerce_reasons =
      case commerce do
        %{rebuild: %{reasons: reasons}} -> reasons
        _ -> []
      end

    companion_reasons =
      if companion.gated_by do
        ["companion #{companion.gated_by} binding may require companion verification"]
      else
        []
      end

    reasons = capability_reasons ++ commerce_reasons ++ companion_reasons

    native_required? =
      Enum.any?(capabilities, &(&1["rebuild"] == "native-required")) or
        get_in(commerce || %{}, [:rebuild, :native_required]) == true

    companion_required? =
      Enum.any?(capabilities, &(&1["rebuild"] == "companion-required")) or
        get_in(commerce || %{}, [:rebuild, :companion_required]) == true or
        companion.gated_by != nil

    action_classes =
      []
      |> maybe_action_class(native_required?, "native_shell")
      |> maybe_action_class(commerce && commerce.advisory_provider_proof, "provider_adapter")
      |> maybe_action_class(companion_required?, "companion_native")
      |> Enum.uniq()

    %{
      native_required: native_required?,
      companion_required: companion_required?,
      reasons: Enum.uniq(reasons),
      change_class:
        if(native_required? or companion_required?,
          do: "native or companion rebuild required",
          else: "core-only/no native rebuild"
        ),
      action_classes: if(action_classes == [], do: ["route_manifest"], else: action_classes),
      compatibility_signal:
        cond do
          native_required? -> "native_runtime_version"
          companion_required? -> "companion_dependency"
          true -> "manifest_schema_version"
        end
    }
  end

  defp maybe_action_class(classes, true, action_class), do: classes ++ [action_class]
  defp maybe_action_class(classes, _falsey, _action_class), do: classes

  defp denials_entry(capabilities, commerce, companion, auth) do
    capability_denials = capabilities |> Enum.map(& &1["denial"]) |> Enum.reject(&is_nil/1)
    commerce_denials = (commerce && commerce.denial_codes) || []

    companion_denials =
      if(companion.gated_by, do: ["gate_denied", "kill_switch_active"], else: [])

    auth_denials = if(auth.fallback == :step_up_required, do: ["step_up_required"], else: [])

    (capability_denials ++ commerce_denials ++ companion_denials ++ auth_denials)
    |> Enum.uniq()
    |> Enum.filter(&canonical_denial?/1)
  end

  defp canonical_denial?("commerce.corridor." <> _), do: true

  defp canonical_denial?(reason) do
    reason in Enum.map(Crosswake.Shell.Denial.reasons(), &Atom.to_string/1)
  end

  defp support_entry(capabilities, commerce, companion, auth, notifications, rebuild) do
    capability_statuses = Enum.map(capabilities, & &1["status"])

    verification_required? =
      "verification required" in capability_statuses or
        "verification_required" in capability_statuses or
        get_in(commerce || %{}, [:advisory_provider_proof]) == true or
        companion.gated_by != nil or
        auth.readiness == :verification_required or
        notifications.provider_readiness == :verification_required or
        rebuild.native_required or
        rebuild.companion_required

    unsupported? = "unsupported" in capability_statuses

    proof_class = proof_class(capabilities, commerce, companion, auth, notifications)

    promotion_rule_ids = promotion_rule_ids(commerce, auth, notifications)

    %{
      status:
        cond do
          unsupported? -> :unsupported
          verification_required? -> :verification_required
          true -> :supported
        end,
      proof_class: proof_class,
      advisory_only: proof_class == :advisory,
      promotion_rule_ids: promotion_rule_ids,
      blocking_reasons: blocking_reasons(unsupported?, verification_required?, rebuild)
    }
  end

  defp promotion_rule_ids(commerce, auth, notifications) do
    []
    |> commerce_promotion_rule_ids(commerce)
    |> notification_promotion_rule_ids(notifications)
    |> auth_promotion_rule_ids(auth)
    |> Enum.uniq()
  end

  defp commerce_promotion_rule_ids(ids, %{role: :purchase_intent}) do
    ids ++ ["purchase_intent.provider.storekit", "purchase_intent.provider.play_billing"]
  end

  defp commerce_promotion_rule_ids(ids, %{role: :restore_intent}) do
    ids ++ ["restore_intent.provider.storekit", "restore_intent.provider.play_billing"]
  end

  defp commerce_promotion_rule_ids(ids, _commerce), do: ids

  defp notification_promotion_rule_ids(ids, %{token_capability_declared: true}) do
    ids ++ ["notification_token.provider_snapshot"]
  end

  defp notification_promotion_rule_ids(ids, _notifications), do: ids

  defp auth_promotion_rule_ids(ids, %{fallback: :step_up_required}),
    do: ids ++ ["auth.sigra.contract_only"]

  defp auth_promotion_rule_ids(ids, _auth), do: ids

  defp proof_class(capabilities, commerce, companion, auth, notifications) do
    advisory? =
      Enum.any?(capabilities, &(&1["proof_class"] == "advisory")) or
        get_in(commerce || %{}, [:advisory_provider_proof]) == true or
        companion.gated_by != nil or
        auth.readiness == :verification_required or
        notifications.provider_readiness == :verification_required

    if advisory?, do: :advisory, else: :merge_blocking
  end

  defp blocking_reasons(true, _verification_required?, _rebuild), do: ["unsupported_capability"]

  defp blocking_reasons(false, true, rebuild) do
    if rebuild.native_required or rebuild.companion_required do
      rebuild.reasons
    else
      ["verification_required"]
    end
  end

  defp blocking_reasons(false, false, _rebuild), do: []

  defp conditions(route, support, rebuild, commerce, auth, notifications, companion) do
    [
      Types.condition(
        type: :support_status,
        status: support.status == :supported,
        reason: support.status,
        severity: severity_for_support(support.status),
        message: "route #{route.id} support status is #{support.status}",
        route_id: route.id,
        details: %{support_status: support.status}
      ),
      Types.condition(
        type: :rebuild_required,
        status: not (rebuild.native_required or rebuild.companion_required),
        reason:
          if(rebuild.native_required or rebuild.companion_required,
            do: :rebuild_required,
            else: :none
          ),
        severity:
          if(rebuild.native_required or rebuild.companion_required, do: :warning, else: :advisory),
        message: rebuild_message(route.id, rebuild),
        route_id: route.id,
        details: rebuild
      )
    ] ++ optional_conditions(route, commerce, auth, notifications, companion)
  end

  defp optional_conditions(route, commerce, auth, notifications, companion) do
    []
    |> maybe_condition(commerce_condition(route, commerce))
    |> maybe_condition(auth_condition(route, auth))
    |> maybe_condition(notification_condition(route, notifications))
    |> maybe_condition(companion_condition(route, companion))
  end

  defp maybe_condition(list, nil), do: list
  defp maybe_condition(list, condition), do: list ++ [condition]

  defp commerce_condition(_route, nil), do: nil

  defp commerce_condition(route, commerce) do
    Types.condition(
      type: :commerce_corridor,
      status: commerce.owner_posture in [:phoenix_owned, :native_or_companion_required],
      reason: commerce.role,
      severity: :advisory,
      message: "route #{route.id} declares commerce corridor #{commerce.corridor_ref}",
      route_id: route.id,
      details: commerce
    )
  end

  defp auth_condition(route, %{fallback: :step_up_required} = auth) do
    Types.condition(
      type: :auth_contract,
      status: :unknown,
      reason: :step_up_required,
      severity: :advisory,
      message: "route #{route.id} uses contract-only auth predicates",
      route_id: route.id,
      details: auth
    )
  end

  defp auth_condition(_route, _auth), do: nil

  defp notification_condition(route, %{token_capability_declared: true} = notifications) do
    Types.condition(
      type: :notification_token,
      status: :unknown,
      reason: :provider_snapshot,
      severity: :advisory,
      message: "route #{route.id} declares notification token provider snapshot readiness",
      route_id: route.id,
      details: notifications
    )
  end

  defp notification_condition(_route, _notifications), do: nil

  defp companion_condition(route, %{gated_by: gated_by} = companion) when not is_nil(gated_by) do
    Types.condition(
      type: :companion_binding,
      status: :unknown,
      reason: :first_party_typed_companion,
      severity: :advisory,
      message: "route #{route.id} is bound to companion #{gated_by}",
      route_id: route.id,
      details: companion
    )
  end

  defp companion_condition(_route, _companion), do: nil

  defp severity_for_support(:unsupported), do: :error
  defp severity_for_support(:verification_required), do: :warning
  defp severity_for_support(_status), do: :advisory

  defp rebuild_message(route_id, %{native_required: false, companion_required: false}) do
    "route #{route_id} has no rebuild requirement"
  end

  defp rebuild_message(route_id, _rebuild),
    do: "route #{route_id} requires native or companion rebuild verification"

  defp summary(routes, findings) do
    route_values = Map.values(routes)

    %{
      status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
      route_count: map_size(routes),
      verification_required_count:
        Enum.count(route_values, &(&1.support.status == :verification_required)),
      rebuild_required_count:
        Enum.count(route_values, &(&1.rebuild.native_required or &1.rebuild.companion_required)),
      blocking_count: Enum.count(route_values, &(&1.support.status == :unsupported)),
      finding_count: length(findings)
    }
  end

  defp indexes(routes) do
    %{
      by_runtime: index_by(routes, &Atom.to_string(&1.runtime)),
      by_capability: index_many(routes, fn route -> Enum.map(route.capabilities, & &1["id"]) end),
      by_companion:
        index_by(routes, fn route ->
          if route.companion.gated_by, do: Atom.to_string(route.companion.gated_by), else: nil
        end),
      by_auth_predicate:
        index_by(routes, fn route ->
          if route.auth.fallback == :step_up_required, do: "step_up_required", else: nil
        end),
      by_rebuild_requirement:
        index_by(routes, fn route ->
          cond do
            route.rebuild.native_required -> "native_required"
            route.rebuild.companion_required -> "companion_required"
            true -> nil
          end
        end),
      by_support_status: index_by(routes, &Atom.to_string(&1.support.status))
    }
  end

  defp index_by(routes, fun) do
    Enum.reduce(routes, %{}, fn {route_id, route}, acc ->
      case fun.(route) do
        nil -> acc
        key -> Map.update(acc, key, [route_id], &Enum.sort([route_id | &1]))
      end
    end)
  end

  defp index_many(routes, fun) do
    Enum.reduce(routes, %{}, fn {route_id, route}, acc ->
      route
      |> fun.()
      |> Enum.reduce(acc, fn key, inner ->
        Map.update(inner, key, [route_id], &Enum.sort([route_id | &1]))
      end)
    end)
  end

  defp findings_from_routes(routes) do
    routes
    |> Enum.flat_map(fn {route_id, route} ->
      route.conditions
      |> Enum.reject(
        &(&1.severity == :advisory and &1.type in [:support_status, :rebuild_required])
      )
      |> Enum.map(fn condition ->
        %Check{
          severity: condition.severity,
          code: "operator.#{condition.type}.#{condition.reason}",
          check: "operator_inspection",
          message: condition.message,
          hint: "inspect route #{route_id} support, proof, rebuild, and denial fields",
          details: Map.put(condition.details, :route_id, route_id)
        }
      end)
    end)
  end
end
