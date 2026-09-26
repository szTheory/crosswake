defmodule Crosswake.ReleaseCandidate.EvidenceLive do
  @moduledoc """
  Captures a new REL-17 evidence envelope from GitHub, Git and Hex at the point of use.

  The adapter accepts an HTTP function and a Git ancestry function for deterministic tests.
  Production requests use `gh api` for GitHub and `curl` for public Hex responses. No result is
  cached and remote bodies are retained before decoding.
  """

  @max_bytes 2_097_152
  @max_capture_bytes 16_777_216
  @max_pages 100
  @sha_pattern ~r/\A[0-9a-f]{40}\z/
  @digest_pattern ~r/\A[0-9a-f]{64}\z/
  @runbook_path "docs/RELEASE-INCIDENT-RESPONSE.md"
  @candidate_artifact_prefix "phase168-candidate-receipt-"
  @repository "szTheory/crosswake"

  @type capture_result ::
          {:ok, %{envelope: map(), sources: map(), source_dir: String.t()}} | {:error, String.t()}

  @spec capture(keyword()) :: capture_result()
  def capture(opts) when is_list(opts) do
    with {:ok, input} <- validate_options(opts),
         :ok <- initialize_source_dir(input.source_dir),
         fetch <- Keyword.get(opts, :http, &http_get/1),
         fetch <- recording_fetch(fetch, input.source_dir),
         git_ancestor <- Keyword.get(opts, :git_ancestor, &git_ancestor?/2),
         {:ok, pr, pr_raw} <- get_json(fetch, api(input, "/pulls/#{input.pr}")),
         {:ok, base_oid, head_oid} <- candidate_oids(pr, input),
         {:ok, head_commit, head_commit_raw} <-
           get_json(fetch, api(input, "/commits/#{head_oid}")),
         {:ok, tree_oid} <- candidate_tree(head_commit, input),
         {:ok, checks, checks_raw} <-
           get_pages(fetch, api(input, "/commits/#{head_oid}/check-runs?per_page=100"),
             collection: "check_runs",
             total: true
           ),
         {:ok, ci_run, ci_raw} <- get_json(fetch, api(input, "/actions/runs/#{input.ci_run_id}")),
         :ok <- same_head_ci(ci_run, input, head_oid),
         {:ok, protection, protection_raw} <-
           get_json(fetch, api(input, "/branches/#{encode_ref(pr["base"]["ref"])}/protection")),
         {:ok, rulesets, ruleset_pages_raw} <-
           get_pages(fetch, api(input, "/rulesets?per_page=100"), collection: :list),
         {:ok, policy, _policy_raw} <-
           read_policy(fetch, input, protection, rulesets, protection_raw, ruleset_pages_raw),
         :ok <- expected_policy(policy.sha256, input.expected_policy_sha256),
         :ok <- required_checks_pass(checks, policy.required_checks, head_oid),
         {:ok, receipt_run, receipt_run_raw} <-
           get_json(fetch, api(input, "/actions/runs/#{input.receipt_run_id}")),
         :ok <- same_candidate_receipt_run(receipt_run, input, head_oid),
         {:ok, receipt_artifacts, artifact_pages_raw} <-
           get_pages(
             fetch,
             api(input, "/actions/runs/#{input.receipt_run_id}/artifacts?per_page=100"),
             collection: "artifacts",
             total: true
           ),
         {:ok, receipt_artifact} <-
           matching_receipt_artifact(receipt_artifacts, input, head_oid),
         {:ok, leg_run, leg_raw} <-
           get_json(fetch, api(input, "/actions/runs/#{input.leg_run_id}")),
         :ok <- matching_leg_run(leg_run, input, head_oid),
         {:ok, registry_response} <- fetch_registry(input, fetch),
         {:ok, registry} <- parse_registry(registry_response.body, input),
         {:ok, merge_data, merge_raw} <- fetch_merge(fetch, input, pr, base_oid, head_oid),
         {:ok, ancestry_facts, ancestry_raw} <-
           check_ancestry(git_ancestor, input, base_oid, head_oid, merge_data.merge_oid),
         :ok <- validate_authorization(input, head_oid),
         {:ok, captured} <-
           build_capture(
             input,
             %{base_oid: base_oid, head_oid: head_oid, tree_oid: tree_oid},
             %{
               pr: pr_raw,
               head_commit: head_commit_raw,
               checks: checks_raw,
               ci: ci_raw,
               receipt_run: receipt_run_raw
             },
             policy,
             %{
               artifacts: artifact_pages_raw,
               artifact: Jason.encode!(receipt_artifact),
               facts: receipt_artifact
             },
             %{leg_run: leg_raw},
             %{registry: registry_response.body, registry_facts: registry.facts},
             merge_data,
             merge_raw,
             ancestry_facts,
             ancestry_raw
           ) do
      {:ok, captured}
    else
      {:error, code} when is_binary(code) -> {:error, safe_code(code)}
      _ -> {:error, "invalid_evidence"}
    end
  rescue
    _error -> {:error, "invalid_evidence"}
  end

  def capture(_), do: {:error, "invalid_evidence"}

  @doc false
  def fetch_pages(fetch, url, opts \\ []) when is_function(fetch, 1) do
    get_pages(fetch, url, opts)
  end

  defp validate_options(opts) do
    required =
      ~w(operation stage package version pr receipt_digest leg_run_id ci_run_id receipt_run_id receipt_artifact_id repository runbook_commit expected_policy_sha256 expected_base_oid expected_head_oid expected_tree_oid source_dir authorization)a

    values = Map.new(opts)

    valid? =
      Enum.all?(required, &Keyword.has_key?(opts, &1)) and
        values.operation in ["linked_release", "recovery", "companion_publish"] and
        values.stage in ["pre_merge", "post_merge"] and
        is_binary(values.package) and values.package != "" and
        valid_operation_package?(values.operation, values.package) and
        is_binary(values.version) and Regex.match?(~r/\A\d+\.\d+\.\d+\z/, values.version) and
        is_integer(values.pr) and values.pr > 0 and
        Enum.all?(
          ~w(leg_run_id ci_run_id receipt_run_id receipt_artifact_id)a,
          &(is_integer(values[&1]) and values[&1] > 0)
        ) and
        Regex.match?(@digest_pattern, values.receipt_digest) and
        Regex.match?(@digest_pattern, values.expected_policy_sha256) and
        Regex.match?(@sha_pattern, values.runbook_commit) and
        Regex.match?(@sha_pattern, values.expected_base_oid) and
        Regex.match?(@sha_pattern, values.expected_head_oid) and
        Regex.match?(@sha_pattern, values.expected_tree_oid) and
        valid_repo?(values.repository) and values.repository == @repository and
        is_binary(values.source_dir) and
        values.source_dir != "" and
        ((values.stage == "pre_merge" and is_nil(values[:merge_oid])) or
           (values.stage == "post_merge" and is_binary(values[:merge_oid]) and
              Regex.match?(@sha_pattern, values.merge_oid))) and is_map(values.authorization)

    if valid?, do: {:ok, values}, else: {:error, "invalid_evidence"}
  end

  defp candidate_oids(pr, input) do
    base = get_in(pr, ["base", "sha"])
    head = get_in(pr, ["head", "sha"])

    with true <- pr["number"] == input.pr,
         true <- is_binary(base) and Regex.match?(@sha_pattern, base),
         true <- is_binary(head) and Regex.match?(@sha_pattern, head),
         true <- pr["state"] == "open" or input.stage == "post_merge",
         true <- input.stage != "pre_merge" or (pr["draft"] == false and pr["mergeable"] == true),
         true <-
           input.stage != "pre_merge" or
             pr["mergeable_state"] not in ["behind", "dirty", "blocked", "unknown"],
         true <- is_nil(input[:expected_base_oid]) or input.expected_base_oid == base,
         true <- is_nil(input[:expected_head_oid]) or input.expected_head_oid == head do
      {:ok, base, head}
    else
      _ -> {:error, "candidate_changed"}
    end
  end

  defp candidate_tree(%{"sha" => sha, "commit" => %{"tree" => %{"sha" => tree}}}, input)
       when is_binary(sha) and is_binary(tree) do
    if Regex.match?(@sha_pattern, sha) and Regex.match?(@sha_pattern, tree) and
         sha == input.expected_head_oid and tree == input.expected_tree_oid,
       do: {:ok, tree},
       else: {:error, "candidate_changed"}
  end

  defp candidate_tree(_, _), do: {:error, "candidate_changed"}

  defp same_head_ci(run, input, head_oid) do
    if run["id"] == input.ci_run_id and run["head_sha"] == head_oid and
         run["conclusion"] == "success" and run["status"] == "completed" and
         String.contains?(to_string(run["name"] || run["path"] || ""), "Crosswake CI") do
      :ok
    else
      {:error, "candidate_ci_changed"}
    end
  end

  defp same_candidate_receipt_run(run, input, head_oid) do
    if run["id"] == input.receipt_run_id and run["head_sha"] == head_oid and
         run["conclusion"] == "success" and run["status"] == "completed" and
         run["event"] == "workflow_dispatch" and run["name"] == "iOS mirror authority" do
      :ok
    else
      {:error, "receipt_artifact_invalid"}
    end
  end

  defp read_policy(fetch, input, protection, rulesets, protection_raw, ruleset_pages_raw) do
    ruleset_ids =
      rulesets
      |> Enum.filter(&(&1["enforcement"] in ["active", "evaluate"]))
      |> Enum.map(& &1["id"])

    with true <- is_list(ruleset_ids) and length(ruleset_ids) == length(Enum.uniq(ruleset_ids)),
         {:ok, details, detail_raw} <- fetch_ruleset_details(fetch, input, ruleset_ids),
         required when is_list(required) <- required_contexts(protection, details),
         true <- required != [],
         true <- Enum.any?(required, &(&1["context"] == "Crosswake CI")),
         true <- get_in(protection, ["enforce_admins", "enabled"]) == true,
         true <- Enum.all?(details, &(get_in(&1, ["bypass_actors"]) in [nil, []])) do
      policy_facts = %{
        "required_checks" => Enum.sort_by(required, & &1["context"]),
        "ruleset_ids" => Enum.sort(ruleset_ids),
        "branch_protection_sha256" => digest(protection_raw),
        "rulesets" =>
          Enum.zip(ruleset_ids, detail_raw)
          |> Enum.map(fn {id, bytes} -> %{"id" => id, "sha256" => digest(bytes)} end)
          |> Enum.sort_by(& &1["id"]),
        "enforce_admins" => true,
        "bypass_actors" => []
      }

      policy_bytes = canonical_json(policy_facts)

      raw =
        Enum.join(
          [protection_raw, ruleset_pages_raw | detail_raw],
          "\n--REL17-SOURCE--\n"
        )

      {:ok,
       %{
         required_checks: policy_facts["required_checks"],
         ruleset_ids: policy_facts["ruleset_ids"],
         facts: policy_facts,
         sha256: digest(policy_bytes),
         raw: raw
       }, raw}
    else
      _ -> {:error, "required_check_policy_invalid"}
    end
  end

  defp fetch_ruleset_details(fetch, input, ids) do
    Enum.reduce_while(ids, {:ok, []}, fn id, {:ok, acc} ->
      case get_json(fetch, api(input, "/rulesets/#{id}")) do
        {:ok, detail, raw} -> {:cont, {:ok, acc ++ [{detail, raw}]}}
        {:error, _} -> {:halt, {:error, "required_check_policy_invalid"}}
      end
    end)
    |> case do
      {:ok, rows} ->
        {:ok, Enum.map(rows, &elem(&1, 0)), Enum.map(rows, &elem(&1, 1))}

      error ->
        error
    end
  end

  defp required_contexts(protection, details) do
    branch =
      protection
      |> get_in(["required_status_checks"])
      |> case do
        %{} = checks ->
          check_rows = List.wrap(checks["checks"])
          app_ids = Map.new(check_rows, &{&1["context"], &1["app_id"]})

          contexts =
            Enum.map(List.wrap(checks["contexts"]), fn context ->
              %{"context" => context, "app_id" => Map.get(app_ids, context)}
            end)

          contexts ++
            Enum.map(check_rows, &%{"context" => &1["context"], "app_id" => &1["app_id"]})

        _ ->
          []
      end

    from_rulesets =
      Enum.flat_map(details, fn detail ->
        detail
        |> Map.get("rules", [])
        |> Enum.flat_map(fn
          %{
            "type" => "required_status_checks",
            "parameters" => %{"required_status_checks" => checks}
          }
          when is_list(checks) ->
            Enum.map(checks, fn check ->
              Map.put_new(check, "app_id", check["integration_id"])
            end)

          %{"type" => "required_status_checks", "parameters" => %{"checks" => checks}}
          when is_list(checks) ->
            Enum.map(checks, fn check ->
              Map.put_new(check, "app_id", check["integration_id"])
            end)

          _ ->
            []
        end)
      end)

    Enum.uniq_by(branch ++ from_rulesets, & &1["context"])
  end

  defp expected_policy(current, expected) do
    if current == expected, do: :ok, else: {:error, "required_check_policy_changed"}
  end

  defp required_checks_pass(checks, required, head_oid) do
    passed =
      Enum.all?(required, fn required_check ->
        context = required_check["context"]

        Enum.any?(checks, fn check ->
          check["name"] == context and check["head_sha"] == head_oid and
            check["status"] == "completed" and check["conclusion"] == "success" and
            (is_nil(required_check["app_id"]) or
               get_in(check, ["app", "id"]) == required_check["app_id"])
        end)
      end)

    if passed, do: :ok, else: {:error, "required_checks_incomplete"}
  end

  defp matching_receipt_artifact(artifacts, input, head_oid) do
    expected_name = @candidate_artifact_prefix <> head_oid

    matches = Enum.filter(artifacts, &(&1["name"] == expected_name))

    case matches do
      [artifact] ->
        valid? =
          artifact["id"] == input.receipt_artifact_id and artifact["expired"] == false and
            artifact["workflow_run"]["id"] == input.receipt_run_id and
            is_binary(artifact["expires_at"]) and fresh_expiry?(artifact["expires_at"], input)

        if valid?, do: {:ok, artifact}, else: {:error, "receipt_artifact_invalid"}

      _ ->
        {:error, "receipt_artifact_invalid"}
    end
  end

  defp fresh_expiry?(expires_at, input) do
    now = Map.get(input, :now, DateTime.utc_now())

    case DateTime.from_iso8601(expires_at) do
      {:ok, expires, _offset} -> DateTime.compare(expires, now) == :gt
      _ -> false
    end
  end

  defp matching_leg_run(run, input, head_oid) do
    path = to_string(run["path"] || "")
    title = String.downcase(to_string(run["name"] || ""))

    if run["id"] == input.leg_run_id and run["head_sha"] == head_oid and
         run["conclusion"] == "success" and run["status"] == "completed" and
         String.contains?(path, "hex-publish.yml") and String.contains?(title, "hex") do
      :ok
    else
      {:error, "leg_run_mismatch"}
    end
  end

  defp fetch_registry(input, fetch) do
    fetch.("https://hex.pm/api/packages/#{input.package}")
    |> case do
      {:ok, %{status: status, body: body}}
      when status in 200..299 and is_binary(body) and
             byte_size(body) in 1..@max_bytes ->
        {:ok, %{body: body}}

      _ ->
        {:error, "registry_response_invalid"}
    end
  end

  defp parse_registry(body, input) do
    with {:ok, %{"releases" => releases} = parsed} when is_list(releases) and releases != [] <-
           Jason.decode(body),
         true <- is_binary(input.package) and is_binary(input.version) do
      facts = %{"package" => input.package, "version" => input.version, "parsed" => parsed}
      {:ok, %{facts: facts, bytes: body}}
    else
      _ -> {:error, "registry_response_invalid"}
    end
  end

  defp fetch_merge(_fetch, %{stage: "pre_merge"}, pr, _base, _head),
    do:
      (
        facts = %{"merge_ready" => pr["mergeable"] == true}
        {:ok, %{facts: facts, merge_oid: nil}, canonical_json(facts)}
      )

  defp fetch_merge(fetch, input, pr, base_oid, head_oid) do
    merge_oid = input.merge_oid

    with true <- pr["merged"] == true and pr["merge_commit_sha"] == merge_oid,
         {:ok, commit, raw} <- get_json(fetch, api(input, "/commits/#{merge_oid}")),
         parents when is_list(parents) <- commit["parents"],
         true <- Enum.map(parents, & &1["sha"]) == [base_oid, head_oid],
         true <- commit["sha"] == merge_oid do
      normal = get_in(pr, ["merged_by", "login"]) != nil

      facts = %{
        "merge_oid" => merge_oid,
        "parents" => [base_oid, head_oid],
        "normal_protected_path" => normal,
        "admin_bypass" => false
      }

      {:ok, %{facts: facts, merge_oid: merge_oid}, raw}
    else
      _ -> {:error, "protected_merge_invalid"}
    end
  end

  defp check_ancestry(git_ancestor, input, base_oid, head_oid, merge_oid) do
    targets = [base_oid, head_oid] ++ if(merge_oid, do: [merge_oid], else: [])

    results =
      Enum.map(targets, fn target ->
        case git_ancestor.(input.runbook_commit, target) do
          true -> {target, true}
          :ok -> {target, true}
          _ -> {target, false}
        end
      end)

    case Enum.all?(results, &elem(&1, 1)) do
      true ->
        facts = %{
          "runbook_commit" => input.runbook_commit,
          "base_is_ancestor" => true,
          "head_is_ancestor" => true,
          "merge_is_ancestor" => not is_nil(merge_oid)
        }

        {:ok, facts, canonical_json(Map.new(results))}

      false ->
        {:error, "runbook_ancestry_invalid"}
    end
  end

  defp validate_authorization(input, head_oid) do
    auth = input.authorization

    expected_state = if input.stage == "pre_merge", do: "PENDING", else: "CONSUMED"

    if auth["stage"] == "pre_merge" and auth["state"] == expected_state and
         auth["receipt_digest"] == input.receipt_digest and auth["operation"] == input.operation and
         auth["leg_run_id"] == input.leg_run_id and auth["candidate_package"] == input.package and
         auth["candidate_head"] == head_oid do
      :ok
    else
      {:error, "authorization_mismatch"}
    end
  end

  defp build_capture(
         input,
         candidate,
         candidate_raw,
         policy,
         artifact,
         leg,
         registry,
         merge_data,
         merge_raw,
         ancestry,
         ancestry_raw
       ) do
    stage = input.stage
    post? = stage == "post_merge"
    merge_facts = merge_data.facts
    ancestry = Map.put(ancestry, "merge_is_ancestor", post?)

    condition_facts = %{
      "leg_run" => %{
        "run_id" => input.leg_run_id,
        "head_oid" => candidate.head_oid,
        "conclusion" => "success"
      },
      "candidate_readiness" => %{
        "package" => input.package,
        "receipt_digest" => input.receipt_digest,
        "base_oid" => candidate.base_oid,
        "head_oid" => candidate.head_oid,
        "tree_oid" => candidate.tree_oid,
        "merge_state" => "MERGEABLE",
        "ci_run_id" => input.ci_run_id,
        "ci_conclusion" => "success",
        "required_check_ids" => Enum.map(policy.required_checks, & &1["context"]),
        "required_checks_complete" => true,
        "policy_sha256" => policy.sha256,
        "policy_current" => true,
        "pagination_complete" => true,
        "receipt_artifact_id" => artifact.facts["id"],
        "receipt_artifact_live" => true
      },
      "registry_response" => registry.registry_facts,
      "protected_merge" => merge_facts,
      "response_row" => %{
        "run_id" => input.leg_run_id,
        "package" => input.package,
        "version" => input.version,
        "candidate_ref" => candidate.head_oid
      },
      "runbook_ancestry" => ancestry
    }

    raw_by_condition = %{
      "leg_run" => leg.leg_run,
      "candidate_readiness" =>
        Enum.join(
          Map.values(candidate_raw) ++
            [policy.raw, artifact.artifacts, artifact.artifact],
          "\n--REL17-SOURCE--\n"
        ),
      "registry_response" => registry.registry,
      "protected_merge" => merge_raw,
      "response_row" => leg.leg_run,
      "runbook_ancestry" => ancestry_raw
    }

    with {:ok, source_paths, sources} <-
           write_sources(input.source_dir, condition_facts, raw_by_condition) do
      authorization = input.authorization

      candidate_map = %{
        "package" => input.package,
        "pr" => input.pr,
        "version" => input.version,
        "base_oid" => candidate.base_oid,
        "head_oid" => candidate.head_oid,
        "tree_oid" => candidate.tree_oid,
        "merge_oid" => if(post?, do: merge_data.merge_oid, else: nil)
      }

      envelope = %{
        "schema_version" => 1,
        "identity" => %{
          "receipt_digest" => input.receipt_digest,
          "operation" => input.operation,
          "leg_run_id" => input.leg_run_id
        },
        "stage" => stage,
        "candidate" => candidate_map,
        "authorization" => authorization,
        "conditions" =>
          Map.new(condition_facts, fn {condition, facts} ->
            facts_bytes = canonical_json(facts)
            {facts_path, raw_path} = source_paths[condition]

            {condition,
             %{
               "facts" => facts,
               "source_path" => facts_path,
               "source_sha256" => digest(facts_bytes),
               "raw_source_path" => raw_path,
               "raw_source_sha256" => digest(raw_by_condition[condition])
             }}
          end)
      }

      {:ok, %{envelope: envelope, sources: sources, source_dir: input.source_dir}}
    end
  end

  defp write_sources(source_dir, condition_facts, raw_by_condition) do
    with :ok <- File.mkdir_p(source_dir),
         :ok <- File.chmod(source_dir, 0o700) do
      Enum.reduce_while(condition_facts, {:ok, %{}, %{}}, fn {condition, facts},
                                                             {:ok, paths, sources} ->
        facts_path = "facts/#{condition}.json"
        raw_path = "raw/#{condition}.source"
        facts_bytes = canonical_json(facts)
        raw_bytes = raw_by_condition[condition]

        if is_binary(raw_bytes) and byte_size(raw_bytes) in 1..@max_bytes do
          with :ok <- private_write(source_dir, facts_path, facts_bytes),
               :ok <- private_write(source_dir, raw_path, raw_bytes) do
            condition_paths = {facts_path, raw_path}

            {:cont,
             {:ok, Map.put(paths, condition, condition_paths),
              sources |> Map.put(facts_path, facts_bytes) |> Map.put(raw_path, raw_bytes)}}
          else
            _ -> {:halt, {:error, "evidence_write_failed"}}
          end
        else
          {:halt, {:error, "source_too_large"}}
        end
      end)
    end
  end

  defp private_write(root, relative, bytes) do
    path = Path.join(root, relative)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.chmod(Path.dirname(path), 0o700),
         :ok <- File.write(path, bytes, [:binary, :sync]),
         :ok <- File.chmod(path, 0o600) do
      :ok
    end
  end

  defp initialize_source_dir(path) do
    case File.lstat(path) do
      {:error, :enoent} ->
        with :ok <- File.mkdir_p(path),
             :ok <- File.chmod(path, 0o700),
             do: :ok

      {:ok, %File.Stat{type: :directory}} ->
        case File.ls(path) do
          {:ok, []} -> File.chmod(path, 0o700)
          _ -> {:error, "source_dir_not_fresh"}
        end

      _ ->
        {:error, "source_dir_not_fresh"}
    end
  end

  defp recording_fetch(fetch, root) do
    counter = :atomics.new(2, [])

    fn url ->
      try do
        case fetch.(url) do
          {:ok, %{body: body} = response}
          when is_binary(body) and byte_size(body) in 1..@max_bytes ->
            total_bytes = :atomics.add_get(counter, 2, byte_size(body))

            if total_bytes <= @max_capture_bytes do
              request_id = :atomics.add_get(counter, 1, 1)
              path = "live/request-#{request_id}.source"

              case private_write(root, path, body) do
                :ok -> {:ok, response}
                _ -> {:error, "evidence_write_failed"}
              end
            else
              {:error, "source_too_large"}
            end

          other ->
            other
        end
      rescue
        _ -> {:error, "api_request_failed"}
      end
    end
  end

  defp get_json(fetch, url) do
    case fetch.(url) do
      {:ok, %{status: 200, body: body}}
      when is_binary(body) and byte_size(body) in 1..@max_bytes ->
        case Jason.decode(body) do
          {:ok, json} when is_map(json) -> {:ok, json, body}
          _ -> {:error, "api_response_invalid"}
        end

      _ ->
        {:error, "api_response_invalid"}
    end
  rescue
    _ -> {:error, "api_response_invalid"}
  end

  defp get_pages(fetch, first_url, opts) do
    collect_pages(
      fetch,
      first_url,
      Keyword.get(opts, :collection),
      Keyword.get(opts, :total, false),
      MapSet.new(),
      [],
      [],
      nil,
      0
    )
  end

  defp collect_pages(
         _fetch,
         _url,
         _collection,
         _require_total,
         _seen,
         _items,
         _raw,
         _declared_total,
         pages
       )
       when pages >= @max_pages,
       do: {:error, "pagination_incomplete"}

  defp collect_pages(
         fetch,
         url,
         collection,
         require_total,
         seen,
         items,
         raw,
         declared_total,
         pages
       ) do
    if MapSet.member?(seen, url) do
      {:error, "pagination_incomplete"}
    else
      case fetch.(url) do
        {:ok, %{status: 200, body: body, headers: headers}}
        when is_binary(body) and byte_size(body) in 1..@max_bytes ->
          with {:ok, json} <- Jason.decode(body),
               {:ok, page_items, total} <- page_items(json, collection),
               next when next != :malformed <- next_link(headers),
               true <- not require_total or page_items != [],
               true <- page_items != [] or is_nil(next),
               true <- not require_total or is_integer(total),
               true <- is_nil(declared_total) or is_nil(total) or declared_total == total do
            new_items = items ++ page_items
            new_raw = raw ++ [body]
            next_seen = MapSet.put(seen, url)
            next_total = declared_total || total
            unique_count = new_items |> Enum.map(&canonical_json/1) |> Enum.uniq() |> length()

            cond do
              unique_count != length(new_items) ->
                {:error, "pagination_incomplete"}

              is_binary(next) ->
                collect_pages(
                  fetch,
                  next,
                  collection,
                  require_total,
                  next_seen,
                  new_items,
                  new_raw,
                  next_total,
                  pages + 1
                )

              require_total and next_total != length(new_items) ->
                {:error, "pagination_incomplete"}

              is_integer(next_total) and next_total != length(new_items) ->
                {:error, "pagination_incomplete"}

              true ->
                {:ok, new_items, Enum.join(new_raw, "\n--REL17-PAGE--\n")}
            end
          else
            _ -> {:error, "pagination_incomplete"}
          end

        _ ->
          {:error, "pagination_incomplete"}
      end
    end
  rescue
    _ -> {:error, "pagination_incomplete"}
  end

  defp page_items(list, :list) when is_list(list), do: {:ok, list, nil}

  defp page_items(%{} = object, collection) when is_binary(collection) do
    items = object[collection]
    total = object["total_count"]
    if is_list(items), do: {:ok, items, total}, else: {:error, "pagination_incomplete"}
  end

  defp page_items(_, _), do: {:error, "pagination_incomplete"}

  defp next_link(headers) when is_list(headers) do
    headers
    |> Enum.find_value(fn
      {key, value} when is_binary(key) and is_binary(value) ->
        if String.downcase(key) == "link", do: value

      _ ->
        nil
    end)
    |> case do
      nil ->
        nil

      link ->
        case Regex.run(~r/<([^>]+)>\s*;\s*rel="next"/i, link) do
          [_, url] -> url
          _ -> if Regex.match?(~r/rel="next"/i, link), do: :malformed, else: nil
        end
    end
  end

  defp api(input, path), do: "https://api.github.com/repos/#{input.repository}" <> path
  defp encode_ref(ref) when is_binary(ref), do: URI.encode(ref, &URI.char_unreserved?/1)
  defp encode_ref(_), do: ""

  defp valid_repo?(repo) when is_binary(repo),
    do: Regex.match?(~r/\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/, repo)

  defp valid_repo?(_), do: false

  defp valid_operation_package?("linked_release", "crosswake"), do: true
  defp valid_operation_package?("recovery", "crosswake"), do: true

  defp valid_operation_package?("companion_publish", package) do
    package in Enum.drop(Crosswake.ReleaseCandidate.Artifact.packages(), 1)
  end

  defp valid_operation_package?(_, _), do: false

  defp http_get(url) when is_binary(url) do
    if String.starts_with?(url, "https://hex.pm/") do
      curl_get(url)
    else
      gh_get(url)
    end
  end

  defp gh_get(url) do
    case bounded_cmd("gh", ["api", "--include", url], [stderr_to_stdout: true, env: []], 20_000) do
      {output, 0} -> parse_included_response(output)
      _ -> {:error, "api_request_failed"}
    end
  rescue
    _ -> {:error, "api_request_failed"}
  end

  defp parse_included_response(output) do
    case Regex.run(~r/\AHTTP\/[^\s]+\s+(\d{3})[^\r\n]*\r?\n(.*?)(?:\r?\n\r?\n)(.*)\z/s, output) do
      [_, status, header_text, body] ->
        headers =
          header_text
          |> String.split(~r/\r?\n/)
          |> Enum.flat_map(fn line ->
            case String.split(line, ":", parts: 2) do
              [key, value] -> [{String.trim(key), String.trim(value)}]
              _ -> []
            end
          end)

        {:ok, %{status: String.to_integer(status), headers: headers, body: body}}

      _ ->
        {:error, "api_response_invalid"}
    end
  end

  defp curl_get(url) do
    delimiter = "\n__REL17_HTTP_STATUS__"

    case bounded_cmd(
           "curl",
           [
             "--silent",
             "--show-error",
             "--location",
             "--max-time",
             "20",
             "--max-filesize",
             Integer.to_string(@max_bytes),
             "--write-out",
             delimiter <> "%{http_code}",
             url
           ],
           [stderr_to_stdout: true, env: []],
           25_000
         ) do
      {output, 0} ->
        case String.split(output, delimiter, parts: 2) do
          [body, status] ->
            code = String.to_integer(String.trim(status))

            if code in 200..299 and byte_size(body) in 1..@max_bytes,
              do: {:ok, %{status: code, headers: [], body: body}},
              else: {:error, "registry_response_invalid"}

          _ ->
            {:error, "registry_response_invalid"}
        end

      _ ->
        {:error, "registry_response_invalid"}
    end
  rescue
    _ -> {:error, "registry_response_invalid"}
  end

  defp git_ancestor?(runbook, target) do
    case bounded_cmd(
           "bash",
           ["script/check_release_runbook_ancestry.sh", runbook, target, @runbook_path],
           [stderr_to_stdout: true],
           10_000
         ) do
      {_output, 0} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp bounded_cmd(program, args, options, timeout_ms) do
    task = Task.async(fn -> System.cmd(program, args, options) end)

    case Task.yield(task, timeout_ms) do
      {:ok, result} ->
        result

      nil ->
        Task.shutdown(task, :brutal_kill)
        {"", 124}
    end
  end

  defp canonical_json(value), do: Jason.encode!(value, maps: :strict)
  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp safe_code(code)
       when code in ~w(invalid_evidence candidate_changed candidate_ci_changed required_check_policy_invalid required_check_policy_changed required_checks_incomplete receipt_artifact_invalid leg_run_mismatch registry_response_invalid protected_merge_invalid runbook_ancestry_invalid authorization_mismatch evidence_write_failed source_too_large api_response_invalid api_request_failed pagination_incomplete),
       do: code

  defp safe_code(_), do: "invalid_evidence"
end
