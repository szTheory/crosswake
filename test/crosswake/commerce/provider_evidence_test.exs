defmodule Crosswake.Commerce.ProviderEvidenceTest do
  use ExUnit.Case, async: true

  alias Crosswake.Commerce.ProviderEvidence

  describe "vocabularies" do
    test "locks event kind vocabulary" do
      assert ProviderEvidence.event_kind_vocabulary() == [
               "purchase",
               "restore",
               "renewal",
               "grace_period",
               "billing_retry",
               "refund",
               "revoked"
             ]
    end

    test "includes storekit provider name" do
      assert "storekit" in ProviderEvidence.provider_vocabulary()
    end

    test "includes play billing provider name" do
      assert "play_billing" in ProviderEvidence.provider_vocabulary()
    end

    test "locks result status vocabulary" do
      assert ProviderEvidence.result_status_vocabulary() == [
               :submitted,
               :user_canceled,
               :pending,
               :provider_error,
               :prerequisite_missing,
               :reconcile_required
             ]

      refute :granted in ProviderEvidence.result_status_vocabulary()
      refute :active in ProviderEvidence.result_status_vocabulary()
      refute "purchased" in ProviderEvidence.result_status_vocabulary()
      refute "restored" in ProviderEvidence.result_status_vocabulary()
    end

    test "locks lifecycle hint vocabulary" do
      assert ProviderEvidence.lifecycle_hint_vocabulary() == [
               :flow_opened,
               :flow_closed,
               :pending_external,
               :reconcile_required,
               :reconcile_timeout
             ]

      refute :granted in ProviderEvidence.lifecycle_hint_vocabulary()
      refute :active in ProviderEvidence.lifecycle_hint_vocabulary()
      refute "transaction_updates" in ProviderEvidence.lifecycle_hint_vocabulary()
      refute "purchaseStatePurchased" in ProviderEvidence.lifecycle_hint_vocabulary()
    end
  end

  describe "lifecycle hint authority boundary" do
    test "all lifecycle hints are non-authoritative" do
      for lifecycle_hint <- ProviderEvidence.lifecycle_hint_vocabulary() do
        refute ProviderEvidence.authority_mutation_allowed_from_lifecycle_hint?(lifecycle_hint)
      end
    end
  end
end
