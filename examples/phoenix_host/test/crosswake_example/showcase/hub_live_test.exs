defmodule CrosswakeExample.Showcase.HubLiveTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.Showcase.Catalog
  alias CrosswakeExample.Showcase.HubLive

  test "renders the root showcase hub with all three lanes and visible support labels" do
    html = render_hub()

    assert html =~ "Phoenix routes, native where it matters."
    assert html =~ "Three seeded lanes show which runtime owns each route"
    assert html =~ "Explore Showcase"

    assert html =~ "SaaS/Admin"
    assert html =~ "Field Service"
    assert html =~ "Learning/Training"

    assert html =~ "/saas/dashboard"
    assert html =~ "/native/claims/:id/capture"
    assert html =~ "/study/session"

    for lane <- Catalog.lanes() do
      assert html =~ lane.primary_cta
      assert html =~ lane.boundary_note

      for label <- lane.runtime_labels ++ lane.support_labels do
        assert html =~ label,
               "expected #{inspect(lane.id)} label #{inspect(label)} to render as visible text"
      end
    end
  end

  test "keeps legacy proof routes secondary but one click reachable" do
    html = render_hub()

    assert html =~ "Proof routes stay one click deeper"
    assert html =~ "Use these routes to inspect route-owner semantics"
    assert html =~ ~s(href="/offline")
    assert html =~ "View Offline Study Proof"
    assert html =~ ~s(href="/bridge-proof")
    assert html =~ "View Bridge Proof"
    assert html =~ ~s(href="/native/claims")
    assert html =~ "View Native-Pressure Routes"
  end

  defp render_hub do
    assigns = %{lanes: Catalog.lanes()}

    assigns
    |> HubLive.render()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
