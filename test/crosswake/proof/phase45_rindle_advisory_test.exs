defmodule Crosswake.Proof.Phase45RindleAdvisoryTest do
  @moduledoc """
  Advisory-only proof: asserts that validate_dependency/0 returns :ok when the
  rindle library is present in the dep tree.

  This file is excluded from hermetic runs by the :advisory_only tag and should
  run only in CI steps where MIX_INCLUDE_RINDLE=1 is set.
  """

  use ExUnit.Case, async: false

  @moduletag :advisory_only

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
