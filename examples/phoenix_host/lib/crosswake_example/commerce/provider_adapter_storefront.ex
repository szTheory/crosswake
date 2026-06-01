defmodule CrosswakeExample.Commerce.ProviderAdapterStorefront do
  @moduledoc """
  Pure-Elixir swap-target facade for provider evidence emitters in the example host.

  These helpers emit normalized `ReconciliationEvidence` through the same
  provider-neutral inbox/projection path as the mock corridor.
  """

  alias Crosswake.Commerce.Contracts
  alias Crosswake.Companions.PlayBilling.Evidence, as: PlayBillingEvidence
  alias Crosswake.Companions.StoreKit.Evidence, as: StoreKitEvidence

  @behaviour CrosswakeExample.Commerce.StorefrontAdapter

  @group_id "sub_pro_monthly"

  @impl true
  @spec simulate_purchase(Contracts.PurchaseIntent.t()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_purchase(%Contracts.PurchaseIntent{} = intent) do
    case configured_provider() do
      {:ok, :storekit} -> simulate_storekit_purchase(intent)
      {:ok, :play_billing} -> simulate_play_billing_purchase(intent)
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  @spec simulate_restore(Contracts.RestoreIntent.t()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_restore(%Contracts.RestoreIntent{} = intent) do
    case configured_provider() do
      {:ok, :storekit} -> simulate_storekit_restore(intent)
      {:ok, :play_billing} -> simulate_play_billing_restore(intent)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec simulate_storekit_purchase(Contracts.PurchaseIntent.t(), keyword()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_storekit_purchase(%Contracts.PurchaseIntent{} = intent, opts \\ []) do
    storekit_attrs =
      [
        original_transaction_id: "storekit_original_" <> intent.entry_id,
        transaction_id: Keyword.get(opts, :transaction_id, "storekit_txn_" <> intent.entry_id <> "_purchase"),
        signed_transaction_info_digest: Keyword.get(opts, :signed_transaction_info_digest, "sha256:storekit:purchase"),
        event_kind: :purchase,
        environment: Keyword.get(opts, :environment, :sandbox),
        source: :storefront,
        captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601()),
        idempotency_ref: intent.correlation_id
      ]

    with {:ok, normalized} <- StoreKitEvidence.new(storekit_attrs) do
      StoreKitEvidence.to_reconciliation_evidence(normalized)
    end
  end

  @spec simulate_storekit_restore(Contracts.RestoreIntent.t(), keyword()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_storekit_restore(%Contracts.RestoreIntent{} = intent, opts \\ []) do
    storekit_attrs =
      [
        original_transaction_id: "storekit_original_" <> @group_id,
        notification_uuid: Keyword.get(opts, :notification_uuid, "storekit_note_" <> @group_id <> "_restore"),
        signed_transaction_info_digest: Keyword.get(opts, :signed_transaction_info_digest, "sha256:storekit:restore"),
        event_kind: :restore,
        environment: Keyword.get(opts, :environment, :sandbox),
        source: :storefront,
        captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601()),
        idempotency_ref: intent.correlation_id
      ]

    with {:ok, normalized} <- StoreKitEvidence.new(storekit_attrs) do
      StoreKitEvidence.to_reconciliation_evidence(normalized)
    end
  end

  @spec simulate_play_billing_purchase(Contracts.PurchaseIntent.t(), keyword()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_play_billing_purchase(%Contracts.PurchaseIntent{} = intent, opts \\ []) do
    play_attrs =
      [
        purchase_token: "play_token_" <> intent.entry_id,
        order_id: Keyword.get(opts, :order_id, "GPA." <> intent.entry_id <> ".purchase"),
        payload_digest: Keyword.get(opts, :payload_digest, "sha256:play:purchase"),
        event_kind: :purchase,
        environment: Keyword.get(opts, :environment, :license_test),
        source: :storefront,
        captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601()),
        idempotency_ref: intent.correlation_id
      ]

    with {:ok, normalized} <- PlayBillingEvidence.new(play_attrs) do
      PlayBillingEvidence.to_reconciliation_evidence(normalized)
    end
  end

  @spec simulate_play_billing_restore(Contracts.RestoreIntent.t(), keyword()) ::
          {:ok, Contracts.ReconciliationEvidence.t()} | {:error, term()}
  def simulate_play_billing_restore(%Contracts.RestoreIntent{} = intent, opts \\ []) do
    play_attrs =
      [
        purchase_token: "play_token_" <> @group_id,
        rtdn_message_id: Keyword.get(opts, :rtdn_message_id, "rtdn_" <> @group_id <> "_restore"),
        payload_digest: Keyword.get(opts, :payload_digest, "sha256:play:restore"),
        event_kind: :restore,
        environment: Keyword.get(opts, :environment, :license_test),
        source: :storefront,
        captured_at: Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601()),
        idempotency_ref: intent.correlation_id
      ]

    with {:ok, normalized} <- PlayBillingEvidence.new(play_attrs) do
      PlayBillingEvidence.to_reconciliation_evidence(normalized)
    end
  end

  defp configured_provider do
    case Application.get_env(:crosswake_example, :paywall_storefront_provider, nil) do
      nil -> {:error, :provider_not_configured}
      :storekit -> {:ok, :storekit}
      :play_billing -> {:ok, :play_billing}
      provider -> {:error, {:invalid_provider, provider}}
    end
  end
end
