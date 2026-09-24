defmodule Crosswake.ReleaseCandidate.EvidenceInput do
  @moduledoc """
  Builds candidate receipt input from the named, immutable release rehearsal artifacts.

  This adapter accepts only evidence files and exact identity/run selectors. It never accepts a
  serialized receipt, expression, or caller-defined field map.
  """

  alias Crosswake.ReleaseCandidate.Artifact

  @packages Artifact.packages()
  @files [
    "ci/release-candidate-ci-receipt.json",
    "ci/artifacts/artifacts.json",
    "hex/rehearsal.json",
    "hex/packages/artifacts.json",
    "ios/rehearsal.json",
    "ios/mirror.json",
    "maven/rehearsal.json"
  ]
  @max_file_bytes 8_388_608
  @max_total_bytes 33_554_432
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @workflow_paths [
    {"crosswake-ci", ".github/workflows/crosswake-ci.yml"},
    {"hex-publish", ".github/workflows/hex-publish.yml"},
    {"ios-mirror-backfill", ".github/workflows/ios-mirror-backfill.yml"},
    {"maven-publish-fire-drill", ".github/workflows/maven-publish-fire-drill.yml"},
    {"release-please", ".github/workflows/release-please.yml"}
  ]
  @config_paths [
    {"release-please-config", "release-please-config.json"},
    {"release-please-manifest", ".release-please-manifest.json"}
  ]
  @check_ids ~w(
    candidate.ci
    candidate.identity
    candidate.workflows
    candidate.config
    candidate.coordinates
    candidate.cleanroom
    candidate.external-state
    candidate.credentials
    package.family
    hex.rehearsal
    ios.rehearsal
    maven.rehearsal
    mirror.authority
  )

  @spec load!(Path.t(), keyword()) :: map()
  def load!(evidence_dir, opts) when is_binary(evidence_dir) and is_list(opts) do
    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts)) ==
               Enum.sort([:version, :ref, :ci_run_id, :hex_run_id, :ios_run_id, :maven_run_id]),
           do: invalid!()

    version = Keyword.fetch!(opts, :version)
    ref = sha!(Keyword.fetch!(opts, :ref))
    run_ids = run_ids!(opts)
    root = safe_directory!(evidence_dir)
    assert_exact_file_roster!(root)

    ci_path = Path.join(root, "ci/release-candidate-ci-receipt.json")
    ci_manifest_path = Path.join(root, "ci/artifacts/artifacts.json")
    hex_path = Path.join(root, "hex/rehearsal.json")
    hex_manifest_path = Path.join(root, "hex/packages/artifacts.json")
    ios_path = Path.join(root, "ios/rehearsal.json")
    mirror_path = Path.join(root, "ios/mirror.json")
    maven_path = Path.join(root, "maven/rehearsal.json")

    ci = read_json!(ci_path)
    ci_packages = read_json!(ci_manifest_path)
    hex = read_json!(hex_path)
    hex_packages = read_json!(hex_manifest_path)
    ios = read_json!(ios_path)
    mirror = read_json!(mirror_path)
    maven = read_json!(maven_path)

    paths = %{
      ci: ci_path,
      ci_packages: ci_manifest_path,
      hex: hex_path,
      hex_packages: hex_manifest_path,
      ios: ios_path,
      mirror: mirror_path,
      maven: maven_path
    }

    identity =
      identity!(
        version,
        ref,
        run_ids,
        ci,
        ci_packages,
        hex,
        hex_packages,
        ios,
        mirror,
        maven,
        paths
      )

    observed_identity =
      identity!(
        maven["candidate_version"],
        sha!(ci["head"]),
        %{
          ci: artifact_run_id!(ci["run_id"]),
          hex: artifact_run_id!(hex["run_id"]),
          ios: artifact_run_id!(ios["run_id"]),
          maven: artifact_run_id!(maven["run_id"])
        },
        ci,
        ci_packages,
        hex,
        hex_packages,
        ios,
        mirror,
        maven,
        paths
      )

    %{
      identity: identity,
      observed_identity: observed_identity,
      checks: Enum.map(@check_ids, &%{id: &1, status: "PASS"}),
      external_state: %{
        publication: "NONE",
        successful_coordinates: [],
        failed_step: nil,
        changed: false,
        all_linked_proven: false
      },
      credentials: %{mirror_write_authority: "PROVEN", exercised: true}
    }
  rescue
    _error -> invalid!()
  end

  def load!(_evidence_dir, _opts), do: invalid!()

  defp identity!(
         version,
         ref,
         runs,
         ci,
         ci_packages,
         hex,
         hex_packages,
         ios,
         mirror,
         maven,
         paths
       ) do
    tree = sha!(ci["tree"])
    base = sha!(ci["base"])

    verify_ci!(ci, ref, tree, base, runs.ci, digest(paths.ci_packages))
    package_digests = verify_packages!(ci_packages, hex_packages, ref, version)

    verify_rehearsal!(
      hex,
      ref,
      tree,
      base,
      runs.hex,
      "hex",
      digest(paths.hex_packages),
      digest(".github/workflows/hex-publish.yml")
    )

    verify_rehearsal!(
      ios,
      ref,
      tree,
      base,
      runs.ios,
      "ios",
      digest(paths.mirror),
      digest(".github/workflows/ios-mirror-backfill.yml")
    )

    verify_mirror!(mirror, version, ref)

    verify_maven!(
      maven,
      version,
      ref,
      tree,
      base,
      runs.maven,
      digest(".github/workflows/maven-publish-fire-drill.yml")
    )

    %{
      version: version,
      ref: ref,
      head: ref,
      tree: tree,
      base: base,
      coordinates: [
        %{id: "android-core", coordinate: "crosswake@#{version}"},
        %{id: "hex-core", coordinate: "crosswake@#{version}"},
        %{id: "ios-core", coordinate: "crosswake@#{version}"}
      ],
      config_digests: digests(File.cwd!(), @config_paths),
      workflow_digests: digests(File.cwd!(), @workflow_paths),
      package_digests: package_digests,
      proofs: [
        proof("candidate.ci", paths.ci),
        proof("package.family", paths.hex_packages),
        proof("hex.rehearsal", paths.hex),
        proof("ios.rehearsal", paths.ios),
        proof("maven.rehearsal", paths.maven),
        proof("mirror.authority", paths.mirror)
      ],
      mirror: %{
        split: sha!(mirror["split_sha"]),
        main: sha!(mirror["remote_main"]),
        tag: "v#{version}",
        plan_sha256: digest(paths.mirror)
      },
      run: %{id: runs.ci, head: ref, status: "COMPLETED", conclusion: "SUCCESS"}
    }
  end

  defp verify_ci!(ci, ref, tree, base, run_id, manifest_digest) do
    exact_keys!(
      ci,
      ~w(schema_version state head tree base run_id run_attempt package_count profile_count install_count artifact_manifest_sha256 cleanroom_result_sha256 external_state_changed credentials_exercised)
    )

    unless ci["schema_version"] == 1 and ci["state"] == "PASS" and ci["head"] == ref and
             ci["tree"] == tree and ci["base"] == base and
             ci["run_id"] == Integer.to_string(run_id) and
             positive_integer_string?(ci["run_attempt"]) and ci["package_count"] == 6 and
             ci["profile_count"] == 5 and ci["install_count"] == 2 and
             ci["artifact_manifest_sha256"] == manifest_digest and
             digest?(ci["cleanroom_result_sha256"]) and
             ci["external_state_changed"] == false and ci["credentials_exercised"] == false,
           do: invalid!()
  end

  defp verify_packages!(ci_packages, hex_packages, ref, version) do
    unless is_list(ci_packages) and is_list(hex_packages) and length(ci_packages) == 6 and
             length(hex_packages) == 6,
           do: invalid!()

    ci_normalized = normalize_packages!(ci_packages, ref, version)
    hex_normalized = normalize_packages!(hex_packages, ref, version)
    unless ci_normalized == hex_normalized, do: invalid!()

    Enum.map(hex_normalized, fn package ->
      %{
        id: package["package"],
        outer_sha256: package["outer_checksum"],
        payload_sha256: package["payload_digest"],
        metadata_sha256: package["metadata_digest"]
      }
    end)
  end

  defp normalize_packages!(rows, ref, version) do
    Enum.zip(@packages, rows)
    |> Enum.map(fn {expected_package, row} ->
      exact_keys!(
        row,
        ~w(package version candidate_ref outer_checksum metadata_digest payload_digest files requirements source unpacked_root)
      )

      unless row["package"] == expected_package and is_binary(row["version"]) and
               Regex.match?(~r/\A\d+\.\d+\.\d+\z/, row["version"]) and
               row["candidate_ref"] == ref and row["source"] == "built_tarball" and
               is_list(row["files"]) and row["files"] != [] and is_list(row["requirements"]) and
               digest?(row["outer_checksum"]) and digest?(row["payload_digest"]) and
               digest?(row["metadata_digest"]),
             do: invalid!()

      if expected_package == "crosswake" and row["version"] != version, do: invalid!()

      Map.take(
        row,
        ~w(package version candidate_ref outer_checksum metadata_digest payload_digest)
      )
    end)
  end

  defp verify_rehearsal!(row, ref, tree, base, run_id, type, observed_digest, workflow_digest) do
    common_keys =
      ~w(schema_version requested_head observed_head observed_tree observed_base candidate_receipt run_id run_head run_conclusion workflow_sha256 external_state_changed)

    case type do
      "hex" -> exact_keys!(row, common_keys ++ ~w(package_artifacts_sha256 package_count))
      "ios" -> exact_keys!(row, common_keys ++ ~w(mirror_observation_sha256))
      _ -> invalid!()
    end

    artifact_digest =
      if type == "hex",
        do: row["package_artifacts_sha256"],
        else: row["mirror_observation_sha256"]

    unless row["schema_version"] == "1.0.0" and row["requested_head"] == ref and
             row["observed_head"] == ref and row["observed_tree"] == tree and
             row["observed_base"] == base and row["run_id"] == Integer.to_string(run_id) and
             row["run_head"] == ref and row["run_conclusion"] == "success" and
             digest?(row["candidate_receipt"]) and digest?(row["workflow_sha256"]) and
             row["workflow_sha256"] == workflow_digest and artifact_digest == observed_digest and
             row["external_state_changed"] == false and
             (type != "hex" or row["package_count"] == 6),
           do: invalid!()
  end

  defp verify_mirror!(mirror, version, ref) do
    exact_keys!(
      mirror,
      ~w(state mode source_ref split_sha remote_main remote_tag atomic_supported authorization_checked authorization_result dry_run_result external_state_changed correction operation push_arguments)
    )

    unless mirror["state"] == "PASS" and mirror["mode"] == "candidate" and
             mirror["source_ref"] == ref and sha?(mirror["split_sha"]) and
             sha?(mirror["remote_main"]) and mirror["remote_tag"] in [nil, "-"] and
             mirror["atomic_supported"] == true and mirror["authorization_checked"] == true and
             mirror["authorization_result"] == "PROVEN" and mirror["dry_run_result"] == "PASS" and
             mirror["external_state_changed"] == false and mirror["correction"] == "none" and
             mirror["operation"] == "REHEARSE_ATOMIC" and is_list(mirror["push_arguments"]) and
             version != "",
           do: invalid!()
  end

  defp verify_maven!(row, version, ref, tree, base, run_id, workflow_digest) do
    exact_keys!(
      row,
      ~w(schema_version candidate_version requested_head observed_head observed_tree observed_base run_id run_head run_conclusion workflow_sha256 state deployment_result dropped external_state_changed coordinate)
    )

    unless row["schema_version"] == "1.0.0" and row["candidate_version"] == version and
             row["requested_head"] == ref and row["observed_head"] == ref and
             row["observed_tree"] == tree and row["observed_base"] == base and
             row["run_id"] == Integer.to_string(run_id) and row["run_head"] == ref and
             row["run_conclusion"] == "success" and row["workflow_sha256"] == workflow_digest and
             row["state"] == "VALIDATED" and row["deployment_result"] == "DROP" and
             row["dropped"] == true and row["external_state_changed"] == false and
             row["coordinate"] ==
               "io.github.sztheory:crosswake-shell-core-android:#{version}-firedrill-#{run_id}",
           do: invalid!()
  end

  defp run_ids!(opts) do
    Map.new(~w(ci hex ios maven)a, fn kind ->
      key = String.to_atom("#{kind}_run_id")
      value = Keyword.fetch!(opts, key)
      unless is_integer(value) and value > 0, do: invalid!()
      {kind, value}
    end)
  end

  defp digests(root, entries) do
    Enum.map(entries, fn {id, path} -> %{id: id, sha256: digest(Path.join(root, path))} end)
  end

  defp proof(id, path), do: %{id: id, status: "PASS", sha256: digest(path)}

  defp read_json!(path) do
    bytes = read_file!(path)
    Jason.decode!(bytes)
  rescue
    _error -> invalid!()
  end

  defp digest(path),
    do: path |> read_file!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp read_file!(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular, size: size}} when size <= @max_file_bytes ->
        File.read!(path)

      _ ->
        invalid!()
    end
  rescue
    _error -> invalid!()
  end

  defp safe_directory!(path) do
    expanded = Path.expand(path)

    case File.lstat(expanded) do
      {:ok, %File.Stat{type: :directory}} -> expanded
      _ -> invalid!()
    end
  end

  defp assert_exact_file_roster!(root) do
    actual = walk_files!(root, "") |> Enum.sort()
    expected = Enum.sort(@files)

    unless actual == expected and
             Enum.reduce(actual, 0, &(File.stat!(Path.join(root, &1)).size + &2)) <=
               @max_total_bytes,
           do: invalid!()
  end

  defp walk_files!(directory, prefix) do
    directory
    |> File.ls!()
    |> Enum.flat_map(fn name ->
      path = Path.join(directory, name)
      relative = if prefix == "", do: name, else: Path.join(prefix, name)

      case File.lstat(path) do
        {:ok, %File.Stat{type: :directory}} -> walk_files!(path, relative)
        {:ok, %File.Stat{type: :regular}} -> [relative]
        _ -> invalid!()
      end
    end)
  rescue
    _error -> invalid!()
  end

  defp exact_keys!(value, keys) when is_map(value) do
    unless Enum.sort(Map.keys(value)) == Enum.sort(keys), do: invalid!()
  end

  defp exact_keys!(_value, _keys), do: invalid!()
  defp sha!(value), do: if(sha?(value), do: value, else: invalid!())
  defp sha?(value), do: is_binary(value) and Regex.match?(@sha_pattern, value)
  defp digest?(value), do: is_binary(value) and Regex.match?(@digest_pattern, value)

  defp positive_integer_string?(value),
    do: is_binary(value) and Regex.match?(~r/\A[1-9]\d*\z/, value)

  defp artifact_run_id!(value) when is_binary(value) do
    case Integer.parse(value) do
      {run_id, ""} when run_id > 0 -> run_id
      _ -> invalid!()
    end
  end

  defp artifact_run_id!(_value), do: invalid!()

  defp invalid!, do: raise(ArgumentError, "candidate evidence is invalid")
end
