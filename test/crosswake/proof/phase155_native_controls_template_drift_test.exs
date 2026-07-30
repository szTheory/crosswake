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

  alias Crosswake.TestSupport.ProofAssertions

  @template_dir Path.join([File.cwd!(), "priv", "templates", "crosswake", "native_controls_ui"])

  @checked_in_hash "cdddee8843f28bdf47f4e1d0cddc49c5df7ba825b2f2dfb8a420d4a9f8198c6a"

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
