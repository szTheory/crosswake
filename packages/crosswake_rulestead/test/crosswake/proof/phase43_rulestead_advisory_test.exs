defmodule Crosswake.Proof.Phase43RulesteadAdvisoryTest do
  @moduledoc """
  Advisory-only proof: asserts that validate_dependency/0 returns :ok when
  the rulestead library IS present (or a fake Rulestead stub is loaded).

  This test runs ONLY in the engine-present advisory lane (D-33):
    mix engine-present.test
  which sets ENGINE_PRESENT_LANE=1 and runs mix clean first to avoid stale
  .beam files leaking into the absent lane.

  It must NEVER run in the hermetic (engine-absent) lane.

  The assertion inverts the Phase 42 hermetic assertion:
  - Hermetic lane (rulestead absent): validate_dependency/0 == {:error, [:"Elixir.Rulestead"]}
  - Advisory lane (rulestead present): validate_dependency/0 == :ok

  Exclusion contract: the hermetic lane runs untagged tests (default mix test).
  The :engine_present tag keeps this file out of the hermetic run (D-33).
  """

  # async: false — :companions is a shared global Application key; concurrent tests
  # would observe each other's companion registrations.
  use ExUnit.Case, async: false

  @moduletag :engine_present

  setup do
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    :ok
  end

  test "validate_dependency/0 returns :ok when rulestead library is present (engine-present advisory lane)" do
    # The companion checks Code.ensure_loaded?(Rulestead) for the top-level Hex package module.
    # In the engine-present lane, the fake Rulestead stub in test/support/engine_present/
    # is appended to elixirc_paths (D-33), so Code.ensure_loaded?(Rulestead) returns true.
    # We call via the full module name to avoid alias shadowing.
    assert Crosswake.Companions.Rulestead.validate_dependency() == :ok
  end
end
