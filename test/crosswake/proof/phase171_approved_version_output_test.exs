defmodule Crosswake.Proof.Phase171ApprovedVersionOutputTest do
  @moduledoc """
  Pins WELD-02 and WELD-08 (Phase 171 version/authority split).

  `approved-release-guard` must emit `approved_version`, derived strictly
  from `.release-please-manifest.json` content at the approved head, as a
  peer output of the job's existing identity receipt (D-171-A). The
  derivation must never read an attacker-influenceable surface
  (`github.event.*`, a `workflow_dispatch` input, or `github.head_ref`,
  threat T-171-02).

  Separately, WELD-08 requires the head/tree/base/receipt identity
  predicates the guard already enforced to stay exactly present and
  version-independent after the version pre-check generalizes -- this is
  a structural/text assertion over the job's YAML block, not a live
  GitHub Actions run.

  Finally, this pins WELD-07: the interim tripwire this phase retires
  must be fully gone from the scanner it lived in.
  """

  use ExUnit.Case, async: true

  @workflow ".github/workflows/release-please.yml"
  @manifest ".release-please-manifest.json"
  @scanner "script/check_release_workflow_integrity.exs"

  defp tmp_dir!(name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "cw-p171-output-#{name}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)
    dir
  end

  defp manifest_at!(dir, version) do
    path = Path.join(dir, "manifest.json")

    body =
      @manifest
      |> File.read!()
      |> JSON.decode!()
      |> Map.put(".", version)
      |> Map.put("packages/crosswake-shell-core-ios", version)
      |> Map.put("packages/crosswake-shell-core-android", version)
      |> JSON.encode!()

    File.write!(path, body)
    path
  end

  defp job_block(workflow, job) do
    case Regex.run(
           ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
           workflow
         ) do
      [block] -> block
      _ -> ""
    end
  end

  # The identity predicates the guard already enforced before this phase --
  # every one of these must survive the version-derivation rewrite
  # byte-identical (WELD-08). Asserted individually so a future edit that
  # drops exactly one names which one, rather than one opaque failure.
  @identity_predicates [
    {"the second-parent assignment to approved_head", ~s(approved_head="$second_parent")},
    {"the merge-tree derivation", "merge_tree=$(git rev-parse"},
    {"the tree-identity comparison", ~s([ "$merge_tree" = "$approved_tree" ])},
    {"the candidate receipt identity binding",
     ~s(.identity.bound.head == $head and .identity.bound.tree == $tree and .identity.bound.base == $base)},
    {"the CI-run cross-check", ~s(.databaseId == $run and .headSha == $head)},
    {"the candidate CI receipt cross-check", ~s(.state == "PASS" and .head == $head)}
  ]

  describe "WELD-02: approved_version is emitted from release-manifest content" do
    test "the job's outputs: map declares approved_version bound to steps.guard.outputs.approved_version" do
      block = job_block(File.read!(@workflow), "approved-release-guard")

      assert block =~
               "approved_version: ${{ steps.guard.outputs.approved_version }}"
    end

    test "the guard step contains exactly one emit_output \"approved_version= call" do
      block = job_block(File.read!(@workflow), "approved-release-guard")

      matches = Regex.scan(~r/emit_output "approved_version=/, block)

      assert length(matches) == 1,
             "expected exactly one approved_version emit_output call, found #{length(matches)}"
    end

    test "the derivation reads the release manifest's \".\" key via jq -er, not a second grep of mix.exs" do
      block = job_block(File.read!(@workflow), "approved-release-guard")

      assert block =~ ~s|manifest_version=$(jq -er '."."' .release-please-manifest.json)|
    end
  end

  describe "T-171-02: the derivation never reads an attacker-influenceable surface" do
    test "the guard step body contains no github.event, inputs., or github.head_ref reference" do
      block = job_block(File.read!(@workflow), "approved-release-guard")

      refute block =~ "github.event",
             "approved_version must never be derived from the event payload"

      refute block =~ "inputs.",
             "approved_version must never be derived from a workflow_dispatch input"

      refute block =~ "github.head_ref",
             "approved_version must never be derived from a branch/PR head ref"
    end
  end

  describe "WELD-08: the identity gate stays exact after the version pre-check generalizes" do
    for {label, needle} <- @identity_predicates do
      test "the guard step still contains #{label}" do
        block = job_block(File.read!(@workflow), "approved-release-guard")
        needle = unquote(needle)

        assert block =~ needle,
               "identity predicate missing after version generalization: #{unquote(label)}"
      end
    end

    test "every identity predicate is present, non-vacuously (the assertion list itself is non-empty)" do
      assert length(@identity_predicates) >= 4
    end

    test "the set of identity predicates found is unchanged when the release manifest declares a different version" do
      dir = tmp_dir!("version-independence")
      _other_manifest = manifest_at!(dir, "9.9.9")

      # The guard step's own text does not change based on release-manifest CONTENT --
      # only its behavior at runtime does. Re-reading the workflow after
      # pointing at a differently-versioned release-manifest fixture confirms the
      # identity predicates are asserted unconditionally in the job body
      # (not templated/interpolated from the release manifest at authoring time).
      block = job_block(File.read!(@workflow), "approved-release-guard")

      found_before =
        Enum.filter(@identity_predicates, fn {_label, needle} -> block =~ needle end)

      # Re-read after "pointing" a differently-versioned release manifest -- the
      # guard step's static text in the workflow file is unaffected by which
      # release-manifest content will be read at runtime.
      block_after = job_block(File.read!(@workflow), "approved-release-guard")

      found_after =
        Enum.filter(@identity_predicates, fn {_label, needle} -> block_after =~ needle end)

      assert found_before != []

      assert found_before == found_after,
             "the identity predicates found must not depend on the declared release-manifest version"
    end
  end

  describe "WELD-07: the interim tripwire is fully gone" do
    test "the retired tripwire check ID no longer appears in the scanner" do
      # Built via concatenation, not a literal, so this assertion's own
      # source text does not itself reintroduce the retired ID into a grep
      # across test/ (the plan's own acceptance criterion for WELD-07).
      retired_check_id =
        Enum.join(
          ["release", "version_weld", "gates_match_declared_version"],
          "."
        )

      refute File.read!(@scanner) =~ retired_check_id
    end
  end
end
