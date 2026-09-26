defmodule Crosswake.ReleaseCandidate.EvidenceLiveTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.{EvidenceGate, EvidenceLive}

  @base String.duplicate("a", 40)
  @head String.duplicate("b", 40)
  @tree String.duplicate("c", 40)
  @merge String.duplicate("d", 40)
  @receipt String.duplicate("e", 64)
  @runbook String.duplicate("f", 40)
  @now ~U[2027-01-01 00:00:00Z]

  test "each invocation fetches a complete candidate and retains the exact registry response" do
    {responses, registry_bytes, expected_policy} = fixture()
    {:ok, requests} = Agent.start_link(fn -> [] end)

    fetch = fn url ->
      Agent.update(requests, &[url | &1])
      Map.fetch!(responses, url)
    end

    {:ok, first} = EvidenceLive.capture(options(fetch, expected_policy))
    {:ok, second} = EvidenceLive.capture(options(fetch, expected_policy))

    on_exit(fn ->
      File.rm_rf!(first.source_dir)
      File.rm_rf!(second.source_dir)
    end)

    seen = Agent.get(requests, & &1)
    assert length(seen) == length(Enum.uniq(seen)) * 2

    assert length(Path.wildcard(Path.join(first.source_dir, "live/*.source"))) ==
             length(Enum.uniq(seen))

    assert File.read!(
             Path.join(
               first.source_dir,
               first.envelope["conditions"]["registry_response"]["raw_source_path"]
             )
           ) == registry_bytes

    assert {:ok, %{stage: "pre_merge", next_step: "request_exact_gate"}} =
             EvidenceGate.validate(first.envelope, first.sources)

    assert first.envelope["candidate"]["merge_oid"] == nil
    assert second.envelope["identity"] == first.envelope["identity"]
  end

  test "policy changes, expired or duplicate receipt artifacts, and leg mismatches block" do
    {responses, _registry, expected_policy} = fixture()
    fetch = fn url -> Map.fetch!(responses, url) end

    assert {:error, "required_check_policy_changed"} =
             EvidenceLive.capture(options(fetch, String.duplicate("0", 64)))

    protection_url = github("/branches/main/protection")
    {:ok, protection_response} = responses[protection_url]
    protection = Jason.decode!(protection_response.body) |> Map.put("policy_revision", "changed")
    changed_policy = Map.put(responses, protection_url, response_json(protection))

    assert {:error, "required_check_policy_changed"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(changed_policy, url) end, expected_policy)
             )

    artifact_url = github("/actions/runs/700/artifacts?per_page=100")

    expired =
      update_artifact(responses, artifact_url, &Map.put(&1, "expires_at", "2020-01-01T00:00:00Z"))

    assert {:error, "receipt_artifact_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(expired, url) end, expected_policy)
             )

    duplicate =
      update_artifact(responses, artifact_url, fn artifact -> artifact end, duplicate: true)

    assert {:error, "receipt_artifact_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(duplicate, url) end, expected_policy)
             )

    wrong_leg =
      Map.put(
        responses,
        github("/actions/runs/900"),
        response_json(%{
          "id" => 900,
          "head_sha" => @head,
          "status" => "completed",
          "conclusion" => "failure",
          "path" => ".github/workflows/hex-publish.yml",
          "name" => "Hex candidate rehearsal"
        })
      )

    assert {:error, "leg_run_mismatch"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(wrong_leg, url) end, expected_policy)
             )
  end

  test "API failure, missing candidate keys, changed OIDs and invalid Hex bodies block" do
    {responses, _registry, expected_policy} = fixture()

    pr_url = github("/pulls/147")
    {:ok, pr_response} = responses[pr_url]
    pr = Jason.decode!(pr_response.body)

    changed =
      Map.put(
        responses,
        pr_url,
        response_json(put_in(pr, ["head", "sha"], String.duplicate("9", 40)))
      )

    assert {:error, "candidate_changed"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(changed, url) end, expected_policy)
             )

    missing_key =
      Map.put(responses, pr_url, response_json(update_in(pr, ["head"], &Map.delete(&1, "sha"))))

    assert {:error, "candidate_changed"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(missing_key, url) end, expected_policy)
             )

    api_error =
      Map.put(responses, pr_url, {:ok, %{status: 503, headers: [], body: "unavailable"}})

    assert {:error, "api_response_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(api_error, url) end, expected_policy)
             )

    registry_error =
      Map.put(
        responses,
        "https://hex.pm/api/packages/crosswake",
        {:ok, %{status: 404, headers: [], body: ""}}
      )

    assert {:error, "registry_response_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(registry_error, url) end, expected_policy)
             )

    invalid_registry_bytes = "{invalid-json-sentinel"

    invalid_registry =
      Map.put(
        responses,
        "https://hex.pm/api/packages/crosswake",
        {:ok, %{status: 200, headers: [], body: invalid_registry_bytes}}
      )

    invalid_opts = options(fn url -> Map.fetch!(invalid_registry, url) end, expected_policy)
    source_dir = Keyword.fetch!(invalid_opts, :source_dir)

    assert {:error, "registry_response_invalid"} =
             EvidenceLive.capture(invalid_opts)

    assert File.read!(Path.join(source_dir, "live/request-10.source")) == invalid_registry_bytes

    empty_registry =
      Map.put(
        responses,
        "https://hex.pm/api/packages/crosswake",
        response_body(%{"releases" => []})
      )

    assert {:error, "registry_response_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(empty_registry, url) end, expected_policy)
             )
  end

  test "all REST next links are followed and reported cardinality must reconcile" do
    page_one = %{
      status: 200,
      headers: [{"Link", "<https://api.github.com/page/2>; rel=\"next\""}],
      body: Jason.encode!(%{"total_count" => 2, "check_runs" => [%{"id" => 1}]})
    }

    page_two = %{
      status: 200,
      headers: [],
      body: Jason.encode!(%{"total_count" => 2, "check_runs" => [%{"id" => 2}]})
    }

    assert {:ok, [%{"id" => 1}, %{"id" => 2}], raw} =
             EvidenceLive.fetch_pages(
               fn
                 "https://api.github.com/page/1" -> {:ok, page_one}
                 "https://api.github.com/page/2" -> {:ok, page_two}
               end,
               "https://api.github.com/page/1",
               collection: "check_runs",
               total: true
             )

    assert raw =~ "\"id\":1"
    assert raw =~ "\"id\":2"

    assert {:error, "pagination_incomplete"} =
             EvidenceLive.fetch_pages(
               fn _url ->
                 {:ok,
                  %{
                    status: 200,
                    headers: [],
                    body: Jason.encode!(%{"total_count" => 2, "check_runs" => [%{"id" => 1}]})
                  }}
               end,
               "https://api.github.com/page/1",
               collection: "check_runs",
               total: true
             )

    assert {:error, "pagination_incomplete"} =
             EvidenceLive.fetch_pages(
               fn _url -> {:ok, %{status: 200, headers: [], body: "{}"}} end,
               "https://api.github.com/page/1",
               collection: "check_runs",
               total: true
             )
  end

  test "an active ruleset with a bypass actor fails the protected policy check" do
    {responses, _registry, expected_policy} = fixture()

    responses =
      responses
      |> Map.put(
        github("/rulesets?per_page=100"),
        response_json([%{"id" => 31, "enforcement" => "active"}])
      )
      |> Map.put(
        github("/rulesets/31"),
        response_json(%{
          "id" => 31,
          "enforcement" => "active",
          "bypass_actors" => [%{"actor_id" => 1, "bypass_mode" => "always"}],
          "rules" => []
        })
      )

    assert {:error, "required_check_policy_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(responses, url) end, expected_policy)
             )
  end

  test "post-merge capture binds the actual merge parents and no-bypass policy" do
    {responses, _registry, expected_policy} = fixture(post_merge: true)
    fetch = fn url -> Map.fetch!(responses, url) end

    result =
      EvidenceLive.capture(
        options(fetch, expected_policy,
          stage: "post_merge",
          merge_oid: @merge,
          authorization: authorization("CONSUMED")
        )
      )

    assert {:ok, capture} = result
    on_exit(fn -> File.rm_rf!(capture.source_dir) end)
    assert capture.envelope["candidate"]["merge_oid"] == @merge
    assert capture.envelope["conditions"]["protected_merge"]["facts"]["parents"] == [@base, @head]

    assert {:ok, %{stage: "post_merge"}} =
             EvidenceGate.validate(capture.envelope, capture.sources)

    wrong_parent =
      Map.put(
        responses,
        github("/commits/#{@merge}"),
        response_json(%{
          "sha" => @merge,
          "parents" => [%{"sha" => @base}, %{"sha" => String.duplicate("9", 40)}]
        })
      )

    assert {:error, "protected_merge_invalid"} =
             EvidenceLive.capture(
               options(fn url -> Map.fetch!(wrong_parent, url) end, expected_policy,
                 stage: "post_merge",
                 merge_oid: @merge,
                 authorization: authorization("CONSUMED")
               )
             )

    assert {:error, "runbook_ancestry_invalid"} =
             EvidenceLive.capture(
               options(fetch, expected_policy,
                 stage: "post_merge",
                 merge_oid: @merge,
                 authorization: authorization("CONSUMED"),
                 git_ancestor: fn _runbook, target -> target == @base end
               )
             )
  end

  defp options(fetch, expected_policy, overrides \\ []) do
    source_dir =
      Path.join(System.tmp_dir!(), "crosswake-rel17-live-#{System.unique_integer([:positive])}")

    File.rm_rf(source_dir)
    on_exit(fn -> File.rm_rf(source_dir) end)

    base = [
      operation: "linked_release",
      stage: "pre_merge",
      package: "crosswake",
      version: "0.2.6",
      pr: 147,
      receipt_digest: @receipt,
      leg_run_id: 900,
      ci_run_id: 800,
      receipt_run_id: 700,
      receipt_artifact_id: 710,
      repository: "szTheory/crosswake",
      runbook_commit: @runbook,
      expected_policy_sha256: expected_policy,
      source_dir: source_dir,
      authorization: authorization("PENDING"),
      expected_base_oid: @base,
      expected_head_oid: @head,
      expected_tree_oid: @tree,
      now: @now,
      http: fetch,
      git_ancestor: fn _runbook, _target -> true end
    ]

    Keyword.merge(base, overrides)
  end

  defp authorization(state) do
    %{
      "stage" => "pre_merge",
      "state" => state,
      "receipt_digest" => @receipt,
      "operation" => "linked_release",
      "leg_run_id" => 900,
      "candidate_package" => "crosswake",
      "candidate_head" => @head
    }
  end

  defp fixture(opts \\ []) do
    post? = Keyword.get(opts, :post_merge, false)
    required = [%{"context" => "Crosswake CI", "app_id" => nil}]

    policy_facts = %{
      "required_checks" => required,
      "ruleset_ids" => [],
      "branch_protection_sha256" =>
        digest(
          Jason.encode!(%{
            "required_status_checks" => %{"contexts" => ["Crosswake CI"], "checks" => []},
            "enforce_admins" => %{"enabled" => true}
          })
        ),
      "rulesets" => [],
      "enforce_admins" => true,
      "bypass_actors" => []
    }

    expected_policy =
      :crypto.hash(:sha256, Jason.encode!(policy_facts)) |> Base.encode16(case: :lower)

    expires = DateTime.add(@now, 86_400, :second) |> DateTime.to_iso8601()

    artifact = %{
      "id" => 710,
      "name" => "phase168-candidate-receipt-#{@head}",
      "expired" => false,
      "expires_at" => expires,
      "workflow_run" => %{"id" => 700}
    }

    pr = %{
      "number" => 147,
      "state" => if(post?, do: "closed", else: "open"),
      "draft" => false,
      "mergeable" => true,
      "mergeable_state" => "clean",
      "base" => %{"sha" => @base, "ref" => "main"},
      "head" => %{"sha" => @head},
      "merged" => post?,
      "merge_commit_sha" => if(post?, do: @merge, else: nil),
      "merged_by" => if(post?, do: %{"login" => "maintainer"}, else: nil)
    }

    check_run = %{
      "name" => "Crosswake CI",
      "head_sha" => @head,
      "status" => "completed",
      "conclusion" => "success"
    }

    ci_run = %{
      "id" => 800,
      "head_sha" => @head,
      "status" => "completed",
      "conclusion" => "success",
      "name" => "Crosswake CI"
    }

    receipt_run = %{
      "id" => 700,
      "head_sha" => @head,
      "status" => "completed",
      "conclusion" => "success",
      "event" => "workflow_dispatch",
      "name" => "iOS mirror authority"
    }

    leg_run = %{
      "id" => 900,
      "head_sha" => @head,
      "status" => "completed",
      "conclusion" => "success",
      "path" => ".github/workflows/hex-publish.yml",
      "name" => "Hex candidate rehearsal"
    }

    protection = %{
      "required_status_checks" => %{"contexts" => ["Crosswake CI"], "checks" => []},
      "enforce_admins" => %{"enabled" => true}
    }

    registry = Jason.encode!(%{"releases" => [%{"version" => "0.2.1"}]})

    responses = %{
      github("/pulls/147") => response_json(pr),
      github("/commits/#{@head}") =>
        response_json(%{"sha" => @head, "commit" => %{"tree" => %{"sha" => @tree}}}),
      github("/commits/#{@head}/check-runs?per_page=100") =>
        response_json(%{"total_count" => 1, "check_runs" => [check_run]}),
      github("/actions/runs/800") => response_json(ci_run),
      github("/actions/runs/700") => response_json(receipt_run),
      github("/branches/main/protection") => response_json(protection),
      github("/rulesets?per_page=100") => response_json([]),
      github("/actions/runs/700/artifacts?per_page=100") =>
        response_json(%{"total_count" => 1, "artifacts" => [artifact]}),
      github("/actions/runs/900") => response_json(leg_run)
    }

    responses =
      Map.put(
        responses,
        "https://hex.pm/api/packages/crosswake",
        {:ok, %{status: 200, headers: [], body: registry}}
      )

    responses =
      if post? do
        Map.put(
          responses,
          github("/commits/#{@merge}"),
          response_json(%{"sha" => @merge, "parents" => [%{"sha" => @base}, %{"sha" => @head}]})
        )
      else
        responses
      end

    {responses, registry, expected_policy}
  end

  defp update_artifact(responses, url, update, opts \\ []) do
    {:ok, current_response} = responses[url]
    current = current_response.body |> Jason.decode!()
    [artifact] = current["artifacts"]

    artifacts =
      if Keyword.get(opts, :duplicate, false),
        do: [update.(artifact), update.(artifact) |> Map.put("id", 711)],
        else: [update.(artifact)]

    Map.put(
      responses,
      url,
      response_json(
        Map.put(current, "artifacts", artifacts)
        |> Map.put("total_count", length(artifacts))
      )
    )
  end

  defp response_json(value), do: {:ok, %{status: 200, headers: [], body: Jason.encode!(value)}}

  defp response_body(body), do: {:ok, %{status: 200, headers: [], body: Jason.encode!(body)}}

  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp github(path), do: "https://api.github.com/repos/szTheory/crosswake" <> path
end
