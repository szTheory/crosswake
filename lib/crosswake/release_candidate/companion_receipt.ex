defmodule Crosswake.ReleaseCandidate.CompanionReceipt do
  @moduledoc """
  Builds a deterministic receipt for one independently published companion package.

  The builder accepts only exact, source-bound candidate, CI, rehearsal, and package-row facts.
  It does not authorize a merge or publication.
  """

  alias Crosswake.ReleaseCandidate.Artifact

  @input_keys ~w(package version candidate ci hex_rehearsal package_row sources)
  @source_ids ~w(candidate ci hex_rehearsal package_row)
  @companion_packages Artifact.packages() |> tl()
  @package_keys ~w(candidate_ref metadata_digest outer_checksum package run_id version payload_digest)
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @max_source_bytes 2_097_152

  @spec build(map()) :: {:ok, map()} | {:error, String.t()}
  def build(input) when is_map(input) do
    with :ok <- exact_keys(input, @input_keys),
         package when is_binary(package) <- input["package"],
         :ok <- check(package in @companion_packages, "invalid_package"),
         version when is_binary(version) <- input["version"],
         true <- Regex.match?(@version_pattern, version),
         {:ok, candidate} <- validate_candidate(input["candidate"]),
         :ok <- validate_ci(input["ci"], candidate),
         :ok <- validate_hex_rehearsal(input["hex_rehearsal"], package, version, candidate),
         :ok <-
           validate_package_row(
             input["package_row"],
             package,
             version,
             candidate,
             input["hex_rehearsal"]
           ),
         {:ok, proofs} <-
           validate_sources(
             input["sources"],
             candidate,
             input["ci"],
             input["hex_rehearsal"],
             input["package_row"]
           ) do
      receipt = %{
        "schema_version" => 1,
        "package" => package,
        "version" => version,
        "candidate" => candidate,
        "ci" => input["ci"],
        "hex_run_id" => input["hex_rehearsal"]["run_id"],
        "package_row" => input["package_row"],
        "external_state_changed" => false,
        "target_absent" => true,
        "proofs" => proofs
      }

      canonical_bytes = canonical_json(receipt)

      {:ok,
       %{
         receipt: receipt,
         canonical_bytes: canonical_bytes,
         digest: digest(canonical_bytes)
       }}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, "invalid_companion_evidence"}
    end
  rescue
    _error -> {:error, "invalid_companion_evidence"}
  end

  def build(_input), do: {:error, "invalid_companion_evidence"}

  defp validate_candidate(value) when is_map(value) do
    with :ok <- exact_keys(value, ~w(pr base_oid head_oid tree_oid ci_run_id)),
         :ok <- check(positive_integer?(value["pr"]), "invalid_candidate"),
         :ok <-
           check(
             sha?(value["base_oid"]) and sha?(value["head_oid"]) and sha?(value["tree_oid"]),
             "invalid_candidate"
           ),
         :ok <- check(positive_integer?(value["ci_run_id"]), "invalid_candidate") do
      {:ok, value}
    end
  end

  defp validate_candidate(_), do: {:error, "invalid_candidate"}

  defp validate_ci(value, candidate) when is_map(value) do
    with :ok <- exact_keys(value, ~w(run_id head_oid conclusion)),
         :ok <- check(value["run_id"] == candidate["ci_run_id"], "stale_ci"),
         :ok <-
           check(
             value["head_oid"] == candidate["head_oid"] and value["conclusion"] == "success",
             "stale_ci"
           ) do
      :ok
    end
  end

  defp validate_ci(_, _), do: {:error, "stale_ci"}

  defp validate_hex_rehearsal(value, package, version, candidate) when is_map(value) do
    with :ok <-
           exact_keys(
             value,
             ~w(run_id head_oid package version external_state_changed target_absent)
           ),
         :ok <- check(positive_integer?(value["run_id"]), "stale_hex_run"),
         :ok <- check(value["head_oid"] == candidate["head_oid"], "stale_hex_run"),
         :ok <-
           check(value["package"] == package and value["version"] == version, "package_mismatch"),
         :ok <-
           check(
             value["external_state_changed"] == false and value["target_absent"] == true,
             "unsafe_rehearsal"
           ) do
      :ok
    end
  end

  defp validate_hex_rehearsal(_, _, _, _), do: {:error, "stale_hex_run"}

  defp validate_package_row(value, package, version, candidate, rehearsal) when is_map(value) do
    with :ok <- exact_keys(value, @package_keys),
         :ok <- check(value["run_id"] == rehearsal["run_id"], "stale_hex_run"),
         :ok <- check(value["candidate_ref"] == candidate["head_oid"], "stale_hex_run"),
         :ok <-
           check(value["package"] == package and value["version"] == version, "package_mismatch"),
         :ok <-
           check(
             Enum.all?(~w(metadata_digest outer_checksum payload_digest), &digest?(value[&1])),
             "invalid_package_row"
           ) do
      :ok
    end
  end

  defp validate_package_row(_, _, _, _, _), do: {:error, "invalid_package_row"}

  defp validate_sources(sources, candidate, ci, rehearsal, package_row) when is_map(sources) do
    expected = %{
      "candidate" => candidate,
      "ci" => ci,
      "hex_rehearsal" => rehearsal,
      "package_row" => package_row
    }

    with :ok <- exact_keys(sources, @source_ids),
         {:ok, proofs} <- collect_proofs(sources, expected) do
      {:ok, proofs}
    end
  end

  defp validate_sources(_, _, _, _, _), do: {:error, "missing_source"}

  defp collect_proofs(sources, expected) do
    Enum.reduce_while(@source_ids, {:ok, []}, fn id, {:ok, proofs} ->
      source = Map.get(sources, id)

      with true <- is_map(source),
           :ok <- exact_keys(source, ~w(path bytes)),
           path when is_binary(path) <- source["path"],
           true <- safe_relative_path?(path),
           bytes when is_binary(bytes) and byte_size(bytes) in 1..@max_source_bytes <-
             source["bytes"],
           {:ok, decoded} <- Jason.decode(bytes),
           true <- decoded == Map.fetch!(expected, id) do
        proof = %{"id" => id, "path" => path, "sha256" => digest(bytes)}
        {:cont, {:ok, [proof | proofs]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
        _ -> {:halt, {:error, "source_mismatch"}}
      end
    end)
    |> case do
      {:ok, proofs} -> {:ok, Enum.reverse(proofs)}
      error -> error
    end
  end

  defp canonical_json(value) when is_map(value) do
    entries =
      value
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map(fn {key, nested} -> Jason.encode!(key) <> ":" <> canonical_json(nested) end)

    "{" <> Enum.join(entries, ",") <> "}"
  end

  defp canonical_json(value) when is_list(value),
    do: "[" <> (value |> Enum.map(&canonical_json/1) |> Enum.join(",")) <> "]"

  defp canonical_json(value), do: Jason.encode!(value)

  defp exact_keys(value, keys) when is_map(value) do
    check(Enum.sort(Map.keys(value)) == Enum.sort(keys), "invalid_companion_evidence")
  end

  defp exact_keys(_, _), do: {:error, "invalid_companion_evidence"}
  defp check(true, _reason), do: :ok
  defp check(false, reason), do: {:error, reason}
  defp positive_integer?(value), do: is_integer(value) and value > 0
  defp sha?(value), do: is_binary(value) and Regex.match?(@sha_pattern, value)
  defp digest?(value), do: is_binary(value) and Regex.match?(@digest_pattern, value)
  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp safe_relative_path?(path) when is_binary(path) do
    Path.type(path) == :relative and path != "" and not String.contains?(path, <<0>>) and
      Enum.all?(Path.split(path), &(&1 not in [".", "..", ""]))
  end

  defp safe_relative_path?(_), do: false
end
