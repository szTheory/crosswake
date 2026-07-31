defmodule Crosswake.CapabilityMap.RendererTest do
  use ExUnit.Case, async: true

  alias Crosswake.CapabilityMap
  alias Crosswake.CapabilityMap.Renderer

  @guide_path "guides/capability_map.md"

  test "D-06/D-20/D-21 renderer emits deterministic markdown and write semantics" do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-capability-map-#{System.unique_integer([:positive])}.md"
      )

    File.rm(path)

    rendered_once = Renderer.render()
    rendered_twice = Renderer.render()

    assert rendered_once == rendered_twice
    assert {:ok, :created} = Renderer.write(path)
    assert {:ok, :reused} = Renderer.write(path)

    changed_rows =
      CapabilityMap.canonical()
      |> Enum.map(&normalize_row/1)
      |> Enum.map(fn
        %{id: "route-policy"} = row -> %{row | v20_implication: "temporary update"}
        row -> row
      end)

    assert {:ok, :updated} = Renderer.write(path, changed_rows)
  end

  test "D-06/D-20/D-21 guides/capability_map.md is byte-identical to renderer output" do
    rendered = Renderer.render()

    assert File.read!(@guide_path) == rendered,
           "D-06/D-20/D-21: #{@guide_path} drifted from Crosswake.CapabilityMap.Renderer.render/0"

    assert rendered == Renderer.render()
  end

  test "D-26 guide starts with reader-first sections before detailed rows" do
    rendered = Renderer.render()

    assert section_index(rendered, "## What works today") <
             section_index(rendered, "## What evidence exists")

    assert section_index(rendered, "## What evidence exists") <
             section_index(rendered, "## What the first adopter changes")

    assert section_index(rendered, "## What the first adopter changes") <
             section_index(rendered, "## Detailed Capability Rows")
  end

  test "D-27/D-28 detailed table uses UI-SPEC column order and exact status labels" do
    rendered = Renderer.render()

    assert rendered =~
             "| Capability or surface | Display label | Route or evidence source | Current category | Route runtime owner | Package owner | Proof posture | Rebuild | Denial/fallback behavior | Adoption implication |"

    for label <- CapabilityMap.display_labels() do
      assert rendered =~ label
    end

    for posture <- ["merge-blocking", "advisory", "not-yet-proven", "unsupported"] do
      assert rendered =~ posture
    end

    for rebuild_label <- [
          "No rebuild required",
          "Native rebuild required",
          "Companion rebuild required"
        ] do
      assert rendered =~ rebuild_label
    end

    assert rendered =~ "Screenshots are collateral after route-tour assertions"
    assert rendered =~ "Cached read-only is not offline mutation"
    assert rendered =~ "Backend projection"
  end

  test "D-27 renderer escapes pipes and newlines in interpolated cells" do
    risky_row = %{
      id: "synthetic-risky-row",
      surface: "Risky | Surface",
      route_or_evidence_source: "line one\nline two",
      category: :demoed,
      display_label: "Demo pressure",
      route_runtime_owner: :live_view,
      package_owner: :example_docs_only,
      proof_posture: :advisory,
      rebuild: :native_required,
      denial_fallback: "alpha | beta",
      v20_implication: "gamma\ndelta"
    }

    rendered = Renderer.render([risky_row])

    assert rendered =~ "Risky \\| Surface"
    assert rendered =~ "line one line two"
    assert rendered =~ "alpha \\| beta"
    assert rendered =~ "gamma delta"

    refute rendered =~ "Risky | Surface"
    refute rendered =~ "alpha | beta |"
  end

  defp section_index(rendered, heading) do
    index =
      rendered
      |> String.split("\n")
      |> Enum.find_index(&(&1 == heading))

    assert is_integer(index), "expected rendered guide to contain #{heading}"
    index
  end

  defp normalize_row(%_{} = row), do: Map.from_struct(row)
  defp normalize_row(row) when is_map(row), do: row
end
