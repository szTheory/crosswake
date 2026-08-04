defmodule Crosswake.Proof.Phase155NativeControlsTemplateDriftTest do
  @moduledoc """
  Merge-blocking drift test for FALL-01.

  Asserts that the SHA-256 hash of the two `mix crosswake.gen.native_controls_ui`
  `.eex` templates (sorted, bytewise) matches the `@checked_in_hash` module
  attribute. Any change to either template without a deliberate hash bump
  causes this test to fail — mirrors
  `Crosswake.Proof.Phase134TemplateVersionDriftTest`'s shape for the shell
  generator's templates.

  Also asserts non-vacuity: the glob must resolve to at least two files, so an
  empty or renamed template directory can never produce a vacuous pass.

  Untagged, `async: true` — read-only filesystem access; no Application state
  mutation, no `:requires_example_host` tag (D-39 — a tagged test drops to a
  single serial CI lane).

  Stable id: `proof.fall_01.template_version_drift`

  ## Remedy

  If this test goes red because you intentionally changed one of the two
  templates, bump `@template_version` in
  `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` AND update
  `@checked_in_hash` below to the new sorted-bytewise SHA-256, in the SAME
  commit as the template change.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.CapabilityMap
  alias Crosswake.SupportMatrix
  alias Crosswake.TestSupport.ProofAssertions

  @template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "native_controls_ui"])

  @checked_in_hash "cff393da15476ab12a643b6851eb50c171e0ec96e5e13bbf8eb8f772809a6a1e"

  @confirmation_reversal "Phoenix-owned confirmation is the current required fallback on every platform. Native alert/confirm is stopped and may be reconsidered only after passed physical-iPhone proof, a demonstrated active-adopter route blocker, and an explicit maintainer roadmap decision."

  test "template hash matches checked-in hash (drift guard)" do
    live = live_template_hash()

    assert live == @checked_in_hash,
           ProofAssertions.stable_id_message(
             "proof.fall_01.template_version_drift",
             "native-controls-ui templates must not change without bumping @template_version",
             "priv/templates/crosswake/native_controls_ui/**/*.eex (sorted, SHA-256)",
             "live hash #{live} != checked-in hash #{@checked_in_hash}",
             "priv/templates/crosswake/native_controls_ui/",
             "bump @template_version in lib/mix/tasks/crosswake.gen.native_controls_ui.ex and " <>
               "update @checked_in_hash in this file, in the same commit as the template change",
             :merge_blocking
           )
  end

  test "at least 2 native-controls-ui templates present (non-vacuity guard)" do
    templates = Path.wildcard(Path.join(@template_dir, "*.eex"))
    count = length(templates)

    assert count >= 2,
           ProofAssertions.stable_id_message(
             "proof.fall_01.template_version_drift.non_vacuity",
             "at least two .eex templates must exist under priv/templates/crosswake/native_controls_ui/",
             "Path.wildcard(priv/templates/crosswake/native_controls_ui/*.eex)",
             "found #{count} .eex template(s) — the drift test would pass vacuously on an empty glob",
             "priv/templates/crosswake/native_controls_ui/",
             "confirm both crosswake_fallbacks.ex.eex and crosswake_fallback.css.eex exist",
             :merge_blocking
           )
  end

  test "generator and fallback template preserve Phoenix-owned confirmation and the exhaustive reversal gate" do
    generator =
      Path.join([File.cwd!(), "lib", "mix", "tasks", "crosswake.gen.native_controls_ui.ex"])
      |> File.read!()

    template = Path.join(@template_dir, "crosswake_fallbacks.ex.eex") |> File.read!()

    for source <- [generator, template] do
      assert source =~ @confirmation_reversal
      refute source =~ "Crosswake.Bridge.alert"
      refute source =~ "Crosswake.Bridge.confirm"
    end
  end

  test "NAV-07 keeps the Phoenix fallback and reversal gate aligned across canonical, generated, and rendered truth" do
    generator = source!("lib/mix/tasks/crosswake.gen.native_controls_ui.ex")
    template = source!("priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex")
    guide = source!("guides/native_shell.md")

    alert_confirm_row =
      CapabilityMap.canonical()
      |> Enum.find(&(&1.id == "native-controls-alert-confirm"))

    assert alert_confirm_row.denial_fallback =~ "Phoenix-owned confirmation"

    for source <- [generator, template, guide] do
      assert source =~ @confirmation_reversal
    end

    for prerequisite <- [
          "physical-iPhone proof",
          "active-adopter route blocker",
          "maintainer roadmap decision"
        ] do
      assert alert_confirm_row.adoption_implication =~ prerequisite
    end

    ios_notes = SupportMatrix.canonical().ios |> hd() |> Map.fetch!(:notes)

    assert ios_notes =~ "simulator advisory evidence remains distinct"
    assert ios_notes =~ "physical-iPhone promotion is Phase 162 only"
  end

  test "NAV-07 leaves native alert and confirm outside the bridge command and capability registries" do
    commands = Contract.commands() ++ Registry.allowed_commands()
    capability_ids = Crosswake.Manifest.Builder.capability_registry([]) |> Map.keys()

    refute "alert" in commands
    refute "confirm" in commands
    refute "alert" in capability_ids
    refute "confirm" in capability_ids
  end

  defp source!(relative_path) do
    File.read!(Path.join(File.cwd!(), relative_path))
  end

  defp live_template_hash do
    @template_dir
    |> Path.join("*.eex")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.map(&File.read!/1)
    |> Enum.join()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
