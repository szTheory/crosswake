defmodule Crosswake.Guides.CapabilitiesTest do
  use ExUnit.Case, async: true

  @families [
    "deep_link",
    "app_info",
    "haptics",
    "share",
    "permissions.status",
    "notification_token",
    "media_capture",
    "scanner",
    "document_scan",
    "paywall_entry",
    "purchase_intent",
    "restore_intent",
    "entitlement_snapshot",
    "reconciliation_evidence"
  ]

  test "capability guide publishes the locked ownership-first rubric and family inventory" do
    guide = File.read!("guides/capabilities.md")

    assert guide =~ "Ownership-First Rubric"
    assert guide =~ "bounded_bridge"
    assert guide =~ "native_screen"
    assert guide =~ "backend_seam"
    assert guide =~ "defer"
    assert guide =~ "manifest-first shell activation truth"

    for family <- @families do
      assert guide =~ family
    end

    assert guide =~ "Package Boundary Rules"
    assert guide =~ "Packaging Ledger"
    assert guide =~ "Documentation Strength"
    assert guide =~ "Docs-Only Boundary"
    assert guide =~ "First Public Example Set"
    assert guide =~ "Package Class Examples"
    assert guide =~ "Explicit Defers"
    assert guide =~ "Package class does not override runtime ownership"
    assert guide =~ "not first-class supported"
    assert guide =~ "supported example"
    assert guide =~ "companion guidance"
    assert guide =~ "docs-only classification"
    assert guide =~ "### Route owner"
    assert guide =~ "### Why not core/companion"
    assert guide =~ "### Host-owned responsibilities"
    assert guide =~ "### Prerequisites"
    assert guide =~ "### Denial behavior"
    assert guide =~ "### Fallback behavior"
    assert guide =~ "### Native rebuild required"
    assert guide =~ "### Commerce Corridor Ownership Guidance"
    assert guide =~ "account_management"
    assert guide =~ "Phoenix-owned corridor surfaces"
    assert guide =~ "purchase_intent"
    assert guide =~ "restore_intent"
    assert guide =~ "core"
    assert guide =~ "companion"
    assert guide =~ "example/docs-only"
    assert guide =~ "silent web checkout or generic WebView fallback for digital goods is unsupported"
    end
  test "bridge and native shell guides stay aligned to the family-first capability posture" do
    bridge = File.read!("guides/bridge.md")
    native_shell = File.read!("guides/native_shell.md")

    assert bridge =~ "bounded bridge"
    assert bridge =~ "app_info"
    assert native_shell =~ "native screen"
    assert native_shell =~ "media_capture"
  end
end
