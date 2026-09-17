defmodule Crosswake.ReleaseCandidate do
  @moduledoc """
  Pure release-candidate evaluation and receipt authority.

  External adapters provide normalized observations. This module validates those observations,
  detects drift, and derives one closed release-candidate state without network or process access.
  """

  alias Crosswake.ReleaseCandidate.{Identity, Projection, Receipt}

  @input_keys ~w(identity observed_identity checks external_state credentials)a
  @run_keys ~w(version ref output_dir input input_adapter)a
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @output_files %{
    json: "candidate-receipt.json",
    markdown: "candidate-receipt.md",
    github_summary: "candidate-github-summary.md",
    terminal: "candidate-terminal.txt"
  }

  @spec evaluate!(map()) :: Receipt.t()
  def evaluate!(input) do
    unless is_map(input) and Enum.sort(Map.keys(input)) == Enum.sort(@input_keys), do: invalid!()

    Receipt.build!(%{
      identity: %{
        bound: Identity.normalize!(input.identity),
        observed: Identity.normalize!(input.observed_identity, consistent?: false)
      },
      checks: input.checks,
      external_state: input.external_state,
      credentials: input.credentials
    })
  rescue
    KeyError -> invalid!()
  end

  @spec run!(keyword()) :: map()
  def run!(opts) when is_list(opts) do
    validate_run_options!(opts)

    version = Keyword.fetch!(opts, :version)
    ref = Keyword.fetch!(opts, :ref)
    output_dir = Keyword.fetch!(opts, :output_dir)
    validate_command_identity!(version, ref, output_dir)

    input = candidate_input!(opts)
    validate_bound_command_identity!(input, version, ref)

    receipt = evaluate!(input)
    json = Receipt.encode!(receipt) <> "\n"
    markdown = Projection.markdown(receipt)
    github_summary = Projection.github_summary(receipt)
    terminal = Projection.terminal(receipt)

    files = write_outputs!(output_dir, json, markdown, github_summary, terminal)

    %{
      receipt: receipt,
      json: json,
      markdown: markdown,
      github_summary: github_summary,
      terminal: terminal,
      files: files
    }
  rescue
    KeyError -> raise(ArgumentError, "candidate command identity is invalid")
  end

  @spec exit_code(map()) :: 0 | 1
  def exit_code(%{state: state}) when state in ["READY FOR APPROVAL", "COMPLETE"], do: 0
  def exit_code(%{state: state}) when state in ["BLOCKED", "STALE", "PARTIAL"], do: 1
  def exit_code(_receipt), do: 1

  defp candidate_input!(opts) do
    cond do
      Keyword.has_key?(opts, :input) ->
        Keyword.fetch!(opts, :input)

      adapter = Keyword.get(opts, :input_adapter) ->
        unless is_function(adapter, 0), do: raise(ArgumentError, "candidate adapter is invalid")
        adapter.()

      true ->
        raise ArgumentError, "candidate observations are unavailable"
    end
  end

  defp validate_run_options!(opts) do
    keys = Keyword.keys(opts)

    unless Keyword.keyword?(opts) and Enum.uniq(keys) == keys and
             Enum.all?(keys, &(&1 in @run_keys)) and
             Enum.all?(~w(version ref output_dir)a, &Keyword.has_key?(opts, &1)) and
             not (Keyword.has_key?(opts, :input) and Keyword.has_key?(opts, :input_adapter)) do
      raise ArgumentError, "candidate command options are invalid"
    end
  end

  defp validate_command_identity!(version, ref, output_dir)
       when is_binary(version) and is_binary(ref) and is_binary(output_dir) do
    unless Regex.match?(@version_pattern, version) and Regex.match?(@sha_pattern, ref) and
             output_dir != "" and not String.contains?(output_dir, <<0>>) do
      raise ArgumentError, "candidate command identity is invalid"
    end
  end

  defp validate_command_identity!(_version, _ref, _output_dir),
    do: raise(ArgumentError, "candidate command identity is invalid")

  defp validate_bound_command_identity!(input, version, ref) when is_map(input) do
    case input do
      %{identity: %{version: ^version, ref: ^ref, head: ^ref}} -> :ok
      _other -> raise ArgumentError, "candidate command identity is invalid"
    end
  end

  defp validate_bound_command_identity!(_input, _version, _ref),
    do: raise(ArgumentError, "candidate command identity is invalid")

  defp write_outputs!(output_dir, json, markdown, github_summary, terminal) do
    ensure_output_directory!(output_dir)

    contents = %{
      json: json,
      markdown: markdown,
      github_summary: github_summary,
      terminal: terminal
    }

    Map.new(@output_files, fn {kind, filename} ->
      path = Path.join(output_dir, filename)
      atomic_write!(path, Map.fetch!(contents, kind))
      {kind, path}
    end)
  rescue
    File.Error -> raise(ArgumentError, "candidate output directory is unavailable")
  end

  defp ensure_output_directory!(output_dir) do
    case File.lstat(output_dir) do
      {:ok, %File.Stat{type: :directory}} -> :ok
      {:ok, _other} -> raise ArgumentError, "candidate output directory is unavailable"
      {:error, :enoent} -> File.mkdir_p!(output_dir)
      {:error, _reason} -> raise ArgumentError, "candidate output directory is unavailable"
    end
  end

  defp atomic_write!(path, bytes) do
    temporary = path <> ".tmp.#{System.unique_integer([:positive, :monotonic])}"

    try do
      File.write!(temporary, bytes, [:binary, :exclusive])
      File.rename!(temporary, path)
    after
      File.rm(temporary)
    end
  end

  defp invalid!, do: raise(ArgumentError, "candidate receipt input is invalid")
end
