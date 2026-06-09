defmodule Crosswake.Threadline.Id do
  @moduledoc """
  RFC-4122 v4 UUID minting for Crosswake Threadline.
  """

  @doc """
  Generates a canonical 36-char hyphenated RFC-4122 v4 UUID.
  """
  @spec generate() :: String.t()
  def generate do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    raw = <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    
    hex = Base.encode16(raw, case: :lower)
    <<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>> = hex
    
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end
end
