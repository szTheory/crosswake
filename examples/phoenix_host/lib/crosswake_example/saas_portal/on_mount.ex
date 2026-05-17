defmodule CrosswakeExample.SaaSPortal.OnMount do
  @moduledoc """
  Lane-specific LiveView auth boundary for the SaaS example host.
  """

  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Auth
  alias Phoenix.Component

  def on_mount(:require_authenticated_member, _params, session, socket) do
    user =
      session
      |> Map.get(Auth.session_key(), "member-1")
      |> Auth.current_user_from_session()

    socket =
      socket
      |> Component.assign(:current_saas_user, user)
      |> Component.assign(:current_saas_account, Accounts.get_account_for_user!(user))
      |> Component.assign(:saas_role, user.role)

    {:cont, socket}
  end
end
