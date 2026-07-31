defmodule Crosswake.ProofLane.NativePromotion do
  @moduledoc false

  alias Crosswake.ProofLane.Evidence.Error

  @spec rename_noreplace(Path.t(), Path.t()) :: :ok | {:error, Error.t()}
  def rename_noreplace(stage, destination), do: rename_noreplace(stage, destination, [])

  @spec rename_noreplace(Path.t(), Path.t(), keyword()) :: :ok | {:error, Error.t()}
  def rename_noreplace(stage, destination, opts)
      when is_binary(stage) and is_binary(destination) and is_list(opts) do
    with :ok <- supported_os(Keyword.get(opts, :os_type, :os.type())),
         {:ok, compiler} <- compiler(Keyword.get(opts, :compiler, System.get_env("CC"))),
         {:ok, executable} <- build(compiler) do
      try do
        case System.cmd(executable, [stage, destination], stderr_to_stdout: true) do
          {_, 0} ->
            :ok

          {_, 10} ->
            error("PL-EVIDENCE-COLLISION", "artifact", "choose an unused evidence destination")

          {_, 20} ->
            unavailable()

          _ ->
            unavailable()
        end
      rescue
        _ -> unavailable()
      after
        File.rm(executable)
      end
    end
  end

  def rename_noreplace(_, _, _), do: unavailable()

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

  defp unavailable,
    do:
      error(
        "PL-EVIDENCE-PROMOTION-UNAVAILABLE",
        "artifact",
        "provide a supported local promotion capability"
      )

  defp error(rule_id, path, remediation),
    do: {:error, %Error{rule_id: rule_id, path: path, remediation: remediation}}
end
