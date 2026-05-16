defmodule Crosswake.Doctor.Check do
  @moduledoc """
  Structured doctor finding.
  """

  @enforce_keys [:severity, :code, :message, :check]
  defstruct [:severity, :code, :message, :hint, :check, details: %{}]

  @type severity :: :error | :warning | :advisory

  @type t :: %__MODULE__{
          severity: severity(),
          code: String.t(),
          message: String.t(),
          hint: String.t() | nil,
          check: String.t(),
          details: map()
        }
end
