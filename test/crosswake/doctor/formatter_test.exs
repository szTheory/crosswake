defmodule Crosswake.Doctor.FormatterTest do
  use ExUnit.Case, async: true
  alias Crosswake.Doctor.Check
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

  test "formats commerce corridor findings with canonical IDs and fallback hints" do
    report = %{
      status: :error,
      findings: [
        %Check{
          severity: :error,
          code: "commerce.corridor.runtime_incompatible",
          check: "commerce_corridor",
          message: "route billing triggered commerce.corridor.runtime_incompatible",
          hint: "return_to_phoenix_guidance",
          details: %{
            corridor_ref: "subscription_default",
            role: :purchase_intent,
            denial_code: "commerce.corridor.runtime_incompatible",
            fallback_hint: "return_to_phoenix_guidance"
          }
        }
      ]
    }

    output = Formatter.render(report)

    assert output =~ "commerce.corridor.runtime_incompatible"
    assert output =~ "corridor_ref=subscription_default"
    assert output =~ "role=purchase_intent"
    assert output =~ "denial_code=commerce.corridor.runtime_incompatible"
    assert output =~ "fallback_hint=return_to_phoenix_guidance"
  end
end
