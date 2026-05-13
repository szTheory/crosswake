defmodule Crosswake.Policy.Merge do
  @moduledoc """
  Merge helpers for router-authored Crosswake policy.
  """

  @spec route_defaults(keyword(), keyword()) :: keyword()
  def route_defaults(defaults, route_options)
      when is_list(defaults) and is_list(route_options) do
    Keyword.merge(defaults, route_options, fn _key, _default, route_value -> route_value end)
  end
end
