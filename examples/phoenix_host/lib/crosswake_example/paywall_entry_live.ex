defmodule CrosswakeExample.PaywallEntryLive do
  use Phoenix.LiveView

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.{MockStorefront, ReconciliationInbox, MockBackend, EntitlementProjection}

  @group_id "sub_pro_monthly"
  @dev_mode Mix.env() == :dev

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(CrosswakeExample.PubSub, "entitlement:" <> @group_id)
    end

    {:ok,
     assign(socket,
       derived_state: :stale,
       paywall_entry: paywall_entry(),
       dev_mode: @dev_mode
     )}
  end

  @impl true
  def handle_event("subscribe", _params, socket) do
    intent = %Contracts.PurchaseIntent{
      entry_id: @group_id,
      correlation_id: Ecto.UUID.generate()
    }

    evidence = MockStorefront.simulate_purchase(intent)

    case ReconciliationInbox.ingest_evidence(evidence) do
      {:ok, _attempt} ->
        Phoenix.PubSub.broadcast(
          CrosswakeExample.PubSub,
          "entitlement:" <> @group_id,
          {:entitlement_update, :pending}
        )

        Task.start(fn ->
          :timer.sleep(1_500)
          MockBackend.verify_and_broadcast(evidence, @group_id)
        end)

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Something went wrong submitting your purchase. Please try again."
         )}
    end
  end

  @impl true
  def handle_event("restore", _params, socket) do
    intent = %Contracts.RestoreIntent{
      correlation_id: Ecto.UUID.generate()
    }

    evidence = MockStorefront.simulate_restore(intent)

    case ReconciliationInbox.ingest_evidence(evidence) do
      {:ok, _attempt} ->
        Phoenix.PubSub.broadcast(
          CrosswakeExample.PubSub,
          "entitlement:" <> @group_id,
          {:entitlement_update, :pending}
        )

        Task.start(fn ->
          :timer.sleep(1_500)
          MockBackend.verify_and_broadcast(evidence, @group_id)
        end)

        {:noreply, socket}

      {:error, _reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Something went wrong submitting your purchase. Please try again."
         )}
    end
  end

  @impl true
  def handle_event("dev_force_granted", _params, socket) do
    now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

    snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: @group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :active, reason: nil},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: nil},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "dev_granted_ref"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: now_iso,
          stale_after: nil
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: now_iso,
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: "dev_evt_granted",
          observed_at: now_iso
        },
        as_of: System.system_time(:microsecond)
      })

    state = EntitlementProjection.derived_state(snapshot)

    Phoenix.PubSub.broadcast(
      CrosswakeExample.PubSub,
      "entitlement:" <> @group_id,
      {:entitlement_update, state}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dev_force_pending", _params, socket) do
    now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

    # :pending dev snapshot uses :awaiting_verification — passed directly to derived_state/1,
    # NOT through project_snapshot/2 (which rejects :awaiting_verification, Pitfall 1)
    snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: @group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :none, reason: nil},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :denied, reason: nil},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :awaiting_verification,
          reference: "dev_pending_ref"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: now_iso,
          stale_after: nil
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: now_iso,
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: "dev_evt_pending",
          observed_at: now_iso
        },
        as_of: System.system_time(:microsecond)
      })

    state = EntitlementProjection.derived_state(snapshot)

    Phoenix.PubSub.broadcast(
      CrosswakeExample.PubSub,
      "entitlement:" <> @group_id,
      {:entitlement_update, state}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dev_force_denied", _params, socket) do
    now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

    snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: @group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :none, reason: nil},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :denied, reason: nil},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "dev_denied_ref"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :fresh,
          checked_at: now_iso,
          stale_after: nil
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: now_iso,
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: "dev_evt_denied",
          observed_at: now_iso
        },
        as_of: System.system_time(:microsecond)
      })

    state = EntitlementProjection.derived_state(snapshot)

    Phoenix.PubSub.broadcast(
      CrosswakeExample.PubSub,
      "entitlement:" <> @group_id,
      {:entitlement_update, state}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dev_force_stale", _params, socket) do
    now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

    snapshot =
      struct!(Contracts.EntitlementSnapshot, %{
        group_id: @group_id,
        authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :none, reason: nil},
        access: %Contracts.EntitlementSnapshot.AccessLane{decision: :denied, reason: nil},
        reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
          state: :projection_refreshed,
          reference: "dev_stale_ref"
        },
        freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
          state: :stale,
          checked_at: now_iso,
          stale_after: nil
        },
        effective: %Contracts.EntitlementSnapshot.EffectiveLane{
          effective_from: now_iso,
          effective_until: nil
        },
        evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
          source: :storefront,
          reference: "dev_evt_stale",
          observed_at: now_iso
        },
        as_of: System.system_time(:microsecond)
      })

    state = EntitlementProjection.derived_state(snapshot)

    Phoenix.PubSub.broadcast(
      CrosswakeExample.PubSub,
      "entitlement:" <> @group_id,
      {:entitlement_update, state}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:entitlement_update, derived_state}, socket) do
    {:noreply, assign(socket, derived_state: derived_state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="paywall-corridor">
      <%= case @derived_state do %>
        <% :granted -> %>
          <.granted />
        <% :pending -> %>
          <.pending />
        <% :denied -> %>
          <.denied paywall_entry={@paywall_entry} />
        <% :stale -> %>
          <.stale />
      <% end %>
      <%= if @dev_mode do %>
        <.dev_scenarios />
      <% end %>
    </div>
    """
  end

  defp granted(assigns) do
    ~H"""
    <div class="paywall-state paywall-state--granted">
      <h2>Access granted</h2>
      <p>Your subscription is active. You have full access.</p>
      <a href="#">Manage subscription</a>
    </div>
    """
  end

  defp pending(assigns) do
    ~H"""
    <div class="paywall-state paywall-state--pending">
      <h2>Processing your purchase</h2>
      <p>Verifying with our backend — this usually takes a few seconds.</p>
    </div>
    """
  end

  defp denied(assigns) do
    ~H"""
    <div class="paywall-state paywall-state--denied">
      <h2>Subscribe to continue</h2>
      <p>Pro Monthly</p>
      <p>{@paywall_entry.price_display}</p>
      <button phx-click="subscribe" class="button primary">Subscribe</button>
      <button phx-click="restore" class="button">Already subscribed? Restore purchase</button>
    </div>
    """
  end

  defp stale(assigns) do
    ~H"""
    <div class="paywall-state paywall-state--stale">
      <h2>Access unavailable</h2>
      <p>We can't verify your access right now. Access is closed until verification succeeds.</p>
    </div>
    """
  end

  defp dev_scenarios(assigns) do
    ~H"""
    <div class="dev-scenarios">
      <h3>Dev scenarios (not shown in production)</h3>
      <button phx-click="dev_force_granted" class="button">Force: granted</button>
      <button phx-click="dev_force_pending" class="button">Force: pending</button>
      <button phx-click="dev_force_denied" class="button">Force: denied</button>
      <button phx-click="dev_force_stale" class="button">Force: stale</button>
    </div>
    """
  end

  defp paywall_entry do
    %Contracts.PaywallEntry{
      id: @group_id,
      price_display: "$9.99 / month",
      group_id: @group_id,
      features: [
        "Full access to all content",
        "Offline downloads",
        "Priority support"
      ]
    }
  end
end
