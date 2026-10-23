defmodule Crosswake.Guides.HostCommandSeamGuideTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Locks the host-command seam guide truth (Phase 181, SEAM-05). Hermetic: reads
  repository files only.
  """

  defp flat(text), do: text |> String.split() |> Enum.join(" ")

  defp guide(name), do: flat(File.read!(Path.join(["guides", name])))

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

  test "bridge states the per-route grant rule and keeps undeclared_capability" do
    text = guide("bridge.md")

    for needle <- [
          "registeredCommands",
          "declares it",
          "1.x.y",
          "every navigation, deep link and back step",
          "never inherited by another",
          "keeps the shared reason `undeclared_capability`",
          "No new reason code exists",
          "names the route and the command",
          "Authors never edit manifest or activation fixtures",
          "[crosswake.route.unknown_host_command]",
          "[crosswake.route.host_command_runtime]"
        ] do
      assert text =~ needle, "bridge.md is missing: #{needle}"
    end
  end

  test "upgrade guide has the combination table and the legacy-manifest denial" do
    text = guide("native_shell_upgrade.md")

    for needle <- [
          "| Host with no declaring routes |",
          "| New shell with an old manifest (before 1.2.0) |",
          "| New shell with a 1.2.0 manifest, declared command, no registered delegate |",
          "| Old shell with a new manifest |",
          "Upgrade core and the iOS shell together",
          "host_commands_stale",
          "host_command_shell_unsupported",
          "host_commands_legacy_manifest",
          "host_commands_stale_skipped",
          "mix crosswake.gen.shell ios",
          "not_registered",
          "version_unsupported"
        ] do
      assert text =~ needle, "native_shell_upgrade.md is missing: #{needle}"
    end

    refute text =~ "keeps working for the entry route only"
  end

  test "compatibility guide states the seam floor: the route activates and each declared command is denied with seam_unsupported" do
    text = guide("compatibility.md")

    assert text =~ "denied with `seam_unsupported`"
    assert text =~ "The route still activates"
    refute text =~ "refuses to activate a declaring route"
  end

  test "the legacy-manifest changelog entry names the behaviour change and the repair" do
    changelog = File.read!("CHANGELOG.md")
    [entry] = Regex.run(~r/\* \*\*Legacy-manifest denial[^\n]*/, changelog)
    [seam] = Regex.run(~r/\* \*\*Host-command seam[^\n]*/, changelog)
    refute entry == seam
    assert entry =~ "mix crosswake.gen.shell ios"
    assert entry =~ "host_commands_legacy_manifest"
    assert entry =~ "not released"
  end

  test "upgrade guide explains the remote shell package gate and its fix" do
    text = guide("native_shell_upgrade.md")
    assert text =~ "remote crosswake-shell-core-ios package cannot declare host commands"
    assert text =~ "until a published shell release carries the seam"
    assert text =~ "local `crosswake-shell-core-ios` path"
    assert text =~ "`HostCommandSeam` version 1.0.0"
    assert text =~ "leave `host_commands` undeclared"
  end

  test "upgrade guide tells hosts to add case .offlineIsland" do
    upgrade = guide("native_shell_upgrade.md")

    assert upgrade =~ "case .offlineIsland"
    assert upgrade =~ "same web container"
    assert upgrade =~ "source break is intended"
  end

  test "offline and native_shell guides list every offline non-promise" do
    offline = guide("offline.md")
    shell = guide("native_shell.md")

    for needle <- [
          "offline cold start",
          "outbox durability, replay or auth",
          "service workers",
          "data-store survival under storage pressure",
          "generic sync, background sync or native storage",
          "Phase 180 relaunch evidence is its own observation"
        ] do
      assert offline =~ needle, "offline.md is missing: #{needle}"
    end

    assert shell =~ "`offline_island`"
    assert shell =~ "offline.md#what-the-shell-does-not-promise"
    assert shell =~ "Admission is not an offline guarantee"
  end

  test "edited guides make no release-done claim and name no adopter detail" do
    files =
      ~w(route_policy.md bridge.md native_shell_upgrade.md native_shell.md offline.md)
      |> Enum.map(&Path.join("guides", &1))

    for path <- files do
      text = path |> File.read!() |> flat()

      refute text =~ ~r/host.command seam[^.\n]*\b(has shipped|is released|was released)/i,
             "#{path} claims the seam is released"

      refute text =~ ~r/\$\d/, "#{path} contains a price-like token"
    end

    assert guide("native_shell_upgrade.md") =~ "Nothing described here is a release"
  end
end
