defmodule CrosswakeExample.E2E.SaaSSessionControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Plug.Conn

  alias CrosswakeExample.SaaSPortal.Auth

  @source_path Path.expand(
                 "../../../lib/crosswake_example/e2e/saas_session_controller.ex",
                 __DIR__
               )
  @router_path Path.expand("../../../lib/crosswake_example/router.ex", __DIR__)

  test "create accepts an allowlisted approver fixture and writes the SaaS session" do
    conn =
      build_conn(:post, "/_e2e/saas-session", %{"user_id" => "approver-1"})
      |> init_test_session(%{})
      |> CrosswakeExample.E2E.SaaSSessionController.create(%{"user_id" => "approver-1"})

    body = Jason.decode!(conn.resp_body)

    assert conn.status == 201
    assert get_session(conn, Auth.session_key()) == "approver-1"

    assert body == %{
             "account_id" => "acct-north",
             "role" => "approver",
             "user_id" => "approver-1"
           }
  end

  test "create ignores arbitrary role and account params" do
    conn =
      build_conn(:post, "/_e2e/saas-session", %{
        "user_id" => "member-1",
        "role" => "owner",
        "account_id" => "acct-admin"
      })
      |> init_test_session(%{})
      |> CrosswakeExample.E2E.SaaSSessionController.create(%{
        "user_id" => "member-1",
        "role" => "owner",
        "account_id" => "acct-admin"
      })

    body = Jason.decode!(conn.resp_body)

    assert conn.status == 201
    assert get_session(conn, Auth.session_key()) == "member-1"
    assert body["user_id"] == "member-1"
    assert body["role"] == "member"
    assert body["account_id"] == "acct-north"
    refute Map.has_key?(body, "session_ref")
    refute Map.has_key?(body, "provider")
    refute Map.has_key?(body, "token")
  end

  test "create rejects unknown or missing fixture users" do
    missing =
      build_conn(:post, "/_e2e/saas-session", %{})
      |> init_test_session(%{})
      |> CrosswakeExample.E2E.SaaSSessionController.create(%{})

    unknown =
      build_conn(:post, "/_e2e/saas-session", %{"user_id" => "owner-by-param"})
      |> init_test_session(%{})
      |> CrosswakeExample.E2E.SaaSSessionController.create(%{"user_id" => "owner-by-param"})

    assert missing.status == 422
    assert unknown.status == 404
    refute get_session(missing, Auth.session_key())
    refute get_session(unknown, Auth.session_key())
  end

  test "POST /_e2e/saas-session is compiled only inside the reserved e2e guard" do
    route =
      CrosswakeExample.Router
      |> Phoenix.Router.routes()
      |> Enum.find(&(&1.path == "/_e2e/saas-session"))

    assert route, "expected /_e2e/saas-session compiled in :test"
    assert route.verb == :post
    assert route.plug == CrosswakeExample.E2E.SaaSSessionController
    assert route.plug_opts == :create

    router_source = File.read!(@router_path)

    assert router_source =~
             ~r/if Mix\.env\(\) in \[:test, :e2e\] do.*post\("\/saas-session", SaaSSessionController, :create\)/s
  end

  test "controller source uses fixture allowlisting and the existing SaaS session helper" do
    source = File.read!(@source_path)

    assert source =~ "Fixtures.user_by_id(user_id)"
    assert source =~ "Auth.put_user_session(conn, user)"
    refute source =~ ~r/put_session\(conn,\s*"role"/
    refute source =~ ~r/put_session\(conn,\s*"account/
  end
end
