defmodule CrosswakeExample.SaaSPortal.Diagnostics do
  @moduledoc """
  Lane-local AdminPilot route policy diagnostics.

  The route facts here are derived from compiled Phoenix router metadata. Product
  copy and support enrichment are layered separately so this module does not
  become a prose-only shadow of `router.ex`.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Router
  alias CrosswakeExample.Showcase.Catalog

  @route_ids [
    "saas-dashboard",
    "saas-approvals",
    "saas-approval",
    "saas-account",
    "saas-profile-settings",
    "saas-admin-member-access"
  ]

  @guide_links [
    %{label: "Route policy guide", path: "guides/route_policy.md"},
    %{label: "Support matrix", path: "guides/support_matrix.md"},
    %{label: "Bounded bridge guide", path: "guides/bridge.md"},
    %{label: "Web-to-mobile migration guide", path: "guides/web_to_mobile_migration.md"}
  ]

  @row_guide_links %{
    default: ["guides/route_policy.md", "guides/support_matrix.md"],
    bridge: ["guides/route_policy.md", "guides/bridge.md", "guides/support_matrix.md"]
  }

  @support_enrichment %{
    "saas-dashboard" => %{
      support_label: "Available today",
      rough_edge:
        "Cached read-only dashboard context is a degraded read, not offline admin mutation.",
      guide_links: @row_guide_links.default
    },
    "saas-approvals" => %{
      support_label: "Available today",
      rough_edge:
        "The queue can be inspected as cached read-only state; approval decisions stay online and Phoenix-owned.",
      guide_links: @row_guide_links.default
    },
    "saas-approval" => %{
      support_label: "Proof-backed example",
      rough_edge:
        "Haptics is optional confirmation after server success; it never owns approval authority.",
      guide_links: @row_guide_links.bridge
    },
    "saas-account" => %{
      support_label: "Available today",
      rough_edge:
        "Account, team, role, and activity context is deterministic read data, not a CRUD admin framework.",
      guide_links: @row_guide_links.default
    },
    "saas-profile-settings" => %{
      support_label: "Demo pressure",
      rough_edge:
        "MFA and recent-auth posture are backend-owned example pressure; no native auth UI is claimed.",
      guide_links: @row_guide_links.default
    },
    "saas-admin-member-access" => %{
      support_label: "Demo pressure",
      rough_edge:
        "Persistent shell session state does not grant sensitive member-access authority.",
      guide_links: @row_guide_links.default
    }
  }

  @spec route_ids() :: [String.t()]
  def route_ids, do: @route_ids

  @spec allowed_support_labels() :: [String.t()]
  def allowed_support_labels, do: Catalog.allowed_support_labels()

  @spec guide_links() :: [map()]
  def guide_links, do: @guide_links

  @spec route_policy_rows(module()) :: [map()]
  def route_policy_rows(router \\ Router) do
    router
    |> compiled_saas_routes()
    |> Enum.sort_by(fn %{policy: policy} ->
      Enum.find_index(@route_ids, &(&1 == policy.id)) || length(@route_ids)
    end)
    |> Enum.map(&route_row/1)
  end

  defp compiled_saas_routes(router) do
    router
    |> Phoenix.Router.routes()
    |> Enum.flat_map(fn route ->
      with true <- String.starts_with?(route.path, "/saas"),
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
      entry_posture: policy.entry,
      entry_posture_label: entry_posture_label(policy.entry),
      security_posture: policy.security,
      security_posture_label: security_posture_label(policy.security),
      auth_posture: auth_posture(policy),
      auth_posture_label: auth_posture_label(policy),
      capabilities: policy.capabilities,
      capability_labels: capability_labels(policy.capabilities),
      approval_authority: approval_authority(policy.id)
    }
    |> Map.merge(enrichment!(policy.id))
  end

  defp enrichment!(route_id) do
    Map.fetch!(@support_enrichment, route_id)
  end

  defp runtime_owner_label(:live_view), do: "LiveView route"
  defp runtime_owner_label(runtime), do: humanize_atom(runtime)

  defp offline_posture_label(:cached_read_only), do: "Cached read-only"
  defp offline_posture_label(:unavailable), do: "Offline unavailable"
  defp offline_posture_label(offline), do: humanize_atom(offline)

  defp entry_posture_label(:external), do: "External entry"
  defp entry_posture_label(:internal_only), do: "Internal entry only"
  defp entry_posture_label(entry), do: humanize_atom(entry)

  defp security_posture_label(:sensitive), do: "Sensitive route"
  defp security_posture_label(:standard), do: "Standard route"
  defp security_posture_label(security), do: humanize_atom(security)

  defp auth_posture(%{auth_min_level: nil, requires_recent_auth: nil, auth_posture: nil}) do
    :session_required
  end

  defp auth_posture(policy), do: policy.auth_posture || :session_required

  defp auth_posture_label(%{
         auth_min_level: :mfa,
         requires_recent_auth: seconds,
         auth_posture: :strict_recent
       })
       when is_integer(seconds) do
    "MFA required / Recent auth required"
  end

  defp auth_posture_label(%{auth_min_level: :mfa}), do: "MFA required"

  defp auth_posture_label(%{requires_recent_auth: seconds}) when is_integer(seconds),
    do: "Recent auth required"

  defp auth_posture_label(_policy), do: "Authenticated session"

  defp capability_labels([]), do: ["No native capability required"]
  defp capability_labels(capabilities), do: Enum.map(capabilities, &to_string/1)

  defp approval_authority("saas-approval"), do: "Server authority"
  defp approval_authority(_route_id), do: "Phoenix-owned route policy"

  defp humanize_atom(nil), do: "Not declared"

  defp humanize_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
