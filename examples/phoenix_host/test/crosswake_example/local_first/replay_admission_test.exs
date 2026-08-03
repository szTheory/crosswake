defmodule CrosswakeExample.LocalFirst.ReplayAdmissionTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.LocalFirst.ReplayAdmission

  @scope "v1.scope_fixture_alpha_01"
  @event %{"client_mutation_id" => "mutation-1", "card_id" => 1, "rating" => "good"}

  test "the no-callback production path fails closed without a host authority adapter" do
    previous = Application.get_env(:crosswake_example, :offline_study_replay_authority)
    Application.delete_env(:crosswake_example, :offline_study_replay_authority)

    on_exit(fn ->
      if is_nil(previous), do: :ok, else: Application.put_env(:crosswake_example, :offline_study_replay_authority, previous)
    end)

    assert {:deny, :authority_unavailable} = ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event)
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
        else:
          Application.put_env(:crosswake_example, :offline_study_fixture_auth_min_level, previous)
    end)

    assert {:deny, :authority_unavailable} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               domain: fn _, _, _ ->
                 send(self(), :domain_called)
                 :allow
               end
             )

    refute_received :domain_called
  end

  test "missing host auth evidence denies before the domain callback" do
    assert {:deny, :authority_unavailable} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event,
               session: fn _ -> {:ok, %{scope_ref: @scope}} end,
               domain: fn _, _, _ ->
                 send(self(), :domain_called)
                 :allow
               end
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
    assert {:deny, :authority_unavailable} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event, feature: fn _ -> :deny end)

    assert {:deny, :authority_unavailable} =
             ReplayAdmission.authorize(%Plug.Conn{}, @scope, @event, sigra: fn _ -> :deny end)

    assert {:deny, :authority_unavailable} =
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

  test "every hostile fourth replay key denies before session resolution" do
    hostile_events = [
      Map.put(@event, "status", "rejected"),
      Map.put(@event, "outcome", "rejected"),
      Map.put(@event, "authority", "allow"),
      Map.put(@event, :status, "rejected"),
      Map.put(@event, "metadata", %{"nested" => "value"})
    ]

    for event <- hostile_events do
      assert {:deny, :invalid_envelope} =
               ReplayAdmission.authorize(%Plug.Conn{}, @scope, event,
                 session: callback(:session, {:ok, %{scope_ref: @scope}}),
                 route: callback(:route, {:ok, %{id: "offline-study"}}),
                 feature: callback(:feature, :allow),
                 sigra: callback(:sigra, :allow),
                 domain: fn _, _, _ ->
                   send(self(), :domain)
                   :allow
                 end
               )

      refute_received :session
      refute_received :route
      refute_received :feature
      refute_received :sigra
      refute_received :domain
    end
  end

  test "accepts opaque scope payloads at the exact shared grammar boundaries" do
    for payload_size <- [16, 128] do
      scope_ref = "v12." <> String.duplicate("A", payload_size)

      assert {:allow, _} =
               ReplayAdmission.authorize(%Plug.Conn{}, scope_ref, @event,
                 session: fn _ -> {:ok, %{scope_ref: scope_ref}} end,
                 route: fn _ -> {:ok, %{id: "offline-study"}} end,
                 feature: fn _ -> :allow end,
                 sigra: fn _ -> :allow end,
                 domain: fn _, _, _ -> :allow end
               )
    end
  end

  test "hostile scope values deny before every authority callback without echoing scope bytes" do
    hostile_scope_refs = [
      "v1." <> String.duplicate("A", 15),
      "v1." <> String.duplicate("A", 129),
      "v1.opaque scope value",
      "v1.opaque.value-123",
      "v1.opaque/value-123",
      "v1.opaque:value-123",
      "v1.opaque@value-123",
      "v1.opaque\u00E9value-123",
      "v1.account:member@host",
      "v0." <> String.duplicate("A", 16),
      "v01." <> String.duplicate("A", 16),
      String.duplicate("A", 16),
      "v1." <> String.duplicate("A", 16) <> "\n"
    ]

    for scope_ref <- hostile_scope_refs do
      refute scope_ref =~ "scope_fixture_alpha_01"

      assert {:deny, :invalid_envelope} =
               ReplayAdmission.authorize(%Plug.Conn{}, scope_ref, @event,
                 session: fn _ ->
                   send(self(), :session_called)
                   {:ok, %{scope_ref: scope_ref}}
                 end,
                 route: fn _ ->
                   send(self(), :route_called)
                   {:ok, %{id: "offline-study"}}
                 end,
                 feature: fn _ ->
                   send(self(), :feature_called)
                   :allow
                 end,
                 sigra: fn _ ->
                   send(self(), :sigra_called)
                   :allow
                 end,
                 domain: fn _, _, _ ->
                   send(self(), :domain_called)
                   :allow
                 end
               )

      refute_received :session_called
      refute_received :route_called
      refute_received :feature_called
      refute_received :sigra_called
      refute_received :domain_called
    end
  end

  defp callback(label, value) do
    fn _ ->
      send(self(), label)
      value
    end
  end
end
