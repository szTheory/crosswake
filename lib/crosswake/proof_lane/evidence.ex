defmodule Crosswake.ProofLane.Evidence do
  @moduledoc "Builds and atomically promotes the proof lane's small opaque evidence record."

  @outcomes ~w(passed blocked unavailable)
  @allowed_keys [:assertion_id, :outcome]

  @spec build(map()) :: {:ok, map()} | {:error, {String.t(), String.t()}}
  def build(input) when is_map(input) do
    keys = Map.keys(input)

    cond do
      Enum.any?(keys, &(&1 not in @allowed_keys)) ->
        {:error, {"proof_lane_evidence.unknown_key", "input"}}

      not is_binary(input[:assertion_id]) or
          not String.match?(input[:assertion_id], ~r/^[a-z][a-z0-9_]{0,63}$/) ->
        {:error, {"proof_lane_evidence.invalid_assertion", "assertion_id"}}

      input[:outcome] not in @outcomes ->
        {:error, {"proof_lane_evidence.invalid_outcome", "outcome"}}

      true ->
        {:ok, %{schema_version: 1, assertion_id: input[:assertion_id], outcome: input[:outcome]}}
    end
  end

  def build(_), do: {:error, {"proof_lane_evidence.invalid_input", "input"}}

  @spec promote(map(), Path.t()) :: :ok | {:error, {String.t(), String.t()}}
  def promote(evidence, destination) when is_map(evidence) and is_binary(destination) do
    with :ok <- safe_destination(destination),
         :ok <- ensure_absent(destination) do
      stage = destination <> ".stage-" <> Integer.to_string(System.unique_integer([:positive]))

      try do
        with :ok <- File.mkdir_p(stage),
             :ok <- File.write(Path.join(stage, "evidence.json"), Jason.encode!(evidence)),
             :ok <- scan(stage),
             :ok <- File.rename(stage, destination) do
          :ok
        else
          {:error, _} -> {:error, {"proof_lane_evidence.promotion_failed", "artifact"}}
        end
      after
        File.rm_rf(stage)
      end
    end
  end

  def promote(_, _), do: {:error, {"proof_lane_evidence.invalid_destination", "artifact"}}

  defp safe_destination(path) do
    if Path.type(path) == :absolute and not String.contains?(path, ".."),
      do: :ok,
      else: {:error, {"proof_lane_evidence.unsafe_path", "artifact"}}
  end

  defp ensure_absent(path) do
    if File.exists?(path),
      do: {:error, {"proof_lane_evidence.destination_exists", "artifact"}},
      else: :ok
  end

  defp scan(stage) do
    case Path.wildcard(Path.join(stage, "**/*")) |> Enum.filter(&File.regular?/1) do
      [file] ->
        case Jason.decode(File.read!(file)) do
          {:ok, %{"schema_version" => 1, "assertion_id" => assertion, "outcome" => outcome}}
          when is_binary(assertion) and outcome in @outcomes ->
            :ok

          _ ->
            {:error, :unsafe}
        end

      _ ->
        {:error, :unsafe}
    end
  end
end
