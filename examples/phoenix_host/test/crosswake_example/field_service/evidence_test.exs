defmodule CrosswakeExample.FieldService.EvidenceTest do
  use ExUnit.Case, async: false

  @evidence Module.concat([CrosswakeExample, FieldService, Evidence])
  @event Module.concat([CrosswakeExample, FieldService, EvidenceEvent])
  @state Module.concat([CrosswakeExample, FieldService, TechnicianJobState])

  @scope %{
    job_id: "job-1",
    evidence_id: "evidence-1",
    asset_id: "asset-windshield-1",
    technician_id: "tech-rivera",
    route_id: "fieldserv-evidence-review",
    support_ref: "support:fieldserv:evidence"
  }

  @tag :fieldserv_evidence_state
  test "Fieldserv evidence state contract persists backend-authoritative evidence events and technician state" do
    assert_exported!(
      @event,
      :changeset,
      2,
      "Fieldserv evidence state contract D-11/D-12/D-19 requires EvidenceEvent.changeset/2"
    )

    assert_exported!(
      @state,
      :changeset,
      2,
      "Fieldserv evidence state contract D-11/D-12 requires TechnicianJobState.changeset/2"
    )

    module =
      assert_exported!(
        @evidence,
        :reset!,
        0,
        "Fieldserv evidence state contract D-13 requires #{@evidence}.reset!/0"
      )

    for {function, arity} <- [
          digest_components: 0,
          list_evidence_events: 1,
          record_inspection_event: 3,
          record_device_evidence: 3,
          start_backend_verification: 3,
          mark_backend_verified: 3,
          mark_backend_rejected: 3
        ] do
      assert function_exported?(module, function, arity),
             "Fieldserv evidence state contract D-11/D-12/D-19 requires #{@evidence}.#{function}/#{arity}"
    end

    first = apply(module, :reset!, [])
    second = apply(module, :reset!, [])

    assert first == second,
           "Fieldserv evidence state contract D-13 requires idempotent reset counts"

    {:ok, device_event} =
      apply(module, :record_device_evidence, [
        "job-1",
        "evidence-1",
        Map.merge(@scope, %{token: "must-not-persist", provider_payload: %{secret: true}})
      ])

    assert device_event.status == :device_evidence_recorded

    refute Map.has_key?(device_event.metadata, "token"),
           "Fieldserv evidence state contract T-150-19 requires token metadata to be sanitized"

    refute Map.has_key?(device_event.metadata, "provider_payload"),
           "Fieldserv evidence state contract T-150-19 requires provider payloads to be sanitized"

    {:ok, pending} =
      apply(module, :start_backend_verification, ["job-1", "evidence-1", @scope])

    assert pending.status == :backend_verification_pending

    {:ok, verified} =
      apply(module, :mark_backend_verified, ["job-1", "evidence-1", @scope])

    assert verified.status == :backend_verified

    {:ok, rejected} =
      apply(module, :mark_backend_rejected, ["job-1", "evidence-2", Map.put(@scope, :evidence_id, "evidence-2")])

    assert rejected.status == :backend_rejected

    events = apply(module, :list_evidence_events, ["job-1"])
    assert length(events) >= 4

    assert Enum.any?(events, &(Map.get(&1, :event_type) == :device_evidence_recorded)),
           "Fieldserv evidence state contract D-19 requires device evidence before backend availability"

    assert Enum.any?(events, &(Map.get(&1, :event_type) == :backend_verified_available)),
           "Fieldserv evidence state contract D-19 requires backend verified availability as explicit authority"
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end
end
