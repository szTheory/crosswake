defmodule Crosswake.ProofLane.PhysicalIphoneHost do
  @moduledoc false

  @callbacks [
    {:preflight_options, 0},
    {:device_report, 1},
    {:backend_report, 1},
    {:cleanup_run, 0},
    {:evidence_input, 1},
    {:destination, 0}
  ]

  @spec load() :: {:ok, keyword()} | {:error, String.t()}
  def load do
    case Application.get_env(:crosswake, :physical_iphone_proof_host) do
      adapter when is_atom(adapter) and adapter not in [nil, true, false] ->
        if Code.ensure_loaded?(adapter) and
             Enum.all?(@callbacks, fn {name, arity} ->
               function_exported?(adapter, name, arity)
             end) do
          {:ok,
           [
             host_adapter: adapter,
             prepare_for_run: fn -> safe_optional(adapter, :prepare_for_run, []) end,
             inventory_and_checks: fn -> safe(adapter, :preflight_options, []) end,
             device_report: fn contract -> safe(adapter, :device_report, [contract]) end,
             backend_report: fn contract -> safe(adapter, :backend_report, [contract]) end,
             cleanup_run: fn -> safe(adapter, :cleanup_run, []) end,
             evidence_input: fn candidate -> safe(adapter, :evidence_input, [candidate]) end,
             evidence_destination: fn -> safe(adapter, :destination, []) end
           ]}
        else
          {:error, "PI-HOST-CONFIG"}
        end

      _ ->
        {:error, "PI-HOST-CONFIG"}
    end
  end

  defp safe(adapter, name, args) do
    try do
      apply(adapter, name, args)
    rescue
      _ -> {:error, "PI-HOST-CALLBACK"}
    catch
      _, _ -> {:error, "PI-HOST-CALLBACK"}
    end
  end

  defp safe_optional(adapter, name, args) do
    if function_exported?(adapter, name, length(args)),
      do: safe(adapter, name, args),
      else: :ok
  end
end
