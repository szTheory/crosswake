defmodule Crosswake.SupportMatrix.RendererTest do
  use ExUnit.Case, async: true

  alias Crosswake.SupportMatrix
  alias Crosswake.SupportMatrix.Renderer

  test "renderer emits deterministic markdown and preserves created, reused, and updated semantics" do
    matrix = SupportMatrix.canonical()

    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-support-matrix-#{System.unique_integer([:positive])}.md"
      )

    rendered_once = Renderer.render(matrix)
    rendered_twice = Renderer.render(matrix)

    assert rendered_once == rendered_twice
    assert {:ok, :created} = Renderer.write(path, matrix)
    assert {:ok, :reused} = Renderer.write(path, matrix)

    updated_matrix = SupportMatrix.canonical(ios_version: "18.0")
    assert {:ok, :updated} = Renderer.write(path, updated_matrix)
  end

  test "generated guide renders the exact public support statuses from canonical truth" do
    guide = Renderer.render(SupportMatrix.canonical())

    assert guide =~ "supported"
    assert guide =~ "verification required"
    assert guide =~ "unsupported"
  end

  test "guides remain mechanically checked against canonical support truth and phase 3 boundaries" do
    assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())

    compatibility = File.read!("guides/compatibility.md")
    install = File.read!("guides/install.md")

    assert compatibility =~ "Runtime ownership"
    assert compatibility =~ "manifest_schema_version"
    assert compatibility =~ "bridge_protocol_version"
    assert compatibility =~ "native_runtime_version"
    assert compatibility =~ "bundled"
    assert compatibility =~ "cached"
    assert compatibility =~ "remote"
    assert compatibility =~ "fail-closed"
    assert compatibility =~ "Phase 3"

    assert install =~ "mix crosswake.doctor"
    assert install =~ "guides/compatibility.md"
    assert install =~ "guides/support_matrix.md"
  end
end
