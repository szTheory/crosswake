defmodule CrosswakeExample.E2E.ReplayAuthority do
  @moduledoc false

  import Plug.Conn

  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Manifest.Types.RouteEntry

  @session_key :e2e_replay_session
  @alpha_scope "v1.scope_fixture_alpha_01"
  @beta_scope "v1.scope_fixture_bravo_01"

  def current_session(conn) do
    with %{"state" => "current", "principal" => principal} <- get_session(conn, @session_key),
         {:ok, auth_context} <- auth_context(principal),
         {:ok, scope_ref} <- scope_for(principal) do
      {:ok, %{scope_ref: scope_ref, auth_context: auth_context}}
    else
      _ -> {:error, :auth_required}
    end
  rescue
    _ -> {:error, :auth_required}
  catch
    :exit, _ -> {:error, :auth_required}
    :throw, _ -> {:error, :auth_required}
  end

  def current_route(_conn) do
    {:ok,
     %RouteEntry{
       id: "offline-study",
       path: "/study",
       runtime: :offline_island,
       offline: :local_first,
       gated_by: :offline_study_replay
     }}
  end

  def feature_enabled?(_route, _conn), do: {:ok, :allow}
  def domain_allows?(_route, _session, _event), do: {:ok, :allow}

  defp auth_context("primary") do
    Contracts.new_auth_context(%{
      actor_id: "e2e-primary",
      org_id: "e2e-host",
      mfa_level: :mfa,
      auth_age: 0
    })
  end

  defp auth_context("secondary") do
    Contracts.new_auth_context(%{
      actor_id: "e2e-secondary",
      org_id: "e2e-host",
      mfa_level: :mfa,
      auth_age: 0
    })
  end

  defp auth_context(_), do: {:error, :auth_required}
  defp scope_for("primary"), do: {:ok, @alpha_scope}
  defp scope_for("secondary"), do: {:ok, @beta_scope}
  defp scope_for(_), do: {:error, :auth_required}
end
