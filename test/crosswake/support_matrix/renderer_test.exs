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

  test "first adopter readiness keeps policy completion separate from host and device proof" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "policy-contract complete"
    assert guide =~ "adopter-instance input remains `unknown_blocking`"
    assert guide =~ "unknown_blocking` blocks host-proof and physical-device promotion"
    assert guide =~ "Route-local safety fields do not inherit from surface defaults."
    assert guide =~ "host-owned `gated_by` seam"
    assert guide =~ "v20 is stopped/partial; it has no shipped support claim."
    assert guide =~ "one offline island"
    assert guide =~ "Generic sync is not claimed."
  end

  test "first adopter readiness preserves Android freeze and makes no unsupported proof claim" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~
             "Android is frozen at its existing generator, Maven, JVM, and shared-vector posture."

    assert guide =~
             "Example-host, simulator, package-version, and policy-contract evidence do not prove an external host or physical device."

    refute guide =~ "First B2C Adopter"
    refute guide =~ "first-adopter"
  end

  test "first adopter readiness renders only the retained corrected physical evidence claim" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~
             "| physical-iPhone offline study | device evidence | A committed corrected-provenance physical-device record and deterministic authority gates support one first adopter offline-study flow. |"

    for non_claim <- [
          "It does not claim Android.",
          "It does not claim background replay or sync.",
          "It does not claim generic storage or sync.",
          "It does not claim multiple offline islands.",
          "It does not claim simulator substitution.",
          "It does not claim every iPhone."
        ] do
      assert guide =~ non_claim
    end

    refute guide =~ "First B2C Adopter"
  end

  test "generated guide renders support-truth labels with proof and non-proof meanings" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Support-Truth Label Legend"

    for label <- [
          "merge-blocking proof",
          "advisory evidence",
          "checked-in public-coordinate proof",
          "local-dev proof",
          "generated public-coordinate proof",
          "JVM hermetic proof",
          "emulator evidence",
          "device evidence",
          "verification-required",
          "rebuild-required"
        ] do
      assert guide =~ label
    end

    assert guide =~ "supported` is not the same as device-verified"
    assert guide =~ "JVM hermetic proof is not emulator evidence or physical-device proof"
    assert guide =~ "Emulator evidence is not physical-device proof"
    assert guide =~ "It is not generated public-coordinate proof"
    assert guide =~ "Visual collateral is not correctness proof by itself"
    assert guide =~ "Device/provider evidence is not backend/session authority"
    assert guide =~ "Cached read-only is not offline mutation"
    assert guide =~ "Bridge is not high-frequency or mutation authority"
  end

  test "generated guide renders capability-family support from manifest-derived metadata" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Capability Families"

    assert guide =~
             "| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |"

    assert guide =~ "| deep_link | activation | activation_first | supported | supported | core |"

    assert guide =~
             "| app_info | bounded_bridge | bounded_bridge | supported | verification required | core |"

    assert guide =~
             "| haptics | bounded_bridge | bounded_bridge | supported | verification required | core |"

    assert guide =~ "| share | bounded_bridge | bounded_bridge | supported | supported | core |"

    assert guide =~
             "| media_capture | native_screen | native_screen | supported | verification required | companion |"

    assert guide =~
             "| notification_token | bounded_bridge | provider_snapshot | supported | verification required | companion |"

    assert guide =~
             "| permissions.status | bounded_bridge | alias_snapshot | supported | verification required | core |"

    assert guide =~
             "| paywall_entry | backend_seam | backend_seam | supported | verification required | core | merge-blocking"

    assert guide =~
             "| purchase_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking"

    assert guide =~
             "| restore_intent | backend_seam | backend_seam | supported | verification required | core | merge-blocking"

    assert guide =~
             "| entitlement_snapshot | backend_seam | backend_seam | supported | verification required | core | merge-blocking"

    assert guide =~
             "| reconciliation_evidence | backend_seam | backend_seam | supported | verification required | core | merge-blocking"

    assert guide =~ "freshness posture (fresh/stale/unknown) surfaced before access checks"

    assert guide =~
             "Fail closed for access decisions when snapshot freshness is stale or unknown until refreshed backend authority is available"

    assert guide =~
             "device/storefront/webhook/support evidence as non-authoritative reconciliation input"

    assert guide =~
             "pending_purchase, pending_restore, and awaiting_verification remain non-granting until backend projection refreshes authority"

    assert guide =~
             "StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass"

    refute String.downcase(guide) =~ "revenuecat"

    assert guide =~
             "| document_scan | native_screen | native_screen | unsupported | unsupported | defer |"

    assert guide =~
             "| scanner | native_screen | native_screen | unsupported | unsupported | defer |"

    refute guide =~
             "| document_scan | native_screen | native_screen | supported | supported | defer |"

    refute guide =~ "| scanner | native_screen | native_screen | supported | supported | defer |"
  end

  test "deferred capture and device families do not render as shipped support by package class alone" do
    guide = Renderer.render(SupportMatrix.canonical())

    for family <- ["document_scan", "scanner"] do
      assert guide =~
               "| #{family} | native_screen | native_screen | unsupported | unsupported | defer |"

      refute guide =~
               "| #{family} | native_screen | native_screen | supported | supported | defer |",
             "#{family} must stay unsupported until native runtime and proof posture ship"
    end
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
    assert guide =~ "| Standalone native shell core packages | core |"
    assert guide =~ "## Release And Versioning Policy"
    assert guide =~ "package versions alone do not define support truth"
    assert guide =~ "manifest_schema_version"
    assert guide =~ "bridge_protocol_version"
    assert guide =~ "native_runtime_version"
    assert guide =~ "## Change Classes"

    assert guide =~
             "| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |"

    assert guide =~ "| docs-only |"
    assert guide =~ "| core-only/no native rebuild |"
    assert guide =~ "| compatibility-bump only |"
    assert guide =~ "| native or companion rebuild required |"
  end

  test "generated guide renders phase 51 action classes, promotion rules, and public non-claims" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "## Action Classes"
    assert guide =~ "## Promotion Rules"
    assert guide =~ "## Public Non-Claims And Rough Edges"

    for action_class <- [
          "docs_only",
          "route_manifest",
          "compatibility",
          "native_shell",
          "companion_native",
          "provider_adapter"
        ] do
      assert guide =~ action_class
    end

    for claim_id <- [
          "shell.ios.generated_project",
          "shell.android.generated_project",
          "notification_token.provider_snapshot",
          "auth.sigra.session_authority",
          "purchase_intent.provider.storekit",
          "purchase_intent.provider.play_billing"
        ] do
      assert guide =~ claim_id
    end

    assert guide =~
             "StoreKit and Play Billing provider adapter seams are shipped, but provider/storefront proof remains advisory until promotion criteria pass"

    assert guide =~
             "Sigra session-authority route evaluation, Phase 55 handoff ticket/server-record contract machinery, Phase 56 step-up intent plus Plug/LiveView ceremony, Phase 57 OAuth/passkey/native auth-return boundary contracts, Phase 58 auth telemetry/security closeout, and Phase 73 auth-sensitive admin workflow proof are shipped"

    assert guide =~ "auth.handoff.*"
    assert guide =~ "auth.step_up_intent.*"
    assert guide =~ "auth.return.*"
    assert guide =~ "[:crosswake, :auth, ...]"
    assert guide =~ "persistent shell session state does not grant admin access"
    assert guide =~ "auth.sigra.session_authority"
    assert guide =~ "diag.auth.sigra_session_authority"

    assert guide =~ "notification-open workflow proof is hermetic route activation proof"
    assert guide =~ "RouteGate and Sigra decide activation"
    assert guide =~ "token/open evidence is not auth authority"
    assert guide =~ "APNs/FCM delivery is not part of this proof"

    assert guide =~
             "Standalone native shell core packages are consumed by generated host-owned wrappers"
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
    assert guide =~
             "| paywall_entry | phoenix_owned | route_declaration; backend_reconciliation |"

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

  test "guides/support_matrix.md is byte-identical to canonical renderer output after Plan 23-02 enrichment" do
    # Plan 23-02 enriched commerce corridor entries with prerequisite_classes,
    # rebuild_requirement, and proof_class metadata, and added three new columns to
    # the Commerce Corridors section. Plan 23-03 explicitly re-asserts this byte-identity
    # so a reviewer or future planner can see the guarantee in the test suite without
    # having to reason through the broader guide parity test below.
    rendered = Renderer.render(SupportMatrix.canonical())
    on_disk = File.read!("guides/support_matrix.md")

    assert rendered == on_disk,
           "guides/support_matrix.md drifted from canonical Renderer output; regenerate before merging"

    # Determinism guard: re-rendering must produce identical bytes (no nondeterministic ordering).
    assert rendered == Renderer.render(SupportMatrix.canonical())
  end

  test "renderer escapes pipe characters in support entry cells so future data cannot rip the markdown column layout" do
    # Synthesizes a SupportMatrix with a notes string containing a literal
    # pipe character. Without escaping, the rendered row would silently split
    # into extra columns and break GitHub markdown parsing for the entire
    # Phoenix section. Asserts the renderer emits the escaped form (`\|`)
    # and does not produce a row with a raw inline `|` in the notes cell.
    base = SupportMatrix.canonical()

    risky_phoenix =
      Enum.map(base.phoenix, fn entry ->
        %{entry | notes: "alpha | beta"}
      end)

    matrix = %{base | phoenix: risky_phoenix}

    rendered = Renderer.render(matrix)

    assert rendered =~ "alpha \\| beta",
           "renderer must escape `|` in interpolated cells"

    refute rendered =~ "alpha | beta |",
           "rendered output still contains an unescaped pipe in a cell, which would break the markdown table layout"
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

  test "NAV-06 renders the bounded iOS posture and frozen Android boundary" do
    guide = Renderer.render(SupportMatrix.canonical())

    for claim <- [
          "bounded iOS-only compiled topology, typed stack protocol, UIKit host composition, marker/insets, and generated host proof are verified in Phase 161.1; simulator advisory evidence remains distinct, TODO-002/adopter topology is unknown_blocking, and physical-iPhone promotion is Phase 162 only.",
          "Bounded iOS shell evidence excludes generic navigation, native leaf rendering, arbitrary restoration/modal breadth, and browser-history authority.",
          "Android retains its frozen generator, Maven, JVM, and shared-vector posture.",
          "Android is frozen during first adopter iOS readiness: no new feature, parity, device, template, or release claim."
        ] do
      assert guide =~ claim
    end
  end
end
