defmodule CrosswakeExample.FieldService.JobsLiveTest do
  use ExUnit.Case, async: false

  @jobs_live Module.concat([CrosswakeExample, FieldService, JobsLive])

  @tag :fieldserv_jobs_live
  test "Fieldserv jobs LiveView contract renders dense job queue and support truth" do
    module =
      assert_exported!(
        @jobs_live,
        :mount,
        3,
        "Fieldserv jobs LiveView contract D-01/D-04/D-30 requires JobsLive.mount/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])
    html = render_to_string(module, mounted.assigns)

    assert html =~ "Fieldserv"
    assert html =~ "Ridgeway"
    assert html =~ "Broken windshield"
    assert html =~ "LiveView route"
    assert html =~ "Cached read-only"
    assert html =~ "Evidence blocker"
    assert html =~ ~s(href="/fieldserv/jobs/job-1")
    assert html =~ "role=\"status\""
    refute html =~ ~r/saved locally|queued for sync|camera bridge|scanner bridge/i
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
