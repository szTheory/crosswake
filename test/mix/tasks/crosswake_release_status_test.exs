defmodule Mix.Tasks.Crosswake.Release.StatusTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @governance_check_codes ~w(
    release.governance_queue_max
    release.governance_behavioral_identity_gates
    release.governance_cleanup_after_proof
  )
  @forbidden_public_ids ~w(PREF-01 MIRR-01 STAT-01)
  @stale_phrase Enum.join(["PREF validation", "remains", "Phase 144"], " ")
  @stale_companion_deferred Enum.join(
                              [
                                "companion extraction",
                                "and broad native runtime expansion are not shipped"
                              ],
                              ", "
                            )
  @stale_companion_version Enum.join(["publish separately at", "their own `0.1.0`"], " ")

  test "release status reports local graph and scanner-backed guard checks" do
    status = Crosswake.ReleaseStatus.build()

    assert status.schema_version == "1.0.0"
    assert status.status == :ok
    assert Enum.any?(status.core, &(&1.component == "hex"))
    assert Enum.any?(status.companions, &(&1.package == "crosswake_sigra"))
    assert Enum.any?(status.checks, &(&1.code == "release.workflow_path_gates"))

    assert %{status: :ok, source: "script/check_release_workflow_integrity.exs"} =
             cleanroom = check!(status, "release.cleanroom_dependency_floor")

    assert cleanroom.message =~ "Hex metadata floors"
    assert "release.cleanroom.hex_metadata_floor" in cleanroom.evidence
    assert "release.cleanroom.exact_companion_pin" in cleanroom.evidence
    refute cleanroom.message =~ @stale_phrase

    for code <- @governance_check_codes do
      assert %{status: :ok, source: "script/check_release_workflow_integrity.exs"} =
               check!(status, code)
    end
  end

  test "scanner failure outside scoped evidence IDs fails the status surface" do
    baseline = Crosswake.ReleaseStatus.build()

    checks =
      baseline.checks
      |> Enum.filter(&(&1.source == "script/check_release_workflow_integrity.exs"))
      |> Enum.flat_map(& &1.evidence)
      |> Enum.uniq()
      |> Map.new(&{&1, %{status: :ok, detail: "fixture ok"}})
      |> Map.put("release.unscoped.regression", %{status: :error, detail: "fixture failure"})

    status =
      Crosswake.ReleaseStatus.build(
        workflow_integrity: %{
          status: :failed,
          checks: checks,
          message: "scanner reported release workflow drift"
        }
      )

    assert status.status == :error

    assert %{status: :error, evidence: evidence, message: message, next_action: next_action} =
             check!(status, "release.workflow_path_gates")

    assert "release.unscoped.regression" in evidence
    assert message =~ "failing scanner IDs: release.unscoped.regression"
    assert next_action == "elixir script/check_release_workflow_integrity.exs"
  end

  test "human task output names package-family release posture without stale phase copy" do
    output =
      capture_io(fn ->
        Mix.Task.clear()
        Mix.Tasks.Crosswake.Release.Status.run([])
      end)

    assert output =~ "Crosswake release status"
    assert output =~ "Core/native lockstep"
    assert output =~ "Companions"
    assert output =~ "Checks:"
    assert output =~ "release.workflow_path_gates"
    assert output =~ "clean-room proof uses Hex metadata floors and exact companion pins"
    assert output =~ "release-as pin"
    refute output =~ @stale_phrase

    for code <- @governance_check_codes do
      assert output =~ code
    end

    for requirement_id <- @forbidden_public_ids do
      refute output =~ requirement_id
    end
  end

  test "json task output is a stable automation contract" do
    output =
      capture_io(fn ->
        Mix.Task.clear()
        Mix.Tasks.Crosswake.Release.Status.run(["--json"])
      end)

    assert output |> String.trim_leading() |> String.starts_with?("{")
    refute output =~ "Crosswake release status"

    decoded = Jason.decode!(output)

    assert Map.keys(decoded) |> Enum.sort() ==
             ~w(checks companions core generated_at live_checked schema_version status)

    assert decoded["schema_version"] == "1.0.0"
    assert decoded["status"] == "ok"
    assert decoded["live_checked"] == false

    assert_required_fields(hd(decoded["core"]), ~w(
      component configured_version kind live manifest_version name path
    ))

    assert_required_fields(hd(decoded["companions"]), ~w(
      configured_version core_requirement kind live manifest_version name package path
      release_as release_as_tag_exists version
    ))

    for check <- decoded["checks"] do
      assert_required_fields(check, ~w(code message next_action source status))
    end

    assert Enum.any?(decoded["checks"], &(&1["code"] == "release.release_as_staleness"))

    for code <- @governance_check_codes do
      assert Enum.any?(decoded["checks"], &(&1["code"] == code))
    end

    encoded = Jason.encode!(decoded)
    refute encoded =~ @stale_phrase

    for requirement_id <- @forbidden_public_ids do
      refute encoded =~ requirement_id
    end
  end

  test "exit behavior is non-fatal for ok and warning, fatal for error, and strict for args" do
    assert Crosswake.ReleaseStatus.aggregate_status([%{status: :ok}, %{status: :warning}]) ==
             :warning

    assert Crosswake.ReleaseStatus.aggregate_status([%{status: :warning}, %{status: :error}]) ==
             :error

    assert Crosswake.ReleaseStatus.exit_code(:ok) == 0
    assert Crosswake.ReleaseStatus.exit_code(:warning) == 0
    assert Crosswake.ReleaseStatus.exit_code(:error) == 1

    assert_raise Mix.Error, fn ->
      Mix.Task.clear()
      Mix.Tasks.Crosswake.Release.Status.run(["--bogus"])
    end
  end

  # D-18: a missing mirror tag used to surface as :warning, so
  # `mix crosswake.release.status --live` exited 0 while every iOS adopter's
  # `.package(from: "0.2.0")` could not resolve. Both failure kinds are now
  # fatal, but they are reported under DISTINCT codes: a registry that answered
  # "no such release" is a definite negative; a probe that never got an answer
  # is an unknown. Fail closed on both, but never misreport which one happened.
  test "live probes split definite absence from unverifiable, and both fail closed (D-18)" do
    status =
      Crosswake.ReleaseStatus.build(
        live?: true,
        http_probe: fn _url, context ->
          case context do
            %{kind: :hex, package: "crosswake"} -> %{status: :ok, evidence: ["hex fixture"]}
            %{kind: :maven} -> %{status: :missing, evidence: ["maven fixture"]}
            %{kind: :hex} -> %{status: :unavailable, evidence: ["hex unavailable fixture"]}
          end
        end,
        git_ref_probe: fn _remote, _ref -> %{status: :missing, evidence: ["ios fixture"]} end
      )

    assert status.status == :error
    assert status.live_checked == true

    assert %{live: %{status: :ok, source: "hex"}} =
             Enum.find(status.core, &(&1.component == "hex"))

    assert %{live: %{status: :missing, source: "ios_mirror", ref: "refs/tags/v0.2.0"}} =
             Enum.find(status.core, &(&1.component == "ios-core"))

    assert %{live: %{status: :missing, source: "maven"}} =
             Enum.find(status.core, &(&1.component == "android-core"))

    assert %{live: %{status: :unavailable, source: "hex"}} =
             Enum.find(status.companions, &(&1.package == "crosswake_sigra"))

    # Definite negatives: the registry answered, the release is not there.
    assert %{
             status: :error,
             next_action: presence_next,
             evidence: presence_evidence,
             message: presence_message
           } = presence = check!(status, "release.live_registry_presence")

    assert presence_next =~ "mix crosswake.release.status --live"
    assert "android-core@0.2.0=missing" in presence_evidence
    assert presence_message =~ "ios-core@0.2.0 missing on ios_mirror"
    assert presence_message =~ "found no release"
    # A source we merely could not reach must NOT be named as a confirmed absence.
    refute presence_message =~ "crosswake_sigra"
    refute Enum.any?(presence_evidence, &String.starts_with?(&1, "crosswake_sigra"))

    # Unknowns: the probe itself failed after retries. Still fatal, differently named.
    assert %{
             status: :error,
             next_action: unverifiable_next,
             evidence: unverifiable_evidence,
             message: unverifiable_message
           } = unverifiable = check!(status, "release.live_registry_unverifiable")

    assert unverifiable_next =~ "mix crosswake.release.status --live"
    assert unverifiable_message =~ "crosswake_sigra@0.1.1 unavailable on hex"
    assert unverifiable_message =~ "probe failure"
    refute unverifiable_message =~ "ios-core"
    refute unverifiable_message =~ "android-core"
    assert Enum.any?(unverifiable_evidence, &String.starts_with?(&1, "crosswake_sigra"))

    # Both exit 1 — fail closed on unknowns as well as on definite negatives.
    assert Crosswake.ReleaseStatus.exit_code(presence) == 1
    assert Crosswake.ReleaseStatus.exit_code(unverifiable) == 1
    assert Crosswake.ReleaseStatus.exit_code(status) == 1

    for check <- status.checks, check.status != :ok do
      assert is_binary(check.next_action)
      assert check.next_action != ""
    end
  end

  test "all-ok live probes produce one ok presence check, no unverifiable check, and exit 0" do
    status =
      Crosswake.ReleaseStatus.build(
        live?: true,
        http_probe: fn _url, _context -> %{status: :ok, evidence: ["ok fixture"]} end,
        git_ref_probe: fn _remote, _ref -> %{status: :ok, evidence: ["ok fixture"]} end
      )

    assert status.status == :ok

    assert %{status: :ok, next_action: nil, message: message} =
             check!(status, "release.live_registry_presence")

    assert message =~ "all live registry probes found manifest versions"
    refute Enum.any?(status.checks, &(&1.code == "release.live_registry_unverifiable"))
    assert Crosswake.ReleaseStatus.exit_code(status) == 0
  end

  test "injected probes are called exactly once — retries live on the real probes, not the seam" do
    counter = :counters.new(1, [])

    status =
      Crosswake.ReleaseStatus.build(
        live?: true,
        http_probe: fn _url, _context ->
          :counters.add(counter, 1, 1)
          %{status: :unavailable, evidence: ["fixture"]}
        end,
        git_ref_probe: fn _remote, _ref ->
          :counters.add(counter, 1, 1)
          %{status: :unavailable, evidence: ["fixture"]}
        end
      )

    live_entries = Enum.count(status.core ++ status.companions, & &1.live)

    assert live_entries > 0
    assert :counters.get(counter, 1) == live_entries
  end

  test "a probe that fails twice and then answers is NOT unavailable (retry short-circuits)" do
    counter = :counters.new(1, [])

    result =
      Crosswake.ReleaseStatus.probe_with_retry(
        fn ->
          attempt = :counters.get(counter, 1) + 1
          :counters.add(counter, 1, 1)

          if attempt < 3 do
            %{status: :unavailable, evidence: ["flake #{attempt}"]}
          else
            %{status: :missing, evidence: ["registry answered: no such release"]}
          end
        end,
        3,
        0
      )

    assert result.status == :missing
    assert :counters.get(counter, 1) == 3
  end

  test "a probe is classified unavailable only after all 3 attempts fail" do
    counter = :counters.new(1, [])

    result =
      Crosswake.ReleaseStatus.probe_with_retry(
        fn ->
          :counters.add(counter, 1, 1)
          %{status: :unavailable, evidence: ["network down"]}
        end,
        3,
        0
      )

    assert result.status == :unavailable
    assert :counters.get(counter, 1) == 3
  end

  test "a probe that answers on the first attempt is called exactly once" do
    counter = :counters.new(1, [])

    result =
      Crosswake.ReleaseStatus.probe_with_retry(
        fn ->
          :counters.add(counter, 1, 1)
          %{status: :ok, evidence: ["first try"]}
        end,
        3,
        0
      )

    assert result.status == :ok
    assert :counters.get(counter, 1) == 1
  end

  test "the real probes are the ones wrapped in retry, not the injection seam" do
    source = File.read!("lib/crosswake/release_status.ex")

    assert source =~ "probe_with_retry(fn -> git_ref_live_probe_once("
    assert source =~ "probe_with_retry(fn -> http_live_probe_once("
    # The seam build/1 exposes must keep pointing at the retrying wrappers.
    assert source =~ "Keyword.get(opts, :http_probe, &http_live_probe/2)"
    assert source =~ "Keyword.get(opts, :git_ref_probe, &git_ref_live_probe/2)"
  end

  test "release status source stays read-only and avoids mutation commands" do
    source = File.read!("lib/crosswake/release_status.ex")
    changelog = File.read!("CHANGELOG.md")
    rendered = Crosswake.ReleaseStatus.build() |> Crosswake.ReleaseStatus.render()
    json = Crosswake.ReleaseStatus.build() |> Jason.encode!()

    for text <- [source, rendered, json] do
      refute text =~ @stale_phrase
    end

    refute source =~ "hex.publish"
    refute source =~ "git push"
    refute source =~ "--apply"
    refute source =~ "gh pr"
    refute source =~ "gh issue"
    refute changelog =~ @stale_companion_deferred
    refute changelog =~ @stale_companion_version
  end

  defp check!(status, code) do
    Enum.find(status.checks, &(&1.code == code)) || flunk("missing check #{code}")
  end

  defp assert_required_fields(map, keys) do
    assert MapSet.subset?(MapSet.new(keys), MapSet.new(Map.keys(map)))
  end
end
