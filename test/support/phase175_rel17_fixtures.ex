defmodule Crosswake.Phase175Rel17Fixtures do
  @moduledoc false

  @loader "script/release_candidate/load_release_evidence_context.sh"
  @operation "linked_release"
  @package "crosswake"
  @version "0.2.5"
  @base String.duplicate("a", 40)
  @head String.duplicate("b", 40)
  @tree String.duplicate("c", 40)
  @merge String.duplicate("d", 40)
  @policy String.duplicate("e", 64)
  @receipt String.duplicate("f", 64)
  @runbook String.duplicate("1", 40)

  def context(overrides \\ []) do
    values = %{
      authorization_run_id: nil,
      base_oid: @base,
      ci_run_id: 202,
      consumed: false,
      expected_base_oid: @base,
      expected_head_oid: @head,
      expected_policy_sha256: @policy,
      expected_tree_oid: @tree,
      head_oid: @head,
      leg_run_id: 101,
      merge_oid: @merge,
      operation: @operation,
      package: @package,
      policy_sha256: @policy,
      pr: 113,
      receipt_artifact_id: 303,
      receipt_digest: @receipt,
      receipt_run_id: 304,
      repository: "szTheory/crosswake",
      runbook_commit: @runbook,
      schema_version: 1,
      stage: "post_merge",
      state: "AUTHORIZED",
      tree_oid: @tree,
      version: @version
    }

    values = Map.merge(values, Map.new(overrides))

    authorization =
      Keyword.get(overrides, :authorization) ||
        case {values.operation, values.package, values.pr} do
          {"linked_release", _, _} ->
            "publish successor core #{values.leg_run_id}"

          {"recovery", _, _} ->
            "recover #{values.package} #{values.leg_run_id}"

          {"companion_publish", "crosswake_chimeway", 115} ->
            "publish leg 3 #{values.authorization_run_id}"

          {"companion_publish", _, _} ->
            "publish companion #{values.package} #{values.leg_run_id}"
        end

    values = Map.put(values, :authorization, authorization)

    authorization_json = %{
      stage: "pre_merge",
      state: "CONSUMED",
      receipt_digest: values.receipt_digest,
      operation: values.operation,
      leg_run_id: values.leg_run_id,
      candidate_package: values.package,
      candidate_head: values.expected_head_oid
    }

    values
    |> Map.put(:authorization_json, Jason.encode!(authorization_json))
    |> Jason.encode!()
  end

  def run_loader(context, expected \\ []) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-rel17-context-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    env_file = Path.join(dir, "github-env")
    File.write!(env_file, "")

    expected = Map.new(expected)

    env = [
      {"REL17_CONTEXT_JSON", context},
      {"REL17_EXPECTED_OPERATION", Map.get(expected, :operation, @operation)},
      {"REL17_EXPECTED_PACKAGE", Map.get(expected, :package, @package)},
      {"REL17_EXPECTED_VERSION", Map.get(expected, :version, @version)},
      {"REL17_EXPECTED_MERGE_OID", Map.get(expected, :merge_oid, @merge)},
      {"GITHUB_ENV", env_file},
      {"RUNNER_TEMP", dir}
    ]

    {output, status} =
      System.cmd("bash", [@loader], env: env, stderr_to_stdout: true)

    authorization_file =
      env_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.find(&String.starts_with?(&1, "REL17_AUTHORIZATION_FILE="))

    authorization_file =
      if authorization_file,
        do: String.replace_prefix(authorization_file, "REL17_AUTHORIZATION_FILE=", ""),
        else: nil

    %{
      output: output,
      status: status,
      env_file: env_file,
      env: File.read!(env_file),
      auth_file: authorization_file,
      dir: dir
    }
  end

  def clean_loader_result(result), do: File.rm_rf!(result.dir)
end
