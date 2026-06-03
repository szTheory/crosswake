defmodule CrosswakeExample.Commerce.StorefrontAdapter do
  @moduledoc """
  Behaviour for the example-host paywall storefront swap target.

  Implementations emit reconciliation evidence only. They do not grant
  entitlement authority; backend reconciliation and projection own that boundary.
  """

  @callback simulate_purchase(Crosswake.Commerce.Contracts.PurchaseIntent.t()) ::
              {:ok, Crosswake.Commerce.Contracts.ReconciliationEvidence.t()} | {:error, term()}

  @callback simulate_restore(Crosswake.Commerce.Contracts.RestoreIntent.t()) ::
              {:ok, Crosswake.Commerce.Contracts.ReconciliationEvidence.t()} | {:error, term()}
end
