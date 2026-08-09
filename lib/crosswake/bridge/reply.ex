defmodule Crosswake.Bridge.Reply do
  @moduledoc """
  Adopter-facing typed reply delivered to `handle_info/2`.

  This is deliberately distinct from the wire-level `Crosswake.Bridge.Contract.Reply` —
  its `denial` field holds a `%Crosswake.Shell.Denial{}`, never the doubly-nested wire
  envelope (`Crosswake.Bridge.Denial`). An adopter's `handle_info/2` clause always
  pattern-matches on this struct, never on raw wire JSON (D-17).

  The field set is frozen deliberately: there is nowhere here to put an
  authority-carrying key, and no open metadata map is added. A future maintainer who
  wants to attach more context should add a named field with a typed value, not a
  free-form map.
  """

  alias Crosswake.Shell.Denial

  @enforce_keys [:status]
  defstruct [
    :command,
    :route_id,
    :status,
    payload: %{},
    denial: nil
  ]

  @type status :: :ok | :deny

  @type t :: %__MODULE__{
          command: String.t() | nil,
          route_id: String.t() | nil,
          status: status(),
          payload: map(),
          denial: Denial.t() | nil
        }
end
