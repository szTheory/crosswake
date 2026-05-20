defmodule Crosswake.Bridge.Commands.Haptics do
  @moduledoc """
  Payload structs for haptics.impact bridge command.
  """

  defmodule Request do
    @moduledoc false

    @enforce_keys [:style]
    defstruct [:style]

    @type t :: %__MODULE__{
            style: String.t()
          }
  end
end
