defmodule Crosswake.ReleaseCandidate.Coordinate do
  @moduledoc """
  Validates the closed candidate release coordinate graph from distributable metadata.

  Only Hex core, iOS core, and Android core are linked. Companion packages remain independently
  versioned approval outsiders, but each must declare a public core requirement whose boundary and
  candidate behavior are explicit.
  """

  alias Crosswake.ReleaseCandidate.Artifact

  @candidate "0.2.1"
  @linked_components ~w(hex ios-core android-core)
  @input_keys ~w(
    version
    artifacts
    manifest
    release_config
    root_mix
    ios_package
    android_gradle
    independent_proposals
    approval_children
  )a
  @manifest_paths %{
    "hex" => ".",
    "ios-core" => "packages/crosswake-shell-core-ios",
    "android-core" => "packages/crosswake-shell-core-android"
  }
  @independent_proposals [115, 146, 147]

  @type companion_floor :: %{
          package: String.t(),
          version: String.t(),
          requirement: String.t(),
          floor: String.t(),
          below_floor: String.t()
        }

  @spec validate!(map()) :: %{
          version: String.t(),
          linked_coordinates: %{String.t() => String.t()},
          companions: [companion_floor()],
          independent_proposals: [pos_integer()],
          approval_children: []
        }
  def validate!(input) do
    unless exact_map?(input, @input_keys), do: invalid!()
    unless input.version == @candidate, do: invalid!()
    unless input.independent_proposals == @independent_proposals, do: invalid!()
    unless input.approval_children == [], do: invalid!()

    artifacts = validate_artifacts!(input.artifacts)
    validate_manifest!(input.manifest, artifacts)
    validate_release_config!(input.release_config)
    validate_sources!(input)

    companions =
      Artifact.packages()
      |> tl()
      |> Enum.map(&companion_floor!(Map.fetch!(artifacts, &1), input.version))

    %{
      version: input.version,
      linked_coordinates: Map.new(@linked_components, &{&1, input.version}),
      companions: companions,
      independent_proposals: input.independent_proposals,
      approval_children: []
    }
  rescue
    KeyError -> invalid!()
    ArgumentError -> invalid!()
  end

  defp validate_artifacts!(artifacts) when is_list(artifacts) do
    packages = Enum.map(artifacts, &artifact_package!/1)
    unless packages == Artifact.packages(), do: invalid!()

    by_package = Map.new(artifacts, &{&1.package, &1})
    core = Map.fetch!(by_package, "crosswake")
    unless core.version == @candidate, do: invalid!()

    Enum.each(artifacts, fn artifact ->
      unless is_binary(artifact.version), do: invalid!()
      unless match?({:ok, _version}, Version.parse(artifact.version)), do: invalid!()
      unless regular_mix_file?(artifact.files), do: invalid!()
      unless is_list(artifact.requirements), do: invalid!()
    end)

    by_package
  end

  defp validate_artifacts!(_artifacts), do: invalid!()

  defp artifact_package!(%{package: package}) when is_binary(package), do: package
  defp artifact_package!(_artifact), do: invalid!()

  defp regular_mix_file?(files) when is_list(files) do
    Enum.any?(files, fn
      %{path: "mix.exs", type: "file"} -> true
      _entry -> false
    end)
  end

  defp regular_mix_file?(_files), do: false

  defp validate_manifest!(manifest, artifacts) when is_map(manifest) do
    expected_paths =
      Map.values(@manifest_paths) ++ Enum.map(tl(Artifact.packages()), &"packages/#{&1}")

    unless Map.keys(manifest) |> Enum.sort() == Enum.sort(expected_paths), do: invalid!()

    Enum.each(@manifest_paths, fn {_component, path} ->
      unless Map.get(manifest, path) == @candidate, do: invalid!()
    end)

    Artifact.packages()
    |> tl()
    |> Enum.each(fn package ->
      unless Map.get(manifest, "packages/#{package}") == Map.fetch!(artifacts, package).version,
        do: invalid!()
    end)
  end

  defp validate_manifest!(_manifest, _artifacts), do: invalid!()

  defp validate_release_config!(%{"plugins" => plugins, "packages" => packages})
       when is_list(plugins) and is_map(packages) do
    linked =
      Enum.filter(plugins, fn plugin ->
        is_map(plugin) and plugin["type"] == "linked-versions" and
          plugin["groupName"] == "crosswake"
      end)

    unless linked == [
             %{
               "type" => "linked-versions",
               "groupName" => "crosswake",
               "components" => @linked_components
             }
           ],
           do: invalid!()

    Enum.each(@manifest_paths, fn {component, path} ->
      unless get_in(packages, [path, "component"]) == component, do: invalid!()
    end)

    Artifact.packages()
    |> tl()
    |> Enum.each(fn package ->
      config = Map.get(packages, "packages/#{package}")

      unless is_map(config) and config["component"] == package and
               config["separate-pull-requests"] == true,
             do: invalid!()
    end)
  end

  defp validate_release_config!(_config), do: invalid!()

  defp validate_sources!(input) do
    unless extract_version!(input.root_mix, ~r/@version\s+"([^"]+)"/) == @candidate,
      do: invalid!()

    unless extract_version!(input.android_gradle, ~r/version\s*=\s*"([^"]+)"/) == @candidate,
      do: invalid!()

    unless is_binary(input.ios_package) and
             input.ios_package =~ ~s(name: "CrosswakeShellCore") and
             input.ios_package =~ ".iOS(.v15)" and input.ios_package =~ ".macOS(.v12)",
           do: invalid!()
  end

  defp extract_version!(source, regex) when is_binary(source) do
    case Regex.run(regex, source) do
      [_, version] -> version
      _other -> invalid!()
    end
  end

  defp extract_version!(_source, _regex), do: invalid!()

  defp companion_floor!(artifact, candidate) do
    crosswake_requirements =
      Enum.filter(artifact.requirements, fn
        %{name: "crosswake"} -> true
        _requirement -> false
      end)

    unless match?([_one], crosswake_requirements), do: invalid!()
    [crosswake] = crosswake_requirements

    unless crosswake.optional == false and is_binary(crosswake.requirement), do: invalid!()

    requirement =
      case Version.parse_requirement(crosswake.requirement) do
        {:ok, parsed} -> parsed
        :error -> invalid!()
      end

    {floor, below_floor} = floor_boundary!(crosswake.requirement)

    unless Version.match?(candidate, requirement) and Version.match?(floor, requirement) and
             not Version.match?(below_floor, requirement),
           do: invalid!()

    %{
      package: artifact.package,
      version: artifact.version,
      requirement: crosswake.requirement,
      floor: floor,
      below_floor: below_floor
    }
  end

  defp floor_boundary!(requirement) do
    case Regex.run(~r/\A~>\s*(\d+)\.(\d+)\z/, requirement) do
      [_, major_text, minor_text] ->
        major = String.to_integer(major_text)
        minor = String.to_integer(minor_text)
        floor = "#{major}.#{minor}.0"

        below =
          cond do
            minor > 0 -> "#{major}.#{minor - 1}.999"
            major > 0 -> "#{major - 1}.999.999"
            true -> invalid!()
          end

        {floor, below}

      _other ->
        invalid!()
    end
  end

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp invalid!, do: raise(ArgumentError, "candidate coordinate input is invalid")
end
