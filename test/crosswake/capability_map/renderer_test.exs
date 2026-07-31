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
        %{id: "route-policy"} = row -> %{row | adoption_implication: "temporary update"}
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

  test "D-11/D-13 public guide uses first-adopter framing without active native-control breadth" do
    rendered = Renderer.render()

    assert rendered =~ "first adopter"
    refute rendered =~ "First B2C Adopter"
    refute rendered =~ "Native Controls Pack 1"
  end

  test "RESET-01 equal implications preserve canonical row adjacency in deterministic rendering" do
    rows = [
      renderer_row(%{id: "first-equal", surface: "First equal", adoption_implication: "same"}),
      renderer_row(%{id: "second-equal", surface: "Second equal", adoption_implication: "same"})
    ]

    rendered_once = Renderer.render(rows)
    rendered_twice = Renderer.render(rows)

    assert rendered_once == rendered_twice
    assert elem(:binary.match(rendered_once, "First equal"), 0) <
             elem(:binary.match(rendered_once, "Second equal"), 0)
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
      adoption_implication: "gamma\ndelta"
    }

    rendered = Renderer.render([risky_row])

    assert rendered =~ "Risky \\| Surface"
    assert rendered =~ "line one line two"
    assert rendered =~ "alpha \\| beta"
    assert rendered =~ "gamma delta"

    refute rendered =~ "Risky | Surface"
    refute rendered =~ "alpha | beta |"
  end

  test "D-11/D-12 normalizes canonical and legacy implication inputs through one compatibility window" do
    canonical = renderer_row(%{adoption_implication: "canonical implication"})
    legacy_atom = renderer_row(%{v20_implication: "legacy implication"}) |> Map.delete(:adoption_implication)

    legacy_string =
      renderer_row(%{})
      |> stringify_keys()
      |> Map.delete("adoption_implication")
      |> Map.put("v20_implication", "legacy implication")

    equal_dual = renderer_row(%{v20_implication: "canonical implication"})

    assert Renderer.render([canonical]) =~ "canonical implication"
    assert Renderer.render([legacy_atom]) =~ "legacy implication"
    assert Renderer.render([legacy_string]) =~ "legacy implication"
    assert Renderer.render([equal_dual]) =~ "canonical implication"
  end

  test "D-12 conflicting implication aliases fail closed without echoing row content" do
    assert_raise ArgumentError, "conflicting adoption_implication and v20_implication", fn ->
      Renderer.render([renderer_row(%{v20_implication: "legacy secret"})])
    end
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

  defp renderer_row(overrides) do
    Map.merge(
      %{
        id: "synthetic-row",
        surface: "Synthetic surface",
        route_or_evidence_source: "synthetic evidence",
        category: :demoed,
        display_label: "Demo pressure",
        route_runtime_owner: :bounded_bridge,
        package_owner: :core,
        proof_posture: :advisory,
        rebuild: :none,
        denial_fallback: "Explicit fallback",
        adoption_implication: "canonical implication"
      },
      overrides
    )
  end

  defp stringify_keys(row) do
    Map.new(row, fn {key, value} -> {Atom.to_string(key), value} end)
  end
end
