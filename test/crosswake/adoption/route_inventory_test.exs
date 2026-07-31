defmodule Crosswake.Adoption.RouteInventoryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Adoption.RouteInventory

  test "validates a synthetic sanitized row and preserves explicit route-local posture" do
    assert RouteInventory.status_values() == [
             :confirmed_sanitized,
             :known_default,
             :unknown_blocking,
             :not_applicable
           ]

    assert {:ok, row} = RouteInventory.validate(valid_row())
    assert row.route_id == "route-opaque-study"
    assert row.path_pattern == "/study/session/:id"
    assert row.runtime_owner.value == :offline_island
    assert row.media_requirement.value.codec_family == :aac
    assert {:eligible, ^row} = RouteInventory.promotion_status(row)
  end

  test "records unknown blocking posture but blocks promotion" do
    row = Keyword.put(valid_row(), :media_requirement, %{status: :unknown_blocking})

    assert {:ok, validated} = RouteInventory.validate(row)

    assert {:blocked, %{route_ref: "route-opaque-study", fields: [:media_requirement]}} =
             RouteInventory.promotion_status(validated)
  end

  test "rejects known defaults for every concrete-route safety field before promotion" do
    for field <- safety_fields() do
      supplied_posture = %{status: :known_default, value: :supplied_posture_canary}

      assert {:error, error} =
               RouteInventory.validate(Keyword.put(valid_row(), field, supplied_posture))

      assert_safe_error(error, "RI-SAFETY_STATUS", Atom.to_string(field))
      refute Exception.message(error) =~ "supplied_posture_canary"
    end
  end

  test "defaults-only concrete rows cannot become eligible" do
    defaults_only_row =
      Enum.reduce(safety_fields(), valid_row(), fn field, row ->
        Keyword.put(row, field, %{status: :known_default, value: :synthetic_default})
      end)

    assert {:error, error} = RouteInventory.validate(defaults_only_row)
    assert_safe_error(error, "RI-SAFETY_STATUS", "runtime_owner")
    refute Exception.message(error) =~ "synthetic_default"
  end

  test "rejects incoherent local-mutation posture by invariant axis" do
    cases = [
      runtime_owner: confirmed(:live_view),
      mutation_categories: confirmed([:none]),
      scope_posture: %{status: :not_applicable},
      fallbacks: %{status: :not_applicable},
      disablement: %{status: :not_applicable},
      queued_data_retention: %{status: :not_applicable}
    ]

    for {field, posture} <- cases do
      assert {:error, error} = RouteInventory.validate(Keyword.put(valid_row(), field, posture))
      assert_safe_error(error, "RI-ROUTE_INVARIANT", Atom.to_string(field))
    end
  end

  test "rejects contradictory recent-auth authority in either direction" do
    assert {:error, error} =
             RouteInventory.validate(
               valid_row(auth: confirmed(:recent_auth), recent_auth: confirmed(:not_required))
             )

    assert_safe_error(error, "RI-ROUTE_INVARIANT", "recent_auth")

    assert {:error, error} =
             RouteInventory.validate(
               valid_row(auth: confirmed(:authenticated), recent_auth: confirmed(:required))
             )

    assert_safe_error(error, "RI-ROUTE_INVARIANT", "auth")
  end

  test "promotes a coherent recent-auth local-mutation row" do
    assert {:ok, row} =
             RouteInventory.validate(
               valid_row(auth: confirmed(:recent_auth), recent_auth: confirmed(:required))
             )

    assert {:eligible, ^row} = RouteInventory.promotion_status(row)
  end

  test "rejects missing, blank, nil, unknown, and forbidden fields without echoing rejected input" do
    assert {:error, error} = RouteInventory.validate(Keyword.delete(valid_row(), :auth))
    assert_safe_error(error, "RI-REQUIRED", "auth")

    assert {:error, error} = RouteInventory.validate(Keyword.put(valid_row(), :route_id, ""))
    assert_safe_error(error, "RI-INVALID", "route_id")

    assert {:error, error} = RouteInventory.validate(Keyword.put(valid_row(), :auth, nil))
    assert_safe_error(error, "RI-INVALID", "auth")

    assert {:error, error} = RouteInventory.validate(valid_row() ++ [unknown_key: :value])
    assert_safe_error(error, "RI-UNKNOWN_FIELD", "unknown_key")

    secret = "private-secret-canary"

    assert {:error, error} = RouteInventory.validate(valid_row() ++ [raw_answer: secret])
    assert_safe_error(error, "RI-FORBIDDEN_FIELD", "raw_answer")
    refute Exception.message(error) =~ secret
  end

  test "rejects duplicate route IDs and path patterns without merging adjacent rows" do
    assert {:error, error} =
             RouteInventory.validate_inventory([
               valid_row(),
               valid_row(route_id: "route-opaque-study")
             ])

    assert_safe_error(error, "RI-DUPLICATE_ROUTE_ID", "route_id")

    assert {:error, error} =
             RouteInventory.validate_inventory([
               valid_row(),
               valid_row(route_id: "route-opaque-other", path_pattern: "/study/session/:id")
             ])

    assert_safe_error(error, "RI-DUPLICATE_PATH_PATTERN", "path_pattern")
  end

  test "empty inventories are contract complete but blocked for adopter-instance promotion" do
    assert {:ok, []} = RouteInventory.validate_inventory([])

    assert {:blocked, %{reason: :empty_inventory, fields: []}} =
             RouteInventory.promotion_status([])
  end

  test "keeps declaration order stable when inventory values compare equally" do
    first = valid_row(route_id: "route-opaque-first", path_pattern: "/study/first/:id")
    second = valid_row(route_id: "route-opaque-second", path_pattern: "/study/second/:id")

    assert {:ok, [first_validated, second_validated]} =
             RouteInventory.validate_inventory([first, second])

    assert [first_validated.route_id, second_validated.route_id] == [
             "route-opaque-first",
             "route-opaque-second"
           ]
  end

  test "route-policy map shares the closed vocabulary and keeps the concrete inventory blocked" do
    map = File.read!(".planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md")
    todo = File.read!(".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md")

    for status <- RouteInventory.status_values() do
      assert map =~ Atom.to_string(status)
    end

    for field <- [
          "auth",
          "recent-auth",
          "scope",
          "mutation",
          "media",
          "fallback",
          "disablement",
          "queued-data retention"
        ] do
      assert map =~ field
    end

    assert map =~ "adopter-instance completeness is blocked"
    assert map =~ "web-only"
    assert map =~ "Concrete-route promotion invariants"
    assert map =~ "never supplies a concrete-route safety field"
    assert map =~ "offline_island"
    assert map =~ "retain_until_resolution"
    assert map =~ "auth: recent_auth"
    assert todo =~ "status: open"
  end

  defp valid_row(overrides \\ []) do
    base = [
      route_id: "route-opaque-study",
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

  defp confirmed(value), do: %{status: :confirmed_sanitized, value: value}

  defp safety_fields do
    [
      :runtime_owner,
      :offline_posture,
      :mutation_categories,
      :staleness_class,
      :auth,
      :recent_auth,
      :scope_posture,
      :media_requirement,
      :fallbacks,
      :disablement,
      :queued_data_retention
    ]
  end

  defp assert_safe_error(error, rule_id, field) do
    message = Exception.message(error)
    assert message =~ rule_id
    assert message =~ field
    assert message =~ ~r/route (route-opaque-study|unresolved)/
    assert message =~ "remediation:"
  end
end
