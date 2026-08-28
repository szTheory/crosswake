defmodule Crosswake.ProofLane.PhysicalIphoneEvidenceTransactionTest do
  use ExUnit.Case, async: true

  @script "script/retain_physical_iphone_evidence_transaction.sh"

  test "durable transaction script names a distinct Plan 16 ledger and exact provenance gates" do
    assert File.regular?(@script)
    source = File.read!(@script)

    assert source =~ "CROSSWAKE_TRANSACTION_TEST_GUARD"
    assert source =~ "EVIDENCE_PARENT=\"$(dirname \"$DEST\")\""
    assert source =~ "mkdir -p \"$EVIDENCE_PARENT\" || fail"
    assert source =~ "[ -L \"$EVIDENCE_PARENT\" ] && fail"
    assert source =~ "PARENT_REAL"
    assert source =~ "chore(162-16): consume corrected-provenance run"
    assert source =~ "feat(162-16): retain corrected physical iPhone evidence"
    assert source =~ "merge-base --is-ancestor b79bce8b HEAD"
    assert source =~ "merge-base --is-ancestor c11886b7 HEAD"
    assert source =~ "merge-base --is-ancestor e46f5136 HEAD"
    assert source =~ "jq -er '.commit_ref | sub(\"^git-\"; \"\")'"
    refute source =~ ".evidence.commit_ref"
    assert source =~ ~s("$DEST/proof-lane-evidence.json")
    assert source =~ "Evidence.scan_stage"
    assert source =~ "if CAPTURE_MODE=\"$(stat -f %Lp"
    assert source =~ "CAPTURE_MODE=\"$(stat -c %a"
    assert source =~ "rev-parse \"$LEDGER_COMMIT^\""
    assert source =~ "Evidence.check"
  end

  test "isolated transaction accepts promoted artifact provenance when passed run JSON omits optional evidence" do
    root =
      Path.join(System.tmp_dir!(), "crosswake-transaction-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(Path.join(root, "script"))
    File.cp!(@script, Path.join(root, @script))

    assert {_, 0} = System.cmd("git", ["init", "-q"], cd: root)
    assert {_, 0} = System.cmd("git", ["config", "user.email", "fixture@example.test"], cd: root)
    assert {_, 0} = System.cmd("git", ["config", "user.name", "Fixture"], cd: root)
    File.write!(Path.join(root, "baseline"), "fixture")
    assert {_, 0} = System.cmd("git", ["add", "baseline"], cd: root)

    assert {_, 0} =
             System.cmd(
               "git",
               [
                 "-c",
                 "user.email=fixture@example.test",
                 "-c",
                 "user.name=Fixture",
                 "commit",
                 "-qm",
                 "baseline"
               ], cd: root)

    {code_commit, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: root)
    code_commit = String.trim(code_commit)

    evidence_dir =
      Path.join(
        root,
        ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone"
      )

    File.mkdir_p!(Path.join(root, "fake"))
    write_fixture_commands!(root, evidence_dir, code_commit)

    {output, status} =
      System.cmd("bash", [@script],
        cd: root,
        env: [
          {"CROSSWAKE_PHYSICAL_IPHONE_HOST_BASE_URL", "http://127.0.0.1:4700"},
          {"CROSSWAKE_TRANSACTION_TEST_GUARD", "isolated-fixture"},
          {"CROSSWAKE_TRANSACTION_TEST_READY", Path.join(root, "fake/ready")},
          {"CROSSWAKE_TRANSACTION_TEST_RUN", Path.join(root, "fake/run")},
          {"CROSSWAKE_TRANSACTION_TEST_VERIFY", Path.join(root, "fake/verify")}
        ],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert {subject, 0} = System.cmd("git", ["show", "-s", "--format=%s", "HEAD"], cd: root)
    assert String.trim(subject) == "feat(162-16): retain corrected physical iPhone evidence"
    assert {parent, 0} = System.cmd("git", ["rev-parse", "HEAD^"], cd: root)
    assert {ledger_parent, 0} = System.cmd("git", ["rev-parse", "HEAD^^"], cd: root)
    assert String.trim(parent) != code_commit
    assert String.trim(ledger_parent) == code_commit
  end

  defp write_fixture_commands!(root, evidence_dir, code_commit) do
    File.write!(
      Path.join(root, "fake/ready"),
      "#!/usr/bin/env bash\nprintf '%s\\n' '{\"outcome\":\"ready\",\"checks\":[{\"state\":\"ready\"}]}'\n"
    )

    json =
      Jason.encode!(%{
        "commit_ref" => "git-#{code_commit}",
        "schema_version" => "1",
        "outcome" => "passed"
      })

    artifact = Path.join(root, "fake/artifact.json")
    File.write!(artifact, json)
    marker = Base.encode16(:crypto.hash(:sha256, json), case: :lower)

    File.write!(
      Path.join(root, "fake/run"),
      "#!/usr/bin/env bash\nset -euo pipefail\nmkdir -p #{shell_quote(evidence_dir)}\ncp #{shell_quote(artifact)} #{shell_quote(Path.join(evidence_dir, "proof-lane-evidence.json"))}\nprintf '%s' #{shell_quote(marker)} > #{shell_quote(Path.join(evidence_dir, ".complete"))}\nprintf '%s' '{\"outcome\":\"passed\",\"assertions\":[{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"},{\"outcome\":\"passed\"}]}'\nprintf '%s' fixture > \"$CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CAPTURE\"\nchmod 600 \"$CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CAPTURE\"\n"
    )

    File.write!(
      Path.join(root, "fake/verify"),
      "#!/usr/bin/env bash\nset -euo pipefail\ntest -f \"$1/proof-lane-evidence.json\"\ntest -f \"$1/.complete\"\n"
    )

    for command <- ~w(ready run verify) do
      File.chmod!(Path.join(root, "fake/#{command}"), 0o755)
    end
  end

  defp shell_quote(value), do: "'#{String.replace(value, "'", "'\\\"'\\\"'")}'"
end
