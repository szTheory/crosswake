defmodule Crosswake.Proof.CiRecurringLanesTest do
  @moduledoc """
  REL-04: CI runs only recurring lanes. The set of phase proof workflows that carry a
  `schedule:` trigger must equal exactly `@pending_schedule_removal`; plan 06 empties that list.
  The floor on matched files keeps an empty glob from scoring as success.
  """
  use ExUnit.Case, async: true

  # Phase 195 (REL-04): lanes still scheduled; emptied by plan 06
  @pending_schedule_removal [
    "phase34-proof.yml",
    "phase43-proof.yml",
    "phase45-proof.yml",
    "phase48-proof.yml",
    "phase52-proof.yml",
    "phase58-proof.yml",
    "phase130-proof.yml",
    "phase132-proof.yml",
    "phase70-proof.yml",
    "phase71-proof.yml",
    "phase73-proof.yml",
    "phase74-proof.yml",
    "phase96-proof-advisory.yml"
  ]

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
    fixture = %{"phase2-proof.yml" => "on:\n  workflow_dispatch:\n\njobs:\n  a:\n    runs-on: x\n"}
    assert scheduled_phase_proofs(fixture) == []
  end

  test "live scheduled phase proof lanes equal the pending removal list exactly" do
    live = live_files()
    assert map_size(live) >= 14, "matched only #{map_size(live)} phase proof workflows"
    assert scheduled_phase_proofs(live) == Enum.sort(@pending_schedule_removal)
  end
end
