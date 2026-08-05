defmodule Crosswake.ProofLane.PhysicalIphoneContract do
  @moduledoc """
  Closed, versioned vocabulary for a single physical-iPhone proof run.

  It intentionally carries neither device identity nor host/adopter values.
  """

  @schema_version 1
  @device_class :physical_iphone
  @owners [:device_local, :backend_authority, :evidence_promotion]
  @outcomes [:passed, :blocked, :unavailable]
  @assertions [
    %{id: "PI-PACK-INSTALL-AUDIO", owner: :device_local},
    %{id: "PI-OFFLINE-SELECTED-PERSISTENCE", owner: :device_local},
    %{id: "PI-OFFLINE-FREE-FORM-PERSISTENCE", owner: :device_local},
    %{id: "PI-RELAUNCH-PERSISTENCE", owner: :device_local},
    %{id: "PI-RECOVERY-RETAINED", owner: :device_local},
    %{id: "PI-LOGOUT-ACCOUNT-FENCE", owner: :backend_authority},
    %{id: "PI-ENTRY-DISABLEMENT", owner: :backend_authority},
    %{id: "PI-REPLAY-DISABLEMENT", owner: :backend_authority},
    %{id: "PI-EXACTLY-ONCE-EMPTY-OUTBOX", owner: :backend_authority},
    %{id: "PI-REDACTED-PROMOTION", owner: :evidence_promotion}
  ]

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec device_class() :: :physical_iphone
  def device_class, do: @device_class

  @spec assertions() :: [
          %{id: String.t(), owner: :device_local | :backend_authority | :evidence_promotion}
        ]
  def assertions, do: @assertions

  @spec ios_runtime_line(term()) :: {:ok, String.t()} | {:error, String.t()}
  def ios_runtime_line(value) when is_binary(value) do
    if Regex.match?(~r/^(?:[1-9][0-9]{0,2})\.(?:0|[1-9][0-9]{0,2})$/, value),
      do: {:ok, value},
      else: {:error, "PI-RUNTIME-LINE"}
  end

  def ios_runtime_line(_), do: {:error, "PI-RUNTIME-LINE"}

  @spec validate_report(term()) :: :ok | {:error, String.t()}
  def validate_report(report) when is_list(report) do
    if Enum.all?(report, &exact_report_entry_shape?/1) do
      expected_ids = Enum.map(@assertions, & &1.id)
      supplied_ids = Enum.map(report, &Map.fetch!(&1, :id))

      cond do
        length(report) != length(@assertions) or Enum.uniq(supplied_ids) != supplied_ids or
            Enum.sort(supplied_ids) != Enum.sort(expected_ids) ->
          {:error, "PI-ASSERTIONS-COMPLETE"}

        supplied_ids != expected_ids ->
          {:error, "PI-ASSERTIONS-ORDER"}

        not Enum.all?(report, &valid_report_entry?/1) ->
          {:error, "PI-ASSERTIONS-OWNER"}

        true ->
          :ok
      end
    else
      {:error, "PI-ASSERTIONS-COMPLETE"}
    end
  end

  def validate_report(_), do: {:error, "PI-ASSERTIONS-COMPLETE"}

  defp exact_report_entry_shape?(entry) when is_map(entry),
    do:
      map_size(entry) == 3 and
        Map.keys(entry) |> MapSet.new() == MapSet.new([:id, :owner, :outcome])

  defp exact_report_entry_shape?(_), do: false

  defp valid_report_entry?(%{id: id, owner: owner, outcome: outcome})
       when owner in @owners and outcome in @outcomes do
    case Enum.find(@assertions, &(&1.id == id)) do
      %{owner: ^owner} -> true
      _ -> false
    end
  end

  defp valid_report_entry?(_), do: false
end
