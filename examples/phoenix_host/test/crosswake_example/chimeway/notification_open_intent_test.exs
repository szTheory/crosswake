defmodule CrosswakeExample.Chimeway.NotificationOpenIntentTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.Chimeway.NotificationOpenIntent

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  describe "changeset/2" do
    @valid_attrs %{
      open_ref: "open_123",
      binding_ref: "bind_123",
      route_id: "dashboard",
      state: "issued",
      expires_at: ~U[2026-06-03 00:00:00Z],
      scope: "test_scope",
      metadata: %{"key" => "value"}
    }

    test "is valid with valid attributes" do
      changeset = NotificationOpenIntent.changeset(%NotificationOpenIntent{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires essential attributes" do
      changeset = NotificationOpenIntent.changeset(%NotificationOpenIntent{}, %{})
      refute changeset.valid?

      assert "can't be blank" in errors_on(changeset).open_ref
      assert "can't be blank" in errors_on(changeset).binding_ref
      assert "can't be blank" in errors_on(changeset).route_id
      assert "can't be blank" in errors_on(changeset).expires_at
    end

    test "enforces state inclusion" do
      changeset = NotificationOpenIntent.changeset(%NotificationOpenIntent{}, Map.put(@valid_attrs, :state, "invalid"))
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).state
    end
  end
end
