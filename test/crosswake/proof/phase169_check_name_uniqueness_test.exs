defmodule Crosswake.Proof.Phase169CheckNameUniquenessTest do
  @moduledoc """
  MSG-06 / D-20 / D-21 / D-22 / D-23: duplicate-name detection must actually be able to find a
  duplicate, and no release job or artifact display name may carry a frozen version literal.

  Before this phase, `list_merge_blocking_checks.py`'s duplicate grouping only ran over names
  containing the substring `merge-blocking`. Post-v22.0 that substring matches only de-registered
  legacy names, so the one real collision in the tree (`advisory provider sandbox/device proof
  (storekit + play billing)`, produced by both `phase48-proof.yml` and `phase70-proof.yml`) slipped
  straight through — the check was vacuous by construction. This module proves the widened scan
  fires on a fixture that does NOT contain "merge-blocking" (the exact shape the old filter missed),
  proves the version-literal reject fires on both a job name and an `upload-artifact` name, proves
  the real tree is clean under both new assertions, and proves the same guarantee at the shell entry
  point independent of the Python exit code.
  """
  use ExUnit.Case, async: true

  @discover "script/list_merge_blocking_checks.py"
  @checker "script/check_required_checks_registered.sh"
  @normalizer "script/normalize_required_checks.py"

  defp prepare_fixture!(tmp, workflows) do
    File.mkdir_p!(Path.join(tmp, "script"))
    File.mkdir_p!(Path.join(tmp, ".github/workflows"))
    File.cp!(@discover, Path.join(tmp, @discover))
    File.cp!(@checker, Path.join(tmp, @checker))
    File.cp!(@normalizer, Path.join(tmp, @normalizer))

    Enum.each(workflows, fn {name, source} ->
      File.write!(Path.join(tmp, ".github/workflows/#{name}"), source)
    end)
  end

  defp run_detector(tmp, args \\ ["--producers"]) do
    System.cmd("python3", [@discover | args], cd: tmp, stderr_to_stdout: true)
  end

  defp run_checker(tmp, registered_json) do
    System.cmd("bash", [@checker],
      cd: tmp,
      env: [{"CROSSWAKE_REQUIRED_CHECKS_JSON", registered_json}],
      stderr_to_stdout: true
    )
  end

  @tag :tmp_dir
  test "Task 2: duplicate reject fires on a collision without the substring 'merge-blocking'", %{
    tmp_dir: tmp
  } do
    workflow = fn wf_name, job_id ->
      """
      name: #{wf_name}
      on: [push]
      jobs:
        #{job_id}:
          name: shared display name that never says the word
          runs-on: ubuntu-latest
          steps:
            - run: "true"
      """
    end

    prepare_fixture!(tmp, [
      {"a.yml", workflow.("A", "alpha")},
      {"b.yml", workflow.("B", "beta")}
    ])

    {out, status} = run_detector(tmp)

    assert status == 1,
           "expected the widened duplicate reject to fire (exit 1), got #{status}:\n#{out}"

    assert out =~ "duplicate-producer/duplicate-display-name"
    assert out =~ "a.yml"
    assert out =~ "b.yml"
  end

  @tag :tmp_dir
  test "Task 2: duplicate reject does not over-fire on distinct names", %{tmp_dir: tmp} do
    prepare_fixture!(tmp, [
      {"a.yml",
       """
       name: A
       on: [push]
       jobs:
         alpha:
           name: alpha distinct name
           runs-on: ubuntu-latest
           steps:
             - run: "true"
       """},
      {"b.yml",
       """
       name: B
       on: [push]
       jobs:
         beta:
           name: beta distinct name
           runs-on: ubuntu-latest
           steps:
             - run: "true"
       """}
    ])

    {out, status} = run_detector(tmp)

    assert status == 0,
           "expected no duplicate reject on distinct names, got #{status}:\n#{out}"

    refute out =~ "duplicate-producer/duplicate-display-name"
  end

  @tag :tmp_dir
  test "Task 2: version-literal reject fires on a job display name", %{tmp_dir: tmp} do
    prepare_fixture!(tmp, [
      {"one.yml",
       """
       name: One
       on: [push]
       jobs:
         gate:
           name: prove 1.2.3 thing
           runs-on: ubuntu-latest
           steps:
             - run: "true"
       """}
    ])

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "version-literal-in-display-name"
    assert out =~ "prove 1.2.3 thing"
  end

  @tag :tmp_dir
  test "Task 2: version-literal reject fires on an upload-artifact name", %{tmp_dir: tmp} do
    prepare_fixture!(tmp, [
      {"one.yml",
       """
       name: One
       on: [push]
       jobs:
         gate:
           name: artifact version check
           runs-on: ubuntu-latest
           steps:
             - run: "true"
             - name: Upload thing
               uses: actions/upload-artifact@v4
               with:
                 name: proof-artifact-9.9.9
                 path: out.json
       """}
    ])

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "version-literal-in-display-name"
    assert out =~ "proof-artifact-9.9.9"
  end

  test "Task 2: the real tree is clean under both widened assertions" do
    {out, status} = System.cmd("python3", [@discover, "--producers"], stderr_to_stdout: true)

    lines = out |> String.split("\n", trim: true)

    assert status == 0,
           "expected the real tree to be clean under the widened scan, got #{status}:\n#{out}"

    assert length(lines) > 100,
           "expected more than 100 emitted records (an empty inventory must never pass this " <>
             "assertion vacuously), got #{length(lines)}"

    refute out =~ "duplicate-producer/duplicate-display-name"
    refute out =~ "version-literal-in-display-name"
  end

  @tag :tmp_dir
  test "Task 2: the shell entry point's global-uniqueness branch fires independent of gh", %{
    tmp_dir: tmp
  } do
    workflow = fn wf_name, job_id ->
      """
      name: #{wf_name}
      on: [push]
      jobs:
        #{job_id}:
          name: shell-level shared display name
          runs-on: ubuntu-latest
          steps:
            - run: "true"
      """
    end

    prepare_fixture!(tmp, [
      {"a.yml", workflow.("A", "alpha")},
      {"b.yml", workflow.("B", "beta")}
    ])

    json =
      ~s({"strict":true,"checks":[{"context":"stale-required","app_id":15368}],"contexts":["stale-required"]})

    {out, status} = run_checker(tmp, json)

    assert status == 1,
           "expected the shell entry point's global-uniqueness branch to fail, got #{status}:\n#{out}"

    assert out =~ "duplicate-producer/duplicate-display-name"
    refute out =~ "gh-was-invoked"
  end

  # No Elixir YAML dependency exists in this project (D-18 forbids any new package-manager
  # install for this plan); PyYAML is already the declared parser for these workflow files
  # (list_merge_blocking_checks.py), so tests that need structured workflow data shell out to
  # it and decode the resulting JSON with the already-present Jason dependency.
  defp workflow_json!(path, extractor) do
    {out, 0} =
      System.cmd("python3", [
        "-c",
        """
        import yaml, json, sys
        doc = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
        print(json.dumps(#{extractor}))
        """,
        path
      ])

    Jason.decode!(out)
  end

  # Extracted as pure predicates (rather than inline asserts against the live file) so a
  # synthetic violating fixture can prove each guard is capable of going red (D-23 non-vacuity)
  # instead of resting on "it currently passes against a currently-clean file."
  defp on_trigger_clean?(triggers) do
    is_map(triggers) and Enum.sort(Map.keys(triggers)) == ["push", "workflow_dispatch"]
  end

  defp release_prefix_lowercase?(name) do
    rest = String.trim_leading(name, "release: ")
    rest == String.downcase(rest)
  end

  test "Task 3: release-please.yml's on: mapping has exactly push and workflow_dispatch keys" do
    triggers =
      workflow_json!(".github/workflows/release-please.yml", "doc.get('on', doc.get(True, {}))")

    assert on_trigger_clean?(triggers)
    refute Map.has_key?(triggers, "pull_request")
  end

  test "Task 3: on:-trigger guard fires on a synthetic trigger set with pull_request added" do
    # Non-vacuity proof: the real file cannot be safely mutated by this test (it is live CI
    # config asserted elsewhere), so this proves the PREDICATE the real-file test relies on is
    # capable of going false, not just currently true.
    refute on_trigger_clean?(%{"push" => %{}, "workflow_dispatch" => nil, "pull_request" => %{}})
  end

  test "Task 3: required_check_policy.json declares exactly one target context bound to app id 15368" do
    policy =
      "script/required_check_policy.json"
      |> File.read!()
      |> Jason.decode!()

    assert policy["target_contexts"] == ["Crosswake CI"]
    assert policy["target_check"] == %{"context" => "Crosswake CI", "app_id" => 15368}
  end

  test "Task 3: every 'release: ' prefixed job display name is lowercase after the prefix" do
    job_names =
      workflow_json!(
        ".github/workflows/release-please.yml",
        "[job.get('name') for job in doc['jobs'].values()]"
      )

    prefixed_names =
      job_names
      |> Enum.filter(&(is_binary(&1) and String.starts_with?(&1, "release: ")))

    assert length(prefixed_names) > 0,
           "expected at least one 'release: ' prefixed job name to examine — an empty " <>
             "examined set would make this assertion pass vacuously"

    for name <- prefixed_names do
      assert release_prefix_lowercase?(name), "#{inspect(name)} is not lowercase after the prefix"
    end
  end

  test "Task 3: release: prefix rule fires on a synthetic name with uppercase after the prefix" do
    refute release_prefix_lowercase?("release: Exact-Public Artifact Proof")
  end
end
