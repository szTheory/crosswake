defmodule Crosswake.ReleaseCandidate.Cleanroom do
  @moduledoc """
  Validates bounded clean-room observations for candidate and exact-public package proofs.

  Shell adapters own package fetching and generated-host execution. This module accepts only the
  closed, low-cardinality result of those operations and refuses incomplete package/profile sets,
  shared scratch state, source substitution, or vacuous profile success.
  """

  alias Crosswake.ReleaseCandidate.Artifact

  @generator_version "1.8.13"
  @profiles ~w(rulestead rindle sigra chimeway threadline)
  @candidate_input_keys ~w(
    source_mode
    generator_version
    repository_root
    source_root
    artifacts
    installs
    profile_results
    live_status
  )a
  @artifact_keys ~w(package version source unpacked_root metadata_digest payload_digest)a
  @install_keys ~w(profile pass status scratch_root path_lock_count)a
  @profile_keys ~w(profile package status passed_checks negative_control)a
  @sha_pattern ~r/\A[0-9a-f]{64}\z/

  @common_checks ~w(
    generated_phoenix
    compile_warnings_as_errors
    runtime_config_loaded
    router_output
    public_smoke
    registration
    doctor
  )
  @profile_checks %{
    "rulestead" => ~w(engine_loaded dependency_validated),
    "rindle" => ~w(engine_loaded dependency_validated contracts_nonempty),
    "sigra" => ~w(auth_non_vacuous),
    "chimeway" => ~w(sigra_absent telemetry_events),
    "threadline" => ~w(observer_unregistered siblings_absent plug telemetry ledger templates)
  }

  @spec profiles() :: [String.t()]
  def profiles, do: @profiles

  @spec expected_checks(String.t()) :: [String.t()]
  def expected_checks(profile) when is_binary(profile) do
    case Map.fetch(@profile_checks, profile) do
      {:ok, profile_checks} -> @common_checks ++ profile_checks
      :error -> invalid!()
    end
  end

  @spec evaluate!(map()) :: map()
  def evaluate!(%{source_mode: "candidate-local"} = input), do: evaluate_candidate!(input)
  def evaluate!(_input), do: invalid!()

  @doc false
  @spec evaluate_cli!([String.t()]) :: :ok
  def evaluate_cli!([input_path, output_path]) do
    input = input_path |> File.read!() |> Jason.decode!(keys: :atoms!)
    result = evaluate!(input)
    File.write!(output_path, Jason.encode!(result) <> "\n", [:binary, :exclusive])
    :ok
  rescue
    File.Error -> invalid!()
    Jason.DecodeError -> invalid!()
    ArgumentError -> invalid!()
  end

  def evaluate_cli!(_args), do: invalid!()

  defp evaluate_candidate!(input) do
    unless exact_map?(input, @candidate_input_keys), do: invalid!()
    unless input.generator_version == @generator_version, do: invalid!()
    unless input.live_status == "not_applicable", do: invalid!()

    repository_root = regular_directory!(input.repository_root)
    source_root = regular_directory!(input.source_root)
    unless outside?(source_root, repository_root), do: invalid!()

    packages = validate_candidate_artifacts!(input.artifacts, source_root, repository_root)
    installs = validate_installs!(input.installs, source_root, repository_root)
    profile_results = validate_profile_results!(input.profile_results)

    %{
      generator_version: @generator_version,
      install_count: installs |> Enum.map(& &1.pass) |> Enum.uniq() |> length(),
      package_count: length(packages),
      profile_count: length(profile_results),
      source_mode: "candidate-local",
      path_lock_count: Enum.sum(Enum.map(installs, & &1.path_lock_count)),
      packages: Enum.map(packages, &Map.drop(&1, [:unpacked_root])),
      profile_results: profile_results,
      live_status: "not_applicable"
    }
  rescue
    File.Error -> invalid!()
    KeyError -> invalid!()
  end

  defp validate_candidate_artifacts!(artifacts, source_root, repository_root)
       when is_list(artifacts) do
    normalized =
      Enum.map(artifacts, fn artifact ->
        unless exact_map?(artifact, @artifact_keys), do: invalid!()
        unless artifact.source == "built_tarball", do: invalid!()

        package = package!(artifact.package)
        version = version!(artifact.version)
        unpacked_root = regular_directory!(artifact.unpacked_root)
        ensure_within!(unpacked_root, source_root)
        unless outside?(unpacked_root, repository_root), do: invalid!()

        %{
          package: package,
          version: version,
          source: "built_tarball",
          unpacked_root: unpacked_root,
          metadata_digest: sha!(artifact.metadata_digest),
          payload_digest: sha!(artifact.payload_digest)
        }
      end)

    by_package = Map.new(normalized, &{&1.package, &1})

    unless length(normalized) == length(Artifact.packages()) and
             map_size(by_package) == length(normalized) and
             Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()),
           do: invalid!()

    Enum.map(Artifact.packages(), &Map.fetch!(by_package, &1))
  end

  defp validate_candidate_artifacts!(_artifacts, _source_root, _repository_root), do: invalid!()

  defp validate_installs!(installs, source_root, repository_root) when is_list(installs) do
    normalized =
      Enum.map(installs, fn install ->
        unless exact_map?(install, @install_keys), do: invalid!()
        profile = profile!(install.profile)
        unless install.pass in [1, 2], do: invalid!()
        unless install.status == "PASS" and install.path_lock_count == 0, do: invalid!()

        scratch_root = regular_directory!(install.scratch_root)

        unless outside?(scratch_root, repository_root) and outside?(scratch_root, source_root),
          do: invalid!()

        %{install | profile: profile, scratch_root: scratch_root}
      end)

    identities = Enum.map(normalized, &{&1.profile, &1.pass})
    scratch_roots = Enum.map(normalized, & &1.scratch_root)
    expected = for profile <- @profiles, pass <- [1, 2], do: {profile, pass}

    unless length(normalized) == length(expected) and Enum.uniq(identities) == identities and
             Enum.sort(identities) == Enum.sort(expected) and
             Enum.uniq(scratch_roots) == scratch_roots,
           do: invalid!()

    Enum.sort_by(
      normalized,
      &{Enum.find_index(@profiles, fn profile -> profile == &1.profile end), &1.pass}
    )
  end

  defp validate_installs!(_installs, _source_root, _repository_root), do: invalid!()

  defp validate_profile_results!(profile_results) when is_list(profile_results) do
    normalized =
      Enum.map(profile_results, fn result ->
        unless exact_map?(result, @profile_keys), do: invalid!()
        profile = profile!(result.profile)
        unless result.package == "crosswake_#{profile}", do: invalid!()
        unless result.status == "PASS" and result.negative_control == "PASS", do: invalid!()
        unless result.passed_checks == expected_checks(profile), do: invalid!()

        result
        |> Map.put(:profile, profile)
        |> Map.put(:digest, digest_profile(result))
      end)

    identities = Enum.map(normalized, & &1.profile)

    unless length(normalized) == length(@profiles) and Enum.uniq(identities) == identities and
             Enum.sort(identities) == Enum.sort(@profiles),
           do: invalid!()

    Enum.sort_by(normalized, &Enum.find_index(@profiles, fn profile -> profile == &1.profile end))
  end

  defp validate_profile_results!(_profile_results), do: invalid!()

  defp digest_profile(result) do
    result
    |> Map.take(@profile_keys)
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp package!(package) when is_binary(package) do
    if package in Artifact.packages(), do: package, else: invalid!()
  end

  defp package!(_package), do: invalid!()

  defp profile!(profile) when profile in @profiles, do: profile
  defp profile!(_profile), do: invalid!()

  defp version!(version) when is_binary(version) do
    case Version.parse(version) do
      {:ok, parsed} when parsed.pre == [] and parsed.build == nil -> version
      _other -> invalid!()
    end
  end

  defp version!(_version), do: invalid!()

  defp sha!(digest) when is_binary(digest) do
    if Regex.match?(@sha_pattern, digest), do: digest, else: invalid!()
  end

  defp sha!(_digest), do: invalid!()

  defp regular_directory!(path) when is_binary(path) and path != "" do
    expanded = Path.expand(path)

    case File.lstat(expanded) do
      {:ok, %File.Stat{type: :directory}} -> expanded
      _other -> invalid!()
    end
  end

  defp regular_directory!(_path), do: invalid!()

  defp ensure_within!(path, root) do
    unless path != root and String.starts_with?(path, root <> "/"), do: invalid!()
    path
  end

  defp outside?(path, root),
    do: path != root and not String.starts_with?(path, root <> "/")

  defp exact_map?(value, keys) when is_map(value),
    do: Map.keys(value) |> Enum.sort() == Enum.sort(keys)

  defp exact_map?(_value, _keys), do: false

  defp invalid!, do: raise(ArgumentError, "candidate clean-room input is invalid")
end
