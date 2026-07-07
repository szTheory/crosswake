#!/usr/bin/env elixir

defmodule Crosswake.ReleaseWorkflowIntegrity do
  @default_workflow ".github/workflows/release-please.yml"
  @components ~w(rulestead rindle sigra chimeway threadline)

  def run(argv \\ System.argv(), env_path \\ System.get_env("RELEASE_WORKFLOW_PATH")) do
    workflow_path = workflow_path(argv, env_path)
    workflow = File.read!(workflow_path)
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    checks =
      [
        concurrency_not_cancelled(non_comment_workflow),
        concurrency_queue_max(non_comment_workflow),
        no_true_cancellation(non_comment_workflow),
        paths_released(non_comment_workflow),
        path_gate(jobs, "release.root_hex.path_gate", "publish-hex", "."),
        path_gate(
          jobs,
          "release.ios.path_gate",
          "publish-ios-core",
          "packages/crosswake-shell-core-ios"
        ),
        path_gate(
          jobs,
          "release.android.path_gate",
          "publish-android-core",
          "packages/crosswake-shell-core-android"
        ),
        aggregate_gate_absent(jobs),
        ios_proof_decoupled(jobs),
        android_proof_decoupled(jobs),
        mirror_token_preflight(jobs),
        cleanup_after_publish_and_proof(jobs),
        cleanup_pr_only(jobs)
      ] ++ component_gates(jobs) ++ component_proof_gates(jobs)

    failures = Enum.filter(checks, &match?({:error, _, _}, &1))

    for {status, id, detail} <- checks do
      prefix = if status == :ok, do: "OK", else: "FAIL"
      IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
    end

    if failures == [] do
      System.halt(0)
    else
      System.halt(1)
    end
  end

  defp workflow_path([path | _], _env_path) when is_binary(path) and path != "", do: path
  defp workflow_path(_, env_path) when is_binary(env_path) and env_path != "", do: env_path
  defp workflow_path(_, _), do: @default_workflow

  defp job_blocks(workflow) do
    ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
    |> Regex.scan(workflow, capture: :all_but_first)
    |> Map.new(fn [name, block] -> {name, strip_full_line_comments(block)} end)
  end

  defp strip_full_line_comments(text) do
    text
    |> String.split("\n", trim: false)
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  defp job_block(jobs, job), do: Map.get(jobs, job, "")

  defp job_if(jobs, job), do: jobs |> job_block(job) |> job_key("if") |> normalize_expression()

  defp job_needs(jobs, job) do
    jobs
    |> job_block(job)
    |> job_key("needs")
    |> then(&Regex.scan(~r/[A-Za-z0-9_-]+/, &1))
    |> List.flatten()
  end

  defp job_needs?(jobs, job, need), do: need in job_needs(jobs, job)

  defp job_key(block, key) do
    lines = String.split(block, "\n", trim: false)
    key_regex = ~r/^    #{Regex.escape(key)}:\s*(.*)$/

    case Enum.find_index(lines, &Regex.match?(key_regex, &1)) do
      nil ->
        ""

      index ->
        line = Enum.at(lines, index)
        [raw_value] = Regex.run(key_regex, line, capture: :all_but_first)
        raw_value = raw_value |> strip_inline_comment() |> String.trim()

        if raw_value == "" or raw_value in ["|", "|-", ">", ">-"] do
          lines
          |> Enum.drop(index + 1)
          |> Enum.take_while(&(not job_level_key?(&1)))
          |> Enum.join("\n")
        else
          raw_value
        end
    end
  end

  defp job_level_key?(line), do: Regex.match?(~r/^    [A-Za-z0-9_-]+:\s*/, line)

  defp strip_inline_comment(line), do: line |> String.split(~r/\s+#/, parts: 2) |> hd()

  defp normalize_expression(value) do
    value
    |> String.split("\n", trim: false)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp check(id, true, detail), do: {:ok, id, detail}
  defp check(id, false, detail), do: {:error, id, detail}

  defp includes?(text, value) when is_binary(value), do: String.contains?(text, value)
  defp includes?(text, %Regex{} = regex), do: Regex.match?(regex, text)

  defp concurrency_not_cancelled(workflow) do
    check(
      "release.concurrency.not_cancelled",
      includes?(workflow, ~r/^\s*cancel-in-progress:\s*false\s*$/m),
      "release workflow publish/proof jobs must keep cancel-in-progress: false; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp concurrency_queue_max(workflow) do
    check(
      "release.concurrency.queue_max",
      includes?(workflow, ~r/^\s*queue:\s*max\s*$/m),
      "release workflow concurrency must preserve pending runs with queue: max; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp no_true_cancellation(workflow) do
    check(
      "release.concurrency.no_true_cancellation",
      not includes?(workflow, ~r/^\s*cancel-in-progress:\s*true\s*$/m),
      "release workflow must not combine release preservation with cancel-in-progress: true; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp paths_released(workflow) do
    check(
      "release.outputs.paths_released",
      includes?(workflow, ~r/^\s*paths_released:/m),
      "release-please must expose paths_released for path-specific publish gates; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp path_gate(jobs, id, job, path) do
    check(
      id,
      job_if(jobs, job) == path_gate_expression(path),
      "#{job} must gate on paths_released exact path #{path}; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp path_gate_expression(path),
    do: "${{ contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}') }}"

  defp component_gate_expression(component),
    do: "${{ needs.release-please.outputs.#{component}_release_created == 'true' }}"

  defp aggregate_gate_absent(jobs) do
    offenders =
      jobs
      |> Enum.filter(fn {job, _block} ->
        behavioral_job?(job) and
          includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
      end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.sort()

    detail =
      case offenders do
        [] ->
          "behavioral jobs must not gate on aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"

        jobs ->
          "behavioral jobs use aggregate releases_created: #{Enum.join(jobs, ", ")}; use exact path/component gates"
      end

    check("release.aggregate_gate.behavioral_jobs_absent", offenders == [], detail)
  end

  defp behavioral_job?(job) do
    String.starts_with?(job, "publish-") or
      String.starts_with?(job, "clean-room-proof-") or
      job == "release-as-cleanup"
  end

  defp ios_proof_decoupled(jobs) do
    check(
      "release.ios_proof.decoupled",
      job_needs?(jobs, "clean-room-proof-ios", "release-please") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-ios", "publish-ios-core") and
        not job_needs?(jobs, "clean-room-proof-ios", "publish-android-core") and
        job_if(jobs, "clean-room-proof-ios") ==
          path_gate_expression("packages/crosswake-shell-core-ios"),
      "iOS clean-room proof must depend on iOS publish and not Android publish; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp android_proof_decoupled(jobs) do
    check(
      "release.android_proof.decoupled",
      job_needs?(jobs, "clean-room-proof-android", "release-please") and
        job_needs?(jobs, "clean-room-proof-android", "publish-hex") and
        job_needs?(jobs, "clean-room-proof-android", "publish-android-core") and
        not job_needs?(jobs, "clean-room-proof-android", "publish-ios-core") and
        job_if(jobs, "clean-room-proof-android") ==
          path_gate_expression("packages/crosswake-shell-core-android"),
      "Android clean-room proof must depend on Android publish and not iOS mirror; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp mirror_token_preflight(jobs) do
    block = job_block(jobs, "publish-ios-core")

    check(
      "release.mirror_token.preflight",
      includes?(block, "MIRROR_PUSH_TOKEN is not configured") and
        includes?(block, "git ls-remote mirror HEAD"),
      "iOS mirror job must fail fast when MIRROR_PUSH_TOKEN is absent or unusable; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp cleanup_after_publish_and_proof(jobs) do
    condition = job_if(jobs, "release-as-cleanup")

    has_release_please_need? = job_needs?(jobs, "release-as-cleanup", "release-please")
    has_always? = includes?(condition, "always()")

    has_all_publish_needs? =
      Enum.all?(@components, &job_needs?(jobs, "release-as-cleanup", "publish-hex-#{&1}"))

    has_all_proof_needs? =
      Enum.all?(@components, &job_needs?(jobs, "release-as-cleanup", "clean-room-proof-#{&1}"))

    has_all_result_implications? =
      Enum.all?(@components, fn component ->
        includes?(
          condition,
          "needs.release-please.outputs.#{component}_release_created != 'true'"
        ) and
          includes?(condition, "needs.publish-hex-#{component}.result == 'success'") and
          includes?(condition, "needs.clean-room-proof-#{component}.result == 'success'")
      end)

    check(
      "release.cleanup.after_publish_and_proof",
      has_release_please_need? and has_always? and has_all_publish_needs? and
        has_all_proof_needs? and has_all_result_implications? and
        companion_proof_jobs_after_publish?(jobs),
      "release-as-cleanup must need every companion publish/proof job and require success for released components; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp cleanup_pr_only(jobs) do
    block = job_block(jobs, "release-as-cleanup")

    direct_main_push? =
      includes?(
        block,
        ~r/\bgit\s+push\s+\S+\s+(?:main|refs\/heads\/main|[^\s]+:(?:refs\/heads\/)?main)(?:\s|$)/
      )

    check(
      "release.cleanup.pr_only",
      includes?(block, "git checkout -b \"$branch\"") and
        includes?(block, "git push origin \"$branch\"") and
        includes?(block, "gh pr create") and
        includes?(block, "--base main") and
        not direct_main_push?,
      "release-as-cleanup must push a branch and open a PR, never push directly to main; run elixir script/check_release_workflow_integrity.exs"
    )
  end

  defp component_gates(jobs) do
    for component <- @components do
      job = "publish-hex-#{component}"

      check(
        "release.#{component}.component_gate",
        job_if(jobs, job) == component_gate_expression(component),
        "#{job} must gate on #{component}_release_created, not aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"
      )
    end
  end

  defp component_proof_gates(jobs) do
    for component <- @components do
      job = "clean-room-proof-#{component}"

      check(
        "release.#{component}.proof_gate",
        component_proof_after_publish?(jobs, component),
        "#{job} must gate on #{component}_release_created and need publish-hex-#{component}; run elixir script/check_release_workflow_integrity.exs"
      )
    end
  end

  defp companion_proof_jobs_after_publish?(jobs) do
    Enum.all?(@components, &component_proof_after_publish?(jobs, &1))
  end

  defp component_proof_after_publish?(jobs, component) do
    job = "clean-room-proof-#{component}"

    job_if(jobs, job) == component_gate_expression(component) and
      job_needs?(jobs, job, "release-please") and
      job_needs?(jobs, job, "publish-hex-#{component}") and
      not includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
  end
end

Crosswake.ReleaseWorkflowIntegrity.run()
