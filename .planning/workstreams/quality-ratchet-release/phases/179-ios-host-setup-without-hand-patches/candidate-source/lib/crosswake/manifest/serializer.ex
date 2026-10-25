defmodule Crosswake.Manifest.Serializer do
  @moduledoc """
  Deterministic JSON renderer and idempotent writer for the canonical manifest artifact.
  """

  alias Crosswake.Manifest.Types

  @type action :: :created | :reused | :updated

  @spec render(Types.Root.t()) :: String.t()
  def render(%Types.Root{} = manifest) do
    manifest
    |> Types.to_map()
    |> ordered()
    |> Jason.encode_to_iodata!(pretty: true)
    |> IO.iodata_to_binary()
    |> Kernel.<>("\n")
  end

  @spec write(String.t(), Types.Root.t()) :: {:ok, action()}
  def write(path, %Types.Root{} = manifest) do
    File.mkdir_p!(Path.dirname(path))

    contents = render(manifest)

    case File.read(path) do
      {:ok, ^contents} ->
        {:ok, :reused}

      {:ok, _previous} ->
        File.write!(path, contents)
        {:ok, :updated}

      {:error, :enoent} ->
        File.write!(path, contents)
        {:ok, :created}

      {:error, reason} ->
        raise "could not persist Crosswake manifest #{path}: #{:file.format_error(reason)}"
    end
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
