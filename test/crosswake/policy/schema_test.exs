defmodule Crosswake.Policy.SchemaTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Schema
  alias Crosswake.Transfer.Contracts
  alias Crosswake.Manifest.Types

  describe "validate!/1" do
    test "requires both id and runtime" do
      assert_raise NimbleOptions.ValidationError, ~r/required :id option not found/, fn ->
        Schema.validate!(runtime: :live_view)
      end

      assert_raise NimbleOptions.ValidationError, ~r/required :runtime option not found/, fn ->
        Schema.validate!(id: "home")
      end
    end

    test "rejects reserved and unknown runtime values" do
      assert_raise NimbleOptions.ValidationError, ~r/reserved future extension point/, fn ->
        Schema.validate!(id: "camera", runtime: :adapter)
      end

      assert_raise NimbleOptions.ValidationError, ~r/expected one of/, fn ->
        Schema.validate!(id: "camera", runtime: :webview)
      end
    end

    test "accepts explicit cache and island contract identifiers" do
      validated =
        Schema.validate!(
          id: "library",
          runtime: :live_view,
          offline: :cached_read_only,
          entry: :external,
          cache_contract: :lesson_library_v1
        )

      assert validated[:id] == "library"
      assert validated[:runtime] == :live_view
      assert validated[:offline] == :cached_read_only
      assert validated[:entry] == :external
      assert validated[:cache_contract] == "lesson_library_v1"

      validated =
        Schema.validate!(
          id: "study-session",
          runtime: :offline_island,
          offline: :local_first,
          island_contract: "study_session_v1"
        )

      assert validated[:id] == "study-session"
      assert validated[:runtime] == :offline_island
      assert validated[:offline] == :local_first
      assert validated[:entry] == :internal_only
      assert validated[:island_contract] == "study_session_v1"
    end

    test "accepts only the explicit route-entry vocabulary" do
      validated = Schema.validate!(id: "approval", runtime: :live_view, entry: :external)
      assert validated[:entry] == :external

      assert_raise NimbleOptions.ValidationError, ~r/invalid value for :entry option/, fn ->
        Schema.validate!(id: "approval", runtime: :live_view, entry: :ambient)
      end
    end

    test "accepts provider-neutral commerce corridor declarations" do
      validated =
        Schema.validate!(
          id: "paywall",
          runtime: :live_view,
          security: :standard,
          commerce: [corridor: :subscription_default, role: :paywall_entry]
        )

      assert validated[:commerce] == %{corridor: "subscription_default", role: :paywall_entry}
    end

    test "accepts typed versioned pack declarations with semantic metadata" do
      validated =
        Schema.validate!(
          id: "library",
          runtime: :live_view,
          offline: :cached_read_only,
          cache_contract: :lesson_library_v1,
          security: :standard,
          packs: [
            [
              id: :lesson_library,
              version: "1.2.0",
              kind: :content,
              integrity: [algorithm: :sha256, digest: "sha256-abc123"]
            ],
            [id: "pronunciation_audio", version: "2.0.0", kind: :media]
          ]
        )

      assert validated[:packs] == [
               %Crosswake.Offline.ContentPack{
                 id: "lesson_library",
                 version: "1.2.0",
                 kind: :content,
                 integrity: %{algorithm: "sha256", digest: "sha256-abc123"},
                 assets: [],
                 data_payloads: []
               },
               %Crosswake.Offline.ContentPack{
                 id: "pronunciation_audio",
                 version: "2.0.0",
                 kind: :media,
                 integrity: nil,
                 assets: [],
                 data_payloads: []
               }
             ]
    end

    test "rejects pack declarations without a required version" do
      assert_raise NimbleOptions.ValidationError, ~r/version/, fn ->
        Schema.validate!(
          id: "library",
          runtime: :live_view,
          security: :standard,
          packs: [[id: "lesson_library", kind: :content]]
        )
      end
    end

    test "accepts explicit route-local transfer seams with typed semantic metadata" do
      validated =
        Schema.validate!(
          id: "library",
          runtime: :live_view,
          offline: :cached_read_only,
          cache_contract: :lesson_library_v1,
          security: :standard,
          transfers: [
            [
              id: :lesson_import,
              intent: :import,
              source: :native_picker,
              verification: :required,
              media_types: ["application/pdf"]
            ],
            [
              id: "lesson_export",
              intent: :export,
              destination: :user_visible_files,
              verification: :required,
              media_types: ["application/pdf"]
            ]
          ]
        )

      assert validated[:transfers] == [
               %Contracts.Declaration{
                 protocol: "crosswake.transfer",
                 version: "1.0.0",
                 id: "lesson_import",
                 intent: :import,
                 direction: :inbound,
                 source: :native_picker,
                 destination: nil,
                 verification: :required,
                 media_types: ["application/pdf"]
               },
               %Contracts.Declaration{
                 protocol: "crosswake.transfer",
                 version: "1.0.0",
                 id: "lesson_export",
                 intent: :export,
                 direction: :outbound,
                 source: nil,
                 destination: :user_visible_files,
                 verification: :required,
                 media_types: ["application/pdf"]
               }
             ]
    end

    test "rejects transfer seams that do not declare the required semantic endpoint metadata" do
      assert_raise NimbleOptions.ValidationError, ~r/source/, fn ->
        Schema.validate!(
          id: "library",
          runtime: :live_view,
          security: :standard,
          transfers: [[id: :asset_upload, intent: :upload, verification: :required]]
        )
      end
    end

    test "accepts valid auth predicates" do
      validated =
        Schema.validate!(
          id: "secure-settings",
          runtime: :live_view,
          auth_min_level: :mfa,
          requires_recent_auth: 300
        )

      assert validated[:auth_min_level] == :mfa
      assert validated[:requires_recent_auth] == 300
    end

    test "accepts only explicit auth posture vocabulary" do
      for posture <- [:strict_recent, :remembered_ok, :cached_read_only_ok] do
        validated =
          Schema.validate!(
            id: "secure-settings",
            runtime: :live_view,
            auth_posture: posture
          )

        assert validated[:auth_posture] == posture
      end

      assert_raise NimbleOptions.ValidationError,
                   ~r/invalid value for :auth_posture option/,
                   fn ->
                     Schema.validate!(
                       id: "secure-settings",
                       runtime: :live_view,
                       auth_posture: :ambient
                     )
                   end
    end

    test "rejects invalid auth predicate values" do
      assert_raise NimbleOptions.ValidationError, ~r/invalid_mfa_level/, fn ->
        Schema.validate!(
          id: "secure-settings",
          runtime: :live_view,
          auth_min_level: :sms
        )
      end

      assert_raise NimbleOptions.ValidationError, ~r/positive integer seconds/, fn ->
        Schema.validate!(
          id: "secure-settings",
          runtime: :live_view,
          requires_recent_auth: 0
        )
      end

      assert_raise NimbleOptions.ValidationError, ~r/positive integer seconds/, fn ->
        Schema.validate!(
          id: "secure-settings",
          runtime: :live_view,
          requires_recent_auth: "300"
        )
      end
    end
  end

  describe "route threading for auth predicates" do
    test "threads auth fields without changing gating defaults" do
      route =
        Route.new!(
          id: "secure-settings",
          runtime: :live_view,
          auth_min_level: :mfa,
          requires_recent_auth: 300
        )

      assert route.auth_min_level == :mfa
      assert route.requires_recent_auth == 300
      assert route.auth_posture == :strict_recent
      assert route.gated_by == nil
      assert route.on_unavailable == nil
    end

    test "remembered posture is explicit and blocked by recent-auth requirements" do
      route =
        Route.new!(
          id: "remembered-dashboard",
          runtime: :live_view,
          auth_min_level: :password,
          auth_posture: :remembered_ok
        )

      assert route.auth_posture == :remembered_ok

      assert_raise NimbleOptions.ValidationError,
                   ~r/requires_recent_auth requires auth_posture :strict_recent/,
                   fn ->
                     Route.new!(
                       id: "recent-settings",
                       runtime: :live_view,
                       auth_min_level: :mfa,
                       requires_recent_auth: 300,
                       auth_posture: :remembered_ok
                     )
                   end
    end

    test "cached read-only posture requires provably cached read-only non-sensitive route" do
      route =
        Route.new!(
          id: "cached-inbox",
          runtime: :live_view,
          offline: :cached_read_only,
          cache_contract: :cached_inbox_v1,
          auth_min_level: :password,
          auth_posture: :cached_read_only_ok
        )

      assert route.auth_posture == :cached_read_only_ok

      assert_raise NimbleOptions.ValidationError,
                   ~r/sensitive routes require auth_posture :strict_recent/,
                   fn ->
                     Route.new!(
                       id: "cached-admin",
                       runtime: :live_view,
                       offline: :cached_read_only,
                       cache_contract: :cached_admin_v1,
                       security: :sensitive,
                       auth_min_level: :mfa,
                       auth_posture: :cached_read_only_ok
                     )
                   end

      assert_raise NimbleOptions.ValidationError, ~r/cached_read_only_ok requires/, fn ->
        Route.new!(
          id: "purchase",
          runtime: :live_view,
          offline: :cached_read_only,
          cache_contract: :purchase_v1,
          commerce: [corridor: :subscription_default, role: :purchase_intent],
          auth_min_level: :mfa,
          auth_posture: :cached_read_only_ok
        )
      end
    end

    test "auth posture is normalized route and manifest truth" do
      route =
        Route.new!(
          id: "secure-settings",
          runtime: :live_view,
          auth_min_level: :mfa,
          requires_recent_auth: 300
        )

      entry =
        Types.new_route_entry(
          id: route.id,
          path: "/settings",
          runtime: route.runtime,
          auth_min_level: route.auth_min_level,
          requires_recent_auth: route.requires_recent_auth,
          auth_posture: route.auth_posture
        )

      assert route.auth_posture == :strict_recent
      assert entry.auth_posture == :strict_recent
      assert Types.to_map(entry)["auth_posture"] == "strict_recent"
    end
  end

  describe "notification_open validation" do
    test "accepts true" do
      validated = Schema.validate!(id: "home", runtime: :live_view, notification_open: true)
      assert validated[:notification_open] == true
    end

    test "accepts actions keyword list and normalizes to map" do
      validated = Schema.validate!(id: "home", runtime: :live_view, notification_open: [actions: [:view, :reply]])
      assert validated[:notification_open] == %{actions: [:view, :reply]}
    end

    test "defaults to nil when not provided" do
      validated = Schema.validate!(id: "home", runtime: :live_view)
      assert validated[:notification_open] == nil
    end

    test "rejects invalid values" do
      assert_raise NimbleOptions.ValidationError, ~r/expected notification_open/, fn ->
        Schema.validate!(id: "home", runtime: :live_view, notification_open: "yes")
      end

      assert_raise NimbleOptions.ValidationError, ~r/list of atoms/, fn ->
        Schema.validate!(id: "home", runtime: :live_view, notification_open: [actions: ["view"]])
      end
    end
  end
end
