defmodule Crosswake.Compatibility.RouteGate do
  @moduledoc """
  Fail-closed route activation decisions derived from layered compatibility findings.
  """

  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial

  defmodule Decision do
    @moduledoc false

    defstruct [:route_id, :status, :denial, denials: [], transition: :activate]

    @type t :: %__MODULE__{
            route_id: String.t(),
            status: :allow | :deny,
            denial: Denial.t() | nil,
            denials: [Denial.t()],
            transition: :activate | :halt | :stay_put
          }
  end

  @spec evaluate(Root.t(), String.t(), Target.t()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target) do
    evaluate(manifest, route_id, target, [])
  end

  @spec evaluate(Root.t(), String.t(), Target.t(), keyword()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target, opts) do
    route = Map.get(manifest.routes, route_id)

    findings =
      manifest
      |> Compatibility.route_findings(route_id, target, opts)
      |> remap_commerce_corridor_findings(route)
      |> prepend_commerce_corridor_findings(route, manifest)

    denials = Enum.map(findings, &Compatibility.finding_to_denial(&1, Keyword.put(opts, :route_id, route_id)))
    status = if(denials == [], do: :allow, else: :deny)

    %Decision{
      route_id: route_id,
      status: status,
      denial: List.first(denials),
      denials: denials,
      transition: transition_for(status, opts)
    }
  end

  defp transition_for(:allow, _opts), do: :activate

  defp transition_for(:deny, opts) do
    if Keyword.get(opts, :activation_source) == :in_app_navigation do
      :stay_put
    else
      :halt
    end
  end

  defp prepend_commerce_corridor_findings(findings, %RouteEntry{} = route, %Root{} = manifest) do
    generated =
      []
      |> maybe_add_finding(commerce_corridor_undeclared(route, manifest))
      |> maybe_add_finding(commerce_corridor_runtime_incompatible(route, manifest))
      |> maybe_add_finding(commerce_corridor_policy_blocked(route, manifest))

    generated ++ findings
  end

  defp prepend_commerce_corridor_findings(findings, _route, _manifest), do: findings

  defp remap_commerce_corridor_findings(findings, %RouteEntry{commerce: nil}), do: findings
  defp remap_commerce_corridor_findings(findings, nil), do: findings

  defp remap_commerce_corridor_findings(findings, _route) do
    Enum.map(findings, fn %Finding{} = finding ->
      axis =
        case finding.axis do
          :entry -> :commerce_corridor_entry_denied
          :origin -> :commerce_corridor_origin_denied
          :pack_version -> :commerce_corridor_pack_incompatible
          :capability_registry -> :commerce_corridor_prerequisite_missing
          :capability_version -> :commerce_corridor_prerequisite_missing
          :manifest_source -> :commerce_corridor_unsupported
          :manifest_schema_version -> :commerce_corridor_runtime_incompatible
          :bridge_protocol_version -> :commerce_corridor_runtime_incompatible
          :native_runtime_version -> :commerce_corridor_runtime_incompatible
          other -> other
        end

      %Finding{finding | axis: axis}
    end)
  end

  defp commerce_corridor_undeclared(%RouteEntry{commerce: nil}, _manifest), do: nil

  defp commerce_corridor_undeclared(%RouteEntry{} = route, %Root{} = manifest) do
    corridor_ref = route.commerce.corridor_ref

    if is_binary(corridor_ref) and Map.has_key?(manifest.commerce_corridors, corridor_ref) do
      nil
    else
      %Finding{
        axis: :commerce_corridor_undeclared,
        route_id: route.id,
        required: corridor_ref,
        available: route.commerce.role,
        subject: corridor_ref,
        message: "route #{route.id} declares undeclared commerce corridor #{inspect(corridor_ref)}",
        hint: "declare the corridor profile or disable commerce for this route"
      }
    end
  end

  defp commerce_corridor_runtime_incompatible(%RouteEntry{commerce: nil}, _manifest), do: nil

  defp commerce_corridor_runtime_incompatible(%RouteEntry{} = route, %Root{} = manifest) do
    with corridor_ref when is_binary(corridor_ref) <- route.commerce.corridor_ref,
         corridor when not is_nil(corridor) <- Map.get(manifest.commerce_corridors, corridor_ref),
         ownership when not is_nil(ownership) <- Map.get(corridor.role_ownership, route.commerce.role),
         true <- ownership == :native_or_companion_required and route.runtime != :native_screen do
      %Finding{
        axis: :commerce_corridor_runtime_incompatible,
        route_id: route.id,
        required: :native_screen,
        available: route.runtime,
        subject: corridor_ref,
        message:
          "route #{route.id} requires native_screen runtime for commerce role #{inspect(route.commerce.role)}",
        hint: "move the commerce role to a native-owned corridor path before activation"
      }
    else
      _other -> nil
    end
  end

  defp commerce_corridor_policy_blocked(%RouteEntry{commerce: nil}, _manifest), do: nil

  defp commerce_corridor_policy_blocked(%RouteEntry{} = route, %Root{} = manifest) do
    with corridor_ref when is_binary(corridor_ref) <- route.commerce.corridor_ref,
         corridor when not is_nil(corridor) <- Map.get(manifest.commerce_corridors, corridor_ref) do
      role = route.commerce.role
      ownership = Map.get(corridor.role_ownership, role)

      cond do
        is_nil(ownership) ->
          %Finding{
            axis: :commerce_corridor_policy_blocked,
            route_id: route.id,
            required: corridor.role_ownership |> Map.keys() |> Enum.map_join(", ", &Atom.to_string/1),
            available: role,
            subject: corridor_ref,
            message:
              "route #{route.id} uses unsupported commerce role #{inspect(role)} for corridor #{inspect(corridor_ref)}",
            hint: "choose a supported role or adjust corridor ownership policy"
          }

        ownership == :phoenix_owned and route.runtime == :native_screen ->
          %Finding{
            axis: :commerce_corridor_policy_blocked,
            route_id: route.id,
            required: :phoenix_owned,
            available: route.runtime,
            subject: corridor_ref,
            message:
              "route #{route.id} is native_screen but corridor #{inspect(corridor_ref)} marks role #{inspect(role)} as phoenix_owned",
            hint: "route phoenix-owned roles through LiveView runtime or change corridor policy"
          }

        true ->
          nil
      end
    else
      _other -> nil
    end
  end

  defp maybe_add_finding(acc, nil), do: acc
  defp maybe_add_finding(acc, finding), do: [finding | acc]
end
