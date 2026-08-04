defmodule Crosswake.NavigationTransitionTest do
  use ExUnit.Case, async: true

  alias Crosswake.NavigationTransition

  @valid %{
    "protocol" => "crosswake.navigation_transition",
    "version" => "1.0.0",
    "transition_id" => "nav-0123456789abcdef",
    "kind" => "push_navigate",
    "route_id" => "route-0123456789abcdef"
  }

  test "push/2 emits one exact reserved LiveView event" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:ok, pushed} = NavigationTransition.push(socket, @valid)

    assert pushed.private[:live_temp][:push_events] == [
             ["crosswake:navigation_transition", @valid]
           ]
  end

  test "push/2 accepts only an optional opaque restoration reference" do
    attrs = Map.put(@valid, "restoration_ref", "restore-0123456789abcdef")

    assert {:ok, pushed} = NavigationTransition.push(%Phoenix.LiveView.Socket{}, attrs)

    assert pushed.private[:live_temp][:push_events] == [
             ["crosswake:navigation_transition", attrs]
           ]
  end

  test "malformed, incompatible, unknown, and sensitive input fails closed" do
    for attrs <- [
          Map.put(@valid, "kind", "replace"),
          Map.put(@valid, "version", "2.0.0"),
          Map.put(@valid, "payload", %{}),
          Map.put(@valid, "account_id", "not-permitted"),
          Map.delete(@valid, "route_id")
        ] do
      assert {:error, reason} = NavigationTransition.push(%Phoenix.LiveView.Socket{}, attrs)
      assert reason in [:invalid_envelope, :incompatible_version]
    end
  end
end
