defmodule Crosswake.SupportMatrix.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the canonical support matrix guide.
  """

  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  alias Crosswake.Manifest.Types.ActionClassEntry
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
  alias Crosswake.Manifest.Types.PromotionRuleEntry
  alias Crosswake.Manifest.Types.ReleaseBoundaryEntry

  @type action :: :created | :reused | :updated

  @spec render(SupportMatrix.t()) :: String.t()
  def render(%SupportMatrix{} = support_matrix) do
    [
      "# Crosswake Support Matrix",
      "",
      "This guide stays narrow and proof-oriented. The published iOS and Android shell claims",
      "below are backed by the checked-in example hosts plus the generated-shell verification",
      "hooks that now pass on the same host-owned artifact classes adopters ship.",
      "",
      "## Status Legend",
      "",
      "- supported",
      "- verification required",
      "- unsupported",
      "",
      section("Phoenix", support_matrix.phoenix),
      "",
      section("LiveView", support_matrix.live_view),
      "",
      section("iOS", support_matrix.ios),
      "",
      section("Android", support_matrix.android),
      "",
      section("Shell Artifacts", support_matrix.shells),
      "",
      capability_family_section(support_matrix.capability_families),
      "",
      commerce_corridor_section(Crosswake.SupportMatrix.commerce_corridors()),
      "",
      package_surface_section(support_matrix.package_surfaces),
      "",
      release_boundary_section(support_matrix.release_boundaries),
      "",
      change_class_section(support_matrix.change_classes),
      "",
      action_class_section(Crosswake.SupportMatrix.action_classes()),
      "",
      promotion_rule_section(Crosswake.SupportMatrix.promotion_rules()),
      "",
      notification_surface_section(),
      "",
      public_non_claims_section(),
      ""
    ]
    |> Enum.join("\n")
  end

  @spec write(String.t(), SupportMatrix.t()) :: {:ok, action()}
  def write(path, %SupportMatrix{} = support_matrix) do
    File.mkdir_p!(Path.dirname(path))

    contents = render(support_matrix)

    case File.read(path) do
      {:ok, ^contents} ->
        {:ok, :reused}

      {:ok, _previous} ->
        File.write!(path, contents)
        {:ok, :updated}

      {:error, :enoent} ->
        File.write!(path, contents)
        {:ok, :created}

      {:error, reason} ->
        raise "could not persist Crosswake support matrix guide #{path}: #{:file.format_error(reason)}"
    end
  end

  defp section(title, entries) do
    [
      "## #{title}",
      "",
      "| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |",
      "|--------|---------|----------|--------------|------------|------------|-------|",
      Enum.map_join(entries, "\n", &row/1)
    ]
    |> Enum.join("\n")
  end

  defp capability_family_section(entries) do
    [
      "## Capability Families",
      "",
      "| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |",
      "|--------|-------|---------|----------|--------------|---------|-------|---------|---------------|--------|----------|-------|",
      Enum.map_join(entries, "\n", &capability_row/1)
    ]
    |> Enum.join("\n")
  end

  defp package_surface_section(entries) do
    [
      "## Packaging Ledger",
      "",
      "`crosswake` remains the one primary public package. Companions are first-party-scoped typed boundaries, not plugin-market surfaces.",
      "",
      "| Surface | Class | Why | Release Burden | Public Guide |",
      "|---------|-------|-----|----------------|--------------|",
      Enum.map_join(entries, "\n", &package_surface_row/1)
    ]
    |> Enum.join("\n")
  end

  defp commerce_corridor_section(entries) do
    [
      "## Commerce Corridors",
      "",
      "| corridor_role | owner_posture | prerequisite_classes | prerequisites | denial_codes | fallback_behavior | proof_class | rebuild_requirement |",
      "|---------------|---------------|----------------------|---------------|--------------|-------------------|-------------|---------------------|",
      Enum.map_join(entries, "\n", &commerce_corridor_row/1)
    ]
    |> Enum.join("\n")
  end

  defp release_boundary_section(entries) do
    [
      "## Release And Versioning Policy",
      "",
      "package versions alone do not define support truth.",
      "",
      "| Target | Versioning | Compatibility Contract | Release Rule |",
      "|--------|------------|------------------------|--------------|",
      Enum.map_join(entries, "\n", &release_boundary_row/1)
    ]
    |> Enum.join("\n")
  end

  defp change_class_section(entries) do
    [
      "## Change Classes",
      "",
      "| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |",
      "|--------------|--------------|----------------|----------------------|----------------|",
      Enum.map_join(entries, "\n", &change_class_row/1)
    ]
    |> Enum.join("\n")
  end

  defp action_class_section(entries) do
    [
      "## Action Classes",
      "",
      "| action_class | subject | required_action | rebuild_required | reason | guide_anchor |",
      "|--------------|---------|-----------------|------------------|--------|--------------|",
      Enum.map_join(entries, "\n", &action_class_row/1)
    ]
    |> Enum.join("\n")
  end

  defp promotion_rule_section(entries) do
    [
      "## Promotion Rules",
      "",
      "Promotion rules keep advisory proof visible until evidence, docs, platform, and demotion criteria are all satisfied.",
      "",
      "| claim_id | current_state | promotes_to | evidence_class | required_evidence | minimum_consecutive_passes | freshness_window | failure_budget | required_platforms | required_docs_anchors | change_class | action_class | check_ids | demotion_trigger |",
      "|----------|---------------|-------------|----------------|-------------------|----------------------------|------------------|----------------|--------------------|-----------------------|--------------|--------------|-----------|------------------|",
      Enum.map_join(entries, "\n", &promotion_rule_row/1)
    ]
    |> Enum.join("\n")
  end

  defp notification_surface_section do
    [
      "## Notification Surface (v3.9)",
      "",
      "Crosswake provides explicitly bounded support for notifications via the Chimeway companion.",
      "",
      "**Supported:**",
      "- **Token binding:** The `notification_token` capability resolves local push tokens.",
      "- **notification-open routing:** Notification open resolved through RouteGate for manifest-known routes and route-local action allowlists.",
      "- **Route activation proof:** The notification-open workflow proof is hermetic route activation proof. RouteGate and Sigra decide activation; token/open evidence is not auth authority.",
      "- **Resolution limits:** Bounded bridge operations ensure requests complete predictably.",
      "- **Evidence redaction:** Diagnostic output actively redacts sensitive identifiers.",
      "",
      "**Deferred (Not Supported):**",
      "- **APNs/FCM delivery execution:** APNs/FCM delivery is not part of this proof, and Crosswake does not act as a push delivery service.",
      "- **Push metrics:** Delivery and read-receipt metrics are not tracked by the core framework.",
      "- **Deep UI native presentation:** Custom native notification UI presentation is left to the host shell.",
      "",
      "**Strict Telemetry Contract:**",
      "The telemetry event structure `[:crosswake, :notification, :*]` exposes low-cardinality delivery status and routing outcomes. **Raw payload data, device tokens, and PII are strictly forbidden and explicitly stripped from all diagnostic output.**"
    ]
    |> Enum.join("\n")
  end

  defp public_non_claims_section do
    [
      "## Public Non-Claims And Rough Edges",
      "",
      "- StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass.",
      "- Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contract machinery, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, and Phase 58 auth telemetry/security closeout are shipped for route predicates, `auth_posture`, route-local `auth_return`, `:step_up_required`, canonical `auth.handoff.*`, canonical `auth.step_up_intent.*`, canonical `auth.return.*` denial codes, stable `[:crosswake, :auth, ...]` telemetry events, and low-cardinality diagnostic metadata; refresh-token helpers, provider/device proof, provider templates, passkey SDK wrappers, direct shell/WebView token authority, and native auth UI remain deferred.",
      "- APNs/FCM push delivery execution, delivery metrics, and deep UI native notification presentation remain deferred; notification support focuses strictly on token binding, notification-open routing, RouteGate/Sigra route activation proof, and diagnostic telemetry.",
      "- Standalone public shell packages are deferred; generated iOS and Android shell projects remain host-owned scaffolds and checked-in example proof artifacts."
    ]
    |> Enum.join("\n")
  end

  defp row(%SupportEntry{} = entry) do
    proof = entry.proof || "-"
    notes = entry.notes || "-"

    boundaries =
      if entry.boundary_link do
        # Strip guides/ prefix if present for relative linking within the guides/ directory
        link = String.replace(entry.boundary_link, ~r/^guides\//, "")
        "[View Boundaries](#{link})"
      else
        "-"
      end

    "| #{escape_cell(entry.target)} | #{escape_cell(entry.version)} | #{format_status(entry.baseline_status || entry.status)} | #{format_status(entry.proof_status || entry.status)} | #{escape_cell(proof)} | #{boundaries} | #{escape_cell(notes)} |"
  end

  defp capability_row(%CapabilitySupportEntry{} = entry) do
    guide =
      if entry.guide do
        link = String.replace(entry.guide, ~r/^guides\//, "")
        "[Guide](#{link})"
      else
        "-"
      end

    prerequisites =
      case entry.prerequisites do
        [] -> "-"
        items -> Enum.map_join(items, "; ", &escape_cell/1)
      end

    "| #{escape_cell(entry.family)} | #{Atom.to_string(entry.owner)} | #{escape_cell(entry.posture || "-")} | #{format_status(entry.baseline_status || :supported)} | #{format_status(entry.proof_status || :supported)} | #{format_package_class(entry.package_class)} | #{format_proof_class(entry.proof_class)} | #{format_rebuild(entry.rebuild)} | #{prerequisites} | #{escape_cell(entry.denial || "-")} | #{escape_cell(entry.fallback || "-")} | #{guide} |"
  end

  defp package_surface_row(%PackageSurfaceEntry{} = entry) do
    "| #{escape_cell(entry.surface)} | #{format_package_class(entry.package_class)} | #{escape_cell(entry.why)} | #{escape_cell(entry.release_burden)} | #{format_guide_link(entry.guide)} |"
  end

  defp commerce_corridor_row(entry) do
    prerequisite_classes = format_atom_list(entry.prerequisite_classes)
    prerequisites = format_list(entry.prerequisites)
    denial_codes = format_list(entry.denial_codes)
    proof_class = format_proof_class(entry.proof_class)
    rebuild_requirement = format_rebuild_requirement(entry.rebuild_requirement)

    "| #{escape_cell(entry.corridor_role)} | #{escape_cell(entry.owner_posture)} | #{prerequisite_classes} | #{prerequisites} | #{denial_codes} | #{escape_cell(entry.fallback_behavior)} | #{proof_class} | #{rebuild_requirement} |"
  end

  defp release_boundary_row(%ReleaseBoundaryEntry{} = entry) do
    "| #{escape_cell(entry.target)} | #{escape_cell(entry.versioning)} | #{escape_cell(entry.compatibility_contract)} | #{escape_cell(entry.release_rule)} |"
  end

  defp change_class_row(%ChangeClassEntry{} = entry) do
    "| #{escape_cell(entry.change_class)} | #{escape_cell(entry.what_changed)} | #{escape_cell(entry.adopter_action)} | #{escape_cell(entry.compatibility_signal)} | #{escape_cell(entry.required_proof)} |"
  end

  defp action_class_row(%ActionClassEntry{} = entry) do
    "| #{escape_cell(entry.action_class)} | #{escape_cell(entry.subject)} | #{escape_cell(entry.required_action)} | #{format_boolean(entry.rebuild_required)} | #{escape_cell(entry.reason)} | #{escape_cell(entry.guide_anchor)} |"
  end

  defp promotion_rule_row(%PromotionRuleEntry{} = entry) do
    "| #{escape_cell(entry.claim_id)} | #{format_proof_class(entry.current_proof_class)} | #{format_promotion_target(entry.promotes_to)} | #{escape_cell(entry.evidence_class)} | #{format_list(entry.required_evidence)} | #{entry.minimum_consecutive_passes} | #{escape_cell(entry.freshness_window)} | #{escape_cell(entry.failure_budget)} | #{format_list(entry.required_platforms)} | #{format_list(entry.required_docs_anchors)} | #{escape_cell(entry.change_class)} | #{escape_cell(entry.action_class)} | #{format_list(entry.check_ids)} | #{escape_cell(entry.demotion_trigger)} |"
  end

  defp format_guide_link(guide) do
    link = String.replace(guide, ~r/^guides\//, "")
    "[Guide](#{link})"
  end

  defp format_status(:verification_required), do: "verification required"
  defp format_status(status), do: Atom.to_string(status)
  defp format_package_class(:example_docs_only), do: "example/docs-only"
  defp format_package_class(package_class), do: Atom.to_string(package_class)
  defp format_proof_class(:merge_blocking), do: "merge-blocking"
  defp format_proof_class(proof_class), do: Atom.to_string(proof_class)
  defp format_promotion_target(:merge_blocking), do: "merge-blocking"
  defp format_promotion_target(target), do: Atom.to_string(target)
  defp format_boolean(true), do: "true"
  defp format_boolean(false), do: "false"
  defp format_rebuild(:native_required), do: "native-required"
  defp format_rebuild(:companion_required), do: "companion-required"
  defp format_rebuild(rebuild), do: Atom.to_string(rebuild)

  defp format_list([]), do: "-"
  defp format_list(items), do: Enum.map_join(items, "; ", &escape_cell/1)

  defp format_atom_list([]), do: "-"
  defp format_atom_list(items), do: Enum.map_join(items, "; ", &Atom.to_string/1)

  defp format_rebuild_requirement(%{native_rebuild_required: required, rebuild_trigger: trigger}) do
    "native_rebuild_required=#{required}: #{escape_cell(trigger)}"
  end

  # Escape a value for inclusion as a single Markdown table cell. Replaces the
  # pipe character (which would otherwise break column layout) with the
  # backslash-escaped form GitHub Flavored Markdown understands, and collapses
  # embedded newlines into spaces so a multi-line value cannot rip the row in
  # two. Backslashes are doubled first so the cell-escape pass is reversible.
  # Returns "-" for nil so the renderer keeps emitting a placeholder rather
  # than an empty cell.
  defp escape_cell(nil), do: "-"

  defp escape_cell(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("|", "\\|")
    |> String.replace("\n", " ")
  end

  defp escape_cell(value), do: escape_cell(to_string(value))
end
