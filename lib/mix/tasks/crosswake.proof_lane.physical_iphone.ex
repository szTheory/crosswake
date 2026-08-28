defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphone do
  use Mix.Task

  alias Crosswake.ProofLane.{
    Evidence,
    PhysicalIphoneContract,
    PhysicalIphoneHost,
    PhysicalIphonePreflight
  }

  @shortdoc "Runs the host-owned physical-iPhone proof only after closed preflight"
  @switches [
    preflight_only: :boolean,
    readiness: :boolean,
    run: :boolean,
    promote: :boolean,
    json: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    # The command's stdout is a machine interface. Load project configuration,
    # then suppress normal host startup chatter before starting the configured
    # application; callbacks still fail closed to stable PI rules.
    Mix.Task.run("app.config")
    Application.put_env(:logger, :level, :warning)
    Logger.configure(level: :warning)

    # A local host may derive its private LAN endpoint and configure its endpoint
    # before the application starts. This remains an optional host capability so
    # remote hosts and generated adapters keep their existing contract.
    host = PhysicalIphoneHost.load()

    if prepare_host(host) == :ok do
      Mix.Task.run("app.start")
    end

    options =
      case host do
        {:ok, loaded} -> host_options(loaded)
        {:error, _} -> []
      end

    case run_with(args, options) do
      {:ready, contract} ->
        emit(%{outcome: "ready", schema_version: contract.schema_version})

      {:readiness, result} ->
        emit(result)
        if result.outcome == "blocked", do: System.halt(2)

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
      if parsed[:readiness] == true do
        {:readiness, readiness_result(options)}
      else
        case PhysicalIphonePreflight.check(options) do
          {:ready, contract} ->
            if parsed[:preflight_only] == true,
              do: {:ready, contract},
              else:
                invoke_runner(contract, Keyword.put(options, :promote, parsed[:promote] == true))

          {:blocked, rule_id} ->
            {:blocked, %{outcome: "blocked", rule_id: rule_id}}
        end
      end
    end
  end

  def run_with(_, _), do: {:error, "PI-COMMAND-OPTIONS"}

  @doc false
  @spec parse_report(binary(), :device_local | :backend_authority) ::
          {:ok, [map()]} | {:error, String.t()}
  def parse_report(bytes, slot)
      when is_binary(bytes) and slot in [:device_local, :backend_authority] do
    with {:ok, envelope} <- decode_exact_envelope(bytes),
         :ok <- valid_envelope_header(envelope),
         {:ok, entries} <- exact_entries(envelope["assertions"], slot) do
      {:ok, entries}
    end
  end

  def parse_report(_, _), do: {:error, "PI-REPORT-ENVELOPE"}

  @doc false
  @spec join_report_entries([map()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def join_report_entries(device_entries, backend_entries) do
    contract = %{
      schema_version: PhysicalIphoneContract.schema_version(),
      device_class: PhysicalIphoneContract.device_class()
    }

    join_reports(contract, device_entries, backend_entries)
  end

  defp invalid_mode?(parsed) do
    Enum.count([:preflight_only, :readiness, :run], &(parsed[&1] == true)) != 1 or
      (parsed[:promote] == true and parsed[:run] != true)
  end

  defp readiness_result(options) do
    PhysicalIphonePreflight.readiness(options)
    |> Map.update!(:outcome, &Atom.to_string/1)
    |> Map.update!(:checks, fn checks ->
      Enum.map(checks, &Map.update!(&1, :state, fn state -> Atom.to_string(state) end))
    end)
  end

  defp invoke_runner(contract, options) do
    try do
      try do
        with {:ok, device_report} <- report_from(options, :device_report, contract),
             {:ok, backend_report} <- report_from(options, :backend_report, contract),
             {:ok, candidate} <- join_reports(contract, device_report, backend_report),
             {:ok, result} <- promote_if_requested(candidate, options) do
          {:passed, result}
        else
          {:error, rule_id} -> {:blocked, %{outcome: "blocked", rule_id: rule_id}}
        end
      after
        if cleanup_run(options) != :ok, do: throw(:physical_iphone_cleanup_failed)
      end
    catch
      :throw, :physical_iphone_cleanup_failed ->
        {:blocked, %{outcome: "blocked", rule_id: "PI-HOST-CLEANUP"}}
    end
  end

  defp cleanup_run(options) do
    case Keyword.get(options, :cleanup_run) do
      callback when is_function(callback, 0) ->
        try do
          if callback.() == :ok, do: :ok, else: :error
        rescue
          _ -> :error
        catch
          _, _ -> :error
        end

      _ ->
        :ok
    end
  end

  defp host_options(host) do
    case host[:inventory_and_checks].() do
      options when is_list(options) -> Keyword.drop(host, [:inventory_and_checks]) ++ options
      _ -> []
    end
  end

  defp prepare_host({:ok, host}) do
    case host[:prepare_for_run].() do
      :ok -> :ok
      _ -> :blocked
    end
  end

  defp prepare_host({:error, _}), do: :ok

  defp promote_if_requested(candidate, options) do
    if Keyword.get(options, :promote, false) do
      with callback when is_function(callback, 1) <- Keyword.get(options, :evidence_input),
           destination when is_function(destination, 0) <-
             Keyword.get(options, :evidence_destination),
           input when is_map(input) <- callback.(candidate),
           path when is_binary(path) <- destination.(),
           :ok <- Evidence.promote(input, path),
           :ok <- Evidence.check(path, Map.get(input, :approved_hashes, [])) do
        {:ok,
         Map.put(
           candidate,
           :assertions,
           candidate.assertions ++
             [%{id: "PI-REDACTED-PROMOTION", owner: :evidence_promotion, outcome: :passed}]
         )}
      else
        _ -> {:error, "PI-PROMOTION"}
      end
    else
      {:ok, candidate}
    end
  end

  defp report_from(options, name, contract) do
    case Keyword.get(options, name) do
      callback when is_function(callback, 1) ->
        try do
          case callback.(contract) do
            report when is_list(report) -> {:ok, report}
            report when is_binary(report) -> parse_report(report, slot_for(name))
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

  defp slot_for(:device_report), do: :device_local
  defp slot_for(:backend_report), do: :backend_authority

  defp join_reports(contract, device_report, backend_report) do
    report = device_report ++ backend_report

    expected =
      PhysicalIphoneContract.assertions()
      |> Enum.reject(&(&1.owner == :evidence_promotion))

    cond do
      not owned_by?(device_report, :device_local) or
          not owned_by?(backend_report, :backend_authority) ->
        {:error, "PI-REPORT-OWNER"}

      Enum.map(report, &Map.take(&1, [:id, :owner, :outcome])) !=
          Enum.map(expected, &Map.put(&1, :outcome, :passed)) ->
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

  defp decode_exact_envelope(bytes) do
    with {:ok, decoded} <- Jason.decode(bytes),
         true <- is_map(decoded),
         true <-
           Map.keys(decoded) |> MapSet.new() ==
             MapSet.new(["schema_version", "device_class", "assertions"]) do
      {:ok, decoded}
    else
      _ -> {:error, "PI-REPORT-ENVELOPE"}
    end
  end

  defp valid_envelope_header(%{"schema_version" => schema, "device_class" => "physical_iphone"}) do
    if schema == PhysicalIphoneContract.schema_version(),
      do: :ok,
      else: {:error, "PI-REPORT-ENVELOPE"}
  end

  defp valid_envelope_header(_), do: {:error, "PI-REPORT-ENVELOPE"}

  defp exact_entries(entries, owner) when is_list(entries) do
    expected =
      PhysicalIphoneContract.assertions()
      |> Enum.filter(&(&1.owner == owner))

    parsed =
      Enum.map(entries, fn
        %{"id" => id, "outcome" => outcome} = entry
        when map_size(entry) == 2 and is_binary(id) and
               outcome in ["passed", "blocked", "unavailable"] ->
          %{id: id, owner: owner, outcome: String.to_existing_atom(outcome)}

        _ ->
          :invalid
      end)

    if Enum.any?(parsed, &(&1 == :invalid)) or
         Enum.map(parsed, & &1.id) != Enum.map(expected, & &1.id),
       do: {:error, "PI-REPORT-OWNER"},
       else: {:ok, parsed}
  rescue
    _ -> {:error, "PI-REPORT-ENVELOPE"}
  end

  defp exact_entries(_, _), do: {:error, "PI-REPORT-ENVELOPE"}

  defp emit(result), do: IO.puts(Jason.encode!(result))
end
