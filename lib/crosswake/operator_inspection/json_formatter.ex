defmodule Crosswake.OperatorInspection.JSONFormatter do
  @moduledoc """
  Stable JSON formatter for operator inspection documents.
  """

  alias Crosswake.OperatorInspection.Types

  @spec render(Types.Document.t()) :: String.t()
  def render(%Types.Document{} = document) do
    document
    |> Types.to_map()
    |> ordered()
    |> Jason.encode!(pretty: true)
  end

  defp ordered(map) when is_map(map) do
    values =
      map
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map(fn {key, value} -> {key, ordered(value)} end)

    %Jason.OrderedObject{values: values}
  end

  defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
  defp ordered(value), do: value
end
