defmodule CrosswakeExample.LearnLoop.HistoryLiveTest do
  use ExUnit.Case, async: false

  @history_live Module.concat([CrosswakeExample, LearnLoop, HistoryLive])

  @tag :learnloop_history_live
  test "LearnLoop history LiveView contract renders server-confirmed progress as cached read-only support truth" do
    module =
      assert_exported!(
        @history_live,
        :mount,
        3,
        "LearnLoop history LiveView contract D-08/D-12/D-13 requires HistoryLive.mount/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])
    html = render_to_string(module, mounted.assigns)

    assert html =~ "LearnLoop"
    assert html =~ "History"
    assert html =~ "server-confirmed"
    assert html =~ "Cached read-only"
    assert html =~ "LiveView route"
    assert html =~ "Synced"
    assert html =~ "Rejected by server - review needed"
    assert html =~ "role=\"status\""
    assert html =~ ~s(href="/learnloop")
    assert html =~ ~s(href="/learnloop/study/session")

    refute html =~ ~r/LiveView works offline|local-first mutation|server reset cleared|native storage|background sync/i
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
