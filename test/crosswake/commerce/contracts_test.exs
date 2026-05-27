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

    test "reconciliation_evidence compiles with bounded provenance metadata" do
      evidence = %Contracts.ReconciliationEvidence{
        source: :device,
        provider: "app_store",
        provider_reference: "tx_123",
        event_kind: "purchase",
        evidence_ref: "receipt_ref_123",
        captured_at: "2023-01-01T12:00:00Z",
        integrity_digest: "sha256:abc123",
        idempotency_ref: "idem_123"
      }

      assert evidence.source == :device
      assert evidence.provider_reference == "tx_123"
      assert evidence.event_kind == "purchase"
      assert evidence.evidence_ref == "receipt_ref_123"
      assert evidence.integrity_digest == "sha256:abc123"
      assert evidence.idempotency_ref == "idem_123"
      refute Map.has_key?(evidence, :provider_payload)
    end
  end

  describe "entitlement taxonomy placement" do
    test "locks authority, reconciliation, freshness, and access vocabularies" do
      assert :active in Contracts.authority_vocabulary()
      assert :grace in Contracts.authority_vocabulary()
      assert :billing_retry in Contracts.authority_vocabulary()
      assert :canceled_scheduled_end in Contracts.authority_vocabulary()
      assert :revoked in Contracts.authority_vocabulary()
      assert :refunded in Contracts.authority_vocabulary()
      assert :expired in Contracts.authority_vocabulary()

      assert :pending_purchase in Contracts.reconciliation_vocabulary()
      assert :pending_restore in Contracts.reconciliation_vocabulary()
      assert :awaiting_verification in Contracts.reconciliation_vocabulary()

      assert :fresh in Contracts.freshness_vocabulary()
      assert :stale in Contracts.freshness_vocabulary()
      assert :unknown in Contracts.freshness_vocabulary()

      assert Contracts.access_vocabulary() == [:granted, :denied]
    end

    test "rejects invalid mixed lane placement for authority and freshness states" do
      {:error, authority_errors} =
        Contracts.new_entitlement_snapshot(
          snapshot_attrs(%{
            authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :pending_restore}
          })
        )

      assert {:authority, {:invalid_state, :pending_restore}} in authority_errors

      {:error, freshness_errors} =
        Contracts.new_entitlement_snapshot(
          snapshot_attrs(%{
            freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
              state: :active,
              checked_at: "2023-01-01T12:00:00Z",
              stale_after: "2023-01-01T13:00:00Z"
            }
          })
        )

      assert {:freshness, {:invalid_state, :active}} in freshness_errors
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

  describe "reconciliation evidence vocabulary" do
    test "locks normalized source vocabulary" do
      assert Contracts.reconciliation_evidence_source_vocabulary() == [:device, :storefront, :webhook, :support]
      refute :device_callback in Contracts.reconciliation_evidence_source_vocabulary()
    end
  end

  defp snapshot_attrs(overrides) do
    base_attrs = %{
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

    Map.merge(base_attrs, overrides)
  end
end
