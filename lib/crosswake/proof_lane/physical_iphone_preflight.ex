defmodule Crosswake.ProofLane.PhysicalIphonePreflight do
  @moduledoc "Ordered, callback-driven, side-effect-free physical-iPhone readiness gate."

  alias Crosswake.Adoption.RouteInventory
  alias Crosswake.ProofLane.{Config, Generator, PhysicalIphoneContract}
  alias Crosswake.Shell.IOSHostOriginMode

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

  @inventory_rule "PI-PREFLIGHT-INVENTORY"
  @adopter_handoff_rule "PI-PREFLIGHT-ADOPTER-HANDOFF"
  @config_rule "PI-PREFLIGHT-CONFIG"

  @unreadable_plist_reason "The generated iOS host files could not be read: CrosswakeShell/Info.plist is missing or unreadable, so the origin cannot be checked. Regenerate the shell and run again."
  @unreadable_activation_reason "The generated iOS host files could not be read: Fixtures/route_activation.json exists but cannot be read or parsed, so the origin cannot be checked. Regenerate the shell and run again."

  @doc "Returns a safe, complete readiness summary without invoking proof reports or promotion."
  @spec readiness(keyword()) :: %{outcome: :ready | :blocked, checks: [map()]}
  def readiness(options) when is_list(options) do
    checks = [
      readiness_entry(@adopter_handoff_rule, adopter_handoff_ready?(options)),
      readiness_entry(@inventory_rule, inventory_ready?(options)),
      readiness_entry(@config_rule, config_ready?(options))
      | Enum.map(@checks, fn {name, rule} ->
          readiness_entry(rule, check_ready?(name, Keyword.get(options, name)))
        end)
    ]

    %{
      outcome: if(Enum.all?(checks, &(&1.state == :ready)), do: :ready, else: :blocked),
      checks: checks
    }
  rescue
    _ -> blocked_readiness()
  end

  def readiness(_), do: blocked_readiness()

  @spec check(keyword()) :: {:ready, map()} | {:blocked, String.t()}
  def check(options) when is_list(options) do
    with :ok <- adopter_handoff(options),
         {:ok, rows} <- inventory(options),
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
      {:adopter_handoff_error, _} -> {:blocked, @adopter_handoff_rule}
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

  defp blocked_readiness do
    %{
      outcome: :blocked,
      checks:
        [@adopter_handoff_rule, @inventory_rule, @config_rule | Enum.map(@checks, &elem(&1, 1))]
        |> Enum.map(&%{id: &1, state: :blocked})
    }
  end

  defp readiness_entry(rule, true), do: %{id: rule, state: :ready}
  defp readiness_entry(rule, false), do: %{id: rule, state: :blocked}

  defp inventory_ready?(options) do
    with {:ok, rows} <- inventory(options),
         {:eligible, _} <- RouteInventory.promotion_status(rows),
         do: true,
         else: (_ -> false)
  end

  defp adopter_handoff_ready?(options), do: adopter_handoff(options) == :ok

  defp adopter_handoff(options) do
    case callback_result(:adopter_handoff, Keyword.get(options, :adopter_handoff)) do
      %{source: :adopter, topology: %{status: :ready}} -> :ok
      _ -> {:adopter_handoff_error, :blocked}
    end
  end

  defp config_ready?(options), do: match?({:ok, _}, config(options))

  defp check_ready?(:destination, callback),
    do: callback_result(:destination, callback) == :physical_iphone

  defp check_ready?(_name, callback), do: callback_result(:check, callback) == :ok

  defp inventory(options) do
    case RouteInventory.validate_inventory(Keyword.get(options, :inventory, [])) do
      {:ok, rows} -> {:ok, rows}
      {:error, _} -> {:inventory_error, :invalid}
    end
  end

  defp config(options) do
    case Config.normalize(Keyword.get(options, :config)) do
      {:ok, config} ->
        if origin_refusal_for(config, options),
          do: {:config_error, :local_loopback},
          else: {:ok, config}

      {:error, _} ->
        {:config_error, :invalid}
    end
  end

  @doc false
  # Returns the generator's local-mode refusal text for any local-loopback signal in the
  # declaration or the generated iOS files, otherwise nil. When the generated shell folder exists,
  # an Info.plist that cannot be read, or a Fixtures/route_activation.json that exists but cannot
  # be read or parsed, returns a reason naming that file. A missing shell folder, or a missing
  # route_activation.json next to a readable Info.plist, is not a refusal by itself.
  @spec origin_refusal(keyword()) :: String.t() | nil
  def origin_refusal(options) when is_list(options) do
    case Config.normalize(Keyword.get(options, :config)) do
      {:ok, config} -> origin_refusal_for(config, options)
      {:error, _} -> nil
    end
  end

  def origin_refusal(_), do: nil

  defp origin_refusal_for(config, options) do
    declaration =
      Keyword.get_lazy(options, :ios_host, fn -> Application.get_env(:crosswake, :ios_host) end)

    root = Path.join(config.ios_shell_root, "crosswake_shell")

    case shell_input_refusal(root) do
      nil ->
        case IOSHostOriginMode.observe(root, declaration) do
          :none -> nil
          _signal -> Generator.local_mode_refusal()
        end

      reason ->
        reason
    end
  rescue
    _ -> Generator.local_mode_refusal()
  end

  # When the generated shell folder exists, its origin inputs must be readable. A folder that
  # does not exist keeps the earlier behaviour (nothing to read, nothing to refuse).
  defp shell_input_refusal(root) do
    case File.lstat(root) do
      {:error, reason} when reason in [:enoent, :enotdir] ->
        nil

      {:error, _} ->
        @unreadable_plist_reason

      {:ok, _} ->
        case Crosswake.Shell.ManagedOutputs.read_origin_plist(root) do
          {:ok, _} -> activation_refusal(root)
          _ -> @unreadable_plist_reason
        end
    end
  end

  defp activation_refusal(root) do
    path = Path.join(root, "Fixtures/route_activation.json")

    case File.lstat(path) do
      {:error, :enoent} ->
        nil

      _ ->
        with {:ok, bytes} <- File.read(path),
             {:ok, _} <- Jason.decode(bytes) do
          nil
        else
          _ -> @unreadable_activation_reason
        end
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
