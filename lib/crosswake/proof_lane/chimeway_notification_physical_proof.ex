defmodule Crosswake.ProofLane.ChimewayNotificationPhysicalProof do
  @moduledoc """
  Closed notification facts owned by CrossWake for Chimeway's physical proof.

  The report contains only owner-qualified outcomes. Canonical evidence bytes stay
  inside this module when a report is bound to a promoted CrossWake artifact.
  """

  alias Crosswake.ProofLane.{Evidence, PhysicalIphoneContract}

  @schema_version 1
  @outcomes [:passed, :blocked, :unavailable]
  @assertions [
    %{id: "permission_observed", owner: :device_local},
    %{id: "authenticated_registration", owner: :backend_authority},
    %{id: "protected_activation_once", owner: :backend_authority}
  ]

  @canonical_physical_run_contract Jason.encode!(%{
                                     "schema_version" => 1,
                                     "device_class" => "physical_iphone",
                                     "ios_runtime_line" => "18.0",
                                     "outcome" => "passed",
                                     "assertions" =>
                                       PhysicalIphoneContract.assertions()
                                       |> Enum.map(fn %{id: id, owner: owner} ->
                                         %{
                                           "id" => id,
                                           "owner" => Atom.to_string(owner),
                                           "outcome" => "passed"
                                         }
                                       end)
                                   })

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec assertions() :: [%{id: String.t(), owner: :device_local | :backend_authority}]
  def assertions, do: @assertions

  @spec validate_report(term()) :: :ok | {:error, String.t()}
  def validate_report(report) when is_list(report) do
    if Enum.all?(report, &exact_entry_shape?/1) do
      expected_ids = Enum.map(@assertions, & &1.id)
      supplied_ids = Enum.map(report, &Map.fetch!(&1, :id))

      cond do
        length(report) != length(@assertions) or Enum.uniq(supplied_ids) != supplied_ids or
            Enum.sort(supplied_ids) != Enum.sort(expected_ids) ->
          {:error, "CW-NOTIFICATION-ASSERTIONS-COMPLETE"}

        supplied_ids != expected_ids ->
          {:error, "CW-NOTIFICATION-ASSERTIONS-ORDER"}

        not Enum.all?(report, &valid_entry?/1) ->
          {:error, "CW-NOTIFICATION-ASSERTIONS-OWNER"}

        true ->
          :ok
      end
    else
      {:error, "CW-NOTIFICATION-ASSERTIONS-COMPLETE"}
    end
  end

  def validate_report(_), do: {:error, "CW-NOTIFICATION-ASSERTIONS-COMPLETE"}

  @spec validate_source_bound(term(), Path.t()) :: :ok | {:error, String.t()}
  def validate_source_bound(report, evidence_path) when is_binary(evidence_path) do
    with :ok <- validate_report(report),
         :ok <- Evidence.check(evidence_path, [canonical_source()]) do
      :ok
    else
      {:error, rule} when is_binary(rule) -> {:error, rule}
      _ -> {:error, "CW-NOTIFICATION-SOURCE-BOUND"}
    end
  end

  def validate_source_bound(_, _), do: {:error, "CW-NOTIFICATION-SOURCE-BOUND"}

  defp canonical_source do
    %{kind: :physical_iphone_run_contract, canonical_bytes: @canonical_physical_run_contract}
  end

  defp exact_entry_shape?(entry) when is_map(entry),
    do:
      map_size(entry) == 3 and
        Map.keys(entry) |> MapSet.new() == MapSet.new([:id, :owner, :outcome])

  defp exact_entry_shape?(_), do: false

  defp valid_entry?(%{id: id, owner: owner, outcome: outcome}) when outcome in @outcomes do
    case Enum.find(@assertions, &(&1.id == id)) do
      %{owner: ^owner} -> true
      _ -> false
    end
  end

  defp valid_entry?(_), do: false
end
