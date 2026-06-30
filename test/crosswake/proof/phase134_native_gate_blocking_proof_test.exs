defmodule Crosswake.Proof.Phase134NativeGateBlockingProofTest do
  @moduledoc """
  Merge-blocking proof that the `android-generated-shell-unit` lane is wired to actually
  block a PR merge via the `merge-blocking-native-behavioral-proof` aggregator (LIFE-01a).

  This is the shift-left of 134-UAT Test #1 ("Android generated-shell lane actually blocks
  a real PR merge"), which was previously a human verification gated on a live PR against
  origin. The blocking claim decomposes into three independently-automatable parts; this
  file proves CLAIM 1 (wiring) on every PR:

    - claim 1 (wiring)            -> THIS file
    - claim 2 (rollup semantics)  -> .github/workflows/aggregator-negative-control.yml
    - claim 3 (registration)      -> .github/workflows/required-checks-audit.yml (scheduled)

  Literal-presence facts are asserted via `File.read!` + `String.contains?`. Structural
  facts that a substring cannot prove (list membership in `needs:`, `if: always()` on THIS
  job) are checked in pure Elixir: `aggregator_wiring_errors/3` scopes to the aggregator's
  YAML block (`job_block/2`) and verifies `if: always()`, `needs:` membership, and
  alls-green/`toJSON(needs)`. A renamed/removed aggregator yields a "job not found" error
  (non-vacuity guard). No python/PyYAML — the lane stays hermetic and green everywhere
  (an earlier python+PyYAML version reddened proof lanes whose runners lacked PyYAML).

  Untagged. `async: true` — read-only filesystem only; no Application state mutation and
  (per the deferred-items.md flaky-test lesson) no `File.cd!`.

  Stable ids (LIFE-01a):
    - proof.life_01a.gate.aggregator_job
    - proof.life_01a.gate.if_always
    - proof.life_01a.gate.alls_green_action
    - proof.life_01a.gate.tojson_needs
    - proof.life_01a.gate.structural_wiring
    - proof.life_01a.gate.leaf_present
    - proof.life_01a.gate.leaf_macos
    - proof.life_01a.gate.sibling_wiring.<aggregator>
    - proof.life_01a.negctl.present
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @gate ".github/workflows/native-behavioral-proof-gate.yml"
  @negctl ".github/workflows/aggregator-negative-control.yml"

  # ---------------------------------------------------------------------------
  # Claim 1a — literal presence of the load-bearing aggregator tokens.
  # ---------------------------------------------------------------------------

  test "aggregator job, if:always(), alls-green action, and toJSON(needs) are present" do
    src = File.read!(@gate)

    presence = [
      {"proof.life_01a.gate.aggregator_job", "merge-blocking-native-behavioral-proof",
       "the merge-blocking aggregator job must be named in the workflow",
       "rename/restore the merge-blocking-native-behavioral-proof job"},
      {"proof.life_01a.gate.if_always", "if: always()",
       "aggregator must run even when a leaf is skipped/failed",
       "restore `if: always()` on the aggregator — a skipped dep would otherwise count as success (footgun 1)"},
      {"proof.life_01a.gate.alls_green_action", "re-actors/alls-green@release/v1",
       "rollup must use the pinned alls-green action",
       "restore the re-actors/alls-green@release/v1 step"},
      {"proof.life_01a.gate.tojson_needs", "${{ toJSON(needs) }}",
       "rollup must feed every needed job's result into alls-green",
       "restore `jobs: ${{ toJSON(needs) }}` on the alls-green step"}
    ]

    for {id, needle, subject, hint} <- presence do
      assert String.contains?(src, needle),
             ProofAssertions.stable_id_message(
               id,
               subject,
               @gate,
               "needle not found in workflow: #{inspect(needle)}",
               @gate,
               hint,
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Claim 1b — structural wiring: if:always() on THIS job, both leaves in needs:,
  # alls-green/toJSON(needs). Pure Elixir (scoped to the aggregator's YAML block) —
  # no python/PyYAML, so the check stays hermetic and green on every merge-blocking
  # lane. A renamed/removed aggregator job surfaces as "job not found".
  # ---------------------------------------------------------------------------

  test "aggregator structurally gates on both android-package-unit and android-generated-shell-unit" do
    errors =
      aggregator_wiring_errors(@gate, "merge-blocking-native-behavioral-proof", [
        "android-package-unit",
        "android-generated-shell-unit"
      ])

    assert errors == [],
           ProofAssertions.stable_id_message(
             "proof.life_01a.gate.structural_wiring",
             "aggregator must have if:always(), needs:{android-package-unit,android-generated-shell-unit}, and alls-green/toJSON(needs)",
             @gate,
             "wiring errors: #{inspect(errors)}",
             @gate,
             "fix the reported wiring; both leaves must be in needs: and if:always() must be set",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Claim 1c — the leaf the UAT names exists and runs on the right runner.
  # Guards against an edit that drops the leaf from needs: while leaving the
  # name elsewhere in the file (the verify script arch()-exit-1s off-mac, so
  # macos-latest is a hard invariant).
  # ---------------------------------------------------------------------------

  test "android-generated-shell-unit leaf exists on macos-latest" do
    src = File.read!(@gate)

    assert String.contains?(src, "android-generated-shell-unit"),
           ProofAssertions.stable_id_message(
             "proof.life_01a.gate.leaf_present",
             "the android-generated-shell-unit leaf job must exist",
             @gate,
             "leaf job name not found in workflow",
             @gate,
             "restore the android-generated-shell-unit job and keep it in the aggregator's needs:",
             :merge_blocking
           )

    assert String.contains?(src, "runs-on: macos-latest"),
           ProofAssertions.stable_id_message(
             "proof.life_01a.gate.leaf_macos",
             "the generated-shell verify script is mac-specific (arch() exits 1 off-mac)",
             @gate,
             "no `runs-on: macos-latest` job found in workflow",
             @gate,
             "keep android-generated-shell-unit on macos-latest",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Claim 1d — sibling-aggregator parity (the reuse payoff). All three gates
  # share the if:always()+needs+alls-green pattern that the negative-control
  # workflow proves sound; lock that they each still use it.
  # ---------------------------------------------------------------------------

  @siblings [
    {".github/workflows/contract-drift-gate.yml", "merge-blocking-contract-drift",
     ["guard-01-contract-drift-test", "guard-02-generate-and-diff"]},
    {".github/workflows/offline-sync-e2e-gate.yml", "merge-blocking-offline-sync-e2e",
     ["guard-01-e2e-honesty", "guard-02-prod-route-absence", "e2e-proof", "route-tour-proof"]}
  ]

  test "sibling merge-blocking aggregators share the same rollup wiring" do
    for {file, aggregator, leaves} <- @siblings do
      errors = aggregator_wiring_errors(file, aggregator, leaves)

      assert errors == [],
             ProofAssertions.stable_id_message(
               "proof.life_01a.gate.sibling_wiring.#{aggregator}",
               "sibling aggregator #{aggregator} must share the if:always()+needs+alls-green pattern",
               file,
               "wiring errors: #{inspect(errors)}",
               file,
               "the shared aggregator rollup pattern regressed in #{file}",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Claim 2 anchor — the negative-control workflow (which proves the rollup
  # semantics) must exist and keep its footgun-1 (skipped-leaf) arm, so it
  # cannot be silently deleted or hollowed out.
  # ---------------------------------------------------------------------------

  test "aggregator negative-control workflow exists with its skipped-leaf arm" do
    src = File.read!(@negctl)

    for {needle, what} <- [
          {"merge-blocking-aggregator-negative-control", "the merge-blocking gate job"},
          {~s({"result": "skipped"}), "the footgun-1 skipped-leaf-result arm"}
        ] do
      assert String.contains?(src, needle),
             ProofAssertions.stable_id_message(
               "proof.life_01a.negctl.present",
               "negative-control workflow must retain #{what}",
               @negctl,
               "needle not found: #{inspect(needle)}",
               @negctl,
               "do not remove #{what} — it proves alls-green fails on a skipped leaf (footgun 1)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Pure-Elixir structural wiring check (no python/PyYAML — stays hermetic).
  # Scopes to the aggregator's YAML block and returns a list of wiring errors
  # ([] == fully wired). Robust for this repo's single-line `needs: [a, b]` form.
  # ---------------------------------------------------------------------------

  defp aggregator_wiring_errors(file, aggregator, leaves) do
    case job_block(File.read!(file), aggregator) do
      nil ->
        ["aggregator job '#{aggregator}' not found in #{file}"]

      block ->
        if_errors =
          if Regex.match?(~r/^\s+if:\s*always\(\)\s*(#.*)?$/m, block),
            do: [],
            else: ["'#{aggregator}' must declare `if: always()` (a skipped dep would else count as success)"]

        alls_green_errors =
          if String.contains?(block, "re-actors/alls-green@") and String.contains?(block, "toJSON(needs)"),
            do: [],
            else: ["'#{aggregator}' must use re-actors/alls-green with `jobs: ${{ toJSON(needs) }}`"]

        if_errors ++ alls_green_errors ++ missing_needs(block, leaves)
    end
  end

  # The aggregator's YAML block: from its 2-space-indented job key until the next
  # job key (2-space) or top-level key (0-space). Blank/deeper-indented lines stay in.
  defp job_block(src, aggregator) do
    lines = String.split(src, "\n")

    case Enum.find_index(lines, &Regex.match?(~r/^  #{Regex.escape(aggregator)}:\s*(#.*)?$/, &1)) do
      nil ->
        nil

      i ->
        lines
        |> Enum.drop(i + 1)
        |> Enum.take_while(fn l -> not Regex.match?(~r/^ {0,2}\S/, l) end)
        |> Enum.join("\n")
    end
  end

  # Each leaf must appear in the block's `needs: [ ... ]` list.
  defp missing_needs(block, leaves) do
    declared =
      case Regex.run(~r/needs:\s*\[([^\]]*)\]/, block) do
        [_, inner] -> inner |> String.split(",") |> Enum.map(&String.trim/1)
        _ -> []
      end

    case Enum.reject(leaves, &(&1 in declared)) do
      [] -> []
      missing -> ["needs: is missing #{inspect(missing)} (declared: #{inspect(declared)})"]
    end
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-18).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 134 native-gate blocking proof file must not carry @moduletag: tags — it runs untagged (D-18)"
  end
end
