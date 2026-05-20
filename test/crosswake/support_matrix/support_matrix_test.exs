defmodule Crosswake.SupportMatrixTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix

  test "canonical support matrix provides the typed manifest slots used by phase 2" do
    matrix = SupportMatrix.canonical()

    root =
      Types.new_root(
        crosswake_version: "0.1.0",
        generated_at: "2026-05-14T00:00:00Z",
        host: Types.new_host(),
        compatibility: Types.new_compatibility(),
        support_matrix: matrix,
        capability_registry: %{},
        routes: %{}
      )

    root_map = Types.to_map(root)

    assert Map.keys(root_map) == [
             "capability_registry",
             "compatibility",
             "crosswake_version",
             "generated_at",
             "host",
             "manifest_schema_version",
             "pack_registry",
             "routes",
             "support_matrix"
           ]

    assert root_map["support_matrix"]["phoenix"] != []
    assert root_map["capability_registry"] == %{}
    assert root_map["support_matrix"]["capability_families"] != []
    assert root_map["support_matrix"]["package_surfaces"] != []
    assert root_map["support_matrix"]["release_boundaries"] != []
    assert root_map["support_matrix"]["change_classes"] != []
  end

  test "canonical support entries now publish the proof-backed phase 5 shell posture" do
    matrix = SupportMatrix.canonical()

    statuses =
      [:phoenix, :live_view, :ios, :android, :shells]
      |> Enum.flat_map(fn category -> Enum.map(Map.fetch!(matrix, category), & &1.status) end)
      |> Enum.uniq()
      |> Enum.sort()

    assert statuses == [:supported]
    assert SupportMatrix.statuses() == [:supported, :verification_required, :unsupported]
  end

  test "the first support matrix stays narrow and proof-oriented" do
    matrix = SupportMatrix.canonical()

    assert length(matrix.phoenix) == 1
    assert length(matrix.live_view) == 1
    assert length(matrix.ios) == 1
    assert length(matrix.android) == 1
    assert length(matrix.shells) == 2
    assert matrix.capability_families != []
    assert length(matrix.package_surfaces) == 5
    assert length(matrix.release_boundaries) == 4
    assert length(matrix.change_classes) == 4
    assert SupportMatrix.validate(matrix) == []
  end

  test "capability family posture is derived from manifest capability entries" do
    capability_registry = %{
      "haptics" =>
        Types.new_capability(
          id: "haptics",
          family: "haptics",
          owner: :bounded_bridge,
          package_class: :core,
          proof_class: :merge_blocking,
          rebuild: :none,
          prerequisites: ["declared route capability"],
          denial: "undeclared_capability",
          fallback: "Phoenix route continues without native confirmation feedback",
          guide: "guides/bridge.md#bounded-bridge"
        ),
      "haptics.impact" =>
        Types.new_capability(
          id: "haptics.impact",
          family: "haptics",
          owner: :bounded_bridge,
          package_class: :companion,
          proof_class: :advisory,
          rebuild: :native_required,
          prerequisites: ["legacy compatibility"],
          denial: "undeclared_capability",
          fallback: "legacy compatibility only",
          guide: "guides/bridge.md#bounded-bridge"
        )
    }

    matrix = SupportMatrix.canonical(capability_registry: capability_registry)

    assert matrix.capability_families == [
             Types.new_capability_support_entry(
               family: "haptics",
               owner: :bounded_bridge,
               package_class: :core,
               proof_class: :merge_blocking,
               rebuild: :none,
               prerequisites: ["declared route capability"],
               denial: "undeclared_capability",
               fallback: "Phoenix route continues without native confirmation feedback",
               guide: "guides/bridge.md#bounded-bridge"
             )
           ]
  end

  test "canonical support truth publishes one primary crosswake package and explicit package classes" do
    matrix = SupportMatrix.canonical()

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.surface == "`crosswake` primary package" and entry.package_class == :core
           end)

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.package_class == :example_docs_only and
               entry.surface == "Checked-in example hosts and install walkthroughs"
           end)

    assert Enum.any?(matrix.package_surfaces, fn entry ->
             entry.package_class == :defer and entry.surface == "Standalone public shell packages"
           end)
  end

  test "release policy stays hybrid instead of repo-wide lockstep versioning" do
    matrix = SupportMatrix.canonical()

    assert Enum.any?(matrix.release_boundaries, fn entry ->
             entry.target == "core" and entry.compatibility_contract =~ "package versions alone do not define support truth"
           end)

    refute Enum.any?(matrix.release_boundaries, fn entry ->
             String.contains?(entry.versioning, "lockstep")
           end)
  end

  test "change classes stay frozen to the four public release actions" do
    matrix = SupportMatrix.canonical()

    assert Enum.map(matrix.change_classes, & &1.change_class) == [
             "docs-only",
             "core-only/no native rebuild",
             "compatibility-bump only",
             "native or companion rebuild required"
           ]
  end
end
