defmodule Crosswake.Adoption.NavigationTopologyTest do
  use ExUnit.Case, async: true

  alias Crosswake.Adoption.NavigationTopology

  test "renders empty inventory as an explicit unknown blocking artifact" do
    assert {:ok, json} = NavigationTopology.render([])
    assert %{"status" => "unknown_blocking", "entries" => []} = Jason.decode!(json)
    assert {:blocked, %{reason: :unknown_blocking}} = NavigationTopology.promotion_status([])
  end

  test "compiles one opaque root from an eligible sanitized row" do
    assert {:ok, topology} =
             NavigationTopology.compile(%{rows: [valid_row()], entries: [root_entry()]})

    assert topology.status == :ready
    assert [%{route_id: "route-0123456789abcdef", presentation: :root}] = topology.entries
  end

  test "rejects malformed topology without echoing supplied values" do
    secret = "topology-private-canary"
    invalid = Map.put(root_entry(), :parent_route_id, secret)

    assert {:error, error} =
             NavigationTopology.compile(%{rows: [valid_row()], entries: [invalid]})

    assert Exception.message(error) =~ "NT-INVALID_ENTRY"
    refute Exception.message(error) =~ secret
  end

  test "does not promote incomplete route inventory" do
    incomplete = Keyword.put(valid_row(), :media_requirement, %{status: :unknown_blocking})

    assert {:ok, %{status: :unknown_blocking, entries: []}} =
             NavigationTopology.compile(%{rows: [incomplete], entries: [root_entry()]})
  end

  test "rejects duplicate roots, missing parents, cross tab parents, and cycles" do
    child =
      root_entry(
        route_id: "route-fedcba9876543210",
        presentation: :push,
        parent_route_id: "route-0123456789abcdef"
      )

    other_tab_child = %{child | root_tab_id: "tab-fedcba9876543210"}
    missing_parent = %{child | parent_route_id: "route-aaaaaaaaaaaaaaaa"}

    for entries <- [
          [root_entry(), root_entry()],
          [root_entry(), missing_parent],
          [root_entry(), other_tab_child]
        ] do
      assert {:error, error} =
               NavigationTopology.compile(%{rows: [valid_row(), second_row()], entries: entries})

      assert Exception.message(error) =~ "NT-"
    end

    cycle_one =
      root_entry(
        route_id: "route-fedcba9876543210",
        presentation: :push,
        parent_route_id: "route-aaaaaaaaaaaaaaaa"
      )

    cycle_two =
      root_entry(
        route_id: "route-aaaaaaaaaaaaaaaa",
        presentation: :push,
        parent_route_id: "route-fedcba9876543210"
      )

    assert {:error, error} =
             NavigationTopology.compile(%{
               rows: [valid_row(), second_row(), third_row()],
               entries: [root_entry(), cycle_one, cycle_two]
             })

    assert Exception.message(error) =~ "NT-INVALID_GRAPH"
  end

  defp root_entry(overrides \\ []) do
    Keyword.merge(
      [
        route_id: "route-0123456789abcdef",
        root_tab_id: "tab-0123456789abcdef",
        presentation: :root,
        parent_route_id: nil,
        deep_link_posture: :deny,
        restoration_posture: :deny
      ],
      overrides
    )
    |> Map.new()
  end

  defp valid_row(overrides \\ []) do
    base = [
      route_id: "route-0123456789abcdef",
      path_pattern: "/study/session/:id",
      runtime_owner: confirmed(:offline_island),
      offline_posture: confirmed(:local_first),
      mutation_categories: confirmed([:answer_submission]),
      staleness_class: confirmed(:not_cacheable),
      auth: confirmed(:authenticated),
      recent_auth: confirmed(:not_required),
      scope_posture:
        confirmed(%{
          scope: :opaque_partitioned,
          logout: :stops_replay,
          account_switch: :stops_replay
        }),
      media_requirement:
        confirmed(%{
          requirement: :required,
          size_band: :small,
          codec_family: :aac,
          integrity: :verified
        }),
      fallbacks:
        confirmed(%{
          online: :serve,
          offline: :queue_local,
          denied: :block,
          corrupt_pack: :block,
          disabled: :retain_and_block
        }),
      disablement: confirmed(%{entry: :server_enforced, replay: :server_reauthorized}),
      queued_data_retention: confirmed(:retain_until_resolution)
    ]

    Keyword.merge(base, overrides)
  end

  defp second_row,
    do: valid_row(route_id: "route-fedcba9876543210", path_pattern: "/learning/path/:id")

  defp third_row,
    do: valid_row(route_id: "route-aaaaaaaaaaaaaaaa", path_pattern: "/dashboard/history/:id")

  defp confirmed(value), do: %{status: :confirmed_sanitized, value: value}
end
