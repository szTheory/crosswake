defmodule Crosswake.Install.Manifest do
  @moduledoc """
  Persists machine-readable scaffold state for later diagnostics and upgrade tooling.
  """

  require EEx

  EEx.function_from_file(
    :defp,
    :render_template,
    Application.app_dir(:crosswake, "priv/templates/crosswake/install_manifest.json.eex"),
    [:assigns]
  )

  @type action :: :created | :reused | :updated

  @spec write(String.t(), map()) :: {:ok, action()}
  def write(path, attrs) do
    File.mkdir_p!(Path.dirname(path))

    contents = render(attrs)

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
        raise "could not persist Crosswake install manifest #{path}: #{:file.format_error(reason)}"
    end
  end

  @spec render(map()) :: String.t()
  def render(attrs) do
    render_template(
      Map.merge(attrs, %{
        files_json: json(Map.fetch!(attrs, :files)),
        markers_json: json(Map.fetch!(attrs, :markers))
      })
    )
  end

  @spec json(term()) :: String.t()
  def json(value) when is_map(value) do
    value
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, nested} ->
      "#{json(to_string(key))}: #{json(nested)}"
    end)
    |> Enum.join(", ")
    |> then(&"{#{&1}}")
  end

  def json(value) when is_list(value) do
    value
    |> Enum.map(&json/1)
    |> Enum.join(", ")
    |> then(&"[#{&1}]")
  end

  def json(value) when is_binary(value) do
    escaped =
      value
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")
      |> String.replace("\n", "\\n")

    ~s("#{escaped}")
  end

  def json(value) when is_atom(value), do: json(Atom.to_string(value))
  def json(value) when is_boolean(value), do: if(value, do: "true", else: "false")
  def json(nil), do: "null"
  def json(value) when is_integer(value) or is_float(value), do: to_string(value)
end
