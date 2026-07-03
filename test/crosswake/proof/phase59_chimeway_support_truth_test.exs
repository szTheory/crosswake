defmodule Crosswake.Proof.Phase59ChimawaySupportTruthTest do
  use ExUnit.Case, async: true

  # Phase 59 split: the SupportMatrix.notification_support_truth/0 assertion stays in core.
  # notification_support_truth/0 is a static function returning a fixed map — it does NOT
  # depend on the :companions runtime registry (DECOUPLE-03 / T-136-03 stale-beam fix).
  # The non-vacuity here is structural: the function always returns exactly one element with
  # the expected content (surface, proof_class, delivery_supported, deferred, posture).
  # The chimeway-internal assertions (report_state, struct aliases, raw-token absence,
  # delivery_accepted) moved to packages/crosswake_chimeway/test/crosswake/proof/
  # phase59_chimeway_contract_test.exs where Chimeway modules are available.
  alias Crosswake.SupportMatrix

  test "notification_support_truth/0 returns exactly one advisory truth entry with chimeway surface" do
    assert [notification_truth] = SupportMatrix.notification_support_truth()
    assert notification_truth.surface == "notification-open route activation proof"
    assert notification_truth.proof_class == :advisory
    assert notification_truth.delivery_supported == false
    assert :chimeway_delivery in notification_truth.deferred
    refute :notification_open_routing in notification_truth.deferred

    assert notification_truth.posture =~
             "APNs/FCM delivery is not part of this proof and remains unsupported/advisory"
  end
end
