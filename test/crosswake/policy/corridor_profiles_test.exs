defmodule Crosswake.Policy.CorridorProfilesTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.CorridorProfiles

  test "canonical commerce corridor profiles are provider-neutral and include denial/fallback posture" do
    corridors = CorridorProfiles.commerce_corridors()

    assert is_map(corridors)
    assert Map.has_key?(corridors, "subscription_default")

    corridor = corridors["subscription_default"]

    assert corridor.id == "subscription_default"
    assert corridor.denial == "commerce.corridor.unsupported"
    assert corridor.fallback == "return_to_phoenix_guidance"
    assert corridor.prerequisites != []
    assert corridor.role_ownership[:paywall_entry] == :phoenix_owned
    assert corridor.role_ownership[:purchase_intent] == :native_or_companion_required
    assert corridor.role_ownership[:restore_intent] == :native_or_companion_required
    assert corridor.role_ownership[:account_management] == :phoenix_owned

    encoded = inspect(corridors)

    refute String.contains?(encoded, "storekit")
    refute String.contains?(encoded, "play_billing")
    refute String.contains?(encoded, "revenuecat")
  end
end
