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
  end
end
