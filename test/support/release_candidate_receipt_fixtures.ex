defmodule Crosswake.ReleaseCandidateReceiptFixtures do
  @moduledoc false

  @version "0.2.4"
  @head String.duplicate("a", 40)
  @tree String.duplicate("b", 40)
  @base String.duplicate("c", 40)
  @split String.duplicate("d", 40)
  @mirror_main String.duplicate("e", 40)
  @digest String.duplicate("1", 64)
  @runs %{ci: 1001, hex: 1002, ios: 1003, maven: 1004}
  @files %{
    ci: "ci/release-candidate-ci-receipt.json",
    ci_packages: "ci/artifacts/artifacts.json",
    cleanroom: "ci/cleanroom.json",
    hex: "hex/rehearsal.json",
    hex_packages: "hex/packages/artifacts.json",
    ios: "ios/rehearsal.json",
    mirror: "ios/mirror.json",
    maven: "maven/rehearsal.json"
  }

  def build!(root) do
    File.mkdir_p!(root)
    ci_packages = package_rows("a")
    hex_packages = package_rows("b")
    write!(root, @files.ci_packages, ci_packages)

    write!(root, @files.cleanroom, %{
      "package_count" => 6,
      "profile_count" => 5,
      "install_count" => 2,
      "profile_results" => []
    })

    write!(root, @files.hex_packages, hex_packages)

    write!(root, @files.ci, %{
      "schema_version" => 1,
      "state" => "PASS",
      "head" => @head,
      "tree" => @tree,
      "base" => @base,
      "run_id" => Integer.to_string(@runs.ci),
      "run_attempt" => "1",
      "package_count" => 6,
      "profile_count" => 5,
      "install_count" => 2,
      "artifact_manifest_sha256" => file_digest(root, @files.ci_packages),
      "cleanroom_result_sha256" => file_digest(root, @files.cleanroom),
      "external_state_changed" => false,
      "credentials_exercised" => false
    })

    mirror = %{
      "state" => "PASS",
      "mode" => "candidate",
      "source_ref" => @head,
      "split_sha" => @split,
      "remote_main" => @mirror_main,
      "remote_tag" => "-",
      "atomic_supported" => true,
      "authorization_checked" => true,
      "authorization_result" => "PROVEN",
      "dry_run_result" => "PASS",
      "external_state_changed" => false,
      "correction" => "none",
      "operation" => "REHEARSE_ATOMIC",
      "push_arguments" => []
    }

    write!(root, @files.mirror, mirror)

    write!(
      root,
      @files.hex,
      rehearsal(
        "hex",
        "package_artifacts_sha256",
        file_digest(root, @files.hex_packages),
        @runs.hex
      )
    )

    write!(
      root,
      @files.ios,
      rehearsal("ios", "mirror_observation_sha256", file_digest(root, @files.mirror), @runs.ios)
    )

    write!(root, @files.maven, %{
      "schema_version" => "1.0.0",
      "candidate_version" => @version,
      "requested_head" => @head,
      "observed_head" => @head,
      "observed_tree" => @tree,
      "observed_base" => @base,
      "run_id" => Integer.to_string(@runs.maven),
      "run_head" => @head,
      "run_conclusion" => "success",
      "workflow_sha256" => repo_digest(".github/workflows/maven-publish-fire-drill.yml"),
      "state" => "VALIDATED",
      "deployment_result" => "DROP",
      "dropped" => true,
      "external_state_changed" => false,
      "coordinate" =>
        "io.github.sztheory:crosswake-shell-core-android:#{@version}-firedrill-#{@runs.maven}"
    })

    %{root: root, version: @version, ref: @head, runs: @runs, files: @files}
  end

  def selectors(%{version: version, ref: ref, runs: runs}) do
    [
      version: version,
      ref: ref,
      ci_run_id: runs.ci,
      hex_run_id: runs.hex,
      ios_run_id: runs.ios,
      maven_run_id: runs.maven
    ]
  end

  def mutate_json!(%{root: root, files: files}, kind, fun) do
    path = Path.join(root, Map.fetch!(files, kind))
    value = path |> File.read!() |> Jason.decode!()
    write!(root, Map.fetch!(files, kind), fun.(value))
  end

  defp package_rows(outer_prefix) do
    Crosswake.ReleaseCandidate.Artifact.packages()
    |> Enum.map(fn package ->
      version = if package == "crosswake", do: @version, else: "0.1.0"

      suffix =
        Integer.to_string(
          Enum.find_index(Crosswake.ReleaseCandidate.Artifact.packages(), &(&1 == package)) + 1
        )

      %{
        "package" => package,
        "version" => version,
        "candidate_ref" => @head,
        "outer_checksum" => String.duplicate(outer_prefix, 63) <> suffix,
        "metadata_digest" => @digest,
        "payload_digest" => String.duplicate("2", 64),
        "files" => [%{"path" => "mix.exs", "type" => "file"}],
        "requirements" => [],
        "source" => "built_tarball",
        "unpacked_root" => "/runner/unpacked/#{package}"
      }
    end)
  end

  defp rehearsal(kind, digest_key, digest_value, run_id) do
    base = %{
      "schema_version" => "1.0.0",
      "requested_head" => @head,
      "observed_head" => @head,
      "observed_tree" => @tree,
      "observed_base" => @base,
      "candidate_receipt" => @digest,
      "run_id" => Integer.to_string(run_id),
      "run_head" => @head,
      "run_conclusion" => "success",
      "workflow_sha256" =>
        repo_digest(
          ".github/workflows/#{if kind == "hex", do: "hex-publish", else: "ios-mirror-backfill"}.yml"
        ),
      "external_state_changed" => false
    }

    Map.put(base, digest_key, digest_value)
    |> then(fn value -> if kind == "hex", do: Map.put(value, "package_count", 6), else: value end)
  end

  defp write!(root, relative, value) do
    path = Path.join(root, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode!(value) <> "\n")
    value
  end

  defp file_digest(root, relative), do: digest(Path.join(root, relative))
  defp repo_digest(path), do: digest(path)

  defp digest(path),
    do: path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
end
