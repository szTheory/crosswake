defmodule Crosswake.Proof.Phase129CompanionContractFreezeTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 129: Stable Companion Contract Surface.

  Proves SEAM-01 (5 contract modules have non-hidden moduledoc + typedoc on t()),
  SEAM-01 (Companion callback set frozen at exactly 6), SEAM-02 (companion_contract.md
  guide exists), and SEAM-03 (Shell.Denial absent / Compatibility.Finding present
  in the "Companion Contract" groups_for_modules entry).

  Runs UNTAGGED so the existing PR-gating proof lane auto-picks it. async: true
  (read-only — no Application.put_env, no shared state mutation).
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  # The canonical pre-phase-129 callback shape. Equality (not membership) means
  # both additions AND removals fail. Change this attribute AND the @callback defs
  # in companion.ex in the SAME PR to signal intentional shape change (D-12, D-17).
  @expected_callbacks MapSet.new([
    {:companion_id, 0},
    {:enabled?, 1},
    {:route_gated?, 2},
    {:kill_switch_active?, 1},
    {:validate_dependency, 0},
    {:report_state, 0}
  ])

  # Struct-bearing contract modules for the typedoc assertion (SEAM-01).
  @struct_contract_modules [
    Crosswake.Companion.State,
    Crosswake.Compatibility.Finding,
    Crosswake.Compatibility.Target,
    Crosswake.Manifest.Types.RouteEntry
  ]

  # The canonical Phase 129 contract module set. Equality (not membership) means
  # both additions AND removals fail — a future PR narrowing the frozen public
  # surface (e.g. dropping a module from the mix.exs "Companion Contract" group)
  # trips this merge-blocking test instead of passing silently (D-15, SEAM-01).
  # Change this attribute AND the mix.exs group in the SAME PR for an intentional
  # surface change.
  @expected_contract_modules MapSet.new([
    Crosswake.Companion,
    Crosswake.Companion.State,
    Crosswake.Compatibility.Finding,
    Crosswake.Compatibility.Target,
    Crosswake.Manifest.Types.RouteEntry
  ])

  # Derives the "Companion Contract" module list from the single source of truth
  # in mix.exs docs/0 groups_for_modules (D-15). Returns [] until plan 129-02 lands.
  defp contract_modules do
    Mix.Project.config()[:docs][:groups_for_modules]
    |> Keyword.get(:"Companion Contract", [])
  end

  # ---------------------------------------------------------------------------
  # Test 1 — Callback freeze (D-12, D-13, SEAM-01)
  # ---------------------------------------------------------------------------

  test "Companion behaviour callbacks are frozen at the Phase 129 contract shape" do
    actual = MapSet.new(Crosswake.Companion.behaviour_info(:callbacks))

    assert MapSet.equal?(@expected_callbacks, actual),
           ProofAssertions.stable_id_message(
             "proof.seam_01.companion.callback_shape",
             "Crosswake.Companion callbacks must match the frozen Phase 129 set",
             "Crosswake.Companion.behaviour_info(:callbacks)",
             "drift detected — actual: #{inspect(MapSet.to_list(actual))}, expected: #{inspect(MapSet.to_list(@expected_callbacks))}",
             "lib/crosswake/companion.ex",
             "change @expected_callbacks in this test AND the @callback defs in companion.ex in the SAME PR so the reviewer sees the intentional shape change",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 2 — moduledoc non-hidden for all 5 contract modules (D-14, SEAM-01)
  # ---------------------------------------------------------------------------

  test "all Companion Contract modules have non-hidden moduledoc" do
    for mod <- contract_modules() do
      result = Code.fetch_docs(mod)

      assert match?({:docs_v1, _, _, _, moduledoc, _, _} when is_map(moduledoc), result),
             ProofAssertions.stable_id_message(
               "proof.seam_01.moduledoc.#{mod}",
               "#{inspect(mod)} must have a non-hidden @moduledoc",
               "Code.fetch_docs(#{inspect(mod)})",
               "got #{inspect(result)}",
               "see guides/companion_contract.md and SEAM-01",
               "add @moduledoc with ## Stability section to #{inspect(mod)} (SEAM-01)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Test 3 — @typedoc on t/0 for all 4 struct-bearing contract modules (D-14, SEAM-01)
  # ---------------------------------------------------------------------------

  test "all struct-bearing Companion Contract modules have @typedoc on t/0" do
    for mod <- @struct_contract_modules do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(mod)

      t_typedoc =
        Enum.find_value(docs, fn
          {{:type, :t, 0}, _anno, _sigs, doc, _meta} -> doc
          _ -> nil
        end)

      assert is_map(t_typedoc),
             ProofAssertions.stable_id_message(
               "proof.seam_01.typedoc.#{mod}.t",
               "#{inspect(mod)}.t/0 must have a non-hidden @typedoc",
               "Code.fetch_docs(#{inspect(mod)}) type :t/0 doc",
               "got #{inspect(t_typedoc)}",
               "lib/crosswake/#{mod |> Module.split() |> Enum.map(&Macro.underscore/1) |> Enum.join("/")}",
               "add @typedoc immediately before @type t :: ... (SEAM-01)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Test 4 — Shell.Denial ABSENT from contract group (D-19, SEAM-03)
  # ---------------------------------------------------------------------------

  test "Crosswake.Shell.Denial is NOT in the Companion Contract module group" do
    refute Crosswake.Shell.Denial in contract_modules(),
           ProofAssertions.stable_id_message(
             "proof.seam_03.denial.absent_from_contract_group",
             "Crosswake.Shell.Denial must not appear in the 'Companion Contract' groups_for_modules entry",
             "mix.exs docs/0 groups_for_modules :\"Companion Contract\"",
             "Crosswake.Shell.Denial found in contract group",
             "mix.exs",
             "Shell.Denial is core-owned. Companions emit Finding.t(), not Denial. (SEAM-03)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 5 — Compatibility.Finding PRESENT in contract group (D-19, SEAM-03)
  # ---------------------------------------------------------------------------

  test "Crosswake.Compatibility.Finding IS in the Companion Contract module group" do
    assert Crosswake.Compatibility.Finding in contract_modules(),
           ProofAssertions.stable_id_message(
             "proof.seam_03.finding.present_in_contract_group",
             "Crosswake.Compatibility.Finding must appear in the 'Companion Contract' groups_for_modules entry",
             "mix.exs docs/0 groups_for_modules :\"Companion Contract\"",
             "Crosswake.Compatibility.Finding not found in contract group",
             "mix.exs",
             "Add Crosswake.Compatibility.Finding to the 'Companion Contract' group in mix.exs (SEAM-03)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 5.5 — Contract module SET frozen exactly (D-15, SEAM-01)
  # ---------------------------------------------------------------------------

  test "the Companion Contract module set is frozen at exactly the Phase 129 surface" do
    actual = MapSet.new(contract_modules())

    assert MapSet.equal?(@expected_contract_modules, actual),
           ProofAssertions.stable_id_message(
             "proof.seam_01.contract.module_set",
             "the 'Companion Contract' groups_for_modules set must match the frozen Phase 129 surface",
             "mix.exs docs/0 groups_for_modules :\"Companion Contract\"",
             "drift detected — actual: #{inspect(MapSet.to_list(actual))}, expected: #{inspect(MapSet.to_list(@expected_contract_modules))}",
             "mix.exs",
             "change @expected_contract_modules in this test AND the mix.exs 'Companion Contract' group in the SAME PR so the reviewer sees the intentional surface change",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 6 — guides/companion_contract.md exists on disk (SEAM-02)
  # ---------------------------------------------------------------------------

  test "guides/companion_contract.md exists on disk" do
    path = Path.join(File.cwd!(), "guides/companion_contract.md")

    assert File.exists?(path),
           ProofAssertions.stable_id_message(
             "proof.seam_02.guide.exists",
             "guides/companion_contract.md must exist on disk",
             "File.exists?(\"guides/companion_contract.md\")",
             "file not found at #{path}",
             "guides/companion_contract.md",
             "create guides/companion_contract.md and register it in mix.exs extras (SEAM-02)",
             :merge_blocking
           )
  end
end
