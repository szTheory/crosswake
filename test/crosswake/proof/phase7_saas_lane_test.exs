Code.require_file("../../support/example_host.exs", __DIR__)

defmodule Crosswake.Proof.Phase7SaaSLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest
  alias Phoenix.Component
  alias Phoenix.LiveViewTest

  @saas_routes %{
    "saas-dashboard" => "/saas/dashboard",
    "saas-account" => "/saas/accounts/:id",
    "saas-approvals" => "/saas/approvals",
    "saas-approval" => "/saas/approvals/:id",
    "saas-profile-settings" => "/saas/settings/profile"
  }

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end

  test "shared example host exposes exactly the locked SaaS route set under /saas" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    saas_routes =
      manifest.routes
      |> Enum.filter(fn {_id, route} -> String.starts_with?(route.path, "/saas") end)
      |> Enum.into(%{})

    assert Map.keys(saas_routes) |> Enum.sort() == Map.keys(@saas_routes) |> Enum.sort()

    for {route_id, path} <- @saas_routes do
      assert saas_routes[route_id].path == path
    end
  end

  test "all SaaS routes stay live_view-owned inside one shared defaults posture" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    for route_id <- Map.keys(@saas_routes) do
      route = manifest.routes[route_id]

      assert route.runtime == :live_view
      assert route.offline == :cached_read_only
      assert route.security == :standard
    end
  end

  test "the SaaS lane does not drift into packs, transfers, offline islands, or native screens" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    for route_id <- Map.keys(@saas_routes) do
      route = manifest.routes[route_id]

      assert route.runtime != :native_screen
      assert route.runtime != :offline_island
      assert route.packs == []
      assert route.transfers == []
    end
  end

  test "only the approval detail route declares the bounded haptics capability" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    assert manifest.routes["saas-approval"].capabilities == ["haptics.impact"]

    for route_id <- Map.keys(@saas_routes) -- ["saas-approval"] do
      assert manifest.routes[route_id].capabilities == []
    end
  end

  test "host-owned auth keeps one signed-in boundary and one lightweight role split" do
    auth = CrosswakeExample.SaaSPortal.Auth
    fixtures_mod = CrosswakeExample.SaaSPortal.Fixtures

    assert apply(auth, :session_key, []) == "saas_portal_user_id"
    assert Enum.sort(apply(auth, :roles, [])) == [:approver, :member]

    fixtures = apply(fixtures_mod, :seed, [])
    approver = apply(fixtures_mod, :user!, [:approver])
    member = apply(fixtures_mod, :user!, [:member])

    assert fixtures.account.id == "acct-north"
    assert approver.role == :approver
    assert member.role == :member
    assert approver.account_id == fixtures.account.id
    assert member.account_id == fixtures.account.id
  end

  test "ordinary Phoenix boundaries and the guarded approval action re-check authorization" do
    approvals = CrosswakeExample.SaaSPortal.Approvals
    fixtures = CrosswakeExample.SaaSPortal.Fixtures
    router = File.read!("examples/phoenix_host/lib/crosswake_example/router.ex")

    assert router =~ "pipe_through [:browser, :saas_portal]"
    assert router =~ "live_session :saas_portal"
    assert router =~ "CrosswakeExample.SaaSPortal.OnMount"

    approval = apply(approvals, :get_approval!, ["approval-1"])
    approver = apply(fixtures, :user!, [:approver])
    member = apply(fixtures, :user!, [:member])

    assert {:ok, approved} = apply(approvals, :approve, [approval, approver])
    assert approved.status == :approved
    assert approved.reviewed_by == approver.id

    assert {:error, :forbidden} = apply(approvals, :approve, [approval, member])
  end

  test "fixture realism stays minimal with one account, two users, and a small approval queue" do
    fixtures_mod = CrosswakeExample.SaaSPortal.Fixtures
    accounts = CrosswakeExample.SaaSPortal.Accounts
    approvals = CrosswakeExample.SaaSPortal.Approvals
    fixtures = apply(fixtures_mod, :seed, [])

    assert fixtures.account.name == "Northwind Workspace"
    assert Enum.map(fixtures.users, & &1.role) |> Enum.sort() == [:approver, :member]
    assert length(fixtures.approvals) == 3

    assert Enum.all?(fixtures.approvals, fn approval ->
             approval.account_id == fixtures.account.id and approval.status in [:pending, :approved]
           end)

    assert %{id: "acct-north"} = apply(accounts, :get_account!, ["acct-north"])
    assert Enum.count(apply(approvals, :list_approvals, ["acct-north"])) == 3
  end

  test "the five LiveViews render one coherent approvals-led SaaS companion lane" do
    fixtures_mod = CrosswakeExample.SaaSPortal.Fixtures
    fixtures = apply(fixtures_mod, :seed, [])
    user = apply(fixtures_mod, :user!, [:approver])

    dashboard_socket =
      base_socket(user, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.DashboardLive)

    dashboard_html = render_html(CrosswakeExample.SaaSPortal.DashboardLive, dashboard_socket.assigns)
    assert dashboard_html =~ "Northwind mobile approvals"
    assert dashboard_html =~ "Account health"

    account_socket =
      base_socket(user, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.AccountLive)
      |> handle_params!(CrosswakeExample.SaaSPortal.AccountLive, %{"id" => "acct-north"})

    account_html = render_html(CrosswakeExample.SaaSPortal.AccountLive, account_socket.assigns)
    assert account_html =~ "Account health"
    assert account_html =~ "Pending approvals"

    approvals_socket =
      base_socket(user, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.ApprovalsLive)

    approvals_html = render_html(CrosswakeExample.SaaSPortal.ApprovalsLive, approvals_socket.assigns)
    assert approvals_html =~ "Approvals queue"
    assert approvals_html =~ "server-authoritative action"

    settings_socket =
      base_socket(user, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.SettingsLive)

    settings_html = render_html(CrosswakeExample.SaaSPortal.SettingsLive, settings_socket.assigns)
    assert settings_html =~ "Profile settings"
    assert settings_html =~ "Route unavailable remains explicit"
  end

  test "approval detail keeps the write path server-authoritative and emits the bounded haptics request on success" do
    fixtures_mod = CrosswakeExample.SaaSPortal.Fixtures
    fixtures = apply(fixtures_mod, :seed, [])
    approver = apply(fixtures_mod, :user!, [:approver])
    member = apply(fixtures_mod, :user!, [:member])

    approver_socket =
      base_socket(approver, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.ApprovalLive)
      |> handle_params!(CrosswakeExample.SaaSPortal.ApprovalLive, %{"id" => "approval-1"})
      |> handle_event!(CrosswakeExample.SaaSPortal.ApprovalLive, "approve", %{})

    assert approver_socket.assigns.approval.status == :approved
    assert approver_socket.assigns.approval.reviewed_by == approver.id
    assert approver_socket.assigns.approval_notice =~ "Phoenix remains the authority"
    assert approver_socket.assigns.bridge_request["command"] == "haptics.impact"

    approval_html = render_html(CrosswakeExample.SaaSPortal.ApprovalLive, approver_socket.assigns)
    assert approval_html =~ "Approval complete"
    assert approval_html =~ "crosswakeBridge"
    assert approval_html =~ "approval-haptics-approval-1"

    member_socket =
      base_socket(member, fixtures.account)
      |> mount!(CrosswakeExample.SaaSPortal.ApprovalLive)
      |> handle_params!(CrosswakeExample.SaaSPortal.ApprovalLive, %{"id" => "approval-1"})
      |> handle_event!(CrosswakeExample.SaaSPortal.ApprovalLive, "approve", %{})

    assert member_socket.assigns.approval.status == :pending
    assert member_socket.assigns.approval_error == "Approver role required at the action boundary."
    assert member_socket.assigns.bridge_request == nil
  end

  test "the base checked-in proof entrypoint layers in the SaaS lane" do
    example_host_script = File.read!("script/verify_phase5_example_hosts.sh")

    assert example_host_script =~ "test/crosswake/proof/adopter_profile_contract_test.exs"
    assert example_host_script =~ "test/crosswake/proof/phase7_saas_lane_test.exs"
    assert example_host_script =~ "test/crosswake/proof/phase5_proof_lane_test.exs"
  end

  defp base_socket(user, account) do
    %Phoenix.LiveView.Socket{}
    |> Component.assign(:current_saas_user, user)
    |> Component.assign(:current_saas_account, account)
    |> Component.assign(:saas_role, user.role)
  end

  defp mount!(socket, module) do
    assert {:ok, mounted_socket} = module.mount(%{}, %{}, socket)
    mounted_socket
  end

  defp handle_params!(socket, module, params) do
    assert {:noreply, updated_socket} = module.handle_params(params, nil, socket)
    updated_socket
  end

  defp handle_event!(socket, module, event, params) do
    assert {:noreply, updated_socket} = module.handle_event(event, params, socket)
    updated_socket
  end

  defp render_html(module, assigns) do
    assigns
    |> module.render()
    |> LiveViewTest.rendered_to_string()
  end
end
