defmodule Crosswake.Manifest.Validator do
  @moduledoc """
  Validates manifest contract truth before serialization or release artifact output.
  """

  alias Crosswake.Compatibility
  alias Crosswake.Manifest.Types
  alias Crosswake.Policy.Error
  alias Crosswake.SupportMatrix
  alias Crosswake.Transfer.Contracts

  @commerce_role_values Crosswake.Policy.Schema.commerce_role_values()
  @provider_specific_commerce_terms [
    "storekit",
    "play_billing",
    "play-billing",
    "play billing",
    "revenuecat"
  ]
  @nested_commerce_semantic_keys [
    "entitlement",
    "entitlements",
    "entitlement_snapshot",
    "evidence",
    "reconciliation",
    "authority",
    "access",
    "freshness",
    "effective",
    "lifecycle",
    "state",
    "status"
  ]
  @additive_compatibility_hint "commerce corridor fields are additive in manifest schema 1.0.0 and only required when a route declares commerce"
  @opaque_route_id ~r/^route-[0-9a-f]{16}$/
  @opaque_tab_id ~r/^tab-[0-9a-f]{16}$/

  @spec validate(Types.Root.t()) :: [Error.t()]
  def validate(%Types.Root{} = manifest) do
    []
    |> validate_top_level_sections(manifest)
    |> validate_compatibility(manifest.compatibility)
    |> validate_support_matrix(manifest.support_matrix)
    |> validate_capability_registry(manifest.capability_registry)
    |> validate_commerce_corridors(manifest.commerce_corridors)
    |> validate_routes(
      manifest.routes,
      manifest.capability_registry,
      manifest.pack_registry,
      manifest.commerce_corridors
    )
    |> validate_navigation_topology(
      manifest.navigation_topology,
      manifest.routes,
      manifest.manifest_schema_version,
      manifest.compatibility
    )
  end

  defp validate_top_level_sections(errors, %Types.Root{} = manifest) do
    [
      {:manifest_schema_version, manifest.manifest_schema_version},
      {:crosswake_version, manifest.crosswake_version},
      {:generated_at, manifest.generated_at},
      {:host, manifest.host},
      {:compatibility, manifest.compatibility},
      {:support_matrix, manifest.support_matrix},
      {:capability_registry, manifest.capability_registry},
      {:pack_registry, manifest.pack_registry},
      {:commerce_corridors, manifest.commerce_corridors},
      {:navigation_topology, manifest.navigation_topology},
      {:routes, manifest.routes}
    ]
    |> Enum.reduce(errors, fn {key, value}, acc ->
      if present?(key, value) do
        acc
      else
        [
          build_error(
            key: key,
            message: "manifest is missing required top-level section #{inspect(key)}",
            hint: "populate #{inspect(key)} before manifest serialization"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_compatibility(errors, compatibility) do
    Compatibility.validate_contract(compatibility)
    |> Enum.map(&build_error/1)
    |> Kernel.++(errors)
  end

  defp validate_support_matrix(errors, support_matrix) do
    SupportMatrix.validate(support_matrix)
    |> Enum.map(&build_error/1)
    |> Kernel.++(errors)
  end

  defp validate_capability_registry(errors, capability_registry)
       when is_map(capability_registry) do
    Enum.reduce(capability_registry, errors, fn {_id, capability}, acc ->
      capability
      |> capability_errors()
      |> Enum.map(&build_error/1)
      |> Kernel.++(acc)
    end)
  end

  defp validate_commerce_corridors(errors, commerce_corridors) when is_map(commerce_corridors) do
    Enum.reduce(commerce_corridors, errors, fn {corridor_ref, corridor}, acc ->
      corridor
      |> commerce_corridor_errors(corridor_ref)
      |> Enum.map(&build_error/1)
      |> Kernel.++(acc)
    end)
  end

  defp validate_routes(errors, routes, capability_registry, pack_registry, commerce_corridors) do
    Enum.reduce(routes, errors, fn {_id, route}, acc ->
      route
      |> route_errors(capability_registry, pack_registry, commerce_corridors)
      |> Enum.map(&build_error(&1, route))
      |> Kernel.++(acc)
    end)
  end

  defp validate_navigation_topology(
         errors,
         %Types.NavigationTopology{} = topology,
         routes,
         manifest_schema_version,
         compatibility
       ) do
    errors
    |> validate_topology_versions(topology, manifest_schema_version, compatibility)
    |> validate_topology_status(topology)
    |> validate_topology_entries(topology, routes)
  end

  defp validate_navigation_topology(
         errors,
         _topology,
         _routes,
         _manifest_schema_version,
         _compatibility
       ),
       do: [topology_error("NT-MANIFEST-SECTION", :navigation_topology) | errors]

  defp validate_topology_versions(errors, topology, manifest_schema_version, compatibility) do
    if topology.manifest_schema_version == manifest_schema_version and
         topology.manifest_schema_version == compatibility.manifest_schema_version do
      errors
    else
      [topology_error("NT-MANIFEST-VERSION", :manifest_schema_version) | errors]
    end
  end

  defp validate_topology_status(errors, %Types.NavigationTopology{
         status: :unknown_blocking,
         entries: []
       }),
       do: errors

  defp validate_topology_status(errors, %Types.NavigationTopology{status: :unknown_blocking}),
    do: [topology_error("NT-MANIFEST-UNKNOWN_BLOCKING", :entries) | errors]

  defp validate_topology_status(errors, %Types.NavigationTopology{
         status: :ready,
         entries: entries
       })
       when is_list(entries) and entries != [],
       do: errors

  defp validate_topology_status(errors, _topology),
    do: [topology_error("NT-MANIFEST-STATUS", :status) | errors]

  defp validate_topology_entries(errors, %Types.NavigationTopology{entries: entries}, routes)
       when is_list(entries) do
    valid_entries = Enum.filter(entries, &valid_topology_entry?/1)

    errors
    |> validate_topology_entry_shapes(entries)
    |> validate_topology_route_references(valid_entries, routes)
    |> validate_topology_roots(valid_entries)
    |> validate_topology_parents(valid_entries)
    |> validate_topology_cycles(valid_entries)
    |> validate_topology_runtime_pairs(valid_entries, routes)
  end

  defp validate_topology_entries(errors, _topology, _routes),
    do: [topology_error("NT-MANIFEST-ENTRIES", :entries) | errors]

  defp validate_topology_entry_shapes(errors, entries) do
    Enum.reduce(entries, errors, fn
      %Types.NavigationTopologyEntry{
        route_id: route_id,
        root_tab_id: root_tab_id,
        presentation: presentation,
        deep_link_posture: deep_link_posture,
        restoration_posture: restoration_posture
      },
      acc
      when is_binary(route_id) and is_binary(root_tab_id) and presentation in [:root, :push] and
             deep_link_posture in [:allow, :deny] and
             restoration_posture in [:allow, :deny] ->
        if Regex.match?(@opaque_route_id, route_id) and Regex.match?(@opaque_tab_id, root_tab_id),
          do: acc,
          else: [topology_error("NT-MANIFEST-ENTRY", :entry) | acc]

      _entry, acc ->
        [topology_error("NT-MANIFEST-ENTRY", :entry) | acc]
    end)
  end

  defp valid_topology_entry?(%Types.NavigationTopologyEntry{
         route_id: route_id,
         root_tab_id: root_tab_id,
         presentation: presentation,
         deep_link_posture: deep_link_posture,
         restoration_posture: restoration_posture
       }) do
    is_binary(route_id) and Regex.match?(@opaque_route_id, route_id) and is_binary(root_tab_id) and
      Regex.match?(@opaque_tab_id, root_tab_id) and presentation in [:root, :push] and
      deep_link_posture in [:allow, :deny] and restoration_posture in [:allow, :deny]
  end

  defp valid_topology_entry?(_entry), do: false

  defp validate_topology_route_references(errors, entries, routes) do
    Enum.reduce(entries, errors, fn
      %Types.NavigationTopologyEntry{route_id: route_id}, acc when is_binary(route_id) ->
        if Map.has_key?(routes, route_id),
          do: acc,
          else: [topology_error("NT-MANIFEST-UNKNOWN_ROUTE", :route_id) | acc]

      _entry, acc ->
        [topology_error("NT-MANIFEST-UNKNOWN_ROUTE", :route_id) | acc]
    end)
  end

  defp validate_topology_roots(errors, entries) do
    roots = Enum.filter(entries, &match?(%Types.NavigationTopologyEntry{presentation: :root}, &1))
    root_tab_ids = Enum.map(roots, & &1.root_tab_id)

    cond do
      roots == [] ->
        [topology_error("NT-MANIFEST-ROOT_REQUIRED", :entries) | errors]

      Enum.any?(roots, &(&1.parent_route_id != nil)) ->
        [topology_error("NT-MANIFEST-ROOT_PARENT", :parent_route_id) | errors]

      length(root_tab_ids) != MapSet.size(MapSet.new(root_tab_ids)) ->
        [topology_error("NT-MANIFEST-DUPLICATE_ROOT", :root_tab_id) | errors]

      true ->
        errors
    end
  end

  defp validate_topology_parents(errors, entries) do
    entry_by_id = Map.new(entries, &{&1.route_id, &1})

    Enum.reduce(entries, errors, fn
      %Types.NavigationTopologyEntry{presentation: :push} = entry, acc ->
        case Map.get(entry_by_id, entry.parent_route_id) do
          %Types.NavigationTopologyEntry{root_tab_id: root_tab_id}
          when root_tab_id == entry.root_tab_id ->
            acc

          _parent ->
            [topology_error("NT-MANIFEST-INVALID_PARENT", :parent_route_id) | acc]
        end

      _entry, acc ->
        acc
    end)
  end

  defp validate_topology_cycles(errors, entries) do
    entry_by_id = Map.new(entries, &{&1.route_id, &1})

    if Enum.any?(entries, &topology_cycle?(&1, entry_by_id, MapSet.new())) do
      [topology_error("NT-MANIFEST-CYCLE", :parent_route_id) | errors]
    else
      errors
    end
  end

  defp topology_cycle?(%Types.NavigationTopologyEntry{presentation: :root}, _entries, _seen),
    do: false

  defp topology_cycle?(%Types.NavigationTopologyEntry{} = entry, entries, seen) do
    cond do
      MapSet.member?(seen, entry.route_id) ->
        true

      not is_binary(entry.parent_route_id) ->
        false

      true ->
        case Map.get(entries, entry.parent_route_id) do
          %Types.NavigationTopologyEntry{} = parent ->
            topology_cycle?(parent, entries, MapSet.put(seen, entry.route_id))

          _parent ->
            false
        end
    end
  end

  defp validate_topology_runtime_pairs(errors, entries, routes) do
    Enum.reduce(entries, errors, fn
      %Types.NavigationTopologyEntry{route_id: route_id}, acc ->
        case Map.get(routes, route_id) do
          %{runtime: runtime} when runtime in [:live_view, :offline_island, :native_screen] -> acc
          _route -> [topology_error("NT-MANIFEST-RUNTIME_PRESENTATION", :runtime) | acc]
        end

      _entry, acc ->
        acc
    end)
  end

  defp route_errors(route, capability_registry, pack_registry, commerce_corridors) do
    []
    |> validate_route_field(route, :path, route.path)
    |> validate_route_field(route, :runtime, route.runtime)
    |> validate_route_entry(route)
    |> validate_route_capabilities(route, capability_registry)
    |> validate_route_packs(route, pack_registry)
    |> validate_route_commerce(route, commerce_corridors)
    |> validate_route_transfers(route)
  end

  defp validate_route_entry(errors, route) do
    if route.entry in [:internal_only, :external] do
      errors
    else
      [
        %{
          key: :entry,
          route_id: route.id,
          path: route.path,
          message: "route #{route.id} declares unsupported entry policy #{inspect(route.entry)}",
          hint: "use entry :internal_only or :external in manifest route truth"
        }
        | errors
      ]
    end
  end

  defp validate_route_field(errors, _route, _key, value) when not is_nil(value), do: errors

  defp validate_route_field(errors, route, key, _value) do
    [
      %{
        key: key,
        route_id: route.id,
        path: route.path,
        message: "route #{route.id} is missing required field #{inspect(key)}",
        hint: "populate #{inspect(key)} for route #{route.id} before manifest generation"
      }
      | errors
    ]
  end

  defp validate_route_capabilities(errors, route, capability_registry) do
    Enum.reduce(route.capabilities, errors, fn capability, acc ->
      if route_capability_declared?(capability_registry, capability) do
        acc
      else
        [
          %{
            key: :capabilities,
            route_id: route.id,
            path: route.path,
            message:
              "route #{route.id} declares capability #{inspect(capability)} outside the manifest registry",
            hint:
              "register #{inspect(capability)} in capability_registry before validation passes"
          }
          | acc
        ]
      end
    end)
  end

  defp validate_route_commerce(errors, %{commerce: nil}, _commerce_corridors), do: errors

  defp validate_route_commerce(errors, route, commerce_corridors) do
    errors
    |> validate_route_commerce_corridor_ref(route, commerce_corridors)
    |> validate_route_commerce_role(route)
    |> validate_route_commerce_vocab(route)
  end

  defp validate_route_commerce_corridor_ref(errors, route, commerce_corridors) do
    corridor_ref = commerce_field(route.commerce, :corridor_ref)

    cond do
      not non_empty_string?(corridor_ref) ->
        [
          %{
            key: :commerce,
            route_id: route.id,
            path: route.path,
            message: "route #{route.id} declares commerce without a corridor_ref",
            hint:
              "declare route commerce with a canonical corridor_ref from commerce_corridors; #{@additive_compatibility_hint}"
          }
          | errors
        ]

      Map.has_key?(commerce_corridors, corridor_ref) ->
        errors

      true ->
        [
          %{
            key: :commerce,
            route_id: route.id,
            path: route.path,
            message:
              "route #{route.id} declares undeclared corridor_ref #{inspect(corridor_ref)} outside commerce_corridors",
            hint:
              "declare #{inspect(corridor_ref)} in Crosswake.Policy.CorridorProfiles before manifest validation"
          }
          | errors
        ]
    end
  end

  defp validate_route_commerce_role(errors, route) do
    role = commerce_field(route.commerce, :role)

    cond do
      is_nil(role) ->
        [
          %{
            key: :commerce,
            route_id: route.id,
            path: route.path,
            message: "route #{route.id} declares commerce without a role",
            hint:
              "declare role with route commerce (for example :paywall_entry); #{@additive_compatibility_hint}"
          }
          | errors
        ]

      role in @commerce_role_values ->
        errors

      true ->
        [
          %{
            key: :commerce,
            route_id: route.id,
            path: route.path,
            message: "route #{route.id} declares unsupported commerce role #{inspect(role)}",
            hint: "use provider-neutral roles #{inspect(@commerce_role_values)}"
          }
          | errors
        ]
    end
  end

  defp validate_route_commerce_vocab(errors, route) do
    commerce = route.commerce

    if provider_specific_vocabulary?(commerce) do
      message =
        if provider_specific_semantic_vocabulary?(commerce) do
          "route #{route.id} uses provider-specific commerce vocabulary in nested entitlement or evidence semantics"
        else
          "route #{route.id} uses provider-specific commerce vocabulary in corridor_ref or role"
        end

      [
        %{
          key: :commerce,
          route_id: route.id,
          path: route.path,
          message: message,
          hint: "use provider-neutral commerce corridor vocabulary in core manifest seams"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp commerce_corridor_errors(corridor, corridor_ref) do
    []
    |> validate_commerce_corridor_id(corridor, corridor_ref)
    |> validate_commerce_corridor_required_string(
      corridor,
      corridor_ref,
      :denial,
      corridor.denial
    )
    |> validate_commerce_corridor_required_string(
      corridor,
      corridor_ref,
      :fallback,
      corridor.fallback
    )
    |> validate_commerce_corridor_prerequisites(corridor, corridor_ref)
    |> validate_commerce_corridor_vocab(corridor, corridor_ref)
  end

  defp validate_commerce_corridor_id(errors, corridor, corridor_ref) do
    if corridor.id == corridor_ref and non_empty_string?(corridor.id) do
      errors
    else
      [
        %{
          key: :commerce_corridors,
          message:
            "commerce corridor #{inspect(corridor_ref)} must declare matching non-empty id metadata",
          hint: "set commerce corridor id to match the registry key"
        }
        | errors
      ]
    end
  end

  defp validate_commerce_corridor_required_string(errors, _corridor, corridor_ref, key, value) do
    if non_empty_string?(value) do
      errors
    else
      [
        %{
          key: :commerce_corridors,
          message:
            "commerce corridor #{inspect(corridor_ref)} must provide non-empty #{inspect(key)} posture",
          hint: "declare explicit denial and fallback posture for every commerce corridor entry"
        }
        | errors
      ]
    end
  end

  defp validate_commerce_corridor_prerequisites(errors, corridor, corridor_ref) do
    if is_list(corridor.prerequisites) and corridor.prerequisites != [] and
         Enum.all?(corridor.prerequisites, &non_empty_string?/1) do
      errors
    else
      [
        %{
          key: :commerce_corridors,
          message:
            "commerce corridor #{inspect(corridor_ref)} must provide non-empty prerequisites",
          hint: "declare at least one provider-neutral prerequisite for each corridor profile"
        }
        | errors
      ]
    end
  end

  defp validate_commerce_corridor_vocab(errors, corridor, corridor_ref) do
    if provider_specific_vocabulary?(corridor) do
      message =
        if provider_specific_semantic_vocabulary?(corridor) do
          "commerce corridor #{inspect(corridor_ref)} includes provider-specific vocabulary in nested entitlement or evidence semantics"
        else
          "commerce corridor #{inspect(corridor_ref)} includes provider-specific vocabulary"
        end

      [
        %{
          key: :commerce_corridors,
          message: message,
          hint: "use provider-neutral commerce corridor vocabulary in core manifest seams"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp capability_errors(%Types.Capability{} = capability) do
    []
    |> validate_capability_vocab(
      :owner,
      capability.owner,
      [:bounded_bridge, :native_screen, :backend_seam, :activation, :defer]
    )
    |> validate_capability_vocab(
      :package_class,
      capability.package_class,
      [:core, :companion, :example_docs_only, :defer]
    )
    |> validate_capability_vocab(:proof_class, capability.proof_class, [
      :merge_blocking,
      :advisory
    ])
    |> validate_capability_vocab(
      :rebuild,
      capability.rebuild,
      [:none, :native_required, :companion_required]
    )
    |> validate_capability_required_string(:denial, capability.denial, capability.id)
    |> validate_capability_required_string(:fallback, capability.fallback, capability.id)
    |> validate_capability_required_string(:guide, capability.guide, capability.id)
    |> validate_capability_prerequisites(capability)
  end

  defp validate_capability_vocab(errors, key, value, allowed) do
    if value in allowed do
      errors
    else
      [
        %{
          key: key,
          message: "capability metadata uses unsupported #{key} #{inspect(value)}",
          hint: "use one of #{Enum.map_join(allowed, ", ", &inspect/1)}"
        }
        | errors
      ]
    end
  end

  defp validate_capability_required_string(errors, key, value, capability_id) do
    if non_empty_string?(value) do
      errors
    else
      [
        %{
          key: key,
          message:
            "capability #{inspect(capability_id)} must provide non-empty #{inspect(key)} metadata",
          hint: "populate #{inspect(key)} with explicit support truth"
        }
        | errors
      ]
    end
  end

  defp validate_capability_prerequisites(errors, %Types.Capability{
         id: id,
         prerequisites: prerequisites
       }) do
    if is_list(prerequisites) and prerequisites != [] and
         Enum.all?(prerequisites, &non_empty_string?/1) do
      errors
    else
      [
        %{
          key: :prerequisites,
          message: "capability #{inspect(id)} must provide non-empty prerequisite strings",
          hint: "publish explicit prerequisite truth for every capability entry"
        }
        | errors
      ]
    end
  end

  defp route_capability_declared?(capability_registry, capability) do
    Map.has_key?(capability_registry, capability) or
      Enum.any?(capability_registry, fn {_id, entry} -> capability in entry.legacy_ids end)
  end

  defp validate_route_packs(errors, route, pack_registry) do
    Enum.reduce(route.packs, errors, fn pack_reference, acc ->
      if Map.has_key?(pack_registry, pack_reference) do
        acc
      else
        [
          %{
            key: :packs,
            route_id: route.id,
            path: route.path,
            message:
              "route #{route.id} declares pack reference #{inspect(pack_reference)} outside the manifest pack registry",
            hint: "compile #{inspect(pack_reference)} into pack_registry before validation passes"
          }
          | acc
        ]
      end
    end)
  end

  defp validate_route_transfers(errors, route) do
    Enum.reduce(route.transfers, errors, fn transfer, acc ->
      acc
      |> validate_transfer_protocol(route, transfer)
      |> validate_transfer_declaration(route, transfer)
      |> validate_transfer_runtime(route, transfer)
    end)
  end

  defp validate_transfer_protocol(errors, route, transfer) do
    cond do
      transfer.protocol != Contracts.protocol() ->
        [
          %{
            key: :transfers,
            route_id: route.id,
            path: route.path,
            message:
              "transfer seam #{inspect(transfer.id)} must use protocol #{inspect(Contracts.protocol())}",
            hint: "compile transfer seams from the canonical Crosswake transfer contract"
          }
          | errors
        ]

      transfer.version != Contracts.version() ->
        [
          %{
            key: :transfers,
            route_id: route.id,
            path: route.path,
            message:
              "transfer seam #{inspect(transfer.id)} must use version #{inspect(Contracts.version())}",
            hint: "regenerate the manifest from current transfer seam truth"
          }
          | errors
        ]

      transfer.states != Contracts.transfer_states() ->
        [
          %{
            key: :transfers,
            route_id: route.id,
            path: route.path,
            message:
              "transfer seam #{inspect(transfer.id)} must expose the canonical route-local transfer state vocabulary",
            hint: "compile states from Crosswake.Transfer.Contracts.transfer_states/0"
          }
          | errors
        ]

      true ->
        errors
    end
  end

  defp validate_transfer_declaration(errors, route, transfer) do
    attrs = [
      id: transfer.id,
      intent: transfer.intent,
      source: transfer.source,
      destination: transfer.destination,
      verification: transfer.verification,
      media_types: transfer.media_types
    ]

    case Contracts.normalize_declaration(attrs) do
      {:ok, declaration} ->
        if declaration.direction == transfer.direction do
          errors
        else
          [
            %{
              key: :transfers,
              route_id: route.id,
              path: route.path,
              message:
                "transfer seam #{inspect(transfer.id)} must use direction #{inspect(declaration.direction)}",
              hint: "derive transfer direction from intent instead of hand-authoring it"
            }
            | errors
          ]
        end

      {:error, reason} ->
        [
          %{
            key: :transfers,
            route_id: route.id,
            path: route.path,
            message: "transfer seam #{inspect(transfer.id)} is invalid: #{reason}",
            hint: "supply typed source or destination metadata that matches the transfer intent"
          }
          | errors
        ]
    end
  end

  defp validate_transfer_runtime(errors, route, transfer) do
    if transfer.source == :native_capture and route.runtime != :native_screen do
      [
        %{
          key: :transfers,
          route_id: route.id,
          path: route.path,
          message:
            "transfer seam #{inspect(transfer.id)} native_capture source requires route runtime :native_screen",
          hint:
            "move capture-owned transfers to a native_screen route or use a non-capture transfer source"
        }
        | errors
      ]
    else
      errors
    end
  end

  defp build_error(attrs, route \\ nil) do
    struct!(Error, %{
      key: attrs[:key],
      route_id: attrs[:route_id] || (route && route.id),
      path: attrs[:path] || (route && route.path),
      message: attrs[:message],
      hint: attrs[:hint]
    })
  end

  defp topology_error(rule_id, field) do
    build_error(%{
      key: :navigation_topology,
      message: "#{rule_id}: navigation topology #{field} is invalid",
      hint: "regenerate navigation_topology from validated route inventory"
    })
  end

  defp non_empty_string?(value) when is_binary(value), do: byte_size(String.trim(value)) > 0
  defp non_empty_string?(_value), do: false

  defp provider_specific_vocabulary?(value) when is_binary(value) do
    normalized = value |> String.downcase() |> String.trim()
    normalized in @provider_specific_commerce_terms
  end

  defp provider_specific_vocabulary?(value) when is_atom(value),
    do: value |> Atom.to_string() |> provider_specific_vocabulary?()

  defp provider_specific_vocabulary?(value) when is_list(value),
    do: Enum.any?(value, &provider_specific_vocabulary?/1)

  defp provider_specific_vocabulary?(value) when is_map(value),
    do:
      value
      |> normalize_provider_vocab_map()
      |> Enum.any?(fn {key, nested_value} ->
        provider_specific_vocabulary?(key) or provider_specific_vocabulary?(nested_value)
      end)

  defp provider_specific_vocabulary?(_value), do: false

  defp provider_specific_semantic_vocabulary?(value) when is_map(value) do
    value
    |> normalize_provider_vocab_map()
    |> Enum.any?(fn {key, nested_value} ->
      if commerce_semantic_key?(key) do
        provider_specific_vocabulary?(nested_value)
      else
        provider_specific_semantic_vocabulary?(nested_value)
      end
    end)
  end

  defp provider_specific_semantic_vocabulary?(value) when is_list(value),
    do: Enum.any?(value, &provider_specific_semantic_vocabulary?/1)

  defp provider_specific_semantic_vocabulary?(_value), do: false

  defp commerce_semantic_key?(value) when is_atom(value),
    do: value |> Atom.to_string() |> commerce_semantic_key?()

  defp commerce_semantic_key?(value) when is_binary(value),
    do: String.downcase(value) in @nested_commerce_semantic_keys

  defp commerce_semantic_key?(_value), do: false

  defp normalize_provider_vocab_map(%_{} = struct), do: Map.from_struct(struct)
  defp normalize_provider_vocab_map(map), do: map

  defp commerce_field(nil, _field), do: nil
  defp commerce_field(commerce, field) when is_map(commerce), do: Map.get(commerce, field)

  defp present?(:pack_registry, value) when is_map(value), do: true
  defp present?(:commerce_corridors, value) when is_map(value), do: true
  defp present?(_key, value) when value in [nil, ""], do: false
  defp present?(_key, value) when is_map(value), do: map_size(value) > 0
  defp present?(_key, value) when is_list(value), do: value != []
  defp present?(_key, _value), do: true
end
