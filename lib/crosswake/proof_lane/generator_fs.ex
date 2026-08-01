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
      {:error, 11} -> {:error, :missing}
      _ -> {:error, :unsafe}
    end
  end

  def read(_, _), do: {:error, :unsafe}

  @spec regular?(Path.t(), String.t()) :: boolean()
  def regular?(root, relative) when is_binary(root) and is_binary(relative) do
    match?({:ok, 0, _}, invoke("regular", root, relative, "", []))
  end

  def regular?(_, _), do: false

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

        if status == 0, do: {:ok, status, output}, else: {:error, status}
      rescue
        _ -> {:error, 20}
      after
        File.rm(executable)
        File.rm(input_path)
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
    case Keyword.get(opts, :before_final_open_hook) do
      value when is_binary(value) -> [{"CROSSWAKE_PROOF_LANE_FS_TEST_BEFORE_FINAL_OPEN", value}]
      _ -> []
    end
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
