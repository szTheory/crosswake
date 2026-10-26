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

  # REL-04: the Cancel Obsolete controller and its selector are gone. Names are built from
  # parts so this file does not itself match the absence grep.
  defp retired_controller, do: "cancel-obsolete" <> "-crosswake-ci"
  defp retired_selector, do: "select_obsolete" <> "_ci_runs"

  defp absent_references?(matches), do: matches == []

  test "the retired controller and selector files do not exist" do
    refute File.exists?(".github/workflows/#{retired_controller()}.yml")
    refute File.exists?("script/#{retired_selector()}.py")
  end

  test "no tracked file outside .planning and CHANGELOG.md names the controller or selector" do
    {out, status} =
      System.cmd(
        "git",
        [
          "grep",
          "-l",
          "-e",
          retired_controller(),
          "-e",
          retired_selector(),
          "--",
          ":!.planning",
          ":!CHANGELOG.md"
        ],
        stderr_to_stdout: true
      )

    assert status == 1, out
    assert out == ""
  end

  test "absence predicate rejects a non-empty match list (negative control)" do
    refute absent_references?(["script/x.sh"])
    assert absent_references?([])
  end

  # REL-04: See It Run web-and-gif completes on its own; native capture is a manual lane.
  defp job_block(text, job) do
    case Regex.run(~r/^  #{job}:\n((?:    .*\n|\n)*)/m, text) do
      [_, block] -> block
      _ -> ""
    end
  end

  defp collateral_ok?(text) do
    job_block(text, "web-and-gif") != "" and
      not (job_block(text, "web-and-gif") =~ ~r/^    needs:/m) and
      not (text =~ ~r/^\s+needs:.*native/m) and
      not (text =~ ~r/runs-on:\s*macos/)
  end

  defp collateral_text, do: File.read!(".github/workflows/see-it-run-collateral.yml")

  test "collateral run has independent web-and-gif and no native dependency" do
    assert collateral_ok?(collateral_text())
  end

  test "collateral predicate rejects needs on native (negative control)" do
    refute collateral_ok?(
             String.replace(
               collateral_text(),
               "needs: [web-and-gif]",
               "needs: [web-and-gif, native]"
             )
           )
  end

  test "the native capture is a dispatch-only, read-only workflow" do
    text = File.read!(".github/workflows/see-it-run-native.yml")
    assert text =~ "name: See It Run Native"
    assert on_block(text) =~ ~r/^  workflow_dispatch:/m
    refute on_block(text) =~ ~r/^  (push|pull_request|schedule):/m
    assert text =~ ~r/^  contents: read\s*$/m
    assert text =~ ~r/^  native:\n/m
    assert text =~ "group: see-it-run-native"
  end

  # REL-05: Dependabot groups actions monthly; the group covers version updates only.
  defp dependabot_ok?(text) do
    length(Regex.scan(~r/package-ecosystem:/, text)) == 1 and
      text =~ ~r/interval: "monthly"/ and
      text =~ ~r/applies-to: version-updates/ and
      text =~ ~r/- "\*"/ and
      not (text =~ "weekly")
  end

  defp dependabot_text, do: File.read!(".github/dependabot.yml")

  test "dependabot groups actions monthly, version updates only" do
    assert dependabot_ok?(dependabot_text())
  end

  test "dependabot predicate rejects a weekly interval (negative control)" do
    refute dependabot_ok?(String.replace(dependabot_text(), "monthly", "weekly"))
  end
end
