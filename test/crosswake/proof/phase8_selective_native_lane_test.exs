Code.require_file("../../support/example_host.exs", __DIR__)

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
    Crosswake.TestSupport.ExampleHost.load!()
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
    assert capture_route.capabilities == ["camera"]
    assert capture_route.packs == ["camera_capture_assets@1.0.0"]
    assert length(capture_route.transfers) == 1
    transfer = hd(capture_route.transfers)
    assert transfer.id == "capture_upload"
    assert transfer.intent == :upload
    assert transfer.source == :native_capture
    assert transfer.verification == :required
    assert transfer.media_types == ["image/*"]

    for route_id <- Map.keys(@native_routes) -- ["selective-native-claim-capture"] do
      route = manifest.routes[route_id]
      assert route.runtime != :native_screen
      assert route.capabilities == []
      assert route.packs == []
      assert route.transfers == []
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

  test "example host has a narrow Ecto-backed claim and submission slice without leaking into core" do
    assert File.exists?("examples/phoenix_host/lib/crosswake_example/repo.ex")
    assert File.exists?("examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex")
    assert File.exists?("examples/phoenix_host/lib/crosswake_example/selective_native/submission.ex")

    # Core library should not have Ecto schemas
    refute File.exists?("lib/crosswake/selective_native/claim.ex")
  end

  test "the data boundary keeps local capture, staging, upload, and submission as distinct states" do
    claim_code = File.read!("examples/phoenix_host/lib/crosswake_example/selective_native/claim.ex")
    submission_code = File.read!("examples/phoenix_host/lib/crosswake_example/selective_native/submission.ex")

    assert claim_code =~ "field :status, :string"
    assert claim_code =~ "schema \"selective_native_claims\""
    
    assert submission_code =~ "field :status, :string"
    assert submission_code =~ "schema \"selective_native_submissions\""
    assert submission_code =~ "\"captured locally\""
    assert submission_code =~ "\"staged\""
    assert submission_code =~ "\"uploaded\""
    assert submission_code =~ "\"submitted\""
  end
end
