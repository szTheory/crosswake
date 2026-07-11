defmodule CrosswakeExample.FieldService.EvidenceReviewLiveTest do
  use ExUnit.Case, async: false

  @review_live Module.concat([CrosswakeExample, FieldService, EvidenceReviewLive])
  @evidence Module.concat([CrosswakeExample, FieldService, Evidence])

  @tag :fieldserv_evidence_review_live
  test "Fieldserv evidence review LiveView contract keeps backend verification authoritative" do
    if Code.ensure_loaded?(@evidence) and function_exported?(@evidence, :reset!, 0) do
      apply(@evidence, :reset!, [])
    end

    module =
      assert_exported!(
        @review_live,
        :handle_event,
        3,
        "Fieldserv evidence review LiveView contract D-19 requires EvidenceReviewLive.handle_event/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [
        %{"id" => "job-1", "evidence_id" => "evidence-1"},
        "/fieldserv/jobs/job-1/evidence/evidence-1/review",
        mounted
      ])

    html = render_to_string(module, loaded.assigns)
    assert html =~ "Evidence review"
    assert html =~ "Device evidence recorded"
    assert html =~ "Backend verification pending"
    assert html =~ "Backend verified"
    assert html =~ "Backend rejected"
    refute html =~ ~r/uploaded successfully|media available after device capture/i

    {:noreply, pending} = apply(module, :handle_event, ["start-backend-verification", %{}, loaded])
    assert render_to_string(module, pending.assigns) =~ "role=\"status\""

    {:noreply, verified} = apply(module, :handle_event, ["mark-backend-verified", %{}, pending])
    assert render_to_string(module, verified.assigns) =~ "Backend verified"

    {:noreply, rejected} = apply(module, :handle_event, ["mark-backend-rejected", %{}, verified])
    assert render_to_string(module, rejected.assigns) =~ "Backend rejected"
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
