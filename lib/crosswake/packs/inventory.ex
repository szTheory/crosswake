defmodule Crosswake.Packs.Inventory do
  @moduledoc """
  Installed-pack inventory truth consumed by activation, compatibility, and shell UI.
  """

  @type integrity_status :: :verified | :pending | :failed
  @type status :: :available | :invalidating
  @type last_known_state :: %{required(:state) => atom(), required(:version) => String.t()}

  @enforce_keys [
    :pack_id,
    :required_version,
    :installed_version,
    :bytes,
    :integrity_status
  ]
  defstruct [
    :pack_id,
    :required_version,
    :installed_version,
    :bytes,
    :integrity_status,
    :verified_at,
    status: :available,
    invalidation_reason: nil,
    invalidated_at: nil,
    last_known_state: nil
  ]

  @type t :: %__MODULE__{
          pack_id: String.t(),
          required_version: String.t(),
          installed_version: String.t(),
          bytes: non_neg_integer(),
          integrity_status: integrity_status(),
          verified_at: DateTime.t() | nil,
          status: status(),
          invalidation_reason: atom() | nil,
          invalidated_at: DateTime.t() | nil,
          last_known_state: last_known_state() | nil
        }

  @spec record(keyword()) :: t()
  def record(attrs) when is_list(attrs) do
    struct!(__MODULE__, %{
      pack_id: Keyword.fetch!(attrs, :pack_id),
      required_version: Keyword.fetch!(attrs, :required_version),
      installed_version: Keyword.fetch!(attrs, :installed_version),
      bytes: Keyword.fetch!(attrs, :bytes),
      integrity_status: Keyword.fetch!(attrs, :integrity_status),
      verified_at: Keyword.get(attrs, :verified_at),
      status: Keyword.get(attrs, :status, :available),
      invalidation_reason: Keyword.get(attrs, :invalidation_reason),
      invalidated_at: Keyword.get(attrs, :invalidated_at),
      last_known_state: Keyword.get(attrs, :last_known_state)
    })
  end
end
