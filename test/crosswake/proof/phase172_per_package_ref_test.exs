defmodule Crosswake.Proof.Phase172PerPackageRefTest do
  @moduledoc """
  Non-vacuity proof for Phase 172 (Per-Package Proof Scope).

  Phase 172 loosens the release-candidate proof from one shared `candidate_ref` broadcast onto
  every package, to six independent per-package refs, threaded through the Elixir producer
  (`Artifact`), the Elixir consumer (`Cleanroom`), and both shell transports
  (`hex_artifacts.sh`, `verify_companion_cleanroom.sh`).

  This module proves the collapse cannot return by any route: neither by reintroducing a
  family-wide `jq ... | unique | length == 1` reduction in the shell transport, nor by
  re-hoisting `candidate_ref` back onto `Artifact`'s family-level input map, nor by silently
  dropping either of the two new graded-claim branches from `Cleanroom.public_artifact_reason/3`
  without a named test failing.

  Every "X is gone" assertion below is paired with a sibling "Y is there instead" assertion in
  the same test, per this milestone's absence-scored-as-success rule
  (`.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`).
  """

  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Artifact
  alias Crosswake.ReleaseCandidate.Cleanroom

  @script "script/verify_companion_cleanroom.sh"
  @hex_artifacts_script "script/release_candidate/hex_artifacts.sh"
  @artifact_source "lib/crosswake/release_candidate/artifact.ex"
  @cleanroom_source "lib/crosswake/release_candidate/cleanroom.ex"

  # The fixed positional width of one artifact's chunk across the CLI boundary
  # (package, version, candidate_ref, tarball, unpacked_root, outer_checksum, source).
  # Named here, not inlined as a bare `7`, so a future field addition updates one place.
  @artifact_field_count 7

  @candidate_ref String.duplicate("a", 40)
  @second_candidate_ref String.duplicate("b", 40)
  @package_count length(Artifact.packages())

  describe "the family-wide ref collapse cannot return in the shell transport (SC#1)" do
    test "no jq expression collapses the approved manifest's refs to one scalar, and a per-package lookup is there instead" do
      source = non_comment_source!(@script)

      refute source =~ "unique",
             "verify_companion_cleanroom.sh must not reintroduce any `unique`-based reduction " <>
               "over the approved manifest's candidate_ref column"

      assert source =~
               ~r/jq -er --arg package "\$package" '\.\[\] \| select\(\.package == \$package\) \| \.candidate_ref'/,
             "a per-package candidate_ref lookup, keyed on $package, must be present in its place"
    end

    test "the observed ref is assigned exactly once, from a repository head resolution, never from the approved manifest" do
      source = non_comment_source!(@script)

      assignments = Regex.scan(~r/^\s*MATRIX_PUBLIC_REF=.*$/m, source) |> List.flatten()

      assert length(assignments) == 1,
             "MATRIX_PUBLIC_REF must be assigned exactly once; found #{length(assignments)}: #{inspect(assignments)}"

      [assignment] = assignments

      assert assignment =~ ~r/git -C "\$MATRIX_REPO_ROOT" rev-parse HEAD/,
             "the single MATRIX_PUBLIC_REF assignment must resolve independently from git rev-parse HEAD"

      refute assignment =~ "MATRIX_APPROVED_MANIFEST",
             "MATRIX_PUBLIC_REF must never be resolved from the approved manifest it is later compared against (T-172-01)"
    end

    test "neither shell script passes a ref as the first positional into Artifact.inspect_cli!/1, and the root/manifest positionals are there instead" do
      script_source = non_comment_source!(@script)
      hex_source = non_comment_source!(@hex_artifacts_script)

      assert Regex.match?(
               ~r/inspect_cli!\(System\.argv\(\)\)'\s*--\s*\\\n\s*"\$public_root" "\$normalized_manifest" "\$\{artifact_args\[@\]\}"/,
               script_source
             ),
             "verify_companion_cleanroom.sh's producer CLI call must pass public_root and the " <>
               "manifest path first, not a ref"

      assert Regex.match?(
               ~r/inspect_cli!\(System\.argv\(\)\)'\s*--\s*\\\n\s*"\$OUTPUT_DIR" "\$MANIFEST" "\$\{ARTIFACT_ARGS\[@\]\}"/,
               hex_source
             ),
             "hex_artifacts.sh's producer CLI call must pass OUTPUT_DIR and MANIFEST first, not a ref"
    end
  end

  describe "both shell scripts group artifact positionals in sevens (SC#1, task 1b)" do
    test "verify_companion_cleanroom.sh's artifact_args append carries exactly the named field count" do
      source = non_comment_source!(@script)
      line = single_line_matching!(source, ~r/^\s*artifact_args\+=\(.*\)\s*$/m)

      assert quoted_token_count(line) == @artifact_field_count,
             "artifact_args must append exactly #{@artifact_field_count} positional fields per " <>
               "package; found #{quoted_token_count(line)} in: #{line}"

      assert line =~ "\"$MATRIX_PUBLIC_REF\"",
             "the observed ref must still be one of the appended fields"
    end

    test "hex_artifacts.sh's ARTIFACT_ARGS append carries exactly the named field count" do
      source = non_comment_source!(@hex_artifacts_script)
      line = single_line_matching!(source, ~r/^\s*ARTIFACT_ARGS\+=\(.*\)\s*$/m)

      assert quoted_token_count(line) == @artifact_field_count,
             "ARTIFACT_ARGS must append exactly #{@artifact_field_count} positional fields per " <>
               "package; found #{quoted_token_count(line)} in: #{line}"

      assert line =~ "\"$CANDIDATE_REF\"",
             "the candidate ref must still be one of the appended fields"
    end
  end

  describe "candidate_ref is per-artifact on the producer, not a family-level input (SC#1)" do
    test "Artifact's family-level input keys omit candidate_ref, and the per-artifact keys carry it instead" do
      source = File.read!(@artifact_source)

      input_keys = attribute_body!(source, "input_keys")
      artifact_keys = attribute_body!(source, "artifact_keys")

      refute input_keys =~ "candidate_ref",
             "Artifact.@input_keys must not carry a family-level candidate_ref: #{inspect(input_keys)}"

      assert artifact_keys =~ "candidate_ref",
             "Artifact.@artifact_keys (per-artifact) must carry candidate_ref: #{inspect(artifact_keys)}"
    end
  end

  describe "candidate_ref is present on Cleanroom's approved/public schemas but not the candidate-local one (SC#1)" do
    test "the candidate-local artifact keys omit candidate_ref, and the approved/public keys carry it instead" do
      source = File.read!(@cleanroom_source)

      candidate_local_keys = attribute_body!(source, "artifact_keys")
      approved_keys = attribute_body!(source, "approved_artifact_keys")
      public_keys = attribute_body!(source, "public_artifact_keys")

      refute candidate_local_keys =~ "candidate_ref",
             "Cleanroom.@artifact_keys (candidate-local) must not carry candidate_ref: " <>
               inspect(candidate_local_keys)

      assert approved_keys =~ "candidate_ref",
             "Cleanroom.@approved_artifact_keys must carry candidate_ref: #{inspect(approved_keys)}"

      assert public_keys =~ "candidate_ref",
             "Cleanroom.@public_artifact_keys must carry candidate_ref: #{inspect(public_keys)}"
    end
  end

  describe "the three claim strings are reachable through the public evaluator, not merely present in source (SC#4)" do
    test "the two new reason strings and all three claim strings are typed in the classifier source" do
      source = non_comment_source!(@cleanroom_source)

      for literal <- ["\"reachable_and_compatible\"", "\"unproven\"", "\"fully_proven\""] do
        assert source =~ literal, "#{literal} must appear in Cleanroom's source"
      end
    end

    test "a fully-proven family reaches the fully_proven claim for every package" do
      result = public_fixture(@candidate_ref) |> Cleanroom.evaluate_public!()

      assert result.state == "COMPLETE"
      assert length(result.package_claims) == @package_count
      assert Enum.all?(result.package_claims, &(&1.claim == "fully_proven"))
    end

    test "a drifted-but-byte-identical package reaches the reachable_and_compatible claim through the evaluator" do
      target = hd(Artifact.packages())

      result =
        public_fixture(@candidate_ref)
        |> override_public(target, &Map.put(&1, :candidate_ref, @second_candidate_ref))
        |> Cleanroom.evaluate_public!()

      assert claim_for(result, target) == "reachable_and_compatible"
    end

    test "a drifted package whose bytes also differ reaches the unproven claim, never fully_proven, through the evaluator" do
      target = hd(Artifact.packages())

      result =
        public_fixture(@candidate_ref)
        |> override_public(target, &Map.put(&1, :candidate_ref, @second_candidate_ref))
        |> override_public(target, &Map.put(&1, :payload_digest, digest("mutated-#{target}")))
        |> Cleanroom.evaluate_public!()

      assert claim_for(result, target) == "unproven"
    end

    test "the claim entry count equals the package count and no package carries two claims, for a fully-proven run" do
      result = public_fixture(@candidate_ref) |> Cleanroom.evaluate_public!()

      assert length(result.package_claims) == @package_count

      assert result.package_claims |> Enum.map(& &1.package) |> Enum.uniq() |> length() ==
               @package_count
    end

    test "the claim entry count equals the package count and no package carries two claims, for a mixed-claim run" do
      target = hd(Artifact.packages())

      result =
        public_fixture(@candidate_ref)
        |> override_public(target, &Map.put(&1, :candidate_ref, @second_candidate_ref))
        |> Cleanroom.evaluate_public!()

      assert length(result.package_claims) == @package_count

      assert result.package_claims |> Enum.map(& &1.package) |> Enum.uniq() |> length() ==
               @package_count
    end
  end

  # --- fixture construction -------------------------------------------------

  defp public_fixture(ref) do
    fixture_root =
      Path.join(
        System.tmp_dir!(),
        "cw-p172-proof-#{System.unique_integer([:positive, :monotonic])}"
      )

    repository_root = Path.join(fixture_root, "repo")
    source_root = Path.join(fixture_root, "public")
    scratch_root = Path.join(fixture_root, "scratch")
    File.mkdir_p!(repository_root)
    File.mkdir_p!(source_root)
    File.mkdir_p!(scratch_root)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(fixture_root) end)

    artifacts =
      Enum.with_index(Artifact.packages(), fn package, index ->
        root = Path.join(source_root, package)
        File.mkdir!(root)

        %{
          package: package,
          version: if(index == 0, do: "0.2.1", else: "0.1.#{index}"),
          candidate_ref: ref,
          unpacked_root: root,
          metadata_digest: digest("metadata-#{package}"),
          payload_digest: digest("payload-#{package}")
        }
      end)

    approved_artifacts =
      Enum.map(
        artifacts,
        &Map.take(&1, [:package, :version, :candidate_ref, :metadata_digest, :payload_digest])
      )

    public_artifacts =
      Enum.map(artifacts, fn artifact ->
        artifact
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
      repository_root: repository_root,
      source_root: source_root,
      approved_artifacts: approved_artifacts,
      public_artifacts: public_artifacts,
      installs: installs,
      profile_results: profile_results,
      live_status: "PASS"
    }
  end

  defp override_public(fixture, package, callback) do
    update_in(fixture.public_artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end

  defp claim_for(result, package) do
    result.package_claims |> Enum.find(&(&1.package == package)) |> Map.fetch!(:claim)
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  # --- source-reading helpers ------------------------------------------------

  # Strips full-line `#` comments before any grep-hygiene assertion, so a comment mentioning a
  # removed construct can never make a live-code assertion pass or fail spuriously (task 1e).
  defp non_comment_source!(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.trim() |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp single_line_matching!(source, pattern) do
    case Regex.run(pattern, source) do
      [line] -> String.trim_trailing(line)
      nil -> flunk("no line in source matched #{inspect(pattern)}")
    end
  end

  defp quoted_token_count(line), do: Regex.scan(~r/"[^"]*"/, line) |> length()

  # Extracts the body of a `@name ~w(...)a` module attribute, single- or multi-line.
  defp attribute_body!(source, name) do
    case Regex.run(~r/@#{name}\s+~w\((.*?)\)a/s, source) do
      [_, body] -> body
      nil -> flunk("no @#{name} ~w(...)a attribute found in source")
    end
  end
end
