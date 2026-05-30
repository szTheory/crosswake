defmodule Crosswake.Guides.CompanionsTest do
  @moduledoc """
  Docs-contract test for guides/companions.md.

  Asserts that canonical anchor strings (DSL keys, companion contract terms, and
  MockFlagSource symbol names) appear verbatim in the guide, and that live code
  symbols referenced in the guide resolve to real exports.

  Pattern mirrors test/crosswake/guides/commerce_test.exs — File.read! + setup_all
  + assert content =~ + function_exported? live-code guard.
  """

  use ExUnit.Case, async: false

  @guide_path Path.join([File.cwd!(), "guides", "companions.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes gated_by DSL anchor", %{content: content} do
    assert content =~ "gated_by"
  end

  test "includes on_unavailable anchor", %{content: content} do
    assert content =~ "on_unavailable"
  end

  test "includes kill_switch anchor", %{content: content} do
    assert content =~ "kill_switch"
  end

  test "includes MockFlagSource anchor", %{content: content} do
    assert content =~ "MockFlagSource"
  end

  test "includes fail-closed semantics anchor", %{content: content} do
    assert content =~ "fail-closed"
  end

  test "includes gate state denial reasons", %{content: content} do
    assert content =~ ":gate_denied"
    assert content =~ ":kill_switch_active"
  end

  test "includes companion.dependency_missing finding code", %{content: content} do
    assert content =~ "companion.dependency_missing"
  end

  test "includes set_flag anchor for MockFlagSource usage", %{content: content} do
    assert content =~ "set_flag"
  end

  test "live code guard — key companion symbols resolve to real exports", _context do
    # Ensure modules are loaded before reflection — function_exported?/3 requires
    # the module to be loaded in the current node (same pattern as :erlang.function_exported).
    Code.ensure_loaded!(Crosswake.Companions.Rulestead)
    Code.ensure_loaded!(Crosswake.Companions.Rulestead.MockFlagSource)
    Code.ensure_loaded!(Crosswake.SupportMatrix)

    assert function_exported?(Crosswake.Companions.Rulestead, :validate_dependency, 0),
           "Crosswake.Companions.Rulestead.validate_dependency/0 not exported — guide anchor is stale"

    assert function_exported?(Crosswake.Companions.Rulestead.MockFlagSource, :set_flag, 2),
           "MockFlagSource.set_flag/2 not exported — guide anchor is stale"

    assert function_exported?(Crosswake.SupportMatrix, :gating_truth, 0),
           "Crosswake.SupportMatrix.gating_truth/0 not exported — gate-state semantics anchor is stale"
  end
end
