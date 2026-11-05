defmodule Crosswake.Guides.IOSHostDocValuesTest do
  @moduledoc """
  The documented `:ios_host` declaration is checked by the current validator (T-197-19).

  The published-cleanroom docs leg defers the `:ios_host` block against crosswake 0.2.11,
  which does not read that setting yet (D-04 amendment), so nothing else in Phase 197
  executes it. This network-free test reads the values out of the ios-host block of
  `guides/install.md` and of `README.md` (never from a literal in this file), swaps only the
  placeholder `MyAppWeb.Router` for a compiled fixture router, and requires
  `Crosswake.Shell.IOSHostConfig.normalize/2` to accept them with `env: :prod`.

  `normalize/2` checks only that `entry_route_id` is non-empty; that the documented router
  declares that route is covered by the route-id consistency rule of
  `cleanroom_doc_markers_test.exs` and, at generation time, by
  `Crosswake.Shell.IOSHostGeneration`.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  @docs [readme: "README.md", install: "guides/install.md"]
  @placeholder_router MyAppWeb.Router

  test "each doc has exactly one :ios_host block, and the two declare equal values" do
    readme = values!(File.read!(@docs[:readme]))
    install = values!(File.read!(@docs[:install]))

    assert readme == install
    assert Keyword.fetch!(install, :router) == @placeholder_router

    assert Enum.sort(Keyword.keys(install)) ==
             Enum.sort(IOSHostConfig.__struct__() |> required_keys())
  end

  test "the documented values are accepted by the current IOSHostConfig with env: :prod" do
    for {file, path} <- @docs do
      values = path |> File.read!() |> values!() |> Keyword.put(:router, ManagedRouter)

      assert {:ok, %IOSHostConfig{} = config} = IOSHostConfig.normalize(values, env: :prod),
             "#{file}: the documented :ios_host values were rejected"

      assert config.router == ManagedRouter
      assert config.entry_route_id == Keyword.fetch!(values, :entry_route_id)
    end
  end

  test "control: a documented origin that gains a path is rejected" do
    install = File.read!(@docs[:install])
    origin = install |> values!() |> Keyword.fetch!(:origin)

    mutated = mutate!(install, ~s("#{origin}"), ~s("#{origin}/x"))
    values = mutated |> values!() |> Keyword.put(:router, ManagedRouter)

    assert String.ends_with?(Keyword.fetch!(values, :origin), "/x")
    assert {:error, _reason} = IOSHostConfig.normalize(values, env: :prod)
  end

  test "control: a proof bundle id equal to the app bundle id is rejected" do
    install = File.read!(@docs[:install])
    values = values!(install)
    app = Keyword.fetch!(values, :app_bundle_id)
    proof = Keyword.fetch!(values, :proof_app_bundle_id)
    key = Atom.to_string(:proof_app_bundle_id) <> ": "

    mutated = mutate!(install, key <> ~s("#{proof}"), key <> ~s("#{app}"))
    collided = mutated |> values!() |> Keyword.put(:router, ManagedRouter)

    assert Keyword.fetch!(collided, :proof_app_bundle_id) == app
    assert {:error, _reason} = IOSHostConfig.normalize(collided, env: :prod)
  end

  test "the extraction refuses a declaration that is not literal-only" do
    install = File.read!(@docs[:install])
    block = ios_host_fence!(install)
    poisoned = String.replace(block, ~s[origin: "], ~s[origin: System.get_env("X") <> "])

    assert poisoned != block

    assert_raise RuntimeError, ~r/not literal-only/, fn ->
      values!(String.replace(install, block, poisoned))
    end
  end

  # --- extraction ---------------------------------------------------------------------

  defp required_keys(struct) do
    struct |> Map.keys() |> Enum.reject(&(&1 in [:__struct__, :origin_mode]))
  end

  defp mutate!(text, from, to) do
    mutated = String.replace(text, from, to, global: false)

    if mutated == text do
      raise "the mutation changed nothing; the control would assert nothing"
    end

    mutated
  end

  # The body of the one fence that holds `config :crosswake, :ios_host`.
  defp ios_host_fence!(text) do
    bodies =
      ~r/^```[a-z]*\r?\n(.*?)^```\s*$/ms
      |> Regex.scan(text, capture: :all_but_first)
      |> List.flatten()
      |> Enum.filter(&String.contains?(&1, "config :crosswake, :ios_host"))

    case bodies do
      [body] -> body
      other -> raise "expected exactly one :ios_host block, found #{length(other)}"
    end
  end

  defp values!(text) do
    ast = text |> ios_host_fence!() |> Code.string_to_quoted!()

    {:config, _, [:crosswake, :ios_host, kw_ast]} = ast

    literal_only!(kw_ast)
    {values, _binding} = Code.eval_quoted(kw_ast)
    values
  end

  # No calls, no operators: only literals, lists, pairs, atoms and module aliases, so
  # evaluating the quoted value runs no code.
  defp literal_only!(ast) when is_atom(ast) or is_binary(ast) or is_number(ast), do: :ok
  defp literal_only!(list) when is_list(list), do: Enum.each(list, &literal_only!/1)

  defp literal_only!({left, right}) do
    literal_only!(left)
    literal_only!(right)
  end

  defp literal_only!({:__aliases__, _meta, parts} = ast) when is_list(parts) do
    if Enum.all?(parts, &is_atom/1), do: :ok, else: raise("not literal-only: #{inspect(ast)}")
  end

  defp literal_only!(other), do: raise("not literal-only: #{Macro.to_string(other)}")
end
