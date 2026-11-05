defmodule Crosswake.Doctor.PublishReadinessChangelogTest do
  use ExUnit.Case, async: true

  alias Crosswake.Doctor.PublishReadiness

  @pointer_sentence "* Releases that have no section in this file are listed on [GitHub Releases](https://github.com/szTheory/crosswake/releases) and [hex.pm](https://hex.pm/packages/crosswake/versions).\n"

  defp real_changelog, do: File.read!(Path.join(File.cwd!(), "CHANGELOG.md"))

  defp parity(opts \\ []) do
    report = PublishReadiness.run([cwd: File.cwd!()] ++ opts)
    Enum.find(report.checks, &(&1.id == "publish.parity"))
  end

  defp without_pointer(changelog) do
    copy = String.replace(changelog, @pointer_sentence, "")

    if copy == changelog do
      raise "control did not change the CHANGELOG: pointer sentence not found"
    end

    copy
  end

  defp newest_release_section(changelog) do
    [_, version] = Regex.run(~r/^## \[(\d+\.\d+\.\d+)\]/m, changelog)
    version
  end

  test "precondition: the manifest is ahead of the newest release section, so the candidate rule is exercised" do
    version = Mix.Project.config()[:version]
    manifest = File.cwd!() |> Path.join(".release-please-manifest.json") |> File.read!()
    manifest_version = manifest |> Jason.decode!() |> Map.fetch!(".")
    changelog = real_changelog()
    newest = newest_release_section(changelog)

    assert manifest_version == version
    assert Version.compare(version, newest) == :gt

    refute changelog =~ ~r/^## \[#{Regex.escape(version)}\]/m,
           "CHANGELOG has a [#{version}] section of its own: a hand-added release section " <>
             "moves the repository onto the direct-section path and this test no longer " <>
             "exercises the unpublished-candidate rule (D-13: no backfill)"
  end

  test "publish.parity passes on the real repository" do
    check = parity()

    assert check.result == :pass
    assert check.details.errors == []
  end

  test "control: the real CHANGELOG without the pointer sentence fails publish.parity" do
    version = Mix.Project.config()[:version]
    check = parity(changelog_contents: without_pointer(real_changelog()))

    assert check.result != :pass
    assert Enum.any?(check.details.errors, &(&1 =~ "[#{version}]"))
  end

  test "control: only the two deleted version sentences, without the pointer, still fail" do
    version = Mix.Project.config()[:version]
    changelog = real_changelog()
    newest = newest_release_section(changelog)

    old_sentences =
      "* No new support claims have been cut after `#{newest}` yet. Future entries here must distinguish planning milestone work from published Hex release truth.\n" <>
        "* The current published Hex release is `#{newest}`.\n"

    copy =
      changelog
      |> without_pointer()
      |> String.replace(
        "### Published Hex truth\n\n",
        "### Published Hex truth\n\n" <> old_sentences
      )

    assert copy != without_pointer(changelog)

    check = parity(changelog_contents: copy)

    assert check.result != :pass
    assert Enum.any?(check.details.errors, &(&1 =~ "[#{version}]"))
  end
end
