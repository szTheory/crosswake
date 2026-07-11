defmodule CrosswakeExample.LearnLoop.SubscriptionLiveTest do
  use ExUnit.Case, async: false

  @subscription_live Module.concat([CrosswakeExample, LearnLoop, SubscriptionLive])

  @tag :learnloop_subscription_live
  test "LearnLoop subscription LiveView contract renders backend-owned entitlement states and mocked storefront evidence" do
    module =
      assert_exported!(
        @subscription_live,
        :mount,
        3,
        "LearnLoop subscription LiveView contract D-16/D-18/D-20 requires SubscriptionLive.mount/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])
    html = render_to_string(module, mounted.assigns)

    assert html =~ "LearnLoop"
    assert html =~ "Backend projection"
    assert html =~ "Backend projection required"
    assert html =~ "Access stays closed until backend projection refreshes"
    assert html =~ "Mock storefront evidence received"
    assert html =~ "No live StoreKit, Play Billing, or RevenueCat adapter in this demo"
    assert html =~ "granted"
    assert html =~ "pending"
    assert html =~ "stale"
    assert html =~ "denied"
    assert html =~ "role=\"status\""
    assert html =~ ~s(href="/learnloop")
    assert html =~ ~s(href="/learnloop/study/session")

    refute html =~ ~r/purchase succeeded|subscribed|unlocked|subscription verified on device|storefront support shipped|RevenueCat adapter/i
  end

  defp socket do
    %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp render_to_string(module, assigns) do
    assigns
    |> Map.put_new(:__changed__, %{})
    |> Map.put_new(:flash, %{})
    |> then(&module.render/1)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
