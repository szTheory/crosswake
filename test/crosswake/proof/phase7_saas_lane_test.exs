defmodule Crosswake.Proof.Phase7SaaSLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest
  @saas_routes %{
    "saas-dashboard" => "/saas/dashboard",
    "saas-account" => "/saas/accounts/:id",
    "saas-approvals" => "/saas/approvals",
    "saas-approval" => "/saas/approvals/:id",
    "saas-profile-settings" => "/saas/settings/profile"
  }

  setup_all do
    for path <- [
          "examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex",
          "examples/phoenix_host/lib/crosswake_example/router.ex"
        ] do
      Code.require_file(Path.expand(path, File.cwd!()))
    end

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
end
