defmodule Mix.Tasks.Crosswake.Release.Gate do
  use Mix.Task

  @shortdoc "Validate a fresh REL-17 release evidence envelope"

  @moduledoc """
  Validates a retained envelope against its exact operation and candidate identity.

      mix crosswake.release.gate --operation linked_release --stage post_merge \\
        --package <name> --receipt-digest <sha256> --leg-run-id <id> --merge-oid <sha> \\
        --envelope-file <path> --source-dir <path>

  A PASS is a closed evidence verdict. It does not create or consume authorization.
  """

  @max_envelope_bytes 262_144
  @max_source_bytes 2_097_152
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @digest_pattern ~r/\A[0-9a-f]{64}\z/

  @impl Mix.Task
  def run(args) do
    outcome =
      try do
        Mix.Task.run("app.config")
        options = parse!(args)
        envelope = options.envelope_file |> read_regular!(@max_envelope_bytes) |> Jason.decode!()
        sources = load_sources!(envelope, options.source_dir)

        case Crosswake.ReleaseCandidate.EvidenceGate.validate(envelope, sources) do
          {:ok, result} ->
            if matches_expected?(result, envelope, options) do
              {:pass, result}
            else
              {:blocked, result.stage, result.operation, "identity_mismatch"}
            end

          {:error, reason} ->
            {:blocked, Map.get(envelope, "stage", "unknown"),
             get_in(envelope, ["identity", "operation"]) || "unknown", reason}
        end
      rescue
        _error -> {:blocked, "unknown", "unknown", "invalid_evidence"}
      end

    case outcome do
      {:pass, result} ->
        Mix.shell().info(
          "REL-17 PASS stage=#{result.stage} operation=#{result.operation} next=#{result.next_step}"
        )

      {:blocked, stage, operation, reason} ->
        blocked!(stage, operation, reason)
    end
  end

  defp parse!(args) do
    {opts, argv, invalid} =
      OptionParser.parse(args,
        strict: [
          operation: :string,
          stage: :string,
          package: :string,
          receipt_digest: :string,
          leg_run_id: :integer,
          merge_oid: :string,
          envelope_file: :string,
          source_dir: :string
        ]
      )

    required =
      ~w(operation stage package receipt_digest leg_run_id merge_oid envelope_file source_dir)a

    unless invalid == [] and argv == [] and Enum.sort(Keyword.keys(opts)) == Enum.sort(required) and
             Enum.all?(required, &Keyword.has_key?(opts, &1)),
           do: Mix.raise("invalid REL-17 gate command")

    values = Map.new(opts)

    unless values.operation in ~w(linked_release recovery companion_publish) and
             values.stage == "post_merge" and is_binary(values.package) and
             values.package != "" and is_integer(values.leg_run_id) and
             values.leg_run_id > 0 and
             is_binary(values.receipt_digest) and
             Regex.match?(@digest_pattern, values.receipt_digest) and
             is_binary(values.merge_oid) and Regex.match?(@sha_pattern, values.merge_oid) and
             is_binary(values.envelope_file) and values.envelope_file != "" and
             is_binary(values.source_dir) and values.source_dir != "",
           do: Mix.raise("invalid REL-17 gate command")

    values
  end

  defp load_sources!(%{"conditions" => conditions}, source_dir) when is_map(conditions) do
    root = Path.expand(source_dir)

    Map.new(conditions, fn {_id, condition} ->
      path = condition["source_path"]

      unless safe_relative_path?(path), do: Mix.raise("invalid REL-17 evidence source")

      full_path = Path.expand(path, root)

      unless String.starts_with?(full_path, root <> "/"),
        do: Mix.raise("invalid REL-17 evidence source")

      {path, read_regular!(full_path, @max_source_bytes)}
    end)
  end

  defp load_sources!(_, _), do: Mix.raise("invalid REL-17 evidence envelope")

  defp read_regular!(path, max_bytes) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :regular, size: size}} when size >= 1 and size <= max_bytes ->
        File.read!(path)

      _ ->
        Mix.raise("invalid REL-17 evidence file")
    end
  end

  defp matches_expected?(result, envelope, options) do
    identity = envelope["identity"]
    candidate = envelope["candidate"]

    result.stage == options.stage and result.operation == options.operation and
      identity["receipt_digest"] == options.receipt_digest and
      identity["leg_run_id"] == options.leg_run_id and candidate["merge_oid"] == options.merge_oid and
      candidate["package"] == options.package
  end

  defp blocked!(stage, operation, reason) do
    Mix.raise(
      "REL-17 BLOCKED stage=#{safe_label(stage)} operation=#{safe_label(operation)} " <>
        "reason=#{safe_label(reason)} next=gather_fresh_evidence_and_request_a_new_gate"
    )
  end

  defp safe_label(value) when is_binary(value) do
    if Regex.match?(~r/\A[a-zA-Z0-9_-]{1,40}\z/, value), do: value, else: "invalid"
  end

  defp safe_label(_), do: "unknown"

  defp safe_relative_path?(path) when is_binary(path) do
    Path.type(path) == :relative and path != "" and not String.contains?(path, <<0>>) and
      Enum.all?(Path.split(path), &(&1 not in [".", "..", ""]))
  end

  defp safe_relative_path?(_), do: false
end
