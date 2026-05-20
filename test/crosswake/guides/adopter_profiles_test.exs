defmodule Crosswake.Guides.AdopterProfilesTest do
  use ExUnit.Case, async: true

  @matrix_header [
    "Profile",
    "Product shape",
    "Primary route classes",
    "Runtime ownership expectation",
    "Required seams",
    "What it pressures",
    "Explicit non-goals"
  ]

  @locked_names [
    "Phoenix SaaS Portal",
    "Selective Native Flow",
    "Local-First Study Flow"
  ]

  test "guide publishes exactly one locked adopter-profile matrix" do
    guide = File.read!("guides/adopter_profiles.md")

    assert count_occurrences(guide, "| #{Enum.join(@matrix_header, " | ")} |") == 1
    assert count_occurrences(guide, "|---------|---------------|-----------------------|-------------------------------|----------------|-------------------|--------------------|") == 1

    for name <- @locked_names do
      assert guide =~ name
    end
  end

  test "each profile section includes routes seams failure focus proof posture and non-goals" do
    guide = File.read!("guides/adopter_profiles.md")

    assert guide =~ "Representative routes:"
    assert guide =~ "Required seams:"
    assert guide =~ "Primary failure vocabulary focus:"
    assert guide =~ "Proof posture summary:"
    assert guide =~ "Explicit non-goals:"

    assert guide =~ "/dashboard"
    assert guide =~ "/native/claims/:id/capture"
    assert guide =~ "/study/session"

    assert guide =~ "`route unavailable`"
    assert guide =~ "`pack_incompatible`"
    assert guide =~ "`conflict requires attention`"
  end

  test "profile guide and linked docs preserve the no-second-support-matrix boundary" do
    guide = File.read!("guides/adopter_profiles.md")
    install = File.read!("guides/install.md")
    native_shell = File.read!("guides/native_shell.md")
    offline = File.read!("guides/offline.md")
    packs = File.read!("guides/packs.md")

    assert install =~ "guides/adopter_profiles.md"
    assert native_shell =~ "guides/adopter_profiles.md"
    assert offline =~ "guides/adopter_profiles.md"
    assert packs =~ "guides/adopter_profiles.md"

    assert guide =~ "guides/support_matrix.md"
    assert guide =~ "guides/native_shell.md"
    assert guide =~ "guides/offline.md"
    assert guide =~ "guides/packs.md"
    assert guide =~ "guides/install.md"

    refute guide =~ "| Target | Version | Status | Proof | Notes |"
    refute guide =~ "verification required"
    refute guide =~ "script/verify_generated_ios_shell.sh"
    refute guide =~ "script/verify_generated_android_shell.sh"
    refute guide =~ "plugin bus"
    refute guide =~ "plugin-bus"
    refute guide =~ ":adapter"
  end

  defp count_occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
