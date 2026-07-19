defmodule CrosswakeExample.Showcase.Fixtures do
  @moduledoc """
  Deterministic foundation records for the example-host showcase reset.

  This module keeps static showcase accounting local to the example host while
  lane-specific persistence stays owned by its lane context.
  """

  alias CrosswakeExample.FieldService.Evidence, as: FieldServiceEvidence
  alias CrosswakeExample.FieldService.Fixtures, as: FieldServiceFixtures
  alias CrosswakeExample.SaaSPortal.Approvals
  alias CrosswakeExample.SaaSPortal.Fixtures, as: SaaSFixtures

  def reset_saas_admin! do
    data = SaaSFixtures.seed()
    persisted = Approvals.reset!()

    %{
      accounts: 1,
      teams: length(data.teams),
      users: length(data.users),
      roles: length(data.roles),
      settings: 1,
      approvals: persisted.approvals,
      approval_activity_events: persisted.approval_activity_events,
      operational_records: length(data.operational_records),
      approval_policies: length(data.approval_policies),
      activity_events: length(data.activity_events),
      admin_pressure: 1
    }
  end

  def saas_admin_digest_components do
    SaaSFixtures.digest_components() ++ Approvals.digest_components()
  end

  def reset_field_service! do
    data = FieldServiceFixtures.seed()
    persisted = FieldServiceEvidence.reset!()

    %{
      jobs: length(data.jobs),
      assets: length(data.assets),
      technicians: length(data.technicians),
      dispatcher: 1,
      adjuster: 1,
      inspection_templates: length(data.inspection_templates),
      notes: length(data.notes),
      evidence_items: length(data.evidence_items),
      route_postures: length(data.route_postures),
      support_findings: length(data.support_findings),
      permission_pressure: length(data.permission_pressure),
      evidence_events: persisted.evidence_events,
      technician_job_states: persisted.technician_job_states
    }
  end

  def field_service_digest_components do
    FieldServiceFixtures.digest_components() ++ FieldServiceEvidence.digest_components()
  end
end
