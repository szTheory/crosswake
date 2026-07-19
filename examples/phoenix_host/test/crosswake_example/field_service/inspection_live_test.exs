defmodule CrosswakeExample.FieldService.InspectionLiveTest do
  use ExUnit.Case, async: false

  @inspection_live Module.concat([CrosswakeExample, FieldService, InspectionLive])
  @evidence Module.concat([CrosswakeExample, FieldService, Evidence])

  @tag :fieldserv_inspection_live
  test "Fieldserv inspection LiveView contract records online events and keeps offline island future-only" do
    if Code.ensure_loaded?(@evidence) and function_exported?(@evidence, :reset!, 0) do
      apply(@evidence, :reset!, [])
    end

    module =
      assert_exported!(
        @inspection_live,
        :handle_event,
        3,
        "Fieldserv inspection LiveView contract D-14/D-24/D-26 requires InspectionLive.handle_event/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [
        %{"id" => "job-1"},
        "/fieldserv/jobs/job-1/inspection",
        mounted
      ])

    html = render_to_string(module, loaded.assigns)
    assert html =~ "Inspection workspace"
    assert html =~ "Cached read-only"
    assert html =~ "Future offline island candidate"
    assert html =~ "local draft storage"
    assert html =~ "journal/outbox"
    refute html =~ ~r/saved locally|queued for sync|working offline/i

    {:noreply, updated} = apply(module, :handle_event, ["record-step", %{"step_id" => "step-1"}, loaded])
    updated_html = render_to_string(module, updated.assigns)

    assert updated_html =~ "role=\"status\""
    assert updated_html =~ "Server recorded"
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
