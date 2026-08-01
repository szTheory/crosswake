defmodule Crosswake.ProofLane.TemplateContractTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator}

  @root Path.expand("../../..", __DIR__)

  defp source(path), do: File.read!(Path.join(@root, path))

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
      EEx.eval_file(Path.join(@root, "priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex"),
        assigns: [config: config, template_version: 1]
      )

    assert rendered == source("examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts")
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

  test "proof project declares concrete separate XCTest and XCUITest source membership" do
    project =
      source(
        "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"
      )

    for token <- [
          "ProofLaneDriver.swift in Sources",
          "ProofLaneContractTests.swift in Sources",
          "ProofLaneUITests.swift in Sources",
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

  test "native test templates use deterministic and accessibility-only boundaries" do
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
    assert contract =~ "testHostAdapterContract"
    assert contract =~ "testMissingAdapterRemainsUnavailable"
    refute contract =~ "XCTSkip"
    assert ui =~ "XCUIApplication"
    assert ui =~ "terminate()"
    assert ui =~ "launch()"
    assert ui =~ "matching(identifier:"
    assert ui =~ "proof-lane-outcome"
    assert ui =~ "proof-lane-reconnect"
    assert ui =~ "UIContentSizeCategoryAccessibility"
    assert ui =~ "44"
    refute ui =~ "resetContentAndSettings"
    refute ui =~ "XCTSkip"
  end

  test "native verifier keeps package and git configuration operation-scoped" do
    verifier = source("script/verify_generated_ios_shell.sh")

    assert verifier =~ "GIT_CONFIG_COUNT"
    assert verifier =~ "-clonedSourcePackagesDirPath"
    refute verifier =~ "git config --global"
    refute verifier =~ "${HOME}/.swiftpm"
    refute verifier =~ "-downloadPlatform"
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
end
