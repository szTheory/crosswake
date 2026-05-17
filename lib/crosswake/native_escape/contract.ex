defmodule Crosswake.NativeEscape.Contract do
  @moduledoc """
  Typed contract for Crosswake's single public native escape hatch: route-owned
  media capture with explicit local staging and explicit transfer handoff.
  """

  @protocol "crosswake.native_escape"
  @version "1.0.0"
  @purposes [:media_capture]
  @permission_postures [:required, :granted, :denied]
  @states [:captured_local, :transfer_complete]

  defmodule Request do
    @moduledoc false

    @enforce_keys [:protocol, :version, :route_id, :route_runtime, :purpose, :transfer_id, :permission_posture]
    defstruct [
      :protocol,
      :version,
      :route_id,
      :route_runtime,
      :purpose,
      :transfer_id,
      :permission_posture,
      media_types: []
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            route_id: String.t(),
            route_runtime: :native_screen | :live_view | :offline_island,
            purpose: :media_capture,
            transfer_id: String.t(),
            permission_posture: Contract.permission_posture(),
            media_types: [String.t()]
          }
  end

  defmodule LocalCapture do
    @moduledoc false

    @enforce_keys [:capture_id, :local_path, :media_type, :bytes]
    defstruct [:capture_id, :local_path, :media_type, :bytes]

    @type t :: %__MODULE__{
            capture_id: String.t(),
            local_path: String.t(),
            media_type: String.t(),
            bytes: non_neg_integer()
          }
  end

  defmodule TransferHandoff do
    @moduledoc false

    @enforce_keys [:transfer_id, :transfer_protocol, :transfer_version, :transfer_intent]
    defstruct [:transfer_id, :transfer_protocol, :transfer_version, :transfer_intent]

    @type t :: %__MODULE__{
            transfer_id: String.t(),
            transfer_protocol: String.t(),
            transfer_version: String.t(),
            transfer_intent: :upload
          }
  end

  defmodule Result do
    @moduledoc false

    @enforce_keys [:protocol, :version, :route_id, :state]
    defstruct [
      :protocol,
      :version,
      :route_id,
      :state,
      :local_capture,
      :transfer_handoff,
      :transfer_result
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            route_id: String.t(),
            state: Contract.state(),
            local_capture: Contract.local_capture() | nil,
            transfer_handoff: Contract.transfer_handoff() | nil,
            transfer_result: Crosswake.Transfer.Contracts.Result.t() | nil
          }
  end

  defmodule Denial do
    @moduledoc false

    @enforce_keys [:reason, :message]
    defstruct [:reason, :message]

    @type t :: %__MODULE__{
            reason: :native_screen_required | :undeclared_transfer_seam | :invalid_transfer_result,
            message: String.t()
          }
  end

  @type permission_posture :: :required | :granted | :denied
  @type state :: :captured_local | :transfer_complete
  @type request :: Request.t()
  @type local_capture :: LocalCapture.t()
  @type transfer_handoff :: TransferHandoff.t()
  @type result :: Result.t()
  @type denial :: Denial.t()

  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @spec version() :: String.t()
  def version, do: @version

  @spec purposes() :: [:media_capture]
  def purposes, do: @purposes

  @spec states() :: [state()]
  def states, do: @states

  @spec new_request(keyword()) :: request()
  def new_request(attrs) when is_list(attrs) do
    permission_posture = Keyword.fetch!(attrs, :permission_posture)

    unless permission_posture in @permission_postures do
      raise ArgumentError,
            "permission_posture must be one of #{inspect(@permission_postures)}, got: #{inspect(permission_posture)}"
    end

    struct!(Request, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      route_id: Keyword.fetch!(attrs, :route_id),
      route_runtime: Keyword.fetch!(attrs, :route_runtime),
      purpose: Keyword.get(attrs, :purpose, :media_capture),
      transfer_id: Keyword.fetch!(attrs, :transfer_id),
      permission_posture: permission_posture,
      media_types: Keyword.get(attrs, :media_types, [])
    })
  end

  @spec new_local_capture(keyword()) :: local_capture()
  def new_local_capture(attrs) when is_list(attrs) do
    struct!(LocalCapture, %{
      capture_id: Keyword.fetch!(attrs, :capture_id),
      local_path: Keyword.fetch!(attrs, :local_path),
      media_type: Keyword.fetch!(attrs, :media_type),
      bytes: Keyword.fetch!(attrs, :bytes)
    })
  end

  @spec new_transfer_handoff(keyword()) :: transfer_handoff()
  def new_transfer_handoff(attrs) when is_list(attrs) do
    struct!(TransferHandoff, %{
      transfer_id: Keyword.fetch!(attrs, :transfer_id),
      transfer_protocol: Keyword.fetch!(attrs, :transfer_protocol),
      transfer_version: Keyword.fetch!(attrs, :transfer_version),
      transfer_intent: Keyword.fetch!(attrs, :transfer_intent)
    })
  end

  @spec new_result(keyword()) :: result()
  def new_result(attrs) when is_list(attrs) do
    struct!(Result, %{
      protocol: Keyword.get(attrs, :protocol, @protocol),
      version: Keyword.get(attrs, :version, @version),
      route_id: Keyword.fetch!(attrs, :route_id),
      state: Keyword.fetch!(attrs, :state),
      local_capture: Keyword.get(attrs, :local_capture),
      transfer_handoff: Keyword.get(attrs, :transfer_handoff),
      transfer_result: Keyword.get(attrs, :transfer_result)
    })
  end

  @spec new_denial(keyword()) :: denial()
  def new_denial(attrs) when is_list(attrs) do
    struct!(Denial, %{
      reason: Keyword.fetch!(attrs, :reason),
      message: Keyword.fetch!(attrs, :message)
    })
  end
end
