defmodule Crosswake.OperatorInspection.FormatterTest do
  # async: false — this module mutates the global :companions application env in
  # setup (put_env/delete_env). Post-DECOUPLE-03, SupportMatrix.auth_contract_truth/0
  # reads that env at runtime, so an async mutator races with async readers
  # (e.g. phase54) and intermittently empties their view of the registry. Every
  # other :companions-mutating test module is already async: false for this reason.
  use ExUnit.Case, async: false

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.TestSupport.StubCompanion
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  defmodule PageController do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule Phase51Router do
    use Crosswake.Router

    pipeline :browser do
      plug(:accepts, ["html"])
    end

    scope "/" do
      pipe_through(:browser)

      get(
        "/checkout",
        Elixir.Crosswake.OperatorInspection.FormatterTest.PageController,
        :checkout,
        crosswake: [
          id: "checkout",
          runtime: :live_view,
          security: :sensitive,
          commerce: [corridor: :subscription_default, role: :purchase_intent]
        ]
      )

      get(
        "/notifications",
        Elixir.Crosswake.OperatorInspection.FormatterTest.PageController,
        :notifications,
        crosswake: [
          id: "notifications",
          runtime: :live_view,
          security: :standard,
          capabilities: ["notification_token"]
        ]
      )

      get("/secure", Elixir.Crosswake.OperatorInspection.FormatterTest.PageController, :secure,
        crosswake: [
          id: "secure",
          runtime: :live_view,
          security: :sensitive,
          auth_min_level: :mfa,
          requires_recent_auth: 600
        ]
      )

      get("/gated", Elixir.Crosswake.OperatorInspection.FormatterTest.PageController, :gated,
        crosswake: [
          id: "gated",
          runtime: :live_view,
          security: :standard,
          gated_by: :stub_companion
        ]
      )
    end
  end

  test "renders concise route-first human output" do
    document =
      OperatorInspection.inspect(
        route_source: ManagedRouter,
        generated_at: "2026-05-31T00:00:00Z"
      )

    output = Formatter.render(document)

    assert output =~ "Crosswake operator inspection"
    assert output =~ "schema_version: 1.0.0"
    assert output =~ "source: manifest_schema_version=1.0.0"
    assert output =~ "routes:"
    assert output =~ "dashboard /dashboard runtime=live_view owner=phoenix"
    assert output =~ "library /library runtime=live_view owner=phoenix"
    assert output =~ "offline=cached_read_only cache_contract=yes island_contract=no"
    assert output =~ "camera /camera runtime=native_screen owner=native_screen"
    assert output =~ "capabilities: camera"
  end

  test "renders support and proof separately while showing rebuild action metadata" do
    previous = Application.get_env(:crosswake, :companions)
    Application.put_env(:crosswake, :companions, [StubCompanion])

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:crosswake, :companions)
      else
        Application.put_env(:crosswake, :companions, previous)
      end
    end)

    document =
      OperatorInspection.inspect(
        route_source: Phase51Router,
        generated_at: "2026-05-31T00:00:00Z"
      )

    output = Formatter.render(document)

    assert output =~
             "checkout /checkout runtime=live_view owner=phoenix support=verification_required proof=advisory"

    assert output =~
             "notifications /notifications runtime=live_view owner=phoenix support=verification_required proof=advisory"

    assert output =~
             "secure /secure runtime=live_view owner=phoenix support=verification_required proof=advisory"

    assert output =~
             "gated /gated runtime=live_view owner=companion support=verification_required proof=advisory"

    assert output =~ "change_class=native or companion rebuild required"
    assert output =~ "actions=native_shell, provider_adapter"
    assert output =~ "actions=companion_native"
  end
end
