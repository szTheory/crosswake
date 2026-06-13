defmodule Crosswake.Offline.ContentPack do
  @moduledoc """
  Data structure representing an offline content pack.
  """

  @derive Jason.Encoder
  @enforce_keys [:id, :version, :kind]
  defstruct [:id, :version, :kind, :integrity, assets: [], data_payloads: []]

  @type t :: %__MODULE__{
          id: String.t(),
          version: String.t(),
          kind: atom(),
          integrity: map() | nil,
          assets: [String.t()],
          data_payloads: [String.t()]
        }
end
