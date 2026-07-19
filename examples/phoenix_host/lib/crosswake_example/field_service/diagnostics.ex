defmodule CrosswakeExample.FieldService.Diagnostics do
  @moduledoc """
  Lane-local Fieldserv route policy diagnostics.

  Compiled router metadata is the source of truth for route ownership. Support
  copy is layered separately so Fieldserv diagnostics do not become a prose-only
  shadow of `router.ex`.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Router
  alias CrosswakeExample.Showcase.Catalog

  @route_ids [
    "fieldserv-jobs",
    "fieldserv-job",
    "fieldserv-inspection",
    "fieldserv-job-capture",
    "fieldserv-evidence-review"
  ]

  @guide_links [
    %{label: "Route policy guide", path: "guides/route_policy.md"},
    %{label: "Capability families", path: "guides/capabilities.md"},
    %{label: "Support matrix", path: "guides/support_matrix.md"},
    %{label: "Native shell guide", path: "guides/native_shell.md"},
    %{label: "Bounded bridge guide", path: "guides/bridge.md"},
    %{label: "Offline guide", path: "guides/offline.md"}
  ]

  @row_guide_links %{
    live_view: ["guides/route_policy.md", "guides/support_matrix.md", "guides/offline.md"],
    native_capture: [
      "guides/route_policy.md",
      "guides/native_shell.md",
      "guides/capabilities.md",
      "guides/bridge.md"
    ],
    evidence: ["guides/route_policy.md", "guides/support_matrix.md", "guides/capabilities.md"]
  }

  @support_enrichment %{
    "fieldserv-jobs" => %{
      support_label: "Demo pressure",
      rough_edge: "Cached job queue snapshots are read-only dispatch context.",
      guide_links: @row_guide_links.live_view,
      next_pack_pressure_note: "Scanner, permissions, and capture controls remain capability-map inputs."
    },
    "fieldserv-job" => %{
      support_label: "Demo pressure",
      rough_edge: "This cached job snapshot cannot be edited offline.",
      guide_links: @row_guide_links.live_view,
      next_pack_pressure_note: "Job detail stays Phoenix-owned unless a future offline island ships proof."
    },
    "fieldserv-inspection" => %{
      support_label: "Future gap",
      rough_edge: "Offline inspection requires storage, replay, conflict, and reconciliation proof.",
      guide_links: @row_guide_links.live_view,
      next_pack_pressure_note: "Inspection drafts are a future offline-island candidate."
    },
    "fieldserv-job-capture" => %{
      support_label: "Next-pack candidate",
      rough_edge: "Camera capture requires the native app runtime.",
      guide_links: @row_guide_links.native_capture,
      next_pack_pressure_note: "Capture belongs in native-screen or native-control work, not a web fallback."
    },
    "fieldserv-evidence-review" => %{
      support_label: "Demo pressure",
      rough_edge: "Device evidence is pending backend verification.",
      guide_links: @row_guide_links.evidence,
      next_pack_pressure_note: "Media availability remains backend-authoritative."
    }
  }

  @capability_map_rows [
    %{
      capability: :capture,
      route_id: "fieldserv-job-capture",
      runtime_owner: :native_screen,
      support_label: "Next-pack candidate",
      package_owner: "example/docs-only",
      proof_posture: "capability-map evidence",
      rough_edge: "Camera capture requires the native app runtime."
    },
    %{
      capability: :scanner,
      route_id: "fieldserv-inspection",
      runtime_owner: :future_native_control,
      support_label: "Future gap",
      package_owner: "deferred",
      proof_posture: "capability-map evidence",
      rough_edge: "Scanner support is a future native-control candidate."
    },
    %{
      capability: :document_scan,
      route_id: "fieldserv-inspection",
      runtime_owner: :future_native_control,
      support_label: "Future gap",
      package_owner: "deferred",
      proof_posture: "capability-map evidence",
      rough_edge: "Document scan remains deferred native-control pressure."
    },
    %{
      capability: :permissions,
      route_id: "fieldserv-job-capture",
      runtime_owner: :native_screen,
      support_label: "Demo pressure",
      package_owner: "example/docs-only",
      proof_posture: "capability-map evidence",
      rough_edge: "Permission needed; camera permission belongs inside native capture."
    },
    %{
      capability: :media_upload,
      route_id: "fieldserv-job-capture",
      runtime_owner: :native_screen,
      support_label: "Demo pressure",
      package_owner: "example/docs-only",
      proof_posture: "capability-map evidence",
      rough_edge: "Upload preparation requires native capture source and backend verification."
    },
    %{
      capability: :offline_inspection,
      route_id: "fieldserv-inspection",
      runtime_owner: :future_offline_island,
      support_label: "Future gap",
      package_owner: "deferred",
      proof_posture: "capability-map evidence",
      rough_edge: "Offline inspection needs route-local storage, replay, conflict, and reconciliation proof."
    },
    %{
      capability: :native_rebuild,
      route_id: "fieldserv-job-capture",
      runtime_owner: :native_screen,
      support_label: "Next-pack candidate",
      package_owner: "deferred",
      proof_posture: "capability-map evidence",
      rough_edge: "Native capture changes require host app rebuild and proof."
    }
  ]

  @spec route_ids() :: [String.t()]
  def route_ids, do: @route_ids

  @spec allowed_support_labels() :: [String.t()]
  def allowed_support_labels, do: Catalog.allowed_support_labels()

  @spec guide_links() :: [map()]
  def guide_links, do: @guide_links

  @spec capability_map_rows() :: [map()]
  def capability_map_rows, do: @capability_map_rows

  @spec route_policy_rows(module()) :: [map()]
  def route_policy_rows(router \\ Router) do
    router
    |> compiled_fieldserv_routes()
    |> Enum.sort_by(fn %{policy: policy} ->
      Enum.find_index(@route_ids, &(&1 == policy.id)) || length(@route_ids)
    end)
    |> Enum.map(&route_row/1)
  end

  defp compiled_fieldserv_routes(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.flat_map(fn route ->
      with true <- String.starts_with?(route.path, "/fieldserv"),
           {:ok, policy} <- RouterMetadata.fetch(route.metadata) do
        [%{route: route, policy: policy}]
      else
        _other -> []
      end
    end)
  end

  defp route_row(%{route: route, policy: policy}) do
    %{
      route_id: policy.id,
      path: route.path,
      runtime_owner: policy.runtime,
      runtime_owner_label: runtime_owner_label(policy.runtime),
      offline_posture: policy.offline,
      offline_posture_label: offline_posture_label(policy.offline),
      security_posture: policy.security,
      security_posture_label: security_posture_label(policy.security),
      capabilities: policy.capabilities,
      capability_labels: capability_labels(policy.capabilities),
      packs: policy.packs,
      transfers: policy.transfers,
      transfer_labels: transfer_labels(policy.transfers)
    }
    |> Map.merge(enrichment!(policy.id))
  end

  defp enrichment!(route_id) do
    Map.fetch!(@support_enrichment, route_id)
  end

  defp runtime_owner_label(:live_view), do: "LiveView route"
  defp runtime_owner_label(:native_screen), do: "Native screen"
  defp runtime_owner_label(runtime), do: humanize_atom(runtime)

  defp offline_posture_label(:cached_read_only), do: "Cached read-only"
  defp offline_posture_label(offline), do: humanize_atom(offline)

  defp security_posture_label(:sensitive), do: "Sensitive route"
  defp security_posture_label(:standard), do: "Standard route"
  defp security_posture_label(security), do: humanize_atom(security)

  defp capability_labels([]), do: ["No native capability required"]
  defp capability_labels(capabilities), do: Enum.map(capabilities, &to_string/1)

  defp transfer_labels([]), do: ["No transfer seam declared"]

  defp transfer_labels(transfers) do
    Enum.map(transfers, fn transfer ->
      [
        declaration_field(transfer, :id),
        declaration_field(transfer, :intent),
        declaration_field(transfer, :source),
        declaration_field(transfer, :verification)
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join(" / ")
    end)
  end

  defp declaration_field(declaration, field) when is_map(declaration), do: Map.get(declaration, field)
  defp declaration_field(declaration, field) when is_list(declaration), do: Keyword.get(declaration, field)

  defp humanize_atom(nil), do: "Not declared"

  defp humanize_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
