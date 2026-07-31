defmodule Crosswake.Proof.Phase54SigraSupportTruthTest do
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.SupportMatrix

  # D-137-03: SupportMatrix.auth_contract_truth/0 reads Application.get_env(:crosswake, :companions, [])
  # at runtime. Sigra is not in core's application env after extraction (Phase 137). Register it
  # here so denial_codes is populated with the live DenialCodes.codes() result and the support
  # truth assertion is non-vacuous.
  setup do
    prior = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, prior)
    end)

    :ok
  end

  test "support truth locks route posture vocabulary, denial codes, and later-phase non-claims" do
    assert [%{} = row] = SupportMatrix.auth_contract_truth()

    assert row.route_predicates == [:auth_min_level, :requires_recent_auth, :auth_posture]
    assert row.denial_codes == DenialCodes.codes()
    assert "auth_posture" in row.safe_detail_keys
    assert "handoff_ref" in row.safe_detail_keys
    assert row.posture =~ "SessionAuthorityLane route evaluation"
    assert row.posture =~ "handoff ticket/server-record redemption"
    assert row.posture =~ "server records, audit evidence"
    assert "auth.handoff.invalid_ticket" in row.denial_codes
    refute :ceremony in row.deferred
    refute :handoff in row.deferred
    assert :auth_return_boundaries not in row.deferred
    assert row.posture =~ "OAuth/passkey/native auth-return boundary contracts"
    assert String.downcase(row.posture) =~ "refresh-token"
    assert row.posture =~ "Promotion requires an executable host reference proof"
    assert row.posture =~ "backend reauthorization before replay"
    assert row.posture =~ "documentation alone cannot promote a deferred item"
  end
end
