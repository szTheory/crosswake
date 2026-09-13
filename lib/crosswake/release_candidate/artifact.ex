defmodule Crosswake.ReleaseCandidate.Artifact do
  @moduledoc """
  Validates candidate-local Hex tarball observations and derives normalized payload evidence.

  The shell adapter owns official Hex build and unpack commands. This module is the fail-closed
  authority for the resulting package set, filesystem shape, metadata, and content digests.
  """

  @packages ~w(
    crosswake
    crosswake_rulestead
    crosswake_rindle
    crosswake_sigra
    crosswake_chimeway
    crosswake_threadline
  )
  @artifact_keys ~w(package version tarball unpacked_root outer_checksum source)a
  @input_keys ~w(candidate_ref output_root artifacts)a
  @metadata_keys ~w(app build_tools description elixir files licenses links name requirements version)
  @required_metadata_keys ~w(build_tools files name requirements version)
  @sha_pattern ~r/\A[0-9a-f]{64}\z/
  @ref_pattern ~r/\A[0-9a-f]{40}\z/
  @package_pattern ~r/\A[a-z][a-z0-9_]*\z/
  @path_pattern ~r/\A[[:print:]]+\z/

  @type observation :: %{
          candidate_ref: String.t(),
          package: String.t(),
          version: String.t(),
          outer_checksum: String.t(),
          metadata_digest: String.t(),
          payload_digest: String.t(),
          files: [map()],
          requirements: [map()],
          source: String.t(),
          unpacked_root: String.t()
        }

  @spec packages() :: [String.t()]
  def packages, do: @packages

  @spec inspect_family!(map()) :: [observation()]
  def inspect_family!(input) do
    unless exact_map?(input, @input_keys), do: invalid!()

    candidate_ref = sha!(input.candidate_ref, @ref_pattern)
    output_root = regular_directory!(input.output_root)
    artifacts = input.artifacts

    unless is_list(artifacts) and length(artifacts) == length(@packages), do: invalid!()

    package_names = Enum.map(artifacts, &artifact_package!/1)

    unless package_names == @packages, do: invalid!()

    artifacts
    |> Enum.map(&inspect_artifact!(&1, candidate_ref, output_root))
    |> Enum.sort_by(&Enum.find_index(@packages, fn package -> package == &1.package end))
  rescue
    File.Error -> invalid!()
    MatchError -> invalid!()
    KeyError -> invalid!()
  end

  @doc false
  @spec inspect_cli!([String.t()]) :: :ok
  def inspect_cli!([candidate_ref, output_root, manifest_path | artifact_args]) do
    unless rem(length(artifact_args), 6) == 0, do: invalid!()

    artifacts =
      artifact_args
      |> Enum.chunk_every(6)
      |> Enum.map(fn [package, version, tarball, unpacked_root, outer_checksum, source] ->
        %{
          package: package,
          version: version,
          tarball: tarball,
          unpacked_root: unpacked_root,
          outer_checksum: outer_checksum,
          source: source
        }
      end)

    observations =
      inspect_family!(%{
        candidate_ref: candidate_ref,
        output_root: output_root,
        artifacts: artifacts
      })

    manifest = Path.expand(manifest_path)
    ensure_within!(manifest, output_root)
    File.write!(manifest, Jason.encode!(observations) <> "\n", [:binary, :exclusive])
    :ok
  rescue
    File.Error -> invalid!()
  end

  def inspect_cli!(_args), do: invalid!()

  defp inspect_artifact!(artifact, candidate_ref, output_root) do
    unless exact_map?(artifact, @artifact_keys), do: invalid!()
    unless artifact.source == "built_tarball", do: invalid!()

    package = package!(artifact.package)
    version = version!(artifact.version)
    tarball = regular_file!(artifact.tarball, output_root)
    unpacked_root = regular_directory!(artifact.unpacked_root, output_root)
    outer_checksum = sha!(artifact.outer_checksum, @sha_pattern)
    computed_outer_checksum = digest_file!(tarball)

    unless secure_equal?(outer_checksum, computed_outer_checksum), do: invalid!()

    {metadata, metadata_digest, declared_paths, requirements} =
      inspect_metadata!(unpacked_root, package, version)

    entries = walk!(unpacked_root)
    actual_paths = Enum.map(entries, & &1.path)
    unless actual_paths == declared_paths, do: invalid!()

    files = Enum.filter(entries, &(&1.type == "file"))
    unless files != [], do: invalid!()

    %{
      package: package,
      version: version,
      candidate_ref: candidate_ref,
      outer_checksum: computed_outer_checksum,
      metadata_digest: metadata_digest,
      payload_digest: digest_term(files),
      files: files,
      requirements: requirements,
      source: "built_tarball",
      unpacked_root: unpacked_root
    }
    |> then(fn observation ->
      # Keep metadata reachable through the digest calculation only. Returning it would widen the
      # receipt with links and descriptions that are not candidate-authority fields.
      _ = metadata
      observation
    end)
  end

  defp inspect_metadata!(unpacked_root, package, version) do
    metadata_path = Path.join(unpacked_root, "hex_metadata.config")
    regular_file!(metadata_path, unpacked_root)

    {:ok, terms} = :file.consult(String.to_charlist(metadata_path))
    metadata = string_map!(terms)
    keys = Map.keys(metadata) |> Enum.sort()

    unless Enum.all?(@required_metadata_keys, &(&1 in keys)) and
             Enum.all?(keys, &(&1 in @metadata_keys)),
           do: invalid!()

    unless metadata["name"] == package and metadata["version"] == version, do: invalid!()
    unless metadata["build_tools"] == ["mix"], do: invalid!()

    declared_paths = normalize_declared_paths!(metadata["files"])
    requirements = normalize_requirements!(metadata["requirements"])

    normalized_metadata =
      metadata
      |> Map.put("files", declared_paths)
      |> Map.put("requirements", requirements)
      |> normalize_term()

    {normalized_metadata, digest_term(normalized_metadata), declared_paths, requirements}
  end

  defp normalize_declared_paths!(paths) when is_list(paths) and paths != [] do
    normalized = Enum.map(paths, &safe_relative_path!/1) |> Enum.sort()
    unless Enum.uniq(normalized) == normalized, do: invalid!()
    normalized
  end

  defp normalize_declared_paths!(_paths), do: invalid!()

  defp normalize_requirements!(requirements) when is_list(requirements) do
    normalized =
      Enum.map(requirements, fn requirement ->
        map = string_map!(requirement)
        keys = Map.keys(map)

        unless Enum.all?(~w(name optional requirement), &(&1 in keys)) and
                 Enum.all?(keys, &(&1 in ~w(app name optional repository requirement))),
               do: invalid!()

        name = package!(map["name"])
        requirement_value = requirement!(map["requirement"])
        optional = boolean!(map["optional"])

        if Map.has_key?(map, "repository") and map["repository"] != "hexpm", do: invalid!()
        if Map.has_key?(map, "app") and map["app"] != name, do: invalid!()

        %{name: name, requirement: requirement_value, optional: optional}
      end)
      |> Enum.sort_by(& &1.name)

    names = Enum.map(normalized, & &1.name)
    unless Enum.uniq(names) == names, do: invalid!()
    normalized
  end

  defp normalize_requirements!(_requirements), do: invalid!()

  defp walk!(root), do: walk_directory!(root, root) |> Enum.sort_by(& &1.path)

  defp walk_directory!(root, current) do
    {:ok, names} = File.ls(current)

    Enum.flat_map(names, fn name ->
      path = Path.join(current, name)
      relative = safe_relative_path!(Path.relative_to(path, root))

      case File.lstat(path) do
        {:ok, %File.Stat{type: :directory, mode: mode}} ->
          [
            %{path: relative, type: "directory", mode: permissions(mode)}
            | walk_directory!(root, path)
          ]

        {:ok, %File.Stat{type: :regular, mode: mode}} when relative != "hex_metadata.config" ->
          [%{path: relative, type: "file", mode: permissions(mode), sha256: digest_file!(path)}]

        {:ok, %File.Stat{type: :regular}} when relative == "hex_metadata.config" ->
          []

        _other ->
          invalid!()
      end
    end)
  end

  defp string_map!(pairs) when is_list(pairs) do
    unless Enum.all?(pairs, fn pair -> match?({key, _value} when is_binary(key), pair) end),
      do: invalid!()

    map = Map.new(pairs)
    unless map_size(map) == length(pairs), do: invalid!()
    map
  end

  defp string_map!(_value), do: invalid!()

  defp normalize_term(value) when is_map(value) do
    value
    |> Enum.map(fn {key, nested} -> {to_string(key), normalize_term(nested)} end)
    |> Enum.sort()
  end

  defp normalize_term(value) when is_list(value) do
    value
    |> Enum.map(&normalize_term/1)
    |> Enum.sort_by(&:erlang.term_to_binary(&1, [:deterministic]))
  end

  defp normalize_term({key, value}) when is_binary(key),
    do: {key, normalize_term(value)}

  defp normalize_term(value) when is_binary(value) or is_boolean(value) or is_nil(value),
    do: value

  defp normalize_term(_value), do: invalid!()

  defp artifact_package!(artifact) when is_map(artifact),
    do: package!(Map.get(artifact, :package))

  defp artifact_package!(_artifact), do: invalid!()

  defp package!(value) when is_binary(value) do
    if Regex.match?(@package_pattern, value), do: value, else: invalid!()
  end

  defp package!(_value), do: invalid!()

  defp version!(value) when is_binary(value) do
    case Version.parse(value) do
      {:ok, parsed} when parsed.pre == [] and parsed.build == nil -> value
      _other -> invalid!()
    end
  end

  defp version!(_value), do: invalid!()

  defp requirement!(value) when is_binary(value) and byte_size(value) in 1..80 do
    case Version.parse_requirement(value) do
      {:ok, _requirement} -> value
      :error -> invalid!()
    end
  end

  defp requirement!(_value), do: invalid!()

  defp boolean!(value) when is_boolean(value), do: value
  defp boolean!(_value), do: invalid!()

  defp regular_directory!(path, within \\ nil)

  defp regular_directory!(path, within) when is_binary(path) and path != "" do
    expanded = Path.expand(path)
    if within, do: ensure_within!(expanded, within)

    case File.lstat(expanded) do
      {:ok, %File.Stat{type: :directory}} -> expanded
      _other -> invalid!()
    end
  end

  defp regular_directory!(_path, _within), do: invalid!()

  defp regular_file!(path, within) when is_binary(path) and path != "" do
    expanded = Path.expand(path)
    ensure_within!(expanded, within)

    case File.lstat(expanded) do
      {:ok, %File.Stat{type: :regular}} -> expanded
      _other -> invalid!()
    end
  end

  defp regular_file!(_path, _within), do: invalid!()

  defp ensure_within!(path, root) do
    expanded_root = Path.expand(root)

    unless path != expanded_root and String.starts_with?(path, expanded_root <> "/"),
      do: invalid!()

    path
  end

  defp safe_relative_path!(path) when is_binary(path) and path != "" do
    normalized = Path.expand(path, "/") |> Path.relative_to("/")
    parts = Path.split(path)

    if path == normalized and Path.type(path) != :absolute and
         Enum.all?(parts, &(&1 not in ["", ".", ".."])) and
         not String.contains?(path, ["\\", <<0>>]) and Regex.match?(@path_pattern, path),
       do: path,
       else: invalid!()
  end

  defp safe_relative_path!(_path), do: invalid!()

  defp digest_file!(path) do
    context = :crypto.hash_init(:sha256)

    digest =
      path
      |> File.stream!([], 65_536)
      |> Enum.reduce(context, &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()

    Base.encode16(digest, case: :lower)
  end

  defp digest_term(term) do
    term
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp sha!(value, pattern) when is_binary(value) do
    if Regex.match?(pattern, value), do: value, else: invalid!()
  end

  defp sha!(_value, _pattern), do: invalid!()

  defp secure_equal?(left, right) when byte_size(left) == byte_size(right),
    do: :crypto.hash_equals(left, right)

  defp secure_equal?(_left, _right), do: false

  defp permissions(mode), do: Bitwise.band(mode, 0o777)

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp invalid!, do: raise(ArgumentError, "candidate artifact input is invalid")
end
