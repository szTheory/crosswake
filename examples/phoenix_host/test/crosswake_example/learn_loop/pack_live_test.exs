defmodule CrosswakeExample.LearnLoop.PackLiveTest do
  use ExUnit.Case, async: false

  @pack_live Module.concat([CrosswakeExample, LearnLoop, PackLive])

  @tag :learnloop_pack_live
  test "LearnLoop pack LiveView contract renders content-pack metadata, route badges, and honest offline handoff" do
    module =
      assert_exported!(
        @pack_live,
        :handle_params,
        3,
        "LearnLoop pack LiveView contract D-10/D-13/D-34 requires PackLive.handle_params/3"
      )

    {:ok, mounted} = apply(module, :mount, [%{}, %{}, socket()])

    {:noreply, loaded} =
      apply(module, :handle_params, [
        %{"id" => "learnloop_daily_pack"},
        "/learnloop/packs/learnloop_daily_pack",
        mounted
      ])

    html = render_to_string(module, loaded.assigns)

    assert html =~ "LearnLoop"
    assert html =~ "learnloop_daily_pack"
    assert html =~ "Daily Elixir Pack"
    assert html =~ "Content pack"
    assert html =~ "IndexedDB"
    assert html =~ "Cached read-only"
    assert html =~ "Offline island"
    assert html =~ "Local-first outbox"
    assert html =~ "Backend projection required"
    assert html =~ "Access stays closed until backend projection refreshes"
    assert html =~ "Mock storefront evidence received"
    assert html =~ ~s(data-entitlement-state="pending")
    assert html =~ "Saved locally"
    assert html =~ "Queued for replay"
    assert html =~ ~s(href="/learnloop/study/session")
    assert html =~ ~s(href="/learnloop/subscription")
    assert html =~ "role=\"status\""

    refute html =~
             ~r/native SQLite|native storage shipped|background sync|generic sync engine|media downloads|LiveView works offline/i
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
