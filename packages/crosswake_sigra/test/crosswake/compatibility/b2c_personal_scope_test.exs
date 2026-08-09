defmodule Crosswake.Compatibility.B2CPersonalScopeTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Sigra
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Manifest.Types.RouteEntry

  test "a personal Sigra session is valid without inventing an organization" do
    assert {:ok, lane} =
             Contracts.new_session_authority_lane(%{
               session_ref: "session:opaque",
               subject_ref: "subject:opaque",
               state: :active,
               assurance_level: :password,
               authn_methods: [:password, :magic_link, :oauth_google],
               authenticated_at: "2026-08-04T12:00:00Z",
               last_seen_at: "2026-08-04T12:01:00Z",
               idle_expires_at: "2026-08-04T13:00:00Z",
               absolute_expires_at: "2026-08-05T12:00:00Z",
               session_version: 1,
               as_of: "2026-08-04T12:01:00Z"
             })

    assert lane.org_id == nil

    assert {:ok, context} =
             Contracts.new_auth_context(%{session_authority_lane: lane})

    assert context.org_id == nil

    route = %RouteEntry{
      id: "personal-study",
      path: "/study",
      runtime: :offline_island,
      offline: :local_first,
      entry: :internal_only,
      auth_min_level: :password,
      auth_posture: :strict_recent
    }

    assert :allow = Sigra.replay_decision(route, context)
  end

  test "a missing, expired, or revoked personal session still fails closed" do
    route = %RouteEntry{
      id: "personal-study",
      path: "/study",
      runtime: :offline_island,
      offline: :local_first,
      entry: :internal_only,
      auth_min_level: :password,
      auth_posture: :strict_recent
    }

    assert {:deny, :sigra_denied} = Sigra.replay_decision(route, nil)

    assert {:ok, revoked_lane} =
             Contracts.new_session_authority_lane(%{
               session_ref: "session:opaque",
               subject_ref: "subject:opaque",
               state: :revoked,
               assurance_level: :password,
               authn_methods: [:oauth_google],
               authenticated_at: "2026-08-04T12:00:00Z",
               last_seen_at: "2026-08-04T12:01:00Z",
               idle_expires_at: "2026-08-04T13:00:00Z",
               absolute_expires_at: "2026-08-05T12:00:00Z",
               session_version: 2,
               revoked_at: "2026-08-04T12:02:00Z",
               as_of: "2026-08-04T12:02:00Z"
             })

    assert {:ok, revoked_context} =
             Contracts.new_auth_context(%{session_authority_lane: revoked_lane})

    assert {:deny, :sigra_denied} = Sigra.replay_decision(route, revoked_context)
  end
end
