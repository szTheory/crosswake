defmodule Crosswake.SupportMatrix.RendererTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix
  alias Crosswake.SupportMatrix.Renderer

  test "renderer emits deterministic markdown and preserves created, reused, and updated semantics" do
    matrix = SupportMatrix.canonical()

    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-support-matrix-#{System.unique_integer([:positive])}.md"
      )

    File.rm(path)

    rendered_once = Renderer.render(matrix)
    rendered_twice = Renderer.render(matrix)

    assert rendered_once == rendered_twice
    assert {:ok, :created} = Renderer.write(path, matrix)
    assert {:ok, :reused} = Renderer.write(path, matrix)

    updated_matrix = SupportMatrix.canonical(ios_version: "18.0")
    assert {:ok, :updated} = Renderer.write(path, updated_matrix)
  end

  test "generated guide renders the exact public support statuses from canonical truth" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "supported"
    assert guide =~ "verification required"
    assert guide =~ "unsupported"
  end

  test "generated guide renders capability-family support from manifest-derived metadata" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Capability Families"
    assert guide =~ "| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |"
    assert guide =~ "| deep_link | activation | activation_first | supported | supported | core |"
    assert guide =~ "| app_info | bounded_bridge | bounded_bridge | supported | verification required | core |"
    assert guide =~ "| haptics | bounded_bridge | bounded_bridge | supported | verification required | core |"
    assert guide =~ "| share | bounded_bridge | bounded_bridge | supported | supported | core |"
    assert guide =~ "| media_capture | native_screen | native_screen | supported | verification required | companion |"
    assert guide =~ "| notification_token | bounded_bridge | provider_snapshot | supported | verification required | companion |"
    assert guide =~ "| permissions.status | bounded_bridge | alias_snapshot | supported | verification required | core |"
    assert guide =~ "| paywall_entry | backend_seam | backend_seam | supported | verification required | core | merge-blocking"
    assert guide =~ "| purchase_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking"
    assert guide =~ "| restore_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking"
    assert guide =~ "| entitlement_snapshot | backend_seam | backend_seam | supported | verification required | core | merge-blocking"
    assert guide =~ "| reconciliation_evidence | backend_seam | backend_seam | supported | verification required | core | merge-blocking"
    assert guide =~ "freshness posture (fresh/stale/unknown) surfaced before access checks"
    assert guide =~
             "Fail closed for access decisions when snapshot freshness is stale or unknown until refreshed backend authority is available"
    assert guide =~ "device/storefront/webhook/support evidence as non-authoritative reconciliation input"
    assert guide =~
             "pending_purchase, pending_restore, and awaiting_verification remain non-granting until backend projection refreshes authority"
    refute String.downcase(guide) =~ "storekit"
    refute String.downcase(guide) =~ "play_billing"
    refute String.downcase(guide) =~ "revenuecat"
    assert guide =~ "| scanner | native_screen | native_screen | supported | supported | defer |"
  end

  test "generated support output does not present evidence as direct authority grant" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "non-authoritative reconciliation input"
    refute String.downcase(guide) =~ "evidence is a direct authority grant"
    refute String.downcase(guide) =~ "pending_purchase grants authority"
  end

  test "generated guide renders packaging ledger, release policy, and change classes from typed support truth" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Packaging Ledger"
    assert guide =~ "| Surface | Class | Why | Release Burden | Public Guide |"
    assert guide =~ "| Checked-in example hosts and install walkthroughs | example/docs-only |"
    assert guide =~ "| Standalone public shell packages | defer |"
    assert guide =~ "## Release And Versioning Policy"
    assert guide =~ "package versions alone do not define support truth"
    assert guide =~ "manifest_schema_version"
    assert guide =~ "bridge_protocol_version"
    assert guide =~ "native_runtime_version"
    assert guide =~ "## Change Classes"
    assert guide =~ "| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |"
    assert guide =~ "| docs-only |"
    assert guide =~ "| core-only/no native rebuild |"
    assert guide =~ "| compatibility-bump only |"
    assert guide =~ "| native or companion rebuild required |"
  end

  test "generated guide renders commerce corridor support truth with canonical denial codes" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Commerce Corridors"
    assert guide =~
             "| corridor_role | owner_posture | prerequisite_classes | prerequisites | denial_codes | fallback_behavior | proof_class | rebuild_requirement |"
    assert guide =~ "| paywall_entry | phoenix_owned |"
    assert guide =~ "commerce.corridor.undeclared"
    assert guide =~ "| purchase_intent | native_or_companion_required |"
    assert guide =~ "commerce.corridor.runtime_incompatible"
  end

  test "commerce corridor rows expose proof_class, prerequisite_classes, and rebuild_requirement columns" do
    guide = Renderer.render(SupportMatrix.canonical())

    # proof_class appears on every commerce corridor row
    assert guide =~ "| paywall_entry | phoenix_owned | route_declaration; backend_reconciliation |"

    assert guide =~
             "| account_management | phoenix_owned | route_declaration; backend_reconciliation |"

    assert guide =~
             "| purchase_intent | native_or_companion_required | native_adapter; provider_setup; backend_reconciliation |"

    assert guide =~
             "| restore_intent | native_or_companion_required | native_adapter; provider_setup; backend_reconciliation |"

    # proof_class merge-blocking label appears on commerce corridor rows
    assert guide =~ "| merge-blocking | native_rebuild_required=false:"
    assert guide =~ "| merge-blocking | native_rebuild_required=true:"

    # rebuild_trigger text appears on the corridor row
    assert guide =~
             "Phoenix-owned paywall changes do not require a native shell rebuild"

    assert guide =~ "Native adapter or provider SDK code changes require rebuilding"
    assert guide =~ "Native restore choreography or provider SDK code changes require rebuilding"

    # prerequisite_classes are rendered as semicolon-separated atom names
    assert guide =~ "route_declaration; backend_reconciliation"
    assert guide =~ "native_adapter; provider_setup; backend_reconciliation"
  end

  test "guides remain mechanically checked against canonical support truth and phase 3 boundaries" do
    assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())

    compatibility = File.read!("guides/compatibility.md")
    install = File.read!("guides/install.md")

    assert compatibility =~ "Runtime ownership"
    assert compatibility =~ "manifest_schema_version"
    assert compatibility =~ "bridge_protocol_version"
    assert compatibility =~ "native_runtime_version"
    assert compatibility =~ "Package Versions Versus Compatibility Axes"
    assert compatibility =~ "Companion Compatibility Contract"
    assert compatibility =~ "Release Choreography"
    assert compatibility =~ "Runtime Line Rules"
    assert compatibility =~ "bundled"
    assert compatibility =~ "cached"
    assert compatibility =~ "remote"
    assert compatibility =~ "fail-closed"
    assert compatibility =~ "package versions alone"

    assert install =~ "mix crosswake.doctor"
    assert install =~ "guides/compatibility.md"
    assert install =~ "guides/support_matrix.md"
    assert install =~ "Do I need to rebuild?"
  end
end
