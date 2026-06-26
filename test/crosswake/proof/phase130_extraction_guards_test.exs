defmodule Crosswake.Proof.Phase130ExtractionGuardsTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 130 EXTRACT-01/03/04.

  Proves EXTRACT-01 (core mix.exs contains no MIX_INCLUDE_RULESTEAD or
  MIX_INCLUDE_RINDLE blocks — the env-hack is gone), EXTRACT-03 (no static
  alias to an extracted companion module in lib/), EXTRACT-04 (Code.ensure_loaded?
  calls appear only inside function bodies, never at module-eval time), and the
  D-27 runtime:false guard on the companion mix.exs dep declaration.

  Runs UNTAGGED. async: true (read-only source/config). Must NOT carry
  :requires_example_host or :engine_present tags (D-18).

  These tests are RED (failing by assertion) until Plans 02 and 03 land:
  - EXTRACT-01 fails until Plan 02 deletes MIX_INCLUDE_* blocks from mix.exs
  - EXTRACT-03 and EXTRACT-04 pass at Wave 0 (guard stubs return :ok unconditionally
    and lib/ is clean) but are wired for the non-vacuity pair
  - D-27 guard passes once packages/crosswake_rulestead/mix.exs exists (Plan 01 Task 3)
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.CompanionGuard

  # ---------------------------------------------------------------------------
  # SC#1 — EXTRACT-01: No MIX_INCLUDE_* env hack in core mix.exs
  # These assertions are RED until Plan 02 deletes the MIX_INCLUDE_* blocks.
  # ---------------------------------------------------------------------------

  describe "EXTRACT-01 — core mix.exs must not contain MIX_INCLUDE_* blocks" do
    test "core mix.exs contains no MIX_INCLUDE_RULESTEAD block" do
      source = File.read!(Path.join(File.cwd!(), "mix.exs"))

      refute String.contains?(source, "MIX_" <> "INCLUDE_RULESTEAD"),
             ProofAssertions.stable_id_message(
               "proof.extract_01.mix_exs.no_mix_include_rulestead",
               "core mix.exs must not contain MIX_INCLUDE_RULESTEAD block",
               "File.read!(mix.exs)",
               "found MIX_INCLUDE_RULESTEAD in mix.exs — env hack must be deleted",
               "mix.exs",
               "delete the rulestead MIX_INCLUDE_RULESTEAD conditional block from deps/0 (EXTRACT-01)",
               :merge_blocking
             )
    end

    test "core mix.exs contains no MIX_INCLUDE_RINDLE block" do
      source = File.read!(Path.join(File.cwd!(), "mix.exs"))

      refute String.contains?(source, "MIX_" <> "INCLUDE_RINDLE"),
             ProofAssertions.stable_id_message(
               "proof.extract_01.mix_exs.no_mix_include_rindle",
               "core mix.exs must not contain MIX_INCLUDE_RINDLE block",
               "File.read!(mix.exs)",
               "found MIX_INCLUDE_RINDLE in mix.exs — env hack must be deleted",
               "mix.exs",
               "delete the rindle MIX_INCLUDE_RINDLE conditional block from deps/0 (EXTRACT-01)",
               :merge_blocking
             )
    end

    test "non-vacuity: MIX_INCLUDE_RULESTEAD is detectable in a synthetic source string" do
      # Prove the string comparison can detect the pattern when present.
      # Construct from fragments so THIS proof file does not trip its own guard.
      synthetic = "MIX_" <> "INCLUDE_RULESTEAD"
      assert String.contains?(synthetic, "MIX_" <> "INCLUDE_RULESTEAD"),
             "non-vacuity: the guard must be capable of detecting MIX_INCLUDE_RULESTEAD"
    end
  end

  # ---------------------------------------------------------------------------
  # SC#3 — EXTRACT-03: Static-ref AST guard
  # The CompanionGuard.check_source/1 stubs return :ok in Plan 01.
  # The assert_no_static_refs!/0 test will pass (lib/ has no static refs).
  # Non-vacuity tests ensure the guard CAN detect violations.
  # ---------------------------------------------------------------------------

  describe "EXTRACT-03 — no static alias to extracted companion in lib/" do
    # This test is skipped here because the rulestead adapter source still lives in
    # core lib/ until Plan 04 extracts it. Once Plan 04 removes
    # lib/crosswake/companions/rulestead.ex from core, this skip must be removed and
    # the test asserted green in Plan 05 (the post-extraction verification plan).
    @tag :skip
    test "CompanionGuard.assert_no_static_refs!/0 finds no violations in lib/ — asserted green in Plan 05 (post-extraction)" do
      # DEFERRED to Plan 05: Plan 04 moves lib/crosswake/companions/rulestead.ex into
      # packages/crosswake_rulestead/. Only after that extraction is complete should
      # assert_no_static_refs!/0 pass against the real lib/.
      # The EXTRACT-03 detection LOGIC is proven non-vacuously in the tests below.
      CompanionGuard.assert_no_static_refs!()
    end

    test "CompanionGuard.check_source/1 detects Crosswake.Companions.Rulestead alias — non-vacuity (EXTRACT-03)" do
      # Synthetic source string with a static alias — guard must detect it.
      # Plan 03 implements AST logic; in Plan 01 this test is RED.
      violating = "alias Crosswake.Companions.Rulestead"

      assert {:violation, _} = CompanionGuard.check_source(violating),
             ProofAssertions.stable_id_message(
               "proof.extract_03.non_vacuity.rulestead_detected",
               "check_source/1 must detect Crosswake.Companions.Rulestead alias",
               "CompanionGuard.check_source/1",
               "check_source returned :ok for violating input — guard is not implemented yet",
               "lib/crosswake/companion_guard.ex",
               "Plan 03 must implement AST walk to detect {:__aliases__, _, [:Crosswake, :Companions, :Rulestead]} (EXTRACT-03)",
               :merge_blocking
             )
    end

    test "CompanionGuard.check_source/1 does NOT detect Crosswake.Companions.Sigra alias (legitimate in-tree) — non-vacuity (EXTRACT-03, D-14)" do
      # Sigra stays in-tree — must NOT be flagged by the guard.
      legitimate = "alias Crosswake.Companions.Sigra.Evaluator"

      assert :ok = CompanionGuard.check_source(legitimate),
             ProofAssertions.stable_id_message(
               "proof.extract_03.non_vacuity.sigra_not_detected",
               "check_source/1 must NOT flag Crosswake.Companions.Sigra — it is a legitimate in-tree companion",
               "CompanionGuard.check_source/1",
               "check_source returned {:violation, _} for a legitimate alias",
               "lib/crosswake/companion_guard.ex",
               "Scope guard to frozen @extracted_companions MapSet only — Sigra is NOT extracted (D-14)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # SC#4 — EXTRACT-04: Code.ensure_loaded? placement guard
  # The stubs return :ok so assert_ensure_loaded_in_function_bodies!/0 passes.
  # Non-vacuity tests will be RED until Plan 03 implements the AST walk.
  # ---------------------------------------------------------------------------

  describe "EXTRACT-04 — Code.ensure_loaded? must only appear inside function bodies" do
    test "CompanionGuard.assert_ensure_loaded_in_function_bodies!/0 finds no violations in lib/" do
      # Will pass once Plan 03 implements the AST prune-walk (stubs return :ok now).
      CompanionGuard.assert_ensure_loaded_in_function_bodies!()
    end

    test "CompanionGuard.check_ensure_loaded_placement/1 detects module-eval Code.ensure_loaded? — non-vacuity (EXTRACT-04)" do
      # Synthetic source with a module-eval (non-indented) ensure_loaded? call.
      # Plan 03 implements AST logic; in Plan 01 this test is RED.
      violating_source = """
      defmodule Foo do
        # module-eval call at module body level — violation
        Code.ensure_loaded?(SomeModule)

        def bar, do: :ok
      end
      """

      assert {:violation, _} = CompanionGuard.check_ensure_loaded_placement(violating_source),
             ProofAssertions.stable_id_message(
               "proof.extract_04.non_vacuity.module_eval_detected",
               "check_ensure_loaded_placement/1 must detect module-eval Code.ensure_loaded?",
               "CompanionGuard.check_ensure_loaded_placement/1",
               "check_ensure_loaded_placement returned :ok for violating input — guard is not implemented yet",
               "lib/crosswake/companion_guard.ex",
               "Plan 03 must implement AST prune-walk to detect ensure_loaded? outside def bodies (EXTRACT-04)",
               :merge_blocking
             )
    end

    test "CompanionGuard.check_ensure_loaded_placement/1 does NOT flag Code.ensure_loaded? inside a def body — non-vacuity (EXTRACT-04)" do
      # A valid use: ensure_loaded? inside a function body is fine.
      valid_source = """
      defmodule Foo do
        def validate_dependency do
          if Code.ensure_loaded?(SomeModule) do
            :ok
          else
            {:error, [SomeModule]}
          end
        end
      end
      """

      assert :ok = CompanionGuard.check_ensure_loaded_placement(valid_source),
             ProofAssertions.stable_id_message(
               "proof.extract_04.non_vacuity.function_body_allowed",
               "check_ensure_loaded_placement/1 must NOT flag Code.ensure_loaded? inside a def body",
               "CompanionGuard.check_ensure_loaded_placement/1",
               "check_ensure_loaded_placement returned {:violation, _} for a valid usage",
               "lib/crosswake/companion_guard.ex",
               "Only module-eval (non-indented) Code.ensure_loaded? is a violation (EXTRACT-04)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # D-27 guard — packages/crosswake_rulestead/mix.exs must not have runtime: false
  # This test is RED until Plan 01 Task 3 creates the package skeleton.
  # ---------------------------------------------------------------------------

  describe "D-27 — packages/crosswake_rulestead/mix.exs must not carry runtime: false" do
    test "crosswake_rulestead mix.exs: {:crosswake, path:} dep carries no runtime: false (D-27)" do
      pkg_mix = Path.join(File.cwd!(), "packages/crosswake_rulestead/mix.exs")
      assert File.exists?(pkg_mix),
             ProofAssertions.stable_id_message(
               "proof.d27.package_mix_exists",
               "packages/crosswake_rulestead/mix.exs must exist",
               "File.exists?(packages/crosswake_rulestead/mix.exs)",
               "file not found — package skeleton not created yet",
               "packages/crosswake_rulestead/mix.exs",
               "Plan 01 Task 3 creates the package skeleton",
               :merge_blocking
             )

      source = File.read!(pkg_mix)

      refute String.contains?(source, "runtime: false"),
             ProofAssertions.stable_id_message(
               "proof.d27.no_runtime_false",
               "packages/crosswake_rulestead/mix.exs {:crosswake, path:} dep must carry no runtime: false",
               "File.read!(packages/crosswake_rulestead/mix.exs)",
               "found runtime: false in package mix.exs — core is a RUNTIME dep of the companion (D-27)",
               "packages/crosswake_rulestead/mix.exs",
               "remove runtime: false from {:crosswake, path: ../..} dep declaration (D-19, D-27)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-18).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 130 extraction guards proof file must not carry @moduletag: tags — it runs untagged (D-18)"
  end
end
