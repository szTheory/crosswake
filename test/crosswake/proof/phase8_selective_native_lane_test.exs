defmodule Crosswake.Proof.Phase8SelectiveNativeLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest

  @native_routes %{
    "selective-native-claims" => "/native/claims",
    "selective-native-claim" => "/native/claims/:id",
    "selective-native-claim-capture" => "/native/claims/:id/capture",
    "selective-native-submission-review" => "/native/submissions/:id/review"
  }

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
          "examples/phoenix_host/lib/crosswake_example/router.ex"
        ] do
      Code.require_file(Path.expand(path, File.cwd!()))
    end

    :ok
  end

  test "shared example host exposes exactly the locked selective-native route set under /native" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    native_routes =
      manifest.routes
      |> Enum.filter(fn {_id, route} -> String.starts_with?(route.path, "/native") end)
      |> Enum.into(%{})

    assert Map.keys(native_routes) |> Enum.sort() == Map.keys(@native_routes) |> Enum.sort()

    for {route_id, path} <- @native_routes do
      assert native_routes[route_id].path == path
    end
  end

  test "exactly one Phase 8 route is :native_screen, and it is /native/claims/:id/capture" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    capture_route = manifest.routes["selective-native-claim-capture"]
    assert capture_route.runtime == :native_screen
    assert capture_route.security == :sensitive

    for route_id <- Map.keys(@native_routes) -- ["selective-native-claim-capture"] do
      route = manifest.routes[route_id]
      assert route.runtime != :native_screen
    end
  end

  test "the surrounding Phase 8 routes remain :live_view and use standard/sensitive correctly" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    claims_route = manifest.routes["selective-native-claims"]
    assert claims_route.runtime == :live_view
    assert claims_route.security == :standard

    claim_route = manifest.routes["selective-native-claim"]
    assert claim_route.runtime == :live_view
    assert claim_route.security == :standard

    review_route = manifest.routes["selective-native-submission-review"]
    assert review_route.runtime == :live_view
    assert review_route.security == :sensitive
  end
end
