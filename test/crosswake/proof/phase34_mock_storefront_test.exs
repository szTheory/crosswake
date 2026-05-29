Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)

defmodule Crosswake.Proof.Phase34MockStorefrontTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 34 MockStorefront module.

  Asserts the must-have truths for MOCK-01, MOCK-02, MOCK-03:
  - simulate_purchase/2 returns correctly-shaped ReconciliationEvidence with
    identity derived only from entry_id (never correlation_id)
  - simulate_restore/2 returns correctly-shaped evidence anchored on the
    @subscription_entry_id module constant (never correlation_id)
  - captured_at clock seam is injectable via opts
  - Both functions return raw structs (no {:ok, _} wrapper)
  - No forbidden provider tokens in the source file

  Provider-vocabulary fence (T-34-01): grep for forbidden tokens runs at
  module-load time so CI fails fast if a future edit introduces them.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.MockStorefront

  # Provider-vocabulary fence (WIRE-03 / T-34-01) — runs at compile time in CI
  @source_file "examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex"

  describe "source fence (T-34-01)" do
    test "no forbidden provider tokens in mock_storefront.ex source" do
      source = File.read!(@source_file)
      refute source =~ ~r/storekit/i, "mock_storefront.ex must not contain 'storekit'"
      refute source =~ ~r/play[ _]billing/i, "mock_storefront.ex must not contain 'play_billing' or 'play billing'"
      refute source =~ ~r/revenuecat/i, "mock_storefront.ex must not contain 'revenuecat'"
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
end
