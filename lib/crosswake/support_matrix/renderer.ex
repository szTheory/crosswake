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
      "This guide stays narrow and proof-oriented. A `supported` shell claim is blocked and",
      "remains `verification required` until both generated-project proof hooks pass on the",
      "same host-owned iOS and Android shell artifacts adopters ship.",
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
      "| Target | Version | Status | Proof | Notes |",
      "|--------|---------|--------|-------|-------|",
      Enum.map_join(entries, "\n", &row/1)
    ]
    |> Enum.join("\n")
  end

  defp row(%SupportEntry{} = entry) do
    proof = entry.proof || "-"
    notes = entry.notes || "-"

    "| #{entry.target} | #{entry.version} | #{format_status(entry.status)} | #{proof} | #{notes} |"
  end

  defp format_status(:verification_required), do: "verification required"
  defp format_status(status), do: Atom.to_string(status)
end
