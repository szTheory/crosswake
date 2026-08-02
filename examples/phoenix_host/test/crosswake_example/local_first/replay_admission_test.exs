defmodule CrosswakeExample.LocalFirst.ReplayAdmissionTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.LocalFirst.ReplayAdmission

  @scope "v1.scope_fixture_alpha_01"
  @event %{"client_mutation_id" => "mutation-1", "card_id" => 1, "rating" => "good"}

  test "the no-callback default path supplies typed backend evidence without exposing it" do
    assert {:allow, authority} = ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event)
    assert %{route: %{id: "offline-study"}} = authority

    rendered = inspect(authority)
    refute rendered =~ "actor_id"
    refute rendered =~ "org_id"
    refute rendered =~ "auth_context"
    refute rendered =~ "token"
  end

  test "a server-configured predicated default route denies before the domain callback" do
    previous = Application.get_env(:crosswake_example, :offline_study_fixture_auth_min_level)

    Application.put_env(
      :crosswake_example,
      :offline_study_fixture_auth_min_level,
      :phishing_resistant
    )

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:crosswake_example, :offline_study_fixture_auth_min_level),
        else: Application.put_env(:crosswake_example, :offline_study_fixture_auth_min_level, previous)
    end)

    assert {:deny, :sigra_denied} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               domain: fn _, _, _ -> send(self(), :domain_called); :allow end
             )

    refute_received :domain_called
  end

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
