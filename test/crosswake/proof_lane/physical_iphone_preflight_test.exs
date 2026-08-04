defmodule Crosswake.ProofLane.PhysicalIphonePreflightTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.PhysicalIphonePreflight

  test "preflight is ready only after every closed prerequisite succeeds in order" do
    parent = self()

    assert {:ready, contract} =
             PhysicalIphonePreflight.check(
               inventory: [eligible_row()],
               config: proof_lane_config(),
               generated_lane: callback(parent, :generated_lane),
               destination: callback(parent, :destination, {:ok, :physical_iphone}),
               signing: callback(parent, :signing),
               host: callback(parent, :host),
               fixture_adapter: callback(parent, :fixture_adapter),
               media: callback(parent, :media),
               replay: callback(parent, :replay),
               rejection_conflict: callback(parent, :rejection_conflict),
               scoped_session: callback(parent, :scoped_session),
               feature_controls: callback(parent, :feature_controls),
               destination_parent: callback(parent, :destination_parent)
             )

    assert contract.device_class == :physical_iphone

    assert_receive {:preflight, :generated_lane}
    assert_receive {:preflight, :destination}
    assert_receive {:preflight, :signing}
    assert_receive {:preflight, :host}
    assert_receive {:preflight, :fixture_adapter}
    assert_receive {:preflight, :media}
    assert_receive {:preflight, :replay}
    assert_receive {:preflight, :rejection_conflict}
    assert_receive {:preflight, :scoped_session}
    assert_receive {:preflight, :feature_controls}
    assert_receive {:preflight, :destination_parent}
  end

  test "empty inventory blocks without calling a downstream callback" do
    refute_called = fn -> flunk("a blocked inventory must not call downstream callbacks") end

    assert {:blocked, "PI-PREFLIGHT-INVENTORY"} =
             PhysicalIphonePreflight.check(inventory: [], generated_lane: refute_called)
  end

  test "simulators, malformed callbacks, and exceptions collapse to stable non-echoing blocks" do
    secret = "device-id-private-canary"

    for {name, callback, rule} <- [
          {:destination, fn -> {:ok, :simulator} end, "PI-PREFLIGHT-DESTINATION"},
          {:host, fn -> {:ok, secret} end, "PI-PREFLIGHT-HOST"},
          {:media, fn -> raise secret end, "PI-PREFLIGHT-MEDIA"}
        ] do
      options = ready_options() |> Keyword.put(name, callback)

      assert {:blocked, ^rule} = PhysicalIphonePreflight.check(options)
      refute inspect(PhysicalIphonePreflight.check(options)) =~ secret
    end
  end

  defp ready_options do
    [
      inventory: [eligible_row()],
      config: proof_lane_config(),
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

  defp callback(parent, name, result \\ :ok),
    do: fn ->
      send(parent, {:preflight, name})
      result
    end

  defp proof_lane_config do
    %{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: "/tmp/crosswake/native/ios"
    }
  end

  defp eligible_row do
    confirmed = fn value -> %{status: :confirmed_sanitized, value: value} end

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
  end
end
