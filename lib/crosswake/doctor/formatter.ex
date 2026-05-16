defmodule Crosswake.Doctor.Formatter do
  @moduledoc """
  Human-readable formatter for Crosswake doctor reports.
  """

  alias Crosswake.Doctor.Check

  @spec render(map()) :: String.t()
  def render(report) do
    findings = Map.get(report, :findings, [])

    [
      "Crosswake doctor report",
      "status: #{Map.get(report, :status)}",
      "findings: #{length(findings)}",
      format_support(Map.get(report, :support, %{})),
      format_shells(Map.get(report, :shells, %{})),
      format_bridge(Map.get(report, :bridge, %{})),
      format_findings(findings)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_support(%{status: status, blocking_platforms: blocking_platforms}) do
    blocked =
      case blocking_platforms do
        [] -> "none"
        platforms -> Enum.map_join(platforms, ", ", &Atom.to_string/1)
      end

    "support posture: #{status} (blocking: #{blocked})"
  end

  defp format_support(_support), do: nil

  defp format_shells(shells) when shells == %{}, do: nil

  defp format_shells(shells) do
    lines =
      shells
      |> Enum.sort_by(fn {platform, _shell} -> platform end)
      |> Enum.map(fn {_platform, shell} ->
        "#{shell.label}: generated=#{status_word(shell.generated.ok?)}, manifest-first=#{status_word(shell.manifest_first.ok?)}, route unavailable=#{status_word(shell.route_unavailable.ok?)}, bridge=#{status_word(shell.bridge.ok?)}, proof=#{shell.proof.status |> format_proof_status()}"
      end)

    ["shell posture:" | lines]
    |> Enum.join("\n")
  end

  defp format_bridge(%{protocol: protocol, version: version} = bridge) do
    commands =
      bridge
      |> Map.get(:allowed_commands, [])
      |> Enum.join(", ")

    denials =
      bridge
      |> Map.get(:denial_reasons, [])
      |> Enum.join(", ")

    "bridge posture: #{protocol}@#{version} commands=[#{commands}] denials=[#{denials}]"
  end

  defp format_bridge(_bridge), do: nil

  defp format_findings(findings) do
    findings
    |> Enum.sort_by(&severity_order/1)
    |> Enum.map(&format_check/1)
    |> Enum.join("\n\n")
  end

  defp format_check(%Check{} = check) do
    [
      "[#{check.severity}] #{check.check} (#{check.code})",
      check.message,
      check.hint && "hint: #{check.hint}",
      format_details(check.details)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_details(details) when details in [%{}, nil], do: nil

  defp format_details(details) when is_map(details) do
    details
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map_join(", ", fn {key, value} ->
      "#{key}=#{format_value(value)}"
    end)
    |> then(&"details: " <> &1)
  end

  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_atom(value), do: Atom.to_string(value)
  defp format_value(value) when is_list(value), do: Enum.map_join(value, "|", &format_value/1)
  defp format_value(value) when is_map(value), do: Jason.encode!(value)
  defp format_value(value), do: to_string(value)

  defp status_word(true), do: "yes"
  defp status_word(false), do: "no"

  defp format_proof_status(:passed), do: "supported"
  defp format_proof_status(:failed), do: "failed"
  defp format_proof_status(:missing), do: "unsupported"
  defp format_proof_status(:verification_required), do: "verification required"

  defp severity_order(%Check{severity: :error}), do: 0
  defp severity_order(%Check{severity: :warning}), do: 1
  defp severity_order(%Check{severity: :advisory}), do: 2
end
