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
      tenant_ref: "tenant_123",
      subject_ref: "subject_123",
      session_ref: "session_123",
      session_version: 1,
      route_id: "dashboard",
      state: "issued",
      expires_at: ~U[2026-06-03 00:00:00Z],
      scope: "subject_session",
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
      changeset =
        NotificationOpenIntent.changeset(
          %NotificationOpenIntent{},
          Map.put(@valid_attrs, :state, "invalid")
        )

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).state
    end

    test "recursively removes forbidden metadata while preserving safe siblings" do
      raw_token = "intent-raw-token-sentinel"
      body = "intent-notification-body-sentinel"
      payload = "intent-provider-payload-sentinel"

      changeset =
        NotificationOpenIntent.changeset(
          %NotificationOpenIntent{},
          Map.put(@valid_attrs, :metadata, %{
            "safe_top_level" => "kept",
            "notification_body" => body,
            "nested" => %{
              "provider_payload" => payload,
              "safe_nested" => "kept"
            },
            "list" => [
              %{"safe_list" => "kept", device_token: raw_token},
              [provider_response_body: payload, safe_keyword: "kept"]
            ],
            raw_token: raw_token
          })
        )

      metadata = Ecto.Changeset.get_change(changeset, :metadata)

      assert metadata["safe_top_level"] == "kept"
      assert metadata["nested"]["safe_nested"] == "kept"
      assert inspect(metadata) =~ "kept"
      refute inspect(metadata) =~ raw_token
      refute inspect(metadata) =~ body
      refute inspect(metadata) =~ payload
    end

    test "projects non-map metadata to an empty map" do
      changeset =
        NotificationOpenIntent.changeset(
          %NotificationOpenIntent{},
          Map.put(@valid_attrs, :metadata, ["untrusted"])
        )

      assert Ecto.Changeset.get_change(changeset, :metadata) == %{}
    end
  end
end
