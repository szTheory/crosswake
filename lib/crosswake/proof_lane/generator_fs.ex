defmodule Crosswake.ProofLane.GeneratorFS do
  @moduledoc false

  @max_payload_bytes 4 * 1024 * 1024
  @helper_key {__MODULE__, :private_helper}
  @type error :: {String.t(), String.t()}

  @doc false
  def with_lifecycle(callback) when is_function(callback, 0) do
    case Process.get(@helper_key) do
      nil ->
        with {:ok, compiler} <- compiler(),
             {:ok, directory} <- private_directory(),
             {:ok, executable} <- build(compiler, directory) do
          Process.put(@helper_key, executable)

          try do
            result = callback.()

            case cleanup(directory) do
              :ok -> result
              :error -> {:error, :unavailable}
            end
          after
            Process.delete(@helper_key)
            cleanup(directory)
          end
        end

      _executable ->
        callback.()
    end
  end

  @spec write(Path.t(), String.t(), iodata(), keyword()) ::
          {:ok, :created | :reused} | {:error, error()}
  def write(root, relative, contents, opts \\ [])

  def write(root, relative, contents, opts)
      when is_binary(root) and is_binary(relative) and is_list(opts) do
    with {:ok, bytes} <- bounded_binary(contents),
         {:ok, status, _} <- invoke_write(root, relative, bytes, opts) do
      case status do
        0 -> {:ok, :created}
        10 -> {:ok, :reused}
        12 -> destination_error(relative)
        _ -> write_error(relative)
      end
    else
      {:error, 12} -> destination_error(relative)
      _ -> write_error(relative)
    end
  end

  def write(_, relative, _, _), do: write_error(relative)

  @spec read(Path.t(), String.t()) :: {:ok, binary()} | {:error, :missing | :unsafe}
  def read(root, relative) when is_binary(root) and is_binary(relative) do
    case invoke_read("read", root, relative) do
      {:ok, 0, contents} -> {:ok, contents}
      {:ok, 11, _} -> {:error, :missing}
      _ -> {:error, :unsafe}
    end
  end

  def read(_, _), do: {:error, :unsafe}

  @spec regular?(Path.t(), String.t()) :: boolean()
  def regular?(root, relative) when is_binary(root) and is_binary(relative),
    do: match?({:ok, 0, _}, invoke_read("regular", root, relative))

  def regular?(_, _), do: false

  @spec status(Path.t(), String.t()) :: :regular | :missing | :unsafe
  def status(root, relative) when is_binary(root) and is_binary(relative) do
    case invoke_read("regular", root, relative) do
      {:ok, 0, _} -> :regular
      {:ok, 11, _} -> :missing
      _ -> :unsafe
    end
  end

  def status(_, _), do: :unsafe

  defp bounded_binary(contents) do
    bytes = IO.iodata_to_binary(contents)
    if byte_size(bytes) <= @max_payload_bytes, do: {:ok, bytes}, else: {:error, :too_large}
  rescue
    _ -> {:error, :invalid}
  end

  defp invoke_write(root, relative, bytes, opts) do
    with_helper(fn executable ->
      try do
        run_port(executable, ["write", root, relative, barrier_mode(opts)], bytes, opts)
      rescue
        _ -> {:error, 20}
      end
    end)
  end

  defp invoke_read(action, root, relative) do
    with_helper(fn executable ->
      try do
        {output, status} =
          System.cmd(executable, [action, root, relative], stderr_to_stdout: true)

        {:ok, status, output}
      rescue
        _ -> {:error, 20}
      end
    end)
  end

  defp run_port(executable, args, bytes, opts) do
    port =
      Port.open({:spawn_executable, String.to_charlist(executable)}, [
        :binary,
        :exit_status,
        args: Enum.map(args, &String.to_charlist/1)
      ])

    true = Port.command(port, <<byte_size(bytes)::unsigned-big-64, bytes::binary>>)
    await_port(port, opts, "")
  end

  defp await_port(port, opts, output) do
    receive do
      {^port, {:data, "before_publish\n"}} ->
        respond_to_barrier(port, Keyword.get(opts, :before_publish))
        await_port(port, opts, output)

      {^port, {:data, "after_publish\n"}} ->
        respond_to_barrier(port, Keyword.get(opts, :after_publish))
        await_port(port, opts, output)

      {^port, {:data, _}} ->
        await_port(port, opts, output)

      {^port, {:exit_status, status}} ->
        {:ok, status, output}
    after
      5_000 ->
        Port.close(port)
        {:error, :timeout}
    end
  end

  defp respond_to_barrier(port, callback) when is_function(callback, 0) do
    if callback.() == :ok,
      do: Port.command(port, "resume\n"),
      else: Port.command(port, "abort!\n")
  rescue
    _ -> Port.command(port, "abort!\n")
  end

  defp respond_to_barrier(port, nil), do: Port.command(port, "resume\n")
  defp respond_to_barrier(port, _), do: Port.command(port, "abort!\n")

  defp barrier_mode(opts) do
    before? = is_function(Keyword.get(opts, :before_publish), 0)
    after? = is_function(Keyword.get(opts, :after_publish), 0)

    case {before?, after?} do
      {true, true} -> "both"
      {true, false} -> "before"
      {false, true} -> "after"
      _ -> "none"
    end
  end

  defp compiler do
    case System.find_executable(System.get_env("CC") || "cc") do
      nil -> {:error, :unavailable}
      path -> {:ok, path}
    end
  end

  defp with_helper(callback) when is_function(callback, 1) do
    case Process.get(@helper_key) do
      executable when is_binary(executable) ->
        callback.(executable)

      nil ->
        with {:ok, compiler} <- compiler(),
             {:ok, directory} <- private_directory(),
             {:ok, executable} <- build(compiler, directory) do
          invoke_with_cleanup(directory, callback, executable)
        end
    end
  end

  defp with_helper(_callback), do: {:error, :unavailable}

  defp invoke_with_cleanup(directory, callback, executable) do
    try do
      result = callback.(executable)

      case cleanup(directory) do
        :ok -> result
        :error -> {:error, :unavailable}
      end
    rescue
      _ -> {:error, :unavailable}
    after
      cleanup(directory)
    end
  end

  defp private_directory do
    parent = System.tmp_dir!()
    directory = Path.join(parent, "crosswake-proof-lane-helper-" <> private_suffix())

    case File.mkdir(directory) do
      :ok ->
        with :ok <- File.chmod(directory, 0o700),
             {:ok, %{type: :directory, mode: mode}} <- File.lstat(directory),
             true <- restrictive?(mode) do
          {:ok, directory}
        else
          _ ->
            cleanup(directory)
            {:error, :unavailable}
        end

      _ ->
        {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  defp private_suffix do
    :crypto.strong_rand_bytes(18) |> Base.url_encode64(padding: false)
  rescue
    _ -> Integer.to_string(System.unique_integer([:positive]))
  end

  defp build(compiler, directory) do
    source = Path.join(:code.priv_dir(:crosswake), "native/crosswake_proof_lane_fs.c")
    executable = Path.join(directory, "crosswake-proof-lane-fs")

    with {:ok, %{type: :regular}} <- File.lstat(source),
         {_, 0} <-
           System.cmd(
             compiler,
             ["-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", "-o", executable, source],
             stderr_to_stdout: true
           ),
         :ok <- File.chmod(executable, 0o700),
         {:ok, %{type: :regular, mode: mode}} <- File.lstat(executable),
         true <- restrictive?(mode) do
      {:ok, executable}
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  defp restrictive?(mode), do: Bitwise.band(mode, 0o077) == 0

  defp cleanup(directory) do
    case File.rm_rf(directory) do
      {:ok, _} -> :ok
      _ -> :error
    end
  rescue
    _ -> :error
  end

  defp destination_error(relative), do: {:error, {"PL-GENERATE-DESTINATION", safe_path(relative)}}
  defp write_error(relative), do: {:error, {"PL-GENERATE-WRITE", safe_path(relative)}}
  defp safe_path(relative) when is_binary(relative) and relative != "", do: relative
  defp safe_path(_), do: "destination"
end
