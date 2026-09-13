defmodule Crosswake.ReleaseCandidate.CleanroomTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Cleanroom

  @packages ~w(
    crosswake
    crosswake_rulestead
    crosswake_rindle
    crosswake_sigra
    crosswake_chimeway
    crosswake_threadline
  )
  @profiles ~w(rulestead rindle sigra chimeway threadline)

  test "candidate-local proof normalizes six payloads, five profiles, and two isolated installs" do
    assert Code.ensure_loaded?(Cleanroom),
           "Cleanroom.evaluate!/1 must enforce candidate-local generated-host proof"

    assert function_exported?(Cleanroom, :evaluate!, 1),
           "Cleanroom.evaluate!/1 must enforce candidate-local generated-host proof"

    input = candidate_fixture()
    result = Cleanroom.evaluate!(shuffle_input(input))

    assert result.generator_version == "1.8.13"
    assert result.install_count == 2
    assert result.package_count == 6
    assert result.profile_count == 5
    assert result.source_mode == "candidate-local"
    assert result.path_lock_count == 0
    assert result.live_status == "not_applicable"
    assert Enum.map(result.packages, & &1.package) == @packages
    assert Enum.map(result.profile_results, & &1.profile) == @profiles
    assert Enum.all?(result.profile_results, &(&1.status == "PASS"))
    assert Enum.all?(result.profile_results, &(&1.negative_control == "PASS"))
    assert Enum.all?(result.profile_results, &(&1.digest =~ ~r/\A[0-9a-f]{64}\z/))
  end

  test "candidate-local source authority rejects incomplete, duplicate, public, and repository inputs" do
    input = candidate_fixture()

    mutations = [
      empty: %{input | artifacts: []},
      single: %{input | artifacts: [hd(input.artifacts)]},
      missing: %{input | artifacts: tl(input.artifacts)},
      duplicate: %{input | artifacts: [hd(input.artifacts) | input.artifacts]},
      extra: %{input | artifacts: input.artifacts ++ [%{hd(input.artifacts) | package: "other"}]},
      public_source: update_artifact(input, "crosswake", &Map.put(&1, :source, "hex_registry")),
      repository_root:
        update_artifact(input, "crosswake", fn artifact ->
          %{artifact | unpacked_root: input.repository_root}
        end),
      outside_source_root:
        update_artifact(input, "crosswake", fn artifact ->
          %{artifact | unpacked_root: System.tmp_dir!()}
        end)
    ]

    for {name, mutation} <- mutations do
      error = assert_raise ArgumentError, fn -> Cleanroom.evaluate!(mutation) end
      assert Exception.message(error) == "candidate clean-room input is invalid", "#{name} passed"
    end
  end

  test "every profile requires its complete positive surface and deliberate negative control" do
    input = candidate_fixture()

    for profile <- input.profile_results do
      without_check =
        update_profile(input, profile.profile, fn observation ->
          %{observation | passed_checks: tl(observation.passed_checks)}
        end)

      assert_raise ArgumentError, ~r/candidate clean-room input is invalid/, fn ->
        Cleanroom.evaluate!(without_check)
      end

      without_negative =
        update_profile(input, profile.profile, &Map.put(&1, :negative_control, "FAIL"))

      assert_raise ArgumentError, ~r/candidate clean-room input is invalid/, fn ->
        Cleanroom.evaluate!(without_negative)
      end
    end
  end

  test "install observations require two distinct invocation-owned roots per profile" do
    input = candidate_fixture()

    mutations = [
      one_pass: %{input | installs: Enum.reject(input.installs, &(&1.pass == 2))},
      duplicate_pass: %{input | installs: [hd(input.installs) | input.installs]},
      shared_root:
        update_install(input, "rulestead", 2, fn install ->
          %{install | scratch_root: hd(input.installs).scratch_root}
        end),
      repository_root:
        update_install(input, "rulestead", 1, fn install ->
          %{install | scratch_root: input.repository_root}
        end),
      failed: update_install(input, "rulestead", 1, &Map.put(&1, :status, "FAIL")),
      path_lock: update_install(input, "rulestead", 1, &Map.put(&1, :path_lock_count, 1))
    ]

    for {name, mutation} <- mutations do
      error =
        assert_raise ArgumentError, ~r/candidate clean-room input is invalid/, fn ->
          Cleanroom.evaluate!(mutation)
        end

      assert Exception.message(error) == "candidate clean-room input is invalid", "#{name} passed"
    end
  end

  test "candidate harness declares the pinned generator and closed source-mode contract" do
    script = File.read!("script/verify_companion_cleanroom.sh")

    assert script =~ "--source-mode"
    assert script =~ "candidate-local"
    assert script =~ "exact-public"
    assert script =~ "phx_new 1.8.13"
    assert script =~ "mix phx.new"
    assert script =~ "mktemp -d"
    assert script =~ "for INSTALL_PASS in 1 2"
    assert script =~ ~S(config :crosswake, :${COMPANION_SUFFIX}, %{enabled: true})
    assert script =~ ~S(f"config :crosswake, :{profile}, %{{enabled: true}}\n")
    refute script =~ ~r/config :crosswake, :(?:\$\{COMPANION_SUFFIX\}|\{profile\}), enabled: true/
    assert script =~ ~S(id: "clean-room-home")
    assert script =~ ~S(metadata: %{)

    assert script =~
             ~S(mix crosswake.doctor --router CleanRoomHostWeb.Router > "$MATRIX_PASS_ROOT/doctor.log" || matrix_fail)

    refute script =~ ~s(rm -rf "$CLEAN_ROOM_DIR")
  end

  @tag :post_publication
  test "exact-public proof requires six registry payloads, the same profiles, and live status" do
    assert function_exported?(Cleanroom, :evaluate_public!, 1),
           "Cleanroom.evaluate_public!/1 must enforce exact-public registry proof"

    result = Cleanroom.evaluate_public!(public_fixture())

    assert result.state == "COMPLETE"
    assert result.source_mode == "exact-public"
    assert result.path_lock_count == 0
    assert result.live_status == "PASS"
    assert result.succeeded_packages == @packages
    assert result.failed_packages == []
    assert Enum.map(result.profile_results, & &1.profile) == @profiles
  end

  @tag :post_publication
  test "exact-public proof reports partial registry availability without claiming completeness" do
    input =
      public_fixture()
      |> update_public_artifact("crosswake_threadline", fn artifact ->
        %{
          artifact
          | status: "MISSING",
            source: "unavailable",
            unpacked_root: nil,
            metadata_digest: nil,
            payload_digest: nil
        }
      end)
      |> Map.put(:installs, [])
      |> Map.put(:profile_results, [])
      |> Map.put(:live_status, "not_run")

    result = Cleanroom.evaluate_public!(input)

    assert result.state == "PARTIAL"
    assert result.succeeded_packages == Enum.drop(@packages, -1)

    assert result.failed_packages == [
             %{package: "crosswake_threadline", reason: "registry_missing"}
           ]

    assert result.profile_results == []
  end

  @tag :post_publication
  test "exact-public proof blocks path, cache, digest, lock-source, and live-status ambiguity" do
    input = public_fixture()

    mutations = [
      path_source:
        update_public_artifact(input, "crosswake", &Map.put(&1, :source, "repository_path")),
      cache_source: update_public_artifact(input, "crosswake", &Map.put(&1, :source, "cache")),
      digest_mismatch:
        update_public_artifact(
          input,
          "crosswake",
          &Map.put(&1, :payload_digest, String.duplicate("f", 64))
        ),
      path_lock: update_public_artifact(input, "crosswake", &Map.put(&1, :path_lock_count, 1)),
      live_ambiguous: %{input | live_status: "BLOCKED"}
    ]

    for {name, mutation} <- mutations do
      result = Cleanroom.evaluate_public!(mutation)
      assert result.state == "BLOCKED", "#{name} passed"
      refute result.state == "COMPLETE"
    end
  end

  @tag :post_publication
  test "post-publication adapter fetches exact packages and preapproval command cannot count it" do
    script = File.read!("script/verify_companion_cleanroom.sh")
    candidate_task = File.read!("lib/mix/tasks/crosswake.release.candidate.ex")

    assert script =~ "--approved-manifest"
    assert script =~ "mix hex.package fetch"
    assert script =~ "source_mode=exact-public"
    assert script =~ "crosswake.release.status --live"
    refute candidate_task =~ "verify_companion_cleanroom"
    refute candidate_task =~ "exact-public"
  end

  defp candidate_fixture do
    fixture_root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-cleanroom-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    source_root = Path.join(fixture_root, "candidate-payloads")
    scratch_root = Path.join(fixture_root, "scratch")
    File.mkdir_p!(source_root)
    File.mkdir_p!(scratch_root)
    on_exit(fn -> File.rm_rf!(fixture_root) end)

    artifacts =
      Enum.with_index(@packages, fn package, index ->
        root = Path.join(source_root, package)
        File.mkdir!(root)

        %{
          package: package,
          version: if(index == 0, do: "0.2.1", else: "0.1.#{index}"),
          source: "built_tarball",
          unpacked_root: root,
          metadata_digest: digest("metadata-#{package}"),
          payload_digest: digest("payload-#{package}")
        }
      end)

    installs =
      for profile <- @profiles, pass <- 1..2 do
        root = Path.join(scratch_root, "#{profile}-#{pass}")
        File.mkdir!(root)

        %{
          profile: profile,
          pass: pass,
          status: "PASS",
          scratch_root: root,
          path_lock_count: 0
        }
      end

    profile_results =
      Enum.map(@profiles, fn profile ->
        %{
          profile: profile,
          package: "crosswake_#{profile}",
          status: "PASS",
          passed_checks: expected_checks(profile),
          negative_control: "PASS"
        }
      end)

    %{
      source_mode: "candidate-local",
      generator_version: "1.8.13",
      repository_root: File.cwd!(),
      source_root: source_root,
      artifacts: artifacts,
      installs: installs,
      profile_results: profile_results,
      live_status: "not_applicable"
    }
  end

  defp public_fixture do
    candidate = candidate_fixture()
    public_root = Path.join(Path.dirname(candidate.source_root), "public-payloads")
    File.mkdir!(public_root)

    approved_artifacts =
      Enum.map(candidate.artifacts, fn artifact ->
        Map.take(artifact, [:package, :version, :metadata_digest, :payload_digest])
      end)

    public_artifacts =
      Enum.map(candidate.artifacts, fn artifact ->
        root = Path.join(public_root, artifact.package)
        File.mkdir!(root)

        artifact
        |> Map.put(:source, "hex_registry")
        |> Map.put(:unpacked_root, root)
        |> Map.put(:status, "PASS")
        |> Map.put(:path_lock_count, 0)
      end)

    %{
      source_mode: "exact-public",
      generator_version: "1.8.13",
      repository_root: candidate.repository_root,
      source_root: public_root,
      approved_artifacts: approved_artifacts,
      public_artifacts: public_artifacts,
      installs: candidate.installs,
      profile_results: candidate.profile_results,
      live_status: "PASS"
    }
  end

  defp expected_checks(profile) do
    common =
      ~w(generated_phoenix compile_warnings_as_errors runtime_config_loaded router_output public_smoke registration doctor)

    profile_checks = %{
      "rulestead" => ~w(engine_loaded dependency_validated),
      "rindle" => ~w(engine_loaded dependency_validated contracts_nonempty),
      "sigra" => ~w(auth_non_vacuous),
      "chimeway" => ~w(sigra_absent telemetry_events),
      "threadline" => ~w(observer_unregistered siblings_absent plug telemetry ledger templates)
    }

    common ++ Map.fetch!(profile_checks, profile)
  end

  defp shuffle_input(input) do
    %{
      input
      | artifacts: Enum.reverse(input.artifacts),
        installs: Enum.reverse(input.installs),
        profile_results: Enum.reverse(input.profile_results)
    }
  end

  defp update_artifact(input, package, callback) do
    update_in(input.artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end

  defp update_profile(input, profile, callback) do
    update_in(input.profile_results, fn profiles ->
      Enum.map(profiles, fn observation ->
        if observation.profile == profile, do: callback.(observation), else: observation
      end)
    end)
  end

  defp update_public_artifact(input, package, callback) do
    update_in(input.public_artifacts, fn artifacts ->
      Enum.map(artifacts, fn artifact ->
        if artifact.package == package, do: callback.(artifact), else: artifact
      end)
    end)
  end

  defp update_install(input, profile, pass, callback) do
    update_in(input.installs, fn installs ->
      Enum.map(installs, fn install ->
        if install.profile == profile and install.pass == pass,
          do: callback.(install),
          else: install
      end)
    end)
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
