defmodule Crosswake.Audit.LedgerTest do
  use ExUnit.Case, async: true
  alias Crosswake.Audit.Ledger

  describe "struct" do
    test "has expected canonical keys initialized to nil" do
      ledger = %Ledger{}

      assert ledger.thread_id == nil
      assert ledger.correlation_id == nil
      assert ledger.route_id == nil
      assert ledger.actor_ref == nil
      assert ledger.actor_kind == nil
      assert ledger.event_class == nil
      assert ledger.event_type == nil
      assert ledger.outcome == nil
      assert ledger.provenance == nil
      assert ledger.occurred_at == nil
      assert ledger.recorded_at == nil
      assert ledger.idempotency_key == nil
      assert ledger.metadata == nil
      assert ledger.row_hash == nil
      assert ledger.prev_hash == nil
    end
  end

  describe "actor_ref/2" do
    setup do
      original = Application.get_env(:crosswake, :audit_hmac_secret)
      on_exit(fn ->
        if original do
          Application.put_env(:crosswake, :audit_hmac_secret, original)
        else
          Application.delete_env(:crosswake, :audit_hmac_secret)
        end
      end)
      :ok
    end

    test "computes HMAC-SHA256 with provided secret" do
      id = "user_123"
      secret = "test_secret_key"

      expected_hmac = :crypto.mac(:hmac, :sha256, secret, to_string(id)) |> Base.encode16(case: :lower)

      assert Ledger.actor_ref(id, secret: secret) == expected_hmac
    end

    test "computes HMAC-SHA256 using application environment secret when opts[:secret] is missing" do
      id = "user_456"
      secret = "app_env_secret"
      Application.put_env(:crosswake, :audit_hmac_secret, secret)

      expected_hmac = :crypto.mac(:hmac, :sha256, secret, to_string(id)) |> Base.encode16(case: :lower)

      assert Ledger.actor_ref(id) == expected_hmac
    end

    test "raises ArgumentError when no secret is provided in opts or application environment" do
      Application.delete_env(:crosswake, :audit_hmac_secret)

      assert_raise ArgumentError, fn ->
        Ledger.actor_ref("user_789")
      end
    end

    test "converts non-string ids to string before hashing" do
      id = 12345
      secret = "test_secret_key"

      expected_hmac = :crypto.mac(:hmac, :sha256, secret, to_string(id)) |> Base.encode16(case: :lower)

      assert Ledger.actor_ref(id, secret: secret) == expected_hmac
    end
  end
end
