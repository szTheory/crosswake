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
      primary_path: "/native/claims/:id/capture",
      primary_route_id: "selective-native-claim-capture",
      primary_cta: "Preview Field Service",
      route_posture: %{
        runtime: :native_screen,
        offline: :cached_read_only,
        security: :sensitive,
        capabilities: [:camera]
      },
      runtime_labels: [
        "Native screen",
        "Requires native runtime",
        "Demo pressure",
        "Future native-control candidate",
        "Sensitive route"
      ],
      support_labels: ["Demo pressure", "Future gap", "Next-pack candidate"],
      capability_chips: [
        "Capture upload seam",
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
      body: "Content packs and offline study without pretending every action commits offline.",
      primary_path: "/offline",
      primary_route_id: "offline-study",
      primary_cta: "Open Offline Study Proof",
      route_posture: %{
        runtime: :offline_island,
        offline: :local_first,
        security: :standard,
        capabilities: []
      },
      runtime_labels: ["Offline island", "Local-first outbox"],
      support_labels: ["Available today", "Proof-backed example"],
      capability_chips: [
        "Content pack",
        "IndexedDB outbox",
        "Replay visibility"
      ],
      boundary_note:
        "Offline study state is browser-owned; server reset does not clear IndexedDB.",
      v20_pressure_note:
        "Future native storage and sync helpers should stay explicit about journals, outboxes, and reconciliation."
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
