defmodule Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone

  test "preflight-only JSON is exact and a blocked command does not invoke its runner" do
    parent = self()

    assert {:blocked, %{outcome: "blocked", rule_id: "PI-PREFLIGHT-INVENTORY"}} =
             PhysicalIphone.run_with(["--preflight-only", "--json"],
               runner: fn _ -> send(parent, :runner) end
             )

    refute_received :runner
  end

  test "unknown flags are rejected" do
    assert {:error, "PI-COMMAND-OPTIONS"} = PhysicalIphone.run_with(["--unknown"], [])
  end

  test "the runner is invoked exactly once only after a ready preflight" do
    parent = self()

    assert {:ready, %{device_class: :physical_iphone}} =
             PhysicalIphone.run_with(
               ["--preflight-only", "--json"],
               ready_options() ++ [runner: fn contract -> send(parent, {:runner, contract}) end]
             )

    assert_receive {:runner, %{assertion_ids: assertion_ids}}
    assert is_list(assertion_ids)
    refute_received {:runner, _}
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
