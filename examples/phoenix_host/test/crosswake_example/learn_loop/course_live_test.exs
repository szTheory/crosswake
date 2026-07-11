defmodule CrosswakeExample.LearnLoop.CourseLiveTest do
  use ExUnit.Case, async: false

  @course_live Module.concat([CrosswakeExample, LearnLoop, CourseLive])

  @tag :learnloop_course_live
  test "LearnLoop course LiveView contract renders lesson rows, cached posture, and gated subscription pressure" do
    module =
      assert_exported!(
        @course_live,
        :handle_params,
        3,
        "LearnLoop course LiveView contract D-01/D-04/D-08 requires CourseLive.handle_params/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [
        %{"id" => "course-elixir-routing"},
        "/learnloop/courses/course-elixir-routing",
        mounted
      ])

    html = render_to_string(module, loaded.assigns)

    assert html =~ "LearnLoop"
    assert html =~ "course-elixir-routing"
    assert html =~ "lesson-offline-review"
    assert html =~ "Cached read-only"
    assert html =~ "LiveView route"
    assert html =~ "Backend projection required"
    assert html =~ "Access stays closed until backend projection refreshes"
    assert html =~ ~s(href="/learnloop/study/session")
    assert html =~ ~s(href="/learnloop/subscription")
    assert html =~ "role=\"list\""
    assert html =~ "role=\"status\""

    refute html =~ ~r/edit course|delete course|course marketplace|coach dashboard|saved locally|queued for replay|LiveView works offline/i
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
