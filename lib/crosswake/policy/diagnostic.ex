defmodule Crosswake.Policy.Diagnostic do
  @moduledoc """
  Aggregated compile-time diagnostics for Crosswake route policy.
  """

  alias Crosswake.Policy.Error

  defstruct module: nil, errors: [], warnings: []

  @type t :: %__MODULE__{
          module: module() | nil,
          errors: [Error.t()],
          warnings: [term()]
        }

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      module: Keyword.get(opts, :module),
      errors: Keyword.get(opts, :errors, []),
      warnings: Keyword.get(opts, :warnings, [])
    }
  end

  @spec format(t()) :: String.t()
  def format(%__MODULE__{errors: errors} = diagnostic) do
    header = [
      "Crosswake route policy compilation failed",
      module_line(diagnostic.module),
      "found #{length(errors)} route policy error#{if length(errors) == 1, do: "", else: "s"}"
    ]

    body =
      errors
      |> Enum.map(&format_error/1)
      |> Enum.join("\n\n")

    (header ++ [body])
    |> Enum.reject(&is_nil_or_empty?/1)
    |> Enum.join("\n")
  end

  defp format_error(%Error{} = error) do
    [
      "Route #{error.path || "(unknown path)"}#{route_id_suffix(error.route_id)}",
      context_line(error),
      "reason: #{error.message}",
      key_line(error.key),
      hint_line(error.hint)
    ]
    |> Enum.reject(&is_nil_or_empty?/1)
    |> Enum.join("\n")
  end

  defp module_line(nil), do: nil
  defp module_line(module), do: "router: #{inspect(module)}"

  defp context_line(%Error{} = error) do
    context =
      [
        error.helper && "helper: #{error.helper}",
        error.verb && "verb: #{error.verb}",
        source_line(error.file, error.line)
      ]
      |> Enum.reject(&is_nil_or_empty?/1)
      |> Enum.join(", ")

    if context == "", do: nil, else: context
  end

  defp source_line(nil, _line), do: nil
  defp source_line(file, nil), do: "source: #{file}"
  defp source_line(file, line), do: "source: #{file}:#{line}"

  defp key_line(nil), do: nil
  defp key_line(key), do: "offending key: #{inspect(key)}"

  defp hint_line(nil), do: nil
  defp hint_line(hint), do: "fix hint: #{hint}"

  defp route_id_suffix(nil), do: ""
  defp route_id_suffix(route_id), do: " (id: #{route_id})"

  defp is_nil_or_empty?(nil), do: true
  defp is_nil_or_empty?(""), do: true
  defp is_nil_or_empty?(_value), do: false
end
