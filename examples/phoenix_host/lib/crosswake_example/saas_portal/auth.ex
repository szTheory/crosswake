defmodule CrosswakeExample.SaaSPortal.Auth do
  @moduledoc """
  Host-owned session and authorization helpers for the SaaS example lane.
  """

  import Plug.Conn

  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Fixtures

  @roles [:member, :approver]
  @session_key "saas_portal_user_id"

  def init(action), do: action

  def call(conn, :fetch_current_user) do
    user = current_user(conn)

    conn
    |> assign(:current_saas_user, user)
    |> assign(:current_saas_account, Accounts.get_account_for_user!(user))
  end

  def session_key, do: @session_key
  def roles, do: @roles

  def put_user_session(conn, %{id: id}) when is_binary(id) do
    put_session(conn, @session_key, id)
  end

  def current_user(conn) do
    conn
    |> get_session(@session_key, Fixtures.user!(:member).id)
    |> current_user_from_session()
  end

  def current_user_from_session(user_id) when is_binary(user_id) do
    Fixtures.user_by_id(user_id) || Fixtures.user!(:member)
  end

  def approver?(%{role: :approver}), do: true
  def approver?(_user), do: false
end
