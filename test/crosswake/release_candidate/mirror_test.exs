defmodule Crosswake.ReleaseCandidate.MirrorTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Mirror

  @baseline_sha String.duplicate("a", 40)
  @candidate_sha String.duplicate("b", 40)

  test "baseline accepts only the recorded credential-free 0.2.0 mirror truth" do
    assert Code.ensure_loaded?(Mirror),
           "Mirror.evaluate!/1 must enforce the four closed mirror modes"

    result = Mirror.evaluate!(baseline_fixture())

    assert result.state == "PASS"
    assert result.mode == "baseline"
    assert result.source_ref == "refs/tags/ios-core-v0.2.0"
    assert result.split_sha == @baseline_sha
    assert result.remote_main == @baseline_sha
    assert result.remote_tag == @baseline_sha
    assert result.authorization_checked == false
    assert result.authorization_result == "NOT CHECKED"
    assert result.dry_run_result == "NOT RUN"
    assert result.external_state_changed == false
    assert result.correction == "none"
  end

  test "baseline blocks absent, unreachable, replaced, conflicting, or credentialed observations" do
    input = baseline_fixture()

    mutations = [
      unreachable: put_in(input.remote.status, "UNREACHABLE"),
      absent_main: put_in(input.remote.main, nil),
      absent_tag: put_in(input.remote.tag, nil),
      replaced_main: put_in(input.remote.main, String.duplicate("c", 40)),
      conflicting_tag: put_in(input.remote.tag, String.duplicate("d", 40)),
      recorded_split_changed: %{input | recorded_split_sha: String.duplicate("e", 40)},
      credential_checked: put_in(input.authorization, %{checked: true, result: "PROVEN"}),
      changed: %{input | external_state_changed: true}
    ]

    for {name, mutation} <- mutations do
      result = Mirror.evaluate!(mutation)
      assert result.state == "BLOCKED", "#{name} passed"
      refute result.correction == "none"
    end

    assert Mirror.evaluate!(%{input | external_state_changed: true}).external_state_changed ==
             true
  end

  test "candidate proves exact 0.2.1 split, authorization, atomic porcelain, and no ref change" do
    result = Mirror.evaluate!(candidate_fixture())

    assert result.state == "PASS"
    assert result.mode == "candidate"
    assert result.source_ref == @candidate_sha
    assert result.split_sha == @candidate_sha
    assert result.atomic_supported == true
    assert result.authorization_checked == true
    assert result.authorization_result == "PROVEN"
    assert result.dry_run_result == "PASS"
    assert result.external_state_changed == false
    assert result.correction == "none"
  end

  test "candidate without credentials is honest and every denied, raced, or ambiguous observation blocks" do
    input = candidate_fixture()

    unchecked =
      input
      |> put_in([:authorization], %{checked: false, result: "NOT CHECKED"})
      |> put_in([:dry_run, :status], "NOT RUN")

    result = Mirror.evaluate!(unchecked)
    assert result.state == "BLOCKED"
    assert result.correction == "WRITE AUTHORITY NOT CHECKED"

    mutations = [
      wrong_version: %{input | version: "0.2.0"},
      short_ref: %{input | source_ref: String.duplicate("b", 39)},
      changed_split: %{input | split_sha: String.duplicate("c", 40)},
      unreachable: put_in(input.remote.status, "UNREACHABLE"),
      denied: put_in(input.authorization, %{checked: true, result: "DENIED"}),
      unsupported_atomic: %{input | atomic_supported: false},
      rejected_porcelain: put_in(input.dry_run.status, "REJECTED"),
      unparseable_porcelain: put_in(input.dry_run.status, "UNPARSEABLE"),
      raced_main: put_in(input.dry_run.after_main, String.duplicate("d", 40)),
      raced_tag: put_in(input.dry_run.after_tag, String.duplicate("e", 40)),
      changed: %{input | external_state_changed: true}
    ]

    for {name, mutation} <- mutations do
      result = Mirror.evaluate!(mutation)
      assert result.state == "BLOCKED", "#{name} passed"
      refute result.correction == "none"
    end

    assert Mirror.evaluate!(%{input | external_state_changed: true}).external_state_changed ==
             true
  end

  test "adapter exposes separate baseline and candidate modes with bounded output" do
    script = File.read!("script/release_candidate/ios_mirror.sh")
    wrapper = File.read!("script/verify_ios_mirror_backfill.sh")

    assert script =~ "baseline"
    assert script =~ "candidate"
    assert script =~ "subtree split"
    assert script =~ "--dry-run"
    assert script =~ "--porcelain"
    assert script =~ "--atomic"
    assert script =~ "WRITE AUTHORITY NOT CHECKED"
    assert wrapper =~ "release_candidate/ios_mirror.sh"

    for forbidden <- ["MIRROR_DEPLOY_KEY=", "ssh-private-key", "remote_url", "command_log"] do
      refute script =~ forbidden
    end
  end

  defp baseline_fixture do
    %{
      mode: "baseline",
      version: "0.2.0",
      source_ref: "refs/tags/ios-core-v0.2.0",
      split_sha: @baseline_sha,
      recorded_split_sha: @baseline_sha,
      remote: %{status: "PASS", main: @baseline_sha, tag: @baseline_sha},
      atomic_supported: false,
      authorization: %{checked: false, result: "NOT CHECKED"},
      dry_run: %{
        status: "NOT RUN",
        before_main: @baseline_sha,
        before_tag: @baseline_sha,
        after_main: @baseline_sha,
        after_tag: @baseline_sha
      },
      external_state_changed: false
    }
  end

  defp candidate_fixture do
    remote_main = String.duplicate("9", 40)

    %{
      mode: "candidate",
      version: "0.2.1",
      source_ref: @candidate_sha,
      split_sha: @candidate_sha,
      recorded_split_sha: @candidate_sha,
      remote: %{status: "PASS", main: remote_main, tag: nil},
      atomic_supported: true,
      authorization: %{checked: true, result: "PROVEN"},
      dry_run: %{
        status: "PASS",
        before_main: remote_main,
        before_tag: nil,
        after_main: remote_main,
        after_tag: nil
      },
      external_state_changed: false
    }
  end
end
