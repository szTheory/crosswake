defmodule Mix.Tasks.Crosswake.Release.StatusTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @governance_check_codes ~w(
    release.governance_queue_max
    release.governance_behavioral_identity_gates
    release.governance_cleanup_after_proof
  )
  @forbidden_public_ids ~w(PREF-01 MIRR-01 STAT-01)
  @stale_phrase Enum.join(["PREF validation remains", "Phase 144"], " ")

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

  test "live probes distinguish ok, missing, and unavailable as advisory warnings" do
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

    assert status.status == :warning
    assert status.live_checked == true

    assert %{live: %{status: :ok, source: "hex"}} =
             Enum.find(status.core, &(&1.component == "hex"))

    assert %{live: %{status: :missing, source: "ios_mirror", ref: "refs/tags/v0.2.0"}} =
             Enum.find(status.core, &(&1.component == "ios-core"))

    assert %{live: %{status: :missing, source: "maven"}} =
             Enum.find(status.core, &(&1.component == "android-core"))

    assert %{live: %{status: :unavailable, source: "hex"}} =
             Enum.find(status.companions, &(&1.package == "crosswake_sigra"))

    assert %{status: :warning, next_action: next_action, evidence: evidence, message: message} =
             check!(status, "release.live_registry_presence")

    assert next_action =~ "mix crosswake.release.status --live"
    assert "android-core@0.2.0=missing" in evidence
    assert message =~ "ios-core@0.2.0 missing on ios_mirror"
    assert message =~ "crosswake_sigra@0.1.1 unavailable on hex"

    for check <- status.checks, check.status != :ok do
      assert is_binary(check.next_action)
      assert check.next_action != ""
    end
  end

  test "release status source stays read-only and avoids mutation commands" do
    source = File.read!("lib/crosswake/release_status.ex")
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
  end

  defp check!(status, code) do
    Enum.find(status.checks, &(&1.code == code)) || flunk("missing check #{code}")
  end

  defp assert_required_fields(map, keys) do
    assert MapSet.subset?(MapSet.new(keys), MapSet.new(Map.keys(map)))
  end
end
