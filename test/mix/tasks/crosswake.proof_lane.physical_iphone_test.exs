defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone

  test "run JSON is exact and a blocked command does not invoke its runner" do
    parent = self()

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-PREFLIGHT-INVENTORY"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               adopter_handoff: fn -> {:ok, %{source: :adopter, topology: %{status: :ready}}} end,
               runner: fn _ -> send(parent, :runner) end
             )

    refute_received :runner
  end

  test "unknown flags are rejected" do
    assert {:error, "PI-COMMAND-OPTIONS"} = PhysicalIphone.run_with(["--unknown"], [])
  end

  test "readiness JSON returns all stable prerequisite categories without running reports" do
    assert {:readiness, %{outcome: "blocked", checks: checks}} =
             PhysicalIphone.run_with(["--readiness", "--json"], inventory: [])

    assert Enum.map(checks, & &1.id) == [
             "PI-PREFLIGHT-ADOPTER-HANDOFF",
             "PI-PREFLIGHT-INVENTORY",
             "PI-PREFLIGHT-CONFIG",
             "PI-PREFLIGHT-GENERATED-LANE",
             "PI-PREFLIGHT-DESTINATION",
             "PI-PREFLIGHT-SIGNING",
             "PI-PREFLIGHT-HOST",
             "PI-PREFLIGHT-FIXTURE",
             "PI-PREFLIGHT-MEDIA",
             "PI-PREFLIGHT-REPLAY",
             "PI-PREFLIGHT-REJECTION-CONFLICT",
             "PI-PREFLIGHT-SCOPE",
             "PI-PREFLIGHT-FEATURE-CONTROLS",
             "PI-PREFLIGHT-DESTINATION-PARENT"
           ]

    assert Enum.all?(checks, &(&1.state == "blocked"))
  end

  test "a complete owner-disjoint report joins only after ready preflight" do
    parent = self()

    assert {:passed, %{device_class: "physical_iphone", assertions: assertions}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [
                   device_report: fn contract ->
                     send(parent, {:device, contract})
                     device_report()
                   end,
                   backend_report: fn _ -> backend_report() end,
                   cleanup_run: fn ->
                     send(parent, :cleanup_run)
                     :ok
                   end
                 ]
             )

    assert_receive {:device, %{assertion_ids: assertion_ids}}

    assert assertion_ids == [
             "PI-PACK-INSTALL-AUDIO",
             "PI-OFFLINE-SELECTED-PERSISTENCE",
             "PI-OFFLINE-FREE-FORM-PERSISTENCE",
             "PI-RELAUNCH-PERSISTENCE",
             "PI-RECOVERY-RETAINED",
             "PI-RECOVERY-REJECTION",
             "PI-RECOVERY-CONFLICT",
             "PI-LOGOUT-FENCE",
             "PI-ACCOUNT-SWITCH-FENCE",
             "PI-ENTRY-DISABLEMENT",
             "PI-REPLAY-DISABLEMENT",
             "PI-RECOVERY-REJECTION-AUTHORITY",
             "PI-RECOVERY-CONFLICT-AUTHORITY",
             "PI-LOGOUT-FENCE-AUTHORITY",
             "PI-ACCOUNT-SWITCH-FENCE-AUTHORITY",
             "PI-ENTRY-DISABLEMENT-AUTHORITY",
             "PI-REPLAY-DISABLEMENT-AUTHORITY",
             "PI-EXACTLY-ONCE-EMPTY-OUTBOX",
             "PI-REDACTED-PROMOTION"
           ]

    assert Crosswake.ProofLane.PhysicalIphoneContract.schema_version() == 2
    assert Enum.all?(assertions, &(&1.outcome == :passed))
    refute_received {:device, _}
    assert_receive :cleanup_run
  end

  test "a device report cannot satisfy backend assertions" do
    reports = device_report()

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-OWNER"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [device_report: fn _ -> reports end, backend_report: fn _ -> reports end]
             )
  end

  test "runner cleans up after malformed reports and later join exits" do
    parent = self()

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-ENVELOPE"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [
                   device_report: fn _ -> "not-a-report" end,
                   cleanup_run: fn ->
                     send(parent, :malformed_device_cleanup)
                     :ok
                   end
                 ]
             )

    assert_receive :malformed_device_cleanup

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-ENVELOPE"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [
                   device_report: fn _ -> device_report() end,
                   backend_report: fn _ -> "not-a-report" end,
                   cleanup_run: fn ->
                     send(parent, :malformed_backend_cleanup)
                     :ok
                   end
                 ]
             )

    assert_receive :malformed_backend_cleanup

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-OWNER"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [
                   device_report: fn _ -> device_report() end,
                   backend_report: fn _ -> device_report() end,
                   cleanup_run: fn ->
                     send(parent, :join_cleanup)
                     :ok
                   end
                 ]
             )

    assert_receive :join_cleanup
  end

  test "runner fails closed when its required cleanup callback fails" do
    assert {:blocked, %{outcome: "blocked", rule_id: "PI-HOST-CLEANUP"}} =
             PhysicalIphone.run_with(
               ["--run", "--json"],
               ready_options() ++
                 [
                   device_report: fn _ -> device_report() end,
                   backend_report: fn _ -> backend_report() end,
                   cleanup_run: fn -> {:error, :unavailable} end
                 ]
             )
  end

  test "canonical owner-free producer envelopes parse only in their trusted slots" do
    device = canonical_report(:device_local)
    backend = canonical_report(:backend_authority)

    assert {:ok, device_entries} =
             PhysicalIphone.parse_report(Jason.encode!(device), :device_local)

    assert {:ok, backend_entries} =
             PhysicalIphone.parse_report(Jason.encode!(backend), :backend_authority)

    assert {:ok, _candidate} = PhysicalIphone.join_report_entries(device_entries, backend_entries)

    assert {:error, "PI-REPORT-OWNER"} =
             PhysicalIphone.parse_report(Jason.encode!(device), :backend_authority)

    assert {:error, "PI-REPORT-ENVELOPE"} =
             PhysicalIphone.parse_report(
               Jason.encode!(Map.put(device, "owner", "device_local")),
               :device_local
             )
  end

  @local_mode_cases_modes [
    {:preflight_only, ["--preflight-only", "--json"]},
    {:readiness, ["--readiness", "--json"]},
    {:run, ["--run", "--json"]}
  ]

  test "a local-loopback ios_host declaration blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and never calls device_report" do
    parent = self()
    options = Keyword.put(ready_options(), :ios_host, local_declaration())

    results = run_all_modes(options, parent)
    assert Enum.map(results, &elem(&1, 0)) == [:preflight_only, :readiness, :run]
    assert_all_blocked_by_config(results)
    refute_received :device_report_called
  end

  test "real local-mode gen.shell output under a production declaration blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and never calls device_report" do
    parent = self()
    project = generate_shell(local_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    assert File.regular?(
             Path.join(project, "native/ios/crosswake_shell/CrosswakeShell/Info.plist")
           )

    assert File.regular?(
             Path.join(project, "native/ios/crosswake_shell/Fixtures/route_activation.json")
           )

    results = run_all_modes(host_options(project, production_declaration()), parent)
    assert Enum.map(results, &elem(&1, 0)) == [:preflight_only, :readiness, :run]
    assert_all_blocked_by_config(results)
    refute_received :device_report_called
  end

  test "a local-loopback refusal carries the generator refusal text as its cause" do
    parent = self()
    refusal = Crosswake.ProofLane.Generator.local_mode_refusal()
    project = generate_shell(local_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    for options <- [
          Keyword.put(ready_options(), :ios_host, local_declaration()),
          host_options(project, production_declaration())
        ],
        {_mode, result} <- run_all_modes(options, parent) do
      {_kind, map} = result
      assert %{cause: ^refusal} = map
    end
  end

  test "an Info.plist replaced by a directory blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and a plain cause" do
    parent = self()
    project = generate_shell(production_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    plist = Path.join(project, "native/ios/crosswake_shell/CrosswakeShell/Info.plist")
    File.rm!(plist)
    File.mkdir_p!(plist)

    results = run_all_modes(host_options(project, production_declaration()), parent)
    assert_all_blocked_by_config(results)
    assert_plain_cause(results, "CrosswakeShell/Info.plist", project)
    refute_received :device_report_called
  end

  test "a missing Info.plist in an existing shell folder blocks preflight-only, readiness and run" do
    parent = self()
    project = generate_shell(production_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    File.rm!(Path.join(project, "native/ios/crosswake_shell/CrosswakeShell/Info.plist"))

    results = run_all_modes(host_options(project, production_declaration()), parent)
    assert_all_blocked_by_config(results)
    assert_plain_cause(results, "CrosswakeShell/Info.plist", project)
    refute_received :device_report_called
  end

  test "a malformed route_activation.json blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and a plain cause" do
    parent = self()
    project = generate_shell(production_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    File.write!(
      Path.join(project, "native/ios/crosswake_shell/Fixtures/route_activation.json"),
      "{not json"
    )

    results = run_all_modes(host_options(project, production_declaration()), parent)
    assert_all_blocked_by_config(results)
    assert_plain_cause(results, "Fixtures/route_activation.json", project)
    refute_received :device_report_called
  end

  @unusable_activation_bodies [
    {"null", "null"},
    {"empty list", "[]"},
    {"empty object", "{}"},
    {"numeric origin", ~s({"origin": 5})},
    {"list origin", ~s({"origin": ["http://127.0.0.1:4790"]})},
    {"origin that is not a url", ~s({"origin": "not a url"})}
  ]

  for {label, body} <- @unusable_activation_bodies do
    test "a route_activation.json with no usable origin (#{label}) blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG" do
      parent = self()
      project = generate_shell(production_declaration())
      on_exit(fn -> File.rm_rf!(project) end)

      File.write!(
        Path.join(project, "native/ios/crosswake_shell/Fixtures/route_activation.json"),
        unquote(body)
      )

      results = run_all_modes(host_options(project, production_declaration()), parent)
      assert_all_blocked_by_config(results)
      assert_plain_cause(results, "Fixtures/route_activation.json", project)
      refute_received :device_report_called
    end
  end

  test "a production shell with no route_activation.json still passes preflight-only, readiness and run" do
    parent = self()
    project = generate_shell(production_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    File.rm!(Path.join(project, "native/ios/crosswake_shell/Fixtures/route_activation.json"))

    options = host_options(project, production_declaration())

    assert {:ready, _} = PhysicalIphone.run_with(["--preflight-only", "--json"], options)

    assert {:readiness, %{outcome: "ready"}} =
             PhysicalIphone.run_with(["--readiness", "--json"], options)

    refute_received :device_report_called

    assert {:passed, _} =
             PhysicalIphone.run_with(["--run", "--json"], with_reports(options, parent))

    assert_received :device_report_called
  end

  test "a production declaration over production gen.shell output still passes preflight-only, readiness and run" do
    parent = self()
    project = generate_shell(production_declaration())
    on_exit(fn -> File.rm_rf!(project) end)

    assert File.regular?(
             Path.join(project, "native/ios/crosswake_shell/Fixtures/route_activation.json")
           )

    options = host_options(project, production_declaration())

    assert {:ready, _} = PhysicalIphone.run_with(["--preflight-only", "--json"], options)

    assert {:readiness, %{outcome: "ready"}} =
             PhysicalIphone.run_with(["--readiness", "--json"], options)

    refute_received :device_report_called

    assert {:passed, _} =
             PhysicalIphone.run_with(["--run", "--json"], with_reports(options, parent))

    assert_received :device_report_called
  end

  defp local_declaration do
    [
      router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
      origin: "http://127.0.0.1:4790",
      origin_mode: :local_loopback,
      entry_route_id: "study-session",
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: [mode: :automatic, team_id: "ABCDE12345"]
    ]
  end

  defp production_declaration do
    Keyword.merge(local_declaration(), origin: "https://study.crosswake.test")
    |> Keyword.delete(:origin_mode)
  end

  defp generate_shell(declaration) do
    project =
      Path.join(System.tmp_dir!(), "crosswake-pi-#{System.unique_integer([:positive])}")

    File.mkdir_p!(project)
    previous = Application.fetch_env(:crosswake, :ios_host)
    Application.put_env(:crosswake, :ios_host, declaration)
    Mix.Task.reenable("crosswake.gen.shell")

    try do
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Tasks.Crosswake.Gen.Shell.run(["ios", "--target", project])
      end)
    after
      case previous do
        {:ok, value} -> Application.put_env(:crosswake, :ios_host, value)
        :error -> Application.delete_env(:crosswake, :ios_host)
      end

      Mix.Task.reenable("crosswake.gen.shell")
    end

    project
  end

  defp host_options(project, declaration) do
    options = Keyword.put(ready_options(), :ios_host, declaration)

    config =
      Map.put(Keyword.fetch!(options, :config), :ios_shell_root, Path.join(project, "native/ios"))

    Keyword.put(options, :config, config)
  end

  defp with_reports(options, parent) do
    options
    |> Keyword.put(:device_report, fn _contract ->
      send(parent, :device_report_called)
      device_report()
    end)
    |> Keyword.put(:backend_report, fn _ -> backend_report() end)
    |> Keyword.put(:cleanup_run, fn -> :ok end)
  end

  defp run_all_modes(options, parent) do
    options = with_reports(options, parent)

    for {mode, args} <- @local_mode_cases_modes do
      {mode, PhysicalIphone.run_with(args, options)}
    end
  end

  defp assert_plain_cause(results, file_name, project) do
    for {_mode, {_kind, map}} <- results do
      assert is_binary(map.cause)
      assert String.contains?(map.cause, file_name)
      refute String.contains?(map.cause, project)
    end
  end

  defp assert_all_blocked_by_config(results) do
    for {mode, result} <- results do
      case {mode, result} do
        {:readiness, {:readiness, %{outcome: "blocked", checks: checks}}} ->
          config = Enum.find(checks, &(&1.id == "PI-PREFLIGHT-CONFIG"))
          assert config.state == "blocked"
          others = List.delete(checks, config)
          assert others != []
          assert Enum.map(others, & &1.state) == List.duplicate("ready", length(others))

        {_mode, {:blocked, %{outcome: "blocked", rule_id: "PI-PREFLIGHT-CONFIG"}}} ->
          :ok

        other ->
          flunk("mode #{mode} was not blocked by PI-PREFLIGHT-CONFIG: #{inspect(other)}")
      end
    end
  end

  describe "exit_status_for/1 and handle_result/1 (CW-REQ-B)" do
    test "a validated, complete, correctly-owned, correctly-ordered report with a non-passing outcome exits 1 and classifies as refuted" do
      parent = self()

      refuted_device_report =
        device_report() |> List.update_at(0, &Map.put(&1, :outcome, :blocked))

      assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-OUTCOME"} = result} =
               PhysicalIphone.run_with(
                 ["--run", "--json"],
                 ready_options() ++
                   [
                     device_report: fn _ -> refuted_device_report end,
                     backend_report: fn _ -> backend_report() end,
                     cleanup_run: fn ->
                       send(parent, :cleanup_run)
                       :ok
                     end
                   ]
               )

      assert PhysicalIphone.exit_status_for(result.rule_id) == 1

      assert {1, json} = PhysicalIphone.handle_result({:blocked, result})
      assert json.exit_classification == "refuted"
      assert json.rule_id == "PI-REPORT-OUTCOME"
    end

    test "a failure where no validated report was produced exits 2 and classifies as could-not-run" do
      assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-ENVELOPE"} = result} =
               PhysicalIphone.run_with(
                 ["--run", "--json"],
                 ready_options() ++ [device_report: fn _ -> "not-a-report" end]
               )

      assert PhysicalIphone.exit_status_for(result.rule_id) == 2

      assert {2, json} = PhysicalIphone.handle_result({:blocked, result})
      assert json.exit_classification == "could_not_run"
      assert json.rule_id == "PI-REPORT-ENVELOPE"
    end

    test "a blocked readiness result exits 2 and classifies as could-not-run, because readiness reports a precondition" do
      assert {:readiness, %{outcome: "blocked"} = result} =
               PhysicalIphone.run_with(["--readiness", "--json"], inventory: [])

      assert {2, json} = PhysicalIphone.handle_result({:readiness, result})
      assert json.exit_classification == "could_not_run"
    end

    test "a fully passing run produces no halt status" do
      assert {:passed, candidate} =
               PhysicalIphone.run_with(
                 ["--run", "--json"],
                 ready_options() ++
                   [
                     device_report: fn _ -> device_report() end,
                     backend_report: fn _ -> backend_report() end,
                     cleanup_run: fn -> :ok end
                   ]
               )

      assert {nil, ^candidate} = PhysicalIphone.handle_result({:passed, candidate})
      refute Map.has_key?(candidate, :exit_classification)
    end

    test "a rule id the classifier does not recognise falls through the explicit catch-all to could-not-run" do
      assert PhysicalIphone.exit_status_for("PI-SOME-FUTURE-RULE-NOT-YET-CLASSIFIED") == 2
    end

    test "a non-binary rule id degrades to could-not-run rather than raising, per the fail-closed contract" do
      assert PhysicalIphone.exit_status_for(:some_future_atom_rule) == 2
      assert PhysicalIphone.exit_status_for(nil) == 2
      assert PhysicalIphone.exit_status_for(%{unexpected: :shape}) == 2
    end
  end

  describe "join_reports/3 still enforces ordinal position (174-REVIEW WR-01)" do
    test "a complete, correctly-owned report whose assertions are out of contract order is rejected as incomplete" do
      # Guards the 174-03 change that narrowed the completeness comparison from
      # [:id, :owner, :outcome] to [:id, :owner]. That change un-shadowed the
      # PI-REPORT-OUTCOME branch, and must NOT have cost the contract its ordinal-position
      # requirement: PhysicalIphoneContract is a closed, ORDERED vocabulary. Reversing the
      # device half leaves the id/owner SET identical and only the ORDER wrong, so this
      # report passes any set-equality check and fails only a positional one.
      reversed_device_report = Enum.reverse(device_report())

      assert Enum.sort_by(reversed_device_report, & &1.id) ==
               Enum.sort_by(device_report(), & &1.id),
             "precondition: reversal must change only order, never the member set"

      assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-COMPLETE"}} =
               PhysicalIphone.run_with(
                 ["--run", "--json"],
                 ready_options() ++
                   [
                     device_report: fn _ -> reversed_device_report end,
                     backend_report: fn _ -> backend_report() end,
                     cleanup_run: fn -> :ok end
                   ]
               )
    end
  end

  defp device_report do
    Crosswake.ProofLane.PhysicalIphoneContract.assertions()
    |> Enum.filter(&(&1.owner == :device_local))
    |> Enum.map(&Map.put(&1, :outcome, :passed))
  end

  defp backend_report do
    Crosswake.ProofLane.PhysicalIphoneContract.assertions()
    |> Enum.filter(&(&1.owner == :backend_authority))
    |> Enum.map(&Map.put(&1, :outcome, :passed))
  end

  defp canonical_report(owner) do
    %{
      "schema_version" => Crosswake.ProofLane.PhysicalIphoneContract.schema_version(),
      "device_class" => "physical_iphone",
      "assertions" =>
        Crosswake.ProofLane.PhysicalIphoneContract.assertions()
        |> Enum.filter(&(&1.owner == owner))
        |> Enum.map(&%{"id" => &1.id, "outcome" => "passed"})
    }
  end

  defp ready_options do
    confirmed = fn value -> %{status: :confirmed_sanitized, value: value} end

    [
      ios_host: nil,
      adopter_handoff: fn -> {:ok, %{source: :adopter, topology: %{status: :ready}}} end,
      inventory: [
        [
          route_id: "route-0123456789abcdef",
          path_pattern: "/study/session/:id",
          runtime_owner: confirmed.(:offline_island),
          offline_posture: confirmed.(:local_first),
          mutation_categories: confirmed.([:answer_submission]),
          staleness_class: confirmed.(:not_cacheable),
          auth: confirmed.(:authenticated),
          recent_auth: confirmed.(:not_required),
          scope_posture:
            confirmed.(%{
              scope: :opaque_partitioned,
              logout: :stops_replay,
              account_switch: :stops_replay
            }),
          media_requirement:
            confirmed.(%{
              requirement: :required,
              size_band: :small,
              codec_family: :mp3,
              integrity: :verified
            }),
          fallbacks:
            confirmed.(%{
              online: :serve,
              offline: :queue_local,
              denied: :block,
              corrupt_pack: :block,
              disabled: :retain_and_block
            }),
          disablement: confirmed.(%{entry: :server_enforced, replay: :server_reauthorized}),
          queued_data_retention: confirmed.(:retain_until_resolution)
        ]
      ],
      config: %{
        route_id: "route-0123456789abcdef",
        route_path: "/study/:id",
        indexed_db_database: "proof_lane",
        indexed_db_store: "mutations",
        mutation_id_path: "client_mutation_id",
        sync_path: "/study/sync",
        evidence_path: "/_proof/evidence",
        router: CrosswakeWeb.Router,
        ios_shell_root: "/tmp/crosswake/native/ios"
      },
      generated_lane: fn -> :ok end,
      destination: fn -> {:ok, :physical_iphone} end,
      signing: fn -> :ok end,
      host: fn -> :ok end,
      fixture_adapter: fn -> :ok end,
      media: fn -> :ok end,
      replay: fn -> :ok end,
      rejection_conflict: fn -> :ok end,
      scoped_session: fn -> :ok end,
      feature_controls: fn -> :ok end,
      destination_parent: fn -> :ok end
    ]
  end
end
