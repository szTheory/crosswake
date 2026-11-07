defmodule Crosswake.ReleaseCandidate.CompanionPublishAuthorizationTest do
  use ExUnit.Case, async: false

  alias Crosswake.Phase175Rel17Fixtures, as: Rel17
  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @script "script/release_candidate/companion_publish_authorization.sh"
  @release_workflow ".github/workflows/release-please.yml"
  @prefix "REL17-AUTHORIZATION: "
  @package "crosswake_threadline"
  @leg_run_id 4242

  @guard_keys ~w(authorization authorization_run_id base_oid ci_run_id consumed head_oid leg_run_id
                 operation package policy_sha256 pr receipt_artifact_id receipt_digest
                 receipt_run_id repository runbook_commit schema_version state tree_oid version)

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-companion-authorization-#{System.unique_integer([:positive])}"
      )

    evidence_dir = Path.join(root, "evidence")
    source_dir = Path.join(evidence_dir, "premerge-sources")
    File.mkdir_p!(source_dir)

    identity = %{
      "receipt_digest" => String.duplicate("a", 64),
      "operation" => "companion_publish",
      "leg_run_id" => @leg_run_id
    }

    candidate = %{
      "package" => @package,
      "pr" => 262,
      "version" => "0.1.1",
      "base_oid" => String.duplicate("b", 40),
      "head_oid" => String.duplicate("c", 40),
      "tree_oid" => String.duplicate("d", 40),
      "merge_oid" => nil
    }

    authorization = %{
      "stage" => "pre_merge",
      "state" => "PENDING",
      "receipt_digest" => identity["receipt_digest"],
      "operation" => identity["operation"],
      "leg_run_id" => identity["leg_run_id"],
      "candidate_package" => candidate["package"],
      "candidate_head" => candidate["head_oid"]
    }

    envelope = %{
      "schema_version" => 1,
      "stage" => "pre_merge",
      "identity" => identity,
      "candidate" => candidate,
      "authorization" => authorization,
      "conditions" => []
    }

    envelope_bytes = Jason.encode!(envelope)
    envelope_path = Path.join(source_dir, "envelope.json")
    File.write!(envelope_path, envelope_bytes)

    result = %{
      "stage" => "pre_merge",
      "verdict" => "PASS",
      "identity" => identity,
      "candidate" => candidate,
      "authorization" => authorization,
      "envelope_sha256" => sha256(envelope_bytes),
      "envelope_path" => "premerge-sources/envelope.json"
    }

    options = %{
      "operation" => "companion_publish",
      "stage" => "pre_merge",
      "package" => candidate["package"],
      "version" => candidate["version"],
      "pr" => candidate["pr"],
      "receipt_digest" => identity["receipt_digest"],
      "leg_run_id" => identity["leg_run_id"],
      "ci_run_id" => 303,
      "receipt_run_id" => 304,
      "receipt_artifact_id" => 305,
      "repository" => "szTheory/crosswake",
      "runbook_commit" => String.duplicate("e", 40),
      "expected_policy_sha256" => String.duplicate("f", 64),
      "expected_base_oid" => candidate["base_oid"],
      "expected_head_oid" => candidate["head_oid"],
      "expected_tree_oid" => candidate["tree_oid"],
      "source_dir" => "premerge-sources",
      "authorization" => authorization
    }

    result_path = Path.join(evidence_dir, "premerge-result.json")
    options_path = Path.join(evidence_dir, "premerge-options.json")
    write_json!(result_path, result)
    write_json!(options_path, options)

    on_exit(fn -> File.rm_rf!(root) end)

    {:ok,
     %{
       root: root,
       result: result,
       result_path: result_path,
       options: options,
       options_path: options_path,
       envelope_path: envelope_path,
       envelope_bytes: envelope_bytes,
       trailer_path: Path.join(root, "trailer.txt"),
       trailer_json_path: Path.join(root, "guard-trailer.json")
     }}
  end

  test "render prints one REL17-AUTHORIZATION line with the guard's twenty keys and the companion phrase",
       context do
    result = run("render", context)

    assert result.status == 0, result.output
    assert String.ends_with?(result.output, "\n")
    lines = String.split(result.output, "\n", trim: true)
    assert [line] = lines
    assert String.starts_with?(line, @prefix)

    trailer = decode_line!(line)

    assert Enum.sort(Map.keys(trailer)) == Enum.sort(@guard_keys)
    assert length(@guard_keys) == 20
    assert trailer["authorization"] == "publish companion #{@package} #{@leg_run_id}"
    assert trailer["authorization_run_id"] == nil
    assert trailer["state"] == "AUTHORIZED"
    assert trailer["consumed"] == false
    assert trailer["operation"] == "companion_publish"
    assert trailer["package"] == @package
    assert trailer["version"] == "0.1.1"
    assert trailer["pr"] == 262
    assert trailer["leg_run_id"] == @leg_run_id
    assert trailer["policy_sha256"] == context.options["expected_policy_sha256"]
    assert trailer["base_oid"] == context.result["candidate"]["base_oid"]
    assert trailer["head_oid"] == context.result["candidate"]["head_oid"]
    assert trailer["tree_oid"] == context.result["candidate"]["tree_oid"]
    assert trailer["ci_run_id"] == 303
    assert trailer["receipt_run_id"] == 304
    assert trailer["receipt_artifact_id"] == 305
  end

  test "the rendered trailer passes the real release-please guard predicate and the real context loader; a core phrase fails both",
       context do
    trailer = render_trailer!(context)

    {output, status} = run_workflow_predicate(context, trailer, "companion_publish")
    assert status == 0, output

    loader = Rel17.run_loader(loader_context(trailer), loader_expected(trailer))
    on_exit(fn -> Rel17.clean_loader_result(loader) end)
    assert loader.status == 0, loader.output
    assert loader.env =~ "REL17_LEG_RUN_ID=#{@leg_run_id}\n"
    assert loader.env =~ "REL17_PACKAGE=#{@package}\n"

    core_phrase = Map.put(trailer, "authorization", "publish successor core #{@leg_run_id}")

    {output, status} = run_workflow_predicate(context, core_phrase, "companion_publish")
    assert status != 0, output

    core_loader =
      Rel17.run_loader(
        loader_context(trailer, authorization: core_phrase["authorization"]),
        loader_expected(trailer)
      )

    on_exit(fn -> Rel17.clean_loader_result(core_loader) end)
    assert core_loader.status != 0
    assert core_loader.output =~ "REL-17 BLOCKED"
  end

  test "check accepts the rendered trailer against the same result and options", context do
    render_trailer!(context)

    result = run("check", context)

    assert result.status == 0, result.output
    assert result.output == "companion authorization binding PASS\n"
  end

  test "check rejects a trailer naming another companion, another leg run or the leg 3 phrase",
       context do
    trailer = render_trailer!(context)

    other_package =
      Map.merge(trailer, %{
        "package" => "crosswake_chimeway",
        "authorization" => "publish companion crosswake_chimeway #{@leg_run_id}"
      })

    other_leg =
      Map.merge(trailer, %{
        "leg_run_id" => @leg_run_id + 1,
        "authorization" => "publish companion #{@package} #{@leg_run_id + 1}"
      })

    leg_three =
      Map.merge(trailer, %{
        "authorization_run_id" => 777,
        "authorization" => "publish leg 3 777"
      })

    wrong_phrase_only = Map.put(trailer, "authorization", "publish companion #{@package} 1")

    for {label, changed} <- [
          other_package: other_package,
          other_leg: other_leg,
          leg_three: leg_three,
          wrong_phrase_only: wrong_phrase_only
        ] do
      write_trailer!(context, changed)
      result = run("check", context)

      assert result.status == 1, "#{label}: #{result.output}"
      assert result.output == "REL-17 BLOCKED reason=trailer_mismatch\n", "#{label}"
    end
  end

  test "render and check reject a result for another operation or a package outside the five companions",
       context do
    render_trailer!(context)

    mutations = [
      linked_release: fn result ->
        result
        |> put_in(["identity", "operation"], "linked_release")
        |> put_in(["authorization", "operation"], "linked_release")
      end,
      recovery: fn result ->
        result
        |> put_in(["identity", "operation"], "recovery")
        |> put_in(["authorization", "operation"], "recovery")
      end,
      core_package: fn result ->
        result
        |> put_in(["candidate", "package"], "crosswake")
        |> put_in(["authorization", "candidate_package"], "crosswake")
      end,
      unknown_package: fn result ->
        result
        |> put_in(["candidate", "package"], "crosswake_other")
        |> put_in(["authorization", "candidate_package"], "crosswake_other")
      end
    ]

    for {label, mutate} <- mutations do
      write_json!(context.result_path, mutate.(context.result))

      for mode <- ["render", "check"] do
        result = run(mode, context)

        assert result.status == 1, "#{label} #{mode}: #{result.output}"
        assert result.output == "REL-17 BLOCKED reason=result_not_ready\n", "#{label} #{mode}"
        refute result.output =~ @prefix
        refute result.output =~ "publish companion"
      end
    end
  end

  test "render and check reject an unready result, a mismatched envelope digest or mismatched options",
       context do
    render_trailer!(context)

    result_cases = [
      verdict_not_pass: put_in(context.result, ["verdict"], "BLOCKED"),
      authorization_not_pending: put_in(context.result, ["authorization", "state"], "CONSUMED"),
      merge_oid_present:
        put_in(context.result, ["candidate", "merge_oid"], String.duplicate("9", 40)),
      candidate_head_differs:
        put_in(context.result, ["authorization", "candidate_head"], String.duplicate("9", 40)),
      stage_not_pre_merge: put_in(context.result, ["stage"], "post_merge")
    ]

    for {label, mutated} <- result_cases do
      write_json!(context.result_path, mutated)
      assert_both_blocked(context, "result_not_ready", label)
    end

    write_json!(context.result_path, context.result)

    # The envelope digest named by the result must match the envelope file it names.
    File.write!(context.envelope_path, context.envelope_bytes <> " ")
    assert_both_blocked(context, "envelope_mismatch", :envelope_file_changed)
    File.write!(context.envelope_path, context.envelope_bytes)

    write_json!(
      context.result_path,
      put_in(context.result, ["envelope_sha256"], String.duplicate("0", 64))
    )

    assert_both_blocked(context, "envelope_mismatch", :declared_digest_changed)

    write_json!(
      context.result_path,
      put_in(context.result, ["envelope_path"], "../premerge-options.json")
    )

    assert_both_blocked(context, "envelope_mismatch", :envelope_path_escapes)
    write_json!(context.result_path, context.result)

    option_cases = [
      other_package: put_in(context.options, ["package"], "crosswake_chimeway"),
      other_leg: put_in(context.options, ["leg_run_id"], @leg_run_id + 1),
      other_head: put_in(context.options, ["expected_head_oid"], String.duplicate("9", 40)),
      other_tree: put_in(context.options, ["expected_tree_oid"], String.duplicate("9", 40)),
      other_base: put_in(context.options, ["expected_base_oid"], String.duplicate("9", 40)),
      other_digest: put_in(context.options, ["receipt_digest"], String.duplicate("9", 64)),
      wrong_stage: put_in(context.options, ["stage"], "post_merge"),
      other_repository: put_in(context.options, ["repository"], "example/other")
    ]

    for {label, mutated} <- option_cases do
      write_json!(context.options_path, mutated)
      assert_both_blocked(context, "options_mismatch", label)
    end
  end

  test "check rejects a trailer that diverges from the result or options, and no mode edits an input file",
       context do
    trailer = render_trailer!(context)

    before = snapshot(context)

    assert run("render", context).status == 0
    assert run("check", context).status == 0
    assert snapshot(context) == before

    divergent = [
      base_oid: String.duplicate("9", 40),
      head_oid: String.duplicate("9", 40),
      tree_oid: String.duplicate("9", 40),
      receipt_digest: String.duplicate("9", 64),
      ci_run_id: trailer["ci_run_id"] + 1,
      receipt_run_id: trailer["receipt_run_id"] + 1,
      receipt_artifact_id: trailer["receipt_artifact_id"] + 1
    ]

    for {key, value} <- divergent do
      write_trailer!(context, Map.put(trailer, Atom.to_string(key), value))
      result = run("check", context)

      assert result.status == 1, "#{key}: #{result.output}"
      assert result.output == "REL-17 BLOCKED reason=trailer_mismatch\n", "#{key}"
    end

    # A trailer file with no line, two lines, or text before the prefix is also refused.
    File.write!(context.trailer_path, "")
    assert run("check", context).status == 1

    one = @prefix <> Jason.encode!(trailer) <> "\n"
    File.write!(context.trailer_path, one <> one)
    assert run("check", context).status == 1

    File.write!(context.trailer_path, "note " <> one)
    assert run("check", context).status == 1

    # Usage errors exit 2 and never print a trailer.
    {output, status} = System.cmd("bash", [@script, "render"], stderr_to_stdout: true)
    assert status == 2
    refute output =~ @prefix

    assert snapshot(context) == Map.put(before, :trailer, File.read!(context.trailer_path))
  end

  defp run(mode, context) do
    args =
      case mode do
        "render" ->
          [@script, "render", context.result_path, context.options_path]

        "check" ->
          [@script, "check", context.result_path, context.options_path, context.trailer_path]
      end

    {output, status} = System.cmd("bash", args, stderr_to_stdout: true)
    %{output: output, status: status}
  end

  defp render_trailer!(context) do
    {output, 0} =
      System.cmd("bash", [@script, "render", context.result_path, context.options_path],
        stderr_to_stdout: true
      )

    File.write!(context.trailer_path, output)
    decode_line!(String.trim_trailing(output, "\n"))
  end

  defp write_trailer!(context, trailer),
    do: File.write!(context.trailer_path, @prefix <> Jason.encode!(trailer) <> "\n")

  defp decode_line!(@prefix <> json), do: Jason.decode!(json)

  defp assert_both_blocked(context, reason, label) do
    for mode <- ["render", "check"] do
      result = run(mode, context)

      assert result.status == 1, "#{label} #{mode}: #{result.output}"
      assert result.output == "REL-17 BLOCKED reason=#{reason}\n", "#{label} #{mode}"
      refute result.output =~ @prefix
    end
  end

  defp snapshot(context) do
    %{
      result: File.read!(context.result_path),
      options: File.read!(context.options_path),
      envelope: File.read!(context.envelope_path),
      trailer: File.read!(context.trailer_path)
    }
  end

  defp loader_context(trailer, overrides \\ []) do
    [
      operation: trailer["operation"],
      package: trailer["package"],
      version: trailer["version"],
      pr: trailer["pr"],
      leg_run_id: trailer["leg_run_id"],
      receipt_digest: trailer["receipt_digest"],
      ci_run_id: trailer["ci_run_id"],
      receipt_run_id: trailer["receipt_run_id"],
      receipt_artifact_id: trailer["receipt_artifact_id"],
      repository: trailer["repository"],
      runbook_commit: trailer["runbook_commit"],
      policy_sha256: trailer["policy_sha256"],
      expected_policy_sha256: trailer["policy_sha256"],
      base_oid: trailer["base_oid"],
      expected_base_oid: trailer["base_oid"],
      head_oid: trailer["head_oid"],
      expected_head_oid: trailer["head_oid"],
      tree_oid: trailer["tree_oid"],
      expected_tree_oid: trailer["tree_oid"],
      authorization_run_id: trailer["authorization_run_id"],
      authorization: trailer["authorization"]
    ]
    |> Keyword.merge(overrides)
    |> Rel17.context()
  end

  defp loader_expected(trailer),
    do: [
      operation: trailer["operation"],
      package: trailer["package"],
      version: trailer["version"]
    ]

  defp run_workflow_predicate(context, trailer, operation) do
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

    write_json!(context.trailer_json_path, trailer)

    args = [
      "-e",
      "--arg",
      "operation",
      operation,
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
      context.trailer_json_path
    ]

    System.cmd("jq", args, stderr_to_stdout: true)
  end

  defp write_json!(path, value), do: File.write!(path, Jason.encode!(value))

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
