defmodule CrosswakeExample.FieldService.JobLiveTest do
  use ExUnit.Case, async: false

  @job_live Module.concat([CrosswakeExample, FieldService, JobLive])

  @tag :fieldserv_job_live
  test "Fieldserv job detail LiveView contract renders asset, notes, evidence, and action path" do
    module =
      assert_exported!(
        @job_live,
        :handle_params,
        3,
        "Fieldserv job detail LiveView contract D-02/D-10/D-25 requires JobLive.handle_params/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [%{"id" => "job-1"}, "/fieldserv/jobs/job-1", mounted])

    html = render_to_string(module, loaded.assigns)

    assert html =~ "Broken windshield"
    assert html =~ "Asset"
    assert html =~ "Inspection"
    assert html =~ "Evidence timeline"
    assert html =~ "Cached read-only"
    assert html =~ ~s(href="/fieldserv/jobs/job-1/inspection")
    assert html =~ ~s(href="/fieldserv/jobs/job-1/capture")
    assert html =~ ~s(href="/fieldserv/jobs/job-1/evidence/evidence-1/review")
    refute html =~ ~r/edit job|delete job|routing map|background location|queued for sync/i
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
