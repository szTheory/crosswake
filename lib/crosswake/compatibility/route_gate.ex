defmodule Crosswake.Compatibility.RouteGate do
  @moduledoc """
  Fail-closed route activation decisions derived from layered compatibility findings.
  """

  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Evaluator
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
            transition: :activate | :halt | :stay_put | {:redirect, atom()}
          }
  end

  @spec evaluate(Root.t(), String.t(), Target.t()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target) do
    evaluate(manifest, route_id, target, [])
  end

  @spec evaluate(Root.t(), String.t(), Target.t(), keyword()) :: Decision.t()
  def evaluate(%Root{} = manifest, route_id, %Target{} = target, opts) do
    route = Map.get(manifest.routes, route_id)

    # Gate evaluation produces Denial.t() directly (bypasses finding_to_denial/2)
    gate_denials = prepend_gate_evaluation_findings([], route, target)

    auth_denials = prepend_auth_evaluation_denials([], route, opts, gate_denials)

    findings =
      manifest
      |> Compatibility.route_findings(route_id, target, opts)
      |> remap_commerce_corridor_findings(route)
      |> prepend_commerce_corridor_findings(route, manifest)

    compatibility_denials =
      Enum.map(
        findings,
        &Compatibility.finding_to_denial(&1, Keyword.put(opts, :route_id, route_id))
      )

    # Gate denials prepend before compatibility denials (fail-closed: gate fires first)
    denials = gate_denials ++ auth_denials ++ compatibility_denials
    status = if(denials == [], do: :allow, else: :deny)

    %Decision{
      route_id: route_id,
      status: status,
      denial: List.first(denials),
      denials: denials,
      transition: transition_for(status, route, opts)
    }
  end

  defp transition_for(:allow, _route, _opts), do: :activate

  defp transition_for(:deny, route, opts) do
    if Keyword.get(opts, :activation_source) == :notification do
      :halt
    else
      transition_for_non_notification_denial(route, opts)
    end
  end

  defp transition_for_non_notification_denial(%RouteEntry{on_unavailable: {:fallback_phoenix, id}}, _opts) do
    {:redirect, id}
  end

  defp transition_for_non_notification_denial(_route, opts) do
    if Keyword.get(opts, :activation_source) == :in_app_navigation do
      :stay_put
    else
      :halt
    end
  end

  # ---------------------------------------------------------------------------
  # Gate evaluation step — returns [Denial.t()] directly, bypasses finding_to_denial/2
  # (flag_key and evaluated_at are RouteGate-scoped, not Finding-scoped)
  # ---------------------------------------------------------------------------

  # Unknown route (nil) — skip gate evaluation
  defp prepend_gate_evaluation_findings(acc, nil, _target), do: acc

  # Non-gated route — skip both kill-switch and gate evaluation (D-11)
  defp prepend_gate_evaluation_findings(acc, %RouteEntry{gated_by: nil}, _target), do: acc

  # Gated route — run kill-switch first (short-circuit), then gate check
  defp prepend_gate_evaluation_findings(acc, %RouteEntry{} = route, %Target{} = target) do
    companions =
      Application.get_env(:crosswake, :companions, [])
      |> Enum.filter(fn companion ->
        config = Application.get_env(:crosswake, companion.companion_id(), %{})
        companion.enabled?(config)
      end)

    case check_kill_switches(companions, route, target) do
      {:kill_switch, denial} ->
        [denial | acc]

      :pass ->
        case check_gate(companions, route, target) do
          {:gate_denied, denial} -> [denial | acc]
          :pass -> acc
        end
    end
  end

  defp check_kill_switches(companions, route, target) do
    Enum.reduce_while(companions, :pass, fn companion, _acc ->
      result =
        :telemetry.span(
          [:crosswake, :companion, :kill_switch],
          %{companion_id: companion.companion_id(), route_id: route.id},
          fn ->
            active = companion.kill_switch_active?(target)
            {active, %{companion_id: companion.companion_id(), route_id: route.id}}
          end
        )

      if result do
        denial =
          Denial.new(
            reason: :kill_switch_active,
            message: "kill switch active for companion #{companion.companion_id()}",
            route_id: route.id,
            details: %{"companion_id" => Atom.to_string(companion.companion_id())}
          )

        {:halt, {:kill_switch, denial}}
      else
        {:cont, :pass}
      end
    end)
  end

  defp check_gate(companions, route, target) do
    Enum.reduce_while(companions, :pass, fn companion, _acc ->
      result =
        :telemetry.span(
          [:crosswake, :companion, :route_gate],
          %{companion_id: companion.companion_id(), route_id: route.id},
          fn ->
            gated = companion.route_gated?(route, target)
            {gated, %{companion_id: companion.companion_id(), route_id: route.id}}
          end
        )

      case result do
        {:deny, _finding} ->
          denial =
            Denial.new(
              reason: :gate_denied,
              message:
                "route #{route.id} denied by companion #{companion.companion_id()} — flag #{route.gated_by} is disabled",
              route_id: route.id,
              details: %{
                "flag_key" => Atom.to_string(route.gated_by),
                "reason" => "DISABLED",
                "variant" => "off",
                "evaluated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
              }
            )

          {:halt, {:gate_denied, denial}}

        :pass ->
          {:cont, :pass}
      end
    end)
  end

  defp prepend_auth_evaluation_denials(acc, _route, _opts, gate_denials) when gate_denials != [],
    do: acc

  defp prepend_auth_evaluation_denials(acc, nil, _opts, _gate_denials), do: acc

  defp prepend_auth_evaluation_denials(acc, %RouteEntry{} = route, opts, _gate_denials) do
    case Evaluator.evaluate_route_auth(route, Keyword.get(opts, :auth_context), opts) do
      {:allow, _result} -> acc
      {:deny, denial} -> [denial | acc]
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
        message:
          "route #{route.id} declares undeclared commerce corridor #{inspect(corridor_ref)}",
        hint: "declare the corridor profile or disable commerce for this route"
      }
    end
  end

  defp commerce_corridor_runtime_incompatible(%RouteEntry{commerce: nil}, _manifest), do: nil

  defp commerce_corridor_runtime_incompatible(%RouteEntry{} = route, %Root{} = manifest) do
    with corridor_ref when is_binary(corridor_ref) <- route.commerce.corridor_ref,
         corridor when not is_nil(corridor) <- Map.get(manifest.commerce_corridors, corridor_ref),
         ownership when not is_nil(ownership) <-
           Map.get(corridor.role_ownership, route.commerce.role),
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
            required:
              corridor.role_ownership |> Map.keys() |> Enum.map_join(", ", &Atom.to_string/1),
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
