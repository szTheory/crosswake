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
  @https_origin "https://study.crosswake.test"
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

  defp marker_only_plist do
    String.replace(
      production_plist(),
      @anchor,
      @anchor <> "\n    <key>CrosswakeOriginMode</key>\n    <string>local_loopback</string>"
    )
  end

  defp host_ats_plus_marker_plist do
    String.replace(
      host_ats_plist(),
      @anchor,
      @anchor <> "\n    <key>CrosswakeOriginMode</key>\n    <string>local_loopback</string>"
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
    [
      route_source: PlainRouter,
      install_manifest_path: Path.join(dir, "missing_install.json"),
      cwd: dir,
      ios_shell_root: root,
      ios_host: nil,
      native_targets: []
    ]
    |> Keyword.merge(extra)
    |> Doctor.run()
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
      report = run(dir, root(dir, production_plist(), @https_origin))
      assert codes(report) == []
    end

    test "an HTTPS host with its own ATS dict and no marker yields no ios_host origin finding", %{
      dir: dir
    } do
      plain = run(dir, root(dir, production_plist(), @https_origin))
      report = run(dir, root(dir, host_ats_plist(), @https_origin))

      assert codes(report) == []
      assert report.status == plain.status
    end

    test "a host-owned ATS dict plus the marker with an HTTPS origin is one mismatch error", %{
      dir: dir
    } do
      report = run(dir, root(dir, host_ats_plus_marker_plist(), @https_origin))
      assert codes(report) == ["ios_host.origin_mode_mismatch"]
      assert report.status == :error
    end
  end

  describe "mismatch matrix" do
    defp assert_one_mismatch(report) do
      assert codes(report) == ["ios_host.origin_mode_mismatch"]
      assert [finding] = origin_findings(report)
      assert finding.severity == :error
      assert finding.hint =~ "rerun mix crosswake.gen.shell ios"
      assert report.status == :error
    end

    test "HTTPS activation with the exact Crosswake block", %{dir: dir} do
      assert_one_mismatch(run(dir, root(dir, local_plist(), @https_origin)))
    end

    test "HTTPS activation with only the CrosswakeOriginMode marker", %{dir: dir} do
      assert_one_mismatch(run(dir, root(dir, marker_only_plist(), @https_origin)))
    end

    test "http loopback activation without the block", %{dir: dir} do
      assert_one_mismatch(run(dir, root(dir, production_plist(), @local_origin)))
    end

    test "declared local mode with HTTPS generated outputs", %{dir: dir} do
      report =
        run(dir, root(dir, production_plist(), @https_origin), ios_host: local_declaration())

      assert_one_mismatch(report)
    end

    test "declaration without a mode while the outputs are local", %{dir: dir} do
      report =
        run(dir, root(dir, local_plist(), @local_origin),
          ios_host: declaration(origin: @https_origin)
        )

      assert_one_mismatch(report)
    end

    test "raw declaration with an origin_mode that normalize refuses", %{dir: dir} do
      report =
        run(dir, root(dir, local_plist(), @local_origin),
          ios_host: declaration(origin_mode: :bogus_mode)
        )

      assert_one_mismatch(report)
    end
  end

  describe "declared local mode with no readable Info.plist" do
    test "missing ios_shell_root is one mismatch and no local warning", %{dir: dir} do
      report = run(dir, Path.join(dir, "no_such_root"), ios_host: local_declaration())
      assert codes(report) == ["ios_host.origin_mode_mismatch"]
      assert report.status == :error
    end

    test "root present but Info.plist missing is one mismatch", %{dir: dir} do
      report = run(dir, root(dir, nil, @local_origin), ios_host: local_declaration())
      assert codes(report) == ["ios_host.origin_mode_mismatch"]
      assert report.status == :error
    end

    test "unreadable Info.plist is one mismatch", %{dir: dir} do
      root = root(dir, local_plist(), @local_origin)
      File.chmod!(Path.join(root, "CrosswakeShell/Info.plist"), 0o000)
      report = run(dir, root, ios_host: local_declaration())
      assert codes(report) == ["ios_host.origin_mode_mismatch"]
      assert report.status == :error
    end

    test "missing root with no declaration yields no ios_host origin finding", %{dir: dir} do
      assert codes(run(dir, Path.join(dir, "no_such_root"))) == []
    end
  end

  describe "--check-publish" do
    test "local mode is exactly one error finding and the readiness is not_ready", %{dir: dir} do
      report = run(dir, root(dir, local_plist(), @local_origin), check_publish?: true)

      assert report.publish_readiness.status == :not_ready
      matching = Enum.filter(report.findings, &(&1.code == "ios_host.local_loopback_origin"))
      assert [finding] = matching
      assert finding.severity == :error
      assert report.status == :error
      assert Enum.count(report.publish_readiness.checks) == 12
    end

    test "a mismatch is reported once through readiness", %{dir: dir} do
      report = run(dir, root(dir, local_plist(), @https_origin), check_publish?: true)

      assert [finding] =
               Enum.filter(report.findings, &(&1.code == "ios_host.origin_mode_mismatch"))

      assert finding.severity == :error
      assert report.publish_readiness.status == :not_ready

      assert [%{blocking: true}] =
               Enum.filter(report.publish_readiness.checks, &(&1.category == :ios_host_origin))
    end

    test "an HTTPS host adds no blocking ios_host_origin check", %{dir: dir} do
      with_host = run(dir, root(dir, production_plist(), @https_origin), check_publish?: true)
      without = run(dir, Path.join(dir, "no_such_root"), check_publish?: true)

      refute Enum.any?(with_host.publish_readiness.checks, &(&1.category == :ios_host_origin))
      assert with_host.publish_readiness.status == without.publish_readiness.status
      assert length(with_host.publish_readiness.checks) == 11
    end

    test "readiness without an observation keeps eleven checks" do
      report = Crosswake.Doctor.PublishReadiness.run(cwd: File.cwd!())
      assert length(report.checks) == 11
      refute Enum.any?(report.checks, &(&1.category == :ios_host_origin))
    end

    test "the Mix task raises for the local fixture and prints the code", %{dir: dir} do
      target = Path.join(dir, "task")
      shell = Path.join(target, "native/ios/crosswake_shell")
      File.mkdir_p!(Path.dirname(shell))
      File.cp_r!(root(dir, local_plist(), @local_origin), shell)
      Mix.Task.reenable("crosswake.doctor")

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          assert_raise Mix.Error, ~r/Crosswake doctor found blocking issues/, fn ->
            File.cd!(target, fn ->
              Mix.Tasks.Crosswake.Doctor.run([
                "--router",
                "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
                "--check-publish",
                "--format",
                "json"
              ])
            end)
          end
        end)

      assert output =~ "ios_host.local_loopback_origin"
    end
  end

  describe "formatter and privacy" do
    test "the human report states the local mode right after the status line", %{dir: dir} do
      report = run(dir, root(dir, local_plist(), @local_origin))
      lines = report |> Crosswake.Doctor.Formatter.render() |> String.split("\n")
      index = Enum.find_index(lines, &(&1 == "status: ok"))

      assert Enum.at(lines, index + 1) ==
               "origin mode: local loopback (#{@local_origin}); Simulator only; not production-ready"

      refute Enum.any?(lines, &Regex.match?(~r/(?<!not )production-ready/, &1))
    end

    test "no origin mode line for an HTTPS host", %{dir: dir} do
      report = run(dir, root(dir, production_plist(), @https_origin))
      refute Crosswake.Doctor.Formatter.render(report) =~ "origin mode:"
    end

    test "no entry path, bundle id, team id or tmp path leaks", %{dir: dir} do
      forbidden = [
        "/study-session",
        "dev.crosswake.hostapp",
        "ABCDE12345",
        Path.join(dir, "root")
      ]

      reports = [
        run(dir, root(dir, local_plist(), @local_origin), ios_host: local_declaration()),
        run(dir, root(dir, local_plist(), @https_origin), ios_host: local_declaration()),
        run(dir, root(dir, local_plist(), @local_origin),
          check_publish?: true,
          ios_host: local_declaration()
        )
      ]

      for report <- reports do
        rendered =
          Crosswake.Doctor.Formatter.render(report) <>
            Crosswake.Doctor.JSONFormatter.render(report)

        for value <- forbidden do
          refute rendered =~ value
        end

        for finding <-
              origin_findings(report) ++
                Enum.filter(report.findings, &String.starts_with?(&1.code, "ios_host.")) do
          text = finding.message <> finding.hint <> inspect(finding.details)
          for value <- forbidden, do: refute(text =~ value)
        end
      end
    end

    test "doctor-level finding details keys are exactly origin and mode", %{dir: dir} do
      for plist_origin <- [{local_plist(), @local_origin}, {local_plist(), @https_origin}] do
        {plist, origin} = plist_origin
        report = run(dir, root(dir, plist, origin))
        [finding] = origin_findings(report)
        assert finding.details |> Map.keys() |> Enum.sort() == [:mode, :origin]
      end
    end
  end
end
