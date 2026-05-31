Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/media_projection.ex",
  __DIR__
)

Code.require_file(
  "../../../examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex",
  __DIR__
)

defmodule Crosswake.Proof.Phase45RindleLiveTest do
  use ExUnit.Case, async: false

  @moduletag :requires_example_host

  alias Phoenix.Component
  alias Phoenix.LiveViewTest

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end

  test "router declares the /media/proof LiveView route with honest policy" do
    source = File.read!("examples/phoenix_host/lib/crosswake_example/router.ex")

    assert source =~ ~s(live "/proof", Media.MediaLaneLive)
    assert source =~ ~s(id: "media-proof-lane")
    assert source =~ "runtime: :live_view"
    assert source =~ "offline: :unavailable"
  end

  test "rendered states distinguish queued, uploaded, scanning, and available authority" do
    assert render_state(:queued) =~ "not committed"

    uploaded = render_state(:uploaded)
    assert uploaded =~ "Device upload evidence recorded"
    refute uploaded =~ "media is available"

    assert render_state(:scanning) =~ "Backend verification is in progress"
    assert render_state(:available) =~ "Backend verified media is available"
  end

  test "callbacks only reach available after explicit backend verification" do
    live = media_live()
    assert {:ok, socket} = live.mount(%{}, %{}, %Phoenix.LiveView.Socket{})
    assert socket.assigns.derived_state == :queued

    assert {:noreply, uploaded} = live.handle_event("record_upload", %{}, socket)
    assert uploaded.assigns.derived_state == :uploaded
    refute render_assigns(uploaded.assigns) =~ "Backend verified media is available"

    assert {:noreply, scanning} = live.handle_event("start_scan", %{}, uploaded)
    assert scanning.assigns.derived_state == :scanning

    assert {:noreply, available} = live.handle_event("verify_backend", %{}, scanning)
    assert available.assigns.derived_state == :available
    assert render_assigns(available.assigns) =~ "Backend verified media is available"
  end

  test "event handlers return fail-closed flashes instead of crashing on missing state" do
    live = media_live()
    assert {:ok, socket} = live.mount(%{}, %{}, %Phoenix.LiveView.Socket{})
    broken = Component.assign(socket, grant: nil, media_object: nil)

    assert {:noreply, upload_failed} = live.handle_event("record_upload", %{}, broken)
    assert upload_failed.assigns.error_message =~ "Media lane unavailable"

    assert {:noreply, scan_failed} = live.handle_event("start_scan", %{}, broken)
    assert scan_failed.assigns.error_message =~ "Media lane unavailable"

    assert {:noreply, verify_failed} = live.handle_event("verify_backend", %{}, broken)
    assert verify_failed.assigns.error_message =~ "Media lane unavailable"
  end

  defp media_live, do: Module.concat(["CrosswakeExample", "Media", "MediaLaneLive"])

  defp render_state(state) do
    assert {:ok, socket} = media_live().mount(%{}, %{}, %Phoenix.LiveView.Socket{})

    socket
    |> Component.assign(:derived_state, state)
    |> Map.fetch!(:assigns)
    |> render_assigns()
  end

  defp render_assigns(assigns) do
    assigns
    |> media_live().render()
    |> LiveViewTest.rendered_to_string()
  end
end
