defmodule Crosswake.Proof.Phase166RepositoryQualityTest do
  use ExUnit.Case, async: true

  @policy_path "script/repository_artifact_policy.json"
  @ci_manifest_path "script/ci_leaf_manifest.json"
  @ci_workflow_path ".github/workflows/crosswake-ci.yml"
  @quality_gate_path "script/check_phase166_clean_checkout_engineering_quality.sh"
  @fixture_path "test/fixtures/repository_quality/artifact-cases.json"
  @allowed_policy_keys ~w(schema_version ignored_transient intentionally_tracked generated_contracts forbidden_tracked safe_fixtures)
  @record_keys %{
    "ignored_transient" => ~w(category matchers remediation_command),
    "intentionally_tracked" => ~w(category paths purpose),
    "forbidden_tracked" => ~w(category matchers remediation_command)
  }
  @matcher_keys ~w(kind value)
  @matcher_kinds ~w(exact segment suffix tree)

  @tag :tmp_dir
  test "root formatter contract covers repository Elixir sources and rejects unformatted input",
       %{
         tmp_dir: tmp
       } do
    {formatter, _binding} = Code.eval_file(".formatter.exs")

    assert formatter == [inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]]

    File.write!(Path.join(tmp, ".formatter.exs"), inspect(formatter, pretty: true))
    File.mkdir_p!(Path.join(tmp, "lib"))

    File.write!(
      Path.join(tmp, "lib/unformatted.ex"),
      "defmodule Unformatted do\n def value,do: :ok\nend\n"
    )

    {output, status} =
      System.cmd("mix", ["format", "--check-formatted"], cd: tmp, stderr_to_stdout: true)

    assert status != 0
    assert output =~ "mix format failed"
  end

  @tag :tmp_dir
  test "dependency-security fixture proof resolves the repository through physical paths", %{
    tmp_dir: tmp
  } do
    source = File.cwd!()
    link = Path.join(tmp, "crosswake-link")
    File.ln_s!(source, link)

    {output, status} =
      System.cmd(
        "bash",
        [
          Path.join(link, "script/check_dependency_security.sh"),
          "--assert-vulnerable-fixture",
          "test/fixtures/security/advisory-bearing.lock"
        ],
        cd: link,
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "EXPECTED-REJECTION dependency-security"
  end

  test "fresh-checkout companion verification refuses lockfile drift" do
    aliases = File.read!("mix.exs")

    for package <-
          ~w(crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline) do
      assert aliases =~ "cmd --cd packages/#{package} mix deps.get --check-locked"
    end
  end

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
  test "generated contract registry retains legacy generation and adds exact docs sync ownership" do
    policy = decode!(@policy_path)

    assert [legacy, docs] = policy["generated_contracts"]
    assert Enum.all?([legacy, docs], &valid_generated_contract?/1)
    assert legacy["canonical_source"] == "lib/mix/tasks/crosswake.contract.gen.ex"

    assert legacy["regeneration_argv"] == [
             ["mix", "crosswake.contract.gen"],
             ["mix", "crosswake.contract.gen", "--dev"]
           ]

    assert legacy["output_paths"] == [
             "docs/_contract_snippet.md",
             "examples/android_shell_host/app/src/dev/assets/route_activation.json",
             "examples/android_shell_host/app/src/main/assets/route_activation.json",
             "examples/ios_shell_host/Fixtures/route_activation-dev.json",
             "examples/ios_shell_host/Fixtures/route_activation.json",
             "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json",
             "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json",
             "test/fixtures/bridge_contract_vectors.json"
           ]

    assert legacy["remediation_command"] ==
             "mix crosswake.contract.gen && mix crosswake.contract.gen --dev"

    assert docs == %{
             "canonical_source" => "lib/mix/tasks/crosswake.docs.sync.ex",
             "regeneration_argv" => [["mix", "crosswake.docs.sync"]],
             "output_paths" => ["guides/capability_map.md", "guides/support_matrix.md"],
             "remediation_command" => "mix crosswake.docs.sync"
           }

    tracked = System.cmd("git", ["ls-files", "-z"]) |> elem(0) |> String.split("\0")

    for registry <- [legacy, docs] do
      assert registry["canonical_source"] in tracked
      assert File.regular?(registry["canonical_source"])
    end
  end

  @tag :ownership_ledger
  test "ownership ledger rejects incomplete scope, open edges, dispositions, and removal proof" do
    {output, status} =
      System.cmd("python3", ["script/check_phase166_ownership_ledger.py", "--self-test"],
        stderr_to_stdout: true
      )

    assert status == 0, output

    for mutation <- [
          "missing_candidate",
          "extra_candidate",
          "open_edge",
          "unknown_disposition",
          "missing_supported_entrypoint",
          "missing_workflow_config",
          "missing_dependency",
          "missing_dynamic_dispatch",
          "missing_focused_regression",
          "missing_complete_clean_gate"
        ] do
      assert output =~ "PASS #{mutation}"
    end

    assert output =~ "PASS deterministic_remediation_queue"
    assert output =~ "PASS empty_remediation_queue"
    assert output =~ "PASS evidence_binding"
    assert output =~ "PASS evidence_sha_mismatch"
    assert output =~ "PASS missing_evidence_only_path"
  end

  @tag :ownership_remediation
  test "ownership validator emits the exact deterministic remediation queue" do
    ledger =
      ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md"

    {output, status} =
      System.cmd(
        "python3",
        ["script/check_phase166_ownership_ledger.py", "--verify-remediations", ledger],
        stderr_to_stdout: true
      )

    assert status == 0, output

    [summary | rendered_rows] = String.split(output, "\n", trim: true)
    assert summary == "phase166-remediations: PASS count=#{length(rendered_rows)}"

    rows =
      Enum.map(rendered_rows, fn "phase166-remediation: " <> json -> Jason.decode!(json) end)

    source_paths = Enum.map(rows, & &1["source path"])
    assert source_paths == Enum.sort(source_paths)
    assert length(source_paths) == length(Enum.uniq(source_paths))
    assert "examples/phoenix_host/playwright.config.ts" in source_paths
    assert Enum.all?(rows, &(&1["result"] == "pass"))
  end

  @tag :ci_parity
  test "CI authority validator rejects every stage ownership drift mutation" do
    {output, status} =
      System.cmd("python3", ["script/check_ci_leaf_manifest.py", "--self-test"],
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert output =~ "ci leaf manifest self-test: pass"

    for mutation <- [
          "missing_stage_owner",
          "extra_stage_owner",
          "divergent_stage_command",
          "divergent_stage_cwd",
          "divergent_stage_env",
          "duplicate_stage_owner",
          "copied_stage_command"
        ] do
      assert output =~ "PASS #{mutation}"
    end
  end

  @tag :ci_parity
  test "stage parity preserves the literal Phase 165 authority graph" do
    manifest = decode!(@ci_manifest_path)
    workflow = File.read!(@ci_workflow_path)

    assert length(manifest["proof_leaves"]) == 44

    assert manifest["required_control_nodes"] == [
             %{
               "node_id" => "classify-change",
               "display_name" => "classify-change",
               "required_result" => "success"
             }
           ]

    assert workflow =~ "  merge-blocking-crosswake-ci:"
    assert workflow =~ "    name: Crosswake CI"
    assert workflow =~ "    if: always()"
  end

  @tag :ci_parity
  @tag :generated_contracts
  test "generated and browser owners invoke shared non-staging repository stages" do
    stage_manifest = decode!("script/repository_verification_stages.json")
    leaf_manifest = decode!(@ci_manifest_path)
    workflow = File.read!(@ci_workflow_path)

    for stage <- stage_manifest["stages"], owner <- stage["ci_owners"] do
      assert owner["command"] == "script/verify_repository.sh --stage #{stage["stage_id"]}"
      assert workflow =~ owner["command"]
    end

    guard =
      Enum.find(leaf_manifest["proof_leaves"], &(&1["leaf_id"] == "guard-02-generate-and-diff"))

    e2e = Enum.find(leaf_manifest["proof_leaves"], &(&1["leaf_id"] == "e2e-proof"))
    route_tour = Enum.find(leaf_manifest["proof_leaves"], &(&1["leaf_id"] == "route-tour-proof"))

    assert guard["remediation_command"] ==
             "script/verify_repository.sh --stage repository-cleanliness"

    assert e2e["remediation_command"] == "script/verify_repository.sh --stage browser-proof"

    assert route_tour["remediation_command"] ==
             "script/verify_repository.sh --stage browser-proof"

    refute workflow =~ "git add -A"
    refute workflow =~ "git diff --cached --exit-code"
  end

  @tag :ci_parity
  @tag :generated_contracts
  test "documentation owner checks generated projections without write or staging authority" do
    manifest = decode!(@ci_manifest_path)
    workflow = File.read!(@ci_workflow_path)

    [_, documentation_job] =
      Regex.run(
        ~r/^  documentation-contracts:\n(?<body>.*?)(?=^  brand-structural:)/ms,
        workflow
      )

    assert documentation_job =~ "mix crosswake.docs.sync --check"
    assert documentation_job =~ "test/crosswake/capability_map/capability_map_test.exs"
    assert documentation_job =~ "test/crosswake/support_matrix/renderer_test.exs"
    refute documentation_job =~ ~r/^\s*mix crosswake\.docs\.sync\s*$/m
    refute documentation_job =~ ~r/\bgit add\b|git diff --cached/

    documentation_leaf =
      Enum.find(manifest["proof_leaves"], &(&1["leaf_id"] == "documentation-contracts"))

    assert documentation_leaf["remediation_command"] ==
             "mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && mix test test/crosswake/guides test/crosswake/capability_map/capability_map_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs"
  end

  @tag :quality_gate
  test "recurring repository quality gate is credential-free and purpose-led" do
    gate = File.read!(@quality_gate_path)

    for command <- [
          "script/verify_repository.sh --self-test",
          "node --test test/js/repository_verification.test.mjs",
          "node --test test/js/playwright_repository_mode.test.mjs",
          "mix test test/crosswake/proof/phase166_repository_quality_test.exs",
          "python3 script/check_ci_leaf_manifest.py --self-test",
          "script/check_phase165_efficient_ci.sh",
          "actionlint .github/workflows/crosswake-ci.yml"
        ] do
      assert gate =~ command
    end

    assert gate =~ ~s|"repository-runner-contract"|
    assert gate =~ ~s|"browser-determinism-contract"|
    assert gate =~ ~s|"repository-quality-contracts"|
    assert gate =~ ~s|"ci-authority-contract"|
    assert gate =~ "PASS clean-checkout-engineering-quality"

    refute gate =~ "register_required_checks.sh"
    refute gate =~ "--apply"
    refute gate =~ "git clean"
    refute gate =~ "git add"
    refute gate =~ "capture-evidence"
    refute gate =~ "script/verify_repository.sh --all"
    refute gate =~ "PHASE-166 section="
  end

  defp decode!(path), do: path |> File.read!() |> Jason.decode!()

  defp valid_policy?(policy),
    do: Map.keys(policy) |> Enum.sort() == Enum.sort(@allowed_policy_keys)

  defp valid_generated_contract?(record) do
    Map.keys(record) |> Enum.sort() ==
      ~w(canonical_source output_paths regeneration_argv remediation_command) and
      is_binary(record["canonical_source"]) and record["canonical_source"] != "" and
      is_list(record["regeneration_argv"]) and record["regeneration_argv"] != [] and
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
