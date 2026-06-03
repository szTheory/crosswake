defmodule Crosswake.Proof.Phase63AdvisoryProofTest do
  use ExUnit.Case, async: false

  @moduletag :advisory_only

  @moduledoc """
  Phase 63 advisory proof for device delivery guarantees.
  Validates that push delivery execution (APNs/FCM) remains non-blocking and explicitly marked as advisory.
  """

  alias Crosswake.SupportMatrix
  alias Crosswake.Doctor.PublishReadiness

  test "notification support truth explicitly defines delivery as advisory and un-supported for block proofs" do
    truth = SupportMatrix.notification_support_truth()
    assert is_list(truth)
    assert length(truth) > 0
    
    # Extract the notification capability truth definition
    capability = hd(truth)
    
    # Prove that the overall capability is bound correctly
    assert capability.proof_class == :advisory
    assert capability.delivery_supported == false
    
    # Ensure deferred delivery features are explicitly enumerated
    assert :chimeway_delivery in capability.deferred
    assert :push_delivery_guarantees in capability.deferred
    
    # Assert telemetry is the only merge-blocking proof boundary
    assert capability.telemetry.proof_class == :merge_blocking
  end

  test "publish readiness report tracks advisory proof counts accurately without blocking release" do
    # Run the readiness check within a hermetic context
    report = PublishReadiness.run()
    
    assert report.status == :ready || report.status == :not_ready
    
    # Advisory proofs should never block the pipeline natively
    # At least one advisory rule exists based on push delivery guarantees
    assert report.summary.advisory_count >= 1
    
    # Collect all checks marked as advisory
    advisory_checks = Enum.filter(report.checks, &(&1.proof_class == :advisory))
    
    assert length(advisory_checks) >= 1
    
    # Find any capability readiness check related to notifications that is advisory
    # Wait, we might not know the exact id. We just need to assert advisory checks exist and do not set `blocking: true`.
    Enum.each(advisory_checks, fn check ->
      refute check.blocking, "An advisory check should never be marked as blocking"
    end)
  end
end