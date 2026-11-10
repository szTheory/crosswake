defmodule Crosswake.Guides.ChangelogUnreleasedWordingTest do
  use ExUnit.Case, async: true

  # D-13: `[Unreleased]` makes no current-release claim and names no release version.
  # Published state is read from GitHub Releases and hex.pm, never copied here.

  @changelog_path Path.expand("../../../CHANGELOG.md", __DIR__)
  @stale_wording ~r/current published|published Hex (family|release)/
  @releases_pointer "](https://github.com/szTheory/crosswake/releases)"
  @hex_versions_pointer "](https://hex.pm/packages/crosswake/versions)"
  @pointer_sentence "* Releases that have no section in this file are listed on [GitHub Releases](https://github.com/szTheory/crosswake/releases) and [hex.pm](https://hex.pm/packages/crosswake/versions).\n"

  # Schema and protocol contract versions are not release versions (D-13). A literal
  # is exempt only on a line that also names its context.
  @contract_version_exemptions [{"1.2.0", "schema"}, {"1.1.0", "bridge_protocol_version"}]

  defp changelog, do: File.read!(@changelog_path)
  defp unreleased, do: section!(changelog(), "## [Unreleased]")

  defp section!(content, heading) do
    pattern = ~r/^#{Regex.escape(heading)}\r?\n(.*?)(?=^## \[|\z)/ms

    case Regex.run(pattern, content, capture: :all_but_first) do
      [section] -> section
      nil -> flunk("missing section #{heading}")
    end
  end

  defp mutate!(text, fun) do
    copy = fun.(text)
    if copy == text, do: raise("control did not change the text")
    copy
  end

  defp published_truth_pointer?(unreleased) do
    subsection =
      case Regex.run(~r/^### Published Hex truth\r?\n(.*?)(?=^### |\z)/ms, unreleased,
             capture: :all_but_first
           ) do
        [body] -> body
        nil -> ""
      end

    String.contains?(subsection, @releases_pointer) and
      String.contains?(subsection, @hex_versions_pointer)
  end

  defp release_version_literals(unreleased) do
    unreleased
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      ~r/\b\d+\.\d+\.\d+\b/
      |> Regex.scan(line)
      |> List.flatten()
      |> Enum.reject(fn literal ->
        Enum.any?(@contract_version_exemptions, fn {version, context} ->
          literal == version and String.contains?(line, context)
        end)
      end)
    end)
  end

  test "the real [Unreleased] section is non-empty and has no current-release wording" do
    assert byte_size(unreleased()) > 200
    refute unreleased() =~ @stale_wording
  end

  for phrase <- ["current published Hex release", "published Hex family"] do
    test "control: injecting #{inspect(phrase)} into [Unreleased] is caught" do
      copy = mutate!(unreleased(), &(&1 <> "\n* The #{unquote(phrase)} is listed here.\n"))
      assert copy =~ @stale_wording
    end
  end

  test "the Published Hex truth subsection points to GitHub Releases and the hex.pm versions page" do
    assert published_truth_pointer?(unreleased())
  end

  test "control: removing the pointer sentence turns the pointer check red" do
    copy = mutate!(unreleased(), &String.replace(&1, @pointer_sentence, ""))
    refute published_truth_pointer?(copy)
  end

  test "control: the pointer links outside the Published Hex truth subsection do not count" do
    copy =
      mutate!(unreleased(), fn text ->
        text
        |> String.replace(@pointer_sentence, "")
        |> String.replace(
          "### Deferred non-shipped claims\n",
          "### Deferred non-shipped claims\n\n" <> @pointer_sentence
        )
      end)

    refute published_truth_pointer?(copy)
  end

  test "the real [Unreleased] section names no release version" do
    assert release_version_literals(unreleased()) == []
  end

  test "control: an injected release version is listed" do
    copy = mutate!(unreleased(), &(&1 <> "\n* Shipped in 0.2.12.\n"))
    assert release_version_literals(copy) == ["0.2.12"]
  end

  test "control: a contract-version literal on a line without its context is listed" do
    copy = mutate!(unreleased(), &(&1 <> "\n* Something new in 1.2.0.\n"))
    assert release_version_literals(copy) == ["1.2.0"]
  end

  # 0.2.12 is the first published release that reads :ios_host (199 reader audit), so
  # [Unreleased] no longer lists it, or the other shipped support claims, as unpublished.
  test "[Unreleased] no longer lists the shipped :ios_host declaration as unpublished" do
    refute unreleased() =~ ":ios_host"
    refute unreleased() =~ "not released"
    assert unreleased() =~ "There are no unpublished support claims at this time."
  end

  test "the required headings and the 0.1.0 section remain" do
    for heading <- [
          "### Unpublished support claims",
          "### Verification-required and advisory surfaces",
          "### Deferred non-shipped claims",
          "### Published Hex truth"
        ] do
      assert unreleased() =~ heading
    end

    assert changelog() =~ "## [0.1.0]"
  end
end
