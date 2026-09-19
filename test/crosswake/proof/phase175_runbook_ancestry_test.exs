defmodule Crosswake.Proof.Phase175RunbookAncestryTest do
  use ExUnit.Case, async: true

  @script Path.expand("script/check_release_runbook_ancestry.sh")
  @runbook_path "docs/RELEASE-INCIDENT-RESPONSE.md"

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-runbook-ancestry-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    git!(root, ["init", "-q"])
    git!(root, ["config", "user.email", "fixture@example.test"])
    git!(root, ["config", "user.name", "Fixture"])

    File.write!(Path.join(root, "baseline"), "baseline\n")
    git!(root, ["add", "baseline"])
    git!(root, ["commit", "-qm", "baseline"])
    base = git!(root, ["rev-parse", "HEAD"])
    local_branch = git!(root, ["branch", "--show-current"])

    File.mkdir_p!(Path.join(root, "docs"))
    File.write!(Path.join(root, @runbook_path), "incident response\n")
    git!(root, ["add", @runbook_path])
    git!(root, ["commit", "-qm", "add incident runbook"])
    runbook = git!(root, ["rev-parse", "HEAD"])

    git!(root, ["checkout", "-qb", "remote-main", base])
    File.write!(Path.join(root, "release"), "publish trigger\n")
    git!(root, ["add", "release"])
    git!(root, ["commit", "-qm", "remote release target"])
    remote_target = git!(root, ["rev-parse", "HEAD"])
    git!(root, ["checkout", "-q", local_branch])

    %{root: root, runbook: runbook, remote_target: remote_target}
  end

  test "an exact divergent remote target fails even though the old local HEAD check passes", %{
    root: root,
    runbook: runbook,
    remote_target: remote_target
  } do
    assert {_, 0} =
             System.cmd("git", ["merge-base", "--is-ancestor", runbook, "HEAD"], cd: root)

    assert {output, 1} = run_guard(root, runbook, remote_target)
    assert output =~ "RUNBOOK_NOT_ANCESTOR"
    assert output =~ "target=#{remote_target}"
  end

  test "an exact target containing the runbook passes", %{root: root, runbook: runbook} do
    assert {output, 0} = run_guard(root, runbook, runbook)
    assert output =~ "status=pass"
    assert output =~ "runbook=#{runbook}"
    assert output =~ "target=#{runbook}"
  end

  test "symbolic targets are rejected instead of silently binding to local checkout state", %{
    root: root,
    runbook: runbook
  } do
    assert {output, 2} = run_guard(root, runbook, "HEAD")
    assert output =~ "TARGET_OID_INVALID"
  end

  test "an ancestor does not pass when the target deleted the runbook path", %{
    root: root,
    runbook: runbook
  } do
    File.rm!(Path.join(root, @runbook_path))
    git!(root, ["add", @runbook_path])
    git!(root, ["commit", "-qm", "delete incident runbook"])
    target = git!(root, ["rev-parse", "HEAD"])

    assert {output, 1} = run_guard(root, runbook, target)
    assert output =~ "RUNBOOK_PATH_MISSING_FROM_TARGET"
  end

  test "remaining one-way gates bind the helper to live remote object identities" do
    for plan <- [
          ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-07-PLAN.md",
          ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-08-PLAN.md",
          ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-10-PLAN.md"
        ] do
      contents = File.read!(plan)

      assert contents =~ "script/check_release_runbook_ancestry.sh"
      assert contents =~ "baseRefOid"
      assert contents =~ "headRefOid"
      assert contents =~ "mergeCommit.oid"

      refute contents =~
               ~r/<automated>[^<]*git merge-base --is-ancestor[^<]*HEAD[^<]*<\/automated>/
    end

    record =
      File.read!(
        ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md"
      )

    assert record =~ "historically noncompliant"
    assert record =~ "script/check_release_runbook_ancestry.sh"
    assert record =~ "Symbolic local `HEAD` is not a valid target"
  end

  defp run_guard(root, runbook, target) do
    script = System.get_env("CROSSWAKE_RUNBOOK_ANCESTRY_SCRIPT", @script)

    System.cmd("bash", [script, runbook, target],
      cd: root,
      env: [{"CROSSWAKE_RELEASE_REPO", root}],
      stderr_to_stdout: true
    )
  end

  defp git!(root, args) do
    case System.cmd("git", args, cd: root, stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      {output, status} -> flunk("git #{Enum.join(args, " ")} failed (#{status}): #{output}")
    end
  end
end
