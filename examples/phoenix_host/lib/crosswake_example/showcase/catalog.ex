defmodule CrosswakeExample.Showcase.Catalog do
  @moduledoc """
  Curated route-card metadata for the example-host showcase hub.

  The catalog owns product copy and visible labels only. Crosswake route policy
  remains authoritative through compiled router metadata.
  """

  alias CrosswakeExample.Showcase.Branding

  @allowed_support_labels [
    "Available today",
    "Proof-backed example",
    "Demo pressure",
    "Advisory evidence",
    "Future gap",
    "Next-pack candidate"
  ]

  @lanes [
    %{
      id: :saas_admin,
      heading: "SaaS/Admin",
      body: "LiveView-first operations with admin and auth pressure kept Phoenix-owned.",
      primary_path: "/saas/dashboard",
      primary_route_id: "saas-dashboard",
      primary_cta: "Open SaaS Lane",
      route_posture: %{
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard,
        capabilities: []
      },
      runtime_labels: ["LiveView route", "Cached read-only"],
      support_labels: ["Available today", "Proof-backed example"],
      capability_chips: [
        "Authenticated member route",
        "Admin posture preview",
        "Phoenix-owned workflow"
      ],
      boundary_note: "Cached read-only does not mean offline edits.",
      v20_pressure_note:
        "Future native affordances should stay low-frequency and route-local, such as action menus or haptics."
    },
    %{
      id: :field_service,
      heading: "Field Service",
      body: "Device-pressure jobs with capture gaps and native-screen candidates named honestly.",
      primary_path: "/fieldserv/jobs",
      primary_route_id: "fieldserv-jobs",
      primary_cta: "Open Field Service Lane",
      route_posture: %{
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard,
        capabilities: []
      },
      runtime_labels: [
        "LiveView route",
        "Cached read-only",
        "Demo pressure",
        "Future native-control candidate"
      ],
      support_labels: ["Demo pressure", "Future gap", "Next-pack candidate"],
      capability_chips: [
        "Native capture handoff",
        "Permission pressure",
        "Native-control candidate"
      ],
      boundary_note:
        "Capture/scanning pressure is future/native-control evidence unless a route-specific proof backs it.",
      v20_pressure_note:
        "Use this lane to decide which scanner, capture, and permission controls belong in the next pack."
    },
    %{
      id: :learning_training,
      heading: "Learning/Training",
      body:
        "Course progress, content packs, offline study, and entitlement pressure with route ownership visible.",
      primary_path: "/learnloop",
      primary_route_id: "learnloop-dashboard",
      primary_cta: "Open LearnLoop",
      route_posture: %{
        runtime: :live_view,
        offline: :cached_read_only,
        security: :standard,
        capabilities: []
      },
      runtime_labels: [
        "LiveView route",
        "Cached read-only",
        "Offline island",
        "Local-first outbox",
        "Backend projection",
        "Mocked storefront evidence"
      ],
      support_labels: ["Proof-backed example", "Demo pressure", "Future gap"],
      capability_chips: [
        "Content pack",
        "IndexedDB outbox",
        "Replay visibility",
        "Backend entitlement projection"
      ],
      boundary_note:
        "Server reset does not clear browser-owned IndexedDB or the local study outbox.",
      v20_pressure_note:
        "Future native storage, sync helpers, and storefront adapters need explicit journals, outboxes, backend projection, and reconciliation proof."
    }
  ]

  @spec lanes() :: [map()]
  def lanes do
    Enum.map(@lanes, &attach_brand/1)
  end

  @spec cards() :: [map()]
  def cards, do: lanes()

  @spec route_ids() :: [String.t()]
  def route_ids do
    Enum.map(@lanes, & &1.primary_route_id)
  end

  @spec allowed_support_labels() :: [String.t()]
  def allowed_support_labels, do: @allowed_support_labels

  defp attach_brand(%{id: id} = lane) do
    Map.put(lane, :brand, Branding.brand_for!(id))
  end
end
