defmodule Crosswake.ReleaseCandidate.EvidenceGateTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Crosswake.ReleaseCandidate.EvidenceGate

  @base String.duplicate("a", 40)
  @head String.duplicate("b", 40)
  @tree String.duplicate("c", 40)
  @merge String.duplicate("d", 40)
  @receipt_digest String.duplicate("e", 64)
  @policy_digest String.duplicate("1", 64)
  @runbook_commit String.duplicate("f", 40)
  @leg_run_id 52001

  test "a complete linked post-merge envelope passes with its exact consumed authorization" do
    {envelope, sources} = fixture("post_merge")

    assert {:ok, %{stage: "post_merge", operation: "linked_release"}} =
             EvidenceGate.validate(envelope, sources)
  end

  test "the Mix task validates a seeded envelope, while the shell seam rejects cached evidence" do
    {envelope, sources} = fixture("post_merge")
    root = Path.join(System.tmp_dir!(), "crosswake-rel17-#{System.unique_integer([:positive])}")
    source_dir = Path.join(root, "sources")
    envelope_file = Path.join(root, "envelope.json")
    File.mkdir_p!(source_dir)

    Enum.each(sources, fn {relative_path, bytes} ->
      destination = Path.join(source_dir, relative_path)
      File.mkdir_p!(Path.dirname(destination))
      File.write!(destination, bytes)
    end)

    File.write!(envelope_file, Jason.encode!(envelope))

    task_output =
      capture_io(fn ->
        Mix.Task.clear()

        Mix.Tasks.Crosswake.Release.Gate.run([
          "--operation",
          "linked_release",
          "--stage",
          "post_merge",
          "--package",
          "crosswake",
          "--receipt-digest",
          @receipt_digest,
          "--leg-run-id",
          Integer.to_string(@leg_run_id),
          "--merge-oid",
          @merge,
          "--envelope-file",
          envelope_file,
          "--source-dir",
          source_dir
        ])
      end)

    assert task_output =~ "REL-17 PASS stage=post_merge operation=linked_release"

    {output, status} =
      System.cmd("bash", ["script/release_candidate/require_release_evidence.sh"],
        env: [
          {"MIX_ENV", "test"},
          {"REL17_OPERATION", "linked_release"},
          {"REL17_PACKAGE", "crosswake"},
          {"REL17_RECEIPT_DIGEST", @receipt_digest},
          {"REL17_LEG_RUN_ID", Integer.to_string(@leg_run_id)},
          {"REL17_MERGE_OID", @merge},
          {"REL17_ENVELOPE_FILE", envelope_file},
          {"REL17_SOURCE_DIR", source_dir}
        ],
        stderr_to_stdout: true
      )

    File.rm_rf!(root)
    assert status != 0
    assert output =~ "REL-17 BLOCKED"
    assert output =~ "reason=missing_evidence"
  end

  test "a complete pre-merge envelope validates as evidence without granting publication authority" do
    {envelope, sources} = fixture("pre_merge")

    assert {:ok, %{stage: "pre_merge", next_step: "request_exact_gate"}} =
             EvidenceGate.validate(envelope, sources)
  end

  test "missing evidence, wrong operation, wrong leg, or a ready receipt without exact authority is blocked" do
    {envelope, sources} = fixture("post_merge")

    assert {:error, "missing_evidence"} = EvidenceGate.validate(nil, %{})

    assert {:error, "invalid_operation"} =
             EvidenceGate.validate(
               put_in(envelope, ["identity", "operation"], "publish"),
               sources
             )

    wrong_leg =
      envelope
      |> put_in(["identity", "leg_run_id"], 999)
      |> put_in(["authorization", "leg_run_id"], 999)

    assert {:error, "condition_failed"} = EvidenceGate.validate(wrong_leg, sources)

    assert {:error, "authorization_mismatch"} =
             EvidenceGate.validate(
               put_in(envelope, ["authorization", "state"], "READY FOR APPROVAL"),
               sources
             )
  end

  test "each REL-17 condition and binding blocks when its source fact is changed" do
    {envelope, sources} = fixture("post_merge")
    conditions = envelope["conditions"]

    mutations = [
      replace_facts(envelope, sources, "leg_run", %{
        "run_id" => @leg_run_id,
        "head_oid" => @head,
        "conclusion" => "failure"
      }),
      replace_facts(envelope, sources, "candidate_readiness", %{
        "package" => "crosswake",
        "receipt_digest" => @receipt_digest,
        "base_oid" => @base,
        "head_oid" => @head,
        "tree_oid" => @tree,
        "merge_state" => "MERGEABLE",
        "ci_run_id" => 52002,
        "ci_conclusion" => "success",
        "required_check_ids" => ["Crosswake CI"],
        "required_checks_complete" => true,
        "policy_sha256" => @policy_digest,
        "policy_current" => false,
        "pagination_complete" => true,
        "receipt_artifact_id" => 52003,
        "receipt_artifact_live" => true
      }),
      replace_facts(envelope, sources, "registry_response", %{
        "package" => "crosswake",
        "version" => "0.2.4",
        "parsed" => %{"releases" => []}
      }),
      replace_facts(envelope, sources, "protected_merge", %{
        "merge_oid" => @merge,
        "parents" => [@base, @head],
        "normal_protected_path" => true,
        "admin_bypass" => true
      }),
      replace_facts(envelope, sources, "response_row", %{
        "run_id" => @leg_run_id,
        "package" => "crosswake",
        "version" => "0.2.4",
        "candidate_ref" => String.duplicate("9", 40)
      }),
      replace_facts(envelope, sources, "runbook_ancestry", %{
        "runbook_commit" => @runbook_commit,
        "base_is_ancestor" => false,
        "head_is_ancestor" => true,
        "merge_is_ancestor" => true
      }),
      {put_in(envelope, ["stage"], "pre_merge"), sources},
      {put_in(envelope, ["candidate", "head_oid"], String.duplicate("9", 40)), sources},
      {put_in(envelope, ["conditions", "leg_run", "source_sha256"], String.duplicate("0", 64)),
       sources},
      {put_in(envelope, ["identity", "leg_run_id"], 999), sources}
    ]

    assert map_size(conditions) == 6

    Enum.each(mutations, fn {mutated_envelope, mutated_sources} ->
      assert {:error, _reason} = EvidenceGate.validate(mutated_envelope, mutated_sources)
    end)
  end

  test "the linked workflow requires the shared gate before it can emit linked_release=true" do
    workflow = File.read!(".github/workflows/release-please.yml")
    guard_start = :binary.match(workflow, "approved-release-guard:") |> elem(0)
    authority = :binary.match(workflow, "emit_output \"linked_release=true\"") |> elem(0)

    gate =
      :binary.match(workflow, "script/release_candidate/require_release_evidence.sh") |> elem(0)

    assert guard_start < gate
    assert gate < authority
  end

  defp fixture(stage) do
    post_merge? = stage == "post_merge"
    path = fn name -> "evidence/#{name}.json" end

    evidence = fn name, facts, bytes ->
      {facts_bytes, raw_bytes} =
        case bytes do
          {facts_bytes, raw_bytes} -> {facts_bytes, raw_bytes}
          other -> {other, other}
        end

      source_path = path.(name)
      raw_source_path = path.("raw-#{name}")

      source = %{
        "source_path" => source_path,
        "source_sha256" => digest(facts_bytes),
        "raw_source_path" => raw_source_path,
        "raw_source_sha256" => digest(raw_bytes),
        "facts" => facts
      }

      {source, [{source_path, facts_bytes}, {raw_source_path, raw_bytes}]}
    end

    {leg, leg_source} =
      evidence.(
        "leg-run",
        %{
          "run_id" => @leg_run_id,
          "head_oid" => @head,
          "conclusion" => "success"
        },
        Jason.encode!(%{"run_id" => @leg_run_id, "head_oid" => @head, "conclusion" => "success"})
      )

    {candidate, candidate_source} =
      evidence.(
        "candidate",
        %{
          "package" => "crosswake",
          "receipt_digest" => @receipt_digest,
          "base_oid" => @base,
          "head_oid" => @head,
          "tree_oid" => @tree,
          "merge_state" => "MERGEABLE",
          "ci_run_id" => 52002,
          "ci_conclusion" => "success",
          "required_check_ids" => ["Crosswake CI"],
          "required_checks_complete" => true,
          "policy_sha256" => @policy_digest,
          "policy_current" => true,
          "pagination_complete" => true,
          "receipt_artifact_id" => 52003,
          "receipt_artifact_live" => true
        },
        Jason.encode!(%{
          "package" => "crosswake",
          "receipt_digest" => @receipt_digest,
          "base_oid" => @base,
          "head_oid" => @head,
          "tree_oid" => @tree,
          "merge_state" => "MERGEABLE",
          "ci_run_id" => 52002,
          "ci_conclusion" => "success",
          "required_check_ids" => ["Crosswake CI"],
          "required_checks_complete" => true,
          "policy_sha256" => @policy_digest,
          "policy_current" => true,
          "pagination_complete" => true,
          "receipt_artifact_id" => 52003,
          "receipt_artifact_live" => true
        })
      )

    parsed_registry = %{"releases" => [%{"version" => "0.2.3"}]}

    {registry, registry_source} =
      evidence.(
        "registry",
        %{"package" => "crosswake", "version" => "0.2.4", "parsed" => parsed_registry},
        {
          Jason.encode!(%{
            "package" => "crosswake",
            "version" => "0.2.4",
            "parsed" => parsed_registry
          }),
          Jason.encode!(parsed_registry)
        }
      )

    merge_facts =
      if post_merge? do
        %{
          "merge_oid" => @merge,
          "parents" => [@base, @head],
          "normal_protected_path" => true,
          "admin_bypass" => false
        }
      else
        %{"merge_ready" => true}
      end

    {merge, merge_source} =
      evidence.("merge", merge_facts, Jason.encode!(merge_facts))

    {response_row, response_source} =
      evidence.(
        "hex-response-row",
        %{
          "run_id" => @leg_run_id,
          "package" => "crosswake",
          "version" => "0.2.4",
          "candidate_ref" => @head
        },
        Jason.encode!(%{
          "run_id" => @leg_run_id,
          "package" => "crosswake",
          "version" => "0.2.4",
          "candidate_ref" => @head
        })
      )

    ancestry_facts = %{
      "runbook_commit" => @runbook_commit,
      "base_is_ancestor" => true,
      "head_is_ancestor" => true,
      "merge_is_ancestor" => post_merge?
    }

    {ancestry, ancestry_source} =
      evidence.("runbook-ancestry", ancestry_facts, Jason.encode!(ancestry_facts))

    authorization = %{
      "stage" => "pre_merge",
      "state" => if(post_merge?, do: "CONSUMED", else: "PENDING"),
      "receipt_digest" => @receipt_digest,
      "operation" => "linked_release",
      "leg_run_id" => @leg_run_id,
      "candidate_package" => "crosswake",
      "candidate_head" => @head
    }

    envelope = %{
      "schema_version" => 1,
      "identity" => %{
        "receipt_digest" => @receipt_digest,
        "operation" => "linked_release",
        "leg_run_id" => @leg_run_id
      },
      "stage" => stage,
      "candidate" => %{
        "package" => "crosswake",
        "pr" => 147,
        "version" => "0.2.4",
        "base_oid" => @base,
        "head_oid" => @head,
        "tree_oid" => @tree,
        "merge_oid" => if(post_merge?, do: @merge, else: nil)
      },
      "authorization" => authorization,
      "conditions" => %{
        "leg_run" => leg,
        "candidate_readiness" => candidate,
        "registry_response" => registry,
        "protected_merge" => merge,
        "response_row" => response_row,
        "runbook_ancestry" => ancestry
      }
    }

    sources =
      Map.new(
        leg_source ++
          candidate_source ++
          registry_source ++
          merge_source ++
          response_source ++
          ancestry_source
      )

    {envelope, sources}
  end

  defp replace_facts(envelope, sources, condition_id, facts) do
    condition = envelope["conditions"][condition_id]

    bytes = Jason.encode!(facts)

    raw_bytes =
      if condition_id == "registry_response", do: Jason.encode!(facts["parsed"]), else: bytes

    updated_condition =
      condition
      |> Map.put("facts", facts)
      |> Map.put("source_sha256", digest(bytes))
      |> Map.put("raw_source_sha256", digest(raw_bytes))

    updated_envelope = put_in(envelope, ["conditions", condition_id], updated_condition)

    updated_sources =
      sources
      |> Map.put(condition["source_path"], bytes)
      |> Map.put(condition["raw_source_path"], raw_bytes)

    {updated_envelope, updated_sources}
  end

  defp digest(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
