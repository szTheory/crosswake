defmodule Crosswake.ProofLane.PhysicalIphoneEvidenceTransactionTest do
  use ExUnit.Case, async: true

  @script "script/retain_physical_iphone_evidence_transaction.sh"

  test "durable transaction script names a distinct Plan 16 ledger and exact provenance gates" do
    assert File.regular?(@script)
    source = File.read!(@script)

    assert source =~ "CROSSWAKE_TRANSACTION_TEST_GUARD"
    assert source =~ "EVIDENCE_PARENT=\"$(dirname \"$DEST\")\""
    assert source =~ "mkdir -p \"$EVIDENCE_PARENT\" || fail"
    assert source =~ "[ -L \"$EVIDENCE_PARENT\" ] && fail"
    assert source =~ "PARENT_REAL"
    assert source =~ "chore(162-16): consume corrected-provenance run"
    assert source =~ "feat(162-16): retain corrected physical iPhone evidence"
    assert source =~ "merge-base --is-ancestor b79bce8b HEAD"
    assert source =~ "merge-base --is-ancestor c11886b7 HEAD"
    assert source =~ "merge-base --is-ancestor e46f5136 HEAD"
    assert source =~ "jq -er '.commit_ref | sub(\"^git-\"; \"\")'"
    assert source =~ "rev-parse \"$LEDGER_COMMIT^\""
    assert source =~ "Evidence.check"
  end
end
