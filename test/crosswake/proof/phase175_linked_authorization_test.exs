defmodule Crosswake.Proof.Phase175LinkedAuthorizationTest do
  use ExUnit.Case, async: false

  alias Crosswake.Phase175Rel17Fixtures, as: Rel17
  alias Crosswake.ReleaseCandidate.EvidenceLive
  alias Crosswake.ReleaseCandidate.EvidenceLiveTest, as: LiveFixture
  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @authorization_script "script/release_candidate/linked_release_authorization.sh"
  @release_workflow ".github/workflows/release-please.yml"
  @live_merge String.duplicate("d", 40)

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-linked-authorization-#{System.unique_integer([:positive])}"
      )

    evidence_dir = Path.join(root, "evidence")
    source_dir = Path.join(evidence_dir, "premerge-sources")
    File.mkdir_p!(source_dir)

    identity = %{
      "receipt_digest" => String.duplicate("a", 64),
      "operation" => "linked_release",
      "leg_run_id" => 202
    }

    candidate = %{
      "package" => "crosswake",
      "pr" => 216,
      "version" => "0.2.6",
      "base_oid" => String.duplicate("b", 40),
      "head_oid" => String.duplicate("c", 40),
      "tree_oid" => String.duplicate("d", 40),
      "merge_oid" => nil
    }

    source_authorization = %{
      "stage" => "pre_merge",
      "state" => "PENDING",
      "receipt_digest" => identity["receipt_digest"],
      "operation" => identity["operation"],
      "leg_run_id" => identity["leg_run_id"],
      "candidate_package" => candidate["package"],
      "candidate_head" => candidate["head_oid"]
    }

    source = %{
      "schema_version" => 1,
      "stage" => "pre_merge",
      "identity" => identity,
      "candidate" => candidate,
      "authorization" => source_authorization
    }

    source_bytes = Jason.encode!(source)
    source_path = Path.join(source_dir, "envelope.json")
    File.write!(source_path, source_bytes)

    result = %{
      "stage" => "pre_merge",
      "verdict" => "PASS",
      "identity" => identity,
      "candidate" => candidate,
      "authorization" => Map.put(source_authorization, "authorized", false),
      "envelope_path" => "premerge-sources/envelope.json",
      "envelope_sha256" => sha256(source_bytes),
      "ios_rehearsal_run_id" => 101
    }

    result_path = Path.join(evidence_dir, "premerge.json")
    write_json!(result_path, result)

    gate = gate_record(result, result_path, "PENDING", false)
    gate_path = Path.join(root, "gate-2.json")
    write_json!(gate_path, gate)

    trailer = trailer_record(result, "publish successor core 202")
    trailer_path = Path.join(root, "trailer.json")
    write_json!(trailer_path, trailer)

    on_exit(fn -> File.rm_rf!(root) end)

    {:ok,
     %{
       root: root,
       result: result,
       result_path: result_path,
       source: source,
       source_path: source_path,
       gate: gate,
       gate_path: gate_path,
       trailer: trailer,
       trailer_path: trailer_path
     }}
  end

  test "render derives the Gate 2 phrase from the retained Hex leg identity", context do
    result = run_helper("render", context)

    assert result.status == 0, result.output
    assert result.output == "publish successor core 202\n"
  end

  test "check accepts an authorized Gate 2 record and its matching immutable trailer", context do
    authorized_gate = gate_record(context.result, context.result_path, "AUTHORIZED", true)
    write_json!(context.gate_path, authorized_gate)

    result = run_helper("check", context)

    assert result.status == 0, result.output
    assert result.output =~ "PASS"
    refute result.output =~ "REL17-AUTHORIZATION:"
  end

  test "both operations reject a result projection that changes the source-bound leg id",
       context do
    forged_result = put_in(context.result, ["identity", "leg_run_id"], 101)
    write_json!(context.result_path, forged_result)

    for operation <- ["render", "check"] do
      result = run_helper(operation, context)

      assert result.status != 0
      refute result.output =~ "publish successor core"
    end
  end

  test "the canonical Hex phrase passes the actual workflow predicate and context loader",
       context do
    {responses, _registry, expected_policy} = LiveFixture.fixture(post_merge: true)
    trailer = live_trailer(responses)
    {output, status} = run_workflow_predicate(context, trailer)
    assert status == 0, output

    assert {:ok, capture} = live_capture(responses, expected_policy, trailer)
    File.rm_rf!(capture.source_dir)

    loader = Rel17.run_loader(Rel17.context(leg_run_id: 202))
    on_exit(fn -> Rel17.clean_loader_result(loader) end)
    assert loader.status == 0, loader.output
    assert loader.env =~ "REL17_LEG_RUN_ID=202\n"
  end

  test "the iOS rehearsal id is rejected by both real authorization consumers", context do
    {responses, _registry, expected_policy} = LiveFixture.fixture(post_merge: true)
    trailer = live_trailer(responses)
    wrong_trailer = Map.put(trailer, "authorization", "publish successor core 101")
    {output, status} = run_workflow_predicate(context, wrong_trailer)
    assert status != 0, output

    assert {:error, "authorization_mismatch"} =
             live_capture(responses, expected_policy, wrong_trailer)

    loader =
      Rel17.run_loader(
        Rel17.context(leg_run_id: 202, authorization: "publish successor core 101")
      )

    on_exit(fn -> Rel17.clean_loader_result(loader) end)
    assert loader.status != 0
    assert loader.env == ""
    refute loader.output =~ "REL17_OPERATION="
  end

  test "the integrity scanner requires the exact same-leg workflow predicate", _context do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "approved-release-guard",
        ~s<.authorization == ("publish successor core " + (.leg_run_id|tostring))>,
        ~s<.authorization == ("publish successor core " + (.authorization_run_id|tostring))>
      )

    assert_scanner_failure(mutated)
  end

  test "the integrity scanner rejects moving the same-leg predicate after REL-17 handoff",
       _context do
    workflow = File.read!(@release_workflow)
    selector = ~s<.authorization == ("publish successor core " + (.leg_run_id|tostring))>

    mutated =
      Scanner.replace_in_job(workflow, "approved-release-guard", selector, "true")

    mutated =
      Scanner.replace_in_job(
        mutated,
        "approved-release-guard",
        ~s|emit_output "rel17_context=$rel17_context"|,
        "emit_output \"rel17_context=$rel17_context\"\n          # moved guard: " <> selector
      )

    assert_scanner_failure(mutated)
  end

  test "both helper operations reject missing and blocked Gate 2 evidence verdicts", context do
    missing = update_in(context.gate, ["evidence"], &Map.delete(&1, "verdict"))
    blocked = put_in(context.gate, ["evidence", "verdict"], "BLOCKED")

    for gate <- [missing, blocked] do
      assert_both_operations_blocked(%{context | gate: gate})
    end
  end

  test "both helper operations reject a Gate 2 record naming a different result", context do
    wrong_path = Path.join(context.root, "other-result.json")
    File.write!(wrong_path, "{}")
    gate = put_in(context.gate, ["evidence", "path"], wrong_path)

    assert_both_operations_blocked(%{context | gate: gate})
  end

  test "both helper operations reject a Gate 2 record with a changed pending authorization",
       context do
    pending_authorization = put_in(context.gate, ["pending_authorization", "leg_run_id"], 101)
    assert_both_operations_blocked(%{context | gate: pending_authorization})
  end

  test "both helper operations reject envelope path escape and symlink substitution", context do
    escaped = put_in(context.result, ["envelope_path"], "../outside/envelope.json")
    write_json!(context.result_path, escaped)
    assert_both_operations_blocked(%{context | result: escaped})

    linked_path = Path.join(Path.dirname(context.source_path), "substituted-envelope.json")
    File.ln_s!(context.source_path, linked_path)
    write_json!(context.result_path, context.result)
    assert_both_operations_blocked(%{context | source_path: linked_path})
  end

  test "both helper operations reject a different supplied source file", context do
    other_source = Path.join(Path.dirname(context.source_path), "other-envelope.json")
    File.cp!(context.source_path, other_source)

    assert_both_operations_blocked(%{context | source_path: other_source})
  end

  test "both helper operations reject each broken source/result/Gate 2 digest link", context do
    changed_source = Jason.encode!(context.source) <> " "
    File.write!(context.source_path, changed_source)
    assert_both_operations_blocked(context)

    File.write!(context.source_path, Jason.encode!(context.source))
    wrong_digest = String.duplicate("9", 64)
    result = Map.put(context.result, "envelope_sha256", wrong_digest)
    gate = put_in(context.gate, ["evidence", "envelope_sha256"], wrong_digest)
    write_json!(context.result_path, result)
    assert_both_operations_blocked(%{context | result: result, gate: gate})

    write_json!(context.result_path, context.result)
    gate = put_in(context.gate, ["evidence", "envelope_sha256"], wrong_digest)
    assert_both_operations_blocked(%{context | gate: gate})
  end

  test "source bytes defeat forged result identity, candidate, and pending authorization projections",
       context do
    forged_identity = Map.put(context.result["identity"], "leg_run_id", 101)
    result = Map.put(context.result, "identity", forged_identity)

    gate =
      context.gate
      |> Map.put("identity", forged_identity)
      |> Map.put("hex_rehearsal_run_id", 101)

    trailer =
      context.trailer
      |> Map.put("leg_run_id", 101)
      |> Map.put("authorization", "publish successor core 101")

    write_json!(context.result_path, result)
    write_json!(context.trailer_path, trailer)
    assert_both_operations_blocked(%{context | result: result, gate: gate, trailer: trailer})

    forged_candidate = Map.put(context.result["candidate"], "pr", 217)
    result = Map.put(context.result, "candidate", forged_candidate)
    gate = Map.put(context.gate, "candidate", forged_candidate)
    trailer = Map.put(context.trailer, "pr", 217)
    write_json!(context.result_path, result)
    write_json!(context.trailer_path, trailer)
    assert_both_operations_blocked(%{context | result: result, gate: gate, trailer: trailer})

    forged_authorization = Map.put(context.result["authorization"], "state", "BLOCKED")
    result = Map.put(context.result, "authorization", forged_authorization)
    gate = Map.put(context.gate, "pending_authorization", forged_authorization)
    write_json!(context.result_path, result)
    assert_both_operations_blocked(%{context | result: result, gate: gate})
  end

  test "check rejects an authorization phrase taken from the iOS run", context do
    authorized_gate = gate_record(context.result, context.result_path, "AUTHORIZED", true)
    write_json!(context.gate_path, authorized_gate)
    wrong_trailer = Map.put(context.trailer, "authorization", "publish successor core 101")
    write_json!(context.trailer_path, wrong_trailer)

    result = run_helper("check", context)

    assert result.status != 0
    refute result.output =~ "publish successor core"
  end

  test "check rejects a consumed Gate 2 authorization", context do
    consumed_gate =
      context.result
      |> gate_record(context.result_path, "CONSUMED", true)
      |> Map.put("consumed", true)

    write_json!(context.gate_path, consumed_gate)
    result = run_helper("check", context)

    assert result.status != 0
    refute result.output =~ "publish successor core"
  end

  test "check rejects trailer fields that diverge from the source-bound candidate", context do
    authorized_gate = gate_record(context.result, context.result_path, "AUTHORIZED", true)
    write_json!(context.gate_path, authorized_gate)

    mutations = [
      {"leg_run_id", 101},
      {"receipt_digest", String.duplicate("9", 64)},
      {"operation", "companion_release"},
      {"package", "crosswake_other"},
      {"version", "0.2.7"},
      {"pr", 217},
      {"base_oid", String.duplicate("9", 40)},
      {"head_oid", String.duplicate("9", 40)},
      {"tree_oid", String.duplicate("9", 40)}
    ]

    for {key, value} <- mutations do
      write_json!(context.trailer_path, Map.put(context.trailer, key, value))
      result = run_helper("check", context)

      assert result.status != 0, "check accepted trailer mutation #{key}"
      refute result.output =~ "publish successor core"
    end
  end

  test "render and check leave every supplied evidence file unchanged", context do
    paths = [context.result_path, context.source_path, context.gate_path, context.trailer_path]

    for operation <- ["render", "check"] do
      gate = gate_for_mode(context.gate, operation)
      write_json!(context.gate_path, gate)
      before = Enum.map(paths, &File.read!/1)

      result = run_helper(operation, context)

      assert result.status == 0, result.output
      assert Enum.map(paths, &File.read!/1) == before
    end
  end

  defp run_helper(operation, context) do
    args = [
      @authorization_script,
      operation,
      context.result_path,
      context.source_path,
      context.gate_path
    ]

    args = if operation == "check", do: args ++ [context.trailer_path], else: args

    {output, status} = System.cmd("bash", args, stderr_to_stdout: true)
    %{output: output, status: status}
  end

  defp run_workflow_predicate(context, trailer) do
    block = Scanner.job_block!(File.read!(@release_workflow), "approved-release-guard")
    anchor = ~s(printf '%s' "$authorization_trailer" | jq -e)

    start =
      case :binary.match(block, anchor) do
        {offset, _length} -> offset
        :nomatch -> flunk("linked-release jq predicate disappeared")
      end

    rest = String.slice(block, start + byte_size(anchor), byte_size(block))

    [_, predicate] =
      Regex.run(
        ~r/--arg runbook "\$RUNBOOK_SHA" \\\n\s*'([\s\S]*?)' >\/dev\/null/,
        rest
      ) || flunk("linked-release jq predicate or runbook selector changed")

    write_json!(context.trailer_path, trailer)

    args = [
      "-e",
      "--arg",
      "operation",
      "linked_release",
      "--arg",
      "package",
      trailer["package"],
      "--arg",
      "version",
      trailer["version"],
      "--arg",
      "digest",
      trailer["receipt_digest"],
      "--argjson",
      "ci_run",
      Integer.to_string(trailer["ci_run_id"]),
      "--argjson",
      "receipt_run",
      Integer.to_string(trailer["receipt_run_id"]),
      "--argjson",
      "artifact_id",
      Integer.to_string(trailer["receipt_artifact_id"]),
      "--arg",
      "base",
      trailer["base_oid"],
      "--arg",
      "head",
      trailer["head_oid"],
      "--arg",
      "tree",
      trailer["tree_oid"],
      "--arg",
      "repository",
      trailer["repository"],
      "--arg",
      "runbook",
      trailer["runbook_commit"],
      predicate,
      context.trailer_path
    ]

    System.cmd("jq", args, stderr_to_stdout: true)
  end

  defp live_trailer(responses) do
    merge_url = github("/commits/#{@live_merge}")
    {:ok, response} = Map.fetch!(responses, merge_url)

    response.body
    |> Jason.decode!()
    |> get_in(["commit", "message"])
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, "REL17-AUTHORIZATION: "))
    |> String.replace_prefix("REL17-AUTHORIZATION: ", "")
    |> Jason.decode!()
  end

  defp live_capture(responses, expected_policy, trailer) do
    source_dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-live-trailer-parity-#{System.unique_integer([:positive])}"
      )

    File.rm_rf!(source_dir)
    on_exit(fn -> File.rm_rf!(source_dir) end)

    merge_url = github("/commits/#{@live_merge}")
    {:ok, response} = Map.fetch!(responses, merge_url)

    merge_commit =
      response.body
      |> Jason.decode!()
      |> put_in(
        ["commit", "message"],
        "Merge candidate\n\nREL17-AUTHORIZATION: #{Jason.encode!(trailer)}\n"
      )

    responses = Map.put(responses, merge_url, response_json(merge_commit))

    authorization = %{
      "stage" => "pre_merge",
      "state" => "CONSUMED",
      "receipt_digest" => trailer["receipt_digest"],
      "operation" => trailer["operation"],
      "leg_run_id" => trailer["leg_run_id"],
      "candidate_package" => trailer["package"],
      "candidate_head" => trailer["head_oid"]
    }

    EvidenceLive.capture(
      operation: "linked_release",
      stage: "post_merge",
      package: trailer["package"],
      version: trailer["version"],
      pr: trailer["pr"],
      receipt_digest: trailer["receipt_digest"],
      leg_run_id: trailer["leg_run_id"],
      ci_run_id: trailer["ci_run_id"],
      receipt_run_id: trailer["receipt_run_id"],
      receipt_artifact_id: trailer["receipt_artifact_id"],
      repository: trailer["repository"],
      runbook_commit: trailer["runbook_commit"],
      expected_policy_sha256: expected_policy,
      expected_base_oid: trailer["base_oid"],
      expected_head_oid: trailer["head_oid"],
      expected_tree_oid: trailer["tree_oid"],
      merge_oid: @live_merge,
      source_dir: source_dir,
      authorization: authorization,
      http: fn url -> Map.fetch!(responses, url) end,
      git_ancestor: fn _runbook, _target -> true end
    )
  end

  defp response_json(value),
    do: {:ok, %{status: 200, headers: [], body: Jason.encode!(value)}}

  defp github(path), do: "https://api.github.com/repos/szTheory/crosswake" <> path

  defp assert_both_operations_blocked(context) do
    for operation <- ["render", "check"] do
      gate = gate_for_mode(context.gate, operation)
      write_json!(context.gate_path, gate)
      write_json!(context.result_path, context.result)
      write_json!(context.trailer_path, context.trailer)
      result = run_helper(operation, context)

      assert result.status != 0, "#{operation} unexpectedly passed: #{result.output}"
      refute result.output =~ "publish successor core"
      refute result.output =~ "REL17-AUTHORIZATION:"
    end
  end

  defp gate_for_mode(gate, "render") do
    gate
    |> Map.put("state", "PENDING")
    |> Map.put("authorized", false)
    |> Map.put("consumed", false)
  end

  defp gate_for_mode(gate, "check") do
    gate
    |> Map.put("state", "AUTHORIZED")
    |> Map.put("authorized", true)
    |> Map.put("consumed", false)
  end

  defp assert_scanner_failure(workflow) do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: workflow})
    assert status != 0, output
    assert output =~ "FAIL: release.rel17.approved_guard", output
  end

  defp gate_record(result, result_path, state, authorized) do
    %{
      "schema_version" => 1,
      "stage" => "pre_merge",
      "state" => state,
      "consumed" => false,
      "authorized" => authorized,
      "operation" => "linked_release",
      "identity" => result["identity"],
      "candidate" => result["candidate"],
      "pending_authorization" => result["authorization"],
      "hex_rehearsal_run_id" => result["identity"]["leg_run_id"],
      "evidence" => %{
        "verdict" => "PASS",
        "path" => result_path,
        "envelope_sha256" => result["envelope_sha256"]
      }
    }
  end

  defp trailer_record(result, authorization) do
    identity = result["identity"]
    candidate = result["candidate"]

    %{
      "schema_version" => 1,
      "state" => "AUTHORIZED",
      "consumed" => false,
      "authorization" => authorization,
      "authorization_run_id" => nil,
      "operation" => identity["operation"],
      "package" => candidate["package"],
      "version" => candidate["version"],
      "receipt_digest" => identity["receipt_digest"],
      "leg_run_id" => identity["leg_run_id"],
      "pr" => candidate["pr"],
      "base_oid" => candidate["base_oid"],
      "head_oid" => candidate["head_oid"],
      "tree_oid" => candidate["tree_oid"],
      "ci_run_id" => 303,
      "receipt_run_id" => 304,
      "receipt_artifact_id" => 305,
      "repository" => "szTheory/crosswake",
      "runbook_commit" => String.duplicate("e", 40),
      "policy_sha256" => String.duplicate("f", 64)
    }
  end

  defp write_json!(path, value), do: File.write!(path, Jason.encode!(value))

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
