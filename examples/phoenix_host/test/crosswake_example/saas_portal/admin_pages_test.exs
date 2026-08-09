defmodule CrosswakeExample.SaaSPortal.AdminPagesTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias CrosswakeExample.Showcase.Reset

  @endpoint CrosswakeExample.Endpoint

  setup do
    Reset.reset!()
    :ok
  end

  @tag :adminpilot_pages
  test "dashboard renders AdminPilot approvals workspace with inline diagnostics" do
    html = get_html("/saas/dashboard")

    assert html =~ "adminpilot-shell"
    assert html =~ "AdminPilot"
    assert html =~ "Northwind Workspace"
    assert html =~ "Quarterly spend increase"
    assert html =~ ~s(href="/saas/approvals")
    assert html =~ "Cached read-only"
    assert html =~ "Server authority"
    assert html =~ "adminpilot-diagnostics"
  end

  @tag :adminpilot_pages
  test "account page renders read-only team, role, settings, and activity context" do
    html = get_html("/saas/accounts/acct-north")

    assert html =~ "adminpilot-shell"
    assert html =~ "Operations Control"
    assert html =~ "High-band spend approvals"
    assert html =~ "Marta Member"
    assert html =~ "Alex Approver"
    assert html =~ "No edit controls"
    assert html =~ "adminpilot-diagnostics"
    refute html =~ ~r/<form|phx-submit|Edit account|Delete account|Save changes/i
  end

  @tag :adminpilot_pages
  test "settings page shows authenticated member posture without provider or native auth claims" do
    html = get_html("/saas/settings/profile")

    assert html =~ "adminpilot-shell"
    assert html =~ "Marta Member"
    assert html =~ "Authenticated session"
    assert html =~ "Cached read-only"
    assert html =~ "No native admin mutation authority"
    assert html =~ "adminpilot-diagnostics"
    refute html =~ ~r/native auth UI|provider MFA flow|passkey|OIDC/i
  end

  @tag :adminpilot_pages
  test "admin member-access page remains a blocked sensitive route proof state" do
    html = get_html("/saas/admin/member-access")

    assert html =~ "adminpilot-shell"
    assert html =~ "MFA required"
    assert html =~ "Sensitive route"
    assert html =~ "Server authority"
    assert html =~ "Persistent shell session does not grant admin authority"
    assert html =~ "adminpilot-diagnostics"
    refute html =~ ~r/outbox|journal|reconciliation|local[- ]first|Grant admin access/i
  end

  defp get_html(path) do
    build_conn()
    |> get(path)
    |> html_response(200)
  end
end
