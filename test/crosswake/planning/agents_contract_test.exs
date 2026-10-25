defmodule Crosswake.Planning.AgentsContractTest do
  # Reads the live AGENTS.md relative to the cwd, like first_adopter_context_test.
  use ExUnit.Case, async: true

  @agents "AGENTS.md"
  @adr ".planning/ADR-FIRST-B2C-ADOPTER.md"
  @bearings ".planning/BEARINGS.md"

  @gate_phrases [
    "`allow`",
    "`hold`",
    "one-use",
    "merges to `main`",
    "merging the release PR",
    "Hex, Maven or iOS publish",
    "creating or pushing tags",
    "deleting a remote branch",
    "never transfers to another attempt"
  ]

  defp collapse(text), do: String.replace(text, ~r/\s+/, " ")

  defp gate_ok?(text) do
    collapsed = collapse(text)
    Enum.all?(@gate_phrases, &String.contains?(collapsed, &1))
  end

  defp first_context_item(text) do
    text
    |> String.split("\n")
    |> Enum.drop_while(&(&1 != "## Project Context"))
    |> Enum.drop(1)
    |> Enum.find(&Regex.match?(~r/^(- |1\. )/, &1))
  end

  test "live AGENTS.md keeps the approval gate and names the governing ADR" do
    text = File.read!(@agents)

    assert gate_ok?(text)
    assert String.contains?(text, @adr)
  end

  test "BEARINGS is the first Project Context item" do
    item = first_context_item(File.read!(@agents))

    assert is_binary(item)
    assert String.contains?(item, @bearings)
  end

  for phrase <- @gate_phrases do
    test "negative control: removing #{inspect(phrase)} breaks the gate predicate" do
      text = File.read!(@agents)
      phrase = unquote(phrase)

      assert String.contains?(collapse(text), phrase),
             "live AGENTS.md does not contain gate phrase #{inspect(phrase)}"

      mutated = String.replace(collapse(text), phrase, "REMOVED")

      refute gate_ok?(mutated),
             "gate predicate stayed true after removing #{inspect(phrase)}"
    end
  end

  test "negative control: ROLLING as the first Project Context item fails the first-item predicate" do
    text = File.read!(@agents)

    mutated =
      String.replace(text, @bearings, ".planning/ROADMAP-ROLLING.md", global: false)

    refute String.contains?(first_context_item(mutated), @bearings)
  end
end
