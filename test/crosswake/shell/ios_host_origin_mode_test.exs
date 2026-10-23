defmodule Crosswake.Shell.IOSHostOriginModeTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostOriginMode, as: Mode

  @golden Path.expand("../../fixtures/shell/ios/Info.plist.production.golden", __DIR__)
  @anchor "    <key>LSRequiresIPhoneOS</key>\n    <true/>"
  @forbidden ~w(NSAllowsArbitraryLoads NSAllowsArbitraryLoadsInWebContent NSAllowsArbitraryLoadsForMedia NSExceptionDomains)

  defp production, do: File.read!(@golden)
  defp local, do: elem(Mode.desired(production(), :local_loopback), 1)

  defp host_ats(extra),
    do:
      String.replace(
        production(),
        @anchor,
        @anchor <>
          "\n    <key>NSAppTransportSecurity</key>\n    <dict>\n" <> extra <> "    </dict>"
      )

  defp ats_keys(bytes) do
    [_, rest] = String.split(bytes, "<key>NSAppTransportSecurity</key>", parts: 2)
    [_, dict] = String.split(rest, "<dict>", parts: 2)
    [dict, _] = String.split(dict, "</dict>", parts: 2)
    Regex.scan(~r{<key>([^<]+)</key>}, dict) |> Enum.map(&List.last/1)
  end

  test "ATS dict key set of the local block is exactly NSAllowsLocalNetworking" do
    assert ats_keys(local()) == ["NSAllowsLocalNetworking"]
  end

  test "local output contains no forbidden ATS key and production has no ATS at all" do
    for key <- @forbidden, do: refute(local() =~ key)
    refute production() =~ "NSAppTransportSecurity"
    assert local() =~ "<string>example.com</string>"
  end

  test "desired is idempotent in both modes" do
    assert Mode.desired(local(), :local_loopback) == {:ok, local()}
    assert Mode.desired(production(), nil) == {:ok, production()}
    assert Mode.desired(local(), nil) == {:ok, production()}
    assert Mode.desired(production(), :local_loopback) == {:ok, local()}
  end

  test "inspect_plist classifies production, local, and host ATS" do
    assert Mode.inspect_plist(production()) == {:ok, %{mode: nil, host_ats: false}}
    assert Mode.inspect_plist(local()) == {:ok, %{mode: :local_loopback, host_ats: false}}

    assert Mode.inspect_plist(
             host_ats("        <key>NSAllowsLocalNetworking</key>\n        <true/>\n")
           ) ==
             {:ok, %{mode: nil, host_ats: true}}
  end

  test "an altered block is a conflict, not stripped" do
    altered =
      String.replace(
        local(),
        "        <key>NSAllowsLocalNetworking</key>",
        "      <key>NSAllowsLocalNetworking</key>"
      )

    assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(altered, :local_loopback)
  end

  for key <- @forbidden do
    test "local mode refuses forbidden key #{key}" do
      bytes = host_ats("        <key>#{unquote(key)}</key>\n        <true/>\n")
      assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(bytes, :local_loopback)

      inserted =
        String.replace(
          production(),
          @anchor,
          @anchor <> "\n    <key>#{unquote(key)}</key>\n    <true/>"
        )

      assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(inserted, :local_loopback)
    end
  end

  test "local mode refuses the Crosswake ATS dict with an extra key" do
    extra =
      String.replace(
        local(),
        "        <true/>\n    </dict>",
        "        <true/>\n        <key>Other</key>\n        <true/>\n    </dict>"
      )

    assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(extra, :local_loopback)
  end

  test "local mode refuses a host-owned ATS dict without the marker" do
    bytes = host_ats("        <key>NSAllowsLocalNetworking</key>\n        <true/>\n")
    assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(bytes, :local_loopback)
  end

  test "a different CrosswakeOriginMode value is a conflict in both modes" do
    bytes =
      String.replace(
        production(),
        @anchor,
        @anchor <> "\n    <key>CrosswakeOriginMode</key>\n    <string>other</string>"
      )

    assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(bytes, :local_loopback)
    assert {:error, %{cause: "info_plist_conflict"}} = Mode.desired(bytes, nil)
  end

  test "a missing or duplicated anchor is a conflict" do
    assert {:error, %{cause: "info_plist_conflict"}} =
             Mode.desired(String.replace(production(), @anchor, ""), :local_loopback)

    assert {:error, %{cause: "info_plist_conflict"}} =
             Mode.desired(
               String.replace(production(), @anchor, @anchor <> "\n" <> @anchor),
               :local_loopback
             )
  end

  test "conflict errors never contain file contents" do
    {:error, error} =
      Mode.desired(host_ats("        <key>Secret-Token-Value</key>\n"), :local_loopback)

    refute inspect(error) =~ "Secret-Token-Value"
    assert Map.keys(error) |> Enum.sort() == [:cause, :repair]
  end

  test "mode nil leaves a host-owned ATS dict untouched, even with a forbidden key" do
    cases = [
      host_ats("        <key>NSExceptionDomains</key>\n        <dict/>\n"),
      host_ats(
        "        <key>NSAllowsLocalNetworking</key>\n        <true/>\n        <key>Other</key>\n        <true/>\n"
      ),
      host_ats("        <key>NSAllowsLocalNetworking</key>\n        <true/>\n")
    ]

    for bytes <- cases do
      assert Mode.desired(bytes, nil) == {:ok, bytes}
      assert Mode.inspect_plist(bytes) == {:ok, %{mode: nil, host_ats: true}}
    end
  end

  test "mismatch? treats missing or unreadable under local as drift and not under nil" do
    missing = {:error, %{cause: :missing}}
    assert Mode.mismatch?(:local_loopback, missing)
    refute Mode.mismatch?(nil, missing)
    assert Mode.mismatch?(nil, Mode.inspect_plist(local()))
    assert Mode.mismatch?(:local_loopback, Mode.inspect_plist(production()))
    refute Mode.mismatch?(:local_loopback, Mode.inspect_plist(local()))
    refute Mode.mismatch?(nil, Mode.inspect_plist(host_ats("")))
  end

  test "check_line and banner" do
    assert Mode.check_line("http://127.0.0.1:4790", :local_loopback) ==
             "origin mode: local loopback (http://127.0.0.1:4790); Simulator only; not production-ready; before distributing, switch to your HTTPS production origin and regenerate"

    assert Mode.check_line("https://x.test", nil) == nil

    assert Mode.readme_banner() ==
             "Local loopback build for Simulator demonstration. Not physical, adopter, or release evidence."
  end
end
