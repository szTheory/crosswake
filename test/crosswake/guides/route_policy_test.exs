defmodule Crosswake.Guides.RoutePolicyTest do
  use ExUnit.Case, async: true

  @guide_path "guides/route_policy.md"
  @user_flows_path "guides/user_flows.md"

  @owner_classes [
    "plain `:live_view`",
    "`:live_view` with one bounded bridge affordance",
    "cached read-only",
    "`:offline_island`",
    "`:native_screen`",
    "backend/provider seam",
    "explicit defer"
  ]

  @truth_categories [
    "Manifest truth",
    "Doctor/support posture",
    "Denial/fallback behavior",
    "Rough edge"
  ]

  @route_policy_fields [
    "`runtime`",
    "`offline`",
    "`entry`",
    "`capabilities`",
    "`cache_contract`",
    "`island_contract`",
    "`packs`",
    "`sync`",
    "`transfers`",
    "`security`",
    "`gated_by`",
    "`on_unavailable`",
    "`auth_min_level`",
    "`requires_recent_auth`",
    "`auth_posture`",
    "`auth_return`",
    "`notification_open`"
  ]

  @guide_links [
    "guides/bridge.md",
    "guides/offline.md",
    "guides/native_shell.md",
    "guides/capabilities.md",
    "guides/support_matrix.md"
  ]

  test "route-policy guide exists and opens with the one-job route-owner frame" do
    guide = read_guide!()

    assert guide =~
             "Crosswake's one job is to declare, enforce, and diagnose which runtime owns each route as a Phoenix app crosses into mobile."

    assert guide =~ "Owner selection comes before syntax"
    assert guide =~ "Who should own this route?"
  end

  test "route-policy guide covers all owner classes and downstream truth categories" do
    guide = read_guide!()

    for owner_class <- @owner_classes do
      assert guide =~ owner_class
    end

    for category <- @truth_categories do
      assert guide =~ category
    end

    assert guide =~ "route unavailable"
    assert guide =~ "fail closed"
  end

  test "route-policy examples use current DSL fields without becoming a capability catalog" do
    guide = read_guide!()

    for field <- @route_policy_fields do
      assert guide =~ field
    end

    assert guide =~ "Route owner first, capability second"
    refute guide =~ "## Capability Catalog"
    refute guide =~ "generic plugin"
    refute guide =~ "native mobile with no native work"
    refute guide =~ "everything works offline"
    refute guide =~ "WebView wrapper"
  end

  test "route-policy guide links to canonical reference guides" do
    guide = read_guide!()

    for link <- @guide_links do
      assert guide =~ link
    end
  end

  test "user-flow JTBD ramp remains and links into the route-policy guide" do
    user_flows = File.read!(@user_flows_path)

    assert user_flows =~ "Who should own this route?"
    assert user_flows =~ "Job 1: Keep The Main Product Phoenix-Owned On Mobile"
    assert user_flows =~ "Job 2: Move One Device-Heavy Corridor Native Without Contaminating The Rest"
    assert user_flows =~
             "Job 3: Keep One Meaningful Workflow Useful Offline Without Pretending The Whole App Is Local-First"

    assert user_flows =~ "guides/route_policy.md"
  end

  defp read_guide! do
    assert File.exists?(@guide_path), "#{@guide_path} must exist"
    File.read!(@guide_path)
  end
end
