defmodule Crosswake.Doctor.FormatterTest do
  use ExUnit.Case, async: true
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.PublishReadiness
  alias Crosswake.SupportMatrix

  defmodule PageController do
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  defmodule ReadinessRouter do
    use Crosswake.Router

    scope "/" do
      get("/billing", Elixir.Crosswake.Doctor.FormatterTest.PageController, :billing,
        crosswake: [
          id: "billing",
          runtime: :live_view,
          security: :sensitive,
          commerce: [corridor: :subscription_default, role: :purchase_intent]
        ]
      )
    end
  end

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
            fallback_hint: "return_to_phoenix_guidance",
            proof_class: "merge_blocking"
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
    assert output =~ "[merge-blocking] commerce_corridor"
  end

  test "formats the commerce summary section with corridors, prerequisites, freshness, proof posture, and rebuild requirements" do
    report = %{
      status: :error,
      findings: [],
      commerce_summary: %{
        corridors: [
          %{
            route_id: "buy",
            corridor_ref: "subscription_default",
            role: "purchase_intent",
            owner_posture: "native_or_companion_required",
            native_rebuild_required: true,
            proof_class: :merge_blocking,
            advisory_provider_proof: true
          }
        ],
        prerequisites: %{
          "buy" => ["native or companion storefront corridor implemented"]
        },
        snapshot_freshness: :stale,
        proof_posture: %{
          merge_blocking: ["corridor_contract:buy", "commerce.entitlement.stale_snapshot"],
          advisory: ["provider_storefront:buy"]
        },
        rebuild_requirements: [
          %{route_id: "buy", corridor_ref: "subscription_default", role: "purchase_intent"}
        ]
      }
    }

    output = Formatter.render(report)

    assert output =~ "Commerce:"
    assert output =~ "snapshot_freshness: stale"
    assert output =~ "corridors:"
    assert output =~ "proof_class=[merge-blocking]"
    assert output =~ "prerequisites:"
    assert output =~ "native or companion storefront corridor implemented"
    assert output =~ "proof_posture:"

    assert output =~
             "[merge-blocking]: corridor_contract:buy, commerce.entitlement.stale_snapshot"

    assert output =~ "[advisory]: provider_storefront:buy"
    assert output =~ "rebuild_requirements:"
    assert output =~ "buy: corridor_ref=subscription_default, role=purchase_intent"
    assert output =~ "native rebuild required before commerce support advances"
  end

  test "format commerce summary section is omitted when commerce_summary is empty" do
    report = %{status: :ok, findings: [], commerce_summary: %{}}
    refute Formatter.render(report) =~ "Commerce:"
  end

  test "formatter does not crash when a commerce.corridor.* check carries nil details (WR-08)" do
    # %Check{} struct allows details: nil even though %{} is the default. A hand-
    # built Check (the test fixture pattern, see formatter_test.exs:62-79) with
    # nil details previously raised FunctionClauseError from the detail/2 calls
    # inside format_commerce_corridor_fields/1 and format_check_proof_class/1.
    report = %{
      status: :error,
      findings: [
        %Check{
          severity: :error,
          code: "commerce.corridor.runtime_incompatible",
          check: "commerce_corridor",
          message: "route billing triggered commerce.corridor.runtime_incompatible",
          hint: "return_to_phoenix_guidance",
          details: nil
        }
      ]
    }

    # Must not raise.
    output = Formatter.render(report)

    assert output =~ "commerce.corridor.runtime_incompatible"
    # Fallback values still appear when details is nil.
    assert output =~ "corridor_ref=unknown"
    assert output =~ "fallback_hint=return_to_phoenix_guidance"
  end

  test "formatter detail lookup preserves legitimate `false` values without falling through to the string-keyed slot (WR-09)" do
    # Map.get(...) || Map.get(...) silently overrode `false` at the atom-keyed
    # slot. Use Map.has_key?-based lookup so false survives. Today no commerce
    # finding stores a falsy detail, but advisory_provider_proof: false is a
    # natural future addition. Lock the contract now.
    report = %{
      status: :error,
      findings: [
        %Check{
          severity: :warning,
          code: "commerce.corridor.runtime_incompatible",
          check: "commerce_corridor",
          message: "route buy triggered commerce.corridor.runtime_incompatible",
          hint: "return_to_phoenix_guidance",
          details: %{
            corridor_ref: "subscription_default",
            role: :purchase_intent,
            denial_code: "commerce.corridor.runtime_incompatible",
            # Critical: atom-keyed false. Pre-fix this silently fell through
            # to the string-keyed "fallback_hint" slot and emitted whichever
            # value sat there (or nil → then `|| check.hint` kicked in,
            # giving "return_to_phoenix_guidance" instead of "false").
            fallback_hint: false,
            proof_class: "merge_blocking"
          }
        }
      ]
    }

    output = Formatter.render(report)

    assert output =~ "fallback_hint=false",
           "atom-keyed false must survive detail/2 lookup; got: #{output}"
  end

  test "commerce summary findings render their proof_class label inline" do
    report = %{
      status: :error,
      findings: [
        %Check{
          severity: :warning,
          code: "commerce.entitlement.stale_snapshot",
          check: "commerce_summary",
          message: "entitlement snapshot freshness is stale",
          hint: "refresh the backend entitlement projection",
          details: %{freshness: "stale", proof_class: "merge_blocking"}
        },
        %Check{
          severity: :warning,
          code: "commerce.corridor.native_rebuild_required",
          check: "commerce_summary",
          message:
            "route buy corridor subscription_default (purchase_intent) requires a native or companion rebuild",
          hint: "rebuild the corridor",
          details: %{
            route_id: "buy",
            corridor_ref: "subscription_default",
            role: "purchase_intent",
            proof_class: "merge_blocking"
          }
        }
      ]
    }

    output = Formatter.render(report)

    assert output =~ "[merge-blocking] commerce_summary (commerce.entitlement.stale_snapshot)"

    assert output =~
             "[merge-blocking] commerce_summary (commerce.corridor.native_rebuild_required)"
  end

  test "formats publish readiness as a concise sidecar section ordered by blocking posture" do
    publish_readiness =
      PublishReadiness.run(
        route_source: ReadinessRouter,
        cwd: File.cwd!(),
        generated_at: "2026-05-31T00:00:00Z",
        changelog_contents: "# Changelog\n\n## [0.1.0]\n"
      )

    output =
      Formatter.render(%{
        status: :error,
        findings: [],
        publish_readiness: publish_readiness
      })

    assert output =~ "Publish readiness"
    assert output =~ "status: not_ready"
    assert output =~ "diag.publish.changelog_missing_unreleased"
    assert output =~ "severity=error result=fail blocking=true"
    assert output =~ "claim_scope=Hex metadata and release/changelog truth"
    assert output =~ "docs=CHANGELOG.md"
    assert output =~ "remediation=Keep package metadata"
    assert output =~ "diag.provider.adapter_shipped_seams"
    assert output =~ "blocking=false"
  end
end
