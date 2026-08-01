defmodule Crosswake.ProofLane.GeneratorFS do
  @moduledoc false

  @type error :: {String.t(), String.t()}

  @spec write(Path.t(), String.t(), iodata(), keyword()) ::
          {:ok, :created | :reused} | {:error, error()}
  def write(root, relative, contents, opts \\ [])

  def write(root, relative, contents, opts)
      when is_binary(root) and is_binary(relative) and is_list(opts) do
    with {:ok, status, _} <- invoke("write", root, relative, IO.iodata_to_binary(contents), opts) do
      case status do
        0 -> {:ok, :created}
        10 -> {:ok, :reused}
        12 -> destination_error(relative)
        _ -> write_error(relative)
      end
    else
      {:error, status} when status == 12 -> destination_error(relative)
      {:error, _} -> write_error(relative)
    end
  end

  def write(_, relative, _, _), do: write_error(relative)

  @spec read(Path.t(), String.t()) :: {:ok, binary()} | {:error, :missing | :unsafe}
  def read(root, relative) when is_binary(root) and is_binary(relative) do
    case invoke("read", root, relative, "", []) do
      {:ok, 0, contents} -> {:ok, contents}
      {:ok, 11, _} -> {:error, :missing}
      _ -> {:error, :unsafe}
    end
  end

  def read(_, _), do: {:error, :unsafe}

  @spec regular?(Path.t(), String.t()) :: boolean()
  def regular?(root, relative) when is_binary(root) and is_binary(relative) do
    match?({:ok, 0, _}, invoke("regular", root, relative, "", []))
  end

  def regular?(_, _), do: false

  @spec status(Path.t(), String.t()) :: :regular | :missing | :unsafe
  def status(root, relative) when is_binary(root) and is_binary(relative) do
    case invoke("regular", root, relative, "", []) do
      {:ok, 0, _} -> :regular
      {:ok, 11, _} -> :missing
      _ -> :unsafe
    end
  end

  def status(_, _), do: :unsafe

  @spec publish(Path.t(), String.t(), String.t()) :: {:ok, :created | :reused} | {:error, error()}
  def publish(root, staging, destination)
      when is_binary(root) and is_binary(staging) and is_binary(destination) do
    case invoke_publish(root, staging, destination) do
      {:ok, 0, _} -> {:ok, :created}
      {:ok, 10, _} -> {:ok, :reused}
      {:ok, 12, _} -> destination_error(destination)
      _ -> write_error(destination)
    end
  end

  def publish(_, _, destination), do: write_error(destination)

  defp invoke(action, root, relative, input, opts) do
    with {:ok, compiler} <- compiler(),
         {:ok, executable} <- build(compiler),
         {:ok, input_path} <- input_file(input) do
      try do
        args =
          if action == "write",
            do: [action, root, relative, input_path],
            else: [action, root, relative]

        {output, status} =
          System.cmd(executable, args, stderr_to_stdout: true, env: hook_env(opts))

        {:ok, status, output}
      rescue
        _ -> {:error, 20}
      after
        File.rm(executable)
        File.rm(input_path)
      end
    end
  end

  defp invoke_publish(root, staging, destination) do
    with {:ok, compiler} <- compiler(),
         {:ok, executable} <- build(compiler) do
      try do
        {output, status} =
          System.cmd(executable, ["publish", root, staging, destination], stderr_to_stdout: true)

        {:ok, status, output}
      rescue
        _ -> {:error, 20}
      after
        File.rm(executable)
      end
    end
  end

  defp input_file(contents) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-proof-lane-input-" <>
          Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
      )

    case File.open(path, [:write, :exclusive, :binary]) do
      {:ok, io} ->
        :ok = IO.binwrite(io, contents)
        :ok = File.close(io)
        {:ok, path}

      _ ->
        {:error, :unavailable}
    end
  end

  defp hook_env(opts) do
    before_final_open =
      case Keyword.get(opts, :before_final_open_hook) do
        value when is_binary(value) -> [{"CROSSWAKE_PROOF_LANE_FS_TEST_BEFORE_FINAL_OPEN", value}]
        _ -> []
      end

    post_create_fault =
      case Keyword.get(opts, :post_create_fault) do
        value when value in [:read, :write, :fsync] ->
          [{"CROSSWAKE_PROOF_LANE_FS_TEST_POST_CREATE_FAULT", Atom.to_string(value)}]

        _ ->
          []
      end

    before_final_open ++ post_create_fault
  end

  defp compiler do
    case System.find_executable(System.get_env("CC") || "cc") do
      nil -> {:error, :unavailable}
      path -> {:ok, path}
    end
  end

  defp build(compiler) do
    source = Path.join(:code.priv_dir(:crosswake), "native/crosswake_proof_lane_fs.c")

    executable =
      Path.join(
        System.tmp_dir!(),
        "crosswake-proof-lane-fs-" <>
          Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
      )

    if File.regular?(source) do
      case System.cmd(
             compiler,
             ["-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", "-o", executable, source],
             stderr_to_stdout: true
           ) do
        {_, 0} -> {:ok, executable}
        _ -> {:error, :unavailable}
      end
    else
      {:error, :unavailable}
    end
  end

  defp destination_error(relative), do: {:error, {"PL-GENERATE-DESTINATION", safe_path(relative)}}
  defp write_error(relative), do: {:error, {"PL-GENERATE-WRITE", safe_path(relative)}}

  defp safe_path(relative) when is_binary(relative) and relative != "", do: relative
  defp safe_path(_), do: "destination"
end
