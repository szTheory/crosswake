defmodule Crosswake.Doctor.OriginModeTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.Shell.IOSHostOriginMode, as: Mode
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  defmodule PlainRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live("/study-session", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "study-session", runtime: :live_view]
        )
      end
    end
  end

  @golden Path.expand("../../fixtures/shell/ios/Info.plist.production.golden", __DIR__)
  @permission_strings [
    "aps-environment",
    "NSPrivacyCollectedDataTypeDeviceID",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
    "com.apple.developer.associated-domains"
  ]
  @local_origin "http://127.0.0.1:4790"
  @anchor "    <key>LSRequiresIPhoneOS</key>\n    <true/>"

  setup do
    dir = Path.join(System.tmp_dir!(), "doctor-origin-mode-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.chmod(Path.join(dir, "root/CrosswakeShell/Info.plist"), 0o644)
      File.rm_rf!(dir)
    end)

    %{dir: dir}
  end

  defp production_plist, do: File.read!(@golden)
  defp local_plist, do: elem(Mode.desired(production_plist(), :local_loopback), 1)

  defp host_ats_plist do
    String.replace(
      production_plist(),
      @anchor,
      @anchor <>
        "\n    <key>NSAppTransportSecurity</key>\n    <dict>\n        <key>NSAllowsArbitraryLoads</key>\n        <false/>\n    </dict>"
    )
  end

  defp root(dir, plist, origin) do
    root = Path.join(dir, "root")
    File.mkdir_p!(Path.join(root, "CrosswakeShell"))
    File.mkdir_p!(Path.join(root, "Fixtures"))
    # Permission strings the unrelated shell_permission_drift check requires, so the report
    # status reflects only the origin-mode findings under test.
    File.write!(
      Path.join(root, "CrosswakeShell/CrosswakeShell.entitlements"),
      Enum.join(@permission_strings, "\n")
    )

    if plist, do: File.write!(Path.join(root, "CrosswakeShell/Info.plist"), plist)

    if origin do
      File.write!(
        Path.join(root, "Fixtures/route_activation.json"),
        Jason.encode!(%{"origin" => origin, "entry" => "/study-session"})
      )
    end

    root
  end

  defp declaration(extra) do
    [
      router: ManagedRouter,
      origin: @local_origin,
      entry_route_id: "study-session",
      app_bundle_id: "dev.crosswake.hostapp",
      proof_app_bundle_id: "dev.crosswake.hostapp.proof",
      device_signing: [mode: :automatic, team_id: "ABCDE12345"]
    ]
    |> Keyword.merge(extra)
  end

  defp local_declaration, do: declaration(origin_mode: :local_loopback)

  defp run(dir, root, extra \\ []) do
    Doctor.run(
      [
        route_source: PlainRouter,
        install_manifest_path: Path.join(dir, "missing_install.json"),
        cwd: dir,
        ios_shell_root: root,
        ios_host: nil,
        native_targets: []
      ] ++ extra
    )
  end

  defp origin_findings(report),
    do: Enum.filter(report.findings, &(&1.check == "ios_host_origin"))

  defp codes(report), do: report |> origin_findings() |> Enum.map(& &1.code) |> Enum.sort()

  describe "tracer: local mode warning and HTTPS control" do
    test "a consistent local host yields exactly one warning with only the canonical origin", %{
      dir: dir
    } do
      report = run(dir, root(dir, local_plist(), @local_origin))

      assert [finding] = origin_findings(report)
      assert finding.code == "ios_host.local_loopback_origin"
      assert finding.severity == :warning
      assert finding.check == "ios_host_origin"
      assert finding.details == %{origin: @local_origin, mode: "local_loopback"}
      assert finding.message =~ @local_origin
      assert report.status == :ok
    end

    test "a consistent local host with an agreeing declaration is the same single warning", %{
      dir: dir
    } do
      report =
        run(dir, root(dir, local_plist(), @local_origin), ios_host: local_declaration())

      assert codes(report) == ["ios_host.local_loopback_origin"]
      assert report.status == :ok
    end

    test "an HTTPS host with no local signal yields no ios_host origin finding", %{dir: dir} do
      report = run(dir, root(dir, production_plist(), "https://study.crosswake.test"))
      assert codes(report) == []
    end

    test "an HTTPS host with its own ATS dict and no marker yields no ios_host origin finding", %{
      dir: dir
    } do
      plain = run(dir, root(dir, production_plist(), "https://study.crosswake.test"))
      report = run(dir, root(dir, host_ats_plist(), "https://study.crosswake.test"))

      assert codes(report) == []
      assert report.status == plain.status
    end
  end
end
