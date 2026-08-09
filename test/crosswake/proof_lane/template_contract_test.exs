defmodule Crosswake.ProofLane.TemplateContractTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator}

  @root Path.expand("../../..", __DIR__)

  defp source(path), do: File.read!(Path.join(@root, path))

  defp position(content, needle) do
    {index, _length} = :binary.match(content, needle)
    index
  end

  test "generated browser adapter fixture is byte-identical to the fixed safe render" do
    config = %Config{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: "/tmp/crosswake-proof-lane/native/ios"
    }

    rendered =
      EEx.eval_file(
        Path.join(@root, "priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex"),
        assigns: [config: config, template_version: 1]
      )

    assert rendered ==
             source("examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts")
  end

  test "generated browser adapter retains the closed offline-island semantic sequence" do
    template = source("priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex")

    assert template =~ "export async function runOfflineIslandProof"
    assert template =~ "adapter.navigate"
    assert template =~ "adapter.performMutation"
    assert template =~ "adapter.readQueuedRecord"
    assert template =~ "adapter.reconnect"
    assert template =~ "adapter.assertBackendConfirmation"
    assert template =~ "adapter.assertOutboxEmpty"
    assert template =~ "adapter.assertDuplicateIdempotency"
    assert template =~ "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    assert template =~ "PL-BROWSER-MUTATION-ID"
    refute template =~ "throw new Error(`"
    refute template =~ "LearnLoop"
    refute template =~ "EvidenceManifest"
  end

  test "fresh generator output is an executable version-2 Playwright spec with a fail-closed host adapter" do
    root = Path.join(System.tmp_dir!(), "proof-lane-render-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    config = %Config{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: Path.join(root, "native/ios")
    }

    try do
      assert {:ok, _} = Generator.generate(config)
      spec = File.read!(Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts"))

      adapter =
        File.read!(Path.join(root, "e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts"))

      manifest = File.read!(Path.join(root, ".crosswake/proof_lane.json"))

      assert spec =~ "import { test } from '@playwright/test'"
      assert spec =~ "proofLaneHostAdapter"
      assert spec =~ "runOfflineIslandProof(page, context, proofLaneHostAdapter, proofLaneConfig)"
      assert adapter =~ "export const proofLaneHostAdapter"
      assert adapter =~ "satisfies ProofLaneAdapter"
      assert adapter =~ "PL-BROWSER-HOST-ADAPTER"
      assert manifest =~ "\"template_version\":5"
      assert manifest =~ "e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts"
    after
      File.rm_rf!(root)
    end
  end

  test "Phoenix-host proof command isolates, typechecks, and selects only the generated browser proof" do
    spec_path = "examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts"
    support_path = "examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts"
    spec_relative = "e2e/crosswake_proof_lane/proof_lane.spec.ts"
    support_relative = "e2e/crosswake_proof_lane/support/proof_lane.ts"
    adapter_relative = "e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts"
    adapter_fixture = "test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts"
    package = source("examples/phoenix_host/package.json")
    typecheck = source("examples/phoenix_host/tsconfig.offline_route_proof.json")
    wrapper = source("script/verify_phoenix_host_proof_lane.sh")

    assert File.exists?(Path.join(@root, spec_path))
    assert File.exists?(Path.join(@root, support_path))
    assert File.exists?(Path.join(@root, adapter_fixture))
    assert package =~ spec_relative
    assert typecheck =~ spec_relative
    assert typecheck =~ support_relative
    assert wrapper =~ "mktemp -d"
    assert wrapper =~ "proof_lane_host_adapter.ts"
    assert wrapper =~ adapter_relative
    assert wrapper =~ "--exclude 'e2e/crosswake_proof_lane/proof_lane.spec.ts'"
    assert wrapper =~ "--exclude 'e2e/crosswake_proof_lane/support/proof_lane.ts'"
    assert wrapper =~ spec_relative
    assert wrapper =~ support_relative

    assert wrapper =~
             "playwright test --config playwright.config.ts e2e/crosswake_proof_lane/proof_lane.spec.ts"
  end

  test "proof project declares concrete separate XCTest and XCUITest source membership" do
    project =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"
      )

    for token <- [
          "ProofLaneDriver.swift in Sources",
          "ProofLaneContractTests.swift in Sources",
          "ProofLaneUITests.swift in Sources",
          "pronunciation-pack-fixture.bin in Resources",
          "CrosswakeProofLaneTests",
          "CrosswakeProofLaneUITests",
          "TestTargetID"
        ] do
      assert project =~ token
    end
  end

  test "proof project gives each target an independent build configuration" do
    project =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"
      )

    for configuration <- [
          "A10000000000000000000070",
          "A10000000000000000000072",
          "A10000000000000000000074",
          "A10000000000000000000076"
        ] do
      assert project =~ configuration
    end

    assert project =~ "PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane.tests"
    assert project =~ "PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane.uitests"
  end

  test "proof project gives every generated target a concrete product and module output name" do
    project =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"
      )

    for target <- ["CrosswakeProofLane", "CrosswakeProofLaneTests", "CrosswakeProofLaneUITests"] do
      assert project =~ "PRODUCT_NAME = #{target}"
      assert project =~ "PRODUCT_MODULE_NAME = #{target}"
    end

    assert project =~ "path = CrosswakeProofLane.app"
    assert project =~ "explicitFileType = wrapper.application"
    assert project =~ "ENABLE_TESTABILITY = YES"

    assert project =~
             "TEST_HOST = \"$(BUILT_PRODUCTS_DIR)/CrosswakeProofLane.app/CrosswakeProofLane\""

    assert project =~ "BUNDLE_LOADER = \"$(TEST_HOST)\""
  end

  test "native test templates use deterministic and accessibility-only boundaries" do
    app = source("priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex")

    contract =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"
      )

    ui =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
      )

    assert contract =~ "XCTestCase"
    assert contract =~ "ProofLaneHostAdapter"
    assert contract =~ "testMissingAdapterRemainsUnavailable"
    assert contract =~ "testPhysicalSequenceStopsAtTheFirstNonPassingHostOperation"
    assert contract =~ "RecordingPhysicalIphoneAdapter"
    assert contract =~ "PhysicalIphoneOperation"
    assert contract =~ "testFixtureInstallReconcilesAfterRelaunch"
    assert contract =~ "testWrongRequirementAndFailedAudioRemainNonPassing"
    assert contract =~ "ProofLaneEvidenceDocument"
    assert contract =~ "emitStructuredEvidence"
    assert contract =~ "audioEvidenceForContractTest"
    refute contract =~ "networking_disabled"
    assert contract =~ "print(output)"
    refute contract =~ "XCTSkip"
    assert ui =~ "XCUIApplication"
    assert ui =~ "testMissingProviderInstallRelaunchAndOfflineAudio"
    assert ui =~ "testAccessibilityReflowContract"
    assert ui =~ "terminate()"
    assert ui =~ "launch()"
    assert ui =~ "matching(identifier:"
    assert ui =~ "proof-lane-outcome"
    assert ui =~ "proof-lane-reconnect"
    assert ui =~ "UIContentSizeCategoryAccessibility"
    assert ui =~ "proof-lane-ready"
    assert ui =~ "proof-lane-pack-status"
    assert ui =~ "proof-lane-pack-install"
    assert ui =~ "proof-lane-pack-audio"
    assert ui =~ "testMissingProviderInstallRelaunchAndOfflineAudio"
    assert ui =~ "CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"
    assert ui =~ "CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"
    refute ui =~ "CROSSWAKE_PROOF_LANE_NETWORK_DISABLED"
    assert ui =~ "proof-lane-auth-posture"
    assert ui =~ "24"
    assert ui =~ "app.scrollViews.count, 0"
    assert ui =~ "44"
    refute ui =~ "resetContentAndSettings"
    refute ui =~ "XCTSkip"

    reset = "ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()"
    factory = "ProofLaneHostAdapterFactory.make()"
    blocked = "equals: \"Blocked: packAudio\""
    reset_marker = "PACK-RESET-BLOCKED"
    install_tap = "install.tap()"
    passed = "equals: \"Passed: packAudio\""
    install_marker = "PACK-INSTALL-READY"

    assert position(app, reset) < position(app, factory)
    assert position(ui, blocked) < position(ui, reset_marker)
    assert position(ui, reset_marker) < position(ui, install_tap)
    assert position(ui, install_tap) < position(ui, passed)
    assert position(ui, passed) < position(ui, install_marker)

    assert ui =~
             "app.launchEnvironment.removeValue(forKey: \"CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK\")"
  end

  test "Phoenix authority producer emits only after the host callback contract passes" do
    phoenix = source("priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex")

    assert phoenix =~ "CROSSWAKE_PHYSICAL_IPHONE_PHOENIX_CONTRACT_MODE"
    assert phoenix =~ "emit_backend_authority_report()"
    assert phoenix =~ "IO.write(Jason.encode!(backend_authority_report()))"

    assert position(phoenix, "assert Enum.map(@authority_assertions") <
             position(phoenix, "emit_backend_authority_report()")
  end

  test "required study-status UI assertions fail closed without their host adapter" do
    ui =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
      )

    assert ui =~ "requireStudyStatusHostAdapter()"
    assert ui =~ "XCTFail(\"PL-STUDY-STATUS-HOST-ADAPTER\")"
    refute ui =~ "guard hasStudyStatusHostAdapter else { return }"
    assert ui =~ "CROSSWAKE_PROOF_LANE_STUDY_HOST_ADAPTER"
  end

  test "generated iOS lane owns a missing-only real-byte fixture and closed pack callbacks" do
    generator = source("lib/crosswake/proof_lane/generator.ex")
    driver = source("priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex")

    fixture =
      source(
        "priv/templates/crosswake/proof_lane/ios/Resources/pronunciation-pack-fixture.bin.eex"
      )

    assert generator =~ "pronunciation-pack-fixture.bin"
    assert generator =~ "@template_version 5"
    assert fixture != ""
    assert driver =~ "installPronunciationPackForeground"
    assert driver =~ "exerciseInstalledPronunciationAudioOffline"
    assert driver =~ "ProofLaneReferencePackAdapter"
    assert driver =~ "CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"
    assert driver =~ "ProofLanePackRequirement"
    assert driver =~ "ProofLaneInstalledRecord"
    assert driver =~ "SHA256"
    assert driver =~ "URLSession"
    assert driver =~ "URLProtocol"
    assert driver =~ "notConnectedToInternet"
    assert driver =~ "ProofLaneDenyingURLProtocol"
    refute driver =~ "CROSSWAKE_PROOF_LANE_NETWORK_DISABLED"
    assert driver =~ "Application Support"

    refute driver =~ "localizedDescription"
    refute driver =~ "archive"
  end

  test "generated iOS lane exposes only a fail-closed navigation observation seam" do
    generator = source("lib/crosswake/proof_lane/generator.ex")
    driver = source("priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex")

    contract =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"
      )

    project =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"
      )

    assert generator =~ "ProofLaneContractTests.swift"
    assert generator =~ "@template_version 5"
    assert driver =~ "ProofLaneNavigationHostAdapter"
    assert driver =~ "PL-IOS-NAV-TOPOLOGY"
    assert driver =~ "PL-IOS-NAV-PATCH-DEPTH"
    assert driver =~ "PL-IOS-NAV-NAVIGATE-ONCE"
    assert driver =~ "PL-IOS-NAV-RESTORE"
    assert driver =~ "PL-IOS-NAV-TABS-BACK"
    assert driver =~ "PL-IOS-NAV-MARKER-INSETS"
    assert driver =~ "PL-IOS-NAV-FOCUS"
    assert contract =~ "testNavigationRemainsUnavailableWithoutProductionHostObservations"
    assert contract =~ "testReferencePackDoesNotCreateNavigationEvidence"
    assert contract =~ "ProofLaneNavigationEvidenceDocument"
    assert project =~ "ProofLaneContractTests.swift in Sources"

    navigation_factory =
      driver
      |> String.split("enum ProofLaneNavigationHostAdapterFactory", parts: 2)
      |> List.last()
      |> String.split("enum ProofLaneNavigationContract", parts: 2)
      |> List.first()

    assert navigation_factory =~ "nil"
    refute navigation_factory =~ "CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"
    refute navigation_factory =~ ".passed"

    for forbidden <- [
          "WKBackForwardList",
          "window.history",
          "routePath",
          "routePayload",
          "ProofLaneReferenceNavigationAdapter",
          "func topology(",
          "func transition(",
          "return .passed",
          "UIAlert",
          "Android"
        ] do
      refute driver =~ forbidden
    end
  end

  test "generator supplies a missing-only physical iPhone host adapter skeleton" do
    generator = source("lib/crosswake/proof_lane/generator.ex")

    template_path =
      "priv/templates/crosswake/proof_lane/physical_iphone/physical_iphone_proof_host.ex.eex"

    assert generator =~ "physical_iphone/physical_iphone_proof_host.ex"
    assert File.exists?(template_path)

    template = source(template_path)
    assert template =~ "def preflight_options"
    assert template =~ "{:error, :unavailable}"
  end

  test "generated iOS lane makes missing navigation visibly unavailable" do
    ui =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
      )

    for token <- [
          "testReferencePackLeavesNavigationUnavailable",
          "testReferencePackNavigationMarkersRemainUnavailable",
          "proof-lane-navigation-tab",
          "proof-lane-navigation-back",
          "proof-lane-navigation-marker",
          "proof-lane-navigation-insets",
          "proof-lane-navigation-focus"
        ] do
      assert ui =~ token
    end

    for forbidden <- [
          "addAttachment",
          "screenshot",
          "debugDescription",
          "routePayload",
          "XCResult"
        ] do
      refute ui =~ forbidden
    end

    assert ui =~ "Navigation advisory: Unavailable"
    refute ui =~ "Navigation advisory: Passed"
  end

  test "native verifier keeps package and git configuration operation-scoped" do
    verifier = source("script/verify_generated_ios_shell.sh")

    assert verifier =~ "GIT_CONFIG_COUNT"
    assert verifier =~ "-clonedSourcePackagesDirPath"
    refute verifier =~ "git config --global"
    refute verifier =~ "${HOME}/.swiftpm"
    refute verifier =~ "-downloadPlatform"
    assert verifier =~ "testMissingAdapterRemainsUnavailable"
    assert verifier =~ "testNavigationRemainsUnavailableWithoutProductionHostObservations"
    assert verifier =~ "testReferencePackDoesNotCreateNavigationEvidence"
    assert verifier =~ "testMissingProviderInstallRelaunchAndOfflineAudio"
    assert verifier =~ "testAccessibilityReflowContract"
    assert verifier =~ "--reference-pack-adapter"
    assert verifier =~ "assertion_ids"
    assert verifier =~ "pack_audio_prerequisite"
    assert verifier =~ "PL-IOS-TEST-EVIDENCE"
    assert verifier =~ "PL-IOS-NAV-SOURCE"
    assert verifier =~ "PACK-RESET-BLOCKED"
    assert verifier =~ "PACK-INSTALL-READY"
    assert verifier =~ "PACK-RELAUNCH-READY"
    assert verifier =~ "PACK-AUDIO-OFFLINE"
  end

  test "generator reruns preserve edited browser and native proof sources" do
    root =
      Path.join(System.tmp_dir!(), "proof-lane-contract-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)

    config = %Config{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: Path.join(root, "native/ios")
    }

    try do
      assert {:ok, _} = Generator.generate(config)

      for relative <- [
            "e2e/crosswake_proof_lane/support/proof_lane.ts",
            "native/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift",
            "native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift"
          ] do
        path = Path.join(root, relative)
        File.write!(path, "// host-owned proof edit\n")
        assert {:ok, _} = Generator.generate(config)
        assert File.read!(path) == "// host-owned proof edit\n"
      end
    after
      File.rm_rf!(root)
    end
  end

  test "generated Phoenix authority fixture requires closed host callbacks" do
    fixture = source("priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex")

    assert fixture =~ "CrosswakeProofLaneHostAuthority"
    assert fixture =~ "accepted_replay"
    assert fixture =~ "duplicate_replay"
    assert fixture =~ "retained_rejection"
    assert fixture =~ "retained_conflict"
    assert fixture =~ "scope_fence"
    assert fixture =~ "entry_disablement"
    assert fixture =~ "replay_disablement"
    assert fixture =~ "PI-EXACTLY-ONCE-EMPTY-OUTBOX"
    assert fixture =~ "PI-LOGOUT-ACCOUNT-FENCE"
    refute fixture =~ "scope_ref"
    refute fixture =~ "client_mutation_id"
  end
end
