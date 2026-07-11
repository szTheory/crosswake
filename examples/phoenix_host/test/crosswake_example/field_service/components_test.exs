defmodule CrosswakeExample.FieldService.ComponentsTest do
  use ExUnit.Case, async: true

  @endpoint CrosswakeExample.Endpoint
  @components Module.concat([CrosswakeExample, FieldService, Components])
  @diagnostics Module.concat([CrosswakeExample, FieldService, Diagnostics])

  @job %{
    id: "job-1",
    title: "Broken windshield",
    route_id: "fieldserv-job",
    evidence_id: "evidence-1"
  }

  @tag :fieldserv_component_contract
  test "Fieldserv component contract renders brand, route badges, diagnostics, and slot content" do
    module =
      assert_exported!(
        @components,
        :fieldserv_shell,
        1,
        "Fieldserv component contract D-29/D-30/D-32 requires #{@components}.fieldserv_shell/1"
      )

    rows =
      if Code.ensure_loaded?(@diagnostics) and function_exported?(@diagnostics, :route_policy_rows, 0) do
        apply(@diagnostics, :route_policy_rows, [])
      else
        []
      end

    html =
      render_component(module, :fieldserv_shell, %{
        page_title: "Ridgeway job queue",
        route_id: "fieldserv-jobs",
        job: @job,
        diagnostics_rows: rows,
        posture_badges: ["LiveView route", "Cached read-only", "Dispatcher queue"],
        inner_block: slot("Jobsite body")
      })

    assert html =~ "Fieldserv"
    assert html =~ "Field Service"
    assert html =~ "Jobsite body"
    assert html =~ ~s(href="/fieldserv/jobs")
    assert html =~ ~s(href="/fieldserv/jobs/job-1/inspection")
    assert html =~ ~s(href="/fieldserv/jobs/job-1/capture")
    assert html =~ ~s(href="/fieldserv/jobs/job-1/evidence/evidence-1/review")
    assert html =~ "Cached read-only"
    assert html =~ "Route policy diagnostics"
  end

  @tag :fieldserv_component_contract
  test "Fieldserv component contract exports lane-local building blocks" do
    module =
      assert_exported!(
        @components,
        :status_badge,
        1,
        "Fieldserv component contract D-33/D-35 requires status_badge/1"
      )

    for function <- [
          :fieldserv_shell,
          :posture_badges,
          :diagnostics_panel,
          :job_status_strip,
          :evidence_timeline,
          :checklist_rows,
          :status_badge
        ] do
      assert function_exported?(module, function, 1),
             "Fieldserv component contract D-33 requires #{inspect(module)}.#{function}/1"
    end

    html =
      render_component(module, :status_badge, %{
        label: "Backend verification pending",
        tone: :warning
      })

    assert html =~ "fieldserv-status-badge"
    assert html =~ "Backend verification pending"
  end

  @tag :fieldserv_component_contract
  test "Fieldserv component contract requires scoped accessible CSS" do
    css = File.read!("priv/static/css/app.css")

    for selector <- [
          ".fieldserv-shell",
          ".fieldserv-topbar",
          ".fieldserv-job-grid",
          ".fieldserv-status-strip",
          ".fieldserv-route-badge",
          ".fieldserv-evidence-timeline",
          ".fieldserv-checklist",
          ".fieldserv-action-footer",
          ".fieldserv-diagnostics",
          ".fieldserv-capture-handoff",
          ".fieldserv-review-panel"
        ] do
      assert css =~ selector, "Fieldserv component contract D-33 expected #{selector}"
    end

    assert css =~ "focus-visible"
    assert css =~ "prefers-reduced-motion"
    assert css =~ "box-sizing: border-box"
    assert css =~ "min-height: 44px"
    assert css =~ "grid-template-columns: 1fr"
    refute css =~ "fieldserv-hero"
    refute css =~ ~r/native-control command|camera bridge|scanner bridge|saved locally|queued for sync/i
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end

  defp render_component(module, function, assigns) do
    Phoenix.LiveViewTest.__render_component__(
      @endpoint,
      Function.capture(module, function, 1),
      assigns,
      []
    )
  end

  defp slot(text) do
    [
      %{
        __slot__: :inner_block,
        inner_block: fn _changed, _argument -> text end
      }
    ]
  end
end
