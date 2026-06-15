defmodule Crosswake.Proof.Phase9LocalFirstLaneTest do
  use ExUnit.Case, async: false

  # Depends on the checked-in example Phoenix app (CrosswakeExample.*) being
  # compiled. Run by phase5-proof.yml, which builds the example host first;
  # excluded from the hermetic hex-page-proof full-suite run via --exclude.
  @moduletag :requires_example_host

  alias Crosswake.Manifest

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
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

    sync_route =
      Enum.find(routes, fn route ->
        route.path == "/study/sync" and route.verb == :post
      end)

    assert sync_route != nil
    assert sync_route.plug == CrosswakeExample.LocalFirst.SyncController
    assert sync_route.plug_opts == :sync
  end

  test "checked-in shell fixtures carry the local-first route truth" do
    ios_manifest = File.read!("examples/ios_shell_host/Fixtures/crosswake_manifest.json")

    android_manifest =
      File.read!("examples/android_shell_host/app/src/main/assets/crosswake_manifest.json")

    android_instrumented =
      File.read!(
        "examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt"
      )

    assert ios_manifest =~ "\"local-first-study-session\""
    assert ios_manifest =~ "\"path\": \"/study/history\""

    assert android_manifest =~ "\"local-first-study-session\""
    assert android_manifest =~ "\"path\": \"/study/history\""
    assert android_instrumented =~ "https://example.crosswake.invalid/study/history"
  end
end
