
defmodule Crosswake.Proof.Phase5ProofLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.Manifest

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end

  test "checked-in Phoenix example host compiles the public pack, transfer, and native capture route surfaces" do
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
    assert manifest.routes["saas-approval"].capabilities == ["haptics.impact"]
    assert manifest.routes["local-first-study-session"].path == "/study/session"
    assert manifest.routes["local-first-study-history"].path == "/study/history"
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
    assert router =~ "local-first-study-session"
    assert approval_live =~ "haptics.impact"

    assert ios_activation =~ "\"route_id\": \"selective-native-claim-capture\""
    assert ios_activation =~ "\"camera\": \"1.0.0\""
    assert ios_manifest =~ "\"selective-native-claim-capture\""
    assert ios_manifest =~ "\"local-first-study-session\""
    assert ios_manifest =~ "\"local-first-study-history\""
    assert ios_tests =~ "\"camera\": \"1.0.0\""
    assert ios_tests =~ "https://example.crosswake.invalid/native/claims/claim-1/capture"
    assert ios_tests =~ "https://example.crosswake.invalid/study/history"

    assert android_activation =~ "\"route_id\": \"selective-native-claim-capture\""
    assert android_activation =~ "\"camera\": \"1.0.0\""
    assert android_manifest =~ "\"selective-native-claim-capture\""
    assert android_manifest =~ "\"local-first-study-session\""
    assert android_manifest =~ "\"local-first-study-history\""
    assert android_instrumented =~ "https://example.crosswake.invalid/saas/approvals/approval-1"
    assert android_instrumented =~ "https://example.crosswake.invalid/study/history"
  end

  test "phase 5 proof workflow keeps native shell proof delegated to Phase 18" do
    example_script = File.read!("script/verify_phase5_example_hosts.sh")
    workflow = File.read!(".github/workflows/phase5-proof.yml")

    assert example_script =~ "test/crosswake/proof/phase5_proof_lane_test.exs"
    assert example_script =~ "CROSSWAKE_IOS_PROJECT_ROOT=\"examples/ios_shell_host\""
    assert example_script =~ "CROSSWAKE_ANDROID_PROJECT_ROOT=\"examples/android_shell_host\""
    assert example_script =~ "CROSSWAKE_PHASE5_NATIVE_PROOFS"

    assert workflow =~ "bash script/verify_phase5_example_hosts.sh"
    assert workflow =~ "CROSSWAKE_PHASE5_NATIVE_PROOFS: \"0\""
    refute workflow =~ "bash script/verify_generated_ios_shell.sh"
    refute workflow =~ "bash script/verify_generated_android_shell.sh"
  end
end
