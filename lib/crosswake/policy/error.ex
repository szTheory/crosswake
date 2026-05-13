defmodule Crosswake.Policy.Error do
  @moduledoc """
  Structured compile-time route policy error with route-local context.
  """

  @enforce_keys [:message]
  defstruct [
    :message,
    :hint,
    :key,
    :path,
    :helper,
    :verb,
    :route_id,
    :file,
    :line
  ]

  @type t :: %__MODULE__{
          message: String.t(),
          hint: String.t() | nil,
          key: atom() | nil,
          path: String.t() | nil,
          helper: String.t() | nil,
          verb: atom() | nil,
          route_id: String.t() | nil,
          file: String.t() | nil,
          line: pos_integer() | nil
        }
end
