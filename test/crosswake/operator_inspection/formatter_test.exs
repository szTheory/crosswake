defmodule Crosswake.OperatorInspection.FormatterTest do
  use ExUnit.Case, async: true

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

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
end
