defmodule CrosswakeExample.LayoutsTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias CrosswakeExample.Showcase.Reset

  @endpoint CrosswakeExample.Endpoint

  setup do
    Reset.reset!()
    :ok
  end

  test "root layout loads shared token and app stylesheets for AdminPilot pages" do
    html =
      build_conn()
      |> get("/saas/dashboard")
      |> html_response(200)

    assert html =~ ~s(<link rel="stylesheet" href="/css/tokens.css")
    assert html =~ ~s(<link rel="stylesheet" href="/css/app.css")
    assert html =~ "adminpilot-shell"
  end

  test "shared stylesheets are served by the example host" do
    assert build_conn()
           |> get("/css/tokens.css")
           |> response(200) =~ "--cw-"

    assert build_conn()
           |> get("/css/app.css")
           |> response(200) =~ ".adminpilot-shell"
  end
end
