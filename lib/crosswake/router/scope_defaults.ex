defmodule Crosswake.Router.ScopeDefaults do
  @moduledoc """
  Applies nested Crosswake defaults directly to router AST.
  """

  alias Crosswake.Policy.Merge

  @http_verbs [:get, :post, :put, :patch, :delete, :options, :head]

  @spec apply(Macro.t(), keyword(), Macro.Env.t()) :: Macro.t()
  def apply(block, defaults, caller) when is_list(defaults) do
    rewrite(block, defaults, caller)
  end

  defp rewrite({:__block__, meta, expressions}, defaults, caller) do
    {:__block__, meta, Enum.map(expressions, &rewrite(&1, defaults, caller))}
  end

  defp rewrite({:crosswake_defaults, meta, [nested_defaults_ast, [do: nested_block]]}, defaults, caller) do
    nested_defaults =
      nested_defaults_ast
      |> Crosswake.Router.__eval_keyword!(caller)
      |> Merge.route_defaults(defaults)

    {:crosswake_defaults, meta, [nested_defaults, [do: rewrite(nested_block, nested_defaults, caller)]]}
  end

  defp rewrite({verb, meta, args}, defaults, caller) when verb in @http_verbs do
    {path, controller, action, opts} = normalize_http_args(args)
    rewritten_opts = merge_route_opts(opts, defaults, caller)
    {verb, meta, [path, controller, action, rewritten_opts]}
  end

  defp rewrite({:live, meta, args}, defaults, caller) do
    rewritten_args =
      case normalize_live_args(args) do
        {path, live_view, nil, opts} ->
          [path, live_view, merge_route_opts(opts, defaults, caller)]

        {path, live_view, action, opts} ->
          [path, live_view, action, merge_route_opts(opts, defaults, caller)]
      end

    {:live, meta, rewritten_args}
  end

  defp rewrite(other, _defaults, _caller), do: other

  defp normalize_http_args([path, controller, action]), do: {path, controller, action, []}
  defp normalize_http_args([path, controller, action, opts]), do: {path, controller, action, opts}

  defp normalize_live_args([path, live_view]), do: {path, live_view, nil, []}

  defp normalize_live_args([path, live_view, action_or_opts]) do
    if Crosswake.Router.__keyword_ast__?(action_or_opts) do
      {path, live_view, nil, action_or_opts}
    else
      {path, live_view, action_or_opts, []}
    end
  end

  defp normalize_live_args([path, live_view, action, opts]), do: {path, live_view, action, opts}

  defp merge_route_opts(opts_ast, defaults, caller) do
    opts = Crosswake.Router.__eval_keyword!(opts_ast, caller)
    {crosswake, phoenix_opts} = Keyword.pop(opts, :crosswake)

    merged_crosswake =
      defaults
      |> Merge.route_defaults(crosswake || [])

    Keyword.put(phoenix_opts, :crosswake, merged_crosswake)
  end
end
