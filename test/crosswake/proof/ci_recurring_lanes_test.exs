defmodule Crosswake.Proof.CiRecurringLanesTest do
  @moduledoc """
  REL-04: CI runs only recurring lanes. The set of phase proof workflows that carry a
  `schedule:` trigger must be empty; the one advisory weekly canary owns the recurring run.
  The floor on matched files keeps an empty glob from scoring as success.
  """
  use ExUnit.Case, async: true

  defp on_block(text) do
    # The `on:` block runs from `on:` to the next top-level key.
    case Regex.run(~r/^on:\n((?:[ \t]+.*\n|\n)*)/m, text) do
      [_, block] -> block
      _ -> ""
    end
  end

  defp scheduled_phase_proofs(files) do
    files
    |> Enum.filter(fn {_name, text} -> on_block(text) =~ ~r/^  schedule:/m end)
    |> Enum.map(fn {name, _} -> name end)
    |> Enum.sort()
  end

  defp live_files do
    ".github/workflows/phase*-proof*.yml"
    |> Path.wildcard()
    |> Map.new(fn path -> {Path.basename(path), File.read!(path)} end)
  end

  test "predicate detects a scheduled fixture workflow (negative control)" do
    fixture = %{
      "phase1-proof.yml" => "on:\n  workflow_dispatch:\n  schedule:\n    - cron: \"0 6 * * 1\"\n"
    }

    assert scheduled_phase_proofs(fixture) == ["phase1-proof.yml"]
  end

  test "predicate ignores a dispatch-only workflow" do
    fixture = %{
      "phase2-proof.yml" => "on:\n  workflow_dispatch:\n\njobs:\n  a:\n    runs-on: x\n"
    }

    assert scheduled_phase_proofs(fixture) == []
  end

  test "no live phase proof workflow carries a schedule trigger" do
    live = live_files()
    assert map_size(live) >= 14, "matched only #{map_size(live)} phase proof workflows"
    assert scheduled_phase_proofs(live) == []
  end

  defp canary_ok?(text) do
    text =~ ~r/^\s+- cron: ['"]?\S+ \S+ \S+ \S+ [0-7*]['"]?\s*$/m and
      text =~ ~r/^  workflow_dispatch:/m and
      text =~ ~r/^\s+ref: main\s*$/m and
      text =~ ~r/^  contents: read\s*$/m and
      text =~ "script/verify_repository.sh --stage root-proof"
  end

  defp canary_text, do: File.read!(".github/workflows/weekly-canary.yml")

  test "the weekly canary is a read-only weekly root proof on main" do
    assert canary_ok?(canary_text())
    assert canary_text() =~ ~r/uses: actions\/checkout@[0-9a-f]{40} # v/
  end

  test "canary predicate rejects a canary that does not check out main (negative control)" do
    refute canary_ok?(String.replace(canary_text(), "ref: main", "ref: other"))
  end

  test "exactly one workflow is the weekly canary and it is not a required check" do
    named =
      ".github/workflows/*.yml"
      |> Path.wildcard()
      |> Enum.filter(&(File.read!(&1) =~ "name: Weekly Canary"))

    assert named == [".github/workflows/weekly-canary.yml"]
    refute File.read!("script/required_check_policy.json") =~ "Weekly Canary"
  end
end
