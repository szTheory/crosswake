defmodule CrosswakeExample.FieldService.CaptureLiveTest do
  use ExUnit.Case, async: false

  @capture_live Module.concat([CrosswakeExample, FieldService, CaptureLive])

  @tag :fieldserv_capture_live
  test "Fieldserv capture LiveView contract renders native-screen handoff without web camera or scanner control" do
    module =
      assert_exported!(
        @capture_live,
        :handle_params,
        3,
        "Fieldserv capture LiveView contract D-15/D-16/D-18 requires CaptureLive.handle_params/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [%{"id" => "job-1"}, "/fieldserv/jobs/job-1/capture", mounted])

    html = render_to_string(module, loaded.assigns)

    assert html =~ "Camera capture requires the native app runtime."
    assert html =~ "fieldserv-job-capture"
    assert html =~ "Native screen"
    assert html =~ "camera"
    assert html =~ "capture_upload"
    assert html =~ "Permission needed"
    assert html =~ "Scanner support is a future native-control candidate."
    assert html =~ ~s(href="/fieldserv/jobs/job-1/evidence/evidence-1/review")
    refute html =~ ~r/type="file"|getUserMedia|camera bridge|scanner bridge|document scan now/i
  end

  defp socket do
    %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}}}
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp render_to_string(module, assigns) do
    assigns
    |> Map.put_new(:__changed__, %{})
    |> Map.put_new(:flash, %{})
    |> then(&module.render/1)
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
