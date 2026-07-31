defmodule Crosswake.CapabilityMap.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the canonical capability map guide.
  """

  alias Crosswake.CapabilityMap

  @type action :: :created | :reused | :updated

  @guide_path "guides/capability_map.md"

  @row_fields [
    :id,
    :surface,
    :route_or_evidence_source,
    :category,
    :display_label,
    :route_runtime_owner,
    :package_owner,
    :proof_posture,
    :rebuild,
    :denial_fallback
  ]

  @spec render() :: String.t()
  def render do
    render(CapabilityMap.canonical())
  end

  @spec render([CapabilityMap.Row.t() | map()]) :: String.t()
  def render(rows) when is_list(rows) do
    rows = Enum.map(rows, &normalize_row/1)

    [
      "# Crosswake Capability Map",
      "",
      "This guide is rendered from `Crosswake.CapabilityMap`. It classifies what Crosswake supports today, what existing proof demonstrates, what the first adopter pressures, and what remains a future gap.",
      "",
      what_works_today_section(rows),
      "",
      what_evidence_exists_section(rows),
      "",
      adoption_priority_section(rows),
      "",
      detailed_rows_section(rows),
      ""
    ]
    |> Enum.join("\n")
  end

  @spec write(String.t()) :: {:ok, action()}
  def write(path) do
    write(path, CapabilityMap.canonical())
  end

  @spec write(String.t(), [CapabilityMap.Row.t() | map()]) :: {:ok, action()}
  def write(path, rows) when is_binary(path) and is_list(rows) do
    File.mkdir_p!(Path.dirname(path))
    contents = render(rows)

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
        raise "could not persist Crosswake capability map guide #{path}: #{:file.format_error(reason)}"
    end
  end

  @spec write() :: {:ok, action()}
  def write do
    write(@guide_path)
  end

  defp what_works_today_section(rows) do
    shipped_rows = Enum.filter(rows, &(&1.category == :shipped))

    [
      "## What works today",
      "",
      "Available today means the support claim is backed by typed route policy, manifest/support truth, and an explicit fallback. It is not a blanket device, provider, or plugin claim.",
      "",
      bullet_rows(shipped_rows)
    ]
    |> Enum.join("\n")
  end

  defp what_evidence_exists_section(rows) do
    evidence_rows = Enum.filter(rows, &(&1.category in [:demoed, :missing]))

    [
      "## What evidence exists",
      "",
      "Existing examples give proof-backed evidence and demo pressure across bounded bridge, offline study, native fallback, and capability-pressure rows. Screenshots are collateral after route-tour assertions; screenshots are not proof posture.",
      "",
      "Cached read-only is not offline mutation. Backend projection required means provider or storefront evidence is reconciliation input until the backend grants authority.",
      "",
      bullet_rows(evidence_rows)
    ]
    |> Enum.join("\n")
  end

  defp adoption_priority_section(rows) do
    candidate_rows = Enum.filter(rows, &(&1.category == :next_pack_candidate))
    deferred_rows = Enum.filter(rows, &(&1.category == :deferred))

    [
      "## What the first adopter changes",
      "",
      "Crosswake is currently infrastructure for one first adopter. Work is ordered by host-reusable proof, privacy-safe replay, one foreground iOS pronunciation-pack adapter, and physical-iPhone evidence. Android parity and native-control breadth are frozen.",
      "",
      "### Frozen candidates",
      "",
      bullet_rows(candidate_rows),
      "",
      "### Deferred surfaces",
      "",
      bullet_rows(deferred_rows)
    ]
    |> Enum.join("\n")
  end

  defp detailed_rows_section(rows) do
    [
      "## Detailed Capability Rows",
      "",
      "| Capability or surface | Display label | Route or evidence source | Current category | Route runtime owner | Package owner | Proof posture | Rebuild | Denial/fallback behavior | Adoption implication |",
      "|-----------------------|---------------|--------------------------|------------------|---------------------|---------------|---------------|---------|--------------------------|-----------------|",
      Enum.map_join(rows, "\n", &table_row/1)
    ]
    |> Enum.join("\n")
  end

  defp bullet_rows([]), do: "- No capability rows defined."

  defp bullet_rows(rows) do
    Enum.map_join(rows, "\n", fn row ->
      "- **#{escape_inline(row.surface)}** — #{escape_inline(row.display_label)}; #{escape_inline(row.adoption_implication)}"
    end)
  end

  defp table_row(row) do
    "| #{escape_cell(row.surface)} | #{escape_cell(row.display_label)} | #{escape_cell(row.route_or_evidence_source)} | #{escape_cell(category_label(row.category))} | #{escape_cell(owner_label(row.route_runtime_owner))} | #{escape_cell(owner_label(row.package_owner))} | #{escape_cell(proof_label(row.proof_posture))} | #{escape_cell(rebuild_label(row.rebuild))} | #{escape_cell(row.denial_fallback)} | #{escape_cell(row.adoption_implication)} |"
  end

  # D-12 compatibility window: map-based renderer callers may keep supplying
  # `v20_implication` until this documented alias is removed in a future breaking change.
  # Canonical rows and renderer output use `adoption_implication` exclusively.
  defp normalize_row(%_{} = row), do: row |> Map.from_struct() |> normalize_implication()

  defp normalize_row(row) when is_map(row) do
    row
    |> normalize_string_keys()
    |> normalize_implication()
  end

  defp normalize_string_keys(row) do
    Enum.reduce(@row_fields, row, fn field, normalized ->
      case implication_value(normalized, field) do
        {:present, value} -> Map.put(normalized, field, value)
        :missing -> normalized
      end
    end)
  end

  defp normalize_implication(row) do
    canonical = implication_value(row, :adoption_implication)
    legacy = implication_value(row, :v20_implication)

    implication =
      case {canonical, legacy} do
        {{:present, canonical_value}, {:present, legacy_value}}
        when canonical_value != legacy_value ->
          raise ArgumentError, "conflicting adoption_implication and v20_implication"

        {{:present, value}, _} -> value
        {:missing, {:present, value}} -> value
        {:missing, :missing} -> nil
      end

    row
    |> Map.delete(:v20_implication)
    |> Map.delete("v20_implication")
    |> Map.put(:adoption_implication, implication)
  end

  defp implication_value(row, field) do
    string_field = Atom.to_string(field)

    cond do
      Map.has_key?(row, field) -> {:present, Map.fetch!(row, field)}
      Map.has_key?(row, string_field) -> {:present, Map.fetch!(row, string_field)}
      true -> :missing
    end
  end

  defp category_label(:next_pack_candidate), do: "next-pack candidate"
  defp category_label(value), do: value |> Atom.to_string() |> String.replace("_", "-")

  defp owner_label(:native_shell), do: "native shell"
  defp owner_label(:first_party_companion), do: "first-party companion"
  defp owner_label(:example_docs_only), do: "example/docs-only"

  defp owner_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", " ")

  defp owner_label(value), do: to_string(value)

  defp proof_label(:merge_blocking), do: "merge-blocking"
  defp proof_label(:not_yet_proven), do: "not-yet-proven"

  defp proof_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", "-")

  defp proof_label(value), do: to_string(value)

  # D-53: spelled out (not just "none"/"native-required") so the word "rebuild"
  # is visible on every row of the guide adopters read to choose controls —
  # rebuild cost must never require decoding a bare enum value.
  defp rebuild_label(:none), do: "No rebuild required"
  defp rebuild_label(:native_required), do: "Native rebuild required"
  defp rebuild_label(:companion_required), do: "Companion rebuild required"

  defp rebuild_label(value) when is_atom(value),
    do: value |> Atom.to_string() |> String.replace("_", " ")

  defp rebuild_label(value), do: to_string(value)

  defp escape_inline(value) do
    value
    |> escape_cell()
    |> String.replace("**", "\\*\\*")
  end

  defp escape_cell(nil), do: "-"

  defp escape_cell(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("|", "\\|")
    |> String.replace("\n", " ")
  end

  defp escape_cell(value), do: escape_cell(to_string(value))
end
