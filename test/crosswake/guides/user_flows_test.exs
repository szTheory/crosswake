defmodule Crosswake.Guides.UserFlowsTest do
  use ExUnit.Case, async: true

  test "user flow guide publishes the three locked jobs and route classification model" do
    guide = File.read!("guides/user_flows.md")

    assert guide =~ "Crosswake User Flows And Jobs To Be Done"
    assert guide =~ "Three Canonical Jobs"
    assert guide =~ "Job 1: Keep The Main Product Phoenix-Owned On Mobile"
    assert guide =~ "Job 2: Move One Device-Heavy Corridor Native Without Contaminating The Rest"
    assert guide =~
             "Job 3: Keep One Meaningful Workflow Useful Offline Without Pretending The Whole App Is Local-First"

    assert guide =~ "Trigger"
    assert guide =~ "Desired outcome"
    assert guide =~ "Happy-path flow"
    assert guide =~ "Degraded path"
    assert guide =~ "Why this boundary is right"

    assert guide =~ "Route-By-Route User Flows"
    assert guide =~ ":live_view"
    assert guide =~ ":offline_island"
    assert guide =~ ":native_screen"
    assert guide =~ "What Crosswake Deliberately Does Not Do"
    assert guide =~ "How To Decide If Your Flow Fits"
  end

  test "user flow guide is wired into the public guide graph without duplicating support matrix tables" do
    guide = File.read!("guides/user_flows.md")
    readme = File.read!("README.md")
    adopter_profiles = File.read!("guides/adopter_profiles.md")

    assert guide =~ "guides/adopter_profiles.md"
    assert guide =~ "guides/bridge.md"
    assert guide =~ "guides/packs.md"
    assert guide =~ "guides/offline.md"
    assert guide =~ "guides/commerce.md"
    assert guide =~ "guides/support_matrix.md"

    assert readme =~ "guides/user_flows.md"
    assert adopter_profiles =~ "guides/user_flows.md"

    refute guide =~ "| Target | Version | Status | Proof | Notes |"
    refute guide =~ "verification required"
  end

  test "planning memo locks gap ordering and diminishing-returns sections" do
    memo = File.read!(".planning/research/JTBD-AND-USER-FLOWS.md")

    assert memo =~ "Current JTBD Map"
    assert memo =~ "What Is Fully Covered Today"
    assert memo =~ "Biggest Gaps"
    assert memo =~ "Proposed Ordering"
    assert memo =~ "Diminishing Returns Boundary"
    assert memo =~ "Update Protocol"
    assert memo =~ "Commerce And Paywall Corridor"
    assert memo =~ "Notification-Driven Re-Entry Corridor"
    assert memo =~ "Auth And Account-Security Corridor"
    assert memo =~ "Operator Truth And Diagnostic Surfaces"
  end
end
