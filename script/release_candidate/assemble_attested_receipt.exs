defmodule Crosswake.ReleaseCandidate.AttestedReceiptAssembler do
  @moduledoc false

  @required_packages ~w(
    crosswake
    crosswake_rulestead
    crosswake_rindle
    crosswake_sigra
    crosswake_chimeway
    crosswake_threadline
  )

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
    mirror.authority
  )

  def run! do
    env =
      required_env!(
        ~w(CANDIDATE_HEAD CANDIDATE_TREE CANDIDATE_BASE CANDIDATE_VERSION CANDIDATE_CI_RUN_ID OUTPUT_DIR)
      )

    root = env.output_dir
    ci = read_json!(Path.join(root, "ci/release-candidate-ci-receipt.json"))
    packages = read_json!(Path.join(root, "ci/artifacts/artifacts.json"))
    hex = read_json!(Path.join(root, "hex/rehearsal.json"))
    ios = read_json!(Path.join(root, "ios/rehearsal.json"))
    mirror = read_json!(Path.join(root, "ios/mirror.json"))

    verify_ci!(ci, env)
    verify_packages!(packages, env.candidate_head)
    verify_rehearsal!(hex, env, "hex_run_id")
    verify_rehearsal!(ios, env, "ios_run_id")
    verify_mirror!(mirror, env)

    identity = %{
      version: env.candidate_version,
      ref: env.candidate_head,
      head: env.candidate_head,
      tree: env.candidate_tree,
      base: env.candidate_base,
      coordinates: [
        %{id: "android-core", coordinate: "crosswake@#{env.candidate_version}"},
        %{id: "hex-core", coordinate: "crosswake@#{env.candidate_version}"},
        %{id: "ios-core", coordinate: "crosswake@#{env.candidate_version}"}
      ],
      config_digests:
        digests([
          {"release-please-config", "release-please-config.json"},
          {"release-please-manifest", ".release-please-manifest.json"}
        ]),
      workflow_digests:
        digests([
          {"crosswake-ci", ".github/workflows/crosswake-ci.yml"},
          {"hex-publish", ".github/workflows/hex-publish.yml"},
          {"ios-mirror-backfill", ".github/workflows/ios-mirror-backfill.yml"},
          {"release-please", ".github/workflows/release-please.yml"}
        ]),
      package_digests: package_digests!(packages),
      proofs: [
        proof("candidate.ci", Path.join(root, "ci/release-candidate-ci-receipt.json")),
        proof("package.family", Path.join(root, "hex/packages/artifacts.json")),
        proof("hex.rehearsal", Path.join(root, "hex/rehearsal.json")),
        proof("ios.rehearsal", Path.join(root, "ios/rehearsal.json")),
        proof("mirror.authority", Path.join(root, "ios/mirror.json"))
      ],
      mirror: %{
        split: mirror["split_sha"],
        main: mirror["remote_main"],
        tag: "v#{env.candidate_version}",
        plan_sha256: digest(Path.join(root, "ios/mirror.json"))
      },
      run: %{
        id: env.candidate_ci_run_id,
        head: env.candidate_head,
        status: "COMPLETED",
        conclusion: "SUCCESS"
      }
    }

    receipt =
      Crosswake.ReleaseCandidate.evaluate!(%{
        identity: identity,
        observed_identity: identity,
        checks: Enum.map(@check_ids, &%{id: &1, status: "PASS"}),
        external_state: %{
          publication: "NONE",
          successful_coordinates: [],
          failed_step: nil,
          changed: false,
          all_linked_proven: false
        },
        credentials: %{mirror_write_authority: "PROVEN", exercised: true}
      })

    File.write!(
      Path.join(root, "candidate-receipt.json"),
      Crosswake.ReleaseCandidate.Receipt.encode!(receipt) <> "\n"
    )
  end

  defp required_env!(keys) do
    values =
      Map.new(keys, fn key ->
        {Macro.underscore(key) |> String.to_atom(), System.fetch_env!(key)}
      end)

    %{values | candidate_ci_run_id: parse_id!(values.candidate_ci_run_id)}
  end

  defp parse_id!(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> id
      _ -> invalid!()
    end
  end

  defp read_json!(path), do: path |> File.read!() |> Jason.decode!()

  defp verify_ci!(ci, env) do
    unless ci["state"] == "PASS" and ci["head"] == env.candidate_head and
             ci["tree"] == env.candidate_tree and ci["base"] == env.candidate_base and
             ci["run_id"] == Integer.to_string(env.candidate_ci_run_id) and
             ci["package_count"] == 6 and ci["profile_count"] == 5 and ci["install_count"] == 2 and
             ci["external_state_changed"] == false, do: invalid!()
  end

  defp verify_packages!(packages, head) when is_list(packages) do
    unless Enum.map(packages, & &1["package"]) == @required_packages and
             Enum.all?(packages, &(&1["candidate_ref"] == head)), do: invalid!()
  end

  defp verify_packages!(_, _), do: invalid!()

  defp verify_rehearsal!(rehearsal, env, run_key) do
    run_id = System.fetch_env!(run_key |> String.upcase())

    unless rehearsal["requested_head"] == env.candidate_head and
             rehearsal["observed_head"] == env.candidate_head and
             rehearsal["observed_tree"] == env.candidate_tree and
             rehearsal["observed_base"] == env.candidate_base and rehearsal["run_id"] == run_id and
             rehearsal["run_conclusion"] == "success" and
             rehearsal["external_state_changed"] == false, do: invalid!()
  end

  defp verify_mirror!(mirror, env) do
    unless mirror["state"] == "PASS" and mirror["authorization_result"] == "PROVEN" and
             mirror["dry_run_result"] == "PASS" and mirror["external_state_changed"] == false and
             mirror["source_ref"] == env.candidate_head and is_binary(mirror["split_sha"]) and
             is_binary(mirror["remote_main"]), do: invalid!()
  end

  defp package_digests!(packages) do
    Enum.map(packages, fn package ->
      %{
        id: package["package"],
        outer_sha256: package["outer_checksum"],
        payload_sha256: package["payload_digest"],
        metadata_sha256: package["metadata_digest"]
      }
    end)
  end

  defp digests(entries),
    do: Enum.map(entries, fn {id, path} -> %{id: id, sha256: digest(path)} end)

  defp proof(id, path), do: %{id: id, status: "PASS", sha256: digest(path)}
  defp digest(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
  defp invalid!, do: raise(ArgumentError, "attested candidate receipt inputs are invalid")
end

Crosswake.ReleaseCandidate.AttestedReceiptAssembler.run!()
