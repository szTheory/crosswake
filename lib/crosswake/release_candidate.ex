defmodule Crosswake.ReleaseCandidate do
  @moduledoc """
  Pure release-candidate evaluation and receipt authority.

  External adapters provide normalized observations. This module validates those observations,
  detects drift, and derives one closed release-candidate state without network or process access.
  """

  alias Crosswake.ReleaseCandidate.{Identity, Receipt}

  @input_keys ~w(identity observed_identity checks external_state credentials)a

  @spec evaluate!(map()) :: Receipt.t()
  def evaluate!(input) do
    unless is_map(input) and Enum.sort(Map.keys(input)) == Enum.sort(@input_keys), do: invalid!()

    Receipt.build!(%{
      identity: %{
        bound: Identity.normalize!(input.identity),
        observed: Identity.normalize!(input.observed_identity, consistent?: false)
      },
      checks: input.checks,
      external_state: input.external_state,
      credentials: input.credentials
    })
  rescue
    KeyError -> invalid!()
  end

  defp invalid!, do: raise(ArgumentError, "candidate receipt input is invalid")
end
