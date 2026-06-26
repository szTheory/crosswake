defmodule Crosswake.Proof.Phase45RindleAdvisoryTest do
  @moduledoc """
  Engine-present advisory proof: asserts that validate_dependency/0 returns :ok
  when the rindle engine is present in the dep tree.

  This file is excluded from hermetic runs by the :engine_present tag and runs
  only in the advisory lane where ENGINE_PRESENT_LANE=1 appends the fake
  top-level `Rindle` stub (test/engine_present/rindle.ex) to elixirc_paths(:test),
  making Code.ensure_loaded?(Rindle) == true (D-33). Mirrors rulestead's
  phase43_rulestead_advisory_test.exs. The post-extraction lane replaces the
  retired MIX_INCLUDE_RINDLE env var.
  """

  use ExUnit.Case, async: false

  @moduletag :engine_present

  setup do
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Rindle])
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rindle)
    end)

    :ok
  end

  test "validate_dependency/0 returns :ok when rindle library is present" do
    assert Crosswake.Companions.Rindle.validate_dependency() == :ok
  end
end
