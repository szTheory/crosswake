defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone

  test "run JSON is exact and a blocked command does not invoke its runner" do
    parent = self()

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-PREFLIGHT-INVENTORY"}} =
             PhysicalIphone.run_with(["--run", "--json"],
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
    assert length(assertion_ids) == 10
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
      "schema_version" => 1,
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
