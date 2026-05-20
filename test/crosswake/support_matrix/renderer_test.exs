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
    assert guide =~ "| Family | Owner | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |"
    assert guide =~ "| deep_link | bounded_bridge | core |"
    assert guide =~ "| app_info | bounded_bridge | core |"
    assert guide =~ "| haptics | bounded_bridge | core |"
    assert guide =~ "| share | bounded_bridge | core |"
    assert guide =~ "| media_capture | native_screen | companion |"
    assert guide =~ "| notification_token | bounded_bridge | companion |"
    assert guide =~ "| permissions.status | bounded_bridge | example/docs-only |"
    assert guide =~ "| paywall_entry | backend_seam | core | merge-blocking"
    assert guide =~ "| purchase_intent | backend_seam | core | merge-blocking"
    assert guide =~ "| restore_intent | backend_seam | core | merge-blocking"
    assert guide =~ "| entitlement_snapshot | backend_seam | core | merge-blocking"
    assert guide =~ "| reconciliation_evidence | backend_seam | core | merge-blocking"
    assert guide =~ "| scanner | native_screen | defer |"
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
