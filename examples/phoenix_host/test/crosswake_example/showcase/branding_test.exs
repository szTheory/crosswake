defmodule CrosswakeExample.Showcase.BrandingTest do
  use ExUnit.Case, async: true

  alias CrosswakeExample.Showcase.Branding

  @brand_ids [:saas_admin, :field_service, :learning_training]

  test "root brand is Crosswake-owned and points at served logo assets" do
    root = Branding.root()

    assert root.name == "Crosswake Showcase"
    assert root.eyebrow == "Demo apps powered by Crosswake"
    assert root.logo_path == "/brand/crosswake-lockup-horizontal.svg"
    assert root.logo_dark_path == "/brand/crosswake-lockup-horizontal-dark.svg"
  end

  test "demo app identities are stable, fictional, and distinct from Crosswake" do
    brands = Branding.app_brands()

    assert Branding.brand_ids() == @brand_ids
    assert Enum.map(brands, & &1.name) == ["AdminPilot", "Fieldserv", "LearnLoop"]

    for brand <- brands do
      refute brand.name =~ "Crosswake"
      assert brand.category in ["SaaS/Admin", "Field Service", "Subscription Learning"]
      assert is_binary(brand.tagline) and brand.tagline != ""
      assert is_binary(brand.tone) and brand.tone != ""
    end
  end

  test "demo app visual identifiers are unique and CSS-addressable" do
    brands = Branding.app_brands()

    theme_classes = Enum.map(brands, & &1.theme_class)
    style_identifiers = Enum.map(brands, & &1.style_identifier)

    assert Enum.uniq(theme_classes) == theme_classes
    assert Enum.uniq(style_identifiers) == style_identifiers

    for brand <- brands do
      assert brand.theme_class =~ ~r/^showcase-brand-[a-z0-9-]+$/
      assert brand.style_identifier =~ ~r/^[a-z0-9-]+$/
      assert brand.mark =~ ~r/^[A-Z]{2}$/
    end
  end

  test "fixture briefs require realistic organization, people, records, activity, and pressure data" do
    for brand <- Branding.app_brands() do
      fixture = brand.fixture_brief

      assert is_binary(fixture.organization) and fixture.organization != ""
      assert length(fixture.people) >= 2
      assert length(fixture.records) >= 3
      assert length(fixture.activity) >= 2
      assert is_binary(fixture.pressure) and fixture.pressure != ""

      for value <- fixture.people ++ fixture.records ++ fixture.activity do
        assert is_binary(value) and value != ""
      end
    end
  end
end
