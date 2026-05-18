defmodule Crosswake.Proof.Phase5ProofLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest

  test "checked-in Phoenix example host compiles the public pack, transfer, and native capture route surfaces" do
    for path <- [
          "examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/accounts.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/on_mount.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/dashboard_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex",
          "examples/phoenix_host/lib/crosswake_example/saas_portal/settings_live.ex",
          "examples/phoenix_host/lib/crosswake_example/router.ex"
        ] do
      Code.require_file(Path.expand(path, File.cwd!()))
    end

    assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)

    assert manifest.routes["library"].runtime == :live_view
    assert manifest.routes["library"].packs == ["lesson_library@1.2.0"]

    assert Enum.map(manifest.routes["library"].transfers, & &1.id) == [
             "lesson_import",
             "lesson_export",
             "lesson_download"
           ]

    assert manifest.routes["selective-native-claim-capture"].runtime == :native_screen
    assert manifest.routes["selective-native-claim-capture"].packs == ["camera_capture_assets@1.0.0"]
    assert Enum.map(manifest.routes["selective-native-claim-capture"].transfers, & &1.id) == ["capture_upload"]

    assert manifest.routes["saas-dashboard"].runtime == :live_view
    assert manifest.routes["saas-approval"].runtime == :live_view
    assert manifest.routes["saas-approval"].capabilities == ["haptics"]
  end

  test "checked-in iOS and Android example hosts stay aligned to the same example route truth" do
    router = File.read!("examples/phoenix_host/lib/crosswake_example/router.ex")
    approval_live = File.read!("examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex")
    ios_activation = File.read!("examples/ios_shell_host/Fixtures/route_activation.json")
    ios_manifest = File.read!("examples/ios_shell_host/Fixtures/crosswake_manifest.json")
    ios_tests = File.read!("examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift")
    android_activation = File.read!("examples/android_shell_host/app/src/main/assets/route_activation.json")
    android_manifest = File.read!("examples/android_shell_host/app/src/main/assets/crosswake_manifest.json")

    android_instrumented =
      File.read!("examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt")

    assert router =~ "lesson_library"
    assert router =~ "native_screen"
    assert router =~ "capture_upload"
    assert router =~ "saas-approval"
    assert approval_live =~ "haptics.impact"

    assert ios_activation =~ "\"route_id\": \"selective-native-claim-capture\""
    assert ios_activation =~ "\"camera\": \"1.0.0\""
    assert ios_manifest =~ "\"selective-native-claim-capture\""
    assert ios_tests =~ "\"camera\": \"1.0.0\""
    assert ios_tests =~ "https://example.crosswake.invalid/native/claims/claim-1/capture"

    assert android_activation =~ "\"route_id\": \"selective-native-claim-capture\""
    assert android_activation =~ "\"camera\": \"1.0.0\""
    assert android_manifest =~ "\"selective-native-claim-capture\""
    assert android_instrumented =~ "https://example.crosswake.invalid/native/claims/claim-1/capture"
  end

  test "phase 5 proof workflow runs checked-in examples before generated hosts" do
    example_script = File.read!("script/verify_phase5_example_hosts.sh")
    workflow = File.read!(".github/workflows/phase5-proof.yml")

    assert example_script =~ "test/crosswake/proof/phase5_proof_lane_test.exs"
    assert example_script =~ "CROSSWAKE_IOS_PROJECT_ROOT=\"examples/ios_shell_host\""
    assert example_script =~ "CROSSWAKE_ANDROID_PROJECT_ROOT=\"examples/android_shell_host\""

    assert workflow =~ "bash script/verify_phase5_example_hosts.sh"
    assert workflow =~ "bash script/verify_generated_ios_shell.sh"
    assert workflow =~ "bash script/verify_generated_android_shell.sh"

    assert elem(:binary.match(workflow, "bash script/verify_phase5_example_hosts.sh"), 0) <
             elem(:binary.match(workflow, "bash script/verify_generated_ios_shell.sh"), 0)
  end
end
