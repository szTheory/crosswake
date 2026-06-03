defmodule Crosswake.Planning.CloseoutCIParityTest do
  use ExUnit.Case, async: true

  @workflow Path.join(File.cwd!(), ".github/workflows/phase58-proof.yml")

  test "phase 58 merge-blocking proof lane runs hermetic auth closeout checks" do
    workflow = File.read!(@workflow)
    merge_blocking = job_section!(workflow, "merge-blocking-auth-closeout-proof")

    assert merge_blocking =~ "mix compile --warnings-as-errors"

    assert merge_blocking =~
             "mix closeout.verify --security-only --security-closeout .planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md"

    assert merge_blocking =~ "test/crosswake/proof/phase54_sigra_session_authority_test.exs"
    assert merge_blocking =~ "test/crosswake/proof/phase55_session_handoff_tickets_test.exs"
    assert merge_blocking =~ "test/crosswake/proof/phase56_step_up_ceremony_test.exs"
    assert merge_blocking =~ "test/crosswake/proof/phase57_auth_return_boundaries_test.exs"
    assert merge_blocking =~ "test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs"
    assert merge_blocking =~ "test/crosswake/companions/sigra/telemetry_test.exs"
    assert merge_blocking =~ "test/mix/tasks/closeout_verify_test.exs"
    refute merge_blocking =~ "continue-on-error: true"
  end

  test "phase 58 advisory provider device proof remains non-blocking and non-promotional" do
    workflow = File.read!(@workflow)
    advisory = job_section!(workflow, "advisory-auth-provider-device-proof")

    assert advisory =~ "continue-on-error: true"
    assert advisory =~ "Provider/device OAuth"
    assert advisory =~ "passkey"
    assert advisory =~ "verified-link"
    assert advisory =~ "native auth UI"
    assert advisory =~ "refresh-token"
    assert advisory =~ "shell/WebView token-authority proof"
    assert advisory =~ "not merge-blocking support claims"
    refute advisory =~ "mix closeout.verify"
  end

  test "phase 58 workflow keeps advisory lane off pull request and push triggers" do
    workflow = File.read!(@workflow)
    advisory = job_section!(workflow, "advisory-auth-provider-device-proof")

    assert advisory =~ "github.event_name == 'schedule'"
    assert advisory =~ "workflow_dispatch"
    refute advisory =~ "github.event_name == 'pull_request'"
    refute advisory =~ "github.event_name == 'push'"
  end

  defp job_section!(workflow, job_name) do
    pattern = ~r/^  #{Regex.escape(job_name)}:\r?\n(.*?)(?=^  [a-zA-Z0-9_-]+:\r?\n|\z)/ms

    case Regex.run(pattern, workflow, capture: :all_but_first) do
      [section] -> section
      nil -> flunk("missing workflow job #{job_name}")
    end
  end
end
