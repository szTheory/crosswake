defmodule Crosswake.Proof.Phase166RepositoryQualityTest do
  use ExUnit.Case, async: true

  @policy_path "script/repository_artifact_policy.json"
  @fixture_path "test/fixtures/repository_quality/artifact-cases.json"
  @allowed_policy_keys ~w(schema_version ignored_transient intentionally_tracked generated_contracts forbidden_tracked safe_fixtures)
  @record_keys %{
    "ignored_transient" => ~w(category matchers remediation_command),
    "intentionally_tracked" => ~w(category paths purpose),
    "forbidden_tracked" => ~w(category matchers remediation_command)
  }
  @matcher_keys ~w(kind value)
  @matcher_kinds ~w(exact segment suffix tree)

  @tag :artifact_policy
  test "artifact policy is closed, ordered, non-overlapping, and narrow" do
    policy = decode!(@policy_path)

    assert Map.keys(policy) |> Enum.sort() == Enum.sort(@allowed_policy_keys)
    assert policy["schema_version"] == 1

    for class <- ~w(ignored_transient intentionally_tracked forbidden_tracked) do
      records = policy[class]
      assert is_list(records) and records != []
      assert Enum.map(records, & &1["category"]) == Enum.sort(Enum.map(records, & &1["category"]))
      assert length(Enum.uniq_by(records, & &1["category"])) == length(records)

      for record <- records do
        assert Map.keys(record) |> Enum.sort() == Enum.sort(@record_keys[class])
        assert is_binary(record["category"]) and record["category"] != ""
      end
    end

    for class <- ~w(ignored_transient forbidden_tracked), record <- policy[class] do
      assert record["matchers"] != []
      assert record["remediation_command"] =~ ~r/^\S/

      for matcher <- record["matchers"] do
        assert Map.keys(matcher) |> Enum.sort() == @matcher_keys
        assert matcher["kind"] in @matcher_kinds
        assert valid_repo_path?(matcher["value"])
      end
    end

    for record <- policy["intentionally_tracked"] do
      assert record["paths"] != []
      assert record["paths"] == Enum.sort(record["paths"])
      assert Enum.all?(record["paths"], &valid_repo_path?/1)
      assert is_binary(record["purpose"]) and record["purpose"] != ""
    end

    safe_fixtures = policy["safe_fixtures"]

    assert safe_fixtures == [
             %{
               "path" => "examples/phoenix_host/.env",
               "forbidden_category" => "forbidden_secret",
               "purpose" => "Non-secret Compose project and fixed local port fixture"
             }
           ]

    assert Enum.all?(policy["generated_contracts"], &valid_generated_contract?/1)
    assert no_duplicate_matchers?(policy)
  end

  @tag :artifact_policy
  test "closed fixture matrix classifies without reading suspicious contents" do
    policy = decode!(@policy_path)
    fixture = decode!(@fixture_path)

    assert Map.keys(fixture) |> Enum.sort() == ~w(cases schema_version secret_sentinel)
    assert fixture["schema_version"] == 1
    names = Enum.map(fixture["cases"], & &1["name"])
    assert names == Enum.sort(names)
    assert names == Enum.uniq(names)

    for artifact <- fixture["cases"] do
      assert classify(policy, artifact) == artifact["expected"]
    end

    hostile = Enum.find(fixture["cases"], &(&1["name"] == "hostile-forbidden-path"))
    assert Jason.encode!(hostile["path"]) == ~S("config/line\nbreak.pem")
  end

  @tag :artifact_policy
  test "unknown keys and ambiguous policy records fail closed" do
    policy = decode!(@policy_path)

    refute valid_policy?(Map.put(policy, "future_class", []))

    overlap =
      update_in(policy, ["ignored_transient"], fn records ->
        [
          %{
            "category" => "ambiguous_editor",
            "matchers" => [%{"kind" => "suffix", "value" => ".swp"}],
            "remediation_command" => "rm -- <repository-relative-path>"
          }
          | records
        ]
      end)

    refute no_duplicate_matchers?(overlap)
  end

  @tag :generated_contracts
  test "generated contract registry names one source, two argv calls, and eight exact outputs" do
    policy = decode!(@policy_path)

    assert [registry] = policy["generated_contracts"]
    assert valid_generated_contract?(registry)
    assert registry["canonical_source"] == "lib/mix/tasks/crosswake.contract.gen.ex"

    assert registry["regeneration_argv"] == [
             ["mix", "crosswake.contract.gen"],
             ["mix", "crosswake.contract.gen", "--dev"]
           ]

    assert registry["output_paths"] == [
             "docs/_contract_snippet.md",
             "examples/android_shell_host/app/src/dev/assets/route_activation.json",
             "examples/android_shell_host/app/src/main/assets/route_activation.json",
             "examples/ios_shell_host/Fixtures/route_activation-dev.json",
             "examples/ios_shell_host/Fixtures/route_activation.json",
             "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json",
             "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json",
             "test/fixtures/bridge_contract_vectors.json"
           ]

    assert registry["remediation_command"] ==
             "mix crosswake.contract.gen && mix crosswake.contract.gen --dev"
  end

  defp decode!(path), do: path |> File.read!() |> Jason.decode!()

  defp valid_policy?(policy),
    do: Map.keys(policy) |> Enum.sort() == Enum.sort(@allowed_policy_keys)

  defp valid_generated_contract?(record) do
    Map.keys(record) |> Enum.sort() ==
      ~w(canonical_source output_paths regeneration_argv remediation_command) and
      is_binary(record["canonical_source"]) and record["canonical_source"] != "" and
      is_list(record["regeneration_argv"]) and length(record["regeneration_argv"]) == 2 and
      Enum.all?(record["regeneration_argv"], fn argv ->
        is_list(argv) and argv != [] and Enum.all?(argv, &(is_binary(&1) and &1 != ""))
      end) and
      is_list(record["output_paths"]) and record["output_paths"] != [] and
      record["output_paths"] == Enum.sort(record["output_paths"]) and
      Enum.all?(record["output_paths"], &valid_repo_path?/1) and
      is_binary(record["remediation_command"]) and record["remediation_command"] != ""
  end

  defp no_duplicate_matchers?(policy) do
    matchers =
      for class <- ~w(ignored_transient forbidden_tracked),
          record <- policy[class],
          matcher <- record["matchers"],
          do: {matcher["kind"], matcher["value"]}

    length(matchers) == length(Enum.uniq(matchers))
  end

  defp classify(policy, artifact) do
    path = artifact["path"]
    safe? = Enum.any?(policy["safe_fixtures"], &(&1["path"] == path))
    ignored = matching_categories(policy["ignored_transient"], path)
    forbidden = matching_categories(policy["forbidden_tracked"], path)

    cond do
      safe? -> "safe_fixture"
      ignored != [] and forbidden != [] -> "ambiguous"
      artifact["tracked"] and forbidden != [] -> hd(forbidden)
      artifact["ignored"] and ignored != [] -> hd(ignored)
      true -> "unknown"
    end
  end

  defp matching_categories(records, path) do
    for record <- records,
        Enum.any?(record["matchers"], &matches?(&1, path)),
        do: record["category"]
  end

  defp matches?(%{"kind" => "exact", "value" => value}, path), do: path == value
  defp matches?(%{"kind" => "suffix", "value" => value}, path), do: String.ends_with?(path, value)

  defp matches?(%{"kind" => "segment", "value" => value}, path),
    do: value in String.split(path, "/")

  defp matches?(%{"kind" => "tree", "value" => value}, path),
    do: path == value or String.starts_with?(path, value <> "/")

  defp valid_repo_path?(value) do
    is_binary(value) and value != "" and not String.starts_with?(value, "/") and
      ".." not in String.split(value, "/")
  end
end
