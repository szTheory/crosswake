defmodule Crosswake.Proof.Phase43RulesteadAdvisoryTest do
  @moduledoc """
  Advisory-only proof: asserts that validate_dependency/0 returns :ok when
  the rulestead library IS present in the dep tree.

  This test runs ONLY in the advisory CI lane (phase43-proof.yml
  advisory-rulestead-proof job) where MIX_INCLUDE_RULESTEAD=1 was set during
  mix deps.get. It must NEVER run in the hermetic lane.

  The assertion inverts the Phase 42 hermetic assertion:
  - Hermetic lane (rulestead absent): validate_dependency/0 == {:error, [:"Elixir.Rulestead"]}
  - Advisory lane (rulestead present): validate_dependency/0 == :ok

  Exclusion contract: the hermetic lane runs
  `mix test --exclude requires_example_host --exclude advisory_only`.
  The :advisory_only tag keeps this file out of the hermetic run.
  """

  # async: false — :companions is a shared global Application key; concurrent tests
  # would observe each other's companion registrations.
  use ExUnit.Case, async: false

  @moduletag :advisory_only

  setup do
    # Save :companions default (added in mix.exs Phase 136 gap closure) so the on_exit
    # restore does not call delete_env and destroy the ambient default.
    original_companions = Application.get_env(:crosswake, :companions)
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
      Application.delete_env(:crosswake, :rulestead)
    end)

    :ok
  end

  test "validate_dependency/0 returns :ok when rulestead library is present (advisory lane)" do
    # The companion checks Code.ensure_loaded?(Rulestead) for the top-level Hex package module.
    # In this file, we call via the full module name to avoid any alias shadowing
    # (Rulestead alias in this file would shadow the Hex package root module atom).
    # Matches the Phase 42 hermetic test's explicit-call convention.
    assert Crosswake.Companions.Rulestead.validate_dependency() == :ok
  end
end
