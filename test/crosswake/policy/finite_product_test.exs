defmodule Crosswake.Policy.FiniteProductTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Validator

  # Independent specification: these nine cells are intentionally literal.
  @runtime_offline_keys %{
    {:live_view, :unavailable} => [],
    {:live_view, :cached_read_only} => [],
    {:live_view, :local_first} => [:offline],
    {:offline_island, :unavailable} => [:offline],
    {:offline_island, :cached_read_only} => [],
    {:offline_island, :local_first} => [],
    {:native_screen, :unavailable} => [],
    {:native_screen, :cached_read_only} => [],
    {:native_screen, :local_first} => []
  }

  test "108 unique normalized semantic cases match the independent aggregate oracle" do
    cases = product()
    assert length(cases) == 108
    assert MapSet.size(MapSet.new(cases)) == 108
    assert map_size(@runtime_offline_keys) == 9

    completed =
      cases
      |> Enum.with_index(1)
      |> Enum.reduce(0, fn {policy, index}, completed ->
        id = "semantic-#{index}"
        {runtime, offline, entry, security, sync} = policy

        # Direct normalized structs deliberately bypass Route.new's early entry rejection.
        route = %Route{
          id: id,
          runtime: runtime,
          offline: offline,
          entry: entry,
          security: security,
          sync: sync
        }

        errors = Validator.validate([route], [%{}], host_commands: [])
        assert pairs(errors) == expected_pairs(semantic_keys(policy), id)
        completed + 1
      end)

    assert completed == 108
  end

  test "108 unique compiler cases follow the independent early-entry staging rule" do
    cases = product()
    assert length(cases) == 108
    assert MapSet.size(MapSet.new(cases)) == 108

    completed =
      cases
      |> Enum.with_index(1)
      |> Enum.reduce(0, fn {policy, index}, completed ->
        id = "compiled-#{index}"
        {runtime, offline, entry, security, sync} = policy
        options = [id: id, runtime: runtime, offline: offline, entry: entry]
        options = if sync == [], do: options, else: options ++ [sync: sync]
        options = if is_nil(security), do: options, else: options ++ [security: security]

        # Route.new rejects external islands before semantic aggregation can run.
        keys =
          if runtime == :offline_island and entry == :external,
            do: [:entry],
            else: semantic_keys(policy)

        actual =
          case Compiler.compile([%{metadata: %{crosswake: options}}]) do
            {:ok, %{routes: [%Route{id: ^id}], warnings: []}} -> []
            {:error, %{errors: errors, warnings: []}} -> pairs(errors)
          end

        assert actual == expected_pairs(keys, id)
        completed + 1
      end)

    assert completed == 108
  end

  defp product do
    for runtime <- [:live_view, :offline_island, :native_screen],
        offline <- [:unavailable, :cached_read_only, :local_first],
        entry <- [:internal_only, :external],
        security <- [nil, :standard, :sensitive],
        sync <- [[], ["synthetic_sync"]],
        do: {runtime, offline, entry, security, sync}
  end

  defp semantic_keys({runtime, offline, entry, security, sync}) do
    runtime_offline = Map.fetch!(@runtime_offline_keys, {runtime, offline})
    entry_keys = if runtime == :offline_island and entry == :external, do: [:entry], else: []
    sync_keys = if offline == :unavailable and sync != [], do: [:sync], else: []

    security_keys =
      if is_nil(security) and
           (offline != :unavailable or entry == :external or sync != []),
         do: [:security],
         else: []

    runtime_offline ++ entry_keys ++ sync_keys ++ security_keys
  end

  defp expected_pairs(keys, id), do: Enum.sort(Enum.map(keys, &{&1, id}))
  defp pairs(errors), do: Enum.sort(Enum.map(errors, &{&1.key, &1.route_id}))
end
