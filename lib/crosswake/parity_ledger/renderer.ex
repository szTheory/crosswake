defmodule Crosswake.ParityLedger.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the generated parity ledger guide.
  """

  alias Crosswake.ParityLedger
  alias Crosswake.SupportMatrix

  @type action :: :created | :reused | :updated

  @guide_path "guides/parity_ledger.md"

  @qualifier "The vector-set hash and this ledger are not in a published release yet; see CHANGELOG `[Unreleased]`."

  @spec render() :: String.t()
  def render, do: render(ParityLedger.facts())

  @spec render(map()) :: String.t()
  def render(facts) when is_map(facts) do
    [
      "# Crosswake Parity Ledger",
      "",
      "Canonical owner: `Crosswake.ParityLedger`.",
      "Regenerate with `mix crosswake.contract.gen && mix crosswake.docs.sync`.",
      "",
      "This guide is rendered from the shared contract corpora, the generated native constants and a registry of the tests that read each corpus. It shows which existing contracts the Elixir, Swift and Android suites execute, and which they do not.",
      "",
      "The vector-set hash is the SHA-256 of the raw bytes of the shared bridge corpus. Equal hashes prove that the Swift and Kotlin suites load identical corpus bytes. They do not prove that the assertions in those suites are semantically equivalent.",
      "",
      "The evidence is continuous integration on the repository head, not on a published artifact. `JVM test executed` means a Kotlin unit test ran on the JVM in CI; it says nothing about Android hardware.",
      "",
      @qualifier,
      "",
      corpora_section(facts),
      ""
    ]
    |> Enum.join("\n")
  end

  @spec write() :: {:ok, action()}
  def write, do: write(@guide_path)

  @spec write(String.t()) :: {:ok, action()}
  def write(path) when is_binary(path), do: write(path, ParityLedger.facts())

  @spec write(String.t(), map()) :: {:ok, action()}
  def write(path, facts) when is_binary(path) and is_map(facts) do
    File.mkdir_p!(Path.dirname(path))
    contents = render(facts)

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
        raise "could not persist Crosswake parity ledger guide #{path}: #{:file.format_error(reason)}"
    end
  end

  defp corpora_section(facts) do
    rows =
      Enum.map_join(facts.corpora, "\n", fn corpus ->
        "| #{escape_cell(corpus.id)} | #{escape_cell(files_cell(corpus))} | #{escape_cell(hash_cell(corpus))} | #{shared_cell(corpus)} | #{escape_cell(android_cell(facts, corpus))} |"
      end)

    [
      "## Corpora",
      "",
      "The bridge corpus is shared: three byte-identical copies, one hash, and a generated constant on each native side that must equal it. Every other corpus is read from one location, so its hash is informational and no native constant pins it.",
      "",
      @qualifier,
      "",
      "| Corpus | Files | Bytes sha256 | Shared | Android evidence |",
      "|--------|-------|--------------|--------|------------------|",
      rows
    ]
    |> Enum.join("\n")
  end

  defp files_cell(corpus), do: Enum.map_join(corpus.files, "; ", &"`#{&1.path}`")

  defp hash_cell(corpus) do
    corpus.files
    |> Enum.map(&hash_text/1)
    |> Enum.uniq()
    |> Enum.join("; ")
  end

  defp hash_text(%{sha256: nil}), do: "unreadable"
  defp hash_text(%{sha256: hex}), do: "sha256:" <> hex

  defp shared_cell(%{shared: true}), do: "yes"
  defp shared_cell(%{shared: false}), do: "no"

  defp android_cell(facts, %{id: id}) do
    level =
      if id == ParityLedger.bridge_corpus_id(),
        do: ParityLedger.android_level(facts),
        else: :not_claimed

    SupportMatrix.android_evidence_label(level)
  end

  @doc false
  @spec escape_cell(term()) :: String.t()
  def escape_cell(nil), do: "-"

  def escape_cell(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("|", "\\|")
    |> String.replace("\n", " ")
  end

  def escape_cell(value), do: escape_cell(to_string(value))
end
