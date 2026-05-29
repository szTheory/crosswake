defmodule Crosswake.Proof.Phase33CommerceCorridorRoutesTest do
  use ExUnit.Case, async: false

  # Depends on the checked-in example Phoenix app (CrosswakeExample.*) being
  # compiled. Run by phase5-proof.yml, which builds the example host first;
  # excluded from the hermetic merge-blocking lane via --exclude requires_example_host.
  @moduletag :requires_example_host

  alias Crosswake.Manifest

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end

  test "the example host registers a subscription_default commerce corridor with correct role ownership" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    corridor = manifest.commerce_corridors["subscription_default"]
    assert corridor != nil, "expected subscription_default commerce corridor in manifest"

    assert corridor.role_ownership.paywall_entry == :phoenix_owned
    assert corridor.role_ownership.purchase_intent == :native_or_companion_required
    assert corridor.role_ownership.restore_intent == :native_or_companion_required
  end

  test "all three corridor route declarations land in the manifest with subscription_default + correct role" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    paywall_route = manifest.routes["commerce-paywall-entry"]
    assert paywall_route != nil, "expected commerce-paywall-entry in manifest.routes"
    assert paywall_route.commerce.corridor_ref == "subscription_default"
    assert paywall_route.commerce.role == :paywall_entry
    assert paywall_route.runtime == :live_view

    purchase_route = manifest.routes["commerce-purchase-intent"]
    assert purchase_route != nil, "expected commerce-purchase-intent in manifest.routes"
    assert purchase_route.commerce.corridor_ref == "subscription_default"
    assert purchase_route.commerce.role == :purchase_intent
    assert purchase_route.runtime == :native_screen

    restore_route = manifest.routes["commerce-restore-intent"]
    assert restore_route != nil, "expected commerce-restore-intent in manifest.routes"
    assert restore_route.commerce.corridor_ref == "subscription_default"
    assert restore_route.commerce.role == :restore_intent
    assert restore_route.runtime == :native_screen
  end
end
