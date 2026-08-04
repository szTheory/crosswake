defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphone do
  use Mix.Task

  alias Crosswake.ProofLane.PhysicalIphonePreflight

  @shortdoc "Runs the host-owned physical-iPhone proof only after closed preflight"
  @switches [preflight_only: :boolean, json: :boolean]

  @impl Mix.Task
  def run(args) do
    case run_with(args, []) do
      {:ready, contract} ->
        emit(%{outcome: "ready", schema_version: contract.schema_version})

      {:blocked, result} ->
        emit(result)
        System.halt(2)

      {:error, rule} ->
        emit(%{outcome: "blocked", rule_id: rule})
        System.halt(2)
    end
  end

  @spec run_with([String.t()], keyword()) ::
          {:ready, map()} | {:blocked, map()} | {:error, String.t()}
  def run_with(args, options) when is_list(args) and is_list(options) do
    {parsed, positional, invalid} = OptionParser.parse(args, strict: @switches)

    if positional != [] or invalid != [] or parsed[:json] != true or
         parsed[:preflight_only] != true do
      {:error, "PI-COMMAND-OPTIONS"}
    else
      case PhysicalIphonePreflight.check(options) do
        {:ready, contract} -> invoke_runner(contract, options)
        {:blocked, rule_id} -> {:blocked, %{outcome: "blocked", rule_id: rule_id}}
      end
    end
  end

  def run_with(_, _), do: {:error, "PI-COMMAND-OPTIONS"}

  defp invoke_runner(contract, options) do
    case Keyword.get(options, :runner) do
      nil ->
        {:ready, contract}

      runner when is_function(runner, 1) ->
        try do
          runner.(contract)
          {:ready, contract}
        rescue
          _ -> {:blocked, %{outcome: "blocked", rule_id: "PI-RUNNER"}}
        catch
          _, _ -> {:blocked, %{outcome: "blocked", rule_id: "PI-RUNNER"}}
        end

      _ ->
        {:blocked, %{outcome: "blocked", rule_id: "PI-RUNNER"}}
    end
  end

  defp emit(result), do: IO.puts(Jason.encode!(result))
end
