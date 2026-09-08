defmodule Crosswake.Proof.Phase134NativeGateBlockingProofTest do
  @moduledoc """
  Merge-blocking proof that the `android-generated-shell-unit` lane remains under
  the `Crosswake CI` umbrella and its checkout-free
  `merge-blocking-native-behavioral-proof` compatibility projection (LIFE-01a).

  This is the shift-left of 134-UAT Test #1 ("Android generated-shell lane actually blocks
  a real PR merge"), which was previously a human verification gated on a live PR against
  origin. The blocking claim decomposes into three independently-automatable parts; this
  file proves CLAIM 1 (wiring) on every PR:

    - claim 1 (wiring)            -> THIS file
    - claim 2 (rollup semantics)  -> script/check_aggregator_result_semantics.py
    - claim 3 (registration)      -> .github/workflows/required-checks-audit.yml (scheduled)

  Literal-presence facts are asserted via `File.read!` + `String.contains?`. Structural
  facts that a substring cannot prove are scoped to exact YAML job blocks. The historical
  fixture helper still proves exact single-line `needs:` parity; the production contract
  now checks the central umbrella and compatibility jobs directly.

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

  @gate ".github/workflows/crosswake-ci.yml"
  @negctl ".github/workflows/crosswake-ci.yml"

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
      {"proof.life_01a.gate.alls_green_action",
       "proof leaf did not reach a closed accepted result",
       "rollup must reject every non-success proof result that is not explicitly irrelevant",
       "restore the fail-closed Crosswake CI result evaluation"},
      {"proof.life_01a.gate.tojson_needs", "${{ toJSON(needs) }}",
       "rollup must inspect every needed job's result",
       "restore `NEEDS_JSON: ${{ toJSON(needs) }}` on the umbrella"}
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
  # Claim 1b — structural wiring through the central umbrella and compatibility context.
  # ---------------------------------------------------------------------------

  test "Crosswake CI structurally gates both Android native leaves" do
    umbrella = @gate |> File.read!() |> job_block("merge-blocking-crosswake-ci")
    compatibility = @gate |> File.read!() |> job_block("compat-native-behavioral-proof")

    assert umbrella =~ ~r/^      - android-package-unit$/m
    assert umbrella =~ ~r/^      - android-generated-shell-unit$/m
    assert compatibility =~ "name: merge-blocking-native-behavioral-proof"
    assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
    assert compatibility =~ "if: always()"
    assert compatibility =~ ~s(test "$RESULT" = success)
    refute compatibility =~ "actions/checkout"
  end

  # ---------------------------------------------------------------------------
  # Claim 1c — the leaf the UAT names exists and runs on the right runner.
  # Guards against an edit that drops the leaf from needs: while leaving the
  # name elsewhere in the file, or moves pure Android/JVM work back to macOS.
  # ---------------------------------------------------------------------------

  test "android-generated-shell-unit leaf exists on Linux with hermetic JVM setup" do
    src = File.read!(@gate)
    leaf = job_block(src, "android-generated-shell-unit")

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

    assert String.contains?(leaf, "runs-on: ubuntu-latest"),
           ProofAssertions.stable_id_message(
             "proof.life_01a.gate.leaf_macos",
             "the pure generated Android shell proof must run on Linux",
             @gate,
             "android-generated-shell-unit is not on ubuntu-latest",
             @gate,
             "keep pure Android/JVM proof on ubuntu-latest",
             :merge_blocking
           )

    assert leaf =~ "./.github/actions/setup-android-jvm"
    assert leaf =~ "script/verify_generated_android_shell.sh"
  end

  # ---------------------------------------------------------------------------
  # Claim 1d — sibling compatibility projections share the checkout-free,
  # if:always()+single-umbrella-needs pattern.
  # ---------------------------------------------------------------------------

  @siblings [
    {"compat-contract-drift", "merge-blocking-contract-drift"},
    {"compat-offline-sync-e2e", "merge-blocking-offline-sync-e2e"}
  ]

  test "sibling merge-blocking aggregators share the same rollup wiring" do
    src = File.read!(@gate)

    for {job, display_name} <- @siblings do
      compatibility = job_block(src, job)
      assert compatibility =~ "name: #{display_name}"
      assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
      assert compatibility =~ "if: always()"
      assert compatibility =~ "RESULT: ${{ needs.merge-blocking-crosswake-ci.result }}"
      refute compatibility =~ "actions/checkout"
    end
  end

  @tag :tmp_dir
  test "exact aggregator leaf parity accepts ordering-only differences", %{tmp_dir: tmp_dir} do
    fixture = Path.join(tmp_dir, "reordered.yml")
    write_aggregator_fixture!(fixture, ["leaf-b", "leaf-a"])

    assert aggregator_wiring_errors(fixture, "merge-blocking-fixture", ["leaf-a", "leaf-b"]) == []
  end

  @tag :tmp_dir
  test "exact aggregator leaf parity reports a removed required leaf", %{tmp_dir: tmp_dir} do
    fixture = Path.join(tmp_dir, "missing.yml")
    write_aggregator_fixture!(fixture, ["leaf-a"])

    assert aggregator_wiring_errors(fixture, "merge-blocking-fixture", ["leaf-a", "leaf-b"]) == [
             "aggregator 'merge-blocking-fixture' in #{fixture} has invalid needs parity: " <>
               "missing=[\"leaf-b\"] unexpected=[] " <>
               "expected=[\"leaf-a\", \"leaf-b\"] declared=[\"leaf-a\"]"
           ]
  end

  @tag :tmp_dir
  test "exact aggregator leaf parity reports an undeclared added leaf", %{tmp_dir: tmp_dir} do
    fixture = Path.join(tmp_dir, "unexpected.yml")
    write_aggregator_fixture!(fixture, ["leaf-a", "leaf-extra"])

    assert aggregator_wiring_errors(fixture, "merge-blocking-fixture", ["leaf-a"]) == [
             "aggregator 'merge-blocking-fixture' in #{fixture} has invalid needs parity: " <>
               "missing=[] unexpected=[\"leaf-extra\"] " <>
               "expected=[\"leaf-a\"] declared=[\"leaf-a\", \"leaf-extra\"]"
           ]
  end

  # ---------------------------------------------------------------------------
  # Claim 2 anchor — the negative-control leaf and legacy projection must remain.
  # ---------------------------------------------------------------------------

  test "aggregator negative-control workflow exists with its skipped-leaf arm" do
    src = File.read!(@negctl)
    leaf = job_block(src, "proof-aggregator-negative-control")
    compatibility = job_block(src, "compat-aggregator-negative-control")

    assert leaf =~ "name: proof-aggregator-negative-control"
    assert leaf =~ "python3 script/check_aggregator_result_semantics.py --self-test"
    assert compatibility =~ "name: merge-blocking-aggregator-negative-control"
    assert compatibility =~ "needs: [merge-blocking-crosswake-ci]"
    assert compatibility =~ "if: always()"
  end

  test "aggregator negative control awaits every closed-policy action outcome" do
    src = File.read!("script/check_aggregator_result_semantics.py")

    for result_class <- [
          "success",
          "failure",
          "cancelled",
          "skipped_disallowed",
          "skipped_irrelevant",
          "timed_out",
          "action_required",
          "stale",
          "unknown",
          "empty",
          "missing"
        ] do
      assert String.contains?(src, ~s("#{result_class}"))
    end

    assert src =~ "--assert-outcomes"
    assert src =~ "negative-control=missing_outcome"
    assert src =~ "negative-control=inverted_outcome"
    refute src =~ "allowed-failures"
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
            else: [
              "'#{aggregator}' must declare `if: always()` (a skipped dep would else count as success)"
            ]

        alls_green_errors =
          if String.contains?(block, "re-actors/alls-green@") and
               String.contains?(block, "toJSON(needs)"),
             do: [],
             else: [
               "'#{aggregator}' must use re-actors/alls-green with `jobs: ${{ toJSON(needs) }}`"
             ]

        if_errors ++ alls_green_errors ++ needs_parity_errors(block, leaves, file, aggregator)
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

  defp write_aggregator_fixture!(path, leaves) do
    File.write!(
      path,
      """
      name: Fixture
      jobs:
        decoy:
          if: always()
          needs: [leaf-a, leaf-b, leaf-extra]
          steps:
            - uses: re-actors/alls-green@release/v1
              with:
                jobs: \${{ toJSON(needs) }}
        merge-blocking-fixture:
          if: always()
          needs: [#{Enum.join(leaves, ", ")}]
          steps:
            - uses: re-actors/alls-green@release/v1
              with:
                jobs: \${{ toJSON(needs) }}
      """
    )
  end

  # The named aggregator's single-line `needs: [ ... ]` list must be exactly the
  # expected set. Ordering is presentation-only; missing and unexpected leaves
  # both fail with workflow/aggregator provenance.
  defp needs_parity_errors(block, leaves, file, aggregator) do
    declared =
      case Regex.run(~r/needs:\s*\[([^\]]*)\]/, block) do
        [_, inner] ->
          inner
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()
          |> Enum.sort()

        _ ->
          []
      end

    expected = leaves |> Enum.uniq() |> Enum.sort()
    missing = expected -- declared
    unexpected = declared -- expected

    if missing == [] and unexpected == [] do
      []
    else
      [
        "aggregator '#{aggregator}' in #{file} has invalid needs parity: " <>
          "missing=#{inspect(missing)} unexpected=#{inspect(unexpected)} " <>
          "expected=#{inspect(expected)} declared=#{inspect(declared)}"
      ]
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
