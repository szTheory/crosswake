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

    test "entitlement_snapshot uses explicit entitlement lanes with required keys" do
      snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :active},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: :active_subscription},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "attempt_123"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: "2023-01-01T12:00:00Z",
          stale_after: "2023-01-01T13:00:00Z"
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: "2023-01-01T12:00:00Z",
          effective_until: "2023-02-01T12:00:00Z"
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: "tx_123",
          observed_at: "2023-01-01T12:00:00Z"
        },
        as_of: 42
      }

      keys = Map.keys(snapshot)

      assert :authority in keys
      assert :access in keys
      assert :reconciliation in keys
      assert :freshness in keys
      assert :effective in keys
      assert :evidence in keys
      assert :as_of in keys
      refute :authority_state in keys
      refute :checked_at in keys
    end

    test "entitlement_snapshot keeps authority and access semantics orthogonal" do
      snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :canceled_scheduled_end},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: :still_within_term},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "attempt_123"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: "2023-01-01T12:00:00Z",
          stale_after: "2023-01-01T13:00:00Z"
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: "2023-01-01T12:00:00Z",
          effective_until: "2023-02-01T12:00:00Z"
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :webhook,
          reference: "evt_123",
          observed_at: "2023-01-01T12:00:00Z"
        },
        as_of: 43
      }

      assert snapshot.authority.state == :canceled_scheduled_end
      assert snapshot.access.decision == :granted

      revoked_snapshot = %Contracts.EntitlementSnapshot{
        group_id: "premium",
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :revoked},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :denied, reason: :manual_revoke},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "attempt_124"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: "2023-01-01T12:00:00Z",
          stale_after: "2023-01-01T13:00:00Z"
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: "2023-01-01T12:00:00Z",
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :support,
          reference: "ticket_123",
          observed_at: "2023-01-01T12:00:00Z"
        },
        as_of: 44
      }

      assert revoked_snapshot.authority.state == :revoked
    end

    test "reconciliation_evidence compiles without provider leakage" do
      evidence = %Contracts.ReconciliationEvidence{
        correlation_id: "txn_123",
        evidence_token: "receipt_base64_data",
        source: :device
      }

      assert evidence.evidence_token == "receipt_base64_data"
      assert evidence.source == :device
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
