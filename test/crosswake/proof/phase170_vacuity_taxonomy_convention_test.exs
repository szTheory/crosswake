defmodule Crosswake.Proof.Phase170VacuityTaxonomyConventionTest do
  @moduledoc """
  VAC-03 / D-15 / D-16 / D-17 / D-21: turns the `vacuity_taxonomy` phase-close convention
  (`VERIFICATION-CONVENTIONS.md`, landed by plan 170-04) into a decidable, executing check,
  proven capable of going red.

  Per D-16's ROSTER/DONE property, completeness must be a POSITIVE assertion, never an
  inference from absence: an auditor grepping every phase's `VERIFICATION.md` for the
  `## Vacuity Taxonomy` section must get a decidable answer per phase, not silence. The
  predicate this module extracts — `taxonomy_recorded?/2` — is a pure function over a
  directory listing plus a verification source string, so a synthetic fixture can prove it
  capable of returning `false` rather than resting on "it currently passes against a
  currently-compliant tree" (the exact non-vacuity discipline
  `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` established one phase ago).

  Per D-13/D-21/ROADMAP SC#3, this check asserts PRESENCE of the phase-close record only. It
  does not scan for collection assertions anywhere in the tree, does not evaluate the
  quality of an entry's evidence, and is deliberately absent from every merge-blocking
  scanner and required-check registry in this repository — it is an ordinary `mix test`
  entry, exactly like its two phase170 siblings.
  """
  use ExUnit.Case, async: true

  @conventions_doc ".planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md"
  @phases_glob ".planning/workstreams/quality-ratchet-release/phases/*"
  @vacuity_taxonomy_heading "## Vacuity Taxonomy"
  @addendum_suffix "-VACUITY-TAXONOMY.md"

  # Extracted as a pure predicate over a directory listing plus file contents (rather than an
  # inline assert against the live filesystem) so a synthetic fixture can prove it capable of
  # returning false, per D-14/D-23's non-vacuity discipline. Returns true when the
  # verification source contains the "## Vacuity Taxonomy" heading, OR the directory entries
  # include a file matching `*-VACUITY-TAXONOMY.md`.
  defp taxonomy_recorded?(dir_entries, verification_source) do
    has_section? =
      is_binary(verification_source) and
        String.contains?(verification_source, @vacuity_taxonomy_heading)

    has_addendum? = Enum.any?(dir_entries, &String.ends_with?(&1, @addendum_suffix))

    has_section? or has_addendum?
  end

  # Finds every phase directory under this workstream that carries at least one
  # `*-VERIFICATION.md` file — the set this convention applies to (D-17: applied at phase
  # close, through the VERIFICATION.md artifact). A phase with no VERIFICATION.md at all has
  # not yet closed and is out of this convention's scope.
  defp phase_dirs_with_verification do
    @phases_glob
    |> Path.wildcard()
    |> Enum.filter(&File.dir?/1)
    |> Enum.sort()
    |> Enum.filter(fn dir ->
      dir
      |> Path.join("*-VERIFICATION.md")
      |> Path.wildcard()
      |> case do
        [] -> false
        _ -> true
      end
    end)
  end

  defp verification_source_for(dir) do
    dir
    |> Path.join("*-VERIFICATION.md")
    |> Path.wildcard()
    |> List.first()
    |> File.read!()
  end

  test "Task 2: the convention document exists and single-sources the taxonomy" do
    assert File.exists?(@conventions_doc),
           "expected #{@conventions_doc} to exist — it is the single source of the vacuity_taxonomy convention"

    source = File.read!(@conventions_doc)

    assert source =~ "vacuity_taxonomy"
    assert source =~ "This phase landed no new checks."
    assert source =~ "PITFALLS.md"
  end

  test "Task 2: every phase VERIFICATION.md under this workstream complies with the convention" do
    examined = phase_dirs_with_verification()

    offenders =
      examined
      |> Enum.reject(fn dir ->
        entries = File.ls!(dir)
        source = verification_source_for(dir)
        taxonomy_recorded?(entries, source)
      end)
      |> Enum.map(&Path.basename/1)

    assert offenders == [],
           "the following phase directories are missing a '#{@vacuity_taxonomy_heading}' " <>
             "section in their VERIFICATION.md and lack a sibling '*#{@addendum_suffix}' " <>
             "addendum: #{inspect(offenders)}. See VERIFICATION-CONVENTIONS.md."
  end

  test "Task 2: findings floor — the examined phase-directory count is non-zero (D-14)" do
    examined = phase_dirs_with_verification()

    assert length(examined) >= 1,
           "expected at least 1 phase directory with a *-VERIFICATION.md to examine, found 0 — " <>
             "the Path.wildcard glob may have silently stopped matching, which would turn this " <>
             "check into a green no-op (D-14)"
  end

  test "Task 2: non-vacuity control — the predicate returns true for a real *-VERIFICATION.md carrying the section" do
    source =
      verification_source_for(
        ".planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility"
      )

    # 169-VERIFICATION.md is a sealed, digest-covered artifact and was closed before this
    # convention existed, so it is covered by the sibling 169-VACUITY-TAXONOMY.md addendum,
    # not by an in-place section edit. Confirm the ADDENDUM branch fires for the real phase
    # this convention already covers.
    entries =
      File.ls!(".planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility")

    assert taxonomy_recorded?(entries, source)
  end

  @tag :tmp_dir
  test "Task 2: non-vacuity control (D-14) — the predicate returns false for a non-compliant synthetic fixture",
       %{tmp_dir: tmp} do
    File.write!(Path.join(tmp, "999-VERIFICATION.md"), """
    # Phase 999 Verification

    No taxonomy section here at all.
    """)

    entries = File.ls!(tmp)
    source = File.read!(Path.join(tmp, "999-VERIFICATION.md"))

    refute taxonomy_recorded?(entries, source),
           "expected taxonomy_recorded?/2 to return false when neither the section nor an addendum is present"
  end

  @tag :tmp_dir
  test "Task 2: positive control — the predicate returns true via the sibling addendum branch", %{
    tmp_dir: tmp
  } do
    File.write!(Path.join(tmp, "998-VERIFICATION.md"), """
    # Phase 998 Verification

    No heading here either.
    """)

    File.write!(Path.join(tmp, "998-VACUITY-TAXONOMY.md"), """
    # Phase 998 Vacuity Taxonomy Addendum
    """)

    entries = File.ls!(tmp)
    source = File.read!(Path.join(tmp, "998-VERIFICATION.md"))

    assert taxonomy_recorded?(entries, source),
           "expected taxonomy_recorded?/2 to return true when a sibling *-VACUITY-TAXONOMY.md addendum exists"
  end

  @tag :tmp_dir
  test "Task 2: positive control — the predicate returns true via the direct section branch", %{
    tmp_dir: tmp
  } do
    File.write!(Path.join(tmp, "997-VERIFICATION.md"), """
    # Phase 997 Verification

    ## Vacuity Taxonomy

    This phase landed no new checks. No checks were added anywhere in this synthetic phase.
    """)

    entries = File.ls!(tmp)
    source = File.read!(Path.join(tmp, "997-VERIFICATION.md"))

    assert taxonomy_recorded?(entries, source),
           "expected taxonomy_recorded?/2 to return true when the '## Vacuity Taxonomy' heading is present directly"
  end
end
