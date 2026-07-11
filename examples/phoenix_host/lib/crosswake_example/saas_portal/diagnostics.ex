defmodule CrosswakeExample.SaaSPortal.Diagnostics do
  @moduledoc """
  Lane-local AdminPilot route policy diagnostics.

  The route facts here are derived from compiled Phoenix router metadata. Product
  copy and support enrichment are layered separately so this module does not
  become a prose-only shadow of `router.ex`.
  """

  alias Crosswake.Policy.RouterMetadata
  alias CrosswakeExample.Router

  @route_ids [
    "saas-dashboard",
    "saas-approvals",
    "saas-approval",
    "saas-account",
    "saas-profile-settings",
    "saas-admin-member-access"
  ]

  @spec route_ids() :: [String.t()]
  def route_ids, do: @route_ids

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
