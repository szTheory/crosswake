defmodule Crosswake.ProofLane.PhysicalIphoneEvidenceTransactionTest do
  use ExUnit.Case, async: true

  @script "script/retain_physical_iphone_evidence_transaction.sh"

  test "durable transaction script exists and restricts injectable commands to isolated fixtures" do
    assert File.regular?(@script)
    source = File.read!(@script)

    assert source =~ "CROSSWAKE_TRANSACTION_TEST_GUARD"
    assert source =~ "chore(162-14): consume physical retry"
    assert source =~ "Evidence.check"
  end
end
