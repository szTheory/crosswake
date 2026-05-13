defmodule Crosswake.Policy.CompileErrorTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic
  alias Crosswake.Policy.Error

  test "compile failures include route context plus file and line information when available" do
    routes = [
      route("/adapter",
        helper: "camera",
        source: [file: "test/fixtures/sample_router.ex", line: 42],
        crosswake: [id: "camera", runtime: :adapter]
      )
    ]

    assert {:error, diagnostic} = Compiler.compile(routes)

    assert %Diagnostic{errors: [%Error{} = error]} = diagnostic
    assert error.path == "/adapter"
    assert error.helper == "camera"
    assert error.file == "test/fixtures/sample_router.ex"
    assert error.line == 42

    formatted = Diagnostic.format(diagnostic)

    assert formatted =~ "Route /adapter"
    assert formatted =~ "helper: camera"
    assert formatted =~ "test/fixtures/sample_router.ex:42"
  end

  test "diagnostics include offending keys, reasons, and minimal fix hints" do
    routes = [
      route("/broken",
        helper: "broken",
        source: [file: "test/fixtures/sample_router.ex", line: 18],
        crosswake: [id: "broken", runtime: :adapter]
      )
    ]

    assert {:error, diagnostic} = Compiler.compile(routes)

    formatted = Diagnostic.format(diagnostic)

    assert formatted =~ "offending key: :runtime"
    assert formatted =~ "runtime :adapter"
    assert formatted =~ "fix hint"
    assert formatted =~ ":live_view | :offline_island | :native_screen"
    assert formatted =~ ":adapter stays reserved for future extension"
  end

  test "multiple invalid routes aggregate into one diagnostic payload" do
    routes = [
      route("/duplicate-a",
        helper: "page",
        source: [file: "test/fixtures/router_a.ex", line: 10],
        crosswake: [id: "shared", runtime: :live_view]
      ),
      route("/duplicate-b",
        helper: "page",
        source: [file: "test/fixtures/router_b.ex", line: 20],
        crosswake: [id: "shared", runtime: :live_view]
      ),
      route("/invalid-offline",
        helper: "page",
        source: [file: "test/fixtures/router_b.ex", line: 30],
        crosswake: [id: "invalid", runtime: :offline_island, offline: :unavailable, security: :standard]
      )
    ]

    assert {:error, %Diagnostic{errors: errors} = diagnostic} = Compiler.compile(routes)
    assert length(errors) == 3

    formatted = Diagnostic.format(diagnostic)

    assert formatted =~ "found 3 route policy errors"
    assert formatted =~ "duplicate id"
    assert formatted =~ "offline_island routes cannot declare offline :unavailable"
    assert String.contains?(formatted, "router_a.ex:10")
    assert String.contains?(formatted, "router_b.ex:30")
  end

  defp route(path, opts) do
    %{
      path: path,
      metadata: %{crosswake: Keyword.fetch!(opts, :crosswake)},
      helper: Keyword.get(opts, :helper, "route"),
      verb: Keyword.get(opts, :verb, :get),
      source: Map.new(Keyword.get(opts, :source, []))
    }
  end
end
