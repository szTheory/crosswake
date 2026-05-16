Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.ManifestTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  test "manifest compilation from a managed router yields one route-first artifact keyed by route id" do
    assert {:ok, %{manifest: manifest, warnings: []}} = Manifest.compile(ManagedRouter)

    assert Map.keys(manifest.routes) == ["camera", "dashboard", "library"]
    assert manifest.routes["dashboard"].path == "/dashboard"
    assert manifest.routes["library"].offline == :cached_read_only
    assert manifest.routes["camera"].runtime == :native_screen
  end

  test "top-level manifest includes host, compatibility, support matrix, capability registry, and routes" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(ManagedRouter)

    assert manifest.manifest_schema_version == "1.0.0"
    assert manifest.crosswake_version == "0.1.0"
    assert manifest.host.manifest_sources == [:bundled, :cached, :remote]
    assert manifest.compatibility.bridge_protocol_version == "1.0.0"
    assert Map.has_key?(manifest.capability_registry, "camera")
    assert manifest.support_matrix.phoenix != []
  end
end
