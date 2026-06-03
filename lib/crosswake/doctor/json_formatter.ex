defmodule Crosswake.Doctor.JSONFormatter do
  @moduledoc """
  Stable JSON formatter for Crosswake doctor reports.
  """

  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.PublishReadiness

  @spec render(map()) :: String.t()
  def render(report) do
    payload =
      %{
        status: Map.get(report, :status) |> Atom.to_string(),
        support: format_support(Map.get(report, :support, %{})),
        shells: format_shells(Map.get(report, :shells, %{})),
        bridge: format_bridge(Map.get(report, :bridge, %{})),
        offline: format_offline(Map.get(report, :offline, %{})),
        commerce_summary: format_commerce_summary(Map.get(report, :commerce_summary, %{})),
        findings: Enum.map(Map.get(report, :findings, []), &check_to_map/1)
      }
      |> maybe_put_publish_readiness(Map.get(report, :publish_readiness))

    Jason.encode!(payload, pretty: true)
  end

  defp maybe_put_publish_readiness(payload, nil), do: payload

  defp maybe_put_publish_readiness(payload, %PublishReadiness.Report{} = report) do
    Map.put(payload, :publish_readiness, PublishReadiness.to_map(report))
  end

  defp format_commerce_summary(summary) when summary in [nil, %{}], do: %{}

  defp format_commerce_summary(%{
         corridors: corridors,
         prerequisites: prerequisites,
         snapshot_freshness: snapshot_freshness,
         proof_posture: proof_posture,
         rebuild_requirements: rebuild_requirements
       }) do
    %{
      corridors: Enum.map(corridors, &format_commerce_corridor/1),
      prerequisites: prerequisites,
      snapshot_freshness: Atom.to_string(snapshot_freshness),
      proof_posture: format_commerce_proof_posture(proof_posture),
      rebuild_requirements: Enum.map(rebuild_requirements, &format_commerce_rebuild_requirement/1)
    }
  end

  defp format_commerce_summary(_summary), do: %{}

  defp format_commerce_corridor(corridor) do
    %{
      route_id: corridor.route_id,
      corridor_ref: corridor.corridor_ref,
      role: corridor.role,
      owner_posture: corridor.owner_posture,
      native_rebuild_required: corridor.native_rebuild_required,
      proof_class: atom_label(corridor.proof_class),
      advisory_provider_proof: corridor.advisory_provider_proof
    }
  end

  defp format_commerce_proof_posture(%{merge_blocking: mb, advisory: adv}) do
    %{
      "merge_blocking" => mb,
      "advisory" => adv
    }
  end

  defp format_commerce_proof_posture(other), do: other

  defp format_commerce_rebuild_requirement(requirement) do
    %{
      route_id: requirement.route_id,
      corridor_ref: requirement.corridor_ref,
      role: requirement.role
    }
  end

  defp atom_label(value) when is_atom(value), do: Atom.to_string(value)
  defp atom_label(value), do: value

  defp format_support(%{status: status} = support) do
    %{
      status: Atom.to_string(status),
      blocking_platforms:
        support
        |> Map.get(:blocking_platforms, [])
        |> Enum.map(&Atom.to_string/1),
      proof_statuses:
        support
        |> Map.get(:proof_statuses, %{})
        |> Enum.into(%{}, fn {platform, proof_status} ->
          {Atom.to_string(platform), format_proof_status(proof_status)}
        end),
      release_policy: format_release_policy(Map.get(support, :release_policy))
    }
  end

  defp format_support(_support), do: %{}

  defp format_release_policy(nil), do: nil

  defp format_release_policy(release_policy) do
    %{
      crosswake_version: release_policy.crosswake_version,
      manifest_schema_version: release_policy.manifest_schema_version,
      bridge_protocol_version: release_policy.bridge_protocol_version,
      native_runtime_version: release_policy.native_runtime_version,
      package_version_truth: release_policy.package_version_truth,
      companion_requirement: release_policy.companion_requirement,
      package_surfaces: release_policy.package_surfaces,
      change_classes: release_policy.change_classes
    }
  end

  defp format_shells(shells) do
    Enum.into(shells, %{}, fn {platform, shell} ->
      {Atom.to_string(platform),
       %{
         label: shell.label,
         shell_root: shell.shell_root,
         generated: artifact_state(shell.generated),
         manifest_first: artifact_state(shell.manifest_first),
         route_unavailable: artifact_state(shell.route_unavailable),
         bridge: artifact_state(shell.bridge),
         proof: %{
           status: format_proof_status(shell.proof.status),
           script_path: shell.proof.script_path,
           exit_status: shell.proof.exit_status,
           output_excerpt: shell.proof.output_excerpt
         }
       }}
    end)
  end

  defp format_bridge(%{protocol: protocol, version: version} = bridge) do
    %{
      protocol: protocol,
      version: version,
      allowed_commands: Map.get(bridge, :allowed_commands, []),
      denial_reasons: Map.get(bridge, :denial_reasons, []),
      command_posture: Map.get(bridge, :command_posture, []),
      unsupported_declared_capabilities: Map.get(bridge, :unsupported_declared_capabilities, [])
    }
  end

  defp format_bridge(_bridge), do: %{}

  defp format_offline(%{status: status, states: states, telemetry: telemetry, routes: routes}) do
    %{
      status: Atom.to_string(status),
      states: states,
      telemetry: telemetry,
      routes: routes
    }
  end

  defp format_offline(_offline), do: %{}

  defp artifact_state(inspection) do
    %{
      present: inspection.ok?,
      missing: inspection.missing
    }
  end

  defp check_to_map(%Check{} = check) do
    base = %{
      severity: Atom.to_string(check.severity),
      code: check.code,
      message: check.message,
      hint: check.hint,
      check: check.check,
      details: check.details
    }

    base =
      cond do
        commerce_check?(check.code, check.check) and detail(check.details, :proof_class) ->
          Map.put(
            base,
            :proof_class,
            detail(check.details, :proof_class) |> maybe_atom_to_string()
          )

        true ->
          base
      end

    if String.starts_with?(check.code, "commerce.corridor.") and
         check.check == "commerce_corridor" do
      Map.merge(base, %{
        corridor_ref: detail(check.details, :corridor_ref),
        role: detail(check.details, :role) |> maybe_atom_to_string(),
        denial_code: detail(check.details, :denial_code) || check.code,
        fallback_hint: detail(check.details, :fallback_hint) || check.hint
      })
    else
      base
    end
  end

  defp commerce_check?(code, check_name) do
    String.starts_with?(code || "", "commerce.") or
      check_name in ["commerce_corridor", "commerce_summary"]
  end

  defp format_proof_status(:passed), do: "supported"
  defp format_proof_status(:failed), do: "failed"
  defp format_proof_status(:missing), do: "unsupported"
  defp format_proof_status(:verification_required), do: "verification required"

  # nil-safe: %Check{} permits details: nil even though %{} is the default, so
  # a hand-built Check with nil details would otherwise raise FunctionClauseError
  # from every check_to_map/1 detail lookup (WR-08).
  defp detail(nil, _key), do: nil

  # Membership-based lookup so legitimate falsy values (e.g.
  # advisory_provider_proof: false) survive — the previous
  # `Map.get(...) || Map.get(...)` form silently fell through to the
  # string-keyed lookup whenever the atom-keyed value was false (WR-09).
  defp detail(details, key) when is_map(details) do
    cond do
      Map.has_key?(details, key) ->
        Map.get(details, key)

      is_atom(key) and Map.has_key?(details, Atom.to_string(key)) ->
        Map.get(details, Atom.to_string(key))

      true ->
        nil
    end
  end

  defp maybe_atom_to_string(value) when is_atom(value), do: Atom.to_string(value)
  defp maybe_atom_to_string(value), do: value
end
