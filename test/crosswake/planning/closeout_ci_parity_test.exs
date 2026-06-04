defmodule Crosswake.Planning.CloseoutCIParityTest do
  use ExUnit.Case, async: true

  @workflow Path.join(File.cwd!(), ".github/workflows/phase69-proof.yml")

  test "phase 69 merge-blocking proof lane runs milestone closeout checks" do
    workflow = File.read!(@workflow)
    merge_blocking = job_section!(workflow, "merge-blocking-closeout-proof")

    assert merge_blocking =~ "mix compile --warnings-as-errors"
    assert merge_blocking =~ "mix closeout.verify --cwd . --closeout-path .planning/milestones/v4.0-CLOSEOUT.md"

    assert merge_blocking =~ "test/crosswake/proof/phase69_docs_contract_parity_test.exs"
    assert merge_blocking =~ "test/mix/tasks/closeout_verify_test.exs"
    refute merge_blocking =~ "continue-on-error: true"
  end

  defp job_section!(workflow, job_name) do
    pattern = ~r/^  #{Regex.escape(job_name)}:\r?\n(.*?)(?=^  [a-zA-Z0-9_-]+:\r?\n|\z)/ms

    case Regex.run(pattern, workflow, capture: :all_but_first) do
      [section] -> section
      nil -> flunk("missing workflow job #{job_name}")
    end
  end
end
