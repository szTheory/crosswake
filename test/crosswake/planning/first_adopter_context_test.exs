defmodule Crosswake.Planning.FirstAdopterContextTest do
  use ExUnit.Case, async: true

  @durable_paths [
    ".planning/ADR-FIRST-B2C-ADOPTER.md",
    ".planning/DECISIONS.md",
    ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md",
    ".planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md",
    ".planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md",
    ".planning/PROJECT.md",
    ".planning/REQUIREMENTS.md",
    ".planning/ROADMAP.md",
    ".planning/STATE.md",
    ".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md",
    "AGENTS.md"
  ]

  @public_guide_paths [
    "guides/capability_map.md",
    "guides/support_matrix.md"
  ]

  test "adopter-readiness context is durable and discoverable" do
    for path <- @durable_paths do
      assert File.exists?(path), "missing adopter-readiness context: #{path}"
    end

    assert File.read!("AGENTS.md") =~ ".planning/ADR-FIRST-B2C-ADOPTER.md"
    assert File.read!("AGENTS.md") =~ ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md"
    assert File.read!(".planning/STATE.md") =~ "$gsd-discuss-phase 158"
    assert File.read!(".planning/ROADMAP.md") =~ "Physical-iPhone Adoption Proof"

    brief = File.read!(".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md")
    assert brief =~ "## Surface-area audit"
    assert brief =~ "## Stakeholder lens summary"
    assert brief =~ "## Non-goal defense"
    assert brief =~ "## Physical-iPhone milestone"
  end

  test "durable context uses the codename and public guides use the generic phrase" do
    for path <- @durable_paths do
      assert File.read!(path) =~ ~r/First B2C Adopter|first-adopter|first adopter/i,
             "#{path} does not preserve adopter-priority context"
    end

    for path <- @public_guide_paths do
      contents = File.read!(path)
      assert contents =~ ~r/first adopter|first-adopter/i
      refute contents =~ "First B2C Adopter"
    end
  end

  test "active adopter artifacts reject identifying or commercial details" do
    contents =
      (@durable_paths ++ @public_guide_paths)
      |> Enum.map_join("\n", &File.read!/1)

    refute contents =~ ~r/\$\s*\d+/,
           "active adopter artifacts must not contain pricing"

    refute contents =~ ~r/customer[-_ ]?(email|name|address)|legal[-_ ]?name/i,
           "active adopter artifacts must not contain customer or legal identity fields"

    private_terms =
      System.get_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    for term <- private_terms do
      refute String.contains?(String.downcase(contents), String.downcase(term)),
             "active adopter artifacts contain a configured private adopter term"
    end
  end
end
