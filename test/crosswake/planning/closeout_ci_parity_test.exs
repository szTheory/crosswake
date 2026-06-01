defmodule Crosswake.Planning.CloseoutCIParityTest do
  use ExUnit.Case, async: true

  @workflow Path.join(File.cwd!(), ".github/workflows/phase52-proof.yml")

  test "merge-blocking proof lane runs mix closeout.verify" do
    workflow = File.read!(@workflow)
    merge_blocking = job_section!(workflow, "merge-blocking-operator-proof")

    assert merge_blocking =~ "Run milestone closeout verification"
    assert merge_blocking =~ "mix closeout.verify"
    assert merge_blocking =~ "Run hermetic Phase 52 operator proof"
  end

  test "advisory operator proof remains non-blocking and non-promotional" do
    workflow = File.read!(@workflow)
    advisory = job_section!(workflow, "advisory-operator-proof")

    assert advisory =~ "continue-on-error: true"
    assert advisory =~ "StoreKit or Play Billing adapters"
    assert advisory =~ "Chimeway delivery support"
    assert advisory =~ "full Sigra machinery"
    assert advisory =~ "standalone public shell packages"
    refute advisory =~ "mix closeout.verify"
  end

  defp job_section!(workflow, job_name) do
    pattern = ~r/^  #{Regex.escape(job_name)}:\r?\n(.*?)(?=^  [a-zA-Z0-9_-]+:\r?\n|\z)/ms

    case Regex.run(pattern, workflow, capture: :all_but_first) do
      [section] -> section
      nil -> flunk("missing workflow job #{job_name}")
    end
  end
end
