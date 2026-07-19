defmodule CrosswakeExample.LearnLoop.DashboardLiveTest do
  use ExUnit.Case, async: false

  @dashboard_live Module.concat([CrosswakeExample, LearnLoop, DashboardLive])

  @tag :learnloop_dashboard_live
  test "LearnLoop dashboard LiveView contract renders learner momentum, route support truth, and offline-study CTA" do
    module =
      assert_exported!(
        @dashboard_live,
        :mount,
        3,
        "LearnLoop dashboard LiveView contract D-01/D-02/D-30 requires DashboardLive.mount/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])
    html = render_to_string(module, mounted.assigns)

    assert html =~ "LearnLoop"
    assert html =~ "Brightpath Academy"
    assert html =~ "Iris Learner"
    assert html =~ "course-elixir-routing"
    assert html =~ "learnloop_daily_pack"
    assert html =~ "LiveView route"
    assert html =~ "Cached read-only"
    assert html =~ "Offline island"
    assert html =~ "Local-first outbox"
    assert html =~ "Backend projection"
    assert html =~ "Mocked storefront evidence"
    assert html =~ ~s(href="/learnloop/courses/course-elixir-routing")
    assert html =~ ~s(href="/learnloop/packs/learnloop_daily_pack")
    assert html =~ ~s(href="/learnloop/study/session")
    assert html =~ ~s(href="/learnloop/history")
    assert html =~ ~s(href="/learnloop/subscription")
    assert html =~ "role=\"status\""
    assert html =~ "aria-live"

    assert_before(
      html,
      "Iris Learner",
      "Backend projection required",
      "LearnLoop dashboard LiveView contract D-02 requires learner progress before entitlement pressure"
    )

    refute html =~ ~r/course marketplace|course authoring|coach dashboard|generic LMS|LiveView works offline|server reset cleared/i
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

  defp assert_before(html, first, second, message) do
    first_index = :binary.match(html, first)
    second_index = :binary.match(html, second)

    assert first_index != :nomatch, "#{message}; missing #{inspect(first)}"
    assert second_index != :nomatch, "#{message}; missing #{inspect(second)}"
    assert elem(first_index, 0) < elem(second_index, 0), message
  end
end
