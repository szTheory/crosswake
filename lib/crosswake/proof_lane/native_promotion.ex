defmodule Crosswake.ProofLane.NativePromotion do
  @moduledoc false

  alias Crosswake.ProofLane.Evidence.Error

  @max_bytes 65_536

  @spec publish(Path.t(), binary()) :: :ok | {:error, Error.t()}
  def publish(destination, bytes), do: publish(destination, bytes, [])

  @spec publish(Path.t(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def publish(destination, bytes, opts)
      when is_binary(destination) and is_binary(bytes) and byte_size(bytes) <= @max_bytes and
             is_list(opts) do
    digest = Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

    with :ok <- supported_os(Keyword.get(opts, :os_type, :os.type())),
         {:ok, compiler} <- compiler(Keyword.get(opts, :compiler, System.get_env("CC"))),
         {:ok, executable} <- build(compiler) do
      try do
        run(executable, destination, digest, bytes)
      rescue
        _ -> unavailable()
      after
        File.rm(executable)
      end
    end
  end

  def publish(_, _, _), do: unavailable()

  # Retained for the old private test seam while callers migrate to bytes-only publication.
  @spec rename_noreplace(Path.t(), Path.t(), keyword()) :: :ok | {:error, Error.t()}
  def rename_noreplace(_, _, opts), do: unavailable(opts)

  defp run(executable, destination, digest, bytes) do
    port =
      Port.open({:spawn_executable, String.to_charlist(executable)}, [
        :binary,
        :exit_status,
        :use_stdio,
        :hide,
        args: [String.to_charlist(destination)]
      ])

    frame = <<byte_size(bytes)::unsigned-big-32, digest::binary-size(64), bytes::binary>>

    if Port.command(port, frame) do
      await(port)
    else
      unavailable()
    end
  end

  defp await(port) do
    receive do
      {^port, {:exit_status, 0}} ->
        :ok

      {^port, {:exit_status, 10}} ->
        error("PL-EVIDENCE-COLLISION", "artifact", "choose an unused evidence destination")

      {^port, _} ->
        unavailable()
    after
      5_000 -> unavailable()
    end
  end

  defp supported_os({:unix, os}) when os in [:linux, :darwin], do: :ok
  defp supported_os(_), do: unavailable()

  defp compiler(value) when is_binary(value) and value != "" do
    name = if String.match?(value, ~r|\A[A-Za-z0-9_+.\-/]+\z|), do: value, else: "cc"

    case System.find_executable(name) do
      nil -> unavailable()
      path -> {:ok, path}
    end
  end

  defp compiler(_), do: compiler("cc")

  defp build(compiler) do
    source = Path.join(:code.priv_dir(:crosswake), "native/crosswake_evidence_promote.c")

    executable =
      Path.join(
        System.tmp_dir!(),
        "crosswake-evidence-promote-" <>
          Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
      )

    if File.regular?(source) do
      case System.cmd(
             compiler,
             ["-std=c11", "-O2", "-Wall", "-Wextra", "-Werror", "-o", executable, source],
             stderr_to_stdout: true
           ) do
        {_, 0} -> {:ok, executable}
        _ -> unavailable()
      end
    else
      unavailable()
    end
  end

  defp unavailable(_opts \\ []),
    do:
      error(
        "PL-EVIDENCE-PROMOTION-UNAVAILABLE",
        "artifact",
        "provide a supported local promotion capability"
      )

  defp error(rule_id, path, remediation),
    do: {:error, %Error{rule_id: rule_id, path: path, remediation: remediation}}
end
