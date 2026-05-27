defmodule Crosswake.SupportMatrix.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the canonical support matrix guide.
  """

  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
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
      "| corridor_role | owner_posture | prerequisites | denial_codes | fallback_behavior | native_rebuild_required |",
      "|---------------|---------------|---------------|--------------|-------------------|-------------------------|",
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

    "| #{entry.target} | #{entry.version} | #{format_status(entry.baseline_status || entry.status)} | #{format_status(entry.proof_status || entry.status)} | #{proof} | #{boundaries} | #{notes} |"
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
        items -> Enum.join(items, "; ")
      end

    "| #{entry.family} | #{Atom.to_string(entry.owner)} | #{entry.posture || "-"} | #{format_status(entry.baseline_status || :supported)} | #{format_status(entry.proof_status || :supported)} | #{format_package_class(entry.package_class)} | #{format_proof_class(entry.proof_class)} | #{format_rebuild(entry.rebuild)} | #{prerequisites} | #{entry.denial || "-"} | #{entry.fallback || "-"} | #{guide} |"
  end

  defp package_surface_row(%PackageSurfaceEntry{} = entry) do
    "| #{entry.surface} | #{format_package_class(entry.package_class)} | #{entry.why} | #{entry.release_burden} | #{format_guide_link(entry.guide)} |"
  end

  defp commerce_corridor_row(entry) do
    prerequisites = format_list(entry.prerequisites)
    denial_codes = format_list(entry.denial_codes)

    "| #{entry.corridor_role} | #{entry.owner_posture} | #{prerequisites} | #{denial_codes} | #{entry.fallback_behavior} | #{entry.native_rebuild_required} |"
  end

  defp release_boundary_row(%ReleaseBoundaryEntry{} = entry) do
    "| #{entry.target} | #{entry.versioning} | #{entry.compatibility_contract} | #{entry.release_rule} |"
  end

  defp change_class_row(%ChangeClassEntry{} = entry) do
    "| #{entry.change_class} | #{entry.what_changed} | #{entry.adopter_action} | #{entry.compatibility_signal} | #{entry.required_proof} |"
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
  defp format_rebuild(:native_required), do: "native-required"
  defp format_rebuild(:companion_required), do: "companion-required"
  defp format_rebuild(rebuild), do: Atom.to_string(rebuild)

  defp format_list([]), do: "-"
  defp format_list(items), do: Enum.join(items, "; ")
end
