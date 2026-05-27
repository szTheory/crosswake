defmodule Crosswake.Policy.Defaults do
  @moduledoc """
  Canonical defaults for Phase 1 route policy declarations.
  """

  @route [
    offline: :unavailable,
    entry: :internal_only,
    capabilities: [],
    packs: [],
    sync: []
  ]

  @spec route() :: keyword()
  def route, do: @route
end
