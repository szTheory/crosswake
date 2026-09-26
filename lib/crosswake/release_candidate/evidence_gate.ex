defmodule Crosswake.ReleaseCandidate.EvidenceGate do
  @moduledoc """
  Validates a versioned REL-17 evidence envelope without performing I/O.

  Evidence sources are supplied as path-to-bytes values so the caller can fetch and retain them
  before validation. A passing pre-merge envelope is evidence readiness only; it does not authorize
  a release side effect.
  """

  @operations ~w(linked_release recovery companion_publish)
  @companion_packages Crosswake.ReleaseCandidate.Artifact.packages() |> tl()
  @condition_ids ~w(
    leg_run
    candidate_readiness
    registry_response
    protected_merge
    response_row
    runbook_ancestry
  )
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @version_pattern ~r/\A\d+\.\d+\.\d+\z/
  @max_source_bytes 2_097_152

  @type result ::
          {:ok,
           %{
             required(:stage) => String.t(),
             required(:operation) => String.t(),
             optional(:next_step) => String.t()
           }}
          | {:error, String.t()}

  @spec validate(map(), map()) :: result()
  def validate(envelope, sources) when is_map(envelope) and is_map(sources) do
    with :ok <-
           exact_keys(
             envelope,
             ~w(schema_version identity stage candidate authorization conditions)
           ),
         :ok <- valid_schema(envelope),
         {:ok, identity} <- validate_identity(envelope["identity"]),
         {:ok, candidate} <-
           validate_candidate(envelope["candidate"], envelope["stage"], identity.operation),
         :ok <-
           validate_authorization(
             envelope["authorization"],
             identity,
             candidate,
             envelope["stage"]
           ),
         {:ok, conditions} <-
           validate_conditions(
             envelope["conditions"],
             sources,
             identity,
             candidate,
             envelope["stage"]
           ) do
      _ = conditions

      next_step =
        if envelope["stage"] == "pre_merge",
          do: "request_exact_gate",
          else: "continue_exact_authorized_operation"

      result = %{stage: envelope["stage"], operation: identity.operation, next_step: next_step}

      {:ok, result}
    end
  rescue
    _error -> {:error, "invalid_envelope"}
  end

  def validate(nil, _sources), do: {:error, "missing_evidence"}
  def validate(_envelope, _sources), do: {:error, "invalid_envelope"}

  @doc """
  Returns the read-only operator projection of the closed validator result.

  A passing envelope describes evidence only; it never records or consumes authorization.
  """
  @spec status(map() | nil, map()) :: map()
  def status(envelope, sources) do
    case validate(envelope, sources) do
      {:ok, %{stage: stage, operation: operation, next_step: next_step}} ->
        %{
          state: "EVIDENCE_VALID",
          condition: "all_conditions_pass",
          operation: operation,
          stage: stage,
          next_step: next_step
        }

      {:error, reason} ->
        %{
          state: "BLOCKED",
          condition: reason,
          operation: "unknown",
          stage: "unknown",
          next_step: "gather fresh evidence and request a new gate"
        }
    end
  end

  defp valid_schema(%{"schema_version" => 1, "stage" => stage})
       when stage in ["pre_merge", "post_merge"],
       do: :ok

  defp valid_schema(_), do: {:error, "invalid_envelope"}

  defp validate_identity(value) when is_map(value) do
    with :ok <- exact_keys(value, ~w(receipt_digest operation leg_run_id)),
         :ok <- check(digest?(value["receipt_digest"]), "identity_mismatch"),
         :ok <- check(value["operation"] in @operations, "invalid_operation"),
         :ok <- check(positive_integer?(value["leg_run_id"]), "identity_mismatch") do
      {:ok,
       %{
         receipt_digest: value["receipt_digest"],
         operation: value["operation"],
         leg_run_id: value["leg_run_id"]
       }}
    end
  end

  defp validate_identity(_), do: {:error, "identity_mismatch"}

  defp validate_candidate(value, stage, operation) when is_map(value) do
    with :ok <- exact_keys(value, ~w(package pr version base_oid head_oid tree_oid merge_oid)),
         :ok <- check(valid_package?(value["package"], operation), "candidate_mismatch"),
         :ok <- check(positive_integer?(value["pr"]), "candidate_mismatch"),
         :ok <- check(version?(value["version"]), "candidate_mismatch"),
         :ok <-
           check(
             sha?(value["base_oid"]) and sha?(value["head_oid"]) and sha?(value["tree_oid"]),
             "candidate_mismatch"
           ),
         :ok <-
           check(
             (stage == "pre_merge" and is_nil(value["merge_oid"])) or
               (stage == "post_merge" and sha?(value["merge_oid"])),
             "candidate_mismatch"
           ) do
      {:ok,
       %{
         package: value["package"],
         pr: value["pr"],
         version: value["version"],
         base_oid: value["base_oid"],
         head_oid: value["head_oid"],
         tree_oid: value["tree_oid"],
         merge_oid: value["merge_oid"]
       }}
    end
  end

  defp validate_candidate(_, _, _), do: {:error, "candidate_mismatch"}

  defp validate_authorization(value, identity, candidate, stage) when is_map(value) do
    expected_state = if stage == "pre_merge", do: "PENDING", else: "CONSUMED"

    with :ok <-
           exact_keys(
             value,
             ~w(stage state receipt_digest operation leg_run_id candidate_package candidate_head)
           ),
         :ok <-
           check(
             value["stage"] == "pre_merge" and value["state"] == expected_state,
             "authorization_mismatch"
           ),
         :ok <-
           check(value["receipt_digest"] == identity.receipt_digest, "authorization_mismatch"),
         :ok <- check(value["operation"] == identity.operation, "authorization_mismatch"),
         :ok <- check(value["leg_run_id"] == identity.leg_run_id, "authorization_mismatch"),
         :ok <- check(value["candidate_package"] == candidate.package, "authorization_mismatch"),
         :ok <- check(value["candidate_head"] == candidate.head_oid, "authorization_mismatch") do
      :ok
    end
  end

  defp validate_authorization(_, _, _, _), do: {:error, "authorization_mismatch"}

  defp validate_conditions(value, sources, identity, candidate, stage)
       when is_map(value) and is_map(sources) do
    with :ok <- exact_keys(value, @condition_ids),
         {:ok, loaded} <- validate_sources(value, sources),
         :ok <-
           validate_leg_run(
             value["leg_run"]["facts"],
             value["leg_run"],
             loaded,
             identity,
             candidate
           ),
         :ok <-
           validate_candidate_readiness(
             value["candidate_readiness"]["facts"],
             value["candidate_readiness"],
             loaded,
             identity,
             candidate
           ),
         :ok <-
           validate_registry(
             value["registry_response"]["facts"],
             loaded,
             value["registry_response"],
             candidate
           ),
         :ok <-
           validate_merge(
             value["protected_merge"]["facts"],
             value["protected_merge"],
             loaded,
             candidate,
             stage
           ),
         :ok <-
           validate_response_row(
             value["response_row"]["facts"],
             value["response_row"],
             loaded,
             identity,
             candidate
           ),
         :ok <-
           validate_ancestry(
             value["runbook_ancestry"]["facts"],
             value["runbook_ancestry"],
             loaded,
             candidate,
             stage
           ) do
      {:ok, loaded}
    end
  end

  defp validate_conditions(_, _, _, _, _), do: {:error, "condition_failed"}

  defp validate_sources(conditions, sources) do
    entries = Enum.map(conditions, fn {_id, evidence} -> evidence end)

    with :ok <- check(Enum.all?(entries, &is_map/1), "source_mismatch"),
         :ok <-
           check(
             Enum.all?(
               entries,
               &(Map.keys(&1) |> Enum.sort() ==
                   ~w(facts raw_source_path raw_source_sha256 source_path source_sha256))
             ),
             "source_mismatch"
           ),
         paths <- Enum.flat_map(entries, &[&1["source_path"], &1["raw_source_path"]]),
         :ok <- check(length(paths) == length(Enum.uniq(paths)), "source_mismatch"),
         :ok <- check(Enum.sort(Map.keys(sources)) == Enum.sort(paths), "source_mismatch"),
         {:ok, loaded} <- load_sources(entries, sources) do
      {:ok, loaded}
    end
  end

  defp load_sources(entries, sources) do
    Enum.reduce_while(entries, {:ok, %{}}, fn entry, {:ok, loaded} ->
      path = entry["source_path"]
      bytes = Map.get(sources, path)
      raw_path = entry["raw_source_path"]
      raw_bytes = Map.get(sources, raw_path)

      valid? =
        safe_relative_path?(path) and is_binary(bytes) and
          byte_size(bytes) in 1..@max_source_bytes and
          digest(bytes) == entry["source_sha256"] and digest?(entry["source_sha256"])

      raw_valid? =
        safe_relative_path?(raw_path) and is_binary(raw_bytes) and
          byte_size(raw_bytes) in 1..@max_source_bytes and
          digest(raw_bytes) == entry["raw_source_sha256"] and
          digest?(entry["raw_source_sha256"])

      if valid? and raw_valid? do
        {:cont, {:ok, loaded |> Map.put(path, bytes) |> Map.put(raw_path, raw_bytes)}}
      else
        {:halt, {:error, "source_mismatch"}}
      end
    end)
  end

  defp validate_leg_run(facts, evidence, loaded, identity, candidate) when is_map(facts) do
    with :ok <- exact_keys(facts, ~w(run_id head_oid conclusion)),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <-
           check(
             facts["run_id"] == identity.leg_run_id and facts["head_oid"] == candidate.head_oid and
               facts["conclusion"] == "success",
             "condition_failed"
           ) do
      :ok
    end
  end

  defp validate_leg_run(_, _, _, _, _), do: {:error, "condition_failed"}

  defp validate_candidate_readiness(facts, evidence, loaded, identity, candidate)
       when is_map(facts) do
    with :ok <-
           exact_keys(
             facts,
             ~w(package receipt_digest base_oid head_oid tree_oid merge_state ci_run_id ci_conclusion required_check_ids required_checks_complete policy_sha256 policy_current pagination_complete receipt_artifact_id receipt_artifact_live)
           ),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <-
           check(
             facts["package"] == candidate.package and
               facts["receipt_digest"] == identity.receipt_digest,
             "identity_mismatch"
           ),
         :ok <-
           check(
             facts["base_oid"] == candidate.base_oid and facts["head_oid"] == candidate.head_oid and
               facts["tree_oid"] == candidate.tree_oid,
             "condition_failed"
           ),
         :ok <-
           check(
             positive_integer?(facts["ci_run_id"]) and
               is_list(facts["required_check_ids"]) and
               "Crosswake CI" in facts["required_check_ids"] and
               Enum.all?(facts["required_check_ids"], &is_binary/1) and
               facts["required_check_ids"] == Enum.uniq(facts["required_check_ids"]),
             "condition_failed"
           ),
         :ok <-
           check(
             digest?(facts["policy_sha256"]) and facts["pagination_complete"] == true and
               positive_integer?(facts["receipt_artifact_id"]) and
               facts["receipt_artifact_live"] == true,
             "condition_failed"
           ),
         :ok <-
           check(
             facts["merge_state"] == "MERGEABLE" and facts["ci_conclusion"] == "success" and
               facts["required_checks_complete"] == true and facts["policy_current"] == true,
             "condition_failed"
           ) do
      :ok
    end
  end

  defp validate_candidate_readiness(_, _, _, _, _), do: {:error, "condition_failed"}

  defp validate_registry(facts, loaded, evidence, candidate) when is_map(facts) do
    with :ok <- exact_keys(facts, ~w(package version parsed)),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <-
           check(
             facts["package"] == candidate.package and facts["version"] == candidate.version,
             "condition_failed"
           ),
         {:ok, body} <- Map.fetch(loaded, evidence["raw_source_path"]),
         {:ok, parsed} <- Jason.decode(body),
         true <- parsed == facts["parsed"],
         %{"releases" => releases} when is_list(releases) and releases != [] <- parsed do
      :ok
    else
      _ -> {:error, "invalid_registry_response"}
    end
  end

  defp validate_registry(_, _, _, _), do: {:error, "invalid_registry_response"}

  defp validate_merge(facts, evidence, loaded, _candidate, "pre_merge") when is_map(facts) do
    with :ok <- exact_keys(facts, ~w(merge_ready)),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <- check(facts["merge_ready"] == true, "condition_failed") do
      :ok
    end
  end

  defp validate_merge(facts, evidence, loaded, candidate, "post_merge") when is_map(facts) do
    with :ok <- exact_keys(facts, ~w(merge_oid parents normal_protected_path admin_bypass)),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <- check(facts["merge_oid"] == candidate.merge_oid, "condition_failed"),
         :ok <-
           check(facts["parents"] == [candidate.base_oid, candidate.head_oid], "condition_failed"),
         :ok <-
           check(
             facts["normal_protected_path"] == true and facts["admin_bypass"] == false,
             "condition_failed"
           ) do
      :ok
    end
  end

  defp validate_merge(_, _, _, _, _), do: {:error, "condition_failed"}

  defp validate_response_row(facts, evidence, loaded, identity, candidate) when is_map(facts) do
    with :ok <- exact_keys(facts, ~w(run_id package version candidate_ref)),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <-
           check(
             facts["run_id"] == identity.leg_run_id and facts["package"] == candidate.package and
               facts["version"] == candidate.version and
               facts["candidate_ref"] == candidate.head_oid,
             "condition_failed"
           ) do
      :ok
    end
  end

  defp validate_response_row(_, _, _, _, _), do: {:error, "condition_failed"}

  defp validate_ancestry(facts, evidence, loaded, candidate, stage) when is_map(facts) do
    with :ok <-
           exact_keys(
             facts,
             ~w(runbook_commit base_is_ancestor head_is_ancestor merge_is_ancestor)
           ),
         :ok <- source_matches_facts(evidence, loaded, facts),
         :ok <- check(sha?(facts["runbook_commit"]), "condition_failed"),
         :ok <-
           check(
             facts["base_is_ancestor"] == true and facts["head_is_ancestor"] == true,
             "condition_failed"
           ),
         :ok <- check(facts["merge_is_ancestor"] == (stage == "post_merge"), "condition_failed"),
         :ok <- check(stage != "post_merge" or sha?(candidate.merge_oid), "condition_failed") do
      :ok
    end
  end

  defp validate_ancestry(_, _, _, _, _), do: {:error, "condition_failed"}

  defp source_matches_facts(evidence, loaded, facts) do
    case Map.fetch(loaded, evidence["source_path"]) do
      {:ok, bytes} ->
        case Jason.decode(bytes) do
          {:ok, ^facts} -> :ok
          _ -> {:error, "source_mismatch"}
        end

      :error ->
        {:error, "source_mismatch"}
    end
  end

  defp exact_keys(value, keys) when is_map(value) do
    check(Enum.sort(Map.keys(value)) == Enum.sort(keys), "invalid_envelope")
  end

  defp exact_keys(_, _), do: {:error, "invalid_envelope"}

  defp check(true, _reason), do: :ok
  defp check(false, reason), do: {:error, reason}

  defp safe_relative_path?(path) when is_binary(path) do
    Path.type(path) == :relative and path != "" and not String.contains?(path, <<0>>) and
      Enum.all?(Path.split(path), &(&1 not in [".", "..", ""]))
  end

  defp safe_relative_path?(_), do: false

  defp valid_package?("crosswake", operation) when operation in ["linked_release", "recovery"],
    do: true

  defp valid_package?(package, "companion_publish"), do: package in @companion_packages
  defp valid_package?(_, _), do: false
  defp positive_integer?(value), do: is_integer(value) and value > 0
  defp sha?(value), do: is_binary(value) and Regex.match?(@sha_pattern, value)
  defp digest?(value), do: is_binary(value) and Regex.match?(@digest_pattern, value)
  defp version?(value), do: is_binary(value) and Regex.match?(@version_pattern, value)

  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
