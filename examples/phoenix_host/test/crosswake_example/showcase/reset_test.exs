defmodule CrosswakeExample.Showcase.ResetTest do
  use ExUnit.Case, async: false

  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim
  alias CrosswakeExample.SelectiveNative.Fixtures, as: NativeFixtures
  alias CrosswakeExample.Showcase.Reset

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:crosswake_example)
    :ok
  end

  test "reset is idempotent and returns stable counts plus digest" do
    first = Reset.reset!()
    second = Reset.reset!()

    # D-06/D-07/D-08/D-12: the orchestrator delegates to lane-owned deterministic reset helpers.
    assert first.counts == second.counts,
           "D-06/D-07/D-08 require two server-side resets to produce stable lane counts"

    assert first.digest == second.digest,
           "D-12 requires the reset digest to be derived from deterministic records"

    assert first.browser_state_reset == false
    assert second.browser_state_reset == false
    assert Map.has_key?(first.counts, :saas_admin)
    assert Map.has_key?(first.counts, :field_service)
    assert Map.has_key?(first.counts, :learning_training)
    assert is_binary(first.digest)
    assert byte_size(first.digest) == 64
  end

  test "selective-native fixture seed is reset-safe and does not accumulate claim rows" do
    NativeFixtures.seed()
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
    assert result.counts.saas_admin == %{
             accounts: 1,
             activity_events: 3,
             admin_pressure: 1,
             approval_activity_events: 3,
             approval_policies: 3,
             approvals: 3,
             operational_records: 3,
             roles: 3,
             settings: 1,
             teams: 1,
             users: 3
           }

    assert result.counts.field_service == %{
             adjuster: 1,
             assets: 3,
             dispatcher: 1,
             evidence_events: 4,
             evidence_items: 4,
             inspection_templates: 1,
             jobs: 3,
             notes: 4,
             permission_pressure: 7,
             route_postures: 5,
             support_findings: 4,
             technician_job_states: 3,
             technicians: 3
           }

    assert result.counts.learning_training == %{
             browser_state_reset: false,
             content_packs: 2,
             courses: 3,
             learners: 3,
             lessons: 6,
             progress_checkpoints: 3,
             route_postures: 6,
             subscription_states: 4,
             support_findings: 5,
             synced_reviews: 0
           },
           "LearnLoop showcase entry contract D-23/D-29 requires deterministic learning_training reset counts without claiming browser state reset"
  end

  defp claim_count do
    Repo.aggregate(from(c in Claim), :count)
  end
end
