defmodule CrosswakeExample.Showcase.HubLiveTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.Showcase.Branding
  alias CrosswakeExample.Showcase.Catalog
  alias CrosswakeExample.Showcase.HubLive

  test "renders the root showcase hub with all three lanes and visible support labels" do
    html = render_hub()

    assert html =~ "Crosswake Showcase"
    assert html =~ "Demo apps powered by Crosswake"
    assert html =~ ~s(alt="Crosswake")
    assert html =~ ~s(src="/brand/crosswake-lockup-horizontal.svg")
    assert html =~ ~s(srcset="/brand/crosswake-lockup-horizontal-dark.svg")
    refute html =~ "Crosswake example host"

    assert html =~ "Phoenix routes, native where it matters."
    assert html =~ "Three realistic demo apps show which runtime owns each route"
    assert html =~ "Explore Showcase"

    assert html =~ "SaaS/Admin"
    assert html =~ "Field Service"
    assert html =~ "Learning/Training"

    assert html =~ "AdminPilot"
    assert html =~ "Fieldserv"
    assert html =~ "LearnLoop"

    assert html =~ "/saas/dashboard"
    assert html =~ "/fieldserv/jobs"
    assert html =~ ~s(href="/learnloop"),
           "LearnLoop showcase entry contract D-01/D-05 requires the root hub CTA to enter /learnloop"

    assert html =~ "Open LearnLoop",
           "LearnLoop showcase entry contract D-02 requires product-first LearnLoop CTA copy"

    refute html =~ ~s(class="btn-secondary showcase-lane-cta" href="/offline")
    refute html =~ "/study/session"

    for lane <- Catalog.lanes() do
      assert html =~ lane.primary_cta
      assert html =~ lane.boundary_note
      assert html =~ ~s(data-brand="#{lane.brand.name}")
      assert html =~ ~s(data-style="#{lane.brand.style_identifier}")
      assert html =~ lane.brand.tagline
      assert html =~ lane.brand.fixture_brief.organization

      for label <- lane.runtime_labels ++ lane.support_labels do
        assert html =~ label,
               "expected #{inspect(lane.id)} label #{inspect(label)} to render as visible text"
      end
    end
  end

  test "renders fixture records and activity for each branded demo app" do
    html = render_hub()

    for lane <- Catalog.lanes() do
      for record <- lane.brand.fixture_brief.records do
        assert html =~ record,
               "expected #{lane.brand.name} fixture record #{inspect(record)} to render"
      end

      for activity <- lane.brand.fixture_brief.activity do
        assert html =~ activity,
               "expected #{lane.brand.name} activity #{inspect(activity)} to render"
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
    assigns = %{lanes: Catalog.lanes(), parent_brand: Branding.root()}

    assigns
    |> HubLive.render()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
