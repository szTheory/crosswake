defmodule CrosswakeExample.LearnLoop.EntitlementTest do
  use ExUnit.Case, async: true

  @entitlement Module.concat([CrosswakeExample, LearnLoop, Entitlement])
  @visible_states [:granted, :pending, :stale, :denied]
  @required_copy [
    "Backend projection required",
    "Access stays closed until backend projection refreshes",
    "Mock storefront evidence received",
    "No live StoreKit, Play Billing, or RevenueCat adapter in this demo"
  ]

  @tag :learnloop_entitlement_projection
  test "LearnLoop entitlement projection contract exposes small backend-owned visible state vocabulary" do
    module =
      assert_exported!(
        @entitlement,
        :visible_states,
        0,
        "LearnLoop entitlement projection contract D-16/D-19 requires #{@entitlement}.visible_states/0"
      )

    assert apply(module, :visible_states, []) == @visible_states

    assert_exported!(
      module,
      :snapshot_for,
      1,
      "LearnLoop entitlement projection contract D-17/D-18 requires snapshot_for/1"
    )

    snapshot = apply(module, :snapshot_for, ["learner-iris"])

    assert Map.get(snapshot, :learner_id) == "learner-iris"
    assert Map.get(snapshot, :authority) == :backend_projection
    assert Map.get(snapshot, :storefront_provider) == :mock
    refute Map.get(snapshot, :grants_access_from_storefront_evidence, false)
  end

  @tag :learnloop_entitlement_projection
  test "LearnLoop entitlement projection contract fails closed and separates mock storefront evidence from access authority" do
    module =
      assert_exported!(
        @entitlement,
        :state_copy,
        1,
        "LearnLoop entitlement projection contract D-20 requires #{@entitlement}.state_copy/1"
      )

    copy = apply(module, :state_copy, ["learner-iris"])
    text = inspect(copy)

    for required <- @required_copy do
      assert text =~ required,
             "LearnLoop entitlement projection contract D-20 requires copy #{inspect(required)}"
    end

    for state <- [:pending, :stale, :denied] do
      state_copy = copy_for_state(copy, state)

      assert inspect(state_copy) =~ "Access stays closed",
             "LearnLoop entitlement projection contract D-18/D-20 requires #{inspect(state)} to fail closed"

      refute access_granted?(state_copy),
             "LearnLoop entitlement projection contract D-18 forbids #{inspect(state)} from granting access"
    end

    granted = copy_for_state(copy, :granted)
    assert inspect(granted) =~ "backend projection"

    refute text =~
             ~r/purchase succeeded|subscribed|unlocked|subscription verified on device|storefront support shipped/i,
           "LearnLoop entitlement projection contract D-21 rejects live-provider or device-authoritative entitlement copy"
  end

  @tag :learnloop_entitlement_projection
  test "LearnLoop entitlement projection contract contains no live provider, native storage, or secret payload claims" do
    module =
      assert_exported!(
        @entitlement,
        :state_copy,
        1,
        "LearnLoop entitlement projection contract D-45/D-49/D-50 requires state_copy/1"
      )

    text = apply(module, :state_copy, ["learner-iris"]) |> inspect()

    refute text =~ ~r/live storefront support|native storage support|generic sync helper/i
    refute text =~ ~r/token|secret|provider payload|signed transaction/i
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp copy_for_state(copy, state) when is_map(copy) do
    cond do
      Map.has_key?(copy, state) -> Map.fetch!(copy, state)
      is_list(Map.get(copy, :states)) -> Enum.find(copy.states, &(Map.get(&1, :state) == state))
      true -> nil
    end
  end

  defp access_granted?(state_copy) when is_map(state_copy) do
    Map.get(state_copy, :access) == :granted or Map.get(state_copy, :grants_access) == true
  end

  defp access_granted?(_state_copy), do: false
end
