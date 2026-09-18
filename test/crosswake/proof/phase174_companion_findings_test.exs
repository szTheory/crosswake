defmodule Crosswake.Proof.Phase174CompanionFindingsTest do
  @moduledoc """
  Non-vacuity proof for Phase 174 Plan 5 (ROOM-05): the threadline and sigra clean-room failures
  must each have their own separately recorded root-cause finding, and that requirement must be
  checked mechanically against a roster that cannot silently shrink to "whatever findings exist".

  The roster is discovered from `TODO-011`'s dated failure table — an independent source, never
  from `Dir.ls!/1` on the findings directory. Deriving the roster from the findings directory
  would be the exact scope-selector defect this project names as its central failure mode
  (`.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`,
  `SEED-019`-style absence-scored-as-success): a roster read out of the thing it polices can
  never detect that thing's own omission, because a missing finding excludes its own companion
  from the roster before the check ever looks for it.

  TODO-011's table has three rows: threadline, sigra, and rindle. Rindle is EXCLUDED from the
  roster this check requires findings for, not because it is hardcoded away, but because
  TODO-011 diagnoses rindle's root cause in its own body (the `## Root cause of the rindle
  failure` section) while stating explicitly that "the threadline and sigra failures above are
  separate causes and must be diagnosed on their own." The exclusion rule is therefore derived
  from TODO-011's own structure — a section heading naming a companion's root cause — so a future
  companion TODO-011 diagnoses inline drops out of the roster by the same rule, and a future
  undiagnosed row enters it automatically.

  Per this milestone's rule, the non-emptiness of the discovered (pre-filter) roster is asserted
  BEFORE the filtered-roster equality check, and the equality check is demonstrated to go RED
  against a fixture with one finding file removed (D-14 style non-vacuity control).
  """

  use ExUnit.Case, async: true

  @todo011 ".planning/todos/TODO-011-companion-cleanroom-lane-has-never-been-green.md"
  @phase_dir ".planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity"
  @expected_table_cardinality 3
  @expected_finding_roster ["sigra", "threadline"]

  describe "Task 3: the roster is discovered from TODO-011's failure table, not the findings directory" do
    test "TODO-011's failure table names exactly three companions (cardinality gate before filtering)" do
      table_roster = discover_table_roster(File.read!(@todo011))

      assert table_roster != [],
             "expected TODO-011's failure table to name at least one companion — an empty " <>
               "discovery here would let every downstream check pass vacuously"

      assert length(table_roster) == @expected_table_cardinality,
             "expected exactly #{@expected_table_cardinality} companions in TODO-011's failure " <>
               "table, found #{length(table_roster)}: #{inspect(table_roster)}"

      assert Enum.sort(table_roster) == ["rindle", "sigra", "threadline"]
    end

    test "the filtered roster (rindle excluded because TODO-011 diagnoses it inline) equals exactly [sigra, threadline]" do
      todo_text = File.read!(@todo011)
      filtered = filtered_finding_roster(todo_text)

      assert filtered == @expected_finding_roster,
             "expected the filtered roster to equal exactly #{inspect(@expected_finding_roster)}, " <>
               "got #{inspect(filtered)} — a row silently dropped from TODO-011, or a diagnosed " <>
               "companion no longer excluded, must fail this equality rather than shrink or grow " <>
               "the roster unnoticed"
    end

    test "rindle is excluded specifically because TODO-011 carries a '## Root cause of the rindle failure' section" do
      todo_text = File.read!(@todo011)

      assert todo_text =~ ~r/^## Root cause of the rindle failure$/m,
             "expected the fixture assumption (TODO-011 diagnoses rindle inline) to still hold"

      excluded = diagnosed_inline(todo_text)

      assert excluded == ["rindle"],
             "expected the inline-diagnosed set to be exactly [\"rindle\"], got #{inspect(excluded)}"
    end
  end

  describe "Task 3: every roster member has its own finding file, and the two are not byte-identical" do
    test "each of sigra and threadline has a 174-FINDING-<NAME>.md file" do
      roster = filtered_finding_roster(File.read!(@todo011))

      case check_findings_exist(roster, @phase_dir) do
        {:ok, ^roster} ->
          :ok

        {:error, missing} ->
          flunk(
            "expected a finding file for every roster member, missing: #{inspect(missing)} " <>
              "(looked under #{@phase_dir})"
          )
      end
    end

    test "174-FINDING-THREADLINE.md and 174-FINDING-SIGRA.md are not byte-identical" do
      threadline = File.read!(Path.join(@phase_dir, "174-FINDING-THREADLINE.md"))
      sigra = File.read!(Path.join(@phase_dir, "174-FINDING-SIGRA.md"))

      refute threadline == sigra,
             "the two finding files are byte-identical — this is exactly what a single lumped " <>
               "finding copied twice would look like, and SC#5 forbids it"
    end
  end

  describe "Task 3: non-vacuity control — a fixture with one finding removed must fail and name it" do
    test "removing 174-FINDING-SIGRA.md from a temp copy of the phase directory makes the check fail and names sigra" do
      roster = filtered_finding_roster(File.read!(@todo011))
      assert "sigra" in roster

      tmp_dir =
        Path.join(
          System.tmp_dir!(),
          "phase174-findings-fixture-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(tmp_dir)

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      # Copy only the finding files (the fixture's "phase directory") from the real tree, then
      # delete exactly one — the mutation this test exists to prove is caught.
      for companion <- roster do
        src = Path.join(@phase_dir, "174-FINDING-#{String.upcase(companion)}.md")
        dst = Path.join(tmp_dir, "174-FINDING-#{String.upcase(companion)}.md")
        File.cp!(src, dst)
      end

      sigra_finding = Path.join(tmp_dir, "174-FINDING-SIGRA.md")
      assert File.exists?(sigra_finding)
      File.rm!(sigra_finding)

      refute File.exists?(sigra_finding),
             "expected the fixture mutation to actually remove the file"

      assert {:error, missing} = check_findings_exist(roster, tmp_dir)

      assert missing == ["sigra"],
             "expected the check to name exactly the removed companion, got #{inspect(missing)}"
    end

    test "an empty roster is never trivially reported as findings-satisfied" do
      # Guards against a naive implementation that treats [] as "nothing to check, therefore ok".
      assert {:ok, []} = check_findings_exist([], @phase_dir)
      refute [] == @expected_finding_roster
    end
  end

  # --- fixture / source-reading helpers --------------------------------------

  # Scans TODO-011's markdown failure table for rows of the form
  # `| <date> | \`crosswake_<name>\` | ... |` and returns the list of bare companion names
  # (e.g. "threadline"), in table order. This is the independent roster source — it reads
  # nothing from the findings directory.
  defp discover_table_roster(todo_text) do
    ~r/^\|\s*\d{4}-\d{2}-\d{2}\s*\|\s*`crosswake_([a-z]+)`\s*\|/m
    |> Regex.scan(todo_text, capture: :all_but_first)
    |> Enum.map(fn [name] -> name end)
  end

  # Returns the list of companion names TODO-011 diagnoses inline, discovered from its own
  # "## Root cause of the <name> failure" section headings — never a hardcoded literal name.
  defp diagnosed_inline(todo_text) do
    ~r/^## Root cause of the ([a-z]+) failure$/m
    |> Regex.scan(todo_text, capture: :all_but_first)
    |> Enum.map(fn [name] -> name end)
  end

  # The roster this check requires findings for: TODO-011's table roster, minus whatever
  # TODO-011 diagnoses inline, sorted for a stable equality comparison.
  defp filtered_finding_roster(todo_text) do
    table_roster = discover_table_roster(todo_text)
    excluded = diagnosed_inline(todo_text)

    (table_roster -- excluded) |> Enum.uniq() |> Enum.sort()
  end

  # Checks that every member of `roster` has a `174-FINDING-<NAME>.md` file under `phase_dir`.
  # Returns {:ok, roster} when complete, {:error, missing_companions} otherwise. `phase_dir` is
  # a parameter (not a module attribute reference) precisely so the non-vacuity fixture test can
  # point this same function at a temp directory instead of the real phase directory.
  defp check_findings_exist(roster, phase_dir) do
    missing =
      Enum.reject(roster, fn companion ->
        phase_dir
        |> Path.join("174-FINDING-#{String.upcase(companion)}.md")
        |> File.exists?()
      end)

    if missing == [], do: {:ok, roster}, else: {:error, missing}
  end
end
