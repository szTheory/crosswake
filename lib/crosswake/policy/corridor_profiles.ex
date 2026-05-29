defmodule Crosswake.Policy.CorridorProfiles do
  @moduledoc """
  Canonical provider-neutral commerce corridor declarations used by manifest assembly.
  """

  alias Crosswake.Policy.Schema

  @type ownership_posture :: :phoenix_owned | :native_or_companion_required
  @type corridor_definition :: %{
          id: String.t(),
          role_ownership: %{required(Schema.commerce_role()) => ownership_posture()},
          denial: String.t(),
          fallback: String.t(),
          prerequisites: [String.t()]
        }

  @commerce_corridors %{
    "subscription_default" => %{
      id: "subscription_default",
      role_ownership: %{
        paywall_entry: :phoenix_owned,
        purchase_intent: :native_or_companion_required,
        restore_intent: :native_or_companion_required,
        account_management: :phoenix_owned
      },
      denial: "commerce.corridor.unsupported",
      fallback: "return_to_phoenix_guidance",
      prerequisites: [
        "backend_entitlement_contract",
        "storefront_adapter_or_companion",
        "reviewer_playbook"
      ]
    }
  }

  @spec commerce_corridors() :: %{required(String.t()) => corridor_definition()}
  def commerce_corridors, do: @commerce_corridors
end
