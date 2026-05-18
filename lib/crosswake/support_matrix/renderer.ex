defmodule Crosswake.SupportMatrix.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the canonical support matrix guide.
  """

  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix

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
      "| Target | Version | Status | Proof | Boundaries | Notes |",
      "|--------|---------|--------|-------|------------|-------|",
      Enum.map_join(entries, "\n", &row/1)
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

    "| #{entry.target} | #{entry.version} | #{format_status(entry.status)} | #{proof} | #{boundaries} | #{notes} |"
  end

  defp format_status(:verification_required), do: "verification required"
  defp format_status(status), do: Atom.to_string(status)
end
