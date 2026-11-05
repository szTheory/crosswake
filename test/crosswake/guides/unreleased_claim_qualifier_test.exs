defmodule Crosswake.Guides.UnreleasedClaimQualifierTest do
  @moduledoc """
  Linked guides that name behavior no published release has must say so (D-26).

  Published 0.2.11 does not read `config :crosswake, :ios_host` and emits manifest schema
  `1.1.0`. Every heading-delimited section of the named guides that mentions the claim token
  must carry, in its prose outside code fences, both `not in a published release yet` and a
  pointer to CHANGELOG `[Unreleased]`.

  Phase 199 removes or rewords these qualifiers, and this test, in the human PR that records
  0.2.12 as published (never in the release-please bot PR).

  Network-free: it reads only checked-in guides.
  """

  use ExUnit.Case, async: true

  @qualifier "not in a published release yet"
  @pointer "[Unreleased]"

  # {guide, token}. Each pair is a claim a first adopter on 0.2.11 could read as shipped.
  @claims [
    {"guides/capability_map.md", ":ios_host"}
  ]

  describe "sections/1" do
    test "splits at headings and keeps fences inside their section" do
      text = """
      # Title

      intro

      ## One

      ```elixir
      # not a heading
      config :crosswake, :ios_host
      ```

      ## Two

      tail
      """

      assert [{"# Title", _}, {"## One", one}, {"## Two", two}] = sections(text)
      assert one =~ "# not a heading"
      refute two =~ "ios_host"
    end
  end

  describe "claims" do
    for {file, token} <- @claims do
      test "#{file} mentions #{token} in at least one section (non-vacuous)" do
        text = File.read!(unquote(file))

        assert Enum.any?(sections(text), fn {heading, body} ->
                 String.contains?(heading <> "\n" <> body, unquote(token))
               end),
               "#{unquote(file)} has no section mentioning #{unquote(token)}; the claim matches nothing"
      end

      test "#{file}: every section mentioning #{token} carries the unreleased qualifier" do
        text = File.read!(unquote(file))

        assert unqualified_sections(text, unquote(token)) == [],
               "#{unquote(file)}: sections mentioning #{unquote(token)} lack the " <>
                 "'#{@qualifier}' qualifier with a CHANGELOG #{@pointer} pointer (D-26): " <>
                 inspect(unqualified_sections(text, unquote(token)))
      end
    end
  end

  describe "removal control" do
    test "a copy of the capability map without the qualifier sentence is flagged" do
      original = File.read!("guides/capability_map.md")

      copy =
        String.replace(
          original,
          " The `:ios_host` declaration is not in a published release yet (0.2.11 and earlier do not read it); see CHANGELOG `[Unreleased]`.",
          ""
        )

      if copy == original do
        raise "control did not change the copy: the qualifier sentence was not found"
      end

      assert unqualified_sections(original, ":ios_host") == []
      assert unqualified_sections(copy, ":ios_host") == ["## Declared iOS Host Setup"]
    end

    test "a qualifier that appears only inside a code fence does not count" do
      text = """
      ## Section

      The `:ios_host` declaration is read by the generator.

      ```
      not in a published release yet; see [Unreleased]
      ```
      """

      assert unqualified_sections(text, ":ios_host") == ["## Section"]
    end
  end

  # Splits a guide at every line that starts with `#` (outside a fence) into
  # `{heading, body}` pairs. Fenced blocks stay inside the section body.
  defp sections(text) do
    {acc, _in_fence} =
      text
      |> String.split("\n")
      |> Enum.reduce({[], false}, fn line, {acc, in_fence} ->
        trimmed = String.trim(line)
        fence_line? = String.starts_with?(trimmed, "```")
        in_fence_after = if fence_line?, do: not in_fence, else: in_fence

        cond do
          not in_fence and not fence_line? and String.starts_with?(line, "#") ->
            {[{line, ""} | acc], in_fence_after}

          acc == [] ->
            {[{"", line <> "\n"}], in_fence_after}

          true ->
            [{heading, body} | rest] = acc
            {[{heading, body <> line <> "\n"} | rest], in_fence_after}
        end
      end)

    Enum.reverse(acc)
  end

  # Headings of sections that mention `token` anywhere but whose prose outside code fences
  # lacks the qualifier or the CHANGELOG pointer.
  defp unqualified_sections(text, token) do
    text
    |> sections()
    |> Enum.filter(fn {heading, body} -> String.contains?(heading <> "\n" <> body, token) end)
    |> Enum.reject(fn {_heading, body} ->
      prose = prose_outside_fences(body)
      String.contains?(prose, @qualifier) and String.contains?(prose, @pointer)
    end)
    |> Enum.map(fn {heading, _body} -> heading end)
  end

  defp prose_outside_fences(body) do
    {lines, _} =
      body
      |> String.split("\n")
      |> Enum.reduce({[], false}, fn line, {keep, in_fence} ->
        if String.starts_with?(String.trim(line), "```") do
          {keep, not in_fence}
        else
          if in_fence, do: {keep, in_fence}, else: {[line | keep], in_fence}
        end
      end)

    lines |> Enum.reverse() |> Enum.join("\n")
  end
end
