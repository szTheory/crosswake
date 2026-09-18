defmodule Crosswake.ReleaseWorkflowFixtures do
  @moduledoc """
  The one fixture harness for `script/check_release_workflow_integrity.exs`.

  Extracted from `Crosswake.Proof.Phase142ReleaseIntegrityTest`, which had carried it
  privately. It lives here so a second proof module can drive the scanner through the
  SAME temp-file-plus-env override machinery and the SAME raise-on-no-op mutation guard,
  rather than standing up a parallel harness with a looser guard beside it — a second,
  weaker mutation helper is how a negative control quietly stops proving anything.

  Every fixture is built by MUTATING the real workflow text. Hand-written minimal YAML
  drifts away from the real graph silently and then proves nothing about it.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @scanner "script/check_release_workflow_integrity.exs"
  @release_workflow ".github/workflows/release-please.yml"

  def scanner, do: @scanner
  def release_workflow_path, do: @release_workflow

  @doc """
  Env var each fixture key overrides in the scanner.

  A key added here is immediately usable from `run_fixture_set/1`. The scanner reads
  every one of these through its own `path_from_env/2`, so a fixture stands in for a
  real file with no live GitHub Actions run.
  """
  def fixture_env_name(:recovery_workflow), do: "HEX_PUBLISH_WORKFLOW_PATH"
  def fixture_env_name(:helper), do: "GUARDED_HEX_PUBLISH_PATH"
  def fixture_env_name(:release_config), do: "RELEASE_PLEASE_CONFIG_PATH"
  def fixture_env_name(:cleanroom_script), do: "CLEANROOM_SCRIPT_PATH"
  def fixture_env_name(:doctor_task), do: "DOCTOR_TASK_PATH"
  def fixture_env_name(:ios_backfill_script), do: "IOS_BACKFILL_SCRIPT_PATH"
  def fixture_env_name(:ios_backfill_workflow), do: "IOS_BACKFILL_WORKFLOW_PATH"
  def fixture_env_name(:exact_public_proof_workflow), do: "EXACT_PUBLIC_PROOF_WORKFLOW_PATH"

  @doc """
  Run the scanner with each fixture written to a temp file and pointed at by its env var.

  `:release_workflow` is the one key the scanner does not read from the environment in
  the normal path — it takes that file as argv — so it is passed as argv here instead.
  """
  def run_fixture_set(fixtures) do
    fixtures = Enum.to_list(fixtures)

    paths =
      Map.new(fixtures, fn {name, contents} ->
        path =
          Path.join(
            System.tmp_dir!(),
            "crosswake-workflow-fixture-#{name}-#{System.unique_integer([:positive])}"
          )

        File.write!(path, contents)
        on_exit(fn -> File.rm(path) end)

        {name, path}
      end)

    env =
      paths
      |> Enum.reject(fn {name, _path} -> name == :release_workflow end)
      |> Enum.map(fn {name, path} -> {fixture_env_name(name), path} end)

    run_scanner(Map.get(paths, :release_workflow, @release_workflow), env)
  end

  def run_scanner(path, env \\ []) do
    System.cmd("elixir", [@scanner, path], stderr_to_stdout: true, env: env)
  end

  @doc """
  Replace `pattern` inside one job block, failing loudly when the pattern is absent.

  Without this a mutation test silently degrades: `String.replace/4` returns the block
  untouched, the scanner then passes on an UNMUTATED workflow, and the negative control
  stops proving anything about the check it names. Drift in the workflow must break the
  mutation test at the mutation site, not somewhere downstream.
  """
  def replace_in_job(workflow, job, pattern, replacement) do
    mutated =
      Regex.replace(
        ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
        workflow,
        fn block ->
          unless String.contains?(block, pattern) do
            raise """
            replace_in_job/4 found no #{inspect(pattern)} in job #{inspect(job)}.

            The mutation would be a no-op, so the negative control would assert nothing.
            The workflow drifted away from the pattern — update the test to the current
            shape, do not delete the control.
            """
          end

          String.replace(block, pattern, replacement, global: false)
        end,
        global: false
      )

    if mutated == workflow do
      raise "replace_in_job/4 did not locate job #{inspect(job)} — the job was renamed or removed"
    end

    mutated
  end

  @doc """
  Delete one named step from one job, through `replace_in_job/4`'s no-op guard.

  The step text is extracted from the REAL file, so a renamed or restructured step
  raises at the mutation site rather than yielding an unmutated fixture.
  """
  def remove_step!(workflow, job, step_name) do
    block = job_block!(workflow, job)

    step =
      case Regex.run(
             ~r/(?ms)^      - name: #{Regex.escape(step_name)}\n.*?(?=^      - |\z)/,
             block
           ) do
        [text] -> text
        _ -> raise "remove_step!/3 found no step #{inspect(step_name)} in job #{inspect(job)}"
      end

    replace_in_job(workflow, job, step, "")
  end

  def job_block!(workflow, job) do
    case Regex.run(
           ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
           workflow
         ) do
      [block] -> block
      _ -> raise "job_block!/2 did not locate job #{inspect(job)}"
    end
  end
end
