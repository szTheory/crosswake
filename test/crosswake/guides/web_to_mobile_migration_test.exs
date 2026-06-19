defmodule Crosswake.Guides.WebToMobileMigrationTest do
  use ExUnit.Case, async: true

  @guide_path "guides/web_to_mobile_migration.md"

  @promotion_reasons [
    "degradable bounded native affordance",
    "cached read-only",
    "true local mutation/replay",
    "native-owned device session",
    "backend/provider authority",
    "explicit defer"
  ]

  @migration_passes [
    "Pass 1: Inventory routes by user job",
    "Pass 2: Assign the initial owner",
    "Pass 3: Add only required seams",
    "Pass 4: Run doctor and support checks",
    "Pass 5: Capture evidence for owner classes you use"
  ]

  @rejection_cases [
    "Do not move normal SaaS forms native just because the app is mobile",
    "Do not push high-frequency client authority through the bridge",
    "Do not call cached read-only pages offline mutation",
    "Do not treat device or provider events as authority without backend reconciliation",
    "Do not present local native hosts as generated public-coordinate proof"
  ]

  @guide_links [
    "guides/route_policy.md",
    "guides/bridge.md",
    "guides/offline.md",
    "guides/native_shell.md",
    "guides/capabilities.md",
    "guides/compatibility.md",
    "guides/support_matrix.md"
  ]

  test "migration guide exists for existing Phoenix SaaS route inventory" do
    guide = read_guide!()

    assert guide =~ "existing Phoenix SaaS"
    assert guide =~ "operational route inventory"
    assert guide =~ "default most routes to Phoenix/LiveView"
    assert guide =~ "Phoenix SaaS Portal"
    assert guide =~ "Selective Native Flow"
    assert guide =~ "Local-First Study Flow"
  end

  test "migration guide defaults to LiveView and names every promotion reason" do
    guide = read_guide!()

    assert guide =~ "Default most routes to `:live_view`"

    for reason <- @promotion_reasons do
      assert guide =~ reason
    end
  end

  test "migration guide follows the required pass structure" do
    guide = read_guide!()

    for pass <- @migration_passes do
      assert guide =~ pass
    end

    assert guide =~ "| Route | User job | Initial owner | Promotion reason | Required seams | Evidence |"
  end

  test "migration guide rejects common over-migration mistakes" do
    guide = read_guide!()

    assert guide =~ "Do Not Migrate This"

    for rejection <- @rejection_cases do
      assert guide =~ rejection
    end
  end

  test "migration guide links reference guides without becoming their replacement" do
    guide = read_guide!()

    for link <- @guide_links do
      assert guide =~ link
    end

    refute guide =~ "| Target | Version | Baseline | Proof Status | Proof Hook | Boundaries | Notes |"
    refute guide =~ "Crosswake.mutate"
    refute guide =~ "Sync Engine (Bridge)"
    refute guide =~ "XCLocalSwiftPackageReference"
  end

  defp read_guide! do
    assert File.exists?(@guide_path), "#{@guide_path} must exist"
    File.read!(@guide_path)
  end
end
