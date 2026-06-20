defmodule Crosswake.Guides.CompatibilityTest do
  use ExUnit.Case, async: true

  @jtbd_table_header "| Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor |"

  @locked_rebuild_classes [
    "docs-only",
    "core-only/no native rebuild",
    "compatibility-bump only",
    "native or companion rebuild required"
  ]

  # The prose ordering sentinel — the lead prose that must appear AFTER the decision table.
  # If the table is moved below this text, the ordering assert fails.
  @prose_sentinel "Crosswake keeps runtime ownership"

  test "decision table leads the guide — table appears before first prose sentinel" do
    guide = File.read!("guides/compatibility.md")

    # Table header must be present
    assert guide =~ @jtbd_table_header,
           "JTBD table header not found in guides/compatibility.md"

    # Table must appear BEFORE the prose sentinel (the load-bearing ordering assertion)
    {table_pos, _} = :binary.match(guide, @jtbd_table_header)
    {prose_pos, _} = :binary.match(guide, @prose_sentinel)

    assert table_pos < prose_pos,
           "Table header (pos #{table_pos}) must appear before prose sentinel '#{@prose_sentinel}' (pos #{prose_pos})"
  end

  test "rebuild-class names mirror Renderer.render(canonical()) — anti-drift" do
    guide = File.read!("guides/compatibility.md")
    rendered = Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())

    for class_name <- @locked_rebuild_classes do
      assert rendered =~ class_name,
             "Rebuild class '#{class_name}' not found in Renderer.render(canonical()) — canonical source drifted"

      assert guide =~ class_name,
             "Rebuild class '#{class_name}' not found in guides/compatibility.md — guide drifted from canonical"
    end
  end

  test "all three version axes are present in the guide" do
    guide = File.read!("guides/compatibility.md")

    assert guide =~ "manifest_schema_version",
           "Expected manifest_schema_version in guides/compatibility.md"

    assert guide =~ "bridge_protocol_version",
           "Expected bridge_protocol_version in guides/compatibility.md"

    assert guide =~ "native_runtime_version",
           "Expected native_runtime_version in guides/compatibility.md"
  end

  test "native_runtime_version asymmetry is stated and locked" do
    guide = File.read!("guides/compatibility.md")

    # The guide must co-locate native_runtime with the native-rebuild class
    assert guide =~ "native_runtime_version",
           "Expected native_runtime_version in guides/compatibility.md"

    assert guide =~ "native or companion rebuild required",
           "Expected native rebuild class in guides/compatibility.md"

    # The asymmetry note must be present: native_runtime_version additive bumps
    # are always native-rebuild (no additive-without-rebuild row)
    assert guide =~ "native_runtime_version` has **no** additive-without-rebuild row" or
             guide =~ "native_runtime_version has no additive-without-rebuild row" or
             guide =~ "native_runtime_version` any change (additive or breaking)",
           "Expected native_runtime_version asymmetry stated in guides/compatibility.md — no additive-without-rebuild row"

    # There must be NO additive native_runtime row that maps to a non-rebuild class
    # (i.e., the guide must not claim native_runtime_version additive is compat-bump-only)
    refute guide =~ "native_runtime_version | additive | compatibility-bump only",
           "Found prohibited native_runtime_version additive no-rebuild row in guides/compatibility.md"

    refute guide =~ "native_runtime_version | additive | docs-only",
           "Found prohibited native_runtime_version additive docs-only row in guides/compatibility.md"

    refute guide =~ "native_runtime_version | additive | core-only",
           "Found prohibited native_runtime_version additive core-only row in guides/compatibility.md"
  end

  test "guide does not introduce a second support-status table (no-second-support-matrix boundary)" do
    guide = File.read!("guides/compatibility.md")

    refute guide =~ "| Target | Version | Status |",
           "Found prohibited support-status table header in guides/compatibility.md (no-second-support-matrix boundary)"
  end

  test "decision table appears exactly once" do
    guide = File.read!("guides/compatibility.md")

    assert count_occurrences(guide, @jtbd_table_header) == 1,
           "Expected exactly 1 JTBD table header in guides/compatibility.md, found #{count_occurrences(guide, @jtbd_table_header)}"
  end

  defp count_occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
