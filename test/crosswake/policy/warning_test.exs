Code.require_file("../../support/router_fixtures.ex", __DIR__)
Code.require_file("../../support/compile_router_case.ex", __DIR__)

defmodule Crosswake.Policy.WarningTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Warning
  alias Crosswake.TestSupport.CompileRouterCase
  alias Crosswake.TestSupport.RouterFixtures.DefaultsRouter

  test "routers with unmanaged routes can emit an adoption warning without failing compilation" do
    {result, warning_output} = CompileRouterCase.compile_with_warning_output!(DefaultsRouter)

    assert [%Warning{} = warning] = result.warnings
    assert warning.unmanaged_paths == ["/public"]
    assert warning_output =~ "Crosswake incremental adoption warning"
    assert warning_output =~ "/public"
  end

  test "fully managed routers compile cleanly with no warnings" do
    routes = [
      route("/dashboard", helper: "page", crosswake: [id: "dashboard", runtime: :live_view]),
      route("/library", helper: "library", crosswake: [id: "library", runtime: :offline_island, offline: :cached_read_only, security: :standard])
    ]

    assert {:ok, %{routes: compiled_routes, warnings: []}} =
             Compiler.compile(routes, warn_on_unmanaged?: true, emit_warnings?: true)

    assert length(compiled_routes) == 2
  end

  test "warning output is distinct from hard validation failures" do
    routes = [
      route("/managed", helper: "page", crosswake: [id: "managed", runtime: :live_view]),
      route("/invalid", helper: "camera", crosswake: [id: "invalid", runtime: :adapter]),
      route("/unmanaged", helper: "public")
    ]

    assert {:error, diagnostic} = Compiler.compile(routes, warn_on_unmanaged?: true, emit_warnings?: true)
    assert warning_messages = DiagnosticWarningProxy.messages(diagnostic)
    assert warning_messages == []
  end

  defp route(path, opts) do
    metadata =
      case Keyword.fetch(opts, :crosswake) do
        {:ok, crosswake} -> %{crosswake: crosswake}
        :error -> %{}
      end

    %{
      path: path,
      metadata: metadata,
      helper: Keyword.get(opts, :helper, "route"),
      verb: Keyword.get(opts, :verb, :get)
    }
  end
end

defmodule DiagnosticWarningProxy do
  alias Crosswake.Policy.Diagnostic

  def messages(%Diagnostic{warnings: warnings}), do: Enum.map(warnings, & &1.message)
end
