defmodule Crosswake.Bridge.Commands.AppInfo do
  @moduledoc """
  Payload structs for app.info.get bridge command.
  """

  defmodule Request do
    @moduledoc false

    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Response do
    @moduledoc false

    @enforce_keys [:version, :build, :bundle_id]
    defstruct [:version, :build, :bundle_id]

    @type t :: %__MODULE__{
            version: String.t(),
            build: String.t(),
            bundle_id: String.t()
          }
  end
end
