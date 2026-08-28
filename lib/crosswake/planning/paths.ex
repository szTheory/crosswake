defmodule Crosswake.Planning.Paths do
  @moduledoc false

  @inactive_statuses ~w(complete completed parked parked_external_dependency)
  @workstream_name ~r/\A[a-z0-9][a-z0-9_-]*\z/

  @spec resolve!(Path.t(), keyword()) :: Path.t()
  def resolve!(cwd, opts \\ []) when is_binary(cwd) and is_list(opts) do
    case Keyword.get(opts, :planning_root) do
      nil -> resolve_default!(cwd)
      root when is_binary(root) -> expand(cwd, root)
    end
  end

  defp resolve_default!(cwd) do
    flat = Path.join(cwd, ".planning")

    cond do
      File.regular?(Path.join(flat, "STATE.md")) ->
        flat

      workstream = configured_workstream_root(cwd) ->
        workstream

      true ->
        resolve_from_workstreams!(cwd)
    end
  end

  defp configured_workstream_root(cwd) do
    with name when is_binary(name) <- System.get_env("GSD_WORKSTREAM"),
         true <- Regex.match?(@workstream_name, name),
         root = Path.join([cwd, ".planning", "workstreams", name]),
         true <- File.regular?(Path.join(root, "STATE.md")) do
      root
    else
      _ -> nil
    end
  end

  defp resolve_from_workstreams!(cwd) do
    roots =
      cwd
      |> Path.join(".planning/workstreams/*/STATE.md")
      |> Path.wildcard()
      |> Enum.map(&Path.dirname/1)
      |> Enum.sort()

    active = Enum.reject(roots, &inactive?/1)

    case {active, roots} do
      {[root], _} -> root
      {[], [root]} -> root
      {[], []} -> raise "Could not find a planning STATE.md in flat or workstream layout"
      _ -> raise "Could not choose an active planning workstream; pass :planning_root explicitly"
    end
  end

  defp inactive?(root) do
    status =
      root
      |> Path.join("STATE.md")
      |> File.read!()
      |> then(&Regex.run(~r/^status:\s*([^\s]+)\s*$/m, &1, capture: :all_but_first))

    match?([value] when value in @inactive_statuses, status)
  end

  defp expand(_cwd, root) when root == "", do: raise(ArgumentError, "planning_root is empty")
  defp expand(_cwd, "/" <> _ = root), do: Path.expand(root)
  defp expand(cwd, root), do: Path.expand(root, cwd)
end
