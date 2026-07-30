defmodule Crosswake.Proof.Phase7SaaSLaneTest do
  use ExUnit.Case, async: false

  # Depends on the checked-in example Phoenix app (CrosswakeExample.*) being
  # compiled. Run by phase5-proof.yml, which builds the example host first;
  # excluded from the hermetic hex-page-proof full-suite run via --exclude.
  @moduletag :requires_example_host

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Crosswake.Manifest

  @endpoint CrosswakeExample.Endpoint

  @saas_routes %{
    "saas-dashboard" => "/saas/dashboard",
    "saas-account" => "/saas/accounts/:id",
    "saas-approvals" => "/saas/approvals",
    "saas-approval" => "/saas/approvals/:id",
    "saas-profile-settings" => "/saas/settings/profile"
  }

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    Crosswake.TestSupport.ExampleHost.start_saas_repo!()
    Crosswake.TestSupport.ExampleHost.start_endpoint!()
    :ok
  end

  setup do
    # The SaaS approvals lane is Ecto/SQLite-backed; reseed to a pristine fixture
    # set before each test so the write-path (approve) test cannot leak state.
    # Dynamic dispatch avoids compile-time coupling to the example app.
    approvals = CrosswakeExample.SaaSPortal.Approvals
    apply(approvals, :reset!, [])
    :ok
  end

  test "shared example host exposes the locked base SaaS route set under /saas" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    saas_routes = Map.take(manifest.routes, Map.keys(@saas_routes))

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

  # D-61/D-62 (Phase 154): a route DECLARES a capability family ("haptics"); the dotted
  # form ("haptics.impact") is the wire command that family resolves to, and it is the
  # library's business, never a router literal. This assertion carried the pre-D-61
  # vocabulary until now — the router flipped in 94151bd5 and this gated lane, which no
  # local `mix test` runs by default, was not re-run against it.
  test "only the approval detail route declares the bounded haptics capability" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    assert manifest.routes["saas-approval"].capabilities == ["haptics"]

    # Guard the decision, not just the string: the declaration must stay in family form,
    # so a future edit that re-inlines a wire command id fails here rather than silently
    # reintroducing the drift D-61 removed.
    refute Enum.any?(manifest.routes["saas-approval"].capabilities, &String.contains?(&1, "."))

    for route_id <- Map.keys(@saas_routes) -- ["saas-approval"] do
      assert manifest.routes[route_id].capabilities == []
    end
  end

  test "host-owned auth keeps one signed-in boundary and one lightweight role split" do
    auth = CrosswakeExample.SaaSPortal.Auth
    fixtures_mod = CrosswakeExample.SaaSPortal.Fixtures

    assert apply(auth, :session_key, []) == "saas_portal_user_id"
    assert Enum.sort(apply(auth, :roles, [])) == [:approver, :member, :owner]

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

    assert router =~ ~r/pipe_through\(?\[:browser, :saas_portal\]\)?/
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
    assert Enum.map(fixtures.users, & &1.role) |> Enum.sort() == [:approver, :member, :owner]
    assert length(fixtures.approvals) == 3

    assert Enum.all?(fixtures.approvals, fn approval ->
             approval.account_id == fixtures.account.id and
               approval.status in [:pending, :approved]
           end)

    assert %{id: "acct-north"} = apply(accounts, :get_account!, ["acct-north"])
    assert Enum.count(apply(approvals, :list_approvals, ["acct-north"])) == 3
  end

  test "the five LiveViews render one coherent approvals-led SaaS companion lane" do
    conn = conn_for(:approver)

    {:ok, _view, dashboard_html} = live(conn, "/saas/dashboard")
    assert dashboard_html =~ "Northwind mobile approvals"
    assert dashboard_html =~ "Account posture"

    {:ok, _view, account_html} = live(conn, "/saas/accounts/acct-north")
    assert account_html =~ "Read-only account context"
    assert account_html =~ "Approval threshold"

    {:ok, _view, approvals_html} = live(conn, "/saas/approvals")
    assert approvals_html =~ "Approvals queue"
    assert approvals_html =~ "server-authoritative approval action"

    {:ok, _view, settings_html} = live(conn, "/saas/settings/profile")
    assert settings_html =~ "Profile settings"
    assert settings_html =~ "Settings posture"
  end

  # A real Phoenix.LiveViewTest round trip since Phase 154. This route attaches
  # Crosswake.Bridge in mount/3, and the dispatch runs through the LiveView lifecycle
  # hooks attach/1 registers — machinery a hand-built %Phoenix.LiveView.Socket{} does
  # not have (no :lifecycle private key) and that calling module.handle_event/3
  # directly bypasses entirely. Driving the mounted route is the only way this lane
  # can observe the seam rather than a socket the framework would never produce.
  # Mirrors the same migration made for the example host's own copy of this test.
  test "approval detail keeps the write path server-authoritative and emits the bounded haptics request on success" do
    approvals = CrosswakeExample.SaaSPortal.Approvals
    approver = apply(CrosswakeExample.SaaSPortal.Fixtures, :user!, [:approver])

    {:ok, approver_view, initial_html} = live(conn_for(:approver), "/saas/approvals/approval-1")

    # The page carries the bridge element itself, so a shell-side hook has something to
    # bind to. Before Phase 154 this route hand-rolled an inline dispatch script instead.
    assert initial_html =~ ~s(id="crosswake-bridge")
    assert initial_html =~ ~s(phx-hook="CrosswakeBridge")
    assert initial_html =~ "No haptics request sent"
    refute initial_html =~ "Command (wire protocol)"

    approved_html = render_click(approver_view, "approve")

    # The envelope the seam actually built, observed as it crosses the seam. This is the
    # post-154 replacement for the old assertion on a hand-built `bridge_request` assign
    # and its correlation id in the DOM — correlation ids are library-internal now (D-20).
    assert_push_event(approver_view, "crosswake:bridge", envelope)
    assert envelope["command"] == "haptics.impact"
    assert envelope["capability"] == "haptics"
    assert envelope["route_id"] == "saas-approval"

    # Server authority: the decision is committed by Phoenix, independent of any shell.
    approved = apply(approvals, :get_approval!, ["approval-1"])
    assert approved.status == :approved
    assert approved.reviewed_by == approver.id

    assert approved_html =~ "Server-authoritative decision"
    assert approved_html =~ "Phoenix recorded the decision"

    # The evidence panel left its idle state and is projecting a real dispatch (D-74).
    refute approved_html =~ "No haptics request sent"
    assert approved_html =~ "Capability (route policy)"
    assert approved_html =~ "Command (wire protocol)"

    # The approver's approval above persisted to the DB; reseed to a pristine
    # pending approval-1 so the member path tests authorization denial in
    # isolation (was fixture-per-mount before the SQLite persistence layer).
    apply(approvals, :reset!, [])

    {:ok, member_view, _member_html} = live(conn_for(:member), "/saas/approvals/approval-1")
    denied_html = render_click(member_view, "approve")

    assert denied_html =~
             "Approver role required. Phoenix kept the request unchanged at the server boundary."

    assert apply(approvals, :get_approval!, ["approval-1"]).status == :pending

    # No server authority, no shell request: the refusal happens before the seam.
    refute_push_event(member_view, "crosswake:bridge", %{})
  end

  test "the base checked-in proof entrypoint layers in the SaaS lane" do
    example_host_script = File.read!("script/verify_phase5_example_hosts.sh")

    assert example_host_script =~ "test/crosswake/proof/adopter_profile_contract_test.exs"
    assert example_host_script =~ "test/crosswake/proof/phase7_saas_lane_test.exs"
    assert example_host_script =~ "test/crosswake/proof/phase5_proof_lane_test.exs"
  end

  # Signs in through the host's own session boundary rather than assigning around it, so
  # the route's live_session on_mount hook runs for real.
  defp conn_for(role) do
    user = apply(CrosswakeExample.SaaSPortal.Fixtures, :user!, [role])
    session_key = apply(CrosswakeExample.SaaSPortal.Auth, :session_key, [])

    Plug.Test.init_test_session(build_conn(), %{session_key => user.id})
  end
end
