defmodule CrosswakeExample.RulesteadFlagSource do
  @moduledoc """
  The example host's own Rulestead flag source — a named `Agent` holding gate state.

  An adopter owns its flag source: the Rulestead adapter resolves it at runtime via
  `config :crosswake, :rulestead_flag_source, ...` (see config.exs) and calls `get_flag/1`.
  The `crosswake_rulestead` package ships only a *test-support* `MockFlagSource`, so the
  example provides this minimal demo implementation rather than depending on the package's
  test fixtures. A production host would back `get_flag/1` with its real flag service.

  Drive gate states in IEx (the LiveView at the gated route reflects them):

      alias CrosswakeExample.RulesteadFlagSource, as: Flags
      Flags.set_flag(:rulestead, :gated)              # -> :gate_denied denial
      Flags.set_flag(:rulestead, {:rolling_out, 50})  # -> :gate_denied (rolling out)
      Flags.set_flag(:rulestead, :killed)             # -> :kill_switch_active denial
      Flags.delete_flag(:rulestead)                   # clear flag
      Flags.reset()                                   # clear all flags
  """

  use Agent

  @name __MODULE__

  @type gate_state :: :gated | {:rolling_out, non_neg_integer()} | :killed

  @doc """
  Starts the flag-source Agent with an empty flag map.

  `_opts` is accepted (and ignored) so the module works as a supervisor child spec
  directly — `use Agent` generates `child_spec/1` which calls `start_link/1` with an arg.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: @name)
  end

  @doc "Sets the gate state (`:gated`, `{:rolling_out, n}`, or `:killed`) for `flag_key`."
  @spec set_flag(atom(), gate_state()) :: :ok
  def set_flag(flag_key, gate_state) when is_atom(flag_key) do
    Agent.update(@name, &Map.put(&1, flag_key, gate_state))
  end

  @doc "Returns the gate state for `flag_key`, or `nil` if not set. Called by the Rulestead adapter."
  @spec get_flag(atom()) :: gate_state() | nil
  def get_flag(flag_key) when is_atom(flag_key) do
    Agent.get(@name, &Map.get(&1, flag_key))
  end

  @doc "Removes the stored gate state for `flag_key`."
  @spec delete_flag(atom()) :: :ok
  def delete_flag(flag_key) when is_atom(flag_key) do
    Agent.update(@name, &Map.delete(&1, flag_key))
  end

  @doc "Resets all stored flag state to an empty map."
  @spec reset() :: :ok
  def reset do
    Agent.update(@name, fn _ -> %{} end)
  end
end
