defmodule Crosswake.Guides.HostCommandSeamGuideTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Locks the host-command seam guide truth (Phase 181, SEAM-05). Hermetic: reads
  repository files only.
  """

  defp guide(name), do: File.read!(Path.join(["guides", name]))

  test "route_policy documents the author path and both error codes" do
    text = guide("route_policy.md")

    for needle <- [
          "crosswake_host_commands",
          "use Crosswake.Router,",
          "host_commands:",
          "[crosswake.route.unknown_host_command]",
          "[crosswake.route.host_command_runtime]",
          "HostBridgeCommandDelegate",
          "registeredCommands",
          "mix crosswake.gen.shell ios",
          "Authors never edit manifest or activation fixtures",
          "`live_view` and `offline_island`"
        ] do
      assert text =~ needle, "route_policy.md is missing: #{needle}"
    end
  end

  test "route_policy states the supported version range" do
    text = guide("route_policy.md")
    assert text =~ "host-command versions 1.x.y"
    assert text =~ "`^1.0.0`"
    assert text =~ "never grants it"
  end

  test "the seam changelog entry says Android unchanged and claims no release" do
    changelog = File.read!("CHANGELOG.md")
    [entry] = Regex.run(~r/\* \*\*Host-command seam[^\n]*/, changelog)
    assert entry =~ "not released"
    assert entry =~ "This entry is not a release and claims no device or adopter result"
    assert entry =~ "The Android shell, its vectors and its assets are unchanged"
  end
end
