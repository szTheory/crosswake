Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)

defmodule Crosswake.Proof.Phase34MockStorefrontTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 34 MockStorefront module.

  Asserts the must-have truths for MOCK-01, MOCK-02, MOCK-03, WIRE-03:
  - simulate_purchase/2 returns correctly-shaped ReconciliationEvidence with
    identity derived only from entry_id (never correlation_id)
  - simulate_restore/2 returns correctly-shaped evidence anchored on the
    @subscription_entry_id module constant (never correlation_id)
  - captured_at clock seam is injectable via opts
  - Both functions return raw structs (no {:ok, _} wrapper)
  - No forbidden provider tokens in the source file
  - Replay invariant: same entry_id + different correlation_id yields replay?: true
    via ReconciliationInbox.ingest_evidence/2 (WIRE-03)
  - Restore shares subject_key with purchase of same product (D-06)

  Intentionally UNtagged (no @moduletag :requires_example_host) — hermetic via
  Code.require_file and pure function calls, so it runs in the merge-blocking lane
  under `mix test --exclude requires_example_host`.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.MockStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox

  describe "source fence (T-34-01)" do
    test "no forbidden provider tokens in mock_storefront.ex source" do
      forbidden = [
        "store" <> "kit",
        "play" <> "_billing",
        "play" <> " " <> "billing",
        "revenue" <> "cat"
      ]

      content =
        File.read!("examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex")
        |> String.downcase()

      for token <- forbidden do
        refute String.contains?(content, token), "mock_storefront.ex leaked provider token #{token}"
      end
    end
  end

  describe "swap-target documentation (MOCK-03)" do
    test "source names both swap-target functions" do
      source = File.read!("examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex")

      assert String.contains?(source, "simulate_purchase"),
             "mock_storefront.ex must document simulate_purchase"

      assert String.contains?(source, "simulate_restore"),
             "mock_storefront.ex must document simulate_restore"
    end
  end

  describe "simulate_purchase/2" do
    test "returns a raw ReconciliationEvidence struct (no {:ok, _} wrapper)" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      result = MockStorefront.simulate_purchase(intent)

      assert %Contracts.ReconciliationEvidence{} = result
    end

    test "returns correct source, provider, event_kind" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      evidence = MockStorefront.simulate_purchase(intent)

      assert evidence.source == :storefront
      assert evidence.provider == "mock"
      assert evidence.event_kind == "purchase"
    end

    test "derives provider_reference from entry_id" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      evidence = MockStorefront.simulate_purchase(intent)

      assert evidence.provider_reference == "mock_txn_sub_pro_monthly"
    end

    test "derives evidence_ref from entry_id and event_kind" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      evidence = MockStorefront.simulate_purchase(intent)

      assert evidence.evidence_ref == "mock_evt_sub_pro_monthly_purchase"
    end

    test "provider_reference and evidence_ref are identical when entry_id is same but correlation_id differs" do
      intent1 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      intent2 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c2_different"}

      ev1 = MockStorefront.simulate_purchase(intent1)
      ev2 = MockStorefront.simulate_purchase(intent2)

      assert ev1.provider_reference == ev2.provider_reference
      assert ev1.evidence_ref == ev2.evidence_ref
    end

    test "different entry_id produces different provider_reference" do
      intent_a = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      intent_b = %Contracts.PurchaseIntent{entry_id: "sub_pro_annual", correlation_id: "c1"}

      ev_a = MockStorefront.simulate_purchase(intent_a)
      ev_b = MockStorefront.simulate_purchase(intent_b)

      refute ev_a.provider_reference == ev_b.provider_reference
    end

    test "captured_at defaults to a non-nil ISO 8601 string when not provided" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      evidence = MockStorefront.simulate_purchase(intent)

      assert is_binary(evidence.captured_at)
      assert String.length(evidence.captured_at) > 0
      assert {:ok, _dt, _offset} = DateTime.from_iso8601(evidence.captured_at)
    end

    test "captured_at is injectable via opts" do
      intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      fixed_time = "2026-01-01T00:00:00Z"
      evidence = MockStorefront.simulate_purchase(intent, captured_at: fixed_time)

      assert evidence.captured_at == fixed_time
    end
  end

  describe "simulate_restore/2" do
    test "returns a raw ReconciliationEvidence struct (no {:ok, _} wrapper)" do
      intent = %Contracts.RestoreIntent{correlation_id: "whatever"}
      result = MockStorefront.simulate_restore(intent)

      assert %Contracts.ReconciliationEvidence{} = result
    end

    test "returns correct source, provider, event_kind" do
      intent = %Contracts.RestoreIntent{correlation_id: "whatever"}
      evidence = MockStorefront.simulate_restore(intent)

      assert evidence.source == :storefront
      assert evidence.provider == "mock"
      assert evidence.event_kind == "restore"
    end

    test "provider_reference is anchored on @subscription_entry_id constant, not correlation_id" do
      intent1 = %Contracts.RestoreIntent{correlation_id: "c1"}
      intent2 = %Contracts.RestoreIntent{correlation_id: "completely_different"}

      ev1 = MockStorefront.simulate_restore(intent1)
      ev2 = MockStorefront.simulate_restore(intent2)

      assert ev1.provider_reference == "mock_txn_sub_pro_monthly"
      assert ev1.provider_reference == ev2.provider_reference
    end

    test "evidence_ref is anchored on @subscription_entry_id and event_kind restore" do
      intent = %Contracts.RestoreIntent{correlation_id: "whatever"}
      evidence = MockStorefront.simulate_restore(intent)

      assert evidence.evidence_ref == "mock_evt_sub_pro_monthly_restore"
    end

    test "restore shares same provider_reference as purchase for the same product" do
      purchase_intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      restore_intent = %Contracts.RestoreIntent{correlation_id: "c2"}

      purchase_ev = MockStorefront.simulate_purchase(purchase_intent)
      restore_ev = MockStorefront.simulate_restore(restore_intent)

      assert purchase_ev.provider_reference == restore_ev.provider_reference
    end

    test "captured_at defaults to a non-nil ISO 8601 string when not provided" do
      intent = %Contracts.RestoreIntent{correlation_id: "whatever"}
      evidence = MockStorefront.simulate_restore(intent)

      assert is_binary(evidence.captured_at)
      assert String.length(evidence.captured_at) > 0
      assert {:ok, _dt, _offset} = DateTime.from_iso8601(evidence.captured_at)
    end

    test "captured_at is injectable via opts" do
      intent = %Contracts.RestoreIntent{correlation_id: "whatever"}
      fixed_time = "2026-01-01T00:00:00Z"
      evidence = MockStorefront.simulate_restore(intent, captured_at: fixed_time)

      assert evidence.captured_at == fixed_time
    end
  end

  describe "replay invariant via ingest_evidence (WIRE-03)" do
    test "same entry_id with different correlation_id yields replay?: true and identical event_key" do
      intent1 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      intent2 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c2"}

      ev1 = MockStorefront.simulate_purchase(intent1)
      ev2 = MockStorefront.simulate_purchase(intent2)

      assert {:ok, first} = ReconciliationInbox.ingest_evidence(ev1, correlation_id: "c1")

      assert {:ok, replay} =
               ReconciliationInbox.ingest_evidence(ev2,
                 correlation_id: "c2",
                 seen_event_keys: [first.event_key]
               )

      assert replay.replay? == true
      assert replay.event_key == first.event_key
    end

    test "different entry_id yields distinct event_key and replay?: false" do
      intent_a = %Contracts.PurchaseIntent{entry_id: "entry_a", correlation_id: "c1"}
      intent_b = %Contracts.PurchaseIntent{entry_id: "entry_b", correlation_id: "c2"}

      ev_a = MockStorefront.simulate_purchase(intent_a)
      ev_b = MockStorefront.simulate_purchase(intent_b)

      assert {:ok, a} = ReconciliationInbox.ingest_evidence(ev_a)

      assert {:ok, b} =
               ReconciliationInbox.ingest_evidence(ev_b, seen_event_keys: [a.event_key])

      refute b.replay?
      refute a.event_key == b.event_key
    end

    test "restore shares subject_key with purchase of the canonical product (D-06)" do
      purchase_intent = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
      restore_intent = %Contracts.RestoreIntent{correlation_id: "c2"}

      purchase_ev = MockStorefront.simulate_purchase(purchase_intent)
      restore_ev = MockStorefront.simulate_restore(restore_intent)

      assert {:ok, p} = ReconciliationInbox.ingest_evidence(purchase_ev)
      assert {:ok, r} = ReconciliationInbox.ingest_evidence(restore_ev)

      assert p.subject_key == r.subject_key
    end
  end
end
