defmodule Crosswake.Policy.Warning do
  @moduledoc """
  Non-blocking adoption warning for unmanaged routes.
  """

  @enforce_keys [:message, :unmanaged_paths]
  defstruct [:message, :module, unmanaged_paths: []]

  @type t :: %__MODULE__{
          message: String.t(),
          module: module() | nil,
          unmanaged_paths: [String.t()]
        }

  @spec unmanaged_routes([String.t()], module() | nil) :: t()
  def unmanaged_routes(paths, module \\ nil) do
    sorted_paths = Enum.sort(paths)

    %__MODULE__{
      module: module,
      unmanaged_paths: sorted_paths,
      message:
        "Crosswake incremental adoption warning: unmanaged routes remain in this router (#{Enum.join(sorted_paths, ", ")})"
    }
  end

  @spec format(t()) :: String.t()
  def format(%__MODULE__{} = warning) do
    [
      warning.message,
      warning.module && "router: #{inspect(warning.module)}",
      "unmanaged paths: #{Enum.join(warning.unmanaged_paths, ", ")}"
    ]
    |> Enum.reject(&is_nil_or_empty?/1)
    |> Enum.join("\n")
  end

  defp is_nil_or_empty?(nil), do: true
  defp is_nil_or_empty?(""), do: true
  defp is_nil_or_empty?(_value), do: false
end
