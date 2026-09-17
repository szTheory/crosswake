defmodule Crosswake.ReleaseCandidate.ArtifactTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Artifact
  alias Crosswake.ReleaseCandidate.Cleanroom

  @candidate_ref String.duplicate("a", 40)
  @second_candidate_ref String.duplicate("b", 40)
  @packages ~w(
    crosswake
    crosswake_rulestead
    crosswake_rindle
    crosswake_sigra
    crosswake_chimeway
    crosswake_threadline
  )

  test "inspects exactly six non-empty built tarball payloads with stable normalized digests" do
    assert Code.ensure_loaded?(Artifact)

    assert function_exported?(Artifact, :inspect_family!, 1),
           "Artifact.inspect_family!/1 must inspect the exact candidate package family"

    input = fixture_family()
    first = Artifact.inspect_family!(input)
    second = Artifact.inspect_family!(input)

    assert first == second
    assert Enum.map(first, & &1.package) == @packages

    for observation <- first do
      assert Map.keys(observation) |> Enum.sort() ==
               ~w(candidate_ref files metadata_digest outer_checksum package payload_digest requirements source unpacked_root version)a

      assert observation.candidate_ref =~ ~r/\A[0-9a-f]{40}\z/
      assert observation.source == "built_tarball"
      assert observation.files != []
      assert observation.unpacked_root != File.cwd!()

      for digest <- [
            observation.outer_checksum,
            observation.metadata_digest,
            observation.payload_digest
          ] do
        assert digest =~ ~r/\A[0-9a-f]{64}\z/
      end
    end
  end

  test "rejects package-set, file-list, checksum, path, output, and version mutations" do
    mutations = [
      missing_package: fn input -> update_in(input.artifacts, &tl/1) end,
      wrong_version: fn input ->
        mutate_artifact(input, "crosswake", &Map.put(&1, :version, "0.2.9"))
      end,
      changed_checksum: fn input ->
        mutate_artifact(
          input,
          "crosswake",
          &Map.put(&1, :outer_checksum, String.duplicate("f", 64))
        )
      end,
      missing_declared_file: fn input ->
        mutate_metadata(input, "crosswake", fn metadata ->
          put_in(metadata, ["files"], metadata["files"] ++ ["lib/missing.ex"])
        end)
      end,
      extra_payload_file: fn input ->
        mutate_artifact(input, "crosswake", fn artifact ->
          File.write!(Path.join(artifact.unpacked_root, "unexpected.txt"), "unexpected")
          artifact
        end)
      end,
      path_escape: fn input ->
        mutate_metadata(input, "crosswake", fn metadata ->
          put_in(metadata, ["files"], metadata["files"] ++ ["../escape"])
        end)
      end,
      empty_package: fn input ->
        mutate_artifact(input, "crosswake", fn artifact ->
          File.rm_rf!(Path.join(artifact.unpacked_root, "lib"))
          File.rm!(Path.join(artifact.unpacked_root, "mix.exs"))
          write_metadata(artifact.unpacked_root, metadata("crosswake", artifact.version, []))
          artifact
        end)
      end,
      missing_output: fn input ->
        mutate_artifact(input, "crosswake", fn artifact ->
          File.rm!(artifact.tarball)
          artifact
        end)
      end,
      symlink_entry: fn input ->
        mutate_artifact(input, "crosswake", fn artifact ->
          File.ln_s!("mix.exs", Path.join(artifact.unpacked_root, "linked.exs"))
          artifact
        end)
      end,
      repository_fallback: fn input ->
        mutate_artifact(input, "crosswake", &Map.put(&1, :source, "repository_path"))
      end,
      top_level_candidate_ref: fn input ->
        Map.put(input, :candidate_ref, @candidate_ref)
      end,
      malformed_ref: fn input ->
        mutate_artifact(input, "crosswake", &Map.put(&1, :candidate_ref, "not-a-ref"))
      end
    ]

    for {name, mutate} <- mutations do
      error =
        assert_raise ArgumentError, fn ->
          input = fixture_family()
          input |> mutate.() |> Artifact.inspect_family!()
        end

      assert Exception.message(error) == "candidate artifact input is invalid",
             "#{name} did not fail closed"
    end
  end

  test "two artifacts in one family carry their own distinct candidate_ref, not a broadcast value" do
    input =
      mutate_artifact(
        fixture_family(),
        "crosswake_sigra",
        &Map.put(&1, :candidate_ref, @second_candidate_ref)
      )

    observations = Artifact.inspect_family!(input)

    assert by_package(observations, "crosswake").candidate_ref == @candidate_ref
    assert by_package(observations, "crosswake_sigra").candidate_ref == @second_candidate_ref
    assert by_package(observations, "crosswake_rulestead").candidate_ref == @candidate_ref
    assert by_package(observations, "crosswake_rindle").candidate_ref == @candidate_ref
    assert by_package(observations, "crosswake_chimeway").candidate_ref == @candidate_ref
    assert by_package(observations, "crosswake_threadline").candidate_ref == @candidate_ref
  end

  test "changed metadata and payload bytes change their independent normalized digests" do
    baseline_input = fixture_family()
    baseline = Artifact.inspect_family!(baseline_input) |> by_package("crosswake")

    metadata_input = fixture_family()

    mutate_metadata(metadata_input, "crosswake", fn metadata ->
      Map.put(metadata, "description", "changed metadata")
    end)

    changed_metadata = Artifact.inspect_family!(metadata_input) |> by_package("crosswake")

    assert changed_metadata.metadata_digest != baseline.metadata_digest
    assert changed_metadata.payload_digest == baseline.payload_digest

    payload_input = fixture_family()

    mutate_artifact(payload_input, "crosswake", fn artifact ->
      File.write!(Path.join(artifact.unpacked_root, "lib/crosswake.ex"), "changed payload")
      artifact
    end)

    changed_payload = Artifact.inspect_family!(payload_input) |> by_package("crosswake")

    assert changed_payload.payload_digest != baseline.payload_digest
    assert changed_payload.metadata_digest == baseline.metadata_digest
  end

  test "requirements are normalized without credentials, URLs, or volatile adapter diagnostics" do
    observations = Artifact.inspect_family!(fixture_family())
    encoded = Jason.encode!(observations)

    assert by_package(observations, "crosswake_rulestead").requirements == [
             %{name: "crosswake", optional: false, requirement: "~> 0.2"}
           ]

    refute encoded =~ "private-token"
    refute encoded =~ "https://"
    refute encoded =~ "stderr"
  end

  # SC#3 / XPUB-02: the existing digest comparisons above stop at the digest-string layer. A
  # digest-string comparison can pass while the underlying byte-for-byte check has silently
  # stopped running. These two tests pin the floor one layer lower by mutating a real file's
  # bytes and carrying the recomputed digest into an exact-public evaluation, so a verdict is
  # actually reached on the mutated content rather than merely comparing two strings.
  describe "byte-exact floor at the tarball layer (SC#3, XPUB-02)" do
    test "byte-exact regression anchor: a single real byte flip still fails the proof -- silent weakening would show as fully_proven/COMPLETE" do
      baseline_observations = Artifact.inspect_family!(fixture_family())
      baseline = by_package(baseline_observations, "crosswake")

      mutated_input = fixture_family()

      mutate_artifact(mutated_input, "crosswake", fn artifact ->
        File.write!(Path.join(artifact.unpacked_root, "lib/crosswake.ex"), "byte-exact mutation")
        artifact
      end)

      mutated = mutated_input |> Artifact.inspect_family!() |> by_package("crosswake")

      assert mutated.payload_digest != baseline.payload_digest,
             "the fixture mutation must actually change the recomputed payload digest"

      result =
        baseline_observations
        |> public_evaluation_input()
        |> override_public("crosswake", &Map.put(&1, :payload_digest, mutated.payload_digest))
        |> Cleanroom.evaluate_public!()

      assert result.failed_packages == [%{package: "crosswake", reason: "digest_mismatch"}]
      assert result.state == "BLOCKED"
    end

    test "drift cannot launder a byte change: same mutation plus a drifted ref reports unproven, never reachable_and_compatible or fully_proven" do
      baseline_observations = Artifact.inspect_family!(fixture_family())
      baseline = by_package(baseline_observations, "crosswake")

      mutated_input = fixture_family()

      mutate_artifact(mutated_input, "crosswake", fn artifact ->
        File.write!(Path.join(artifact.unpacked_root, "lib/crosswake.ex"), "byte-exact mutation")
        artifact
      end)

      mutated = mutated_input |> Artifact.inspect_family!() |> by_package("crosswake")

      assert mutated.payload_digest != baseline.payload_digest,
             "the fixture mutation must actually change the recomputed payload digest"

      result =
        baseline_observations
        |> public_evaluation_input()
        |> override_public("crosswake", &Map.put(&1, :payload_digest, mutated.payload_digest))
        |> override_public("crosswake", &Map.put(&1, :candidate_ref, @second_candidate_ref))
        |> Cleanroom.evaluate_public!()

      assert result.failed_packages == [%{package: "crosswake", reason: "unproven"}]
      refute result.state == "COMPLETE"
    end
  end

  defp public_evaluation_input(observations) do
    scratch_root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-artifact-proof-scratch-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir_p!(scratch_root)
    on_exit(fn -> File.rm_rf!(scratch_root) end)

    source_root = observations |> hd() |> Map.fetch!(:unpacked_root) |> Path.dirname()

    approved_artifacts =
      Enum.map(
        observations,
        &Map.take(&1, [:package, :version, :candidate_ref, :metadata_digest, :payload_digest])
      )

    public_artifacts =
      Enum.map(observations, fn observation ->
        observation
        |> Map.take([
          :package,
          :version,
          :candidate_ref,
          :unpacked_root,
          :metadata_digest,
          :payload_digest
        ])
        |> Map.put(:status, "PASS")
        |> Map.put(:source, "hex_registry")
        |> Map.put(:path_lock_count, 0)
      end)

    installs =
      for profile <- Cleanroom.profiles(), pass <- [1, 2] do
        root = Path.join(scratch_root, "#{profile}-#{pass}")
        File.mkdir!(root)
        %{profile: profile, pass: pass, status: "PASS", scratch_root: root, path_lock_count: 0}
      end

    profile_results =
      Enum.map(Cleanroom.profiles(), fn profile ->
        %{
          profile: profile,
          package: "crosswake_#{profile}",
          status: "PASS",
          passed_checks: Cleanroom.expected_checks(profile),
          negative_control: "PASS"
        }
      end)

    %{
      source_mode: "exact-public",
      generator_version: "1.8.13",
      repository_root: File.cwd!(),
      source_root: source_root,
      approved_artifacts: approved_artifacts,
      public_artifacts: public_artifacts,
      installs: installs,
      profile_results: profile_results,
      live_status: "PASS"
    }
  end

  defp override_public(input, package, callback) do
    update_in(input.public_artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end

  defp fixture_family do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-artifact-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    File.mkdir!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    artifacts =
      Enum.map(@packages, fn package ->
        version = if package == "crosswake", do: "0.2.1", else: "0.1.0"
        unpacked_root = Path.join(root, "unpacked/#{package}")
        File.mkdir_p!(Path.join(unpacked_root, "lib"))
        source_file = if package == "crosswake", do: "lib/crosswake.ex", else: "lib/#{package}.ex"
        File.write!(Path.join(unpacked_root, source_file), "defmodule Fixture do\nend\n")
        File.write!(Path.join(unpacked_root, "mix.exs"), "# fixture\n")

        requirements =
          if package == "crosswake",
            do: [],
            else: [%{"name" => "crosswake", "requirement" => "~> 0.2", "optional" => false}]

        write_metadata(
          unpacked_root,
          metadata(package, version, ["lib", source_file, "mix.exs"], requirements)
        )

        tarball = Path.join(root, "tarballs/#{package}-#{version}.tar")
        File.mkdir_p!(Path.dirname(tarball))
        File.write!(tarball, "built tarball bytes for #{package} #{version}")

        %{
          package: package,
          version: version,
          candidate_ref: @candidate_ref,
          tarball: tarball,
          unpacked_root: unpacked_root,
          outer_checksum: sha256(File.read!(tarball)),
          source: "built_tarball"
        }
      end)

    %{output_root: root, artifacts: artifacts}
  end

  defp metadata(package, version, files, requirements \\ []) do
    %{
      "name" => package,
      "version" => version,
      "description" => "fixture package",
      "links" => %{"Documentation" => "https://hexdocs.pm/#{package}"},
      "files" => files,
      "requirements" => requirements,
      "build_tools" => ["mix"]
    }
  end

  defp write_metadata(root, metadata) do
    terms =
      Enum.map(metadata, fn {key, value} ->
        {key, encode_metadata(value)}
      end)

    bytes = Enum.map_join(terms, "", &:io_lib.format("~p.~n", [&1]))
    File.write!(Path.join(root, "hex_metadata.config"), bytes)
  end

  defp encode_metadata(value) when is_binary(value), do: value
  defp encode_metadata(value) when is_boolean(value), do: value
  defp encode_metadata({key, value}), do: {key, encode_metadata(value)}
  defp encode_metadata(value) when is_list(value), do: Enum.map(value, &encode_metadata/1)

  defp encode_metadata(value) when is_map(value),
    do: Enum.map(value, fn {key, nested} -> {key, encode_metadata(nested)} end)

  defp mutate_artifact(input, package, callback) do
    update_in(input.artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end

  defp mutate_metadata(input, package, callback) do
    mutate_artifact(input, package, fn artifact ->
      metadata_path = Path.join(artifact.unpacked_root, "hex_metadata.config")
      {:ok, terms} = :file.consult(String.to_charlist(metadata_path))
      decoded = Map.new(terms)
      write_metadata(artifact.unpacked_root, callback.(decoded))
      artifact
    end)
  end

  defp by_package(observations, package) when is_list(observations),
    do: Enum.find(observations, &(&1.package == package))

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
