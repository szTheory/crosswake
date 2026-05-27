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
      format_offline(Map.get(report, :offline, %{})),
      format_commerce_summary(Map.get(report, :commerce_summary, %{})),
      format_findings(findings)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_support(%{
         status: status,
         blocking_platforms: blocking_platforms,
         release_policy: release_policy
       }) do
    blocked =
      case blocking_platforms do
        [] -> "none"
        platforms -> Enum.map_join(platforms, ", ", &Atom.to_string/1)
      end

    [
      "support posture: #{status} (blocking: #{blocked})",
      format_release_policy(release_policy)
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

  defp format_release_policy(%{
         crosswake_version: crosswake_version,
         manifest_schema_version: manifest_schema_version,
         bridge_protocol_version: bridge_protocol_version,
         native_runtime_version: native_runtime_version,
         package_version_truth: package_version_truth,
         companion_requirement: companion_requirement,
         capability_families: capability_families,
         package_surfaces: package_surfaces,
         release_boundaries: release_boundaries,
         change_classes: change_classes
       }) do
    [
      "release policy:",
      "  crosswake_version=#{crosswake_version}",
      "  manifest_schema_version=#{manifest_schema_version}",
      "  bridge_protocol_version=#{bridge_protocol_version}",
      "  native_runtime_version=#{native_runtime_version}",
      "  #{package_version_truth}",
      "  #{companion_requirement}",
      format_capability_families(capability_families),
      format_package_surfaces(package_surfaces),
      format_release_boundaries(release_boundaries),
      format_change_classes(change_classes)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_release_policy(%{
         crosswake_version: crosswake_version,
         manifest_schema_version: manifest_schema_version,
         bridge_protocol_version: bridge_protocol_version,
         native_runtime_version: native_runtime_version,
         package_version_truth: package_version_truth,
         companion_requirement: companion_requirement
       }) do
    [
      "release policy:",
      "  crosswake_version=#{crosswake_version}",
      "  manifest_schema_version=#{manifest_schema_version}",
      "  bridge_protocol_version=#{bridge_protocol_version}",
      "  native_runtime_version=#{native_runtime_version}",
      "  #{package_version_truth}",
      "  #{companion_requirement}"
    ]
    |> Enum.join("\n")
  end

  defp format_release_policy(_release_policy), do: nil

  defp format_capability_families(families) do
    lines =
      Enum.map(families, fn family ->
        prereqs = if family.prerequisites == [], do: "none", else: Enum.join(family.prerequisites, ", ")
        "    #{family.family}: prerequisites=#{prereqs}, denial=#{family.denial || "none"}, fallback=#{family.fallback || "none"}"
      end)

    ["  capability families:" | lines] |> Enum.join("\n")
  end

  defp format_package_surfaces(surfaces) do
    lines =
      Enum.map(surfaces, fn surface ->
        "    #{surface.surface}: class=#{surface.package_class}, why=\"#{surface.why}\", burden=\"#{surface.release_burden}\""
      end)

    ["  package surfaces:" | lines] |> Enum.join("\n")
  end

  defp format_release_boundaries(boundaries) do
    lines =
      Enum.map(boundaries, fn boundary ->
        "    #{boundary.target}: versioning=\"#{boundary.versioning}\", rule=\"#{boundary.release_rule}\""
      end)

    ["  release boundaries:" | lines] |> Enum.join("\n")
  end

  defp format_change_classes(classes) do
    lines =
      Enum.map(classes, fn change_class ->
        "    #{change_class.change_class}: signal=\"#{change_class.compatibility_signal}\", proof=\"#{change_class.required_proof}\""
      end)

    ["  change classes:" | lines] |> Enum.join("\n")
  end

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

  defp format_offline(%{status: status, states: states, telemetry: telemetry, routes: routes}) do
    route_ids =
      routes
      |> Map.keys()
      |> Enum.sort()
      |> Enum.join(", ")

    [
      "offline posture: #{status} states=[#{Enum.join(states, ", ")}] routes=[#{route_ids}]",
      format_offline_telemetry(telemetry)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_offline(%{status: status, states: states, routes: routes}) do
    route_ids =
      routes
      |> Map.keys()
      |> Enum.sort()
      |> Enum.join(", ")

    "offline posture: #{status} states=[#{Enum.join(states, ", ")}] routes=[#{route_ids}]"
  end

  defp format_offline(_offline), do: nil

  defp format_offline_telemetry(%{metadata_keys: keys, terminal_outcomes: terminals}) do
    keys_text = if keys == [], do: "none", else: Enum.join(keys, ", ")
    terminals_text = if terminals == [], do: "none", else: Enum.join(terminals, ", ")
    "  telemetry: metadata_keys=[#{keys_text}] terminal_outcomes=[#{terminals_text}]"
  end

  defp format_offline_telemetry(_telemetry), do: nil

  defp format_commerce_summary(summary) when summary in [nil, %{}], do: nil

  defp format_commerce_summary(%{
         corridors: corridors,
         prerequisites: prerequisites,
         snapshot_freshness: snapshot_freshness,
         proof_posture: proof_posture,
         rebuild_requirements: rebuild_requirements
       }) do
    lines = [
      "Commerce:",
      "  snapshot_freshness: #{snapshot_freshness}",
      format_commerce_corridors(corridors),
      format_commerce_prerequisites(prerequisites),
      format_commerce_proof_posture(proof_posture),
      format_commerce_rebuild_requirements(rebuild_requirements)
    ]

    lines
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_commerce_summary(_summary), do: nil

  defp format_commerce_corridors([]), do: "  corridors: none"

  defp format_commerce_corridors(corridors) do
    rendered =
      Enum.map(corridors, fn corridor ->
        "    #{corridor.route_id}: corridor_ref=#{corridor.corridor_ref}, role=#{corridor.role}, owner=#{corridor.owner_posture || "unknown"}, rebuild=#{corridor.native_rebuild_required}, proof_class=[#{proof_class_label(corridor.proof_class)}]"
      end)

    ["  corridors:" | rendered] |> Enum.join("\n")
  end

  defp format_commerce_prerequisites(prerequisites) when prerequisites == %{}, do: nil

  defp format_commerce_prerequisites(prerequisites) do
    rendered =
      prerequisites
      |> Enum.sort_by(fn {route_id, _} -> route_id end)
      |> Enum.map(fn {route_id, prereqs} ->
        prereq_text = if prereqs == [], do: "none", else: Enum.join(prereqs, ", ")
        "    #{route_id}: #{prereq_text}"
      end)

    ["  prerequisites:" | rendered] |> Enum.join("\n")
  end

  defp format_commerce_proof_posture(%{merge_blocking: mb, advisory: adv}) do
    mb_text = if mb == [], do: "none", else: Enum.join(mb, ", ")
    adv_text = if adv == [], do: "none", else: Enum.join(adv, ", ")

    [
      "  proof_posture:",
      "    [merge-blocking]: #{mb_text}",
      "    [advisory]: #{adv_text}"
    ]
    |> Enum.join("\n")
  end

  defp format_commerce_proof_posture(_proof_posture), do: nil

  defp format_commerce_rebuild_requirements([]), do: "  rebuild_requirements: none"

  defp format_commerce_rebuild_requirements(requirements) do
    rendered =
      Enum.map(requirements, fn requirement ->
        "    #{requirement.route_id}: corridor_ref=#{requirement.corridor_ref}, role=#{requirement.role} — native rebuild required before commerce support advances"
      end)

    ["  rebuild_requirements:" | rendered] |> Enum.join("\n")
  end

  defp proof_class_label(:merge_blocking), do: "merge-blocking"
  defp proof_class_label(:advisory), do: "advisory"
  defp proof_class_label("merge_blocking"), do: "merge-blocking"
  defp proof_class_label("advisory"), do: "advisory"
  defp proof_class_label(other), do: to_string(other)

  defp format_findings(findings) do
    findings
    |> Enum.sort_by(&severity_order/1)
    |> Enum.map(&format_check/1)
    |> Enum.join("\n\n")
  end

  defp format_check(%Check{} = check) do
    [
      "[#{check.severity}] #{format_check_proof_class(check)}#{check.check} (#{check.code})",
      check.message,
      check.hint && "hint: #{check.hint}",
      format_commerce_corridor_fields(check),
      format_details(check.details)
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp format_check_proof_class(%Check{code: code, check: check_name, details: details}) do
    cond do
      commerce_check?(code, check_name) ->
        case detail(details, :proof_class) do
          nil -> ""
          label -> "[#{proof_class_label(label)}] "
        end

      true ->
        ""
    end
  end

  defp commerce_check?(code, check_name) do
    String.starts_with?(code || "", "commerce.") or
      check_name in ["commerce_corridor", "commerce_summary"]
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

  defp format_commerce_corridor_fields(%Check{code: code} = check) do
    if String.starts_with?(code, "commerce.corridor.") do
      corridor_ref = detail(check.details, :corridor_ref) || "unknown"
      role = detail(check.details, :role) |> format_value()
      denial_code = detail(check.details, :denial_code) || code
      fallback_hint = detail(check.details, :fallback_hint) || check.hint || "return_to_phoenix_guidance"

      "corridor: corridor_ref=#{corridor_ref} role=#{role} denial_code=#{denial_code} fallback_hint=#{fallback_hint}"
    end
  end

  # nil-safe: %Check{} allows details: nil even though the default is %{}, so
  # any caller (including hand-built test fixtures) that passes a nil details
  # map would otherwise raise FunctionClauseError from every detail/2 call site
  # (WR-08).
  defp detail(nil, _key), do: nil

  # Membership-based lookup so legitimate falsy values (e.g.
  # advisory_provider_proof: false) are returned as-is. The previous
  # `Map.get(...) || Map.get(...)` form fell through to the string-keyed
  # lookup whenever the atom-keyed value was false, silently overriding
  # correct data (WR-09).
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
