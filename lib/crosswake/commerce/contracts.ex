defmodule Crosswake.Commerce.Contracts do
  @moduledoc """
  Typed commerce contract surfaces shared by core, route policy, and manifest truth.
  """

  defmodule PaywallEntry do
    @moduledoc false
    @enforce_keys [:id, :price_display, :group_id, :features]
    defstruct [:id, :price_display, :group_id, features: []]

    @type t :: %__MODULE__{
            id: String.t(),
            price_display: String.t(),
            group_id: String.t(),
            features: [String.t()]
          }
  end

  defmodule PurchaseIntent do
    @moduledoc false
    @enforce_keys [:entry_id, :correlation_id]
    defstruct [:entry_id, :correlation_id]

    @type t :: %__MODULE__{
            entry_id: String.t(),
            correlation_id: String.t()
          }
  end

  defmodule RestoreIntent do
    @moduledoc false
    @enforce_keys [:correlation_id]
    defstruct [:correlation_id]

    @type t :: %__MODULE__{
            correlation_id: String.t()
          }
  end

  defmodule EntitlementSnapshot do
    @moduledoc false
    @enforce_keys [
      :group_id,
      :authority_state,
      :access_state,
      :checked_at,
      :stale_after,
      :effective_until
    ]
    defstruct [
      :group_id,
      :authority_state,
      :access_state,
      :checked_at,
      :stale_after,
      :effective_until
    ]

    @type authority_state :: :active | :canceled_scheduled_end | :revoked | :expired | :pending
    @type access_state :: :granted | :denied

    @type t :: %__MODULE__{
            group_id: String.t(),
            authority_state: authority_state(),
            access_state: access_state(),
            checked_at: String.t(),
            stale_after: String.t(),
            effective_until: String.t() | nil
          }
  end

  defmodule ReconciliationEvidence do
    @moduledoc false
    @enforce_keys [:correlation_id, :evidence_token, :source]
    defstruct [:correlation_id, :evidence_token, :source]

    @type source :: :device_callback | :webhook

    @type t :: %__MODULE__{
            correlation_id: String.t(),
            evidence_token: String.t(),
            source: source()
          }
  end
end
