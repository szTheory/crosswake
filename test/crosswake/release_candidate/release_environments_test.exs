defmodule Crosswake.ReleaseCandidate.ReleaseEnvironmentsTest do
  # Network-free fixtures for script/release_candidate/check_release_environments.sh
  # (Phase 199, REL-07, D-01). Each failure reason has its own test asserting the exit status
  # and the exact final `verdict=` and `reason=` tokens. The live GitHub repository is read
  # by hand and recorded in the phase evidence, never from this suite.
  use ExUnit.Case, async: true

  @script Path.expand("../../../script/release_candidate/check_release_environments.sh", __DIR__)
  @names ~w(release-tags publish-hex publish-maven publish-ios-mirror)

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-release-env-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf(dir) end)

    for name <- @names do
      write_env(dir, name, protected_body(name))
    end

    {:ok, dir: dir}
  end

  test "1 PASS: four protected environments print four PASS lines and a PASS verdict", %{dir: dir} do
    {output, status} = run(dir)

    assert status == 0
    assert verdict(output) == "verdict=PASS"

    for name <- @names do
      assert output =~
               "release-env: #{name} reviewer_rule=present branch_policy=protected verdict=PASS\n"
    end

    pass_lines =
      output |> String.split("\n") |> Enum.filter(&String.ends_with?(&1, "verdict=PASS"))

    # four per-name lines plus the final line
    assert length(pass_lines) == 5
  end

  test "2 environment_missing: a 404 for one name is FAIL, and every name is still printed",
       %{dir: dir} do
    File.write!(Path.join(dir, "publish-maven.status"), "404\n")
    File.rm!(Path.join(dir, "publish-maven.json"))
    {output, status} = run(dir)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=environment_missing"

    assert output =~
             "release-env: publish-maven reviewer_rule=absent branch_policy=none verdict=FAIL reason=environment_missing\n"

    assert output =~
             "release-env: release-tags reviewer_rule=present branch_policy=protected verdict=PASS\n"
  end

  test "3 reviewer_rule_missing: no protection_rules key at all is never read as protected",
       %{dir: dir} do
    body = protected_body("publish-hex") |> Map.delete("protection_rules")
    write_env(dir, "publish-hex", body)
    {output, status} = run(dir)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=reviewer_rule_missing"

    assert output =~
             "release-env: publish-hex reviewer_rule=absent branch_policy=protected verdict=FAIL reason=reviewer_rule_missing\n"
  end

  test "4 reviewer_rule_empty: a required_reviewers entry with an empty reviewers array",
       %{dir: dir} do
    body =
      protected_body("publish-ios-mirror")
      |> Map.put("protection_rules", [
        %{"id" => 1, "type" => "required_reviewers", "reviewers" => []}
      ])

    write_env(dir, "publish-ios-mirror", body)
    {output, status} = run(dir)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=reviewer_rule_empty"
  end

  test "5 branch_policy_open: protected_branches false is FAIL", %{dir: dir} do
    body =
      protected_body("release-tags")
      |> Map.put("deployment_branch_policy", %{
        "protected_branches" => false,
        "custom_branch_policies" => false
      })

    write_env(dir, "release-tags", body)
    {output, status} = run(dir)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=branch_policy_open"

    assert output =~
             "release-env: release-tags reviewer_rule=present branch_policy=open verdict=FAIL reason=branch_policy_open\n"
  end

  test "6 github_unreadable: a repeating 503 is exit 3 UNVERIFIED, never a pass", %{dir: dir} do
    File.write!(Path.join(dir, "publish-hex.status"), "503\n")
    {output, status} = run(dir)

    assert status == 3
    assert verdict(output) == "verdict=UNVERIFIED reason=github_unreadable"
    assert output =~ "attempt 3/3"
  end

  test "7 the fixtures variable without the selftest flag exits 2", %{dir: dir} do
    {output, status} =
      System.cmd("bash", [@script],
        env: [
          {"CROSSWAKE_RELEASE_ENV_FIXTURES", dir},
          {"CROSSWAKE_RELEASE_ENV_SELFTEST", ""}
        ],
        stderr_to_stdout: true
      )

    assert status == 2
    assert verdict(output) == "verdict=ERROR reason=selftest_seam_refused"
  end

  test "8 a short rate limit is waited out once: 429 with Retry-After 0, then 200", %{dir: dir} do
    File.write!(Path.join(dir, "publish-maven.status"), "429\n200\n")
    File.write!(Path.join(dir, "publish-maven.headers"), "HTTP/2 429\r\nRetry-After: 0\r\n\r\n")
    {output, status} = run(dir)

    assert status == 0
    assert verdict(output) == "verdict=PASS"

    waits =
      output |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "release-env: wait "))

    assert waits == ["release-env: wait 0s reason=retry_after"]
  end

  test "9 a long rate limit is never waited out: 429 with Retry-After 3600 is exit 3 at once",
       %{dir: dir} do
    File.write!(Path.join(dir, "publish-maven.status"), "429\n")

    File.write!(
      Path.join(dir, "publish-maven.headers"),
      "HTTP/2 429\r\nRetry-After: 3600\r\n\r\n"
    )

    {micros, {output, status}} = :timer.tc(fn -> run(dir) end)

    assert status == 3
    assert verdict(output) == "verdict=UNVERIFIED reason=github_unreadable"
    refute output =~ "release-env: wait "
    assert micros < 10_000_000
  end

  test "10 a 403 with no usable rate-limit header is exit 3 at once", %{dir: dir} do
    File.write!(Path.join(dir, "publish-ios-mirror.status"), "403\n")
    {output, status} = run(dir)

    assert status == 3
    assert verdict(output) == "verdict=UNVERIFIED reason=github_unreadable"
    refute output =~ "release-env: wait "
  end

  defp run(dir) do
    System.cmd("bash", [@script],
      env: [
        {"CROSSWAKE_RELEASE_ENV_SELFTEST", "1"},
        {"CROSSWAKE_RELEASE_ENV_FIXTURES", dir},
        {"CROSSWAKE_RELEASE_ENV_RETRY_SLEEP", "0"}
      ],
      stderr_to_stdout: true
    )
  end

  defp write_env(dir, name, body) do
    File.write!(Path.join(dir, "#{name}.status"), "200\n")
    File.write!(Path.join(dir, "#{name}.json"), Jason.encode!(body))
  end

  defp protected_body(name) do
    %{
      "name" => name,
      "protection_rules" => [
        %{
          "id" => 1,
          "type" => "required_reviewers",
          "prevent_self_review" => false,
          "reviewers" => [
            %{"type" => "User", "reviewer" => %{"login" => "fixture-maintainer", "id" => 1}}
          ]
        }
      ],
      "deployment_branch_policy" => %{
        "protected_branches" => true,
        "custom_branch_policies" => false
      }
    }
  end

  defp verdict(output) do
    line = output |> String.trim_trailing() |> String.split("\n") |> List.last()

    case Regex.run(~r/^release-env: (verdict=\S+(?: reason=\S+)?)$/, line, capture: :all_but_first) do
      [tokens] -> tokens
      nil -> "no verdict on last line: #{line}"
    end
  end
end
