defmodule Crosswake.Proof.Phase174CleanRoomHostRealismTest do
  @moduledoc """
  Non-vacuity proof for Phase 174 Task 2 (Clean-Room Host Realism & Adopter Fidelity).

  Task 1 taught the legacy positional clean-room path (`script/verify_companion_cleanroom.sh`)
  to emit one `step=<name>` marker per stage, at the same granularity the matrix path already
  emits (ROOM-04), and to run `mix crosswake.install` before `mix crosswake.doctor` (ROOM-02)
  against a host whose router carries a real Crosswake route (ROOM-01).

  This module asserts the nine-marker roster against the real run's committed evidence log —
  `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-legacy-rindle-local-run.log`
  — from a roster declared LITERALLY in this file, never parsed out of the script under test.
  Deriving the roster from `script/verify_companion_cleanroom.sh` itself would silently shrink
  to whatever the script happens to emit — the scope-selector defect recorded as SEED-019 — and
  this check would then pass by construction for every marker the script forgot.

  Every assertion here is paired with a demonstrated non-vacuity control per this milestone's
  absence-scored-as-success rule
  (`.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`): a one-marker-
  removed fixture and an empty-log fixture must both go RED, and both are exercised below.
  """

  use ExUnit.Case, async: true

  @script "script/verify_companion_cleanroom.sh"

  @evidence_log ".planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-legacy-rindle-local-run.log"

  # The nine-name marker roster, declared literally and independently of the script under
  # test. This list's length is itself asserted below so a future edit that empties it cannot
  # make the roster check vacuous (Task 2's "roster length exactly nine" requirement).
  @markers ~w(metadata generate deps compile router smoke register install doctor)

  describe "the roster itself is a real, non-empty, nine-member declaration" do
    test "the declared marker roster has exactly nine entries" do
      assert length(@markers) == 9,
             "expected the literal marker roster to have exactly nine entries, got #{length(@markers)}: #{inspect(@markers)}"
    end

    test "no assertion in this file derives the roster by grepping the script under test" do
      # This is a source-level guard on THIS file's own text, not on the script — it exists so
      # a future edit cannot quietly reintroduce a script-derived roster without a rename.
      source = File.read!(__ENV__.file)

      refute source =~ ~r/Regex\.scan\(~r\/step=.*@script/,
             "the marker roster must stay a literal list in this file, never parsed from #{@script}"
    end
  end

  describe "the committed evidence log carries every declared marker (ROOM-04)" do
    test "every one of the nine declared markers is found at least once in the real run's log" do
      lines = log_lines!(@evidence_log)

      assert {:ok, _first_seen} = check_markers(lines)
    end

    test "the install marker's first occurrence precedes the doctor marker's first occurrence" do
      lines = log_lines!(@evidence_log)

      assert {:ok, first_seen} = check_markers(lines)

      assert first_seen["install"] < first_seen["doctor"],
             "expected step=install (line #{first_seen["install"]}) to precede " <>
               "step=doctor (line #{first_seen["doctor"]}) in #{@evidence_log}"
    end

    test "reading the committed evidence log by a repository-relative path fails with a named message if absent" do
      bogus_path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase174-missing-log-#{System.unique_integer([:positive])}.log"
        )

      refute File.exists?(bogus_path)

      assert_raise RuntimeError, ~r/evidence log not found at #{Regex.escape(bogus_path)}/, fn ->
        log_lines!(bogus_path)
      end
    end
  end

  describe "non-vacuity control (D-14): a mutated copy of the real log must go RED" do
    test "deleting the install marker's lines from a copy of the real log fails and names 'install'" do
      lines = log_lines!(@evidence_log)
      mutated = Enum.reject(lines, &String.contains?(&1, "step=install"))

      assert {:error, missing} = check_markers(mutated)

      assert missing == ["install"],
             "expected only 'install' to be reported missing, got: #{inspect(missing)}"
    end

    test "an empty log fails rather than passing over an empty collection" do
      assert {:error, missing} = check_markers([])

      assert missing == @markers,
             "expected every declared marker to be reported missing against an empty log, got: #{inspect(missing)}"
    end
  end

  describe "granularity parity with the matrix path (ROADMAP SC#4)" do
    test "the legacy roster's cardinality is >= the matrix path's distinct step= marker count" do
      matrix_source = matrix_region_source!()

      matrix_markers =
        ~r/step=([a-zA-Z_-]+)/
        |> Regex.scan(matrix_source)
        |> Enum.map(fn [_, name] -> name end)
        |> Enum.uniq()

      assert matrix_markers != [],
             "expected to find at least one step= marker in the matrix path region of #{@script}"

      assert length(@markers) >= length(matrix_markers),
             "expected the legacy roster (#{length(@markers)} markers: #{inspect(@markers)}) to be " <>
               "at least as fine-grained as the matrix path's distinct markers " <>
               "(#{length(matrix_markers)}: #{inspect(matrix_markers)})"
    end
  end

  # --- fixture / source-reading helpers --------------------------------------

  # Reads the log at `path` into a list of lines, raising a message that names the path when
  # absent — absence is never treated as a pass by any caller of this helper.
  defp log_lines!(path) do
    case File.read(path) do
      {:ok, contents} -> String.split(contents, "\n")
      {:error, _reason} -> raise "evidence log not found at #{path}"
    end
  end

  # Returns {:ok, first_seen} when every roster entry is found at least once (first_seen maps
  # marker name -> 1-indexed line number of its first occurrence), or {:error, missing} naming
  # every roster entry absent from `lines`. An empty `lines` list is never treated as a pass —
  # it simply reports every roster entry as missing.
  defp check_markers(lines) do
    first_seen =
      lines
      |> Enum.with_index(1)
      |> Enum.reduce(%{}, fn {line, index}, acc ->
        case Regex.run(~r/step=([a-zA-Z_-]+)/, line) do
          [_, marker] -> Map.put_new(acc, marker, index)
          nil -> acc
        end
      end)

    missing = Enum.reject(@markers, &Map.has_key?(first_seen, &1))

    if missing == [] do
      {:ok, first_seen}
    else
      {:error, missing}
    end
  end

  # Strips full-line `#` comments before any grep-hygiene assertion, so a comment mentioning a
  # step= marker can never make a live-code assertion pass or fail spuriously.
  defp non_comment_source!(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.reject(&(&1 |> String.trim() |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  # The matrix path region runs from the top of the file through the line immediately before
  # the legacy positional section's SCRIPT_DIR= assignment — the exact boundary Task 1's scope
  # boundary names ("everything from the SCRIPT_DIR= assignment onward, Steps 1 through 7").
  # Split on the live code, not the "# Parameters (D-16)" comment above it, since
  # non_comment_source!/1 strips full-line comments before this split ever runs.
  defp matrix_region_source! do
    source = non_comment_source!(@script)

    case String.split(source, "\nSCRIPT_DIR=", parts: 2) do
      [matrix_region, _legacy_region] ->
        matrix_region

      _other ->
        flunk(
          "could not locate the SCRIPT_DIR= boundary marking the end of the matrix path " <>
            "region in #{@script}"
        )
    end
  end
end
