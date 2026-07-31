defmodule Crosswake.ProofLane.TemplateContractTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator}

  @root Path.expand("../../..", __DIR__)

  defp source(path), do: File.read!(Path.join(@root, path))

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
    assert contract =~ ".replayAuthorization), .blocked"
    assert contract =~ ".packAudio), .unavailable"
    refute contract =~ "XCTSkip"
    assert ui =~ "XCUIApplication"
    assert ui =~ "terminate()"
    assert ui =~ "launch()"
    assert ui =~ "matching(identifier:"
    refute ui =~ "resetContentAndSettings"
    refute ui =~ "XCTSkip"
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
