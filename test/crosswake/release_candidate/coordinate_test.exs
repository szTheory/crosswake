defmodule Crosswake.ReleaseCandidate.CoordinateTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Coordinate

  @candidate "0.2.1"
  @companions ~w(
    crosswake_rulestead
    crosswake_rindle
    crosswake_sigra
    crosswake_chimeway
    crosswake_threadline
  )

  test "links only Hex, iOS, and Android at the candidate coordinate" do
    assert Code.ensure_loaded?(Coordinate),
           "Coordinate.validate!/1 must enforce the candidate coordinate graph"

    assert function_exported?(Coordinate, :validate!, 1),
           "Coordinate.validate!/1 must enforce the candidate coordinate graph"

    result = Coordinate.validate!(fixture())

    assert result.version == @candidate

    assert result.linked_coordinates == %{
             "android-core" => @candidate,
             "hex" => @candidate,
             "ios-core" => @candidate
           }

    assert Enum.map(result.companions, & &1.package) == @companions
    refute Enum.any?(result.companions, &(&1.version == @candidate))
    assert result.independent_proposals == [115, 146, 147]
    assert result.approval_children == []
  end

  test "proves companion requirements at the boundary and below-floor control" do
    for companion <- Coordinate.validate!(fixture()).companions do
      assert companion.requirement == "~> 0.2"
      assert companion.floor == "0.2.0"
      assert companion.below_floor == "0.1.999"
      assert Version.match?(@candidate, companion.requirement)
      assert Version.match?(companion.floor, companion.requirement)
      refute Version.match?(companion.below_floor, companion.requirement)
    end
  end

  test "rejects coordinate, floor, package membership, and approval-scope mutations" do
    mutations = [
      put_in(fixture(), [:manifest, "packages/crosswake-shell-core-android"], "0.2.2"),
      update_in(fixture(), [:release_config, "plugins", Access.at(0), "components"], fn linked ->
        linked ++ ["crosswake_rulestead"]
      end),
      put_in(fixture(), [:root_mix], "@version \"0.2.0\""),
      put_in(fixture(), [:android_gradle], "version = \"0.2.0\""),
      put_in(fixture(), [:ios_package], "let package = Package(name: \"Other\")"),
      update_artifact(fixture(), "crosswake", &Map.put(&1, :version, "0.2.0")),
      update_artifact(fixture(), "crosswake_rulestead", fn artifact ->
        Map.update!(artifact, :files, &List.delete(&1, %{path: "mix.exs", type: "file"}))
      end),
      update_artifact(fixture(), "crosswake_rindle", fn artifact ->
        put_in(artifact, [:requirements, Access.at(0), :requirement], "not a requirement")
      end),
      update_artifact(fixture(), "crosswake_sigra", fn artifact ->
        put_in(artifact, [:requirements, Access.at(0), :requirement], "~> 0.3")
      end),
      put_in(fixture(), [:approval_children], [115]),
      put_in(fixture(), [:version], "9.9.9")
    ]

    for mutation <- mutations do
      assert_raise ArgumentError, ~r/candidate coordinate input is invalid/, fn ->
        Coordinate.validate!(mutation)
      end
    end
  end

  # D-171-C, Task 3 <behavior>: validate!/1 accepts any well-formed semver
  # once every one of the five sources agrees on it -- not just the historical
  # 0.2.1 literal. The derivation source is the release-manifest `.` entry.
  test "accepts a fully self-consistent input at any well-formed semver, not just 0.2.1" do
    for version <- ["0.2.1", "9.9.9", "12.34.5"] do
      result = Coordinate.validate!(fixture(version))

      assert result.version == version

      assert result.linked_coordinates == %{
               "android-core" => version,
               "hex" => version,
               "ios-core" => version
             }

      assert length(result.companions) == 5
      refute Enum.any?(result.companions, &(&1.version == version))
    end
  end

  # Five independent negative tests -- one per comparison site -- so a site
  # that silently stopped checking is named individually, rather than being
  # masked by a single "something disagreed" assertion.
  test "rejects when exactly one of the five cross-source comparison sites disagrees" do
    base = fixture("9.9.9")

    mutations = [
      input_version: put_in(base, [:version], "1.0.0"),
      artifact_core_version: update_artifact(base, "crosswake", &Map.put(&1, :version, "1.0.0")),
      manifest_ios_path: put_in(base, [:manifest, "packages/crosswake-shell-core-ios"], "1.0.0"),
      root_mix: put_in(base, [:root_mix], "defmodule Candidate do\n  @version \"1.0.0\"\nend\n"),
      android_gradle:
        put_in(base, [:android_gradle], "version = \"1.0.0\" // x-release-please-version\n")
    ]

    for {name, mutation} <- mutations do
      try do
        Coordinate.validate!(mutation)
        flunk("#{name} passed")
      rescue
        e in ArgumentError ->
          assert Exception.message(e) =~ "candidate coordinate input is invalid"
      end
    end
  end

  test "rejects a malformed version even when all five sources agree on it" do
    malformed = fixture("v9.9.9")

    assert_raise ArgumentError, ~r/candidate coordinate input is invalid/, fn ->
      Coordinate.validate!(malformed)
    end
  end

  test "rejects absent or extra packages and malformed input fields" do
    assert_raise ArgumentError, fn ->
      fixture() |> update_in([:artifacts], &tl/1) |> Coordinate.validate!()
    end

    extra = %{package: "crosswake_other", version: "0.1.0", files: [], requirements: []}

    assert_raise ArgumentError, fn ->
      fixture() |> update_in([:artifacts], &(&1 ++ [extra])) |> Coordinate.validate!()
    end

    assert_raise ArgumentError, fn ->
      fixture() |> Map.put(:credential, "forbidden") |> Coordinate.validate!()
    end
  end

  defp fixture(version \\ @candidate) do
    companion_versions = ["0.1.0", "0.1.0", "0.1.3", "0.1.0", "0.1.0"]
    [major, minor, _patch] = String.split(version, ".")
    core_requirement = "~> #{major}.#{minor}"

    artifacts =
      [
        %{
          package: "crosswake",
          version: version,
          files: [%{path: "mix.exs", type: "file"}, %{path: "lib/crosswake.ex", type: "file"}],
          requirements: []
        }
      ] ++
        Enum.zip_with(@companions, companion_versions, fn package, companion_version ->
          %{
            package: package,
            version: companion_version,
            files: [%{path: "mix.exs", type: "file"}, %{path: "lib/#{package}.ex", type: "file"}],
            requirements: [%{name: "crosswake", requirement: core_requirement, optional: false}]
          }
        end)

    %{
      version: version,
      artifacts: artifacts,
      manifest: %{
        "." => version,
        "packages/crosswake-shell-core-ios" => version,
        "packages/crosswake-shell-core-android" => version,
        "packages/crosswake_rulestead" => "0.1.0",
        "packages/crosswake_rindle" => "0.1.0",
        "packages/crosswake_sigra" => "0.1.3",
        "packages/crosswake_chimeway" => "0.1.0",
        "packages/crosswake_threadline" => "0.1.0"
      },
      release_config: %{
        "plugins" => [
          %{
            "type" => "linked-versions",
            "groupName" => "crosswake",
            "components" => ["hex", "ios-core", "android-core"]
          }
        ],
        "packages" => release_packages()
      },
      root_mix: "defmodule Candidate do\n  @version \"#{version}\"\nend\n",
      ios_package: File.read!("packages/crosswake-shell-core-ios/Package.swift"),
      android_gradle: "version = \"#{version}\" // x-release-please-version\n",
      independent_proposals: [115, 146, 147],
      approval_children: []
    }
  end

  defp release_packages do
    %{
      "." => %{"component" => "hex"},
      "packages/crosswake-shell-core-ios" => %{"component" => "ios-core"},
      "packages/crosswake-shell-core-android" => %{"component" => "android-core"}
    }
    |> Map.merge(
      Map.new(@companions, fn package ->
        {"packages/#{package}", %{"component" => package, "separate-pull-requests" => true}}
      end)
    )
  end

  defp update_artifact(input, package, callback) do
    update_in(input.artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end
end
