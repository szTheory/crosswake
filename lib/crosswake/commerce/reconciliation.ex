defmodule Crosswake.Commerce.Reconciliation do
  @moduledoc """
  Typed backend-owned reconciliation vocabulary for commerce.
  
  This module encodes the canonical flow:
  1. Device/native evidence enters Phoenix.
  2. Phoenix records a reconciliation attempt.
  3. Host-owned workers verify it.
  4. Backend publishes a refreshed authoritative entitlement snapshot.
  
  These states represent reconciliation or freshness outcomes, not automatic access grants
  or silent denials. Device success is evidence, not entitlement.
  """

  @type outcome ::
          :pending_purchase
          | :pending_restore
          | :awaiting_verification
          | :projection_refreshed
          | :conflict
          | :verification_failed
          | :stale_authority

  def outcome_vocabulary do
    [
      :pending_purchase,
      :pending_restore,
      :awaiting_verification,
      :projection_refreshed,
      :conflict,
      :verification_failed,
      :stale_authority
    ]
  end

  defmodule Attempt do
    @moduledoc """
    A typed record of a backend-owned reconciliation attempt.
    """
    @enforce_keys [:provider, :provider_reference, :event_kind, :status]
    defstruct [:provider, :provider_reference, :event_kind, :status, :evidence_token, :correlation_id]

    @type t :: %__MODULE__{
            provider: atom(),
            provider_reference: String.t(),
            event_kind: atom(),
            status: Crosswake.Commerce.Reconciliation.outcome(),
            evidence_token: String.t() | nil,
            correlation_id: String.t() | nil
          }
  end

  defmodule IdempotencyKey do
    @moduledoc """
    Provider-aware and backend-owned idempotency fields.
    Transient device correlation ids are not part of this key.
    """
    @enforce_keys [:provider, :provider_reference, :event_kind]
    defstruct [:provider, :provider_reference, :event_kind]

    @type t :: %__MODULE__{
            provider: atom(),
            provider_reference: String.t(),
            event_kind: atom()
          }
  end

  defmodule EvidenceResult do
    @moduledoc """
    Represents an evidence-only result state for device purchase, restore, or native callback success.
    These states do not directly mutate entitlement authority.
    """
    @enforce_keys [:source, :status, :attempt]
    defstruct [:source, :status, :attempt]

    @type t :: %__MODULE__{
            source: atom(),
            status: atom(),
            attempt: Crosswake.Commerce.Reconciliation.Attempt.t()
          }
  end
end
