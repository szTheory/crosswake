defmodule Crosswake.Proof.Phase9LocalFirstLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest

  setup_all do
    for path <- [
          "examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/on_mount.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/claim_live.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/claim_capture_live.ex",
          "examples/phoenix_host/lib/crosswake_example/selective_native/submission_review_live.ex",
          "examples/phoenix_host/lib/crosswake_example/local_first/study_history_live.ex",
          "examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex",
          "examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex",
          "examples/phoenix_host/lib/crosswake_example/router.ex"
        ] do
      Code.require_file(Path.expand(path, File.cwd!()))
    end

    :ok
  end

  test "shared example host exposes the expected /study route policies" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    session_route = manifest.routes["local-first-study-session"]
    assert session_route.path == "/study/session"
    assert session_route.offline == :local_first
    assert session_route.packs == ["daily_study@1.0.0"]

    history_route = manifest.routes["local-first-study-history"]
    assert history_route.path == "/study/history"
    assert history_route.offline == :cached_read_only
  end

  test "sync API endpoint is present in Phoenix Router" do
    routes = Phoenix.Router.routes(CrosswakeExample.Router)
    
    sync_route = Enum.find(routes, fn route -> 
      route.path == "/study/sync" and route.verb == :post
    end)
    
    assert sync_route != nil
    assert sync_route.plug == CrosswakeExample.LocalFirst.SyncController
    assert sync_route.plug_opts == :sync
  end
end
