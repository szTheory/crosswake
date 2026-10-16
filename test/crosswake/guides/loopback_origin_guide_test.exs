defmodule Crosswake.Guides.LoopbackOriginGuideTest do
  use ExUnit.Case, async: true

  @guides Path.expand("../../../guides", __DIR__)

  defp guide(name), do: File.read!(Path.join(@guides, name))

  test "native shell guide documents the local loopback mode and its limits" do
    text = guide("native_shell.md")

    for needle <- [
          "origin_mode: :local_loopback",
          "NSAllowsLocalNetworking",
          "CrosswakeOriginMode",
          "phone itself",
          "MIX_ENV=prod"
        ] do
      assert text =~ needle
    end

    assert text =~ ~r/README[^.]*stale|stale[^.]*README/s
  end

  test "native shell guide documents the manual Simulator harness and its exit codes" do
    flat = guide("native_shell.md") |> String.replace(~r/\s+/, " ")

    assert [_, paragraph] =
             String.split(flat, "script/verify_loopback_origin_simulator.sh", parts: 2)

    paragraph = String.slice(paragraph, 0, 900)

    for needle <- ["manually run phase evidence", "not a CI lane", "`0`", "`2`", "`3`"] do
      assert paragraph =~ needle
    end
  end

  test "upgrade guide notes the exact-block Info.plist reconciliation" do
    assert guide("native_shell_upgrade.md") =~
             "reconciles only the exact Crosswake origin-mode block"
  end

  test "no guide names a widened ATS key" do
    offenders =
      @guides
      |> Path.join("**/*.md")
      |> Path.wildcard()
      |> Enum.filter(fn path ->
        text = File.read!(path)
        text =~ "NSAllowsArbitrary" or text =~ "NSExceptionDomains"
      end)

    assert offenders == []
  end

  test "the app-bound domain stays a fixed example, not derived from the origin" do
    refute guide("native_shell.md") =~ ~r/WKAppBoundDomains[^.]*(derived|from the origin)/i
  end

  test "both renderers mention the local mode and keep their HTTPS wording" do
    support = Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())
    capability = Crosswake.CapabilityMap.Renderer.render()

    assert support =~ "local_loopback"
    assert support =~ "HTTPS primary origin"
    assert capability =~ "local_loopback"
    assert capability =~ "HTTPS origin"
  end
end
