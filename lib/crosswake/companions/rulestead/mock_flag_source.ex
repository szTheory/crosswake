defmodule Crosswake.Companions.Rulestead.MockFlagSource do
  @moduledoc """
  Named Agent storing flag state for local dev and hermetic proof tests.

  This module is mock-only for Phase 42. Production code uses `Rulestead.Snapshot`
  to read flag values from the real rulestead library — that adapter is deferred
  to Phase 43.

  State is a plain map of `%{flag_atom => gate_state}`. The Agent is registered
  under its module name so it is reachable via `Process.whereis/1`.
  """

  use Agent

  @name __MODULE__

  @type gate_state :: :gated | {:rolling_out, non_neg_integer()} | :killed

  @doc """
  Starts the MockFlagSource Agent with an empty flag map.

  The `_opts` argument is accepted (and ignored) so the module can be used as a
  supervisor child spec directly — `use Agent` generates `child_spec/1` which
  calls `start_link/1` with an arg.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: @name)
  end

  @doc """
  Sets the gate state for the given flag key.

  `gate_state` must be `:gated`, `{:rolling_out, n}`, or `:killed`.
  """
  @spec set_flag(atom(), gate_state()) :: :ok
  def set_flag(flag_key, gate_state) when is_atom(flag_key) do
    Agent.update(@name, &Map.put(&1, flag_key, gate_state))
  end

  @doc """
  Returns the gate state for the given flag key, or `nil` if not set.
  """
  @spec get_flag(atom()) :: gate_state() | nil
  def get_flag(flag_key) when is_atom(flag_key) do
    Agent.get(@name, &Map.get(&1, flag_key))
  end

  @doc """
  Resets all stored flag state to an empty map.

  Useful for test cleanup between runs. Callers using `start_supervised!/1` in
  ExUnit setup get a fresh Agent per test automatically, making `reset/0` a
  belt-and-suspenders option.
  """
  @spec reset() :: :ok
  def reset do
    Agent.update(@name, fn _ -> %{} end)
  end
end
