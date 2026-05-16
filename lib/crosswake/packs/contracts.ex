defmodule Crosswake.Packs.Contracts do
  @moduledoc """
  Typed pack lifecycle vocabulary shared across activation, shell UI, and proof lanes.
  """

  alias Crosswake.Packs.Inventory

  @type state ::
          :checking | :not_installed | :installing | :available | :stale | :invalidating | :failed
  @type install_stage :: :preparing | :downloading | :verifying | :installing

  defmodule Verification do
    @moduledoc false

    defstruct [:integrity_status, :verified_at]

    @type t :: %__MODULE__{
            integrity_status: Inventory.integrity_status() | nil,
            verified_at: DateTime.t() | nil
          }
  end

  defmodule Install do
    @moduledoc false

    @enforce_keys [:stage]
    defstruct [:stage]

    @type t :: %__MODULE__{stage: Contracts.install_stage()}
  end

  defmodule Failure do
    @moduledoc false

    @enforce_keys [:reason]
    defstruct [:reason, :retry_hint]

    @type t :: %__MODULE__{
            reason: atom(),
            retry_hint: atom() | nil
          }
  end

  defmodule Invalidation do
    @moduledoc false

    @enforce_keys [:reason, :invalidated_at]
    defstruct [:reason, :invalidated_at]

    @type t :: %__MODULE__{
            reason: atom(),
            invalidated_at: DateTime.t()
          }
  end

  @enforce_keys [:state, :pack_id, :required_version]
  defstruct [
    :state,
    :pack_id,
    :required_version,
    :version,
    :bytes,
    :verification,
    :install,
    :stale_reason,
    :failure,
    :invalidation,
    :last_known_state
  ]

  @type t :: %__MODULE__{
          state: state(),
          pack_id: String.t(),
          required_version: String.t(),
          version: String.t() | nil,
          bytes: non_neg_integer() | nil,
          verification: Verification.t() | nil,
          install: Install.t() | nil,
          stale_reason: atom() | nil,
          failure: Failure.t() | nil,
          invalidation: Invalidation.t() | nil,
          last_known_state: %{required(:state) => atom(), required(:version) => String.t()} | nil
        }

  @spec available(keyword()) :: t()
  def available(attrs) when is_list(attrs) do
    base(attrs, :available)
    |> Map.put(:version, Keyword.fetch!(attrs, :installed_version))
    |> Map.put(:bytes, Keyword.fetch!(attrs, :bytes))
    |> Map.put(:verification, verification(attrs))
    |> then(&struct!(__MODULE__, &1))
  end

  @spec installing(keyword()) :: t()
  def installing(attrs) when is_list(attrs) do
    base(attrs, :installing)
    |> Map.put(:install, struct!(Install, %{stage: Keyword.fetch!(attrs, :stage)}))
    |> then(&struct!(__MODULE__, &1))
  end

  @spec stale(keyword()) :: t()
  def stale(attrs) when is_list(attrs) do
    base(attrs, :stale)
    |> Map.put(:version, Keyword.fetch!(attrs, :installed_version))
    |> Map.put(:bytes, Keyword.fetch!(attrs, :bytes))
    |> Map.put(:verification, verification(attrs))
    |> Map.put(:stale_reason, Keyword.fetch!(attrs, :stale_reason))
    |> then(&struct!(__MODULE__, &1))
  end

  @spec failed(keyword()) :: t()
  def failed(attrs) when is_list(attrs) do
    base(attrs, :failed)
    |> Map.put(
      :failure,
      struct!(Failure, %{
        reason: Keyword.fetch!(attrs, :failure_reason),
        retry_hint: Keyword.get(attrs, :retry_hint)
      })
    )
    |> then(&struct!(__MODULE__, &1))
  end

  @spec not_installed(keyword()) :: t()
  def not_installed(attrs) when is_list(attrs) do
    base(attrs, :not_installed)
    |> then(&struct!(__MODULE__, &1))
  end

  @spec from_inventory(Inventory.t()) :: t()
  def from_inventory(%Inventory{} = record) do
    available(
      pack_id: record.pack_id,
      required_version: record.required_version,
      installed_version: record.installed_version,
      bytes: record.bytes,
      integrity_status: record.integrity_status,
      verified_at: record.verified_at
    )
  end

  @spec invalidate(t(), keyword()) :: t()
  def invalidate(%__MODULE__{} = lifecycle, attrs) when is_list(attrs) do
    struct!(lifecycle, %{
      state: :invalidating,
      invalidation:
        struct!(Invalidation, %{
          reason: Keyword.fetch!(attrs, :reason),
          invalidated_at: Keyword.fetch!(attrs, :invalidated_at)
        }),
      last_known_state: %{state: lifecycle.state, version: lifecycle.version}
    })
  end

  defp base(attrs, state) do
    %{
      state: state,
      pack_id: Keyword.fetch!(attrs, :pack_id),
      required_version: Keyword.fetch!(attrs, :required_version)
    }
  end

  defp verification(attrs) do
    struct!(Verification, %{
      integrity_status: Keyword.get(attrs, :integrity_status),
      verified_at: Keyword.get(attrs, :verified_at)
    })
  end
end
