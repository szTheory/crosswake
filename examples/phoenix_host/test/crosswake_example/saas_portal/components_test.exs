defmodule CrosswakeExample.SaaSPortal.ComponentsTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.SaaSPortal.Diagnostics

  @endpoint CrosswakeExample.Endpoint
  @components Module.concat([CrosswakeExample, SaaSPortal, Components])
  @account %{
    id: "acct-north",
    name: "Northwind Workspace",
    health: :steady,
    renewal_window: "14 days"
  }
  @user %{
    id: "approver-1",
    name: "Alex Approver",
    email: "alex@example.crosswake.invalid",
    role: :approver,
    account_id: "acct-north"
  }

  @tag :adminpilot_components
  test "AdminPilot shell renders brand, product navigation, and slot content" do
    module = assert_component_module!()

    html =
      render_component(module, :admin_shell, %{
        page_title: "Dashboard",
        route_id: "saas-dashboard",
        current_saas_account: @account,
        current_saas_user: @user,
        posture_badges: ["LiveView route", "Cached read-only", "Server authority"],
        inner_block: slot("Workspace body")
      })

    assert html =~ "AdminPilot"
    assert html =~ "SaaS/Admin"
    assert html =~ "Workspace body"
    assert html =~ ~s(href="/saas/dashboard")
    assert html =~ ~s(href="/saas/approvals")
    assert html =~ ~s(href="/saas/accounts/acct-north")
    assert html =~ ~s(href="/saas/settings/profile")
    assert html =~ ~s(href="/saas/admin/member-access")
    assert html =~ "Cached read-only"
  end

  @tag :adminpilot_components
  test "AdminPilot diagnostics panel renders route rows and guide links from diagnostics helpers" do
    module = assert_component_module!()
    rows = Diagnostics.route_policy_rows()

    html =
      render_component(module, :diagnostics_panel, %{
        route_id: "saas-dashboard",
        rows: rows,
        guide_links: Diagnostics.guide_links()
      })

    assert html =~ "adminpilot-diagnostics"
    assert html =~ "saas-dashboard"
    assert html =~ "saas-admin-member-access"
    assert html =~ "Cached read-only"
    assert html =~ "Haptics is optional"
    assert html =~ "Route policy guide"
    assert html =~ "guides/route_policy.md"
  end

  @tag :adminpilot_components
  test "AdminPilot component module exports page building blocks" do
    module = assert_component_module!()

    for function <- [
          :admin_shell,
          :posture_badges,
          :diagnostics_panel,
          :kpi_strip,
          :activity_feed,
          :status_badge
        ] do
      assert function_exported?(module, function, 1),
             "expected #{inspect(module)}.#{function}/1 to be exported"
    end

    html =
      render_component(module, :status_badge, %{
        label: "Server authority",
        tone: :authority
      })

    assert html =~ "adminpilot-status-badge"
    assert html =~ "Server authority"
  end

  @tag :adminpilot_components
  test "AdminPilot CSS is scoped, responsive, focus-visible, and reduced-motion safe" do
    css = File.read!("priv/static/css/app.css")

    for selector <- [
          ".adminpilot-shell",
          ".adminpilot-topbar",
          ".adminpilot-layout",
          ".adminpilot-kpi-strip",
          ".adminpilot-panel",
          ".adminpilot-route-badge",
          ".adminpilot-diagnostics",
          ".adminpilot-record-list",
          ".adminpilot-action-footer",
          ".adminpilot-activity-feed"
        ] do
      assert css =~ selector, "expected #{selector} in scoped AdminPilot CSS"
    end

    assert css =~ "focus-visible"
    assert css =~ "prefers-reduced-motion"
    assert css =~ "min-height: 44px"
    assert css =~ "grid-template-columns: 1fr"
    refute css =~ "adminpilot-hero"
    refute css =~ ~r/native-control|native action bar|provider mfa/i
  end

  defp assert_component_module! do
    assert Code.ensure_loaded?(@components),
           "AdminPilot components contract requires #{@components} to be loadable"

    @components
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
