defmodule Mix.Tasks.Crosswake.Release.Receipt do
  use Mix.Task

  @shortdoc "Create a local package-scoped REL-17 companion receipt"

  @moduledoc """
  Builds a deterministic companion receipt from source-bound local evidence.

      mix crosswake.release.receipt --input <evidence.json> --output <receipt.json>

  The task writes evidence only. It never authorizes a merge or publication.
  """

  @max_input_bytes 16_777_216

  @impl Mix.Task
  def run(args) do
    outcome =
      try do
        Mix.Task.run("app.config")
        options = parse!(args)
        input = options.input |> read_regular!() |> Jason.decode!()

        case Crosswake.ReleaseCandidate.CompanionReceipt.build(input) do
          {:ok, receipt} -> {:ok, options.output, receipt}
          {:error, reason} -> {:blocked, reason}
        end
      rescue
        _error -> {:blocked, "invalid_input"}
      end

    case outcome do
      {:ok, output, receipt} ->
        artifact = %{
          "schema_version" => 1,
          "receipt" => receipt.receipt,
          "receipt_digest" => receipt.digest
        }

        case write_artifact(output, artifact) do
          :ok ->
            Mix.shell().info(
              "REL-17 RECEIPT PASS package=#{receipt.receipt["package"]} " <>
                "digest=#{receipt.digest} next=request_exact_gate"
            )

          :error ->
            Mix.raise(
              "REL-17 RECEIPT BLOCKED reason=write_failed next=review_local_evidence_path"
            )
        end

      {:blocked, reason} ->
        Mix.raise(
          "REL-17 RECEIPT BLOCKED reason=#{safe_reason(reason)} next=gather_fresh_evidence"
        )
    end
  end

  defp parse!(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args, strict: [input: :string, output: :string])

    required = ~w(input output)a

    unless invalid == [] and argv == [] and Enum.sort(Keyword.keys(opts)) == Enum.sort(required) and
             Enum.all?(
               required,
               &(is_binary(Keyword.get(opts, &1)) and Keyword.get(opts, &1) != "")
             ),
           do: Mix.raise("invalid REL-17 receipt command")

    Map.new(opts)
  end

  defp read_regular!(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular, size: size}} when size >= 1 and size <= @max_input_bytes ->
        File.read!(path)

      _ ->
        Mix.raise("invalid REL-17 receipt input")
    end
  end

  defp safe_reason(reason) when is_binary(reason) do
    if Regex.match?(~r/\A[a-z_]{1,40}\z/, reason), do: reason, else: "invalid_evidence"
  end

  defp safe_reason(_), do: "invalid_evidence"

  defp write_artifact(path, artifact) do
    case File.write(path, Jason.encode!(artifact) <> "\n", [:binary, :exclusive]) do
      :ok -> :ok
      {:error, _reason} -> :error
    end
  rescue
    _error -> :error
  end
end
