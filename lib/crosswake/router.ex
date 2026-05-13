defmodule Crosswake.Router do
  @moduledoc """
  Phoenix-native router DSL for authoring Crosswake policy next to routes.
  """

  alias Crosswake.Policy.Merge
  alias Crosswake.Router.ScopeDefaults

  @metadata_key :crosswake
  @http_verbs [:get, :post, :put, :patch, :delete, :options, :head]

  defmacro __using__(_opts) do
    quote do
      use Phoenix.Router
      import Phoenix.Router,
        except: [
          get: 3,
          get: 4,
          post: 3,
          post: 4,
          put: 3,
          put: 4,
          patch: 3,
          patch: 4,
          delete: 3,
          delete: 4,
          options: 3,
          options: 4,
          head: 3,
          head: 4
        ]

      import Phoenix.LiveView.Router, except: [live: 2, live: 3, live: 4]
      import Crosswake.Router

      Crosswake.Router.ScopeDefaults.register(__MODULE__)
    end
  end

  defmacro crosswake_defaults(defaults, do: block) do
    evaluated_defaults = __eval_keyword!(defaults, __CALLER__)

    quote do
      Crosswake.Router.ScopeDefaults.push(
        __MODULE__,
        unquote(Macro.escape(evaluated_defaults))
      )

      unquote(block)
      Crosswake.Router.ScopeDefaults.pop(__MODULE__)
    end
  end

  for verb <- @http_verbs do
    defmacro unquote(verb)(path, controller, action, opts \\ []) do
      __http_route__(unquote(verb), __CALLER__, path, controller, action, opts)
    end
  end

  defmacro live(path, live_view) do
    __live_route__(__CALLER__, path, live_view, nil, [])
  end

  defmacro live(path, live_view, action_or_opts) do
    if __keyword_ast__?(action_or_opts) do
      __live_route__(__CALLER__, path, live_view, nil, action_or_opts)
    else
      __live_route__(__CALLER__, path, live_view, action_or_opts, [])
    end
  end

  defmacro live(path, live_view, action, opts) do
    __live_route__(__CALLER__, path, live_view, action, opts)
  end

  @doc false
  def __http_route__(verb, caller, path, controller, action, opts) do
    route_options = __route_options__(caller.module, opts, caller)

    quote do
      Phoenix.Router.unquote(verb)(
        unquote(path),
        unquote(controller),
        unquote(action),
        unquote(Macro.escape(route_options))
      )
    end
  end

  @doc false
  def __live_route__(caller, path, live_view, action, opts) do
    route_options = __route_options__(caller.module, opts, caller)

    quote do
      Phoenix.LiveView.Router.live(
        unquote(path),
        unquote(live_view),
        unquote(action),
        unquote(Macro.escape(route_options))
      )
    end
  end

  @doc false
  def __route_options__(module, opts_ast, caller) do
    opts = __eval_keyword!(opts_ast, caller)
    {crosswake_options, phoenix_options} = Keyword.pop(opts, :crosswake)

    if is_nil(crosswake_options) do
      phoenix_options
    else
      merged_crosswake =
        module
        |> ScopeDefaults.current()
        |> Merge.route_defaults(crosswake_options)

      metadata =
        phoenix_options
        |> Keyword.get(:metadata, %{})
        |> Map.put(@metadata_key, merged_crosswake)

      Keyword.put(phoenix_options, :metadata, metadata)
    end
  end

  @doc false
  def __eval_keyword__(ast, caller) do
    Code.eval_quoted(ast, [], caller)
  rescue
    error in [SyntaxError] -> reraise error, __STACKTRACE__
  end

  @doc false
  def __eval_keyword!(ast, caller) do
    {value, _binding} = __eval_keyword__(ast, caller)

    if Keyword.keyword?(value) do
      value
    else
      raise ArgumentError, "expected a keyword list for Crosswake router options, got: #{inspect(value)}"
    end
  end

  @doc false
  def __keyword_ast__?(ast) do
    case ast do
      list when is_list(list) -> Keyword.keyword?(list)
      _other -> false
    end
  end
end
