defmodule Crosswake.Doctor.JSONFormatter do
  @moduledoc """
  Stable JSON formatter for Crosswake doctor reports.
  """

  alias Crosswake.Doctor.Check

  @spec render(map()) :: String.t()
  def render(report) do
    payload = %{
      status: Map.get(report, :status) |> Atom.to_string(),
      support: format_support(Map.get(report, :support, %{})),
      shells: format_shells(Map.get(report, :shells, %{})),
      bridge: format_bridge(Map.get(report, :bridge, %{})),
      offline: format_offline(Map.get(report, :offline, %{})),
      findings: Enum.map(Map.get(report, :findings, []), &check_to_map/1)
    }

    Jason.encode!(payload, pretty: true)
  end

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
      unsupported_declared_capabilities:
        Map.get(bridge, :unsupported_declared_capabilities, [])
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
    %{
      severity: Atom.to_string(check.severity),
      code: check.code,
      message: check.message,
      hint: check.hint,
      check: check.check,
      details: check.details
    }
  end

  defp format_proof_status(:passed), do: "supported"
  defp format_proof_status(:failed), do: "failed"
  defp format_proof_status(:missing), do: "unsupported"
  defp format_proof_status(:verification_required), do: "verification required"
end
