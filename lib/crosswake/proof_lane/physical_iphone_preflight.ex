defmodule Crosswake.ProofLane.PhysicalIphonePreflight do
  @moduledoc "Ordered, callback-driven, side-effect-free physical-iPhone readiness gate."

  alias Crosswake.Adoption.RouteInventory
  alias Crosswake.ProofLane.{Config, PhysicalIphoneContract}

  @checks [
    {:generated_lane, "PI-PREFLIGHT-GENERATED-LANE"},
    {:destination, "PI-PREFLIGHT-DESTINATION"},
    {:signing, "PI-PREFLIGHT-SIGNING"},
    {:host, "PI-PREFLIGHT-HOST"},
    {:fixture_adapter, "PI-PREFLIGHT-FIXTURE"},
    {:media, "PI-PREFLIGHT-MEDIA"},
    {:replay, "PI-PREFLIGHT-REPLAY"},
    {:rejection_conflict, "PI-PREFLIGHT-REJECTION-CONFLICT"},
    {:scoped_session, "PI-PREFLIGHT-SCOPE"},
    {:feature_controls, "PI-PREFLIGHT-FEATURE-CONTROLS"},
    {:destination_parent, "PI-PREFLIGHT-DESTINATION-PARENT"}
  ]

  @spec check(keyword()) :: {:ready, map()} | {:blocked, String.t()}
  def check(options) when is_list(options) do
    with {:ok, rows} <- inventory(options),
         {:eligible, _} <- RouteInventory.promotion_status(rows),
         {:ok, _config} <- config(options),
         :ok <- run_checks(options, @checks) do
      {:ready,
       %{
         schema_version: PhysicalIphoneContract.schema_version(),
         device_class: PhysicalIphoneContract.device_class(),
         assertion_ids: Enum.map(PhysicalIphoneContract.assertions(), & &1.id)
       }}
    else
      {:inventory_error, _} -> {:blocked, "PI-PREFLIGHT-INVENTORY"}
      {:blocked, _} -> {:blocked, "PI-PREFLIGHT-INVENTORY"}
      {:config_error, _} -> {:blocked, "PI-PREFLIGHT-CONFIG"}
      {:check_error, rule} -> {:blocked, rule}
      _ -> {:blocked, "PI-PREFLIGHT-INVENTORY"}
    end
  rescue
    _ -> {:blocked, "PI-PREFLIGHT-INVENTORY"}
  end

  def check(_), do: {:blocked, "PI-PREFLIGHT-INVENTORY"}

  defp inventory(options) do
    case RouteInventory.validate_inventory(Keyword.get(options, :inventory, [])) do
      {:ok, rows} -> {:ok, rows}
      {:error, _} -> {:inventory_error, :invalid}
    end
  end

  defp config(options) do
    case Config.normalize(Keyword.get(options, :config)) do
      {:ok, config} -> {:ok, config}
      {:error, _} -> {:config_error, :invalid}
    end
  end

  defp run_checks(_options, []), do: :ok

  defp run_checks(options, [{name, rule} | remaining]) do
    case callback_result(name, Keyword.get(options, name)) do
      :ok -> run_checks(options, remaining)
      :physical_iphone when name == :destination -> run_checks(options, remaining)
      _ -> {:check_error, rule}
    end
  end

  defp callback_result(_name, callback) when is_function(callback, 0) do
    try do
      case callback.() do
        :ok -> :ok
        {:ok, value} -> value
        _ -> :blocked
      end
    rescue
      _ -> :blocked
    catch
      _, _ -> :blocked
    end
  end

  defp callback_result(_, _), do: :blocked
end
