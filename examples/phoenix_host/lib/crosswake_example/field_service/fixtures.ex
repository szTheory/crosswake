defmodule CrosswakeExample.FieldService.Fixtures do
  @moduledoc """
  Deterministic Fieldserv fixtures for the field-service showcase lane.
  """

  @dispatcher %{
    id: "dispatcher-noor",
    name: "Noor Dispatcher",
    label: "Dispatch lead",
    shift: "East storm response",
    status: :coordinating,
    support_ref: "support:fieldserv-dispatch"
  }

  @adjuster %{
    id: "adjuster-inez",
    name: "Inez Adjuster",
    label: "Evidence reviewer",
    queue: "Glass and exterior claims",
    status: :reviewing,
    support_ref: "support:fieldserv-review"
  }

  @technicians [
    %{
      id: "tech-rivera",
      name: "Sam Rivera",
      label: "Sam Inspector",
      state: :en_route,
      current_job_id: "job-1",
      device_state: "Native app signed in; camera permission not yet granted",
      last_seen: "8 min ago"
    },
    %{
      id: "tech-chen",
      name: "Mina Chen",
      label: "Roof specialist",
      state: :on_site,
      current_job_id: "job-2",
      device_state: "Inspection context loaded from cached read-only snapshot",
      last_seen: "2 min ago"
    },
    %{
      id: "tech-okafor",
      name: "Tariq Okafor",
      label: "Moisture scan reviewer",
      state: :awaiting_review,
      current_job_id: "job-3",
      device_state: "Evidence review is waiting on backend verification",
      last_seen: "14 min ago"
    }
  ]

  @assets [
    %{
      id: "asset-windshield-1",
      claim_id: "claim-field-1001",
      label: "Windshield - 2022 delivery van",
      type: :vehicle_glass,
      site: "Ridgeway depot north lot",
      risk: :high_visibility_damage,
      summary: "Broken windshield with spreading crack across driver sightline"
    },
    %{
      id: "asset-roof-1",
      claim_id: "claim-field-1002",
      label: "Roof panel - hail impact",
      type: :roof_panel,
      site: "Ridgeway warehouse annex",
      risk: :storm_damage,
      summary: "Hail strikes visible on raised metal roof seams"
    },
    %{
      id: "asset-moisture-1",
      claim_id: "claim-field-1003",
      label: "Ceiling moisture scan",
      type: :interior_water,
      site: "Ridgeway training room",
      risk: :hidden_water_intrusion,
      summary: "Moisture scan requested after overnight roof leak"
    }
  ]

  @jobs [
    %{
      id: "job-1",
      claim_id: "claim-field-1001",
      title: "Broken windshield",
      priority: :urgent,
      status: :awaiting_capture,
      route_id: "fieldserv-job",
      asset_id: "asset-windshield-1",
      technician_id: "tech-rivera",
      dispatcher_id: @dispatcher.id,
      adjuster_id: @adjuster.id,
      inspection_template_id: "inspection-template-field-damage",
      evidence_id: "evidence-1",
      blocker: "Camera capture requires the native app runtime.",
      cached_snapshot_updated_at: "2026-07-11T12:44:00Z",
      queue_rank: 1
    },
    %{
      id: "job-2",
      claim_id: "claim-field-1002",
      title: "Hail damage",
      priority: :high,
      status: :inspection_in_progress,
      route_id: "fieldserv-job",
      asset_id: "asset-roof-1",
      technician_id: "tech-chen",
      dispatcher_id: @dispatcher.id,
      adjuster_id: @adjuster.id,
      inspection_template_id: "inspection-template-field-damage",
      evidence_id: "evidence-3",
      blocker: "Scanner support is a future native-control candidate.",
      cached_snapshot_updated_at: "2026-07-11T12:31:00Z",
      queue_rank: 2
    },
    %{
      id: "job-3",
      claim_id: "claim-field-1003",
      title: "Roof moisture scan",
      priority: :standard,
      status: :backend_review,
      route_id: "fieldserv-job",
      asset_id: "asset-moisture-1",
      technician_id: "tech-okafor",
      dispatcher_id: @dispatcher.id,
      adjuster_id: @adjuster.id,
      inspection_template_id: "inspection-template-field-damage",
      evidence_id: "evidence-4",
      blocker: "Device evidence is pending backend verification.",
      cached_snapshot_updated_at: "2026-07-11T12:17:00Z",
      queue_rank: 3
    }
  ]

  @inspection_templates [
    %{
      id: "inspection-template-field-damage",
      title: "Exterior damage inspection",
      route_id: "fieldserv-inspection",
      checklist_items: [
        %{
          id: "checklist-1",
          label: "Confirm asset identity and claim reference",
          status: :complete,
          evidence_required: false
        },
        %{
          id: "checklist-2",
          label: "Record visible damage severity",
          status: :in_progress,
          evidence_required: false
        },
        %{
          id: "checklist-3",
          label: "Request native camera capture for close evidence",
          status: :blocked_native_runtime,
          evidence_required: true
        },
        %{
          id: "checklist-4",
          label: "Flag scanner or document-scan need",
          status: :future_gap,
          evidence_required: false
        },
        %{
          id: "checklist-5",
          label: "Submit backend verification review",
          status: :waiting_backend,
          evidence_required: true
        }
      ]
    }
  ]

  @notes [
    %{
      id: "note-1",
      job_id: "job-1",
      actor_id: "dispatcher-noor",
      event_type: :job_assigned,
      summary: "Noor assigned Sam to the windshield claim and marked capture as required.",
      route_id: "fieldserv-jobs",
      recorded_at: "2026-07-11T12:35:00Z"
    },
    %{
      id: "note-2",
      job_id: "job-1",
      actor_id: "tech-rivera",
      event_type: :inspection_started,
      summary: "Sam opened the inspection workspace from a cached read-only job snapshot.",
      route_id: "fieldserv-inspection",
      recorded_at: "2026-07-11T12:41:00Z"
    },
    %{
      id: "note-3",
      job_id: "job-1",
      actor_id: "tech-rivera",
      event_type: :capture_intent_requested,
      summary: "Sam requested native camera capture; browser fallback stays unavailable.",
      route_id: "fieldserv-job-capture",
      recorded_at: "2026-07-11T12:47:00Z"
    },
    %{
      id: "note-4",
      job_id: "job-2",
      actor_id: "tech-chen",
      event_type: :scanner_unavailable,
      summary: "Mina marked scanner support as a future native-control candidate.",
      route_id: "fieldserv-inspection",
      recorded_at: "2026-07-11T12:49:00Z"
    }
  ]

  @evidence_items [
    %{
      id: "evidence-1",
      job_id: "job-1",
      title: "Windshield crack overview",
      status: :device_evidence_recorded,
      status_label: "Device evidence recorded",
      route_id: "fieldserv-evidence-review",
      source: :native_capture,
      backend_authority: "Backend verification required before media availability",
      available_media: false
    },
    %{
      id: "evidence-2",
      job_id: "job-1",
      title: "Driver sightline detail",
      status: :backend_verification_pending,
      status_label: "Backend verification pending",
      route_id: "fieldserv-evidence-review",
      source: :native_capture,
      backend_authority: "Device evidence is pending backend verification.",
      available_media: false
    },
    %{
      id: "evidence-3",
      job_id: "job-2",
      title: "Hail strike photo set",
      status: :backend_verified,
      status_label: "Backend verified",
      route_id: "fieldserv-evidence-review",
      source: :native_capture,
      backend_authority: "Backend verified evidence is available to reviewers.",
      available_media: true
    },
    %{
      id: "evidence-4",
      job_id: "job-3",
      title: "Moisture scan image",
      status: :backend_rejected,
      status_label: "Backend rejected",
      route_id: "fieldserv-evidence-review",
      source: :native_capture,
      backend_authority: "Backend rejected this device evidence for missing context.",
      available_media: false
    }
  ]

  @route_postures [
    %{
      route_id: "fieldserv-jobs",
      path: "/fieldserv/jobs",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Demo pressure",
      badge_label: "LiveView route",
      rough_edge: "Cached job snapshots are read-only."
    },
    %{
      route_id: "fieldserv-job",
      path: "/fieldserv/jobs/:id",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Demo pressure",
      badge_label: "LiveView route",
      rough_edge: "This cached job snapshot cannot be edited offline."
    },
    %{
      route_id: "fieldserv-inspection",
      path: "/fieldserv/jobs/:id/inspection",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :standard,
      support_label: "Future gap",
      badge_label: "Future offline island candidate",
      rough_edge: "Inspection drafts need storage, replay, conflict, and reconciliation proof before local mutation."
    },
    %{
      route_id: "fieldserv-job-capture",
      path: "/fieldserv/jobs/:id/capture",
      runtime_owner: :native_screen,
      offline_posture: :cached_read_only,
      security_posture: :sensitive,
      support_label: "Next-pack candidate",
      badge_label: "Requires native runtime",
      rough_edge: "Camera capture requires the native app runtime."
    },
    %{
      route_id: "fieldserv-evidence-review",
      path: "/fieldserv/jobs/:id/evidence/:evidence_id/review",
      runtime_owner: :live_view,
      offline_posture: :cached_read_only,
      security_posture: :sensitive,
      support_label: "Demo pressure",
      badge_label: "LiveView backend review",
      rough_edge: "Device evidence is pending backend verification."
    }
  ]

  @support_findings [
    %{
      id: "support-cached-read",
      label: "Cached read-only",
      route_id: "fieldserv-job",
      finding: "Job snapshots can be stale and cannot mutate canonical server rows."
    },
    %{
      id: "support-native-capture",
      label: "Requires native runtime",
      route_id: "fieldserv-job-capture",
      finding: "Native code owns camera permission, capture session, and platform UI."
    },
    %{
      id: "support-scanner-gap",
      label: "Future gap",
      route_id: "fieldserv-inspection",
      finding: "Scanner and document scan remain future native-control candidates."
    },
    %{
      id: "support-backend-authority",
      label: "Pending server confirmation",
      route_id: "fieldserv-evidence-review",
      finding: "Backend verification owns media availability."
    }
  ]

  @permission_pressure [
    %{
      id: "pressure-camera-capture",
      capability: :capture,
      label: "Camera capture",
      route_id: "fieldserv-job-capture",
      posture: :native_runtime_pressure,
      support_label: "Next-pack candidate",
      summary: "Camera capture requires the native app runtime."
    },
    %{
      id: "pressure-scanner",
      capability: :scanner,
      label: "Scanner",
      route_id: "fieldserv-inspection",
      posture: :future_gap,
      support_label: "Future gap",
      summary: "Scanner support is a future native-control candidate."
    },
    %{
      id: "pressure-document-scan",
      capability: :document_scan,
      label: "Document scan",
      route_id: "fieldserv-inspection",
      posture: :future_gap,
      support_label: "Future gap",
      summary: "Document scan is represented as capability pressure, not runnable support."
    },
    %{
      id: "pressure-permission-rationale",
      capability: :permissions,
      label: "Permission rationale",
      route_id: "fieldserv-job-capture",
      posture: :native_runtime_pressure,
      support_label: "Demo pressure",
      summary: "Permission needed; camera permission belongs inside the native capture screen."
    },
    %{
      id: "pressure-media-upload",
      capability: :media_upload,
      label: "Media upload",
      route_id: "fieldserv-job-capture",
      posture: :backend_verification_required,
      support_label: "Demo pressure",
      summary: "Upload preparation requires native capture source and backend verification."
    },
    %{
      id: "pressure-offline-inspection",
      capability: :offline_inspection,
      label: "Offline inspection",
      route_id: "fieldserv-inspection",
      posture: :cached_read_only_pressure,
      support_label: "Future gap",
      summary: "Offline inspection requires a route-local island with storage, replay, conflict, and reconciliation proof."
    },
    %{
      id: "pressure-native-rebuild",
      capability: :native_rebuild,
      label: "Native rebuild",
      route_id: "fieldserv-job-capture",
      posture: :native_runtime_pressure,
      support_label: "Next-pack candidate",
      summary: "Native capture changes require host app rebuild and proof."
    }
  ]

  @digest_fields %{
    job: [:id, :title, :status],
    asset: [:id, :label, :type],
    technician: [:id, :name, :state],
    inspection_template: [:id, :title],
    checklist_item: [:id, :label, :status],
    note: [:id, :event_type, :route_id],
    evidence_item: [:id, :title, :status],
    route_posture: [:route_id, :runtime_owner, :offline_posture],
    support_finding: [:id, :label, :route_id],
    permission_pressure: [:id, :capability, :support_label]
  }

  def seed do
    %{
      jobs: @jobs,
      assets: @assets,
      technicians: @technicians,
      dispatcher: @dispatcher,
      adjuster: @adjuster,
      inspection_templates: @inspection_templates,
      notes: @notes,
      evidence_items: @evidence_items,
      route_postures: @route_postures,
      support_findings: @support_findings,
      permission_pressure: @permission_pressure
    }
  end

  def jobs, do: @jobs
  def assets, do: @assets
  def technicians, do: @technicians
  def dispatcher, do: @dispatcher
  def adjuster, do: @adjuster
  def inspection_templates, do: @inspection_templates
  def notes, do: @notes
  def evidence_items, do: @evidence_items
  def route_postures, do: @route_postures
  def support_findings, do: @support_findings
  def permission_pressure, do: @permission_pressure

  def digest_components do
    [
      digest_component(:dispatcher, @dispatcher),
      digest_component(:adjuster, @adjuster),
      Enum.map(@jobs, &digest_component(:job, &1)),
      Enum.map(@assets, &digest_component(:asset, &1)),
      Enum.map(@technicians, &digest_component(:technician, &1)),
      Enum.flat_map(@inspection_templates, fn template ->
        [
          digest_component(:inspection_template, template),
          Enum.map(template.checklist_items, &digest_component(:checklist_item, &1))
        ]
      end),
      Enum.map(@notes, &digest_component(:note, &1)),
      Enum.map(@evidence_items, &digest_component(:evidence_item, &1)),
      Enum.map(@route_postures, &digest_component(:route_posture, &1)),
      Enum.map(@support_findings, &digest_component(:support_finding, &1)),
      Enum.map(@permission_pressure, &digest_component(:permission_pressure, &1))
    ]
    |> List.flatten()
    |> Enum.sort()
  end

  defp digest_component(:dispatcher, dispatcher) do
    "field_service.dispatcher:#{dispatcher.id}:#{dispatcher.name}:#{dispatcher.status}"
  end

  defp digest_component(:adjuster, adjuster) do
    "field_service.adjuster:#{adjuster.id}:#{adjuster.name}:#{adjuster.status}"
  end

  defp digest_component(type, record) do
    fields =
      @digest_fields
      |> Map.fetch!(type)
      |> Enum.map(&Map.fetch!(record, &1))
      |> Enum.join(":")

    "field_service.#{type}:#{fields}"
  end
end
