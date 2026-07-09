defmodule CrosswakeExample.Showcase.ResetTest do
  use ExUnit.Case, async: false

  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim
  alias CrosswakeExample.SelectiveNative.Fixtures, as: NativeFixtures
  alias CrosswakeExample.Showcase.Reset

  test "reset is idempotent and returns stable counts plus digest" do
    first = Reset.reset!()
    second = Reset.reset!()

    # D-06/D-07/D-08/D-12: the orchestrator delegates to lane-owned deterministic reset helpers.
    assert first.counts == second.counts,
           "D-06/D-07/D-08 require two server-side resets to produce stable lane counts"

    assert first.digest == second.digest,
           "D-12 requires the reset digest to be derived from deterministic records"

    assert is_binary(first.digest)
    assert byte_size(first.digest) == 64
  end

  test "selective-native fixture seed is reset-safe and does not accumulate claim rows" do
    Reset.reset!()

    initial_count = claim_count()
    NativeFixtures.seed()
    after_first_seed = claim_count()
    NativeFixtures.seed()
    after_second_seed = claim_count()

    # D-07/D-10: field-service/native-pressure server fixtures are reset-safe server state only.
    assert initial_count == 2
    assert after_first_seed == initial_count

    assert after_second_seed == initial_count,
           "D-07 requires repeated native-pressure fixture seeds to avoid duplicate persisted claims"
  end

  test "reset result explicitly does not claim browser-owned offline state reset" do
    result = Reset.reset!()

    # D-09/D-10: IndexedDB/outbox reset remains in browser-side Playwright helpers, not here.
    assert result.browser_state_reset == false,
           "D-10 requires the server reset to return browser_state_reset: false"
  end

  test "reset counts cover all three showcase lanes without future-domain schemas" do
    result = Reset.reset!()

    # D-11: Phase 147 proves believable foundation data without modeling every future domain table.
    assert result.counts.saas_admin == %{accounts: 1, approvals: 3, users: 2}
    assert result.counts.field_service_native_pressure == %{claims: 2, submissions: 0}

    assert result.counts.learning_training == %{
             browser_state_reset: false,
             cards: 3,
             decks: 1,
             progress: 0,
             synced_reviews: 0
           }
  end

  defp claim_count do
    Repo.aggregate(from(c in Claim), :count)
  end
end
