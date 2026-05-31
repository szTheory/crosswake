defmodule Crosswake.Manifest.Builder do
  @moduledoc """
  Builds the route-first manifest root from compiled Crosswake route policy.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Offline.Contracts
  alias Crosswake.Policy.CorridorProfiles
  alias Crosswake.Policy.Route

  @public_route_capability_ids ~w(
    app_info
    file_picker
    haptics
    notification_token
    permissions.status
    share
    deep_link
    media_capture
    scanner
    document_scan
    paywall_entry
    purchase_intent
    restore_intent
    entitlement_snapshot
    reconciliation_evidence
  )

  @compatibility_route_capability_ids ~w(
    app.info.get
    camera
    camera.capture
    files.pick
    haptics.impact
    push.notifications
  )

  @spec build([Route.t()], [map()], keyword()) :: Types.Root.t()
  def build(routes, managed_routes, opts \\ [])
      when is_list(routes) and is_list(managed_routes) do
    capability_registry = capability_registry(routes)

    host =
      Keyword.get_lazy(opts, :host, fn ->
        case Keyword.fetch(opts, :origin) do
          {:ok, origin} -> Types.new_host(origin: origin)
          :error -> Types.new_host()
        end
      end)

    compatibility = Keyword.get(opts, :compatibility, Types.new_compatibility())
    commerce_corridors = commerce_corridor_registry(routes)
    support_matrix =
      Keyword.get(
        opts,
        :support_matrix,
        Crosswake.SupportMatrix.canonical(capability_registry: capability_registry)
      )

    Types.new_root(
      crosswake_version:
        Keyword.get(opts, :crosswake_version, Mix.Project.config()[:version] || "dev"),
      generated_at:
        Keyword.get(
          opts,
          :generated_at,
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
        ),
      host: host,
      compatibility: compatibility,
      support_matrix: support_matrix,
      capability_registry: capability_registry,
      pack_registry: pack_registry(routes),
      commerce_corridors: commerce_corridors,
      routes: route_entries(routes, managed_routes, host.origin)
    )
  end

  @spec capability_registry([Route.t()]) :: %{String.t() => Types.Capability.t()}
  def capability_registry(routes) do
    public_registry =
      capability_catalog()
      |> Enum.map(fn attrs ->
        capability = Types.new_capability(attrs)
        {capability.id, capability}
      end)
      |> Map.new()

    compatibility_registry =
      routes
      |> Enum.flat_map(& &1.capabilities)
      |> Enum.uniq()
      |> Enum.reject(&Map.has_key?(public_registry, &1))
      |> Enum.map(fn capability_id ->
        family_capability = family_capability_for(capability_id)

        capability =
          family_capability
          |> compatibility_capability_attrs(capability_id)
          |> Types.new_capability()

        {capability_id, capability}
      end)
      |> Map.new()

    Map.merge(public_registry, compatibility_registry)
  end

  @spec public_route_capability_ids() :: [String.t()]
  def public_route_capability_ids, do: @public_route_capability_ids

  @spec compatibility_route_capability_ids() :: [String.t()]
  def compatibility_route_capability_ids, do: @compatibility_route_capability_ids

  defp route_entries(routes, managed_routes, origin) do
    routes
    |> Enum.zip(managed_routes)
    |> Map.new(fn {%Route{} = route, managed_route} ->
      path = Map.fetch!(managed_route, :path)

      entry =
        Types.new_route_entry(
          id: route.id,
          path: path,
          runtime: route.runtime,
          offline: route.offline,
          entry: route.entry,
          cache_contract: cache_contract(route),
          island_contract: island_contract(route),
          commerce: route_commerce(route),
          capabilities: route.capabilities,
          packs: route_pack_references(route.packs),
          sync: route.sync,
          transfers: transfer_seams(route.transfers),
          security: route.security,
          allowlisted_origins: [origin],
          gated_by: route.gated_by,
          on_unavailable: route.on_unavailable,
          auth_min_level: route.auth_min_level,
          requires_recent_auth: route.requires_recent_auth
        )

      {route.id, entry}
    end)
  end

  defp pack_registry(routes) do
    routes
    |> Enum.flat_map(& &1.packs)
    |> Enum.sort_by(&pack_reference/1)
    |> Map.new(fn pack ->
      {pack_reference(pack),
       Types.new_pack_entry(
         id: pack.id,
         version: pack.version,
         kind: pack.kind,
         integrity: pack.integrity
       )}
    end)
  end

  defp commerce_corridor_registry(routes) do
    canonical_profiles = CorridorProfiles.commerce_corridors()

    routes
    |> Enum.flat_map(fn
      %Route{commerce: nil} -> []
      %Route{commerce: %{corridor: corridor}} -> [corridor]
      _route -> []
    end)
    |> Enum.uniq()
    |> Enum.reduce(%{}, fn corridor_ref, acc ->
      case Map.get(canonical_profiles, corridor_ref) do
        nil ->
          acc

        profile ->
          Map.put(
            acc,
            corridor_ref,
            Types.new_commerce_corridor(
              id: profile.id,
              role_ownership: profile.role_ownership,
              denial: profile.denial,
              fallback: profile.fallback,
              prerequisites: profile.prerequisites
            )
          )
      end
    end)
  end

  defp route_pack_references(packs), do: Enum.map(packs, &pack_reference/1)

  defp transfer_seams(transfers) do
    Enum.map(transfers, fn transfer ->
      Types.new_transfer_seam(
        id: transfer.id,
        intent: transfer.intent,
        direction: transfer.direction,
        source: transfer.source,
        destination: transfer.destination,
        verification: transfer.verification,
        media_types: transfer.media_types
      )
    end)
  end

  defp pack_reference(%{id: id, version: version}), do: "#{id}@#{version}"

  defp route_commerce(%Route{commerce: nil}), do: nil

  defp route_commerce(%Route{commerce: %{corridor: corridor, role: role}})
       when is_binary(corridor) and is_atom(role) do
    Types.new_route_commerce(corridor_ref: corridor, role: role)
  end

  defp route_commerce(_route), do: nil

  defp capability_catalog do
    [
      [
        id: "deep_link",
        family: "deep_link",
        owner: :activation,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :none,
        prerequisites: [
          "bundled or cached manifest",
          "shell activation support",
          "explicit route entry approval"
        ],
        denial: "route_unavailable",
        fallback:
          "show route unavailable surface that distinguishes inactive routes from routes that reject external entry",
        guide: "guides/native_shell.md#manifest-first-activation"
      ],
      [
        id: "app_info",
        family: "app_info",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :none,
        prerequisites: ["declared route capability", "bounded bridge support"],
        denial: "undeclared_capability",
        fallback: "Phoenix route continues without native app metadata",
        guide: "guides/bridge.md#bounded-bridge",
        legacy_ids: ["app.info.get"]
      ],
      [
        id: "haptics",
        family: "haptics",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :none,
        prerequisites: ["declared route capability", "bounded bridge support"],
        denial: "undeclared_capability",
        fallback: "Phoenix route continues without native confirmation feedback",
        guide: "guides/bridge.md#bounded-bridge",
        legacy_ids: ["haptics.impact"]
      ],
      [
        id: "share",
        family: "share",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :advisory,
        rebuild: :none,
        prerequisites: ["truthful semantic share contract"],
        denial: "undeclared_capability",
        fallback: "keep content in the Phoenix-owned route until a share family is declared",
        guide: "guides/capabilities.md#bounded-bridge"
      ],
      [
        id: "permissions.status",
        family: "permissions.status",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :none,
        prerequisites: [
          "declared route capability",
          "bounded bridge support",
          "notifications alias only"
        ],
        denial: "undeclared_capability",
        fallback: "route continues without native notification permission snapshot authority",
        guide: "guides/capabilities.md#bounded-bridge"
      ],
      [
        id: "notification_token",
        family: "notification_token",
        owner: :bounded_bridge,
        package_class: :companion,
        proof_class: :advisory,
        rebuild: :companion_required,
        prerequisites: [
          "declared route capability",
          "bounded bridge support",
          "notification authorization already resolved",
          "provider token snapshot available"
        ],
        denial: "unavailable_capability",
        fallback:
          "treat notification token replies as provider-tagged evidence instead of backend registration truth",
        guide: "guides/capabilities.md#bounded-bridge",
        legacy_ids: ["push.notifications"]
      ],
      [
        id: "file_picker",
        family: "file_picker",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :native_required,
        prerequisites: [
          "declared transfer_id",
          "bounded bridge support",
          "inbound native_picker transfer seam",
          "copy-first staged handle plus transfer verification"
        ],
        denial: "undeclared_capability",
        fallback:
          "keep the route on Phoenix-owned import guidance until a copy-first native_picker seam is declared and verified",
        guide: "guides/capabilities.md#bounded-bridge",
        legacy_ids: ["files.pick"]
      ],
      [
        id: "media_capture",
        family: "media_capture",
        owner: :native_screen,
        package_class: :companion,
        proof_class: :merge_blocking,
        rebuild: :native_required,
        prerequisites: ["native screen route", "capture pack availability"],
        denial: "pack_incompatible",
        fallback: "fail closed instead of degrading into a bounded web upload flow",
        guide: "guides/native_shell.md#native-capture-escape-hatch",
        legacy_ids: ["camera", "camera.capture"]
      ],
      [
        id: "scanner",
        family: "scanner",
        owner: :native_screen,
        package_class: :defer,
        proof_class: :advisory,
        rebuild: :companion_required,
        prerequisites: ["scanner-native runtime", "policy-heavy proof lane"],
        denial: "unavailable_capability",
        fallback: "defer scanner support until native and proof posture are explicit",
        guide: "guides/capabilities.md#explicit-defers"
      ],
      [
        id: "document_scan",
        family: "document_scan",
        owner: :native_screen,
        package_class: :defer,
        proof_class: :advisory,
        rebuild: :companion_required,
        prerequisites: ["document-scan runtime", "policy-heavy proof lane"],
        denial: "unavailable_capability",
        fallback: "defer document scan support until native and proof posture are explicit",
        guide: "guides/capabilities.md#explicit-defers"
      ],
      [
        id: "paywall_entry",
        family: "paywall_entry",
        owner: :backend_seam,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :companion_required,
        prerequisites: ["backend entitlement contract", "storefront guidance"],
        denial: "unavailable_capability",
        fallback: "fall back to Phoenix-owned paywall guidance without device authority",
        guide: "guides/capabilities.md#backend-seams-and-deferred-surfaces"
      ],
      [
        id: "purchase_intent",
        family: "purchase_intent",
        owner: :backend_seam,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :companion_required,
        prerequisites: ["backend reconciliation", "provider-specific adapter"],
        denial: "unavailable_capability",
        fallback: "treat purchase events as reconciliation inputs, not entitlement truth",
        guide: "guides/capabilities.md#backend-seams-and-deferred-surfaces"
      ],
      [
        id: "restore_intent",
        family: "restore_intent",
        owner: :backend_seam,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :companion_required,
        prerequisites: ["backend reconciliation", "storefront-aware adapter"],
        denial: "unavailable_capability",
        fallback: "keep restore flow backend-owned until adapter truth is explicit",
        guide: "guides/capabilities.md#backend-seams-and-deferred-surfaces"
      ],
      [
        id: "entitlement_snapshot",
        family: "entitlement_snapshot",
        owner: :backend_seam,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :companion_required,
        prerequisites: ["backend entitlement authority", "reconciliation hook"],
        denial: "unavailable_capability",
        fallback: "treat device-side state as evidence instead of final entitlement truth",
        guide: "guides/capabilities.md#backend-seams-and-deferred-surfaces"
      ],
      [
        id: "reconciliation_evidence",
        family: "reconciliation_evidence",
        owner: :backend_seam,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :companion_required,
        prerequisites: ["backend reconciliation", "device callback or webhook"],
        denial: "unavailable_capability",
        fallback: "treat evidence as asynchronous payload without blocking route entry",
        guide: "guides/capabilities.md#backend-seams-and-deferred-surfaces"
      ]
    ]
  end

  defp family_capability_for(capability_id) do
    Enum.find(capability_catalog(), fn attrs ->
      capability_id in Keyword.get(attrs, :legacy_ids, [])
    end)
  end

  defp compatibility_capability_attrs(nil, capability_id) do
    [
      id: capability_id,
      version: capability_version(capability_id)
    ]
  end

  defp compatibility_capability_attrs(attrs, capability_id) do
    attrs
    |> Keyword.put(:id, capability_id)
    |> Keyword.put(:version, capability_version(capability_id))
    |> Keyword.put(:family, Keyword.fetch!(attrs, :family))
  end

  defp capability_version(_capability), do: "1.0.0"

  defp cache_contract(%Route{cache_contract: nil}), do: nil

  defp cache_contract(%Route{id: route_id, cache_contract: contract_id}) do
    contract_id
    |> Contracts.new_cache_route(route_id: route_id)
    |> Contracts.cache_contract()
  end

  defp island_contract(%Route{island_contract: nil}), do: nil

  defp island_contract(%Route{id: route_id, island_contract: contract_id, sync: [sync_seam | _rest]}) do
    contract_id
    |> Contracts.new_study_session_island(route_id: route_id, sync_seam: sync_seam)
    |> Contracts.island_contract()
  end

  defp island_contract(%Route{id: route_id, island_contract: contract_id}) do
    contract_id
    |> Contracts.new_study_session_island(route_id: route_id, sync_seam: contract_id)
    |> Contracts.island_contract()
  end
end
