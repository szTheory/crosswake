defmodule CrosswakeExample.FieldService.JobsTest do
  use ExUnit.Case, async: true

  @jobs Module.concat([CrosswakeExample, FieldService, Jobs])

  @tag :fieldserv_jobs_context
  test "Fieldserv jobs context contract exposes read-only job, inspection, evidence, and posture helpers" do
    module =
      assert_exported!(
        @jobs,
        :list_jobs,
        0,
        "Fieldserv jobs context contract D-01/D-02/D-09 requires #{@jobs}.list_jobs/0"
      )

    for {function, arity} <- [
          get_job!: 1,
          job_summary!: 1,
          inspection_context!: 1,
          evidence_context!: 1,
          route_posture!: 1
        ] do
      assert function_exported?(module, function, arity),
             "Fieldserv jobs context contract D-09 requires #{@jobs}.#{function}/#{arity}"
    end

    jobs = apply(module, :list_jobs, [])
    assert length(jobs) >= 3, "Fieldserv jobs context contract D-04 requires multiple jobs"

    job = apply(module, :get_job!, ["job-1"])
    assert job.id == "job-1", "Fieldserv jobs context contract D-02 requires stable job-1"

    assert_raise ArgumentError, ~r/unknown Fieldserv job/, fn ->
      apply(module, :get_job!, ["missing-job"])
    end

    summary = apply(module, :job_summary!, ["job-1"])
    assert summary.route_id == "fieldserv-job"
    assert is_binary(summary.asset_label)
    assert is_binary(summary.technician_label)

    inspection = apply(module, :inspection_context!, ["job-1"])
    assert length(inspection.checklist_items) >= 5
    assert inspection.cached_snapshot == "Cached read-only"

    requirements = Map.fetch!(inspection, :future_offline_island_requirements)

    for phrase <- [
          "local draft storage",
          "journal/outbox",
          "replay outcomes",
          "conflict review",
          "reconciliation proof"
        ] do
      assert Enum.any?(requirements, &String.contains?(&1, phrase)),
             "Fieldserv jobs context contract D-26 requires future offline-island requirement #{inspect(phrase)}"
    end

    refute inspect(inspection) =~ ~r/saved locally|queued for sync|working offline/i,
           "Fieldserv jobs context contract D-24/D-27 forbids shipped local mutation copy"

    evidence = apply(module, :evidence_context!, ["job-1"])
    assert Enum.any?(evidence.evidence_items, &(Map.get(&1, :status) == :backend_verification_pending)),
           "Fieldserv jobs context contract D-19 requires backend verification pending state"

    posture = apply(module, :route_posture!, ["fieldserv-job-capture"])
    assert posture.route_id == "fieldserv-job-capture"
    assert posture.runtime_owner in [:native_screen, "native_screen"]
  end

  defp assert_exported!(module, function, arity, message) do
    assert Code.ensure_loaded?(module), "#{message}; module is not loadable"
    assert function_exported?(module, function, arity), "#{message}; function is not exported"
    module
  end
end
