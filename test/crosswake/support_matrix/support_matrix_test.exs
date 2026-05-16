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
             "routes",
             "support_matrix"
           ]

    assert root_map["support_matrix"]["phoenix"] != []
    assert root_map["capability_registry"] == %{}
  end

  test "support entries distinguish supported, verification required, and unsupported exactly" do
    matrix = SupportMatrix.canonical()

    statuses =
      [:phoenix, :live_view, :ios, :android, :shells]
      |> Enum.flat_map(fn category -> Enum.map(Map.fetch!(matrix, category), & &1.status) end)
      |> Enum.uniq()
      |> Enum.sort()

    assert statuses == [:supported, :unsupported, :verification_required]
    assert SupportMatrix.statuses() == [:supported, :verification_required, :unsupported]
  end

  test "the first support matrix stays narrow and proof-oriented" do
    matrix = SupportMatrix.canonical()

    assert length(matrix.phoenix) == 1
    assert length(matrix.live_view) == 1
    assert length(matrix.ios) == 1
    assert length(matrix.android) == 1
    assert length(matrix.shells) == 2
    assert SupportMatrix.validate(matrix) == []
  end
end
