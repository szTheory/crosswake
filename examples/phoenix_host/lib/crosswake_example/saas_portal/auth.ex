defmodule CrosswakeExample.SaaSPortal.Auth do
  @moduledoc """
  Host-owned session and authorization helpers for the SaaS example lane.
  """

  import Plug.Conn

  alias CrosswakeExample.SaaSPortal.Accounts
  alias CrosswakeExample.SaaSPortal.Fixtures

  @roles [:member, :approver, :owner]
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

  def apply_handoff_renewal(conn, %{
        session_renewal_instructions: %{renew_session?: true} = instructions
      }) do
    renewed = configure_session(conn, renew: true)

    renewed =
      Enum.reduce(instructions.delete_session, renewed, fn key, acc ->
        delete_session(acc, key)
      end)

    Enum.reduce(instructions.put_session, renewed, fn {key, value}, acc ->
      put_session(acc, key, value)
    end)
  end

  def apply_step_up_completion(conn, %{
        session_renewal_instructions: %{renew_session?: true, rotate_csrf?: true} = instructions
      }) do
    Plug.CSRFProtection.delete_csrf_token()

    renewed = configure_session(conn, renew: true)

    renewed =
      Enum.reduce(instructions.delete_session, renewed, fn key, acc ->
        delete_session(acc, key)
      end)

    instructions.put_session
    |> Map.take(["crosswake_session_ref", "crosswake_session_version"])
    |> Enum.reduce(renewed, fn {key, value}, acc ->
      put_session(acc, key, value)
    end)
  end

  def current_user(conn) do
    conn
    |> get_session(@session_key, Fixtures.user!(:member).id)
    |> current_user_from_session()
  end

  def current_user_from_session(user_id) when is_binary(user_id) do
    Fixtures.user_by_id(user_id) || Fixtures.user!(:member)
  end

  def approver?(%{role: role}) when role in [:approver, :owner], do: true
  def approver?(_user), do: false
end
