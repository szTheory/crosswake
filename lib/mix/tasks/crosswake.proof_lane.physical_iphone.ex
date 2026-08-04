defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphone do
  use Mix.Task

  alias Crosswake.ProofLane.{PhysicalIphoneContract, PhysicalIphonePreflight}

  @shortdoc "Runs the host-owned physical-iPhone proof only after closed preflight"
  @switches [preflight_only: :boolean, run: :boolean, json: :boolean]

  @impl Mix.Task
  def run(args) do
    case run_with(args, []) do
      {:ready, contract} ->
        emit(%{outcome: "ready", schema_version: contract.schema_version})

      {:passed, candidate} ->
        emit(candidate)

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

    if positional != [] or invalid != [] or parsed[:json] != true or invalid_mode?(parsed) do
      {:error, "PI-COMMAND-OPTIONS"}
    else
      case PhysicalIphonePreflight.check(options) do
        {:ready, contract} ->
          if parsed[:preflight_only] == true,
            do: {:ready, contract},
            else: invoke_runner(contract, options)

        {:blocked, rule_id} ->
          {:blocked, %{outcome: "blocked", rule_id: rule_id}}
      end
    end
  end

  def run_with(_, _), do: {:error, "PI-COMMAND-OPTIONS"}

  defp invalid_mode?(parsed), do: parsed[:preflight_only] == true == (parsed[:run] == true)

  defp invoke_runner(contract, options) do
    with {:ok, device_report} <- report_from(options, :device_report, contract),
         {:ok, backend_report} <- report_from(options, :backend_report, contract),
         {:ok, candidate} <- join_reports(contract, device_report, backend_report) do
      {:passed, candidate}
    else
      {:error, rule_id} -> {:blocked, %{outcome: "blocked", rule_id: rule_id}}
    end
  end

  defp report_from(options, name, contract) do
    case Keyword.get(options, name) do
      callback when is_function(callback, 1) ->
        try do
          case callback.(contract) do
            report when is_list(report) -> {:ok, report}
            _ -> {:error, "PI-REPORT-#{report_name(name)}"}
          end
        rescue
          _ -> {:error, "PI-REPORT-#{report_name(name)}"}
        catch
          _, _ -> {:error, "PI-REPORT-#{report_name(name)}"}
        end

      _ ->
        {:error, "PI-REPORT-#{report_name(name)}"}
    end
  end

  defp join_reports(contract, device_report, backend_report) do
    report = device_report ++ backend_report

    cond do
      not owned_by?(device_report, :device_local) or
          not owned_by?(backend_report, :backend_authority) ->
        {:error, "PI-REPORT-OWNER"}

      PhysicalIphoneContract.validate_report(report) != :ok ->
        {:error, "PI-REPORT-COMPLETE"}

      not Enum.all?(report, &(&1.outcome == :passed)) ->
        {:error, "PI-REPORT-OUTCOME"}

      true ->
        {:ok,
         %{
           outcome: "passed",
           schema_version: contract.schema_version,
           device_class: Atom.to_string(contract.device_class),
           assertions: Enum.map(report, &Map.take(&1, [:id, :owner, :outcome]))
         }}
    end
  end

  defp owned_by?(report, owner) do
    Enum.all?(report, fn
      %{owner: ^owner} -> true
      _ -> false
    end)
  end

  defp report_name(:device_report), do: "DEVICE"
  defp report_name(:backend_report), do: "BACKEND"

  defp emit(result), do: IO.puts(Jason.encode!(result))
end
