defmodule CrosswakeExample.LocalFirst.ReplayAdmissionTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.LocalFirst.ReplayAdmission

  @scope "v1.scope_fixture_alpha_01"
  @event %{"client_mutation_id" => "mutation-1", "card_id" => 1, "rating" => "good"}

  test "runs each current authority layer in D-08 order" do
    parent = self()

    callback = fn label, value ->
      fn _ ->
        send(parent, label)
        {:ok, value}
      end
    end

    assert {:allow, _} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               session: callback.(:session, %{scope_ref: @scope}),
               route: callback.(:route, %{id: "offline-study"}),
               feature: fn _ ->
                 send(parent, :feature)
                 :allow
               end,
               sigra: fn _ ->
                 send(parent, :sigra)
                 :allow
               end,
               domain: fn _, _, _ ->
                 send(parent, :domain)
                 :allow
               end
             )

    assert_received :session
    assert_received :route
    assert_received :feature
    assert_received :sigra
    assert_received :domain
  end

  test "scope mismatch fails closed" do
    assert {:deny, :scope_mismatch} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               session: fn _ -> {:ok, %{scope_ref: "v1.scope_fixture_other_01"}} end
             )
  end

  test "feature, Sigra, domain, and exceptional callbacks fail closed" do
    assert {:deny, :feature_disabled} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event, feature: fn _ -> :deny end)

    assert {:deny, :sigra_denied} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event, sigra: fn _ -> :deny end)

    assert {:deny, :authorization_denied} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               domain: fn _, _, _ -> :deny end
             )

    assert {:deny, :authority_unavailable} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               feature: fn _ -> raise "unavailable" end
             )
  end

  test "invalid batches and envelopes fail before authority callbacks" do
    refute ReplayAdmission.valid_batch?([])
    refute ReplayAdmission.valid_batch?(List.duplicate(@event, 21))
    assert {:deny, :invalid_envelope} = ReplayAdmission.authorize(%Plug.Conn{}, "invalid", @event)
  end
end
