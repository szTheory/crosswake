defmodule Crosswake.Router.ScopeDefaults do
  @moduledoc """
  Tracks nested Crosswake scope defaults while a router module compiles.
  """

  alias Crosswake.Policy.Merge

  @attribute :crosswake_scope_defaults_stack

  @spec register(module()) :: :ok
  def register(module) when is_atom(module) do
    Module.register_attribute(module, @attribute, persist: false)
    Module.put_attribute(module, @attribute, [])
    :ok
  end

  @spec push(module(), keyword()) :: :ok
  def push(module, defaults) when is_atom(module) and is_list(defaults) do
    stack = Module.get_attribute(module, @attribute) || []
    Module.put_attribute(module, @attribute, [defaults | stack])
    :ok
  end

  @spec pop(module()) :: :ok
  def pop(module) when is_atom(module) do
    stack = Module.get_attribute(module, @attribute) || []

    next_stack =
      case stack do
        [_current | rest] -> rest
        [] -> []
      end

    Module.put_attribute(module, @attribute, next_stack)
    :ok
  end

  @spec current(module()) :: keyword()
  def current(module) when is_atom(module) do
    module
    |> Module.get_attribute(@attribute)
    |> List.wrap()
    |> Enum.reverse()
    |> Enum.reduce([], &Merge.route_defaults/2)
  end
end
