defmodule Crosswake.Bridge.Commands.Share do
  @moduledoc """
  Payload structs for share.invoke bridge command.
  """

  defmodule Request do
    @moduledoc false

    defstruct [:url, :text, :title]

    @type t :: %__MODULE__{
            url: String.t() | nil,
            text: String.t() | nil,
            title: String.t() | nil
          }
  end
end
