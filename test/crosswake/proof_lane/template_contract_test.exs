defmodule Crosswake.ProofLane.TemplateContractTest do
  use ExUnit.Case, async: true

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
end
