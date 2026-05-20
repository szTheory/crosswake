defmodule Crosswake.Commerce.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.Contracts

  describe "commerce contracts" do
    test "paywall_entry compiles to an explicit small struct" do
      entry = %Contracts.PaywallEntry{
        id: "premium_monthly",
        price_display: "$4.99/mo",
        group_id: "premium",
        features: ["offline sync", "themes"]
      }

      assert entry.id == "premium_monthly"
      assert entry.price_display == "$4.99/mo"
      refute Map.has_key?(entry, :provider_payload)
    end

    test "purchase_intent compiles to an explicit struct" do
      intent = %Contracts.PurchaseIntent{
        entry_id: "premium_monthly",
        correlation_id: "txn_123"
      }

      assert intent.entry_id == "premium_monthly"
      assert intent.correlation_id == "txn_123"
    end

    test "restore_intent compiles to an explicit struct" do
      intent = %Contracts.RestoreIntent{
        correlation_id: "restore_456"
      }

      assert intent.correlation_id == "restore_456"
    end

    test "entitlement_snapshot keeps authority_state and access_state distinct with freshness fields" do
      snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority_state: :active,
        access_state: :granted,
        checked_at: "2023-01-01T12:00:00Z",
        stale_after: "2023-01-01T13:00:00Z",
        effective_until: "2023-02-01T12:00:00Z"
      }

      assert snapshot.authority_state == :active
      assert snapshot.access_state == :granted
      assert snapshot.checked_at == "2023-01-01T12:00:00Z"
    end

    test "entitlement_snapshot supports canceled_scheduled_end vs revoked authority state" do
      snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority_state: :canceled_scheduled_end,
        access_state: :granted,
        checked_at: "2023-01-01T12:00:00Z",
        stale_after: "2023-01-01T13:00:00Z",
        effective_until: "2023-02-01T12:00:00Z"
      }

      assert snapshot.authority_state == :canceled_scheduled_end
      assert snapshot.access_state == :granted

      revoked_snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority_state: :revoked,
        access_state: :denied,
        checked_at: "2023-01-01T12:00:00Z",
        stale_after: "2023-01-01T13:00:00Z",
        effective_until: nil
      }

      assert revoked_snapshot.authority_state == :revoked
    end

    test "reconciliation_evidence compiles without provider leakage" do
      evidence = %Contracts.ReconciliationEvidence{
        correlation_id: "txn_123",
        evidence_token: "receipt_base64_data",
        source: :device_callback
      }

      assert evidence.evidence_token == "receipt_base64_data"
      assert evidence.source == :device_callback
    end
  end

  describe "commerce behaviour" do
    test "defines thin orchestration seam" do
      callbacks = Crosswake.Commerce.behaviour_info(:callbacks)
      
      assert {:submit_purchase_intent, 1} in callbacks
      assert {:submit_restore_intent, 1} in callbacks
      assert {:ingest_reconciliation_evidence, 1} in callbacks
      assert {:fetch_entitlement_snapshot, 1} in callbacks
    end
  end
end
