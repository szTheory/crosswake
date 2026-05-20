defmodule Crosswake.Doctor.FormatterTest do
  use ExUnit.Case, async: true
  alias Crosswake.Doctor.Formatter
  alias Crosswake.SupportMatrix

  test "formats release policy with structured truth blocks" do
    manifest = %{
      crosswake_version: "0.1.0",
      compatibility: %{
        manifest_schema_version: "1.0",
        bridge_protocol_version: "1.0",
        native_runtime_version: "1"
      },
      support_matrix: SupportMatrix.canonical()
    }
    
    # We construct the same snapshot map Doctor builds
    snapshot = %{
      crosswake_version: manifest.crosswake_version,
      manifest_schema_version: manifest.compatibility.manifest_schema_version,
      bridge_protocol_version: manifest.compatibility.bridge_protocol_version,
      native_runtime_version: manifest.compatibility.native_runtime_version,
      package_version_truth: "Package versions alone do not determine support truth.",
      companion_requirement: "Future companions must declare minimum compatible ranges.",
      capability_families: manifest.support_matrix.capability_families,
      package_surfaces: manifest.support_matrix.package_surfaces,
      release_boundaries: manifest.support_matrix.release_boundaries,
      change_classes: manifest.support_matrix.change_classes
    }

    report = %{
      status: :ok,
      support: %{
        status: :supported,
        blocking_platforms: [],
        release_policy: snapshot
      }
    }

    output = Formatter.render(report)

    # Check some basic parts
    assert output =~ "release policy:"
    assert output =~ "crosswake_version=0.1.0"
    
    # Check new blocks
    assert output =~ "capability families:"
    assert output =~ "app_info: prerequisites=" || output =~ "app_info"
    
    assert output =~ "package surfaces:"
    assert output =~ "crosswake` primary package: class=core"

    assert output =~ "release boundaries:"
    assert output =~ "core: versioning=\"Independent SemVer"

    assert output =~ "change classes:"
    assert output =~ "docs-only: signal=\"No compatibility-axis or capability-version change"
  end
end
